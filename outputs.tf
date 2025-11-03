output "api_endpoint_url" {
  description = "A URL completa do endpoint para disparar o purge."
  value       = "${aws_api_gateway_stage.purger_stage.invoke_url}/${var.api_path_part}"
}

output "api_key_value" {
  description = "A chave de API (x-api-key) necessária para chamar o endpoint."
  value       = aws_api_gateway_api_key.purger_api_key.value
  sensitive   = true # <-- Não imprime a chave nos logs da pipeline
}