
import os
import json
import boto3
from typing import List, Dict, Optional
import logging
from datetime import datetime

logger = logging.getLogger()
logger.setLevel(logging.INFO)

sagemaker = boto3.client('sagemaker')
s3 = boto3.client('s3')
autoscaling = boto3.client('application-autoscaling')


def save_autoscaling_config(endpoint_name: str, bucket: str) -> bool:
    """
    Save autoscaling configuration (target and policies) to S3.

    Args:
        endpoint_name: Name of the endpoint
        bucket: S3 bucket to save config

    Returns:
        True if successful, False otherwise
    """
    try:
        resource_id = f"endpoint/{endpoint_name}/variant/AllTraffic"

        # Get autoscaling target
        try:
            targets_response = autoscaling.describe_scalable_targets(
                ServiceNamespace='sagemaker',
                ResourceIds=[resource_id]
            )
            targets = targets_response.get('ScalableTargets', [])
        except Exception as e:
            logger.warning(f"No autoscaling target found for {endpoint_name}: {e}")
            targets = []

        # Get autoscaling policies
        try:
            policies_response = autoscaling.describe_scaling_policies(
                ServiceNamespace='sagemaker',
                ResourceId=resource_id
            )
            policies = policies_response.get('ScalingPolicies', [])
        except Exception as e:
            logger.warning(f"No autoscaling policies found for {endpoint_name}: {e}")
            policies = []

        if not targets and not policies:
            logger.info(f"No autoscaling configuration found for {endpoint_name}")
            return True

        autoscaling_state = {
            'endpoint_name': endpoint_name,
            'resource_id': resource_id,
            'targets': targets,
            'policies': policies,
            'saved_at': datetime.utcnow().isoformat()
        }

        s3_key = f"sagemaker-scheduler/endpoints/{endpoint_name}/autoscaling.json"

        s3.put_object(
            Bucket=bucket,
            Key=s3_key,
            Body=json.dumps(autoscaling_state, indent=2, default=str),
            ContentType='application/json'
        )

        logger.info(f"Saved autoscaling config to s3://{bucket}/{s3_key} ({len(targets)} targets, {len(policies)} policies)")
        return True

    except Exception as e:
        logger.error(f"Error saving autoscaling config: {e}")
        return False


def restore_autoscaling_config(endpoint_name: str, bucket: str) -> bool:
    """
    Restore autoscaling configuration from S3.

    Args:
        endpoint_name: Name of the endpoint
        bucket: S3 bucket containing config

    Returns:
        True if successful, False otherwise
    """
    try:
        s3_key = f"sagemaker-scheduler/endpoints/{endpoint_name}/autoscaling.json"

        try:
            response = s3.get_object(Bucket=bucket, Key=s3_key)
            autoscaling_state = json.loads(response['Body'].read())
        except s3.exceptions.NoSuchKey:
            logger.info(f"No autoscaling config found for {endpoint_name}")
            return True
        except Exception as e:
            logger.warning(f"Error loading autoscaling config: {e}")
            return True

        resource_id = autoscaling_state.get('resource_id')
        targets = autoscaling_state.get('targets', [])
        policies = autoscaling_state.get('policies', [])

        if not targets and not policies:
            logger.info(f"No autoscaling configuration to restore for {endpoint_name}")
            return True

        # Restore autoscaling target
        for target in targets:
            try:
                autoscaling.register_scalable_target(
                    ServiceNamespace='sagemaker',
                    ResourceId=resource_id,
                    ScalableDimension=target['ScalableDimension'],
                    MinCapacity=target['MinCapacity'],
                    MaxCapacity=target['MaxCapacity'],
                    RoleARN=target['RoleARN']
                )
                logger.info(f"Registered autoscaling target for {endpoint_name} (min={target['MinCapacity']}, max={target['MaxCapacity']})")
            except Exception as e:
                logger.error(f"Error registering autoscaling target: {e}")
                return False

        # Restore autoscaling policies
        for policy in policies:
            try:
                policy_config = {
                    'PolicyName': policy['PolicyName'],
                    'ServiceNamespace': 'sagemaker',
                    'ResourceId': resource_id,
                    'ScalableDimension': policy['ScalableDimension'],
                    'PolicyType': policy['PolicyType']
                }

                if 'TargetTrackingScalingPolicyConfiguration' in policy:
                    policy_config['TargetTrackingScalingPolicyConfiguration'] = policy['TargetTrackingScalingPolicyConfiguration']
                elif 'StepScalingPolicyConfiguration' in policy:
                    policy_config['StepScalingPolicyConfiguration'] = policy['StepScalingPolicyConfiguration']

                autoscaling.put_scaling_policy(**policy_config)
                logger.info(f"Restored autoscaling policy {policy['PolicyName']} for {endpoint_name}")
            except Exception as e:
                logger.error(f"Error restoring autoscaling policy {policy.get('PolicyName')}: {e}")
                # Continue with other policies even if one fails

        logger.info(f"Successfully restored autoscaling config for {endpoint_name}")
        return True

    except Exception as e:
        logger.error(f"Error restoring autoscaling config: {e}")
        return False


def save_endpoint_config_to_s3(endpoint_name: str, bucket: str, region: str) -> bool:
    """
    Save endpoint configuration to S3 before deletion.

    Args:
        endpoint_name: Name of the endpoint
        bucket: S3 bucket to save config
        region: AWS region

    Returns:
        True if successful, False otherwise
    """
    try:
        endpoint = sagemaker.describe_endpoint(EndpointName=endpoint_name)

        config = sagemaker.describe_endpoint_config(
            EndpointConfigName=endpoint['EndpointConfigName']
        )

        endpoint_tags = sagemaker.list_tags(ResourceArn=endpoint['EndpointArn'])

        config_tags = sagemaker.list_tags(ResourceArn=config['EndpointConfigArn'])

        state = {
            'endpoint_name': endpoint_name,
            'endpoint_config_name': endpoint['EndpointConfigName'],
            'production_variants': config['ProductionVariants'],
            'endpoint_tags': endpoint_tags.get('Tags', []),
            'config_tags': config_tags.get('Tags', []),
            'saved_at': datetime.utcnow().isoformat(),
            'region': region,
            'data_capture_config': config.get('DataCaptureConfig'),
            'kms_key_id': config.get('KmsKeyId'),
            'async_inference_config': config.get('AsyncInferenceConfig'),
            'explainer_config': config.get('ExplainerConfig'),
        }

        s3_key = f"sagemaker-scheduler/endpoints/{endpoint_name}/config.json"

        s3.put_object(
            Bucket=bucket,
            Key=s3_key,
            Body=json.dumps(state, indent=2),
            ContentType='application/json'
        )

        logger.info(f"Saved endpoint config to s3://{bucket}/{s3_key}")

        # Also save autoscaling configuration
        save_autoscaling_config(endpoint_name, bucket)

        return True

    except Exception as e:
        logger.error(f"Error saving endpoint config to S3: {e}")
        return False


def load_endpoint_config_from_s3(endpoint_name: str, bucket: str) -> Optional[Dict]:
    """
    Load endpoint configuration from S3.

    Args:
        endpoint_name: Name of the endpoint
        bucket: S3 bucket containing config

    Returns:
        Configuration dict or None
    """
    try:
        s3_key = f"sagemaker-scheduler/endpoints/{endpoint_name}/config.json"

        response = s3.get_object(Bucket=bucket, Key=s3_key)
        state = json.loads(response['Body'].read())

        logger.info(f"Loaded endpoint config from s3://{bucket}/{s3_key}")
        return state

    except s3.exceptions.NoSuchKey:
        logger.warning(f"No saved config found for endpoint {endpoint_name}")
        return None
    except Exception as e:
        logger.error(f"Error loading endpoint config from S3: {e}")
        return None


def list_saved_endpoints(bucket: str, tag_key: str, tag_value: str) -> List[str]:
    """
    List all endpoints that have saved configs in S3 with specific tag.

    Args:
        bucket: S3 bucket containing configs
        tag_key: Tag key to filter
        tag_value: Tag value to filter

    Returns:
        List of endpoint names
    """
    try:
        endpoint_names = []

        paginator = s3.get_paginator('list_objects_v2')

        for page in paginator.paginate(Bucket=bucket, Prefix='sagemaker-scheduler/endpoints/'):
            for obj in page.get('Contents', []):
                if obj['Key'].endswith('/config.json'):
                    parts = obj['Key'].split('/')
                    if len(parts) >= 3:
                        endpoint_name = parts[2]

                        state = load_endpoint_config_from_s3(endpoint_name, bucket)
                        if state:
                            tags = {tag['Key']: tag['Value'] for tag in state.get('endpoint_tags', [])}
                            if tags.get(tag_key) == tag_value:
                                try:
                                    sagemaker.describe_endpoint(EndpointName=endpoint_name)
                                    logger.debug(f"Endpoint {endpoint_name} already exists, skipping")
                                except sagemaker.exceptions.ClientError:
                                    endpoint_names.append(endpoint_name)
                                    logger.info(f"Found saved config for deleted endpoint: {endpoint_name}")

        return endpoint_names

    except Exception as e:
        logger.error(f"Error listing saved endpoints: {e}")
        return []


def get_tagged_endpoints(tag_key: str, tag_value: str) -> List[Dict]:
    """
    Get list of active endpoints with specific tag.

    Args:
        tag_key: Tag key to filter on
        tag_value: Tag value to filter on

    Returns:
        List of dicts with endpoint info
    """
    endpoint_info = []

    try:
        paginator = sagemaker.get_paginator('list_endpoints')

        for page in paginator.paginate():
            for endpoint in page['Endpoints']:
                endpoint_name = endpoint['EndpointName']

                response = sagemaker.list_tags(ResourceArn=endpoint['EndpointArn'])
                tags = {tag['Key']: tag['Value'] for tag in response.get('Tags', [])}

                if tags.get(tag_key) == tag_value:
                    endpoint_info.append({
                        'name': endpoint_name,
                        'status': endpoint['EndpointStatus']
                    })
                    logger.info(f"Found tagged endpoint: {endpoint_name}")

        return endpoint_info

    except Exception as e:
        logger.error(f"Error getting tagged endpoints: {e}")
        raise


def delete_endpoint(endpoint_name: str, bucket: str, region: str) -> bool:
    """
    Save config to S3 then delete endpoint.

    Args:
        endpoint_name: Name of the endpoint to delete
        bucket: S3 bucket to save config
        region: AWS region

    Returns:
        True if successful, False otherwise
    """
    try:
        endpoint = sagemaker.describe_endpoint(EndpointName=endpoint_name)
        status = endpoint['EndpointStatus']

        if status in ['Creating', 'Updating', 'Deleting', 'RollingBack']:
            logger.warning(f"Endpoint {endpoint_name} is in {status} state, skipping")
            return False

        if not save_endpoint_config_to_s3(endpoint_name, bucket, region):
            logger.error(f"Failed to save config for {endpoint_name}, aborting deletion")
            return False

        sagemaker.delete_endpoint(EndpointName=endpoint_name)
        logger.info(f"Successfully deleted endpoint: {endpoint_name}")
        return True

    except sagemaker.exceptions.ClientError as e:
        if 'Could not find endpoint' in str(e):
            logger.info(f"Endpoint {endpoint_name} already deleted")
            return True
        logger.error(f"Error deleting endpoint {endpoint_name}: {e}")
        return False
    except Exception as e:
        logger.error(f"Error deleting endpoint {endpoint_name}: {e}")
        return False


def create_endpoint_from_saved_config(endpoint_name: str, bucket: str) -> bool:
    """
    Recreate endpoint from saved S3 configuration.

    Args:
        endpoint_name: Name for the endpoint
        bucket: S3 bucket containing saved config

    Returns:
        True if successful, False otherwise
    """
    try:
        try:
            endpoint = sagemaker.describe_endpoint(EndpointName=endpoint_name)
            status = endpoint['EndpointStatus']

            if status in ['InService', 'Creating', 'Updating']:
                logger.info(f"Endpoint {endpoint_name} already exists with status {status}")
                return True
            elif status == 'Failed':
                logger.info(f"Endpoint {endpoint_name} is Failed, deleting first")
                sagemaker.delete_endpoint(EndpointName=endpoint_name)
                import time
                time.sleep(5)
        except sagemaker.exceptions.ClientError:
            pass

        state = load_endpoint_config_from_s3(endpoint_name, bucket)
        if not state:
            logger.error(f"No saved config found for {endpoint_name}")
            return False

        config_name = state['endpoint_config_name']
        try:
            sagemaker.describe_endpoint_config(EndpointConfigName=config_name)
            logger.info(f"Endpoint config {config_name} already exists, reusing")
        except sagemaker.exceptions.ClientError:
            logger.info(f"Creating endpoint config: {config_name}")

            config_params = {
                'EndpointConfigName': config_name,
                'ProductionVariants': state['production_variants'],
            }

            if state.get('data_capture_config'):
                config_params['DataCaptureConfig'] = state['data_capture_config']
            if state.get('kms_key_id'):
                config_params['KmsKeyId'] = state['kms_key_id']
            if state.get('async_inference_config'):
                config_params['AsyncInferenceConfig'] = state['async_inference_config']
            if state.get('explainer_config'):
                config_params['ExplainerConfig'] = state['explainer_config']
            if state.get('config_tags'):
                config_params['Tags'] = state['config_tags']

            sagemaker.create_endpoint_config(**config_params)
            logger.info(f"Created endpoint config: {config_name}")

        create_params = {
            'EndpointName': endpoint_name,
            'EndpointConfigName': config_name,
        }

        if state.get('endpoint_tags'):
            create_params['Tags'] = state['endpoint_tags']

        sagemaker.create_endpoint(**create_params)
        logger.info(f"Successfully created endpoint: {endpoint_name} from saved config")

        # Wait for endpoint to be InService before restoring autoscaling (with timeout)
        logger.info(f"Waiting for endpoint {endpoint_name} to be InService before restoring autoscaling...")
        max_wait_time = 600  # 10 minutes max wait
        wait_interval = 30
        elapsed_time = 0

        while elapsed_time < max_wait_time:
            try:
                endpoint_status = sagemaker.describe_endpoint(EndpointName=endpoint_name)
                status = endpoint_status['EndpointStatus']

                if status == 'InService':
                    logger.info(f"Endpoint {endpoint_name} is InService, restoring autoscaling...")
                    restore_autoscaling_config(endpoint_name, bucket)
                    break
                elif status in ['Failed', 'RollingBack']:
                    logger.error(f"Endpoint {endpoint_name} failed to create with status {status}")
                    return False
                else:
                    logger.info(f"Endpoint {endpoint_name} status: {status}, waiting...")
                    import time
                    time.sleep(wait_interval)
                    elapsed_time += wait_interval
            except Exception as e:
                logger.warning(f"Error checking endpoint status: {e}")
                break

        if elapsed_time >= max_wait_time:
            logger.warning(f"Timed out waiting for endpoint {endpoint_name} to be InService. Autoscaling not restored.")
            logger.warning(f"You can manually restore autoscaling by re-running the start action or using Terraform.")

        return True

    except Exception as e:
        logger.error(f"Error creating endpoint {endpoint_name}: {e}")
        return False


def lambda_handler(event, context):
    """
    Lambda handler for scheduling SageMaker endpoints.

    Event format:
    {
        "action": "start" | "stop"
    }
    """
    try:
        logger.info(f"Received event: {json.dumps(event)}")

        tag_key = os.environ.get('TAG_KEY', 'AutoSchedule')
        tag_value = os.environ.get('TAG_VALUE', 'true')
        bucket = os.environ.get('STATE_BUCKET')
        region = os.environ.get('AWS_REGION', 'ap-southeast-1')

        if not bucket:
            raise ValueError("STATE_BUCKET environment variable not set")

        action = event.get('action', '').lower()

        if action not in ['start', 'stop']:
            raise ValueError(f"Invalid action: {action}. Must be 'start' or 'stop'")

        results = []

        if action == 'stop':
            logger.info(f"Looking for endpoints with tag {tag_key}={tag_value} to delete")
            endpoints = get_tagged_endpoints(tag_key, tag_value)

            if not endpoints:
                logger.info("No endpoints found to delete")
                return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'message': 'No endpoints found to delete',
                        'action': action
                    })
                }

            logger.info(f"Found {len(endpoints)} endpoints to delete")

            for endpoint in endpoints:
                success = delete_endpoint(endpoint['name'], bucket, region)
                results.append({
                    'endpoint': endpoint['name'],
                    'action': 'delete',
                    'success': success
                })

        else:
            logger.info(f"Looking for saved endpoint configs with tag {tag_key}={tag_value}")
            endpoint_names = list_saved_endpoints(bucket, tag_key, tag_value)

            if not endpoint_names:
                logger.info("No saved endpoint configs found to recreate")
                return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'message': 'No saved endpoint configs found to recreate',
                        'action': action
                    })
                }

            logger.info(f"Found {len(endpoint_names)} saved configs to recreate")

            for endpoint_name in endpoint_names:
                success = create_endpoint_from_saved_config(endpoint_name, bucket)
                results.append({
                    'endpoint': endpoint_name,
                    'action': 'create',
                    'success': success
                })

        successful = sum(1 for r in results if r['success'])
        failed = len(results) - successful

        response = {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'{action.capitalize()} completed: {successful} successful, {failed} failed',
                'action': action,
                'results': results
            })
        }

        logger.info(f"Completed: {response['body']}")
        return response

    except Exception as e:
        logger.error(f"Error in lambda_handler: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }
