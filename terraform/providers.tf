# =============================================================================
# Terraform Providers — Uncomment the provider(s) your demo needs
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  # required_providers {
  #   # --- AWS ---
  #   aws = {
  #     source  = "hashicorp/aws"
  #     version = "~> 5.0"
  #   }
  #
  #   # --- Azure ---
  #   azurerm = {
  #     source  = "hashicorp/azurerm"
  #     version = "~> 3.0"
  #   }
  #
  #   # --- Google Cloud ---
  #   google = {
  #     source  = "hashicorp/google"
  #     version = "~> 5.0"
  #   }
  #
  #   # --- Grafana ---
  #   grafana = {
  #     source  = "grafana/grafana"
  #     version = "~> 3.0"
  #   }
  # }
}

# --- AWS Provider ---
# provider "aws" {
#   region = var.aws_region
# }

# --- Azure Provider ---
# provider "azurerm" {
#   features {}
# }

# --- Google Cloud Provider ---
# provider "google" {
#   project = var.gcp_project
#   region  = var.gcp_region
# }

# --- Grafana Provider ---
# provider "grafana" {
#   url  = var.grafana_url
#   auth = var.grafana_api_key
# }
