# S3 Backend Configuration for ap-northeast-3 (Osaka)
# Terraform 1.8+ supports native state locking without DynamoDB

bucket       = "<BUCKET_NAME>"
key          = "<STATE_KEY>"
region       = "<AWS_REGION>"
encrypt      = true
use_lockfile = true # Native S3 state locking (Terraform 1.8+)
