terraform {
  required_version = ">= 1.0"
  
  required_providers {
    exoscale = {
      source  = "exoscale/exoscale"
      version = "~> 0.62"
    }
  }
}

provider "exoscale" {
  key    = var.exoscale_api_key
  secret = var.exoscale_api_secret
}

