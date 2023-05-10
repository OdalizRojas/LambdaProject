provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      hashicorp-learn = "lambda-api-gateway"
    }
  }

}

resource "random_pet" "lambda_bucket_name" {
  prefix = "lambda"
  length = 4
}

resource "aws_s3_bucket" "trigger_bucket" {
  bucket = random_pet.lambda_bucket_name.id
}

resource "aws_s3_bucket" "destination_bucket" {
  bucket = "lambda-destination-bucket442002"
}

# resource "aws_s3_bucket_acl" "bucket_acl" {
#   bucket = aws_s3_bucket.trigger_bucket.id
#   acl    = "private"
# }

## Creacion de archivo que comprime el codigo
data "archive_file" "lambda_function" {
  type = "zip"
  source_dir  = "${path.module}/resources"
  output_path = "${path.module}/lambda_function.zip"
}

# Sube la imagen como un objeto al bucket de origen
resource "aws_s3_object" "lambda_object" {
  bucket = aws_s3_bucket.trigger_bucket.id
  key    = "mi_imagen.jpg"
  source = var.image_path
}

# Funcion LAMBDA

resource "aws_lambda_function" "thumbnail_function" {
  function_name = "s3-lambda-thumbnail-img"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"

  // Configuración para el disparador de S3
  environment {
    variables = {
      DESTINATION_BUCKET = aws_s3_bucket.destination_bucket.id
    }
  }
  #s3_bucket = aws_s3_bucket.trigger_bucket.id
  #s3_key    = "mi_imagen.jpg"  # Reemplaza con la ruta a la carpeta y el nombre de archivo de imagen en S3

  // Configuración para crear la imagen en miniatura
  filename      = "lambda_function.zip"
  source_code_hash = data.archive_file.lambda_function.output_base64sha256
}

# # Creacion de Trigger

resource "aws_lambda_permission" "s3_trigger_permission" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.thumbnail_function.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.trigger_bucket.arn
}

resource "aws_s3_bucket_notification" "s3_trigger" {
  bucket = aws_s3_bucket.trigger_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.thumbnail_function.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".jpg"
  }
}

# ## Permisos IAM

# resource "aws_iam_policy" "lambda_policy" {
#   name        = "lambda-s3-policy"
#   description = "Permite acceso a los buckets de origen y destino de S3"

#   policy = <<EOF
#   {
#     "Version": "2012-10-17",
#     "Statement": [
#       {
#         "Effect": "Allow",
#         "Action": [
#           "s3:GetObject",
#           "s3:PutObject"
#         ],
#         "Resource": [
#           "arn:aws:s3:::source-bucket-name/*",
#           "arn:aws:s3:::destination-bucket-name/*"
#         ]
#       }
#     ]
#   }
#   EOF
# }

resource "aws_iam_role" "lambda_role" {
  name = "s3trigger_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
}


