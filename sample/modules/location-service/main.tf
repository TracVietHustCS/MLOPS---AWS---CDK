# =============================================================================
# AWS Location Service Module
# =============================================================================
# Provides geocoding, maps, tracking, geofencing, and routing capabilities
# =============================================================================

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# -----------------------------------------------------------------------------
# Place Index (Geocoding/Search)
# -----------------------------------------------------------------------------
resource "aws_location_place_index" "this" {
  count = var.create_place_index ? 1 : 0

  index_name  = "${var.name_prefix}-${var.environment}-place-index"
  data_source = var.place_index_data_source # "Esri" or "Here"

  data_source_configuration {
    intended_use = var.place_index_intended_use # "SingleUse" or "Storage"
  }

  description = "Place index for geocoding - ${var.environment}"

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-place-index"
      Environment = var.environment
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# Map Resource
# -----------------------------------------------------------------------------
resource "aws_location_map" "this" {
  count = var.create_map ? 1 : 0

  map_name = "${var.name_prefix}-${var.environment}-map"

  configuration {
    style = var.map_style # e.g., "VectorEsriStreets", "VectorHereExplore"
  }

  description = "Map resource - ${var.environment}"

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-map"
      Environment = var.environment
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# Tracker (Device Tracking)
# -----------------------------------------------------------------------------
resource "aws_location_tracker" "this" {
  count = var.create_tracker ? 1 : 0

  tracker_name       = "${var.name_prefix}-${var.environment}-tracker"
  position_filtering = var.tracker_position_filtering # "TimeBased", "DistanceBased", "AccuracyBased"
  kms_key_id         = var.kms_key_id
  description        = "Device tracker - ${var.environment}"

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-tracker"
      Environment = var.environment
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# Geofence Collection
# -----------------------------------------------------------------------------
resource "aws_location_geofence_collection" "this" {
  count = var.create_geofence_collection ? 1 : 0

  collection_name = "${var.name_prefix}-${var.environment}-geofences"
  kms_key_id      = var.kms_key_id
  description     = "Geofence collection - ${var.environment}"

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-geofences"
      Environment = var.environment
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# Tracker-Geofence Association
# -----------------------------------------------------------------------------
resource "aws_location_tracker_association" "this" {
  count = var.create_tracker && var.create_geofence_collection ? 1 : 0

  tracker_name = aws_location_tracker.this[0].tracker_name
  consumer_arn = aws_location_geofence_collection.this[0].collection_arn
}

# -----------------------------------------------------------------------------
# Route Calculator
# -----------------------------------------------------------------------------
resource "aws_location_route_calculator" "this" {
  count = var.create_route_calculator ? 1 : 0

  calculator_name = "${var.name_prefix}-${var.environment}-route-calc"
  data_source     = var.route_calculator_data_source # "Esri" or "Here"
  description     = "Route calculator - ${var.environment}"

  tags = merge(
    {
      Name        = "${var.name_prefix}-${var.environment}-route-calc"
      Environment = var.environment
    },
    var.tags
  )
}
