import os
import logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

ACCOUNT_ID = os.environ['ACCOUNT_ID']

def lambda_handler(event, context):
    logger.info(f"AccountId={ACCOUNT_ID}")
