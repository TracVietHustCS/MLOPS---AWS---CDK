"""
Lambda function to test API Gateway connectivity.
Flow: External Client → API Gateway → Lambda → Response

Returns a simple success response to verify the connection works.
"""

import json
import logging
from datetime import datetime

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    """
    Simple test handler that returns success response.
    
    Test with:
        curl -X POST https://<api-gateway-url>/v1/test \
            -H "Content-Type: application/json" \
            -d '{"message": "hello"}'
    
    Or GET:
        curl https://<api-gateway-url>/v1/test
    """
    
    logger.info(f"Received event: {json.dumps(event)}")
    
    # Extract request info
    http_method = event.get('httpMethod', 'UNKNOWN')
    path = event.get('path', '/')
    headers = event.get('headers', {})
    query_params = event.get('queryStringParameters') or {}
    body = event.get('body')
    
    # Parse body if JSON
    parsed_body = None
    if body:
        try:
            parsed_body = json.loads(body)
        except json.JSONDecodeError:
            parsed_body = body
    
    # Build response
    response_body = {
        "status": "success",
        "message": "API Gateway → Lambda connection successful!",
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "request_info": {
            "method": http_method,
            "path": path,
            "query_params": query_params,
            "body": parsed_body
        },
        "lambda_info": {
            "function_name": context.function_name,
            "function_version": context.function_version,
            "memory_limit_mb": context.memory_limit_in_mb,
            "remaining_time_ms": context.get_remaining_time_in_millis()
        }
    }
    
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type, Authorization"
        },
        "body": json.dumps(response_body, indent=2)
    }
