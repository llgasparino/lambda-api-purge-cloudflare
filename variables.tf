variable "aws_region" {
  description = "Região da AWS para provisionar os recursos."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome base para os recursos (ex: 'api-cache-purger')."
  type        = string
  default     = "api-cache-purger"
}

variable "api_stage_name" {
  description = "Nome do 'stage' da API (ex: 'v1')."
  type        = string
  default     = "v1"
}

variable "api_path_part" {
  description = "O 'path' da URL da API (ex: 'purge-cache')."
  type        = string
  default     = "purge-cache"
}

variable "cors_allowed_origin" {
  description = "Origem permitida para o CORS (use '*' para público)."
  type        = string
  default     = "*"
}

# --- Configuração de Rede (VPC) ---
variable "vpc_subnet_ids" {
  description = "IDs das subnets PRIVADAS, separadas por vírgula (ex: 'subnet-abc,subnet-xyz')."
  type        = string
}

variable "vpc_security_group_ids" {
  description = "IDs dos Security Groups, separados por vírgula (ex: 'sg-123')."
  type        = string
}

# --- Segredos Injetados pela Pipeline ---
variable "cloudflare_api_token" {
  description = "Token da API do Cloudflare."
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "ID da Zona do Cloudflare."
  type        = string
  sensitive   = true
}

variable "cloudflare_prefixes" {
  description = "Lista de prefixos para limpar, separados por vírgula (ex: 'site1.com/,site2.com/')."
  type        = string
  sensitive   = true
}