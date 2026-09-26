// KuryeX Backend Iskeleti (MVP mock - gercek DB Faz 1'de baglanacak)
// Calistir: cd backend; npm install; npm start
// Panel prototipi su an tamamen frontend simülasyonla calisiyor.
// Bu dosya, gercek projeye geciste API kontratini sabitler.
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

let orders = [];
let seq = 100;

// REST: siparis olustur (POS / pazaryeri webhook buraya post eder)
app.post('/api/v1/orders', (req, res) => {
  const o = { id: ++seq, status: 'queued', createdAt: new Date().toISOString(), ...req.body };
  orders.push(o);
  io.to(`tenant_${o.tenantId || 1}`).emit('order:created', o);
  // TODO: dispatch worker tetiklenecek (skor + Redis kuyruk)
  res.status(201).json(o);
});

// REST: manuel atama (panelden surukle-birak)
app.post('/api/v1/orders/:id/assign', (req, res) => {
  const o = orders.find(x => x.id == req.params.id);
  if (!o) return res.status(404).json({ error: 'not found' });
  o.status = 'assigned';
  o.courierId = req.body.courierId;
  o.assignedAt = new Date().toISOString();
  io.to(`tenant_${o.tenantId || 1}`).emit('order:assigned', o);
  res.json(o);
});

// REST: kurye durum degisimi (aldi / yolda / teslim)
app.post('/api/v1/orders/:id/status', (req, res) => {
  const o = orders.find(x => x.id == req.params.id);
  if (!o) return res.status(404).json({ error: 'not found' });
  o.status = req.body.status;
  if (o.status === 'delivered') {
    o.deliveredAt = new Date().toISOString();
    // TODO: muhasebe motoru: delivery_fee + km_bonus + service_charge yaz
  }
  io.to(`tenant_${o.tenantId || 1}`).emit('order:status', o);
  res.json(o);
});

app.get('/api/v1/orders', (req, res) => res.json(orders));

const server = http.createServer(app);
const io = new Server(server, { cors: { origin: '*' } });

io.on('connection', (socket) => {
  // Kurye uygulamasi: socket.emit('join', { tenantId, courierId })
  socket.on('join', ({ tenantId }) => socket.join(`tenant_${tenantId || 1}`));
  // Kurye konum: socket.emit('location', { courierId, lat, lng })
  socket.on('location', (p) => socket.to(`tenant_${p.tenantId || 1}`).emit('courier:location', p));
});

server.listen(3001, () => console.log('KuryeX mock API: http://localhost:3001'));
