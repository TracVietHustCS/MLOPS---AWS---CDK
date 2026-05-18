# CI/CD Implementation Phases - ACB Project

**Target Environment:** ap-southeast-1 (primary), then ap-northeast-1
**Goal:** Full MLOps CI/CD with autoscaling and automated deployments

---

## Phase 1: SageMaker Load-Aware Autoscaling ⏱️ ~30 minutes

**Objective:** Enable automatic scaling of SageMaker endpoints based on concurrent request load.

### Tasks:
1. Add autoscaling variables to sagemaker-endpoint module
2. Add `aws_appautoscaling_target` and `aws_appautoscaling_policy` resources
3. Update environment configuration with autoscaling parameters
4. Optional: CloudWatch alarms for GPU utilization and latency

### Success Criteria:
- ✅ Endpoint scales from 1 to N instances under load
- ✅ Endpoint scales down after cooldown period
- ✅ No service disruption during scaling

---

## Phase 2: SageMaker S3-Triggered Blue/Green Deployment ⏱️ ~2-3 hours

**Objective:** Automate model deployments triggered by S3 uploads with zero-downtime blue/green strategy.

### Tasks:
1. S3 EventBridge notifications for model uploads
2. Deployment IAM roles (CodePipeline, CodeBuild, Lambda)
3. Deployment pipeline module with CodePipeline stages
4. Lambda orchestrator for blue/green traffic shifting
5. CodeBuild validation (checksum, schema checks)
6. Environment integration and testing

### Success Criteria:
- ✅ S3 upload triggers deployment automatically
- ✅ Blue/green deployment completes without downtime
- ✅ Canary validation prevents bad deployments
- ✅ Rollback works on failure

---

## Phase 3: Governance, Testing & Monitoring ⏱️ ~2-3 hours

**Objective:** Add validation, testing, and operational visibility.

### Tasks:
1. Terraform validation pipeline (fmt, validate, tflint)
2. Smoke tests for SageMaker endpoints
3. CloudWatch dashboards (invocations, latency, errors, instance count)
4. CloudWatch alarms with SNS notifications
5. Documentation updates

### Success Criteria:
- ✅ Terraform changes validated in CI
- ✅ Automated tests run on deployments
- ✅ Monitoring dashboards provide visibility
- ✅ Alerts notify on failures

---

## Implementation Timeline

| Phase | Duration | Dependencies | Status |
|-------|----------|--------------|--------|
| Phase 1: SageMaker Autoscaling | 30 min | None | ✅ Done |
| Phase 2: SageMaker Blue/Green | 2-3 hours | Phase 1 (optional) | ⏸️ Pending |
| Phase 3: Governance & Testing | 2-3 hours | Phase 2 | ⏸️ Pending |

**Total Estimated Time:** 5-7 hours
