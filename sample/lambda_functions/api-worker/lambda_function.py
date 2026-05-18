"""
Lambda function for async API worker.
Consumes messages from SQS.
"""

import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)


# def lambda_handler(event, context):
#     """
#     Worker handler - receives SQS messages.
#     """
    
#     logger.info(f"Received {len(event.get('Records', []))} messages")
    
#     for record in event.get('Records', []):
#         logger.info(f"Message: {record['body']}")
    
#     return {"statusCode": 200, "body": "OK"}

"""
Lambda function for async API worker.
Consumes messages from SQS and processes jobs.
"""

import os
import json
import logging
import time
import requests
import boto3
# from aurora_postgres import connect_aurora_postgres
from processor import full_inference_pipeline

logger = logging.getLogger()
logger.setLevel(logging.INFO)

REGION = os.environ['REGION']
ENDPOINT_NAME =  os.environ['ENDPOINT_NAME']


boto_session = boto3.Session(region_name=REGION)
sm_client = boto_session.client(service_name='sagemaker-runtime', region_name=REGION)


def lambda_handler(event, context):
    logger.info(f"Received {len(event.get('Records', []))} SQS messages")

    for record in event.get("Records", []):
        try:
            # Parse message body
            message = json.loads(record["body"])

            job_id = message["job_id"]
            request_data = message["request_data"]
            submitted_at = message.get("submitted_at")

            logger.info(f"Processing job_id={job_id}, submitted_at={submitted_at}")

            # Lấy callback info
            callback_cfg = request_data.get("callback", {})
            callback_url = callback_cfg.get("url")
            callback_token = callback_cfg.get("token")

            # # Giả lập xử lý
            # logger.info(f"Simulating processing for job {job_id}")
            # time.sleep(3)

            # Call Model Endpoint
            result = {
                "job_id": job_id,
                "status": "COMPLETED",
                "model_output": full_inference_pipeline(request_data['input_data'], sm_client, ENDPOINT_NAME),
                "processed_at": time.strftime("%Y-%m-%dT%H:%M:%SZ")
            }
            # print(connect_aurora_postgres(host, database, user, secret_name, REGION))
            print(result)
            # push callback lại 
            if callback_url:
                send_callback(
                    callback_url=callback_url,
                    callback_token=callback_token,
                    payload=result
                )
            else:
                logger.info(f"No callback configured for job {job_id}")

            logger.info(f"Job {job_id} processed successfully")

        except Exception as e:
            logger.error(f"Failed to process SQS record: {str(e)}")
            # raise để SQS retry
            raise

    return {"statusCode": 200, "body": "OK"}


def send_callback(callback_url, callback_token, payload):
    headers = {
        "Content-Type": "application/json"
    }

    if callback_token:
        headers["Authorization"] = f"Bearer {callback_token}"

    response = requests.post(
        callback_url,
        json=payload,
        headers=headers,
        timeout=5
    )

    response.raise_for_status()