output "lambda_function_name" {
  value = aws_lambda_function.hello_lambda.function_name
}
output "lambda_api_url" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}