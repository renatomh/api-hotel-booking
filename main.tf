# Defining variables for the resources
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-2"
}
variable "user_pool_name" {
  description = "AWS Cognito User Pool Name"
  type        = string
  default     = "hotel-booking-users"
}
variable "user_pool_domain" {
  description = "AWS Cognito User Pool Domain"
  type        = string
  default     = "hotel-booking-users"
}
variable "redirect_url" {
  description = "Application Redirect URL"
  type        = string
}
variable "admin_user_email" {
  description = "Admin User Email"
  type        = string
}
variable "admin_user_temporary_password" {
  description = "Admin User Temporary Password"
  type        = string
}

# Specify the provider (AWS)
provider "aws" {
  region = var.aws_region
}

# Creating the Cognito User Pool
resource "aws_cognito_user_pool" "hotel_booking_users" {
  name = var.user_pool_name

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]
  user_attribute_update_settings {
    attributes_require_verification_before_update = ["email"]
  }

  schema {
    attribute_data_type = "String"
    name                = "given_name"
    required            = true
    mutable             = true
  }
  schema {
    attribute_data_type = "String"
    name                = "family_name"
    required            = true
    mutable             = true
  }
  schema {
    attribute_data_type = "String"
    name                = "address"
    required            = true
    mutable             = true
  }
  schema {
    attribute_data_type = "String"
    name                = "email"
    required            = true
    mutable             = false
  }
  schema {
    attribute_data_type = "String"
    name                = "billing_address"
    mutable             = true
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  password_policy {
    minimum_length    = 8
    require_lowercase = false
    require_numbers   = false
    require_symbols   = false
    require_uppercase = false
  }

  mfa_configuration = "OFF"

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_LINK"
  }

  user_pool_add_ons {
    advanced_security_mode = "OFF"
  }

  deletion_protection = "INACTIVE"

  tags = {
    Terraform = "true"
  }
}

# Creating the Cognito User Pool Domain
resource "aws_cognito_user_pool_domain" "hotel_booking_domain" {
  domain       = var.user_pool_domain
  user_pool_id = aws_cognito_user_pool.hotel_booking_users.id
}

# Creating the Cognito User Pool App client (defining redirect URLs, OAuth scopes, etc.)
resource "aws_cognito_user_pool_client" "web" {
  name                                 = "web"
  user_pool_id                         = aws_cognito_user_pool.hotel_booking_users.id
  generate_secret                      = false
  explicit_auth_flows                  = ["ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_SRP_AUTH"]
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["openid", "email", "profile"]
  callback_urls                        = [var.redirect_url]
  logout_urls                          = [var.redirect_url]
  supported_identity_providers         = ["COGNITO"]
  allowed_oauth_flows_user_pool_client = true
  prevent_user_existence_errors        = "ENABLED"
}

# Creating user groups
resource "aws_cognito_user_group" "admin_group" {
  name         = "Admin"
  description  = "Admin Group"
  precedence   = 1
  user_pool_id = aws_cognito_user_pool.hotel_booking_users.id
}

resource "aws_cognito_user_group" "customer_group" {
  name         = "Customer"
  description  = "Customer Group"
  precedence   = 2
  user_pool_id = aws_cognito_user_pool.hotel_booking_users.id
}

resource "aws_cognito_user_group" "hotel_manager_group" {
  name         = "HotelManager"
  description  = "Hotel Manager Group"
  precedence   = 3
  user_pool_id = aws_cognito_user_pool.hotel_booking_users.id
}

# Creating admin user
resource "aws_cognito_user" "admin_user" {
  username                 = var.admin_user_email
  user_pool_id             = aws_cognito_user_pool.hotel_booking_users.id
  desired_delivery_mediums = ["EMAIL"]
  force_alias_creation     = true
  temporary_password       = var.admin_user_temporary_password
  attributes = {
    email          = var.admin_user_email
    email_verified = true
  }
}

# Defining admin user group
resource "aws_cognito_user_in_group" "user_admin_group" {
  user_pool_id = aws_cognito_user_pool.hotel_booking_users.id
  group_name   = aws_cognito_user_group.admin_group.name
  username     = aws_cognito_user.admin_user.username
}

# API Gateway for creating new hotels
resource "aws_api_gateway_rest_api" "new_hotel_api" {
  name        = "NewHotel"
  description = "REST API for creating a mew hotel"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_authorizer" "cognito_authorizer" {
  name            = "NewHotelAuth"
  rest_api_id     = aws_api_gateway_rest_api.new_hotel_api.id
  type            = "COGNITO_USER_POOLS"
  identity_source = "method.request.header.Authorization"
  provider_arns   = [aws_cognito_user_pool.hotel_booking_users.arn]
}

resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.new_hotel_api.id
  resource_id   = aws_api_gateway_rest_api.new_hotel_api.root_resource_id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
}

resource "aws_api_gateway_integration" "post_method" {
  rest_api_id             = aws_api_gateway_rest_api.new_hotel_api.id
  resource_id             = aws_api_gateway_rest_api.new_hotel_api.root_resource_id
  http_method             = aws_api_gateway_method.post_method.http_method
  integration_http_method = aws_api_gateway_method.post_method.http_method
  type                    = "MOCK"

  request_templates = {
    "multipart/form-data" = "{ statusCode: 200 }"
    "application/json"    = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "post_method" {
  rest_api_id = aws_api_gateway_rest_api.new_hotel_api.id
  resource_id = aws_api_gateway_rest_api.new_hotel_api.root_resource_id
  http_method = aws_api_gateway_method.post_method.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "post_method" {
  rest_api_id = aws_api_gateway_rest_api.new_hotel_api.id
  resource_id = aws_api_gateway_rest_api.new_hotel_api.root_resource_id
  http_method = aws_api_gateway_method.post_method.http_method
  status_code = aws_api_gateway_method_response.post_method.status_code

  response_templates = {
    "application/json" = ""
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

module "cors" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"

  api_id          = aws_api_gateway_rest_api.new_hotel_api.id
  api_resource_id = aws_api_gateway_rest_api.new_hotel_api.root_resource_id
}

resource "aws_api_gateway_deployment" "new_hotel_api" {
  rest_api_id = aws_api_gateway_rest_api.new_hotel_api.id

  depends_on = [
    aws_api_gateway_method.post_method,
    aws_api_gateway_integration.post_method,
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "new_hotel_api" {
  deployment_id = aws_api_gateway_deployment.new_hotel_api.id
  rest_api_id   = aws_api_gateway_rest_api.new_hotel_api.id
  stage_name    = "Test"
}
