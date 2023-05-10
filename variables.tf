
# Input variable definitions

variable "aws_region" {
  description = "AWS region for all resources."

  type    = string
  default = "us-east-1"
}

variable "image_path" {
  description = "Ruta local de la imagen a subir al bucket de origen"
  default = "./resources/mi_imagen.jpg"
}