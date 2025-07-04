# Check Service API

This service provides an API endpoint to trigger the location checking workflow.

---

## API Usage

The `check-service` provides an API endpoint to check if a given geographic location is affected by known weather events.

**API Details:**

- **Endpoint URL:** `http://<CHECK_SERVICE_IP>:3002/check`
  - The `<CHECK_SERVICE_IP>` is the value of the `check_service_instance_ip` output from your `terraform apply` command.
- **Method:** `POST`
- **Headers:**
  - `Content-Type: application/json`
  - `X-API-Key`: The API key you provided in the `check_service_api_key` Terraform variable.

**Example Request with `curl`:**

Replace the placeholders with your actual IP address, API key, and location data.

```bash
curl -X POST \
  http://<YOUR_CHECK_SERVICE_IP>:3002/check \
  -H 'Content-Type: application/json' \
  -H 'X-API-Key: <YOUR_API_KEY>' \
  -d '{
    "latitude": 40.7128,
    "longitude": -74.0060,
    "email": "user@example.com",
    "name": "My Favorite Location"
  }'
```

This request will trigger the workflow to check the specified location. The details of the response will be added here later.
