import json
import boto3
import pymysql
import os

secretsmanager = boto3.client('secretsmanager')

def get_secret(secret_name):
    response = secretsmanager.get_secret_value(SecretId=secret_name)
    return json.loads(response['SecretString'])

def lambda_handler(event, context):
    secret_name = os.environ['SECRET_NAME']
    
    try:
        secret = get_secret(secret_name)
        
        connection = pymysql.connect(
            host=secret['host'],
            user=secret['username'],
            password=secret['password'],
            port=secret['port'],
            connect_timeout=5
        )
        
        with connection.cursor() as cursor:
            cursor.execute("SELECT VERSION(), NOW()")
            result = cursor.fetchone()
            version, timestamp = result
        
        connection.close()
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Connection successful',
                'mysql_version': version,
                'timestamp': str(timestamp),
                'secret_used': secret_name
            })
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Connection failed',
                'error': str(e)
            })
        }
