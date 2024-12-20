terraform {
  required_version = "1.10.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0" # Adjust this version as needed
    }
  }
}

provider "azurerm" {
  features {} # This block goes here, not in the required_providers block
}

# Define the provider
provider "azurerm" {
  alias = "subscription1"
  features {}
  subscription_id = "03c8d8e5-2220-4f95-8639-ad155eee1ba7" # Ensure this ID is for Subscription 1
}

provider "azurerm" {
  alias = "subscription2"
  features {}
  subscription_id = "31b7070b-7ad9-4790-baa2-8edd999fa4b4" # Ensure this ID is for Subscription 2
}