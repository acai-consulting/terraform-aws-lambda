import os
import json

ACCOUNT_ID = os.environ['ACCOUNT_ID']

def lambda_handler(event, context):
    file_path = os.path.join("sub-folder", "test.json")

    # Check if the file exists
    if not os.path.exists(file_path):
        return {
            'statusCode': 404,
            'body': json.dumps({'error': 'File not found'})
        }

    # Try to load the file as JSON
    try:
        with open(file_path, 'r') as file:
            data = json.load(file)
            if data.get('accountId', '') == ACCOUNT_ID:
                # Return JSON response
                return {
                    'statusCode': 200,
                    'body': data
                }
            else:
                return {
                    'statusCode': 403,
                    'body': json.dumps({'error': 'Account ID does not match'})
                }
                        
    except json.JSONDecodeError:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Invalid JSON format'})
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal server error'})
        }