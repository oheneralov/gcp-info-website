// app.js
const express = require('express');
const path = require('path');
const expressLayouts = require('express-ejs-layouts');

const app = express();
const PORT = 3000;

// Set the view engine to EJS
app.set('view engine', 'ejs');

// Use express-ejs-layouts

// Serve static files from the "public" directory
app.use(express.static(path.join(__dirname, 'public')));


// Home route
app.get('/', (req, res) => {
  res.render('index', { title: 'Info Page' });
});

// Info page route
app.get('/setup-jenkins-gcp-traefik-kube', (req, res) => {
  res.render('setup-jenkins-gcp-traefik-kube', { title: 'Info Page' });
});

// Start the server
app.listen(PORT, () => {
  console.log(`Server1 is running on http://localhost:${PORT}`);
});
