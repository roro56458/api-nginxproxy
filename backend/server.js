//You can't modify it without crediting me in the code or forking it on github
const express = require('express');
const fs = require('fs');
const path = require('path');
const app = express();
const { exec } = require('child_process');
const port = 3000;

app.get('/api/nginx', (req, res) => {
  const {
    ip,
    port: serverPort,
    ip_acces_path = '',
    https_ip = 'no',
    domaine_names,
    ssl = 'no',
    request_ssl = 'no',
    ssl_certif_name = '',
    force_ssl = 'no',
    hsts_enable = 'no'
  } = req.query;

  if (!ip || !serverPort || !domaine_names) {
    return res.status(400).send('Missing required parameters: ip, port, and domaine_names are mandatory');
  }

  const domain = domaine_names;
  const accessPath = ip_acces_path ? `/${ip_acces_path}` : '';
  const httpsPort = https_ip === 'yes' ? '443' : serverPort;

  let nginxConfig = `
server {
    listen 80;
    server_name ${domain};
    location / {
        proxy_pass http://${ip}:${serverPort}${accessPath};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
`;

  // Gestion du SSL
  if (ssl === 'yes') {
    nginxConfig += `
    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/${ssl_certif_name || domain}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${ssl_certif_name || domain}/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    `;
  }

  // Forcer les requêtes HTTP à être redirigées vers HTTPS
  if (force_ssl === 'yes') {
    nginxConfig += `
    if ($scheme != "https") {
        return 301 https://$host$request_uri;
    }
    `;
  }

  // Gestion de l'HSTS (HTTP Strict Transport Security)
  if (hsts_enable === 'yes') {
    nginxConfig += `
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    `;
  }

  nginxConfig += `
}
`;

// Enregistrement du fichier de configuration Nginx
const filePath = path.join(__dirname, 'config', `${domain}.conf`);
fs.writeFile(filePath, nginxConfig, (err) => {
  if (err) {
    return res.status(500).send('Error writing Nginx configuration file');
  }

  // Recharger Nginx après avoir enregistré la configuration
  exec('sudo nginx -s reload', (err, stdout, stderr) => {
    if (err) {
      console.error(`Error reloading Nginx: ${stderr}`);
      return res.status(500).send('Error reloading Nginx');
    }

    res.send(`Nginx config generated for domain: ${domain} and Nginx reloaded`);
  });
});
});
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Readme-api</title>
        <style>
            body {
                margin: 0;
                padding: 0;
                background-color: #00353F; /* Gris-bleu foncé */
            }
            iframe {
                width: 100vw;
                height: 100vh;
                border: none;
            }
        </style>
    </head>
    <body>
        <iframe src="https://readme-api.chtrg.fr/"></iframe>
    </body>
    </html>
  `);
});
app.listen(port, () => {
  console.log(`API is running on http://localhost:${port}`);
});
