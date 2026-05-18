import os
import joblib
import pandas as pd
import numpy as np
import traceback
import time
import logging
from collections import OrderedDict
from fastapi import FastAPI, Header, HTTPException, Request, Response
from fastapi.responses import JSONResponse

# ======================================================
# Cấu hình Logging & Biến môi trường
# ======================================================
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(name)s: %(message)s'
)
logger = logging.getLogger("SageMaker-MME")

app = FastAPI()

MODEL_BASE_PATH = "/opt/ml/models"
# Giới hạn cache để tránh tràn RAM (OOM)
MODEL_CACHE = OrderedDict()
MAX_CACHE_SIZE = 10  # Điều chỉnh tùy theo RAM của Instance

# ======================================================
# Model Loader (Tối ưu nhất cho MME)
# ======================================================
def load_model(target_model: str, model_id: str = None):
    """
    Phiên bản tối ưu: Tự động Debug, Chờ giải nén và Tìm kiếm sâu (Deep Search)
    """
    model_name = target_model.replace(".tar.gz", "")
    
    # Xác định folder tiềm năng để kiểm tra Cache
    # Ưu tiên model_id hash vì log của bạn cho thấy SageMaker dùng ID này
    potential_dir = os.path.join(MODEL_BASE_PATH, model_id) if model_id else os.path.join(MODEL_BASE_PATH, model_name)

    if potential_dir in MODEL_CACHE:
        MODEL_CACHE.move_to_end(potential_dir)
        return MODEL_CACHE[potential_dir]

    # --- 🔍 DEBUG DISK START: Chỉ chạy khi nạp model mới ---
    logger.info(f"--- 📂 BẮT ĐẦU KIỂM TRA Ổ ĐĨA CHO: {target_model} ---")
    try:
        for root, dirs, files in os.walk(MODEL_BASE_PATH):
            level = root.replace(MODEL_BASE_PATH, '').count(os.sep)
            indent = ' ' * 4 * level
            logger.info(f"{indent}📁 [{os.path.basename(root) or 'models'}] -> Files: {files}")
    except Exception as e:
        logger.error(f"❌ Lỗi khi quét ổ đĩa: {e}")
    logger.info("--- 🔍 KẾT THÚC KIỂM TRA Ổ ĐĨA ---")

    # 2. Đợi SageMaker giải nén và Quét tìm file (Tăng lên 25s)
    actual_path = None
    max_retries = 25
    
    for i in range(max_retries):
        # Kiểm tra tất cả các thư mục con trong /opt/ml/models/
        if os.path.exists(MODEL_BASE_PATH):
            for root, dirs, files in os.walk(MODEL_BASE_PATH):
                # Nếu thấy file quan trọng nhất ở bất cứ đâu
                if "pipeline.joblib" in files:
                    actual_path = root
                    logger.info(f"🎯 Đã tìm thấy model tại đường dẫn thực tế: {actual_path} sau {i}s")
                    break
        
        if actual_path: break
        
        if i % 5 == 0:
            logger.info(f"⏳ [{i}s] Đang đợi mount {model_name}... Thư mục hiện có: {os.listdir(MODEL_BASE_PATH)}")
        time.sleep(1)

    if not actual_path:
        logger.error(f"❌ THẤT BẠI: Không tìm thấy pipeline.joblib sau {max_retries}s")
        return None

    # 3. Load Artifacts
    try:
        logger.info(f"🚀 Đang nạp các file joblib từ {actual_path}...")
        bundle = {
            "pipeline": joblib.load(os.path.join(actual_path, "pipeline.joblib")),
        }
        
        # Lưu vào cache (dùng folder ID làm key để đồng bộ)
        MODEL_CACHE[potential_dir] = bundle
        return bundle
    except Exception as e:
        logger.error(f"❌ Lỗi nghiêm trọng khi load file: {str(e)}")
        # In thêm traceback để biết chính xác file nào bị lỗi định dạng
        logger.error(traceback.format_exc())
        return None

# ======================================================
# API Endpoints
# ======================================================

@app.get("/ping")
def ping():
    return Response(status_code=200)

@app.api_route("/models", methods=["GET", "POST"])
def list_models():
    try:
        models = [f for f in os.listdir(MODEL_BASE_PATH) if f.endswith(".tar.gz")]
        return JSONResponse({"models": models})
    except Exception as e:
        return JSONResponse(status_code=500, content={"error": str(e)})

@app.api_route("/invocations", methods=["GET", "POST"])
@app.post("/models/{model_id}/invoke")
async def handle_request(
    request: Request,
    model_id: str = None,
    x_amzn_sagemaker_target_model: str = Header(None)
):
    if request.method == "GET": 
        return Response(status_code=200)

    # Nếu SageMaker gọi trực tiếp vào /invocations mà không có header
    if not x_amzn_sagemaker_target_model:
        return Response(status_code=200)

    # Nạp model
    bundle = load_model(x_amzn_sagemaker_target_model, model_id=model_id)
    
    if bundle is None:
        # TRẢ VỀ 404: Đây là tín hiệu để SageMaker MME biết model chưa sẵn sàng
        # SageMaker sẽ tự động retry nếu nó đang trong quá trình tải.
        raise HTTPException(
            status_code=404, 
            detail=f"Model {x_amzn_sagemaker_target_model} with ID {model_id} is not ready on disk."
        )

    try:
        payload = await request.json()
        df = input_fn(payload)
        preds = predict_fn(df, bundle)
        return output_fn(preds)
    except Exception as e:
        logger.error(f"❌ Inference Error: {traceback.format_exc()}")
        raise HTTPException(status_code=500, detail=str(e))

# ======================================================
# Xử lý Logic (Giữ nguyên cấu trúc của bạn nhưng tối ưu hơn)
# ======================================================
def input_fn(payload):
    df = pd.DataFrame(payload) if isinstance(payload, list) else pd.DataFrame([payload])
    
    return df

def predict_fn(input_df: pd.DataFrame, bundle):

    pipeline = bundle["pipeline"]

    input_df = input_df.replace(["nan", "NaN", "None", "null", ""], np.nan)
    X = input_df.copy()

    logger.info(f"✅ Dữ liệu đã sẵn sàng cho Model. Shape: {X.shape}")
    
    return pipeline.predict(X)

def output_fn(prediction):
    res = prediction.tolist()
    return JSONResponse({"prediction": res[0] if len(res) == 1 else res})