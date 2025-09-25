import express from 'express';
import { createProxyMiddleware } from 'http-proxy-middleware';

const app = express();

const API_TARGET = process.env.API_TARGET || 'http://localhost:8000';
const PORT = parseInt(process.env.PORT || '8080', 10);

// Proxy /api/* to your backend, changeOrigin helps with CORS
app.use('/api', createProxyMiddleware({
  target: API_TARGET,
  changeOrigin: true,
  xfwd: true,
  logLevel: 'warn',
}));

app.get('/', (_req, res) => {
  res.type('text/plain').send('Dev proxy running. Set API_BASE=http://localhost:' + PORT);
});

app.listen(PORT, () => {
  console.log(`Dev proxy listening on http://localhost:${PORT} -> ${API_TARGET}`);
});
