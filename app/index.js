const express = require('express');
const redis = require('redis');
const app = express();
const PORT = process.env.PORT || 3000;
let redisClient = null;
async function getRedis() {
  if (redisClient) return redisClient;
  try {
    redisClient = redis.createClient({
      socket: {
        host: process.env.REDIS_HOST || 'localhost',
        port: 6379
      },
      disableOfflineQueue: true
    });
    redisClient.on('error', () => {});
    await redisClient.connect();
    return redisClient;
  } catch (e) {
    return null;
  }
}
const HOTELS = [
  { id: 1, name: 'Accra Beach Hotel', city: 'Accra', price: 120, rating: 4.8 },
  { id: 2, name: 'Kumasi Royal Hotel', city: 'Kumasi', price: 85, rating: 4.6 },
  { id: 3, name: 'Cape Coast Castle View', city: 'Cape Coast', price: 95, rating: 4.7 },
  { id: 4, name: 'Takoradi Harbour Hotel', city: 'Takoradi', price: 70, rating: 4.4 },
  { id: 5, name: 'Tamale Savanna Lodge', city: 'Tamale', price: 60, rating: 4.5 }
];
app.get('/health', (req, res) => res.json({ status: 'ok' }));
app.get('/', (req, res) => res.json({ message: 'Hotel Booking Platform - Airbnb Clone', endpoints: ['/health', '/hotels?city=Accra', '/hotels/1'] }));
app.get('/hotels', async (req, res) => {
  const city = (req.query.city || '').toLowerCase();
  const cacheKey = 'hotels:' + (city || 'all');
  const client = await getRedis();
  if (client) {
    try {
      const cached = await client.get(cacheKey);
      if (cached) return res.json({ source: 'redis-cache', data: JSON.parse(cached) });
    } catch (e) {}
  }
  let data = HOTELS;
  if (city) data = HOTELS.filter(h => h.city.toLowerCase() === city);
  if (client) {
    try { await client.setEx(cacheKey, 60, JSON.stringify(data)); } catch (e) {}
  }
  res.json({ source: 'rds-or-memory', data });
});
app.get('/hotels/:id', (req, res) => {
  const h = HOTELS.find(x => x.id === Number(req.params.id));
  if (!h) return res.status(404).json({ error: 'Hotel not found' });
  res.json({ data: h });
});
app.listen(PORT, () => console.log('Hotel app listening on ' + PORT));
