import boto3
from decimal import Decimal
import pickle
from urllib.parse import urlparse
import os

REGION = os.environ['REGION']

boto_session = boto3.Session(region_name=REGION)
s3 = boto_session.client("s3")
fs = boto3.client(
    "sagemaker-featurestore-runtime",
    region_name=REGION
)

sm = boto3.client("sagemaker", region_name=REGION)

# feature group cache
_FEATURE_SCHEMA_CACHE = {}
def _get_feature_schema(feature_group_name):
    """
    Cache describe_feature_group để tránh gọi AWS mỗi request
    """
    if feature_group_name not in _FEATURE_SCHEMA_CACHE:
        _FEATURE_SCHEMA_CACHE[feature_group_name] = sm.describe_feature_group(
            FeatureGroupName=feature_group_name
        )
    return _FEATURE_SCHEMA_CACHE[feature_group_name]

def get(d, key):
    return d.get(key)

TINH_MUC_TIEU = {
    "TP. Hồ Chí Minh",
    "Tỉnh Bình Dương",
    "Tỉnh Bà Rịa - Vũng Tàu",
}

def rule_chung_cu(d):
    return (
        get(d, "TINHTHANH") in TINH_MUC_TIEU
        and get(d, "MALOAITT") == "3 - Áp dụng đối với căn hộ chung cư"
    )

def rule_nha_mtd_thuan_tho_cu(d):
    return (
        get(d, "TINHTHANH") in TINH_MUC_TIEU
        and get(d, "MALOAITT") == "2 - Áp dụng đối với trường hợp nguồn gốc SDĐ là Nhà nước giao đất"
        and get(d, "LOAIBDS") in {
            "2. Đất thổ cư riêng lẻ",
            "3. Đất thổ cư riêng lẻ + Tài sản trên đất",
        }
        and get(d, "VITRI") == "MTĐ"
        and get(d, "HANMUCCONGTRINH") is not None
        and (
            (get(d, "TS_DTSD_CONGNHAN") or 0) > 0
            or (get(d, "DTSD_XD_DUNGGPXD") or 0) > 0
            or (get(d, "DTSD_XACNHANCQNN") or 0) > 0
            or (get(d, "DTSD_XD_KOPHEP_VUOTGPXD") or 0) > 0
        )
        and get(d, "FLAG_UNIQUE_LOAIDAT") == 1
        and get(d, "FLAG_1LOAIDAT_DATTHOCU") == 1
    )

def rule_nha_du_an_thuan_tho_cu(d):
    return (
        get(d, "TINHTHANH") in TINH_MUC_TIEU
        and get(d, "MALOAITT") == "2 - Áp dụng đối với trường hợp nguồn gốc SDĐ là Nhà nước giao đất"
        and get(d, "LOAIBDS") in {
            "2. Đất thổ cư riêng lẻ",
            "3. Đất thổ cư riêng lẻ + Tài sản trên đất",
            "17. Đất nền dự án (Dự án chung cư/Resort/trung tâm thương mại/xây dựng nhà kinh doanh..)",
            "20. Đất nền dự án + Tài sản trên đất",
        }
        and (
            get(d, "DOANDUONG") == "Đất nền dự án"
            or (
                get(d, "LOAIDAT_DOANDUONG") == "Đất nền dự án"
                and get(d, "FLAG_MADOANDUONG") == 1
            )
        )
        and get(d, "FLAG_UNIQUE_LOAIDAT") == 1
        and get(d, "FLAG_1LOAIDAT_DATTHOCU") == 1
    )

RULES = [
    ("ChungCu", rule_chung_cu),
    ("NHAMTD_ThuanThoCu", rule_nha_mtd_thuan_tho_cu),
    ("NhaDuAn_ThuanThoCu", rule_nha_du_an_thuan_tho_cu),
]

def classify_bds(d):
    for label, rule in RULES:
        if rule(d):
            return label
    return "OTHER"


# sagemaker feature store
def fs_quan_features(target, thang, quan):
    fg_name = f"example_{target}_feature_dongialichsu_quan_group"
    response = fs.get_record(
        FeatureGroupName=fg_name,
        RecordIdentifierValueAsString=f"{thang}_{quan}"   # quan = Q1
    )
    # lay schema tu cache
    desc = _get_feature_schema(fg_name)

    all_features = [f["FeatureName"] for f in desc["FeatureDefinitions"]]
    record = response.get("Record", [])
    record_dict = {f["FeatureName"]: f["ValueAsString"] for f in record}
    full_record = {
        feature: record_dict.get(feature, None)
        for feature in all_features
    }
    # drop event_time
    full_record.pop("event_time", None)

    return full_record

def fs_huyen_features(target, thang, huyen):
    fg_name = f"example_{target}_feature_dongialichsu_huyen_group"
    response = fs.get_record(
        FeatureGroupName=fg_name,
        RecordIdentifierValueAsString=f"{thang}_{huyen}"   # huyen
    )
    
    desc = _get_feature_schema(fg_name)

    all_features = [f["FeatureName"] for f in desc["FeatureDefinitions"]]
    record = response.get("Record", [])
    record_dict = {f["FeatureName"]: f["ValueAsString"] for f in record}
    full_record = {
        feature: record_dict.get(feature, None)
        for feature in all_features
    }
    # drop event_time
    full_record.pop("event_time", None)

    return full_record
  