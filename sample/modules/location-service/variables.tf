# =============================================================================
# AWS Location Service Variables
# =============================================================================

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

variable "kms_key_id" {
  description = "KMS key ID for encryption (tracker and geofence)"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Place Index (Geocoding)
# -----------------------------------------------------------------------------
variable "create_place_index" {
  description = "Create Place Index for geocoding"
  type        = bool
  default     = true
}

variable "place_index_data_source" {
  description = "Data source for Place Index: Esri or Here"
  type        = string
  default     = "Esri"
}

variable "place_index_intended_use" {
  description = "Intended use: SingleUse (no storage) or Storage (can store results)"
  type        = string
  default     = "SingleUse"
}

# -----------------------------------------------------------------------------
# Map
# -----------------------------------------------------------------------------
variable "create_map" {
  description = "Create Map resource"
  type        = bool
  default     = true
}

variable "map_style" {
  description = "Map style (VectorEsriStreets, VectorEsriNavigation, VectorHereExplore, etc.)"
  type        = string
  default     = "VectorEsriStreets"
}

# -----------------------------------------------------------------------------
# Tracker
# -----------------------------------------------------------------------------
variable "create_tracker" {
  description = "Create Tracker for device tracking"
  type        = bool
  default     = false
}

variable "tracker_position_filtering" {
  description = "Position filtering: TimeBased, DistanceBased, or AccuracyBased"
  type        = string
  default     = "TimeBased"
}

# -----------------------------------------------------------------------------
# Geofence Collection
# -----------------------------------------------------------------------------
variable "create_geofence_collection" {
  description = "Create Geofence Collection"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Route Calculator
# -----------------------------------------------------------------------------
variable "create_route_calculator" {
  description = "Create Route Calculator"
  type        = bool
  default     = false
}

variable "route_calculator_data_source" {
  description = "Data source for Route Calculator: Esri or Here"
  type        = string
  default     = "Esri"
}
