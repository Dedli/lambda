variable "vault_addr" {
  description = "URL to access Vault"
  type = string
}

variable "vault_root_token" {
  description = "Your root token from Vault"
  type = string
  sensitive   = true
}