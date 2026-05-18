
import os
import time
import logging
import psutil
import boto3
from datetime import datetime
from typing import Optional

try:
    import pynvml
    NVML_AVAILABLE = True
except ImportError:
    NVML_AVAILABLE = False

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class MetricsPublisher:
    def __init__(self, endpoint_name: str, variant_name: str = "AllTraffic",
                 publish_interval: int = 60, region: str = "us-east-1"):
        self.endpoint_name = endpoint_name
        self.variant_name = variant_name
        self.publish_interval = publish_interval
        self.region = region

        self.cloudwatch = boto3.client('cloudwatch', region_name=region)

        self.gpu_available = False
        if NVML_AVAILABLE:
            try:
                pynvml.nvmlInit()
                self.gpu_count = pynvml.nvmlDeviceGetCount()
                self.gpu_available = True
                logger.info(f"NVML initialized. Found {self.gpu_count} GPU(s)")
            except Exception as e:
                logger.warning(f"Failed to initialize NVML: {e}")
        else:
            logger.warning("pynvml not available, GPU metrics will not be published")

    def get_cpu_utilization(self) -> float:
        """Get CPU utilization percentage."""
        return psutil.cpu_percent(interval=1)

    def get_memory_utilization(self) -> float:
        """Get memory utilization percentage."""
        return psutil.virtual_memory().percent

    def get_gpu_metrics(self, device_index: int = 0) -> Optional[tuple]:
        """Get GPU utilization and memory utilization for specified device."""
        if not self.gpu_available:
            return None

        try:
            handle = pynvml.nvmlDeviceGetHandleByIndex(device_index)

            utilization = pynvml.nvmlDeviceGetUtilizationRates(handle)
            gpu_util = utilization.gpu

            mem_info = pynvml.nvmlDeviceGetMemoryInfo(handle)
            gpu_mem_util = (mem_info.used / mem_info.total) * 100

            return gpu_util, gpu_mem_util
        except Exception as e:
            logger.error(f"Error getting GPU metrics: {e}")
            return None

    def publish_metrics(self):
        """Publish all metrics to CloudWatch."""
        timestamp = datetime.utcnow()

        metric_data = []

        cpu_util = self.get_cpu_utilization()
        metric_data.append({
            'MetricName': 'CPUUtilization',
            'Value': cpu_util,
            'Unit': 'Percent',
            'Timestamp': timestamp,
            'Dimensions': [
                {'Name': 'Endpoint', 'Value': self.endpoint_name}
            ]
        })

        mem_util = self.get_memory_utilization()
        metric_data.append({
            'MetricName': 'MemoryUtilization',
            'Value': mem_util,
            'Unit': 'Percent',
            'Timestamp': timestamp,
            'Dimensions': [
                {'Name': 'Endpoint', 'Value': self.endpoint_name}
            ]
        })

        gpu_metrics = self.get_gpu_metrics(0)
        if gpu_metrics:
            gpu_util, gpu_mem_util = gpu_metrics

            metric_data.append({
                'MetricName': 'GPUUtilization',
                'Value': gpu_util,
                'Unit': 'Percent',
                'Timestamp': timestamp,
                'Dimensions': [
                    {'Name': 'Endpoint', 'Value': self.endpoint_name}
                ]
            })

            metric_data.append({
                'MetricName': 'GPUMemoryUtilization',
                'Value': gpu_mem_util,
                'Unit': 'Percent',
                'Timestamp': timestamp,
                'Dimensions': [
                    {'Name': 'Endpoint', 'Value': self.endpoint_name}
                ]
            })

        try:
            self.cloudwatch.put_metric_data(
                Namespace='SageMaker/Custom',
                MetricData=metric_data
            )
            logger.info(f"Published metrics: CPU={cpu_util:.1f}%, MEM={mem_util:.1f}%"
                       + (f", GPU={gpu_util:.1f}%, GPU_MEM={gpu_mem_util:.1f}%" if gpu_metrics else ""))
        except Exception as e:
            logger.error(f"Failed to publish metrics: {e}")

    def run(self):
        """Run the metrics publisher loop."""
        logger.info(f"Starting metrics publisher for endpoint: {self.endpoint_name}")
        logger.info(f"Publishing interval: {self.publish_interval} seconds")

        while True:
            try:
                self.publish_metrics()
            except Exception as e:
                logger.error(f"Error in metrics publishing loop: {e}")

            time.sleep(self.publish_interval)

    def cleanup(self):
        """Cleanup resources."""
        if self.gpu_available:
            try:
                pynvml.nvmlShutdown()
            except:
                pass


def get_endpoint_name_from_metadata():
    """
    Get endpoint name from ECS container metadata or environment.
    SageMaker sets HOSTNAME to the endpoint name in the container.
    """
    endpoint_name = os.environ.get('SAGEMAKER_ENDPOINT_NAME')
    if endpoint_name:
        return endpoint_name

    hostname = os.environ.get('HOSTNAME', '')
    if hostname:
        logger.info(f"Container hostname: {hostname}")
        return hostname

    logger.warning("Could not determine endpoint name from environment")
    return None

def main():
    endpoint_name = get_endpoint_name_from_metadata()
    if not endpoint_name:
        logger.error("Could not determine endpoint name. Metrics will not be published.")
        logger.error("Set SAGEMAKER_ENDPOINT_NAME environment variable or ensure HOSTNAME is set.")
        return

    variant_name = os.environ.get('SAGEMAKER_VARIANT_NAME', 'AllTraffic')
    region = os.environ.get('AWS_REGION', os.environ.get('AWS_DEFAULT_REGION', 'us-east-1'))
    publish_interval = int(os.environ.get('METRICS_PUBLISH_INTERVAL', '60'))

    publisher = MetricsPublisher(
        endpoint_name=endpoint_name,
        variant_name=variant_name,
        publish_interval=publish_interval,
        region=region
    )

    try:
        publisher.run()
    except KeyboardInterrupt:
        logger.info("Metrics publisher stopped")
    finally:
        publisher.cleanup()


if __name__ == "__main__":
    main()
