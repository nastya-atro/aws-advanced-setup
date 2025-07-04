# Check Service API

This service provides an API endpoint to trigger the location checking workflow and check the status of a request.

---

## API Usage

### 1. Trigger a new check

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

This request will trigger the workflow to check the specified location. The response will contain an `executionArn` which you can use to check the status of your request.

### 2. Check the status of a request

You can check the status of a previously submitted request using the `executionArn`.

**API Details:**

- **Endpoint URL:** `http://<CHECK_SERVICE_IP>:3002/check/status/<EXECUTION_ARN>`
- **Method:** `GET`
- **Headers:**
  - `X-API-Key`: The API key you provided in the `check_service_api_key` Terraform variable.

**Example Request with `curl`:**

```bash
curl http://<YOUR_CHECK_SERVICE_IP>:3002/check/status/<YOUR_EXECUTION_ARN> \
  -H 'X-API-Key: <YOUR_API_KEY>'
```

**Example Response:**

```json
{
  "executionArn": "arn:aws:states:us-east-1:123456789012:execution:OnDemandCheckWorkflow:your-execution-id",
  "status": "SUCCEEDED",
  "startDate": "2023-10-27T10:30:00.123Z",
  "stopDate": "2023-10-27T10:30:05.456Z",
  "result": {
    "isAffected": true,
    "locationName": "My Favorite Location",
    "userEmail": "user@example.com"
  }
}
```
