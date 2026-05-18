"""
Lambda function for SageMaker inference.
Flow: API Gateway → Lambda → SageMaker Endpoint → Response
"""

import json
import logging
import os
import boto3
from botocore.config import Config

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize SageMaker runtime client
config = Config(
    retries={'max_attempts': 3, 'mode': 'adaptive'},
    connect_timeout=5,
    read_timeout=60
)
sagemaker_runtime = boto3.client('sagemaker-runtime', config=config)

# Environment variables
VISION_ENDPOINT = os.environ.get('VISION_ENDPOINT_NAME')
TEXT_ENDPOINT = os.environ.get('TEXT_ENDPOINT_NAME')
DEFAULT_ENDPOINT = os.environ.get('DEFAULT_ENDPOINT_NAME', VISION_ENDPOINT)


def lambda_handler(event, context):
    """
    Handle inference requests.
    
    Request body:
    {
        "model": "vision" | "text",  # optional, defaults to vision
        "messages": [
            {"role": "user", "content": "Hello"}
        ],
        "max_tokens": 512,
        "temperature": 0.7,
        "stream": false
    }
    """
    logger.info(f"Received event: {json.dumps(event)}")
    
    try:
        # Parse request
        body = json.loads(event.get('body', '{}'))
        
        # Determine endpoint
        model_type = body.get('model', 'vision').lower()
        if model_type == 'text' and TEXT_ENDPOINT:
            endpoint_name = TEXT_ENDPOINT
        elif model_type == 'vision' and VISION_ENDPOINT:
            endpoint_name = VISION_ENDPOINT
        else:
            endpoint_name = DEFAULT_ENDPOINT
        
        if not endpoint_name:
            return error_response(400, "No endpoint configured")
        
        # Prepare payload for SageMaker (OpenAI-compatible format)
        payload = {
            "messages": body.get('messages', []),
            "max_tokens": body.get('max_tokens', 512),
            "temperature": body.get('temperature', 0.7),
            "top_p": body.get('top_p', 0.9),
            "stream": False  # Lambda doesn't support streaming response
        }
        
        # Invoke SageMaker endpoint
        logger.info(f"Invoking endpoint: {endpoint_name}")
        response = sagemaker_runtime.invoke_endpoint(
            EndpointName=endpoint_name,
            ContentType='application/json',
            Accept='application/json',
            Body=json.dumps(payload)
        )
        
        # Parse response
        result = json.loads(response['Body'].read().decode('utf-8'))
        
        return success_response(result)
        
    except sagemaker_runtime.exceptions.ModelError as e:
        logger.error(f"Model error: {e}")
        return error_response(500, f"Model error: {str(e)}")
    except sagemaker_runtime.exceptions.ValidationError as e:
        logger.error(f"Validation error: {e}")
        return error_response(400, f"Validation error: {str(e)}")
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        return error_response(500, f"Internal error: {str(e)}")


def success_response(data):
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "POST, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type, Authorization"
        },
        "body": json.dumps(data)
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
