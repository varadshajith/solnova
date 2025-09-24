# SOLNOVA Project Tasks / Phased Plan

This plan strictly follows `rules.md`: the spec is the single source of truth, no added scope, no assumptions. Ambiguities will halt work for clarification. Each phase maps directly to `product_spec.md` sections.

## Phase 0 — Readiness and Governance (per rules.md)
- Read `product_spec.md` end-to-end and confirm understanding.
- Identify ambiguities or contradictions (if any) and request clarification before implementation.
- Define acceptance criteria per Expected Outcome and API/UI sections.

Deliverables:
- Confirmation that spec is clear, or a “CLARIFICATION REQUIRED” note (if needed).

Acceptance Criteria:
- No open ambiguities; scope locked to the spec.

## Phase 1 — Environment Setup (Spec §2 Technical Considerations)
- Create Python virtual environment.
- Prepare dependency management: `requirements.txt` for backend/simulator; ensure pinned versions.
- Initialize project scaffolding folders for backend, simulator, and Flutter app.
- Add `.gitignore` (exclude venv, build artifacts, secrets).

Deliverables:
- Activated venv; base folders.
- `.gitignore`, `requirements.txt` (initial).

Acceptance Criteria:
- Commands in `README.md` reproduce the environment successfully.

## Phase 2 — Local Services via Docker (Spec §2, §3)
- Launch InfluxDB (time-series DB) in Docker.
- Launch Mosquitto (MQTT broker) in Docker.
- Document connection details in `.env` (not committed) and `README.md`.

Deliverables:
- Docker configurations/commands for InfluxDB and Mosquitto.
- `.env.example` with required variables.

Acceptance Criteria:
- Both services run locally and are reachable from host and Python.

## Phase 3 — Data Simulator (Spec §3.1)
- Create `data_simulator.py` using `paho-mqtt`.
- Publish payload to `microgrid/data` every ~5s with fields:
  - `timestamp` (UTC), `live_power_consumption` (5.0–15.0), `live_generation` (6.0–16.0), `battery_soc` (20–100), `temp_equipment` (30.0–70.0), `solar_irradiance` (0–100).
- Implement alert rules and publish to `microgrid/alerts`:
  - consumption > 14.0 → "Load Abnormality: Unusual load increase detected."
  - temp_equipment > 60.0 → "Predictive alert: high temperature on equipment."
  - live_generation < 7.0 and solar_irradiance > 50 → "Renewable Performance Issue: Solar output is low."

Deliverables:
- Executable simulator script; instructions in `README.md`.

Acceptance Criteria:
- MQTT topics receive compliant JSON and alerts at expected cadence.

## Phase 4 — FastAPI Backend & MQTT Ingest (Spec §3.2)
- FastAPI app with dependencies: `fastapi`, `uvicorn`, `influxdb-client`, `paho-mqtt`, `python-dotenv`.
- Connect to InfluxDB via env vars; write incoming `microgrid/data` JSON to InfluxDB.
- Subscribe to `microgrid/alerts`; store alerts in in-memory list or simple file for retrieval.
- Structure configuration via `.env`.

Deliverables:
- Backend app entrypoint and modules (MQTT client, InfluxDB client, models/schemas).

Acceptance Criteria:
- On simulator publish, backend persists data and captures alerts without errors.

## Phase 5 — REST API Endpoints (Spec §3.3)
- Implement endpoints:
  - `POST /api/login` → returns `{ "token": "prototype_token" }` when body is `{ "username": "user", "password": "password" }`.
  - `GET /api/dashboard/realtime` → latest values `{ consumption_kW, generation_kW, battery_soc }`.
  - `GET /api/dashboard/alerts` → list of active alerts `[ { id, message, timestamp, severity } ]`.
  - `GET /api/dashboard/historical?metric=...&period=...` → array of `{ time, value }`.
- Add basic token check middleware/filter for prototype endpoints where applicable.

Deliverables:
- FastAPI routes, schemas, and minimal auth check.

Acceptance Criteria:
- All endpoints return responses exactly as specified.

## Phase 6 — Flutter Mobile Prototype (Spec §2 Frontend, §4 UI/UX)
- Create Flutter app with two screens: Login, Dashboard.
- Login Screen: username/password inputs, Login button calling `POST /api/login`.
- Dashboard Screen:
  - Alerts Section (top): list view with severity-based background, shows message + timestamp, tap to view full message.
  - KPI Section: large-font KPIs for Consumption, Generation, Battery SoC using `/realtime`.
  - Historical Trends: single interactive line chart with toggle/dropdown to switch metric (Consumption, Generation, SoC), calling `/historical`.
- No additional navigation beyond login → dashboard.

Deliverables:
- Flutter project with basic theming and API client.

Acceptance Criteria:
- App runs on emulator; UI matches structure/order and behaviors specified.

## Phase 7 — Integration, Token Handling, and UX Polish
- Wire login token storage (in-memory for prototype) and attach to subsequent API calls if required by backend.
- Handle loading/error states for API calls without exposing stack traces.
- Basic input validation for login fields per security checklist.

Deliverables:
- Working end-to-end flow: login → dashboard showing live data and alerts.

Acceptance Criteria:
- Stable usage for several minutes with simulator running; no crashes.

## Phase 8 — Verification & Security Best Practices (Spec §2 checklist, §5 Expected Outcome)
- Validate against Security & Coding Best Practices:
  - Input validation, secrets via env, pinned deps, specific error handling, clean code style.
- Write simple checks/tests to confirm endpoints and UI behaviors meet spec.
- Ensure final output runs cleanly from fresh clone per README.

Deliverables:
- Minimal test/check scripts; updated `README.md` with setup/run instructions and env var usage.

Acceptance Criteria:
- All checks pass; instructions reproduce expected outcome.

## Phase 9 — Handover
- Ensure dependency files are complete, and `.gitignore` excludes secrets/venv/builds.
- Finalize `README.md` with:
  - Project description, setup, run, and usage instructions
  - Env variable guidance
  - Service prerequisites (Docker for InfluxDB/Mosquitto)

Deliverables:
- Complete runnable codebase (backend, simulator, Flutter app), `README.md`, `requirements.txt`, `.gitignore`.

Acceptance Criteria:
- Prototype demonstrates real-time data and alerts as specified in §5.

---

Dependencies and Ordering Notes
- Phases 1–2 must precede 3–5; simulator (3) and backend (4–5) should be running before Flutter integration (6–7).
- Use `.env.example` for all sensitive configuration keys; never commit real secrets.

Open Questions (blockers if unanswered)
- None at this time. Any new ambiguity will trigger a “CLARIFICATION REQUIRED” per `rules.md`.


