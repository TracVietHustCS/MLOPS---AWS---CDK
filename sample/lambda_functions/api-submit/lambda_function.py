"""
Lambda function for async API submit.
Flow: API Gateway → api-submit → SQS → api-worker

Receives inference requests and pushes to SQS queue for async processing.
"""

import json
import logging
import os
import uuid
from datetime import datetime

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

sqs = boto3.client('sqs')

QUEUE_URL = os.environ.get('SQS_QUEUE_URL', '')


def lambda_handler(event, context):
    """
    Submit handler - receives request and pushes to SQS.
    
    Returns a job_id for tracking the async request.
    """
    
    logger.info(f"Received event: {json.dumps(event)}")
    
    # Parse request body
    body = event.get('body')
    if body:
        try:
            request_data = json.loads(body)
        except json.JSONDecodeError:
            return error_response(400, "Invalid JSON body")
    else:
        return error_response(400, "Request body is required")
    
    # Generate job ID
    job_id = str(uuid.uuid4())
    
    # Build SQS message
    message = {
        "job_id": job_id,
        "request_data": request_data,
        "submitted_at": datetime.utcnow().isoformat() + "Z",
        "source_ip": event.get('requestContext', {}).get('identity', {}).get('sourceIp')
    }
    
    try:
        # Send to SQS
        response = sqs.send_message(
            QueueUrl=QUEUE_URL,
            MessageBody=json.dumps(message),
            MessageAttributes={
                'JobId': {
                    'DataType': 'String',
                    'StringValue': job_id
                }
            }
        )
        
        logger.info(f"Message sent to SQS: {response['MessageId']}")
        
        return success_response({
            "status": "submitted",
            "job_id": job_id,
            "message": "Request submitted for async processing",
            "submitted_at": message["submitted_at"]
        })
        
    except Exception as e:
        logger.error(f"Failed to send message to SQS: {str(e)}")
        return error_response(500, f"Failed to submit request: {str(e)}")


def success_response(data):
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type, Authorization"
        },
        "body": json.dumps(data, indent=2)
    }


def error_response(status_code, message):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*"
        },
        "body": json.dumps({"error": message})
    }
