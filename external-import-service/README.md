# external-import-service

A Node.js service that launches two child processes, each running a scheduled cron job. **This service does not expose any ports or provide an HTTP API.**

## How to run

### With Node.js

```
cd external-import-service
node index.js
```

### With Docker Compose

```
docker compose up --build
```

## Structure

- **index.js**: Starts two child processes:
  - `child_processes/upload-fire-forecast.js`: Runs a cron job every hour at :00
  - `child_processes/upload-earthquake.js`: Runs a cron job every hour at :30

Each child process uses [node-cron](https://www.npmjs.com/package/node-cron) for scheduling.

## Extending

Add your logic to the respective files where indicated.
