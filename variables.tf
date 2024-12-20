variable "subscription_id1" {
  description = "The Azure subscription ID"
  type        = string
}

variable "subscription_id2" {
  description = "The Azure subscription ID"
  type        = string
}

variable "alert_email" {
  type    = string
  default = "abiradey92@gmail.com"
}
# Variables for subscription details
variable "subscriptions" {
  description = "List of subscription details"
  type = map(object({
    subscription_id = string
    budget_name     = string
    amount          = number
    start_date      = string
    end_date        = string
  }))
}

variable "tenant_id" {
  type    = string
}