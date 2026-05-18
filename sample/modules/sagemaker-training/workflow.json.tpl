{
  "Comment": "SageMaker Training Workflow",
  "StartAt": "TrainingJob",
  "States": {
    "TrainingJob": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sagemaker:createTrainingJob.sync",
      "Parameters": {
        "TrainingJobName.$": "States.Format('${name_prefix}-${environment}-{}', $$.Execution.Name)",
        "AlgorithmSpecification": {
          "TrainingImage": "${training_image}",
          "TrainingInputMode": "${training_input_mode}"
        },
        "RoleArn": "${sagemaker_role_arn}",
        "InputDataConfig": [
          {
            "ChannelName": "train",
            "DataSource": {
              "S3DataSource": {
                "S3DataType": "S3Prefix",
                "S3Uri.$": "$.TrainingDataS3Uri",
                "S3DataDistributionType": "FullyReplicated"
              }
            },
            "ContentType": "${training_data_content_type}"
          }
        ],
        "OutputDataConfig": {
          "S3OutputPath": "s3://${output_bucket}/${output_prefix}"
        },
        "ResourceConfig": {
          "InstanceType": "${training_instance_type}",
          "InstanceCount": ${training_instance_count},
          "VolumeSizeInGB": ${training_volume_size}
        },
        "StoppingCondition": {
          "MaxRuntimeInSeconds": ${max_runtime_seconds}
        },
        "EnableNetworkIsolation": ${enable_network_isolation},
        "EnableInterContainerTrafficEncryption": ${enable_inter_container_encryption}
      },
      "Next": "RegisterModel",
      "Catch": [
        {
          "ErrorEquals": ["States.ALL"],
          "Next": "TrainingFailed"
        }
      ]
    },
    "RegisterModel": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sagemaker:createModel",
      "Parameters": {
        "ModelName.$": "States.Format('${name_prefix}-${environment}-model-{}', $$.Execution.Name)",
        "ExecutionRoleArn": "${sagemaker_role_arn}",
        "PrimaryContainer": {
          "Image": "${inference_image}",
          "ModelDataUrl.$": "$.ModelArtifacts.S3ModelArtifacts"
        }
      },
      "End": true,
      "Catch": [
        {
          "ErrorEquals": ["States.ALL"],
          "Next": "TrainingFailed"
        }
      ]
    },
    "TrainingFailed": {
      "Type": "Fail",
      "Error": "TrainingJobFailed",
      "Cause": "SageMaker training job failed"
    }
  }
}
