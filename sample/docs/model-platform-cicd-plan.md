# Model Platform CI/CD Expansion Plan

Steps to introduce autoscaling and blue/green deployment workflows for SageMaker endpoints.

---

## 0. Confirm Baseline
1. Select the environment folder to enhance first (e.g., `environments/ap-southeast-1`).
2. Ensure remote state exists (`terraform init` with backend config).
3. Inventory current SageMaker endpoint names.
4. Verify `Name`, `Environment`, and `AutoSchedule` tags are present.

---

## 1. SageMaker – Load Aware Scaling
1. Add scaling variables (`min_instance_count`, `max_instance_count`, `target_concurrent_requests`) to `modules/sagemaker-endpoint/variables.tf`.
2. Create `aws_appautoscaling_target` for the endpoint variant.
3. Add target-tracking policy on `ConcurrentRequestsPerModel` metric.
4. Optional: CloudWatch alarms for GPU utilization or latency.
5. Test scaling under load.

---

## 2. SageMaker – S3 Triggered Blue/Green
1. Add S3 event notifications (EventBridge) for `ObjectCreated` events on model prefix.
2. Create orchestration IAM roles (CodePipeline, CodeBuild, Lambda).
3. Create `modules/sagemaker-deployment-pipeline` with:
   - CodePipeline (Source → Build → Deploy stages)
   - CodeBuild for validation (checksum, schema checks)
   - Lambda orchestrator for blue/green traffic shifting
4. Wire pipeline in environment, passing bucket name, endpoint names, deployment preferences.
5. Blue/green safety: clone current config as blue, deploy new as green, shift 10% traffic, health check, then complete shift.
6. Dry run with dummy model upload.

---

## 3. Governance & Testing
1. Terraform validation pipeline (`terraform fmt`/`validate` in CodeBuild).
2. Extend `common/tests` with smoke tests for CodeBuild and deployment hooks.
3. Ensure Lambda and CodeBuild logs stream to CloudWatch with proper retention.
4. Update documentation with deployment trigger instructions and approval points.

---

### Deliverables Checklist
- [ ] Updated SageMaker module with autoscaling resources and new variables.
- [ ] Event-driven model deployment pipeline module instantiated per environment.
- [ ] Smoke tests and alarm integrations for deployment flows.
- [ ] Documentation refreshed to explain operational runbooks.
