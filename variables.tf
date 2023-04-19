variable "vault_addr" {
  description = "URL to access Vault"
  type = string
}

variable "vault_root_token" {
  description = "Your root token from Vault"
  type = string
  sensitive   = true
}

variable "secret_to_read" {
  description = "existing secret to read from vault"
  type = string
}

variable "vpc_subnet_ids" {
  description = "list of subnet ids to use for the lambda"
  type = list(string)
}

variable "vpc_security_group_ids" {
  description = "list of security group ids to use for the lambda"
  type = list(string)
}