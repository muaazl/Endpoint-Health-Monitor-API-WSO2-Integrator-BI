# Endpoint Health Monitor API (WSO2 Integrator: BI)

A small Customer Success–style utility to validate upstream endpoint availability and latency.

## What it does
- Exposes:
  - `GET /monitor/ping` → quick “is this service running?”
  - `POST /monitor/check` → checks multiple upstream endpoints and returns:
    - status code (if available)
    - latency (ms)
    - error (if failed)

## Run (local)
1. Open the project in VS Code with the WSO2 Integrator: BI extension.
2. Run the integration using the **Try It** panel (top-right) and click **Run Integration** when prompted.

## Test

### Ping
```bash
curl -s http://localhost:9090/monitor/ping
```

### Check
```bash
curl -s http://localhost:9090/monitor/check \
  -H "Content-Type: application/json" \
  -d '{
    "targets": [
      { "name": "Example", "baseUrl": "https://apis.wso2.com", "path": "/", "timeoutSeconds": 10 }
    ]
  }'
```

## Evidence
- Ping: GET /monitor/ping
- Check: POST /monitor/check (example.com = UP, localhost:9999 = DOWN)
- Screenshots: see `evidence/` folder