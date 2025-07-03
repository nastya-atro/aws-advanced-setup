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

app.post('/check', apiKeyMiddleware, (req, res) => {
  console.log('Received payload:', req.body);
  res.send({ status: 'ok', received: req.body });
});

app.listen(PORT, () => {
  console.log(`check-service listening on port ${PORT}`);
});
