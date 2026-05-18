# =============================================================================
# AWS Location Service Outputs
# =============================================================================

output "place_index_name" {
  description = "Place Index name"
  value       = var.create_place_index ? aws_location_place_index.this[0].index_name : null
}

output "place_index_arn" {
  description = "Place Index ARN"
  value       = var.create_place_index ? aws_location_place_index.this[0].index_arn : null
}

output "map_name" {
  description = "Map name"
  value       = var.create_map ? aws_location_map.this[0].map_name : null
}

output "map_arn" {
  description = "Map ARN"
  value       = var.create_map ? aws_location_map.this[0].map_arn : null
}

output "tracker_name" {
  description = "Tracker name"
  value       = var.create_tracker ? aws_location_tracker.this[0].tracker_name : null
}

output "tracker_arn" {
  description = "Tracker ARN"
  value       = var.create_tracker ? aws_location_tracker.this[0].tracker_arn : null
}

output "geofence_collection_name" {
  description = "Geofence Collection name"
  value       = var.create_geofence_collection ? aws_location_geofence_collection.this[0].collection_name : null
}

output "geofence_collection_arn" {
  description = "Geofence Collection ARN"
  value       = var.create_geofence_collection ? aws_location_geofence_collection.this[0].collection_arn : null
}

output "route_calculator_name" {
  description = "Route Calculator name"
  value       = var.create_route_calculator ? aws_location_route_calculator.this[0].calculator_name : null
}

output "route_calculator_arn" {
  description = "Route Calculator ARN"
  value       = var.create_route_calculator ? aws_location_route_calculator.this[0].calculator_arn : null
}
