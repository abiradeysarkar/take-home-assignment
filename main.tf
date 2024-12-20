# Get the current Azure client configuration to fetch tenant_id
data "azurerm_client_config" "azure_tenant" {

}

# Set initial configurations for both subscriptions
resource "azurerm_resource_group" "subscription1_initial_rg" {
  name     = "Tenant1ResourceGroup"
  location = "East US"
  # Use the provider scoped to Subscription 1
  provider = azurerm.subscription1
}

resource "azurerm_resource_group" "subscription2_initial_rg" {
  name     = "Tenant2ResourceGroup"
  location = "West US"
  # Use the provider scoped to Subscription 1
  provider = azurerm.subscription2
}

# Enable basic services (e.g., Storage Account for logging)
resource "azurerm_storage_account" "subscription1_storage" {
  name                     = "storageaccttenant1"
  resource_group_name      = azurerm_resource_group.subscription1_initial_rg.name
  location                 = azurerm_resource_group.subscription1_initial_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  # Use the provider scoped to Subscription 1
  provider = azurerm.subscription1
}

resource "azurerm_storage_account" "subscription2_storage" {
  name                     = "storageaccttenant2"
  resource_group_name      = azurerm_resource_group.subscription2_initial_rg.name
  location                 = azurerm_resource_group.subscription2_initial_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  # Use the provider scoped to Subscription 1
  provider = azurerm.subscription2
}

# Custom RBAC role
resource "azurerm_role_definition" "custom_reader_writer_ml" {
  name        = "CustomReaderWriterML"
  description = "Read access to all resources and write access to Azure Machine Learning resources"
  scope       = "/subscriptions/${var.subscription_id1}"
  permissions {
    actions = [
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.Resources/resources/read",
      "Microsoft.MachineLearningServices/workspaces/*/delete",
      "Microsoft.MachineLearningServices/workspaces/write",
      "Microsoft.MachineLearningServices/workspaces/computes/*/write",
      "Microsoft.MachineLearningServices/workspaces/computes/*/delete",
      "Microsoft.Authorization/*/write"
    ]
    not_actions = [
      "Microsoft.Billing/*"
    ]
  }

  assignable_scopes = [
    "/subscriptions/03c8d8e5-2220-4f95-8639-ad155eee1ba7", # Subscription 1
    "/subscriptions/31b7070b-7ad9-4790-baa2-8edd999fa4b4"  # Subscription 2
  ]
}

# Create a budget for each subscription
resource "azurerm_consumption_budget_subscription" "subscription_budget" {
  for_each        = var.subscriptions
  name            = each.value.budget_name
  subscription_id = each.value.subscription_id
  amount          = each.value.amount
  time_grain      = "Monthly"

  # Define the time period for the budget
  time_period {
    start_date = each.value.start_date
    end_date   = each.value.end_date
  }

  # Notifications for thresholds
  notification {
    enabled        = true
    operator       = "GreaterThanOrEqualTo"
    threshold      = 50
    contact_emails = ["abiradey92@gmail.com"]
  }

  notification {
    enabled        = true
    operator       = "GreaterThanOrEqualTo"
    threshold      = 75
    contact_emails = ["abiradey92@gmail.com"]
  }

  notification {
    enabled        = true
    operator       = "GreaterThanOrEqualTo"
    threshold      = 90
    contact_emails = ["abiradey92@gmail.com"]
  }
}


# Define an Azure Machine Learning workspace with identity
resource "azurerm_machine_learning_workspace" "aml_workspace" {
  name                    = "ml-workspace"
  location                = azurerm_resource_group.subscription2_initial_rg.location
  resource_group_name     = azurerm_resource_group.subscription2_initial_rg.name
  key_vault_id            = azurerm_key_vault.aml_keyvault.id
  application_insights_id = azurerm_application_insights.aml_insights.id
  storage_account_id      = azurerm_storage_account.subscription2_storage.id
  identity {
    type = "SystemAssigned" # Managed Identity for the workspace
  }
}

# Define a Log Analytics workspace for Azure Monitor
resource "azurerm_log_analytics_workspace" "aml_log_analytics" {
  name                = "aml-log-analytics"
  location            = azurerm_resource_group.subscription2_initial_rg.location
  resource_group_name = azurerm_resource_group.subscription2_initial_rg.name
  sku                 = "PerGB2018"
}

# Define an Application Insights resource for monitoring
resource "azurerm_application_insights" "aml_insights" {
  name                = "aml-app-insights"
  location            = azurerm_resource_group.subscription2_initial_rg.location
  resource_group_name = azurerm_resource_group.subscription2_initial_rg.name
  application_type    = "web"
}

# Define a Key Vault to store secrets (if needed)
resource "azurerm_key_vault" "aml_keyvault" {
  name                = "ml-workspace-keys"
  location            = azurerm_resource_group.subscription2_initial_rg.location
  resource_group_name = azurerm_resource_group.subscription2_initial_rg.name
  sku_name            = "standard"
  tenant_id           = var.tenant_id # Get tenant_id from client config

}

# Set up Azure Monitor diagnostics for the ML workspace
resource "azurerm_monitor_diagnostic_setting" "aml_monitoring" {
  name                       = "aml-diagnostic-monitoring"
  target_resource_id         = azurerm_machine_learning_workspace.aml_workspace.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.aml_log_analytics.id
  storage_account_id         = azurerm_storage_account.subscription2_storage.id

  enabled_log {
    category = "AmlComputeClusterNodeEvent"

  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}