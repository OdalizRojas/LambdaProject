# terraform {
#   backend "s3" {
#     bucket = "demian-terraform-state"
#     key    = "lambda.ftstate"
#     region = "us-east-1" 
#     dynamodb_table = "odaliz-terraform-stateDB"
#   }
# }