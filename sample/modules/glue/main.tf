# =============================================================================
# AWS Glue Module
# =============================================================================
# ETL dữ liệu từ hệ thống nguồn (on-premise/PASS) lên AWS và giữa các store
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# Glue Database (Data Catalog)
# -----------------------------------------------------------------------------
resource "aws_glue_catalog_database" "this" {
  name        = lower("${var.name_prefix}-${var.environment}-${var.database_name}")
  description = var.database_description

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-${var.database_name}"
      Environment = var.environment
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# Glue Crawler (Auto-discover schema)
# -----------------------------------------------------------------------------
resource "aws_glue_crawler" "this" {
  count         = var.create_crawler && length(var.crawler_s3_targets) > 0 ? 1 : 0
  name          = "${var.name_prefix}-${var.environment}-${var.crawler_name}"
  database_name = aws_glue_catalog_database.this.name
  role          = var.glue_role_arn != null ? var.glue_role_arn : aws_iam_role.glue[0].arn
  schedule      = var.crawler_schedule

  dynamic "s3_target" {
    for_each = var.crawler_s3_targets
    content {
      path       = s3_target.value.path
      exclusions = lookup(s3_target.value, "exclusions", [])
    }
  }

  schema_change_policy {
    delete_behavior = var.crawler_delete_behavior
    update_behavior = var.crawler_update_behavior
  }

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-${var.crawler_name}"
      Environment = var.environment
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# Glue ETL Job
# -----------------------------------------------------------------------------
resource "aws_glue_job" "this" {
  count    = var.create_etl_job ? 1 : 0
  name     = "${var.name_prefix}-${var.environment}-${var.job_name}"
  role_arn = var.glue_role_arn != null ? var.glue_role_arn : aws_iam_role.glue[0].arn

  command {
    name            = "glueetl"
    script_location = var.job_script_location != null ? var.job_script_location : "s3://placeholder/scripts/etl.py"
    python_version  = var.job_python_version
  }

  default_arguments = merge(
    {
      "--job-language"          = "python"
      "--enable-metrics"        = "true"
      "--enable-spark-ui"       = "true"
      "--spark-event-logs-path" = "s3://${var.job_logs_bucket}/spark-logs/"
      "--TempDir"               = "s3://${var.job_logs_bucket}/temp/"
    },
    # Delta Lake configuration (Glue 4.0+ native support)
    var.enable_delta_lake ? {
      "--datalake-formats"        = "delta"
      "--conf"                    = "spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension --conf spark.sql.catalog.${var.delta_lake_catalog_name}=org.apache.spark.sql.delta.catalog.DeltaCatalog"
      "--enable-glue-datacatalog" = "true"
    } : {},
    var.job_default_arguments
  )

  glue_version      = var.glue_version
  worker_type       = var.job_worker_type
  number_of_workers = var.job_number_of_workers
  timeout           = var.job_timeout
  max_retries       = var.job_max_retries

  execution_property {
    max_concurrent_runs = var.job_max_concurrent_runs
  }

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-${var.job_name}"
      Environment = var.environment
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# Glue Connection (for JDBC sources like RDS, on-premise DB)
# -----------------------------------------------------------------------------
resource "aws_glue_connection" "this" {
  count           = var.create_connection ? 1 : 0
  name            = "${var.name_prefix}-${var.environment}-${var.connection_name}"
  connection_type = var.connection_type

  connection_properties = var.connection_properties

  physical_connection_requirements {
    availability_zone      = var.connection_availability_zone
    security_group_id_list = var.connection_security_group_ids
    subnet_id              = var.connection_subnet_id
  }

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-${var.connection_name}"
      Environment = var.environment
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# Default IAM Role for Glue
# -----------------------------------------------------------------------------
resource "aws_iam_role" "glue" {
  count                = var.glue_role_arn == null ? 1 : 0
  name                 = "${var.name_prefix}-${var.environment}-glue-role"
  permissions_boundary = var.permissions_boundary

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "glue.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "glue_service" {
  count      = var.glue_role_arn == null ? 1 : 0
  role       = aws_iam_role.glue[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy" "glue_s3" {
  count = var.glue_role_arn == null ? 1 : 0
  name  = "glue-s3-access"
  role  = aws_iam_role.glue[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = var.s3_access_arns
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:/aws-glue/*"
      }
    ]
  })
}
