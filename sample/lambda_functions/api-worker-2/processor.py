import os
import json
import logging
from datetime import datetime
import pandas as pd
import asyncio
import boto3

from aws_location_service import (
    ensure_place_index,
    compute_poi_features
)

from utils import (
    classify_bds,
    fs_quan_features, 
    fs_huyen_features 
)

from aurora_postgres import calculate_kinhdo_vido_feats

def full_inference_pipeline(request, sm_client, endpoint_name):
    # Xác định target    
    if request['THONGTINCHUNG__loaihinhnhao'] == 'Nhà ngõ, hẻm':
        target = 'NhaDuAn_ThuanThoCu'
        loaidat = 'Đất thổ cư'
    elif request['THONGTINCHUNG__loaihinhnhao'] == 'Nhà mặt phố, mặt tiền':
        target = 'NHAMTD_ThuanThoCu'
        loaidat = 'Đất thổ cư'
    else:
        return {
            "LoaiBDS": "OUT_OF_SCOPE",
            "prediction_price": 0,
            "confiden_score": 0
        }

    # Extract input
    created_date = request['NGAY'][:9]
    thang = request['NGAY'][:7]
    quan = request['THONGTINCHUNG__quan']
    huyen = request['THONGTINCHUNG__huyen']
    vido = float(request['THONGTINCHUNG__vido'])
    kinhdo = float(request['THONGTINCHUNG__kinhdo'])

    # Get features
    features_quan = fs_quan_features(target, thang, quan)
    features_huyen = fs_huyen_features(target, thang, huyen)
    features_poi = compute_poi_features(vido, kinhdo)
    features_kinhdo_vido = calculate_kinhdo_vido_feats(created_date, loaidat, kinhdo, vido)

    # Build payload
    df_final = pd.concat([
        pd.DataFrame([request]),
        pd.DataFrame([features_quan]),
        pd.DataFrame([features_huyen]),
        pd.DataFrame([features_poi]),
        pd.DataFrame([features_kinhdo_vido]),
    ], axis=1)

    payload = df_final.to_json(orient="records", force_ascii=False)

    # Invoke model
    response = sm_client.invoke_endpoint(
        EndpointName=endpoint_name,
        TargetModel=f"{target}.tar.gz",
        Body=payload,
        ContentType="application/json"
    )

    raw_result = json.loads(response["Body"].read().decode())
    prediction_value = raw_result.get("prediction", 0)

    return {
        "LoaiBDS": target,
        "prediction_price": float(prediction_value),
        "confiden_score": 0.8
    }
