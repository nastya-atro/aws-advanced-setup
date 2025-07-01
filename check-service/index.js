const PORT = 3002;
const express = require('express');
const app = express();

app.use(express.json());

const apiKeyMiddleware = (req, res, next) => {
  const apiKey = req.get('X-API-KEY');
  if (apiKey && apiKey === process.env.CHECK_SERVICE_API_KEY) {
    next();
  } else {
    res.status(401).send('Unauthorized');
  }
};

app.get('/', (req, res) => {
  res.send('check-service is running');
});

app.get('/check', apiKeyMiddleware, (req, res) => {
  res.send({ status: 'ok', timestamp: new Date() });
});

app.listen(PORT, () => {
  console.log(`check-service listening on port ${PORT}`);
});
