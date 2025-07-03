# check-service

A simple Node.js service using Express.

## How to run

### With Node.js
```
cd check-service
node index.js
```
The service will be available at http://localhost:3002/

### With Docker Compose
```
docker compose up --build
```
The service will be available at http://localhost:3002/

## API Endpoints

### GET /
Returns a simple status message.

### GET /health
Returns `{ "status": "ok" }` to indicate the service is healthy.

### POST /check
Accepts JSON: `{ "value": "some string" }`
- Returns `{ "valid": true, "message": "Value is valid." }` if value is a non-empty string.
- Returns 400 and `{ "valid": false, "message": "Invalid value." }` otherwise. 