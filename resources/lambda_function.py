import boto3
import os
import urllib
from PIL import Image

s3 = boto3.client('s3')

def lambda_handler(event, context):
    # Obtener información sobre el archivo cargado
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'])
    temp_filename = '/tmp/temp_image.jpg'
    output_filename = '/tmp/thumbnail.jpg'

    # Descargar el archivo desde S3 al directorio temporal
    s3.download_file(bucket, key, temp_filename)

    # Crear una miniatura de la imagen
    create_thumbnail(temp_filename, output_filename)

    # Subir la miniatura al bucket de destino
    destination_bucket = os.environ['DESTINATION_BUCKET']
    s3.upload_file(output_filename, destination_bucket, 'thumbnail.jpg')

    return {
        'statusCode': 200,
        'body': 'Thumbnail created and uploaded successfully.'
    }

def create_thumbnail(input_filename, output_filename):
    with Image.open(input_filename) as image:
        # Redimensionar la imagen al tamaño deseado para la miniatura
        thumbnail_size = (200, 200)
        image.thumbnail(thumbnail_size)
        
        # Guardar la imagen en el archivo de salida
        image.save(output_filename)
