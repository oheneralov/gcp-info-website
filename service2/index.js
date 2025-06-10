const express = require('express');
const app = express();
const port = 3001;
bodyParser = require('body-parser');
const redis = require('redis');


app.use(bodyParser.json());

// Connect to Redis
const client = redis.createClient({
  socket: {
    host: 'redis', // service name
    port: 6379,
  }
});
client.connect().catch(console.error);

app.use(express.json());

app.post('/data', async (req, res) => {
  try {
    const { key, value } = req.body;
    if (!key || !value) return res.status(400).json({ error: 'Missing key or value' });

    await client.set(key, JSON.stringify(value));
    res.status(200).json({ message: 'Saved' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/data/:key', async (req, res) => {
  try {
    const value = await client.get(req.params.key);
    if (!value) return res.status(404).json({ error: 'Not found' });

    res.status(200).json({ value: JSON.parse(value) });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


app.get('/', (req, res) => {
  const organizations = [
    { id: 1, name: 'Org1' },
    { id: 2, name: 'Org2' },
  ];
  res.json(organizations);
});

app.post('/', function (req, res) {
  const body = req.body;
  /*Body logic here*/
  res.json({ message: 'Organization created' });
})

app.listen(port, () => {
  console.log(`Service 2 is running on port ${port}`);
});
