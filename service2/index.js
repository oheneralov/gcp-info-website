const express = require('express');
const app = express();
const port = 3001;

app.get('/', (req, res) => {
  res.send('Hello from Service 2!');
});

app.listen(port, () => {
  console.log(`Service 2 is running on port ${port}`);
});
