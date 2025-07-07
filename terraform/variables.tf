variable "prefix" {
  description = "A short name for the project, used as a prefix for resources. DL = De Lijn."
  type        = string
  default     = "dl"
}

variable "location" {
  description = "The Azure region where resources will be created."
  type        = string
  default     = "West Europe"
}

variable "resource_group_name" {
  description = "The name of the Azure Resource Group."
  type        = string
  default     = "rg-dl-main"
}

variable "DELIJN_API_KEY" {
  description = "The primary API key for De Lijn Realtime API."
  type        = string
  sensitive   = true
}
