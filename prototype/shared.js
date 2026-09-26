// KuryeX Torbali — ortak senkron magazasi
// admin.html + kurye.html ayni state'i paylasir.
// Mekanizma: localStorage (kalicilik) + BroadcastChannel (sekmeler arasi canli) + storage event (yedek).
// file:// ile de calisir ama en sagliklisi klasoru http ile acmak (BASLAT.bat).
(function () {
  var KEY = 'kuryex_torbali_v1';
  var BUS = 'kuryex_torbali_bus';
  var bc = null;
  try { bc = new BroadcastChannel(BUS); } catch (e) { bc = null; }

  function defaults() {
    return {
      seq: 200,
      delivered: 0,
      revenue: 0,
      couriers: [
        { id: 'K1', name: 'Ozan Şen', load: 0, perf: 92, online: true, status: 'boşta', lat: 38.1490, lng: 27.3590 },
        { id: 'K2', name: 'Hüsnü Can Çoban', load: 0, perf: 87, online: true, status: 'boşta', lat: 38.1525, lng: 27.3495 },
        { id: 'K3', name: 'Muhammet İşcen', load: 1, perf: 90, online: true, status: 'meşgul', lat: 38.1445, lng: 27.3625 },
        { id: 'K4', name: 'Mert Uyanık', load: 0, perf: 84, online: true, status: 'boşta', lat: 38.1500, lng: 27.3550 }
      ],
      orders: [],
      log: []
    };
  }

  function load() {
    try {
      var raw = localStorage.getItem(KEY);
      if (!raw) return defaults();
      var s = JSON.parse(raw);
      if (!s.couriers || !s.orders) return defaults();
      return s;
    } catch (e) { return defaults(); }
  }

  var state = load();
  var listeners = [];

  function persist(broadcast) {
    try { localStorage.setItem(KEY, JSON.stringify(state)); } catch (e) {}
    if (broadcast !== false && bc) { try { bc.postMessage({ t: 'state', s: state }); } catch (e) {} }
    listeners.forEach(function (fn) { try { fn(state); } catch (e) {} });
  }

  function pushLog(msg) {
    state.log.unshift({ at: new Date().toLocaleTimeString('tr-TR'), msg: msg });
    state.log = state.log.slice(0, 80);
  }

  if (bc) {
    bc.onmessage = function (ev) {
      if (ev.data && ev.data.t === 'state' && ev.data.s) {
        state = ev.data.s;
        listeners.forEach(function (fn) { try { fn(state); } catch (e) {} });
      }
    };
  }
  window.addEventListener('storage', function (e) {
    if (e.key === KEY && e.newValue) {
      try { state = JSON.parse(e.newValue); } catch (err) {}
      listeners.forEach(function (fn) { try { fn(state); } catch (e2) {} });
    }
  });

  // harici sekmeden konum pingleri state'i sisirmesin diye throttled
  var locTimer = null;
  function pingLocation(id, lat, lng) {
    var c = state.couriers.find(function (x) { return x.id === id; });
    if (!c) return;
    c.lat = lat; c.lng = lng;
    if (locTimer) return;
    locTimer = setTimeout(function () { locTimer = null; persist(true); }, 2500);
    listeners.forEach(function (fn) { try { fn(state, true); } catch (e) {} });
  }

  window.KX = {
    get state() { return state; },
    subscribe: function (fn) { listeners.push(fn); fn(state); return function () { var i = listeners.indexOf(fn); if (i >= 0) listeners.splice(i, 1); }; },
    commit: function (mut, logMsg) {
      try { mut(state); } catch (e) {}
      if (logMsg) pushLog(logMsg);
      persist(true);
    },
    pingLocation: pingLocation,
    reset: function () { state = defaults(); persist(true); },
    me: function () { try { return localStorage.getItem('kuryex_me') || 'K1'; } catch (e) { return 'K1'; } },
    setMe: function (id) { try { localStorage.setItem('kuryex_me', id); } catch (e) {} }
  };
})();
