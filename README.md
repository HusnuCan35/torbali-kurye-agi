# 🛵 Torbalı Kurye Ağı — Proje Klasörü (v0.2)

Bölgeler: **Torbalı Mah. • Cumhuriyet Mah. • Tepeköy Mah.**
Kadro: **Ozan Şen • Hüsnü Can Çoban • Muhammet İşcen • Mert Uyanık**

## Açılış (önerilen)
`prototype/BASLAT.bat` dosyasına çift tıklayın → `http://localhost:8080/index.html` açılır.
Neden http? Panel + kurye telefonu **BroadcastChannel + localStorage** ile senkron çalışır; http üzerinden en sağlıklısı. Çift tıklama ile de açılır ama senkron için http önerilir.

## Dosyalar
| Yol | Açıklama |
|---|---|
| `prototype/index.html` | Seçici ekran |
| `prototype/admin.html` | Operasyon masası: mahalle filtreli kuyruk, yakınlık skorlu oto-atama, manuel ata, CARTO/OSM-DE/Esri katmanlı canlı harita |
| `prototype/kurye.html` | Kurye telefonu: isim seçici, popup + sayaç, aldım/teslim, dahili rota |
| `prototype/shared.js` | İki ekranın ortak senkron mağazası (sunucusuz) |
| `backend/src/server.js` | Gerçek projeye geçişte kullanılacak mock API |
| `db/schema.sql` | PostgreSQL + PostGIS şeması (Torbalı seed'li) |

## Senkron turu
1. Masayı + telefonu iki sekmede aç, telefonda adını seç.
2. Masada + Sipariş → Otomatik Ata. Telefonda popup çalar.
3. Kabul Et → Aldım → Teslim Et. Masanın haritası/günlüğü aynı saniye güncellenir.

## Harita notu ("Access Blocked")
Bazı ağlar `tile.openstreetmap.org`'u engeller. Bu yüzden varsayılan **CARTO** kullanılır, haritanın sağ üst katman düğmesinden **OSM-Almanya / Esri**'ye geçilebilir, CARTO hata verirse otomatik OSM-DE'ye düşer.
