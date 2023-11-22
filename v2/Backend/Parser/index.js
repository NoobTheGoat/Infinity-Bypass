// Import The Modules
const fs = require('fs');
const http = require('http');
const url = require('url');

const gradient = require('./gradient.js');

// Gradient logging function

async function log(message, colorName) {
  gradient.log(message, colorName);
}

// Create http server
const server = http.createServer(async (req, res) => {
  const parsedUrl = url.parse(req.url, true);

  if (req.method === 'POST' && parsedUrl.pathname === '/SetJson') {
    console.log('Received a POST request to /SetJson');

    let body = '';

    req.on('data', (chunk) => {
      body += chunk;
    });

    req.on('end', () => {
      try {
        const dataObject = JSON.parse(body);
        const dataJ = dataObject.DataJ;

        // Process the dataJ as needed
        // console.log('Received DataJ:', dataJ);

        const name = writeDataFile(dataJ);

        res.statusCode = 200;
        res.end(`{ status: "Success!", file_name: "${name} }", url: "http://parser.rshift4496.repl.co${name}"`);
      } catch (error) {
        console.error('Error parsing JSON:', error);
        res.statusCode = 400; // Bad Request
        res.end('Invalid JSON');
      }
    });
  }
  else if (req.method === 'GET' && (parsedUrl.pathname.endsWith('.json') || parsedUrl.pathname.endsWith('.lua')) && parsedUrl.pathname.startsWith('/')) {
    const fileName = `.${parsedUrl.pathname}`; // Construct the filename based on the URL path
    try {
      const data = fs.readFileSync(fileName, 'utf8'); // Read the JSON file
      res.setHeader('Content-Type', 'application/json');
      res.statusCode = 200;
      res.end(data); // Respond with the file content
    } catch (err) {
      console.error(err);
      res.statusCode = 500;
      res.end('Internal Server Error');
    }
  }
  else {
    res.statusCode = 202;
    res.write("I'm alive");
    res.end();
  }
});

function writeDataFile(data) {
    const fileName = `./DataJsons/data_${Math.floor(Math.random() * 1000000)}.json`;
    fs.writeFileSync(fileName, data);
    console.log(`File ${fileName} has been written.`);
    return fileName.substring(1);
}

// Listen On Port
const PORT = parseInt(process.env.PORT) || 3000;
server.listen(PORT, () => {
  log(`Server is running on port ${PORT}`, 'green');
});