# Phase 2 Task Backlog (derived from product_spec.md)

This backlog translates the "Phase 2 — Production Roadmap" into actionable tasks. Use the checkboxes to track progress. Priority items are listed first.

## High-Priority Next Action

- [ ] UI — Microgrid selection home screen (simple, readable, sophisticated)
  - First app page lists available microgrids for the operator to choose
  - Upon selection, open the monitoring dashboard for that microgrid (grid_id)
  - Keep UI clean and accessible; align with existing dark theme
  - Acceptance:
    - Selecting a microgrid navigates to a dashboard bound to that grid_id
    - Works on Android phones; handles empty/error states gracefully

---

## Edge & AWS IoT Core

- [ ] Provision AWS IoT Core for device connectivity
  - IoT things, X.509 certs/keys, least-privilege policies per device
  - Topics: `microgrid/{grid_id}/device/{device_id}/telemetry` and `microgrid/{grid_id}/alerts`
  - Acceptance: TLS MQTT publish succeeds; messages visible in IoT Core Test

- [ ] Define IoT Core Rules to route messages
  - Rules for telemetry and alerts to downstream targets (Kinesis or Lambda)
  - Acceptance: Test publish triggers downstream; rule metrics show success

## Kinesis and Lambda ETL

- [ ] Stand up raw streaming buffer
  - Kinesis Data Streams/Firehose for telemetry and alerts
  - Acceptance: IoT Rules deliver to Kinesis without throttling

- [ ] Implement ETL Lambda (ingress → transform → load)
  - Schema validation; data cleaning; enrichment (grid_id, device metadata via DynamoDB)
  - Load telemetry to InfluxDB Cloud; persist alerts to DynamoDB
  - DLQ for failed events
  - Acceptance:
    - Telemetry present in InfluxDB with correct measurement/fields/tags
    - Alerts in DynamoDB queryable by grid_id and status
    - <1% ETL error rate in tests

## Data Stores

- [ ] InfluxDB Cloud provisioning and retention
  - Buckets, retention policies (e.g., 30d high-res, 1y aggregated), downsampling tasks
  - Acceptance: Queries return aggregated series by period; retention enforces deletion

- [ ] DynamoDB design for alerts
  - Table keys and GSIs for queries by grid_id, status, and time
  - Acceptance: Active/resolved alert queries per grid_id <200ms avg

## Backend API (FastAPI on AWS Fargate)

- [ ] Containerize FastAPI and provision Fargate behind ALB
  - Dockerfile, ECS task/service, ALB/HTTPS, health checks
  - Acceptance: /health returns 200; rolling deploy passes

- [ ] Integrate Cognito for auth and RBAC
  - Cognito User Pool; JWT validation middleware; roles in claims (Operator, Admin)
  - Acceptance: 401 for invalid tokens; role-gated endpoints enforced

- [ ] Implement production endpoints
  - GET `/api/dashboard/summary/{grid_id}` — latest KPIs from InfluxDB
  - GET `/api/alerts/{grid_id}?status=active|resolved` — paginated alerts from DynamoDB
  - PUT `/api/alerts/{alert_id}/acknowledge` — acknowledge with operator identity
  - GET `/api/historical/{grid_id}/{metric}?period=..&granularity=..` — aggregated series
  - GET `/api/device/{grid_id}/list` — device inventory
  - Acceptance: OpenAPI generated; integration tests pass for authz, pagination, and data correctness

## Mobile Application (Flutter)

- [ ] Switch auth to Cognito-backed API
  - Replace prototype login with Cognito (hosted UI or direct); secure token storage (Keystore/Keychain)
  - Acceptance: JWTs stored securely; 401 triggers re-auth

- [ ] Replace prototype endpoints with production API contract
  - Repository layer; typed models; error/timeout handling; grid_id parameterization
  - Acceptance: Dashboard shows real data; retries and error states implemented

- [ ] Alerts UX and detail view
  - Severity color-coding, timestamps; detail screen with acknowledge action and operator notes
  - Acceptance: Acknowledge updates backend and UI; optimistic updates with rollback on error

- [ ] Offline caching and resiliency
  - Cache last-known KPIs/alerts; online/offline indicator; background refresh
  - Acceptance: App usable offline with cached data; reconciles on reconnect

- [ ] Push notifications for critical alerts (Android first)
  - FCM integration; deep links to alert detail
  - Acceptance: Critical alert triggers notification; tap opens detail

- [ ] Historical charts enhancements
  - Time-based x-axis, pinch-zoom/pan, metric overlays; loading/empty/error states
  - Acceptance: Smooth performance; correct labeling and interactions

## Security and Compliance

- [ ] End-to-end TLS and secrets hygiene
  - HTTPS everywhere; secrets in SSM/Secrets Manager; no secrets in client/repo
  - Acceptance: Security review passes; no hard-coded secrets detected

- [ ] PII/logging policy and centralized logs
  - Redaction; structured logs; correlation IDs
  - Acceptance: No sensitive fields in logs; traceable requests across services

## Monitoring and Alarming

- [ ] CloudWatch dashboards and alarms
  - Dashboards for Lambda errors/duration, ECS CPU/mem, IoT ingest, InfluxDB latency
  - Acceptance: Synthetic tests trigger alarms; runbooks updated

## CI/CD

- [ ] Backend CI/CD
  - Lint/test/build Docker; deploy to ECS with zero-downtime; approvals for prod
  - Acceptance: PRs run tests; auto-deploy to staging; manual promotion to prod

- [ ] Mobile CI
  - Analyze, test, and build Android artifacts; store artifacts; coverage reporting
  - Acceptance: Pipeline produces APK/AAB; coverage uploaded

## Deployment Readiness

- [ ] Environment config and IaC
  - Terraform/CloudFormation for IoT, Kinesis, Lambda, DynamoDB, ECS/ALB, Cognito, CloudWatch; dev/stage/prod vars
  - Acceptance: New env can be provisioned from IaC without manual steps (besides secrets)

- [ ] Operational playbooks
  - Runbooks for device disconnect storms, ETL failures, deployments, rollbacks
  - Acceptance: Playbooks reviewed and accessible
