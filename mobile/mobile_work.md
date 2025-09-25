# Mobile Work Summary

This document summarizes the mobile (Flutter) work completed to date and what’s next as we shift to backend tasks.

Summary

- Implemented end-to-end app flow: Login → Microgrid Selection → Dashboard → Alerts → Devices → Device Details
- Added robust data layer with caching, retry, and providers; polished UI/UX for reliability and clarity

Key features delivered

- App architecture
  - Riverpod-based providers and repository layer
  - ApiClient wrapper (injectable http.Client for tests)
  - Exponential backoff (retryAsync) for network calls
  - Offline caching (shared_preferences) for KPIs, alerts, historical, devices
  - Connectivity indicator (online/offline badge in header)

- Screens & UX
  - Login screen (prototype auth flow)
  - Microgrid Selection (list + fallback stub)
  - Dashboard
    - KPI gauges: Consumption, Generation, Battery SoC
    - “More telemetry” dropdown (DC bus V/A, AC V/Hz, grid-tie, equipment temp, solar irradiance, ambient temp, humidity)
    - Historical chart:
      - Real timestamps on x-axis, adaptive label density, range slider zoom, refresh button
    - Alerts carousel + Alerts screen with detail and acknowledge
    - Pull-to-refresh (KPIs, alerts, historical) and retry affordances
    - Cached-data banner (dismissible) with Refresh action
  - Devices
    - Devices list (retry, pull-to-refresh)
    - Device details (ID, name, status, last seen, type/firmware if available)
    - Per-device telemetry fetch with refresh (renders key-value for now)

- Notifications (Android-first)
  - Firebase Messaging scaffolding (foreground/ background handlers)
  - Runtime permission banner (Android 13+/iOS) with enable flow
  - Subscribes device to topic: critical-alerts

- Dev tooling
  - WARP.md with repo-specific commands and architecture
  - Dev proxy (tools/dev-proxy) to avoid browser CORS in web runs
  - Admin-only FCM sender (tools/fcm-send) to send topic notifications from a service account

Quality & tests

- Repository unit tests covering:
  - Production vs. prototype fallback
  - Cache returns on failure (summary, alerts, historical)
  - Acknowledge success/failure
  - Historical granularity parameter
- Analyzer: 0 errors (one benign warning about missing flutter_lints include)

What remains on mobile (near-term polish)

- Device detail telemetry: visualize with bars/gauges if backend provides stable schema (keys, units, ranges)
- Optional: More widget tests (dashboard gauges, device list/detail, alerts)
- Optional: Alerts list top-level Refresh button (in addition to retry)

Backend next (Phase 2)

- AWS IoT Core
  - Thing registry, certs/policies per device, secure MQTT topics: microgrid/{grid_id}/device/{device_id}/telemetry and microgrid/{grid_id}/alerts
  - IoT Rules routing to Kinesis/Lambda
- ETL & Storage
  - Kinesis stream or Firehose buffer
  - Lambda ETL with schema validation, enrichment, DLQ
  - InfluxDB Cloud: buckets, retention, downsampling for historical querying
  - DynamoDB: alerts store (active/resolved, timestamps, device, severity)
- API (FastAPI on Fargate behind ALB)
  - Cognito auth (JWT), RBAC (Operator/Admin)
  - Endpoints: dashboard summary, alerts (list/ack), historical, devices list/detail
- Monitoring & CI/CD
  - CloudWatch dashboards/alarms; structured logs
  - GitHub Actions/CodePipeline for build & deploy
  - IaC (Terraform/CloudFormation) for reproducible environments

Notes

- Keep android/app/google-services.json local (recommended) unless you explicitly choose to commit it.
- For Flutter web development against local backend, prefer running via the dev proxy to avoid CORS.
