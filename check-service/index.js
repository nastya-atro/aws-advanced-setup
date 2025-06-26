const PORT = 3002;
const express = require('express');
const app = express();

app.use(express.json());

app.get('/', (req, res) => {
  res.send('check-service is running');
});

app.listen(PORT, () => {
  console.log(`check-service listening on port ${PORT}`);
});
