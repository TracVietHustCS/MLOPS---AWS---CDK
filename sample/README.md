# ACB SageMaker MLOps Platform

## Region: Asia Pacific (Singapore) - ap-southeast-1 | Environment: DevTest

---

## Hướng Dẫn Sử Dụng

Hướng dẫn từng bước để triển khai hạ tầng AI/ML trên AWS. Làm theo thứ tự, không cần hiểu sâu về code.

**Yêu cầu:** Terraform >= 1.8.0, AWS CLI v2, Python 3.8+ đã cài sẵn. AWS profile `acb` đã cấu hình.

---

### Bước 1: Tải Source Code

```bash
# Clone repository (hoặc giải nén file zip)
git clone <repository-url>

# Di chuyển vào thư mục environment Singapore
cd acb_sagemaker-main/environments/ap-southeast-1
```

---

### Bước 2: Khởi Tạo Terraform

```bash
# Khởi tạo Terraform (chỉ cần chạy 1 lần đầu, hoặc khi thêm module mới)
terraform init
```

**Nếu dùng S3 backend (production):**
1. Mở file `main.tf`, bỏ comment dòng `backend "s3" {}`
2. Chạy: `terraform init -backend-config=backend.tfvars`

**Kết quả mong đợi:** Hiện `Terraform has been successfully initialized!`

---

### Bước 3: Xem Trước Thay Đổi (Plan)

```bash
# Xem Terraform sẽ tạo/sửa/xóa những gì (KHÔNG thay đổi gì trên AWS)
terraform plan
```

**Đọc kết quả:**
- `+ resource` = sẽ TẠO MỚI
- `~ resource` = sẽ SỬA ĐỔI
- `- resource` = sẽ XÓA

**Lưu ý:** Bước này an toàn, chỉ hiển thị preview, không thay đổi gì trên AWS.

---

### Bước 4: Triển Khai Hạ Tầng (Apply)

**Cách 1: Triển khai từng phần (khuyến nghị cho lần đầu)**

```bash
# Bước 4a: Tạo S3 bucket và VPC endpoints trước
terraform apply -target=module.s3_model_storage -target=module.vpc_endpoints

# Bước 4b: Tạo toàn bộ hạ tầng còn lại
terraform apply
```

**Cách 2: Triển khai tất cả cùng lúc**

```bash
terraform apply
```

Terraform sẽ hỏi: `Do you want to perform these actions?`
- Gõ `yes` rồi Enter để xác nhận
- Gõ `no` để hủy

**Thời gian:** ~10-20 phút tùy số lượng resource.

---

### Bước 5: Upload Model Lên S3 (Khi Cần Deploy Model)

Chỉ cần làm bước này khi muốn deploy SageMaker endpoint (inference).

```bash
# Quay về thư mục gốc
cd ../../common/sagemaker-builder

# Upload vision model
python3 prepare_and_upload_model.py \
  --model-id "Qwen/Qwen2.5-VL-7B-Instruct" \
  --model-name "qwen2-5-vl-7b" \
  --bucket <tên_bucket_từ_bước_4> \
  --region ap-southeast-1

# Upload text model
python3 prepare_and_upload_model.py \
  --model-id "Qwen/Qwen3-30B-A3B-Instruct-2507-FP8" \
  --model-name "qwen3-30b-a3b-instruct-2507-fp8" \
  --bucket <tên_bucket_từ_bước_4> \
  --region ap-southeast-1
```

**Lấy tên bucket:** Chạy `terraform output s3_bucket_name` trong thư mục `environments/ap-southeast-1`.

Sau khi upload xong, sửa file `terraform.tfvars`:
```hcl
deploy_vision_model = true   # đổi từ false → true
deploy_text_model   = true   # đổi từ false → true
```

Rồi chạy lại:
```bash
cd ../../environments/ap-southeast-1
terraform apply
```

---

### Bước 6: Kiểm Tra Kết Quả

```bash
# Xem tất cả outputs
terraform output

# Xem URL API Gateway
terraform output api_gateway_invoke_url

# Xem tên S3 bucket
terraform output s3_bucket_name

# Kiểm tra SageMaker endpoint (nếu đã deploy model)
aws sagemaker describe-endpoint \
  --endpoint-name rrth-mh-bds-dev-qwen3-30b-a3b-instruct-2507-fp8 \
  --region ap-southeast-1 \
  --query 'EndpointStatus' \
  --profile acb
```

---

### Thay Đổi Cấu Hình

Khi cần thay đổi cấu hình (bật/tắt service, đổi instance type, v.v.):

1. Mở file `terraform.tfvars` bằng text editor
2. Sửa giá trị biến cần thay đổi
3. Chạy `terraform plan` để xem preview
4. Chạy `terraform apply` để áp dụng

**Ví dụ bật/tắt service:**
```hcl
# Tắt Location Service
deploy_location_service = false

# Bật SageMaker endpoint
deploy_text_model = true

# Đổi instance type
text_instance_type = "ml.g5.2xlarge"
```

---

### Xóa Toàn Bộ Hạ Tầng (Clean Up)

⚠️ **CẢNH BÁO: Lệnh này sẽ XÓA TẤT CẢ resource trên AWS. Chỉ dùng khi muốn dọn dẹp hoàn toàn.**

```bash
# Xóa hết model trong S3 bucket trước
aws s3 rm s3://<tên_bucket> --recursive --profile acb

# Xóa hết image trong ECR trước
aws ecr batch-delete-image \
  --repository-name rrth-mh-bds-dev-inference \
  --image-ids "$(aws ecr list-images --repository-name rrth-mh-bds-dev-inference --query 'imageIds[*]' --output json --profile acb)" \
  --region ap-southeast-1 --profile acb

# Xóa toàn bộ hạ tầng
terraform destroy
```

**Lưu ý khi destroy:** Security group SageMaker có thể bị lỗi vì ENI chưa xóa kịp. Nếu gặp lỗi:
1. Vào AWS Console → EC2 → Network Interfaces
2. Tìm ENI có description chứa "SageMaker"
3. Đợi status chuyển sang "Available" → Delete
4. Chạy lại `terraform destroy`

---

### Các Lệnh Hay Dùng (Cheat Sheet)

| Lệnh | Mục đích |
|---|---|
| `terraform init` | Khởi tạo (chạy 1 lần đầu) |
| `terraform plan` | Xem preview thay đổi (an toàn) |
| `terraform apply` | Triển khai lên AWS |
| `terraform output` | Xem thông tin sau deploy |
| `terraform destroy` | Xóa toàn bộ (cẩn thận!) |
| `terraform state list` | Liệt kê resource đang quản lý |
| `terraform refresh` | Đồng bộ state với AWS thực tế |

---

### Xử Lý Lỗi Thường Gặp

| Lỗi | Nguyên nhân | Cách xử lý |
|---|---|---|
| `Error: No valid credential sources found` | Chưa cấu hình AWS CLI | Chạy `aws configure --profile acb` |
| `Error: error configuring S3 Backend` | Backend S3 chưa tạo | Dùng local backend (comment `backend "s3"` trong main.tf) |
| `Error acquiring the state lock` | Terraform đang chạy ở nơi khác | Đợi hoặc chạy `terraform force-unlock <lock-id>` |
| `Error: creating SageMaker Endpoint` | Hết quota instance type | Liên hệ AWS Support tăng quota |
| `Error: deleting Security Group` | ENI chưa xóa | Xóa ENI thủ công trong EC2 Console (xem phần Clean Up) |
| `Error: timeout` khi inference lần đầu | Model đang warm up | Đợi 3-5 phút, thử lại |

---

## Bảng Chi Phí & Chi Tiết Kỹ Thuật

Phần dưới đây dành cho team kỹ thuật, mô tả chi tiết mapping giữa biến Terraform và AWS services.

---

## 1. Bảng Chi Phí AWS Calculator

| # | Service | Monthly (USD) | 12 Months (USD) | Thông số chính |
|---|---------|--------------|-----------------|----------------|
| 1 | SageMaker Studio Notebooks | 50.69 | 608.28 | ml.m5.xlarge, 1 DS, 1 instance, 8h/day, 22 days/month |
| 2 | SageMaker Feature Store | 27.69 | 332.28 | Record 5KB/1KB, 32GB storage, 1M writes, 1M reads |
| 3 | SageMaker Training | 77.38 | 928.56 | ml.m5.2xlarge, 25 jobs/month, 1 instance/job, 5h/job |
| 4 | SageMaker Real-Time Inference | 136.30 | 1,635.60 | ml.c5.xlarge + ml.m5.xlarge, 3 models, 2 instances/endpoint, 8h/day, 22 days/month, 25 Monitor jobs |
| 5 | S3 Standard | 5.78 | 69.36 | 15GB, 1M PUT/GET requests |
| 6 | Data Transfer | 1.20 | 14.40 | 10GB outbound Internet |
| 7 | Amazon API Gateway | 27.50 | 330.00 | 5M REST + 5M HTTP requests |
| 8 | AWS Lambda | 9.80 | 117.60 | x86, 50M requests/month, 512MB ephemeral |
| 9 | Maps (Location Service) | 62.50 | 750.00 | 500K dynamic, 50K static, 500K open data |
| 10 | AWS PrivateLink | 52.45 | 629.40 | 6 VPC Interface endpoints (không có S3 Gateway) |
| 11 | AWS WAF | 10.60 | 127.20 | 1 Web ACL, 3 rules, 1 rule group |
| 12 | AWS KMS | 9.80 | 117.60 | 5 CMKs, 1M symmetric, 100K asymmetric requests |
| 13 | Amazon CloudWatch | 18.09 | 217.08 | 10 metrics, 50K GetMetricData, 20GB logs |
| 14 | AWS CloudTrail | 0.00 | 0.00 | 1 management trail (free tier) |
| 15 | RDS Backup | 0.00 | 0.00 | 100GB primary data |
| 16 | EBS Backup | 10.00 | 120.00 | 200GB primary data |
| 17 | AWS Glue Data Catalog | 11.00 | 132.00 | 1M objects, 1M access requests |
| 18 | AWS Glue Crawlers | 36.67 | 440.04 | 1 crawler |
| 19 | Amazon RDS for PostgreSQL | 254.63 | 3,055.56 | db.t4g.medium, 100GB gp2, Multi-AZ, On-Demand |
| 20 | AWS CodeBuild | 9.00 | 108.00 | On-Demand EC2, BUILD_GENERAL1_SMALL, 30 builds/month |
| 21 | Amazon ECR | 5.00 | 60.00 | 50GB storage, 10GB inbound |
| **Tổng** | | **$816.08** | **$9,792.96** | |

---

## 2. Chi Tiết Mapping: Service → Biến → Mục Đích → Cơ Chế


### 2.1 SageMaker Studio Notebooks — $50.69/tháng

| Biến (terraform.tfvars) | Giá trị | Mục đích |
|---|---|---|
| `deploy_sagemaker_studio` | `true` | Bật/tắt deploy SageMaker Studio Domain |
| `studio_auth_mode` | `"IAM"` | Xác thực user bằng IAM (không dùng SSO) |
| `studio_default_instance_type` | `"ml.m5.xlarge"` | Instance mặc định cho kernel gateway (notebook compute) |
| `studio_user_profiles` | 1 user: `data-scientist-1` với `ml.m5.xlarge` | Danh sách data scientist, mỗi người 1 notebook instance |

**Cơ chế:** Module `sagemaker-studio` tạo SageMaker Domain + User Profile. Mỗi user profile có `kernel_gateway_app_settings` chỉ định instance type cho notebook. Chi phí tính theo giờ sử dụng thực tế (8h/day × 22 days là ước lượng trong calculator, không kiểm soát bằng code).

**File:** `sagemaker.tf` → `module "sagemaker_studio"` → `modules/sagemaker-studio/main.tf`

---

### 2.2 SageMaker Feature Store — $27.69/tháng

| Biến (terraform.tfvars) | Giá trị | Mục đích |
|---|---|---|
| `deploy_mlops_feature_store` | `true` | Bật/tắt Feature Store |
| `mlops_feature_group_name` | `"customer-features"` | Tên feature group |
| `mlops_feature_record_identifier` | `"customer_id"` | Cột định danh record |
| `mlops_feature_event_time_name` | `"event_time"` | Cột thời gian event |
| `mlops_feature_enable_online_store` | `true` | Bật online store (low-latency reads) |
| `mlops_feature_enable_offline_store` | `true` | Bật offline store (S3-backed, batch reads) |
| `mlops_feature_definitions` | `age` (Integral), `income` (Fractional) | Định nghĩa các features |

**Cơ chế:** Module `sagemaker-feature-store` tạo Feature Group với online store (DynamoDB-backed) và offline store (S3). Chi phí phụ thuộc vào record size, storage, và số lượng read/write (ước lượng trong calculator).

**File:** `mlops.tf` → `module "mlops_feature_store"` → `modules/sagemaker-feature-store/`

---

### 2.3 SageMaker Training — $77.38/tháng

| Biến (terraform.tfvars) | Giá trị | Mục đích |
|---|---|---|
| `deploy_sagemaker_training` | `true` | Bật/tắt training infrastructure |
| `training_image` | `null` | Container image cho training (cần set khi deploy) |
| `training_instance_type` | `"ml.m5.2xlarge"` | Instance type cho training job |
| `training_instance_count` | `1` | Số instances mỗi training job |
| `training_volume_size` | `50` | Storage (GB) gắn vào training instance |
| `enable_scheduled_training` | `false` | Tắt auto-trigger training theo lịch |
| `training_schedule` | `"cron(0 0 ? * SUN *)"` | Lịch chạy training (nếu bật) |

**Cơ chế:** Module `sagemaker-training` tạo Step Functions state machine để orchestrate training workflow. Khi trigger (manual hoặc EventBridge schedule), Step Functions gọi `sagemaker:CreateTrainingJob` với instance type và count đã cấu hình. Chi phí = instance price × số giờ × số jobs/tháng (25 jobs × 5h/job là ước lượng calculator).

**Lưu ý:** Module chỉ deploy khi `deploy_sagemaker_training = true` VÀ `training_image != null`. Hiện tại `training_image = null` nên module chưa được tạo.

**File:** `mlops.tf` → `module "sagemaker_training"` → `modules/sagemaker-training/main.tf`

---

### 2.4 SageMaker Real-Time Inference — $136.30/tháng

| Biến (terraform.tfvars) | Giá trị | Mục đích |
|---|---|---|
| `deploy_vision_model` | `false` (cần set `true` khi deploy) | Bật/tắt vision model endpoint |
| `deploy_text_model` | `false` (cần set `true` khi deploy) | Bật/tắt text model endpoint |
| `vision_model_name` | `"qwen2-5-vl-7b"` | Tên vision model |
| `vision_model_id` | `"Qwen/Qwen2.5-VL-7B-Instruct"` | Hugging Face model ID cho vision |
| `vision_instance_type` | `"ml.c5.xlarge"` | Instance type cho vision endpoint |
| `text_model_name` | `"qwen3-30b-a3b-instruct-2507-fp8"` | Tên text model |
| `text_model_id` | `"Qwen/Qwen3-30B-A3B-Instruct-2507-FP8"` | Hugging Face model ID cho text |
| `text_instance_type` | `"ml.m5.xlarge"` | Instance type cho text endpoint |
| `initial_instance_count` | `2` | Số instances mỗi endpoint |
| `is_moe_text_model` | `true` | Text model là Mixture-of-Experts |
| `is_moe_vision_model` | `false` | Vision model không phải MoE |
| `enable_endpoint_scheduler` | `true` | Bật Lambda scheduler tắt/bật endpoint theo lịch |
| `schedule_on_off_vision_endpoint` | `true` | Đánh tag AutoSchedule cho vision endpoint |
| `schedule_on_off_text_endpoint` | `true` | Đánh tag AutoSchedule cho text endpoint |
| `scheduler_start_cron` | `"cron(0 1 ? * MON-FRI *)"` | Start endpoint 08:00 SGT (Mon-Fri) |
| `scheduler_stop_cron` | `"cron(0 11 ? * MON-FRI *)"` | Stop endpoint 18:00 SGT (Mon-Fri) |
| `scheduler_instance_count` | `2` | Số instances khi recreate endpoint |

**Model Monitoring:**

| Biến (terraform.tfvars) | Giá trị | Mục đích |
|---|---|---|
| `deploy_mlops_model_monitoring` | `true` | Bật/tắt model monitoring |
| `mlops_monitoring_instance_type` | `"ml.c5.xlarge"` | Instance type cho monitoring job |
| `mlops_monitoring_instance_count` | `1` | Số instances cho monitoring job |
| `mlops_monitoring_schedule_expression` | `"cron(0 * ? * * *)"` | Chạy monitoring mỗi giờ |

**Cơ chế Endpoint:** Module `sagemaker-endpoint` tạo SageMaker Model → Endpoint Configuration → Endpoint. Mỗi endpoint có 1 production variant với instance type và count chỉ định. Container: LMI `djl-inference:0.33.0-lmi15.0.0-cu128`.

**Cơ chế Scheduler (Lambda + EventBridge):**
1. EventBridge trigger Lambda `sagemaker-scheduler` theo cron schedule
2. **Stop (18:00 SGT):** Lambda lưu endpoint config + autoscaling config vào S3 → xóa endpoint hoàn toàn
3. **Start (08:00 SGT):** Lambda đọc config từ S3 → tạo lại endpoint + restore autoscaling
4. Lambda nhận diện endpoint cần schedule qua tag `AutoSchedule=true` (set bởi `enable_auto_schedule` trong endpoint module)

**Cơ chế Monitoring:** Module `sagemaker-model-monitoring` tạo Data Quality Job Definition + Monitoring Schedule. SageMaker tự động chạy monitoring job theo schedule, so sánh data distribution với baseline. Monitoring chỉ deploy khi có ít nhất 1 model endpoint (`deploy_text_model || deploy_vision_model`).

**File:** `sagemaker.tf` → `module "sagemaker_endpoint_text/vision"`, `lambda.tf` → `module "sagemaker_scheduler"`, `mlops.tf` → `module "mlops_model_monitoring"`

---

### 2.5 S3 Standard — $5.78/tháng

| Biến (terraform.tfvars) | Giá trị | Mục đích |
|---|---|---|
| `deploy_data_bucket` | `false` | Data bucket chưa deploy |
| `data_bucket_name` | `"rrth-mh-bds"` | Tên data bucket (khi deploy) |
| `deploy_kms` | `true` | Mã hóa S3 bằng KMS key |

**Cơ chế:**
- `s3_model_storage` (luôn tạo): Lưu model artifacts, training data, feature store offline, monitoring output, scheduler state, Spark logs. Versioning enabled, lifecycle 30 ngày cho noncurrent versions.
- `s3_rrth_mh_bds` (khi `deploy_data_bucket = true`): Data bucket chính. Versioning enabled, KMS encryption, VPC endpoint policy restrict access qua VPC endpoint. Hiện tại `deploy_data_bucket = false` nên chưa tạo.

**File:** `s3.tf` → `module "s3_model_storage"` + `module "s3_rrth_mh_bds"`

---

### 2.6 Data Transfer — $1.20/tháng

Không có biến cấu hình trực tiếp. Chi phí phụ thuộc vào lượng data transfer outbound Internet từ các service (API Gateway responses, S3 downloads, etc.). Calculator ước lượng 10GB/tháng.

---

### 2.7 Amazon API Gateway — $27.50/tháng

| Biến (terraform.tfvars) | Giá trị | Mục đích |
|---|---|---|
| `deploy_api_gateway` | `true` | Bật/tắt API Gateway |
| `api_gateway_name` | `"inference"` | Tên API |
| `api_gateway_endpoint_type` | `"REGIONAL"` | Loại endpoint (REGIONAL/PRIVATE/EDGE) |
| `api_gateway_stage_name` | `"v1"` | Tên stage |
| `api_gateway_throttling_burst_limit` | `100` | Giới hạn burst requests |
| `api_gateway_throttling_rate_limit` | `50` | Giới hạn requests/giây |
| `api_gateway_log_retention_days` | `30` | Retention log access |
| `api_gateway_enable_cors` | `true` | Bật CORS |
| `api_gateway_require_api_key` | `false` | Không yêu cầu API key |
| `api_lambda_layers` | `["arn:aws:lambda:ap-southeast-1:336392948345:layer:AWSSDKPandas-Python311:26"]` | Lambda Layer cho API function |

**Cơ chế:** Module `api-gateway` tạo REST API Gateway với Lambda integration. Request flow: Client → API Gateway → Lambda → Response. Endpoints: `/v1/test` (GET/POST), `/v1/inference` (POST). Chi phí tính theo số requests (ước lượng 5M REST + 5M HTTP/tháng).

**File:** `api.tf` → `module "api_gateway"` + `module "api_lambda"` → `modules/api-gateway/main.tf`

---

### 2.8 AWS Lambda — $9.80/tháng

| Biến (terraform.tfvars) | Giá trị | Mục đích |
|---|---|---|
| `deploy_api_gateway` | `true` | Lambda api deploy cùng API Gateway |
| `enable_endpoint_scheduler` | `true` | Lambda scheduler deploy khi bật |

**Cơ chế:** 2 Lambda functions:
1. `api`: Xử lý API Gateway requests, runtime Python 3.12, 128MB memory, 30s timeout
2. `sagemaker-scheduler`: Tắt/bật SageMaker endpoints, runtime Python 3.12, 256MB memory, 900s timeout

Chi phí tính theo số invocations + duration (ước lượng 50M requests/tháng trong calculator bao gồm cả API traffic).

**File:** `api.tf` → `module "api_lambda"`, `lambda.tf` → `module "sagemaker_scheduler"`

---

### 2.9 Maps (Location Service) — $62.50/tháng

| Biến (terraform.tfvars) | Giá trị | Mục đích |
|---|---|---|
| `deploy_location_service` | `true` | Bật/tắt Location Service |
| `location_service_region` | `"ap-southeast-1"` | Region deploy (cùng region) |
| `location_create_place_index` | `true` | Tạo Place Index (geocoding/search) |
| `location_create_map` | `true` | Tạo Map resource |
| `location_create_tracker` | `false` | Không tạo device tracker |
| `location_create_geofence_collection` | `false` | Không tạo geofence |
| `location_create_route_calculator` | `false` | Không tạo route calculator |
| `location_data_source` | `"Esri"` | Nguồn dữ liệu bản đồ |

**Cơ chế:** Module `location-service` tạo Place Index (Esri, SingleUse) và Map (VectorEsriStreets). Sử dụng provider `aws.location` (cùng region ap-southeast-1). Chi phí tính theo số map tiles requested và geocoding calls (ước lượng 500K dynamic + 50K static maps/tháng).

**File:** `location.tf` → `module "location_service"` → `modules/location-service/main.tf`

---

### 2.10 AWS PrivateLink — $52.45/tháng

| Biến (terraform.tfvars) | Giá trị | Mục đích |
|---|---|---|
| `create_vpc_endpoints` | `true` | Bật/tắt tạo VPC endpoints |
| `create_s3_gateway` | `false` | Không tạo S3 Gateway endpoint |
| `create_s3_interface` | `false` | Không tạo S3 Interface endpoint |
| `create_sagemaker_endpoint` | `true` | VPC endpoint cho SageMaker API + Runtime |
| `create_ecr_endpoint` | `false` | Không tạo VPC endpoint cho ECR API (CodeBuild chạy ngoài VPC) |
| `create_ecr_docker_endpoint` | `false` | Không tạo VPC endpoint cho ECR Docker (CodeBuild chạy ngoài VPC) |
| `create_cloudwatch_endpoint` | `true` | VPC endpoint cho CloudWatch Logs |
| `create_secrets_manager_endpoint` | `true` | VPC endpoint cho Secrets Manager |
| `create_api_gateway_endpoint` | `true` | VPC endpoint cho API Gateway (execute-api) |
| `create_lambda_endpoint` | `true` | VPC endpoint cho Lambda |
| `create_ssm_endpoint` | `false` | Không tạo SSM endpoints |

**Cơ chế:** Module `vpc-endpoints` tạo Interface VPC Endpoints để các service trong private subnet truy cập AWS services mà không cần đi qua Internet. Mỗi interface endpoint tính phí ~$7.20/tháng/AZ. NAT Gateway được tạo riêng cho internet access.

**Interface endpoints được tạo (6 endpoints):**
1. `sagemaker.api` — SageMaker API calls
2. `sagemaker.runtime` — SageMaker inference calls
3. `logs` — CloudWatch Logs
4. `secretsmanager` — Secrets Manager
5. `execute-api` — API Gateway private access
6. `lambda` — Lambda private access

**Không tạo S3 endpoints** — `create_s3_gateway = false`, `create_s3_interface = false`. S3 access đi qua NAT Gateway.

**Không tạo ECR endpoints** — CodeBuild chạy ngoài VPC (`enable_vpc = false`), dùng internet mặc định để pull/push ECR images.

**File:** `networking.tf` → `module "vpc_endpoints"` → `modules/vpc-endpoints/main.tf`

---

### 2.11 AWS WAF — $10.60/tháng

| Biến (terraform.tfvars) | Giá trị | Mục đích |
|---|---|---|
| `deploy_waf` | `true` | Bật/tắt WAF |
| `waf_enable_sql_injection_protection` | `true` | Bật rule chống SQL injection |
| `waf_enable_rate_limiting` | `true` | Bật rate limiting |
| `waf_rate_limit` | `2000` | Giới hạn requests/5 phút/IP |
| `waf_enable_logging` | `true` | Bật WAF logging |
| `waf_log_retention_days` | `30` | Retention log WAF |

**Cơ chế:** Module `waf` tạo Web ACL với các rules:
1. **AWSManagedRulesCommonRuleSet** — Managed rule group chống các attack phổ biến
2. **AWSManagedRulesKnownBadInputsRuleSet** — Managed rule group chặn bad inputs
3. **AWSManagedRulesSQLiRuleSet** — Managed rule group chống SQL injection (khi `waf_enable_sql_injection_protection = true`)
4. **RateLimitRule** — Custom rate-based rule (khi `waf_enable_rate_limiting = true`)

WAF được associate với API Gateway stage. Logging ghi vào CloudWatch Log Group.

**File:** `data-engineering.tf` → `module "waf"` → `modules/waf/main.tf`

---

### 2.12 AWS KMS — $9.80/tháng

| Biến (terraform.tfvars) | Giá trị | Mục đích |
|---|---|---|
| `deploy_kms` | `true` | Bật/tắt KMS keys |

**Cơ chế:** 5 Customer Managed Keys (CMKs) tách riêng theo service group:

| # | Key Name | Dùng cho | Services |
|---|---|---|---|
| 1 | `kms_key_s3` | S3 bucket encryption | S3 |
| 2 | `kms_key_rds` | RDS + Secrets Manager | RDS, Secrets Manager |
| 3 | `kms_key_sagemaker` | SageMaker encryption | SageMaker (training, endpoints) |
| 4 | `kms_key_logs` | Logs encryption | CloudTrail, CloudWatch Logs, VPC Flow Logs |
| 5 | `kms_key_ecr` | ECR + CodeBuild | ECR images, CodeBuild artifacts |

Key rotation enabled cho tất cả. Chi phí = $1/key/tháng × 5 = $5/tháng + request charges. Khớp calculator: 5 CMKs.

**File:** `security.tf` → `module "kms_key_s3"`, `module "kms_key_rds"`, `module "kms_key_sagemaker"`, `module "kms_key_logs"`, `module "kms_key_ecr"` → `modules/kms/main.tf`

---

### 2.13 Amazon CloudWatch — $18.09/tháng

Không có biến cấu hình trực tiếp cho CloudWatch pricing. Chi phí phát sinh từ các log groups được tạo bởi các module khác:

| Log Group | Nguồn | Retention |
|---|---|---|
| `/aws/cloudtrail/*` | CloudTrail | 90 ngày |
| VPC Flow Logs | VPC Flow Logs | 90 ngày |
| `aws-waf-logs-*` | WAF | 30 ngày |
| `/aws/codebuild/*` | CodeBuild | Default |
| `/aws/vendedlogs/states/*-training` | SageMaker Training (Step Functions) | Default |
| API Gateway access logs | API Gateway | 30 ngày |

**Biến liên quan:**
- `cloudtrail_log_retention_days = 90`
- `vpc_flow_logs_retention_days = 90`
- `waf_log_retention_days = 30`
- `api_gateway_log_retention_days = 30`
- `cloudwatch_metrics_namespace = "ACB/SageMaker"`

**Cơ chế:** Mỗi module tự tạo CloudWatch Log Group với retention riêng. Custom metrics được publish bởi SageMaker endpoints. Calculator ước lượng 10 metrics + 20GB logs ingested/tháng.

---

### 2.14 AWS CloudTrail — $0/tháng

| Biến (terraform.tfvars) | Giá trị | Mục đích |
|---|---|---|
| `deploy_cloudtrail` | `true` | Bật/tắt CloudTrail |
| `cloudtrail_log_retention_days` | `90` | Retention CloudWatch logs |
| `cloudtrail_log_archive_days` | `90` | Archive sau N ngày |
| `cloudtrail_log_expiration_days` | `365` | Xóa logs sau N ngày |

**Cơ chế:** Module `cloudtrail` tạo 1 trail multi-region, ghi management events vào CloudWatch Logs + S3 (S3 là bắt buộc theo AWS). Module tự tạo S3 bucket với lifecycle (archive sau 90 ngày, xóa sau 365 ngày). Trail đầu tiên miễn phí. Không bật data events hay Insights.

**File:** `security.tf` → `module "cloudtrail"` → `modules/cloudtrail/main.tf`

---

### 2.15 RDS Backup — $0/tháng

| Biến (terraform.tfvars) | Giá trị | Mục đích |
|---|---|---|
| `mlops_rds_backup_retention_period` | `7` | RDS native backup retention (ngày) |

**Cơ chế:** RDS native automated backup (included trong RDS pricing, miễn phí đến bằng allocated storage). Backup 100GB ≤ allocated storage 100GB → $0.

**File:** `mlops.tf` → `module "mlops_rds_postgres"` → `modules/rds-postgres/main.tf` (param `backup_retention_period`)

---

### 2.16 EBS Backup — $10/tháng

| Biến (terraform.tfvars) | Giá trị | Mục đích |
|---|---|---|
| `deploy_backup` | `true` | Bật/tắt AWS Backup |
| `backup_daily_schedule` | `"cron(0 5 ? * * *)"` | Backup hàng ngày 5:00 UTC (12:00 SGT) |
| `backup_daily_retention_days` | `35` | Giữ daily backup 35 ngày |
| `backup_enable_weekly` | `true` | Bật weekly backup |
| `backup_weekly_retention_days` | `90` | Giữ weekly backup 90 ngày |
| `backup_enable_monthly` | `true` | Bật monthly backup |
| `backup_monthly_retention_days` | `365` | Giữ monthly backup 365 ngày |

**Cơ chế:** Module `backup` tạo AWS Backup vault + plan + selection. Backup targets: RDS instance + S3 model storage bucket (+ data bucket nếu `deploy_data_bucket = true`). AWS Backup tạo snapshots theo schedule. Calculator ước lượng 200GB EBS backup (bao gồm RDS snapshots + incremental changes).

**File:** `security.tf` → `module "backup"` → `modules/backup/main.tf`

---

### 2.17 AWS Glue Data Catalog — $11/tháng

| Biến (terraform.tfvars) | Giá trị | Mục đích |
|---|---|---|
| `deploy_glue` | `true` | Bật/tắt Glue |
| `glue_database_name` | `"mlops-data"` | Tên Glue database |
| `glue_enable_delta_lake` | `true` | Bật Delta Lake support |

**Cơ chế:** Module `glue` tạo Glue Catalog Database để lưu metadata (table schemas, partitions). Chi phí tính theo số objects stored và access requests (ước lượng 1M mỗi loại/tháng).

**File:** `data-engineering.tf` → `module "glue"` → `modules/glue/main.tf` (resource `aws_glue_catalog_database`)

---

### 2.18 AWS Glue Crawlers — $36.67/tháng

| Biến (terraform.tfvars) | Giá trị | Mục đích |
|---|---|---|
| `glue_create_crawler` | `true` | Tạo crawler |
| `glue_crawler_name` | `"data-crawler"` | Tên crawler |
| `glue_crawler_schedule` | `null` | Schedule (null = manual trigger) |
| `glue_crawler_s3_targets` | `[]` | S3 paths để crawl (cần set khi deploy) |

**Lưu ý:** ETL Job đã bị tắt (`glue_create_etl_job = false` — KH đang xóa). Chỉ còn Crawler và Data Catalog.

**Cơ chế:** Module `glue` tạo Glue Crawler để auto-discover schema từ S3 data. Crawler chạy manual hoặc theo schedule, scan S3 và cập nhật Data Catalog. Chi phí tính theo DPU-hours khi crawler chạy.

**File:** `data-engineering.tf` → `module "glue"` → `modules/glue/main.tf` (resource `aws_glue_crawler`)

---

### 2.19 Amazon RDS for PostgreSQL — $254.63/tháng

| Biến (terraform.tfvars) | Giá trị | Mục đích |
|---|---|---|
| `deploy_mlops_rds` | `true` | Bật/tắt RDS |
| `mlops_rds_name` | `"mlops-metadata"` | Tên DB identifier |
| `mlops_rds_engine_version` | `"16.8"` | PostgreSQL version |
| `mlops_rds_instance_class` | `"db.t4g.medium"` | Instance type (Graviton, current gen) |
| `mlops_rds_database_name` | `"mlops"` | Tên database |
| `mlops_rds_master_username` | `"mlopsadmin"` | Master username |
| `mlops_rds_backup_retention_period` | `7` | Backup retention (ngày) |

**Cấu hình hardcode trong mlops.tf:**
- `allocated_storage = 100` (GB)
- `storage_type = "gp2"`
- `multi_az = true` (High Availability)

**Cơ chế:** Module `rds-postgres` tạo RDS PostgreSQL instance. Password lưu trong Secrets Manager (auto-generated 32 chars, `recovery_window_in_days = 0` cho dev). Multi-AZ tạo standby replica ở AZ khác (chi phí gấp đôi single-AZ). Dùng làm metadata store cho MLflow/MLOps pipeline.

**Security Group:** RDS SG cho phép ingress port 5432 từ VPC CIDR `172.20.96.0/20`.

**File:** `mlops.tf` → `module "mlops_rds_postgres"` → `modules/rds-postgres/main.tf`

---

### 2.20 AWS CodeBuild — $9/tháng

| Biến (terraform.tfvars) | Giá trị | Mục đích |
|---|---|---|
| `deploy_sagemaker_codebuild` | `true` | Bật/tắt CodeBuild project |
| `sagemaker_codebuild_compute_type` | `"BUILD_GENERAL1_SMALL"` | Compute type |
| `sagemaker_codebuild_image` | `"aws/codebuild/amazonlinux2-x86_64-standard:5.0"` | x86 build image |

**Cơ chế:** 1 CodeBuild project:
- **sagemaker-model-deploy**: Deploy ML models lên SageMaker endpoint. Chạy Python script `scripts/deploy_model.py`. Compute type `BUILD_GENERAL1_SMALL`, không privileged mode.

Project chạy ngoài VPC (dùng internet mặc định) — không cần ECR VPC endpoints. Dùng KMS encryption. Chi phí tính theo build minutes (ước lượng 30 builds/tháng).

**File:** `cicd.tf` → `module "sagemaker_codebuild_deploy"` → `modules/codebuild/main.tf`

---

### 2.21 Amazon ECR — $5/tháng

| Biến (terraform.tfvars) | Giá trị | Mục đích |
|---|---|---|
| `create_ecr_repository` | `true` | Bật/tắt ECR repository |

**Cơ chế:** Module `ecr-repository` tạo ECR repository để lưu Docker images cho SageMaker inference containers. Có lifecycle policy giới hạn số images. Encryption bằng KMS (nếu `deploy_kms = true`). Scan on push enabled.

**File:** `sagemaker.tf` hoặc file riêng → `module "ecr"` → `modules/ecr-repository/main.tf`

---

## 3. Lưu Ý Quan Trọng

| # | Lưu ý | Chi tiết |
|---|---|---|
| 1 | **Endpoint chưa deploy** | `deploy_vision_model = false`, `deploy_text_model = false`. Set `true` khi sẵn sàng deploy |
| 2 | **Scheduler đã bật** | Lambda + EventBridge tự động tắt/bật endpoint 08:00-18:00 SGT, Mon-Fri |
| 3 | **Training chưa sẵn sàng** | `training_image = null` — module chỉ deploy khi `training_image != null` |
| 4 | **Data bucket chưa deploy** | `deploy_data_bucket = false` — set `true` khi cần |
| 5 | **Glue ETL Job đã tắt** | `glue_create_etl_job = false` — KH đang xóa |
| 6 | **Glue chưa cấu hình đầy đủ** | `glue_crawler_s3_targets = []` cần set khi deploy |
| 7 | **S3 Gateway endpoint tắt** | `create_s3_gateway = false` — S3 access đi qua NAT Gateway |
| 8 | **NAT Gateway đã bật** | `create_nat_gateway = true` — cung cấp internet access cho private subnets |
| 9 | **AWS Config tắt** | `deploy_aws_config = false` — không có S3 bucket riêng |
| 10 | **Transit Gateway tắt** | `deploy_transit_gateway_attachment = false` |
| 11 | **EC2 Test Instance tắt** | `deploy_test_instance = false` |


---

## 4. Danh Sách S3 Buckets

| # | Bucket Name | Module | Mục đích | Encryption | Versioning | Đặc biệt |
|---|-------------|--------|----------|------------|------------|-----------|
| 1 | `{name_prefix}-{environment}-models-{region}-{random_hex}` | `s3-model-storage` | Lưu model artifacts, training data, feature store offline, monitoring output, scheduler state, Spark logs | KMS (nếu `deploy_kms=true`), fallback AES256 | Enabled | Lifecycle: xóa noncurrent versions sau 30 ngày, abort incomplete uploads sau 7 ngày. `force_destroy = true` |
| 2 | `rrth-mh-bds` | `s3-data-bucket` | Data bucket chính cho dự án rrth-mh-bds (chưa deploy) | KMS (nếu `deploy_kms=true`) | Enabled | VPC Endpoint policy restrict access. `force_destroy = true` (dev). `deploy_data_bucket = false` |

**Với giá trị hiện tại (`name_prefix = "rrth-mh-bds"`, `environment = "dev"`, `region = "ap-southeast-1"`):**
- Bucket 1: `rrth-mh-bds-dev-models-ap-southeast-1-{8_hex_chars}`
- Bucket 2: `rrth-mh-bds` (chưa tạo — `deploy_data_bucket = false`)

**Cấu trúc thư mục trong bucket model-storage:**

```
s3://rrth-mh-bds-dev-models-ap-southeast-1-xxxxxxxx/
├── qwen2.5-vl-7b/
│   └── model.tar.gz                    # Vision model artifacts
├── qwen3-30b-a3b-instruct-2507-fp8/
│   └── model.tar.gz                    # Text model artifacts
├── feature-store/                       # Feature Store offline data
├── monitoring/                          # Model monitoring output
├── studio-outputs/                      # SageMaker Studio notebook outputs
├── training-data/                       # Training input data
├── model-artifacts/                     # Training output (trained models)
├── sagemaker-scheduler/
│   └── endpoints/
│       └── {endpoint_name}/
│           ├── config.json              # Endpoint config (saved by scheduler Lambda)
│           └── autoscaling.json         # Autoscaling config (saved by scheduler Lambda)
├── spark-logs/                          # Glue ETL Spark event logs
├── temp/                                # Glue ETL temp directory
├── pipelines/
│   └── definition.json                 # SageMaker Pipeline definition
└── codebuild-logs/                      # CodeBuild S3 logs (nếu bật)
```

---

## 5. Danh Sách Endpoints

### 5.1 SageMaker Endpoints (Real-Time Inference)

| # | Endpoint Name | Instance Type | Instances | Model | Auto Schedule | Trạng thái |
|---|---------------|---------------|-----------|-------|---------------|------------|
| 1 | `rrth-mh-bds-dev-qwen2-5-vl-7b` | ml.c5.xlarge | 2 | Qwen2.5-VL-7B-Instruct (Vision) | ✅ Tắt 18:00, bật 08:00 SGT Mon-Fri | `deploy_vision_model = false` (chưa deploy) |
| 2 | `rrth-mh-bds-dev-qwen3-30b-a3b-instruct-2507-fp8` | ml.m5.xlarge | 2 | Qwen3-30B-A3B-Instruct-2507-FP8 (Text, MoE) | ✅ Tắt 18:00, bật 08:00 SGT Mon-Fri | `deploy_text_model = false` (chưa deploy) |

**Cấu hình endpoint:**
- Production variant: `AllTraffic` (100% traffic)
- Container: LMI `djl-inference:0.33.0-lmi15.0.0-cu128`
- VPC: Private subnets + SageMaker security group
- Tag `AutoSchedule = true` → Lambda scheduler tự động tắt/bật
- Text model: MoE (`is_moe_text_model = true`), async mode, Hermes tool call parser

**Cơ chế tắt/bật (Lambda Scheduler):**
```
EventBridge cron(0 1 ? * MON-FRI *)     EventBridge cron(0 11 ? * MON-FRI *)
         │ 08:00 SGT                              │ 18:00 SGT
         ▼                                        ▼
   Lambda START                              Lambda STOP
         │                                        │
         ├─ Đọc config từ S3                      ├─ Lưu endpoint config → S3
         ├─ Tạo lại Endpoint Config               ├─ Lưu autoscaling config → S3
         ├─ Tạo lại Endpoint                      └─ Xóa Endpoint
         └─ Restore Autoscaling
```

### 5.2 SageMaker Studio Endpoint

| # | Resource | Type | Giá trị |
|---|----------|------|---------|
| 1 | Studio Domain | `rrth-mh-bds-dev-studio` | VPC mode, IAM auth |
| 2 | User Profile | `data-scientist-1` | Kernel: ml.m5.xlarge |

**URL:** Output `sagemaker_studio_url` sau khi deploy

### 5.3 API Gateway Endpoint

| # | Resource | Giá trị |
|---|----------|---------|
| 1 | API Name | `rrth-mh-bds-dev-inference` |
| 2 | Type | REST API, REGIONAL |
| 3 | Stage | `v1` |
| 4 | URL | `https://{api_id}.execute-api.ap-southeast-1.amazonaws.com/v1` |

**Routes:**

| Method | Path | Backend | Mục đích |
|--------|------|---------|----------|
| GET | `/v1/test` | Lambda `api` | Test connection |
| POST | `/v1/test` | Lambda `api` | Test connection |
| POST | `/v1/inference` | Lambda `inference` | Model inference (khi SageMaker deployed) |

**Bảo vệ:** WAF Web ACL → API Gateway Stage (SQL injection, rate limiting, common rules)

### 5.4 RDS Endpoint

| # | Resource | Giá trị |
|---|----------|---------|
| 1 | DB Identifier | `rrth-mh-bds-dev-mlops-metadata` |
| 2 | Engine | PostgreSQL 16.8 |
| 3 | Instance | db.t4g.medium (Graviton) |
| 4 | Endpoint | `rrth-mh-bds-dev-mlops-metadata.xxxxxxxx.ap-southeast-1.rds.amazonaws.com:5432` |
| 5 | Database | `mlops` |
| 6 | Username | `mlopsadmin` |
| 7 | Password | Secrets Manager (auto-generated 32 chars) |

**Kết nối:** Chỉ từ VPC CIDR `172.20.96.0/20` qua port 5432 (RDS security group)

### 5.5 VPC Endpoints (PrivateLink)

| # | Service | Type | Endpoint Name | Mục đích | Phí |
|---|---------|------|---------------|----------|-----|
| 1 | `com.amazonaws.ap-southeast-1.sagemaker.api` | Interface | `*-sagemaker-api-endpoint` | SageMaker API calls (CreateEndpoint, etc.) | ~$7.20/tháng/AZ |
| 2 | `com.amazonaws.ap-southeast-1.sagemaker.runtime` | Interface | `*-sagemaker-runtime-endpoint` | SageMaker inference calls (InvokeEndpoint) | ~$7.20/tháng/AZ |
| 3 | `com.amazonaws.ap-southeast-1.logs` | Interface | `*-logs-endpoint` | CloudWatch Logs | ~$7.20/tháng/AZ |
| 4 | `com.amazonaws.ap-southeast-1.secretsmanager` | Interface | `*-secretsmanager-endpoint` | Secrets Manager (RDS password) | ~$7.20/tháng/AZ |
| 5 | `com.amazonaws.ap-southeast-1.execute-api` | Interface | `*-execute-api-endpoint` | API Gateway private access | ~$7.20/tháng/AZ |
| 6 | `com.amazonaws.ap-southeast-1.lambda` | Interface | `*-lambda-endpoint` | Lambda private access | ~$7.20/tháng/AZ |

**Không tạo S3 endpoints** — `create_s3_gateway = false`, `create_s3_interface = false`. S3 access đi qua NAT Gateway.

**Không tạo ECR endpoints** (`ecr.api` + `ecr.dkr`) — CodeBuild chạy ngoài VPC nên không cần. Tiết kiệm ~$20.98/tháng.

### 5.6 ECR Repository

| # | Resource | Giá trị |
|---|----------|---------|
| 1 | Repository | `rrth-mh-bds-dev-inference` |
| 2 | Encryption | KMS |
| 3 | Scan on push | Enabled |
| 4 | Lifecycle | Giới hạn số images (expire cũ) |

**URI:** `{account_id}.dkr.ecr.ap-southeast-1.amazonaws.com/rrth-mh-bds-dev-inference`


---

## 6. Các Cơ Chế Hoạt Động

### 6.1 Cơ Chế Inference (Request Flow)

```
Client (External)
    │
    ▼
AWS WAF (Web ACL)
    │ Filter: SQL injection, bad inputs, rate limit 2000 req/5min/IP
    ▼
API Gateway (REST, REGIONAL)
    │ Stage: /v1
    │ Throttle: burst=100, rate=50 req/s
    ▼
Lambda (api / inference)
    │ Python 3.12, 128MB, 30s timeout
    │ Layer: AWSSDKPandas-Python311
    ▼
SageMaker Endpoint (Real-Time Inference)
    │ ml.c5.xlarge (vision) / ml.m5.xlarge (text)
    │ 2 instances, LMI container (vLLM engine)
    ▼
Response → API Gateway → Client
```

**Biến liên quan:** `deploy_api_gateway`, `deploy_waf`, `deploy_vision_model`, `deploy_text_model`

---

### 6.2 Cơ Chế Endpoint Scheduler (Tiết Kiệm Chi Phí)

```
EventBridge Rule (cron)
    │
    ├── 08:00 SGT (Mon-Fri) ──► Lambda "sagemaker-scheduler" ──► action: START
    │                                │
    │                                ├─ List saved configs trong S3 (tag AutoSchedule=true)
    │                                ├─ Tạo lại Endpoint Config từ saved state
    │                                ├─ Tạo lại Endpoint
    │                                ├─ Chờ InService (max 10 phút)
    │                                └─ Restore Autoscaling policies
    │
    └── 18:00 SGT (Mon-Fri) ──► Lambda "sagemaker-scheduler" ──► action: STOP
                                     │
                                     ├─ List endpoints có tag AutoSchedule=true
                                     ├─ Lưu endpoint config → S3 (config.json)
                                     ├─ Lưu autoscaling config → S3 (autoscaling.json)
                                     └─ Xóa endpoint hoàn toàn (delete, không scale về 0)
```

**Tại sao xóa thay vì scale về 0?** SageMaker Real-Time Inference không hỗ trợ scale về 0 instances. Phải xóa endpoint hoàn toàn để ngừng tính phí.

**Biến liên quan:** `enable_endpoint_scheduler`, `scheduler_start_cron`, `scheduler_stop_cron`, `schedule_on_off_text_endpoint`, `schedule_on_off_vision_endpoint`

---

### 6.3 Cơ Chế Training (MLOps Pipeline)

```
Trigger (Manual hoặc EventBridge Schedule)
    │
    ▼
Step Functions State Machine
    │
    ├─ Step 1: CreateTrainingJob
    │     │ Instance: ml.m5.2xlarge × 1
    │     │ Input: s3://.../training-data/
    │     │ Output: s3://.../model-artifacts/
    │     │ VPC: private subnets + SG
    │     └─ Chờ training hoàn thành
    │
    ├─ Step 2: CreateModel
    │     │ Đăng ký model từ training output
    │     └─ Container: training image hoặc inference image
    │
    └─ Step 3: (Optional) Update Endpoint
          └─ Deploy model mới lên endpoint
```

**Lưu ý:** Hiện tại `training_image = null` nên module chưa được tạo (điều kiện: `deploy_sagemaker_training && training_image != null`).

**Biến liên quan:** `deploy_sagemaker_training`, `training_instance_type`, `training_instance_count`, `training_volume_size`, `enable_scheduled_training`, `training_schedule`

---

### 6.4 Cơ Chế Model Monitoring

```
SageMaker Monitoring Schedule
    │ cron(0 * ? * * *) = mỗi giờ
    ▼
Data Quality Job
    │ Instance: ml.c5.xlarge × 1
    │
    ├─ Input: Capture data từ endpoint (real-time requests/responses)
    ├─ So sánh data distribution với baseline
    ├─ Output: s3://.../monitoring/ (statistics, violations)
    └─ CloudWatch Metrics: data quality metrics
```

**Lưu ý:** Monitoring chỉ deploy khi `deploy_mlops_model_monitoring = true` VÀ (`deploy_text_model || deploy_vision_model`). Hiện tại cả 2 model đều `false` nên monitoring chưa tạo.

**Biến liên quan:** `deploy_mlops_model_monitoring`, `mlops_monitoring_instance_type`, `mlops_monitoring_instance_count`, `mlops_monitoring_schedule_expression`

---

### 6.5 Cơ Chế CI/CD (Model Deploy)

```
CodeBuild Project: "sagemaker-model-deploy"
    │ x86 container, BUILD_GENERAL1_SMALL
    │ Image: aws/codebuild/amazonlinux2-x86_64-standard:5.0
    │ Chạy ngoài VPC (dùng internet mặc định)
    │
    └─ Build: python scripts/deploy_model.py
         │
         ├─ CreateModel (từ ECR image + S3 model artifacts)
         ├─ CreateEndpointConfig
         └─ CreateEndpoint / UpdateEndpoint
```

**Biến liên quan:** `deploy_sagemaker_codebuild`, `sagemaker_codebuild_compute_type`, `sagemaker_codebuild_image`

---

### 6.6 Cơ Chế Feature Store

```
Application / Training Job
    │
    ├─── Write ──► Online Store (DynamoDB-backed)
    │                 │ Low-latency reads (<10ms)
    │                 │ Record: customer_id + event_time + features
    │                 └─ Dùng cho real-time inference
    │
    └─── Sync ──► Offline Store (S3-backed)
                      │ s3://.../feature-store/
                      │ Parquet format, partitioned by date
                      └─ Dùng cho batch training, analytics
```

**Biến liên quan:** `deploy_mlops_feature_store`, `mlops_feature_enable_online_store`, `mlops_feature_enable_offline_store`, `mlops_feature_definitions`

---

### 6.7 Cơ Chế ETL (Glue)

```
Glue Crawler (manual trigger)
    │ Scan S3 data sources
    │ Auto-discover schema
    ▼
Glue Data Catalog
    │ Database: mlops-data
    │ Tables: auto-created by crawler
    │ Delta Lake support: enabled
    ▼
(ETL Job disabled — glue_create_etl_job = false)
```

**Lưu ý:** ETL Job đã bị tắt (`glue_create_etl_job = false` — KH đang xóa). Chỉ còn Crawler + Data Catalog + Delta Lake support.

**Biến liên quan:** `deploy_glue`, `glue_create_crawler`, `glue_create_etl_job`, `glue_enable_delta_lake`

---

### 6.8 Cơ Chế Security & Encryption

```
KMS Keys (5 CMKs tách riêng theo service group)
    │
    ├─► kms_key_s3 ──► S3 Buckets (server-side encryption)
    ├─► kms_key_rds ──► RDS PostgreSQL (storage encryption) + Secrets Manager
    ├─► kms_key_sagemaker ──► SageMaker (training volumes, endpoints)
    ├─► kms_key_logs ──► CloudTrail + CloudWatch Logs + VPC Flow Logs
    └─► kms_key_ecr ──► ECR images + CodeBuild artifacts

Secrets Manager
    │
    └─► RDS master password (auto-generated 32 chars, recovery_window = 0 for dev)
```

**Biến liên quan:** `deploy_kms`

---

### 6.9 Cơ Chế Network Security

```
VPC: 172.20.96.0/20 (ACB-AI-Scoring-dev-vpc)
    │ create_vpc = true (managed by Terraform)
    │
    ├── Public Subnet 1: 172.20.97.0/24 (ap-southeast-1a)
    ├── Public Subnet 2: 172.20.98.0/24 (ap-southeast-1b)
    ├── Private Subnet 1: 172.20.99.0/24 (ap-southeast-1a)
    ├── Private Subnet 2: 172.20.100.0/24 (ap-southeast-1b)
    │
    ├── NAT Gateway: Enabled (create_nat_gateway = true)
    │     └─ Public subnet: subnet-0ebdfdd3b99947e26
    │
    ├── Security Groups:
    │     ├─ SageMaker SG: Ingress 443 từ VPC CIDR, Egress 443 to VPC CIDR
    │     ├─ RDS SG: Ingress 5432 từ VPC CIDR, No egress
    │     ├─ Glue SG: Self-referencing + HTTPS + PostgreSQL egress
    │     ├─ Lambda SG: Egress 443 (VPC endpoints) + 5432 (RDS)
    │     ├─ VPC Endpoints SG: Ingress 443 từ VPC CIDR
    │     ├─ ALB SG: Ingress 443 từ VPC CIDR
    │     └─ EIC SG: Egress SSH to VPC
    │
    ├── VPC Endpoints (private access, không qua Internet):
    │     ├─ SageMaker API + Runtime
    │     ├─ CloudWatch Logs
    │     ├─ Secrets Manager
    │     ├─ API Gateway (execute-api)
    │     └─ Lambda
    │
    └── Egress Control:
          └─ restrict_egress_to_vpc = true (chỉ cho traffic trong VPC CIDR)
```

**Biến liên quan:** `vpc_id`, `subnet_ids`, `vpc_cidr_block`, `restrict_egress_to_vpc`, `create_vpc_endpoints`, `create_vpc`, `create_nat_gateway`

---

### 6.10 Cơ Chế Audit & Compliance

```
CloudTrail (1 trail, multi-region)
    │ Management events: All (read + write)
    │ Data events: Không bật
    ▼
CloudWatch Logs + S3 Bucket (auto-created)
    │ CloudWatch Retention: 90 ngày
    │ S3 Lifecycle: Archive 90 ngày, xóa 365 ngày
    │ Encryption: KMS

VPC Flow Logs
    │ Traffic type: ALL (accept + reject)
    ▼
CloudWatch Logs
    │ Retention: 90 ngày
    │ Encryption: KMS

WAF Logs
    │ All requests qua API Gateway
    ▼
CloudWatch Logs
    │ Retention: 30 ngày
```

**Biến liên quan:** `deploy_cloudtrail`, `deploy_vpc_flow_logs`, `cloudtrail_log_retention_days`, `vpc_flow_logs_retention_days`, `waf_enable_logging`, `waf_log_retention_days`

---

### 6.11 Cơ Chế Backup & Recovery

```
AWS Backup
    │
    ├── Daily: cron(0 5 ? * * *) = 12:00 SGT
    │     │ Retention: 35 ngày
    │     └─ Targets: RDS + S3 model storage (+ data bucket nếu deploy)
    │
    ├── Weekly (nếu bật):
    │     └─ Retention: 90 ngày
    │
    └── Monthly (nếu bật):
          └─ Retention: 365 ngày → Cold storage

RDS Native Backup
    │ Automated snapshots
    │ Retention: 7 ngày
    └─ Included trong RDS pricing (miễn phí ≤ allocated storage)
```

**Biến liên quan:** `deploy_backup`, `backup_daily_schedule`, `backup_daily_retention_days`, `backup_enable_weekly`, `backup_enable_monthly`, `mlops_rds_backup_retention_period`

---

### 6.12 Cơ Chế Location Service

```
Application
    │
    ├─► Place Index (Esri, SingleUse)
    │     └─ Geocoding: address → coordinates
    │     └─ Reverse geocoding: coordinates → address
    │     └─ Search: tìm địa điểm
    │
    └─► Map Resource (VectorEsriStreets)
          └─ Render bản đồ vector
          └─ Dynamic tiles cho web/mobile app
```

**Provider:** `aws.location` (region: ap-southeast-1, cùng region chính)

**Biến liên quan:** `deploy_location_service`, `location_service_region`, `location_create_place_index`, `location_create_map`, `location_data_source`
