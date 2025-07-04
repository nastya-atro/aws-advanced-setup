const PORT = 3002;
const express = require('express');
const { SFNClient, StartExecutionCommand } = require('@aws-sdk/client-sfn');

const app = express();
const sfnClient = new SFNClient({});

app.use(express.json());

const apiKeyMiddleware = (req, res, next) => {
  const apiKey = req.get('X-API-KEY');
  if (apiKey && apiKey === process.env.CHECK_SERVICE_API_KEY) {
    next();
  } else {
    res.status(401).send('Unauthorized');
  }
};

app.post('/check', apiKeyMiddleware, async (req, res) => {
  console.log('Received payload:', req.body);

  const { latitude, longitude, email, name } = req.body;

  if (!latitude || !longitude || !email || !name) {
    return res.status(400).json({
      error: 'Invalid request body. Missing latitude, longitude, email, or name.',
    });
  }

  const stepFunctionArn = process.env.STEP_FUNCTION_ARN;
  if (!stepFunctionArn) {
    console.error('STEP_FUNCTION_ARN environment variable not set.');
    return res.status(500).send({ message: 'Server configuration error.' });
  }

  const sfnInput = {
    latitude,
    longitude,
    email,
    name,
  };

  const command = new StartExecutionCommand({
    stateMachineArn: stepFunctionArn,
    input: JSON.stringify(sfnInput),
  });

  try {
    const response = await sfnClient.send(command);
    console.log('Step Function execution started:', response.executionArn);
    res.status(202).send({
      message:
        'Check request accepted. You will be notified by email if your location is affected.',
      executionArn: response.executionArn,
    });
  } catch (error) {
    console.error('Failed to start Step Function execution:', error);
    res.status(500).send({ message: 'Failed to process request.' });
  }
});

app.listen(PORT, () => {
  console.log(`check-service listening on port ${PORT}`);
});
