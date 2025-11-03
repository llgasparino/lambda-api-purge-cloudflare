# 1. A API REST
resource "aws_api_gateway_rest_api" "purger_api" {
  name        = "${var.project_name}-api"
  description = "API para disparar o purge manual de prefixos do Cloudflare"
}

# 2. O Recurso (ex: /purge-cache)
resource "aws_api_gateway_resource" "purger_resource" {
  rest_api_id = aws_api_gateway_rest_api.purger_api.id
  parent_id   = aws_api_gateway_rest_api.purger_api.root_resource_id
  path_part   = var.api_path_part
}

# 3. O Método POST (protegido por API Key)
resource "aws_api_gateway_method" "purger_method_post" {
  rest_api_id      = aws_api_gateway_rest_api.purger_api.id
  resource_id      = aws_api_gateway_resource.purger_resource.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true # <-- Exige a chave de API
}

# 4. A Integração POST -> Lambda
resource "aws_api_gateway_integration" "purger_integration" {
  rest_api_id             = aws_api_gateway_rest_api.purger_api.id
  resource_id             = aws_api_gateway_resource.purger_resource.id
  http_method             = aws_api_gateway_method.purger_method_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY" # <-- Passa a requisição direto para a Lambda
  uri                     = aws_lambda_function.api_prefix_purger.invoke_arn
}

# 5. Permissão para o API Gateway invocar a Lambda
resource "aws_lambda_permission" "allow_api_gateway_to_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_prefix_purger.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.purger_api.execution_arn}/*/${aws_api_gateway_method.purger_method_post.http_method}${aws_api_gateway_resource.purger_resource.path}"
}

# 6. Configuração de CORS (OPTIONS)
resource "aws_api_gateway_method" "purger_method_options" {
  rest_api_id      = aws_api_gateway_rest_api.purger_api.id
  resource_id      = aws_api_gateway_resource.purger_resource.id
  http_method      = "OPTIONS"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_integration" "purger_integration_options" {
  rest_api_id = aws_api_gateway_rest_api.purger_api.id
  resource_id = aws_api_gateway_resource.purger_resource.id
  http_method = aws_api_gateway_method.purger_method_options.http_method
  type        = "MOCK" # <-- Simula uma resposta, não chama a Lambda
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.purger_api.id
  resource_id = aws_api_gateway_resource.purger_resource.id
  http_method = aws_api_gateway_method.purger_method_options.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.purger_api.id
  resource_id = aws_api_gateway_resource.purger_resource.id
  http_method = aws_api_gateway_method.purger_method_options.http_method
  status_code = aws_api_gateway_method_response.options_200.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'${var.cors_allowed_origin}'"
  }
  depends_on = [aws_api_gateway_integration.purger_integration_options]
}

# 7. Deploy, Stage e API Key
resource "aws_api_gateway_deployment" "purger_deployment" {
  rest_api_id = aws_api_gateway_rest_api.purger_api.id
  # 'triggers' força um novo deploy sempre que a API mudar
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.purger_resource.id,
      aws_api_gateway_method.purger_method_post.id,
      aws_api_gateway_integration.purger_integration.id,
      aws_api_gateway_method.purger_method_options.id,
    ]))
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "purger_stage" {
  deployment_id = aws_api_gateway_deployment.purger_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.purger_api.id
  stage_name    = var.api_stage_name
}

resource "aws_api_gateway_api_key" "purger_api_key" {
  name    = "${var.project_name}-key"
  enabled = true
}

resource "aws_api_gateway_usage_plan" "purger_usage_plan" {
  name = "${var.project_name}-usage-plan"
  api_stages {
    api_id = aws_api_gateway_rest_api.purger_api.id
    stage  = aws_api_gateway_stage.purger_stage.stage_name
  }
}

resource "aws_api_gateway_usage_plan_key" "purger_usage_plan_key" {
  key_id        = aws_api_gateway_api_key.purger_api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.purger_usage_plan.id
}