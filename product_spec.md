1. Overview
This project's goal is to create a functional prototype of a mobile application for a microgrid monitoring system. The application will serve as the primary interface for community operators, providing them with real-time data and actionable alerts to manage microgrid efficiency and maintenance needs. The prototype will demonstrate core functionality using simulated data, a login page, a real-time dashboard, and an integrated alerts system. The project focuses on validating the user experience before moving to a production-ready system.

2. Technical Considerations
The coding agent should follow these instructions to set up the development environment and backend services.

Virtual Environment: Always create and activate a dedicated Python virtual environment for this project. Use python3 -m venv venv and source venv/bin/activate.


Backend Technology: The backend is a Python-based FastAPI application.


Database: Use a local instance of InfluxDB for time-series data storage. The easiest way to run this is in a Docker container.


Message Broker: Use a local instance of Eclipse Mosquitto for MQTT messaging. This can also be run in a Docker container.

Data Simulation: A Python script must be created to generate and publish simulated microgrid data and alerts to the local MQTT broker.


Frontend Technology: The mobile application should be built using Flutter, a cross-platform framework.

Authentication: Implement a basic, token-based authentication system for the login page. This will involve a POST /api/login endpoint that returns a simple, hard-coded token for this prototype.

3. Data Simulation & Backend Setup
This is the most critical technical task for the prototype. The coding agent must build a data simulator and a backend to ingest and serve this data.

3.1. Simulator Script
Create a Python script named data_simulator.py. This script will connect to the local MQTT broker and publish data payloads.

Dependencies: paho-mqtt.

Functionality:

Initialize an MQTT client and connect to the local Mosquitto broker.

Define a JSON payload with the following fields:

timestamp: Current UTC timestamp.

live_power_consumption: A randomly generated float value (e.g., between 5.0 and 15.0).

live_generation: A randomly generated float value (e.g., between 6.0 and 16.0).

battery_soc: A randomly generated integer value (e.g., between 20 and 100).

temp_equipment: A randomly generated float value (e.g., between 30.0 and 70.0).

solar_irradiance: A randomly generated integer value (e.g., between 0 and 100).

Publish this JSON payload to the MQTT topic microgrid/data at a regular interval (e.g., every 5 seconds).

Implement simple, rule-based logic to trigger alerts:

If live_power_consumption is greater than 14.0, publish an alert message to the microgrid/alerts topic: "Load Abnormality: Unusual load increase detected."

If temp_equipment is greater than 60.0, publish an alert message to microgrid/alerts: "Predictive alert: high temperature on equipment."

If live_generation is less than 7.0 and solar_irradiance is greater than 50, publish an alert message to microgrid/alerts: "Renewable Performance Issue: Solar output is low."

3.2. FastAPI Backend Service
Create a FastAPI application that acts as the API layer for the mobile app.

Dependencies: fastapi, uvicorn, influxdb-client, paho-mqtt, python-dotenv.

Functionality:

Connect to the local InfluxDB instance using a configuration file or environment variables.

Create an MQTT client that subscribes to both microgrid/data and microgrid/alerts.

Implement a message handler that, upon receiving a new MQTT message from microgrid/data, parses the JSON payload and writes it to InfluxDB.

Implement a separate message handler that, upon receiving a message from microgrid/alerts, stores the alert in an in-memory list or a simple file for retrieval.

3.3. API Endpoints
The backend must expose the following RESTful API endpoints for the Flutter application to consume.

POST /api/login

Description: Authenticates the user.

Request Body: {"username": "user", "password": "password"}.

Response: {"token": "prototype_token"}. For this prototype, a simple hard-coded token is sufficient.

GET /api/dashboard/realtime

Description: Returns the most recent data for the real-time KPIs.

Response: {"consumption_kW": 10.5, "generation_kW": 9.8, "battery_soc": 75}.

GET /api/dashboard/alerts

Description: Returns a list of all active alerts.

Response: [{"id": "alert-1", "message": "Load Abnormality: Unusual load increase detected.", "timestamp": "...", "severity": "warning"}].

GET /api/dashboard/historical

Description: Returns historical data points for a selectable metric.

Request Params: metric (e.g., consumption_kW), period (e.g., 24h).

Response: [{"time": "...", "value": 10.5}, {"time": "...", "value": 10.8}, ...].

4. User Flow & UI/UX Requirements
The mobile application should be a single-screen dashboard with a login page, optimized for clarity and ease of use.

Login Screen:

A simple screen with two input fields for username and password, and a "Login" button.

Dashboard Screen:

Alerts Section (High Priority): Located at the very top of the screen . This section should be a list view of alerts. Each list item should have a different background color based on severity and display a concise message and timestamp. Tapping an item should show a full alert message.

KPI Section: Below the alerts, display the three key metrics in large, legible font: Live Power Consumption, Live Generation, and Battery State of Charge (SoC).

Historical Trends Section: Below the KPIs, display a single interactive line chart . The chart should have a dropdown or toggle buttons to switch between different data streams (e.g., Consumption, Generation, SoC).

Navigation: There is no navigation beyond the login screen and the main dashboard. All information is available on a single screen.

5. Expected Outcome
The final deliverable will be a working Flutter mobile app prototype that, when connected to the local backend, displays simulated real-time data and alerts on its dashboard. The data will be stored in InfluxDB, and the alerts will be triggered by simple logic in the data simulator script. This prototype will be a complete proof-of-concept demonstrating the system's core value proposition for operators.


Sources






## Phase 2 — Production Roadmap

### Introduction & Context
Congratulations on completing the prototype! The successful demonstration of the core monitoring and alerting functionalities with simulated data has validated the fundamental concept. This document outlines the requirements and enhancements needed to evolve the prototype into a robust, secure, and scalable production-level Microgrid Monitoring System. This phase focuses on real-world data integration, enhanced security, operational stability, and preparing for deployment in rural community environments.

### 1. Core Objectives for Phase 2
- Real-World Data Integration: Transition from simulated data to actual sensor data from edge devices.
- Full Cloud-Native Backend: Implement the complete AWS-based ETL pipeline and backend services.
- Robust Security: Implement comprehensive authentication, authorization, and data encryption.
- Enhanced Reliability: Ensure the system can handle failures gracefully and maintain data integrity.
- Operational Scalability: Design for growth, supporting a larger number of microgrids and devices.
- Improved User Experience (UX): Refine the mobile app based on prototype feedback, adding necessary features.
- Deployment Readiness: Prepare for installation and ongoing management in target rural environments.

### 2. Detailed Monitoring & Data Points (Confirmed for Production)
All metrics identified previously are now confirmed for real-time monitoring and historical logging. This includes:

- Energy Flow & Performance
  - Live Power Consumption (kW)
  - Live Power Generation (kW)
  - Battery State of Charge (SoC) (%)
  - DC Bus Voltage (V) & Current (A)
  - AC Output Voltage (V) & Frequency (Hz)
  - Grid-Tie Status (On/Off, Connected/Disconnected)

- System Health & Diagnostics
  - Equipment Temperature (°C): For critical components (batteries, inverters, transformers, cabinets).
  - Communication Link Status (Connected/Disconnected, Last Seen Timestamp per device)

- Environmental Context
  - Solar Irradiance (W/m²)
  - Ambient Temperature (°C)
  - Humidity (%)

### 3. Production-Ready Backend Architecture & ETL Pipeline
The shift from the local prototype setup to a fully cloud-native, scalable architecture is paramount.

#### 3.1. Data Ingestion & Edge Connectivity
- Edge Device Firmware: Update ESP32 firmware to connect directly to AWS IoT Core using secure MQTT/TLS. Implement robust error handling, offline data buffering, and retransmission.
- AWS IoT Core Setup:
  - Configure AWS IoT Core for secure device connection, including X.509 certificates and policies for each device.
  - Define MQTT topics for telemetry (microgrid/{grid_id}/device/{device_id}/telemetry) and alerts (microgrid/{grid_id}/alerts).
  - Establish AWS IoT Core Rules Engine rules to filter and route messages.

#### 3.2. ETL Pipeline (AWS Lambda & Kinesis)
- Raw Data Stream (optional but recommended for resilience): Route raw data to Amazon Kinesis Data Firehose or Kinesis Data Streams to provide a durable buffer for higher volumes.
- ETL Lambda Function:
  - Triggered by AWS IoT Core Rules Engine (or Kinesis).
  - Extract: Receives raw JSON payload from IoT Core/Kinesis.
  - Transform:
    - Schema Validation: Enforce a strict schema for incoming data.
    - Data Cleaning: Handle nulls, incorrect types, and out-of-range values.
    - Data Enrichment: Add metadata (e.g., geo coordinates, device type, microgrid ID from a lookup in DynamoDB).
    - Unit Conversion: Standardize units if raw sensors provide varying formats.
  - Load: Write transformed data to InfluxDB Cloud.
  - Error Handling: Implement dead-letter queues (DLQs) for failed Lambda invocations.

#### 3.3. Data Storage & Querying
- InfluxDB Cloud:
  - Provision a production-tier instance.
  - Define retention policies (e.g., high-resolution for 30 days, aggregated for 1 year).
  - Implement downsampling/aggregation (e.g., 5-minute averages, hourly sums) to optimize query performance.
- Alerts Database (Amazon DynamoDB): Store detailed alert records (severity, timestamp, microgrid ID, device ID, resolution status, operator notes).

#### 3.4. Backend API Services (FastAPI on AWS Fargate)
- Deployment: Containerize FastAPI and deploy on AWS Fargate behind an ALB for scalability/reliability.
- Authentication & Authorization:
  - Integrate Amazon Cognito for user management and JWT issuance.
  - Implement Role-Based Access Control (RBAC) with roles (e.g., Community Operator, Admin) and permissions.
  - Validate JWTs on every API request.
- API Endpoints:
  - POST /api/auth/login — Authenticate via Cognito; returns JWT.
  - GET /api/dashboard/summary/{grid_id} — Real-time KPIs for a specific microgrid.
  - GET /api/alerts/{grid_id}?status={active|resolved} — Paginated, filterable alerts.
  - PUT /api/alerts/{alert_id}/acknowledge — Acknowledge alert with operator identity.
  - GET /api/historical/{grid_id}/{metric}?period=..&granularity=.. — Aggregated historical data.
  - GET /api/device/{grid_id}/list — List connected devices.
  - POST /api/device/{device_id}/command — (Future) Device commands via IoT Shadows/MQTT.

### 4. Mobile Application (Flutter) Enhancements
#### 4.1. UI/UX
- Adaptive layouts for various device sizes/orientations.
- Clear loading states, error messaging, and retry.
- Partial offline capability (cache recent data/alerts) with online/offline indicators.
- Push Notifications (AWS Pinpoint or FCM) for critical alerts.
- Alert Detail View: ID, type, severity, timestamp, affected device, recommended action, Acknowledge button, operator notes.
- Historical Charts: pinch-zoom/pan, multi-metric overlays, export data.

#### 4.2. Security & Performance
- Secure credential storage (Android Keystore/iOS Keychain) for tokens.
- Enforce HTTPS/TLS end-to-end.
- Performance tuning: request batching, caching, reduced rebuilds.

### 5. Monitoring, Logging & DevOps
- Centralized Logging: Aggregate app, Lambda, Fargate logs in CloudWatch.
- System Monitoring: Dashboards for Lambda errors/duration, Fargate CPU/memory, InfluxDB performance, IoT ingest rates.
- Alerting & Alarms: CloudWatch Alarms for critical thresholds (e.g., high Lambda error rate, device disconnects).
- CI/CD: CodePipeline/CodeBuild or GitHub Actions for automated tests and deployments.

### 6. Future Enhancements (Post-Production)
- XAI integration for anomaly detection.
- Remote control capabilities for edge devices.
- Reporting & analytics on energy usage and efficiency.
- Admin UI for user/role management.
- Multi-microgrid management overview.

