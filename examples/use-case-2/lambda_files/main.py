import os
import boto3
import json

ACCOUNT_ID = os.environ['ACCOUNT_ID']

def lambda_handler(event, context):
    # Initialize clients
    logs_client = boto3.client('logs')
    iam_client = boto3.client('iam')

    # Retrieve CloudWatch Log Groups
    log_groups = logs_client.describe_log_groups()['logGroups']
    log_groups_info = [{'logGroupName': lg['logGroupName']} for lg in log_groups]

    # Retrieve IAM Roles
    iam_roles = iam_client.list_roles()['Roles']
    iam_roles_info = [{'roleName': role['RoleName'], 'roleId': role['RoleId']} for role in iam_roles]

    # Construct response
    response = {
        'AccountId': ACCOUNT_ID,
        'LogGroups': log_groups_info,
        'IAMRoles': iam_roles_info,
    }

    # Return JSON response
    return {
        'statusCode': 200,
        'body': json.dumps(response)
    }