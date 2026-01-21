#!/usr/bin/env python3
import json
import boto3
import pymysql
import sys

def get_secret(secret_name, region):
    client = boto3.client('secretsmanager', region_name=region)
    response = client.get_secret_value(SecretId=secret_name)
    return json.loads(response['SecretString'])

def test_connection():
    # Load config
    try:
        with open('lab-config.txt', 'r') as f:
            config = dict(line.strip().split('=', 1) for line in f if '=' in line)
    except FileNotFoundError:
        print("❌ lab-config.txt not found. Run ./deploy.sh first.")
        sys.exit(1)
    
    region = config['REGION']
    secret_name = config['SECRET_NAME']
    
    print(f"🔐 Retrieving secret from Secrets Manager...")
    secret = get_secret(secret_name, region)
    
    print(f"✅ Secret retrieved successfully")
    print(f"📊 Connection details:")
    print(f"   Host: {secret['host']}")
    print(f"   Port: {secret['port']}")
    print(f"   Username: {secret['username']}")
    print(f"   Database: {secret.get('dbname', 'N/A')}")
    
    print(f"\n🔌 Testing database connection...")
    
    try:
        connection = pymysql.connect(
            host=secret['host'],
            user=secret['username'],
            password=secret['password'],
            port=secret['port'],
            connect_timeout=10
        )
        
        with connection.cursor() as cursor:
            cursor.execute("SELECT VERSION()")
            version = cursor.fetchone()
            print(f"✅ Connection successful!")
            print(f"📊 MySQL version: {version[0]}")
        
        connection.close()
        
    except Exception as e:
        print(f"❌ Connection failed: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    test_connection()
