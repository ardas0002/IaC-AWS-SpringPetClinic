import json
import boto3
import pymysql
import os
import logging
import time

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    start_time = time.time()
    logger.info("Starting database initialization")
    
    try:
        # Get database credentials from Secrets Manager
        secrets_manager = boto3.client('secretsmanager')
        secret_data = secrets_manager.get_secret_value(SecretId=os.environ['DB_SECRET_ARN'])
        db_credentials = json.loads(secret_data['SecretString'])
        logger.info(f"Secret retrieval took {time.time() - start_time} seconds")

        connection_start = time.time()

        # Connect to the database
        connection = pymysql.connect(
            host=os.environ['DB_ENDPOINT'].split(':')[0],
            user=db_credentials['username'],
            password=db_credentials['password'],
            database=os.environ['DB_NAME'],
            cursorclass=pymysql.cursors.DictCursor
        )
        
        with connection.cursor() as cursor:
            # Test connection with a simple SELECT query
            cursor.execute("SELECT 1")
            result = cursor.fetchone()
            logger.info(f"Connection test result: {result}")

            # Read and execute SQL files
            sql_dir = os.path.join(os.path.dirname(__file__), 'sql')
            for file_name in ['user.sql', 'schema.sql', 'data.sql']:
                file_path = os.path.join(sql_dir, file_name)
                logger.info(f"Executing SQL file: {file_name}")
                with open(file_path, 'r') as sql_file:
                    sql = sql_file.read()
                    # Split the SQL file into individual statements
                    statements = sql.split(';')
                    for statement in statements:
                        if statement.strip():
                            cursor.execute(statement)
        
        connection.commit()
        logger.info('Database initialized successfully')
        
    except Exception as e:
        logger.error(f'Error initializing database: {str(e)}', exc_info=True)
        raise
    
    finally:
        if 'connection' in locals() and connection.open:
            connection.close()
        logger.info(f"Connection to database and initialization took {time.time() - connection_start} seconds")
        logger.info(f"Total time taken: {time.time() - start_time} seconds")

    return {
        'statusCode': 200,
        'body': json.dumps('Database initialization complete')
    }