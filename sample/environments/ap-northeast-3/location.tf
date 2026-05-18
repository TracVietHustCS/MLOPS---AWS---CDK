# =============================================================================
# AWS Location Service
# =============================================================================
# Provides geocoding, maps, tracking, geofencing, and routing capabilities
# NOTE: Location Service is NOT available in ap-northeast-3 (Osaka)
# Deploying in us-east-1 instead
# =============================================================================

module "location_service" {
  source = "../../modules/location-service"
  count  = var.deploy_location_service ? 1 : 0

  providers = {
    aws = aws.location
  }

  name_prefix = var.name_prefix
  environment = var.environment

  # Place Index (Geocoding)
  create_place_index       = var.location_create_place_index
  place_index_data_source  = var.location_data_source
  place_index_intended_use = "SingleUse"

  # Map
  create_map = var.location_create_map
  map_style  = var.location_data_source == "Esri" ? "VectorEsriStreets" : "VectorHereExplore"

  # Tracker
  create_tracker             = var.location_create_tracker
  tracker_position_filtering = "TimeBased"
  kms_key_id                 = null  # KMS key is in different region, cannot use cross-region

  # Geofence Collection
  create_geofence_collection = var.location_create_geofence_collection

  # Route Calculator
  create_route_calculator      = var.location_create_route_calculator
  route_calculator_data_source = var.location_data_source

  tags = var.tags
}
