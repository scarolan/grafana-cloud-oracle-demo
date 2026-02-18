# =============================================================================
# Terraform Resources — Add your demo resources here
# =============================================================================
# This file is intentionally empty. Add resources and modules as needed
# for your demo scenario. Examples:
#
# --- AWS RDS Instance ---
# resource "aws_db_instance" "demo" {
#   identifier     = "${var.demo_name}-db"
#   engine         = "postgres"
#   engine_version = "15"
#   instance_class = "db.t3.micro"
#   ...
# }
#
# --- Azure Container Instance ---
# resource "azurerm_container_group" "demo" {
#   name                = "${var.demo_name}-aci"
#   location            = var.azure_location
#   resource_group_name = var.azure_resource_group
#   os_type             = "Linux"
#   ...
# }
#
# --- GCP Cloud Run Service ---
# resource "google_cloud_run_service" "demo" {
#   name     = var.demo_name
#   location = var.gcp_region
#   ...
# }
