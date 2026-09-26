-- KuryeX MVP veritabani semasi (PostgreSQL 16 + PostGIS)
-- Calistirmak icin: psql -d kuryex -f schema.sql
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE tenants (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  domain TEXT UNIQUE,
  logo_url TEXT,
  primary_color TEXT DEFAULT '#f97316',
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE zones (
  id SERIAL PRIMARY KEY,
  tenant_id INT REFERENCES tenants(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  polygon GEOMETRY(Polygon, 4326) NOT NULL,
  extra_km_fee NUMERIC(10,2) DEFAULT 8.00
);

CREATE TABLE restaurants (
  id SERIAL PRIMARY KEY,
  tenant_id INT REFERENCES tenants(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT,
  lat DOUBLE PRECISION NOT NULL,
  lng DOUBLE PRECISION NOT NULL,
  address TEXT,
  zone_id INT REFERENCES zones(id),
  tariff_0_3km NUMERIC(10,2) DEFAULT 35.00,
  tariff_3_5km NUMERIC(10,2) DEFAULT 45.00,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE couriers (
  id SERIAL PRIMARY KEY,
  tenant_id INT REFERENCES tenants(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT UNIQUE NOT NULL,
  status TEXT DEFAULT 'offline', -- offline, online, busy, full
  current_lat DOUBLE PRECISION,
  current_lng DOUBLE PRECISION,
  perf_score INT DEFAULT 80,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  tenant_id INT REFERENCES tenants(id) ON DELETE CASCADE,
  restaurant_id INT REFERENCES restaurants(id),
  courier_id INT REFERENCES couriers(id),
  status TEXT NOT NULL DEFAULT 'created', -- created, queued, assigned, picked, onway, delivered, cancelled
  delivery_lat DOUBLE PRECISION NOT NULL,
  delivery_lng DOUBLE PRECISION NOT NULL,
  delivery_addr TEXT NOT NULL,
  amount NUMERIC(10,2) NOT NULL,
  payment_type TEXT NOT NULL, -- cash, card, online
  created_at TIMESTAMPTZ DEFAULT now(),
  assigned_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ
);

CREATE TABLE order_events (
  id SERIAL PRIMARY KEY,
  order_id INT REFERENCES orders(id) ON DELETE CASCADE,
  status TEXT NOT NULL,
  actor TEXT NOT NULL, -- system, operator:1, courier:3
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 8 hareket tipli muhasebe cekirdegi
CREATE TABLE transactions (
  id SERIAL PRIMARY KEY,
  tenant_id INT REFERENCES tenants(id) ON DELETE CASCADE,
  related_order INT REFERENCES orders(id),
  related_courier INT REFERENCES couriers(id),
  related_restaurant INT REFERENCES restaurants(id),
  type TEXT NOT NULL, -- delivery_fee, km_bonus, weather_bonus, cash_collection, advance, penalty, service_charge, platform_commission
  amount NUMERIC(10,2) NOT NULL,
  direction TEXT NOT NULL, -- credit, debit
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_tenant ON orders(tenant_id);
CREATE INDEX idx_couriers_status ON couriers(status);

-- Demo verisi (Torbali operasyonu)
INSERT INTO tenants(name, domain) VALUES ('Torbali Bolgesi', 'torbali.kuryex.com');
INSERT INTO zones(tenant_id, name, polygon) VALUES
 (1, 'Torbalı Mah.', ST_GeomFromText('POLYGON((27.345 38.148, 27.362 38.148, 27.362 38.158, 27.345 38.158, 27.345 38.148))', 4326)),
 (1, 'Cumhuriyet Mah.', ST_GeomFromText('POLYGON((27.355 38.152, 27.370 38.152, 27.370 38.162, 27.355 38.162, 27.355 38.152))', 4326)),
 (1, 'Tepeköy Mah.', ST_GeomFromText('POLYGON((27.356 38.137, 27.372 38.137, 27.372 38.148, 27.356 38.148, 27.356 38.137))', 4326));
INSERT INTO restaurants(tenant_id, name, phone, lat, lng, zone_id, address) VALUES
 (1, 'Burger Ding', '0232000001', 38.1483, 27.3598, 3, 'Tepeköy, Hükümet Cd. No:3, 35860 Torbalı/İzmir'),
 (1, 'Naydanoz Döner', '0232000002', 38.1522, 27.3485, 1, 'Ertuğrul, Kazım Dirik Cd. No:61 D:B, 35860 Torbalı/İzmir'),
 (1, 'Beybos Döner', '0232000003', 38.1531, 27.3470, 1, 'Ertuğrul, Kazım Dirik Cd. No:82/A, 35860 Torbalı/İzmir'),
 (1, 'Komadene Çiğköfte', '0232000004', 38.1438, 27.3633, 3, 'Tepeköy, İsmetpaşa Cd. No:50, 35860 Torbalı/İzmir');
INSERT INTO couriers(tenant_id, name, phone, status, current_lat, current_lng, perf_score) VALUES
 (1, 'Ozan Şen', '0532000001', 'online', 38.1525, 27.3560, 92),
 (1, 'Hüsnü Can Çoban', '0532000002', 'online', 38.1560, 27.3610, 87),
 (1, 'Muhammet İşcen', '0532000003', 'online', 38.1430, 27.3620, 90),
 (1, 'Mert Uyanık', '0532000004', 'online', 38.1480, 27.3520, 84);
