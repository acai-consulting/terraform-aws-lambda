import os
import boto3
import json

def lambda_handler(event, context):
    # Initialize clients
    events_client = boto3.client('events')
    ec2_client = boto3.client('ec2')

    # Retrieve EventBridge Rules
    event_rules = events_client.list_rules()['Rules']
    event_rules_info = [{'ruleName': rule['Name'], 'ruleArn': rule['Arn']} for rule in event_rules]

    # Retrieve EC2 Instances
    ec2_instances = ec2_client.describe_instances()
    ec2_instances_info = []
    for reservation in ec2_instances['Reservations']:
        for instance in reservation['Instances']:
            instance_info = {
                'instanceId': instance['InstanceId'],
                'instanceType': instance['InstanceType'],
                'state': instance['State']['Name']
            }
            ec2_instances_info.append(instance_info)

    # Construct response
    response = {
        'AccountId': os.environ['ACCOUNT_ID'],
        'EventRules': event_rules_info,
        'EC2Instances': ec2_instances_info,
    }

    # Return JSON response
    return {
        'statusCode': 200,
        'body': json.dumps(response)
    }
