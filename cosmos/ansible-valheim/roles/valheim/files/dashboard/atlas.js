/* Shared atlas drawing code for the map page and the newspaper teaser. */
(function () {
  "use strict";

  // Paint colours for each biome, plus ink for coastlines, rivers and roads.
  var COLORS = {
    ink: ["Ink", "#2b2118"],
    meadows: ["Meadows", "#8db255"],
    forest: ["Black Forest", "#3d6638"],
    swamp: ["Swamp", "#6e5c3b"],
    mountain: ["Mountain", "#f3f5f6"],
    plains: ["Plains", "#d8b544"],
    mistlands: ["Mistlands", "#8b7aa9"],
    ashlands: ["Ashlands", "#b4442e"],
    ocean: ["Ocean", "#6c9dc0"],
    danger: ["Danger", "#b5141c"]
  };
  var PINS = {
    base: ["Base", "\u{1F3E0}"],
    portal: ["Portal", "\u{1F300}"],
    boss: ["Boss altar", "\u{1F5FF}"],
    dungeon: ["Dungeon", "\u{1F3DA}️"],
    trader: ["Trader", "\u{1F6D2}"],
    ore: ["Ore", "⛏️"],
    ship: ["Ship", "⛵"],
    death: ["Tombstone", "\u{1F480}"],
    other: ["Something", "⭐"]
  };
  // Kinds of line: each one has its own look, so a path never reads as a coastline.
  var STYLES = {
    line: ["Line", "Coasts, cliffs, anything"],
    path: ["Path", "Roads and trails you walked"],
    river: ["River", "Rivers and streams"],
    border: ["Border", "Where one biome meets another"],
    area: ["Biome", "Draw round a region to fill it"]
  };
  var PATH = "#7a5a32", RIVER = "#4f86b0";
  var PAPER = "#e9dcb8", GRID = "rgba(80, 58, 30, .13)", LABEL = "#2b2118", HALO = "rgba(242, 233, 207, .92)";
  var PIN_SIZE = 26;

  function Store() { this.rev = 0; this.items = {}; }
  // Apply a batch from the server; deleted entries remove their item.
  Store.prototype.merge = function (payload) {
    var self = this, changed = false;
    (payload.items || []).forEach(function (item) {
      if (item.deleted) { if (self.items[item.id]) { delete self.items[item.id]; changed = true; } }
      else { self.items[item.id] = item; changed = true; }
    });
    if (typeof payload.rev === "number") this.rev = Math.max(this.rev, payload.rev);
    return changed;
  };
  Store.prototype.list = function () {
    var items = this.items;
    return Object.keys(items).map(function (id) { return items[id]; }).sort(function (a, b) { return (a.rev || Infinity) - (b.rev || Infinity); });
  };

  // Every map is drawn around the sacrificial stones, so they are always in view.
  function bounds(items) {
    var box = { x0: 0, y0: 0, x1: 0, y1: 0 };
    function add(x, y) {
      { box.x0 = Math.min(box.x0, x); box.y0 = Math.min(box.y0, y); box.x1 = Math.max(box.x1, x); box.y1 = Math.max(box.y1, y); }
    }
    items.forEach(function (item) {
      if (item.kind === "stroke") item.points.forEach(function (p) { add(p[0], p[1]); });
      else add(item.x, item.y);
    });
    return box;
  }
  // A view whose scale fits every item inside a w by h canvas.
  function fit(items, w, h, pad) {
    var box = bounds(items);
    var bw = Math.max(box.x1 - box.x0, 80), bh = Math.max(box.y1 - box.y0, 80);
    var scale = Math.min((w - 2 * pad) / bw, (h - 2 * pad) / bh);
    return { x: (box.x0 + box.x1) / 2, y: (box.y0 + box.y1) / 2, scale: Math.max(.01, Math.min(scale, 4)) };
  }
  function toScreen(view, w, h, x, y) { return [(x - view.x) * view.scale + w / 2, (y - view.y) * view.scale + h / 2]; }
  function toWorld(view, w, h, sx, sy) { return [(sx - w / 2) / view.scale + view.x, (sy - h / 2) / view.scale + view.y]; }

  function background(ctx, view, w, h) {
    ctx.fillStyle = PAPER;
    ctx.fillRect(0, 0, w, h);
    // Grid squares stay between 60 and 300 pixels at any zoom.
    var step = Math.pow(5, Math.ceil(Math.log(60 / view.scale) / Math.log(5)));
    var start = toWorld(view, w, h, 0, 0), end = toWorld(view, w, h, w, h);
    ctx.strokeStyle = GRID;
    ctx.lineWidth = 1;
    ctx.beginPath();
    for (var x = Math.floor(start[0] / step) * step; x <= end[0]; x += step) { var sx = Math.round(toScreen(view, w, h, x, 0)[0]) + .5; ctx.moveTo(sx, 0); ctx.lineTo(sx, h); }
    for (var y = Math.floor(start[1] / step) * step; y <= end[1]; y += step) { var sy = Math.round(toScreen(view, w, h, 0, y)[1]) + .5; ctx.moveTo(0, sy); ctx.lineTo(w, sy); }
    ctx.stroke();
    var glow = ctx.createRadialGradient(w / 2, h / 2, Math.min(w, h) * .35, w / 2, h / 2, Math.max(w, h) * .75);
    glow.addColorStop(0, "rgba(120, 80, 30, 0)");
    glow.addColorStop(1, "rgba(120, 80, 30, .2)");
    ctx.fillStyle = glow;
    ctx.fillRect(0, 0, w, h);
  }
  // Trace a smoothed line through screen points; closed traces end back at the start.
  function trace(ctx, pts, closed) {
    ctx.beginPath();
    ctx.moveTo(pts[0][0], pts[0][1]);
    if (pts.length < 3) pts.slice(1).concat(pts.length === 1 ? [[pts[0][0] + .01, pts[0][1]]] : []).forEach(function (p) { ctx.lineTo(p[0], p[1]); });
    for (var i = 1; i < pts.length - 1; i++) {
      var mx = (pts[i][0] + pts[i + 1][0]) / 2, my = (pts[i][1] + pts[i + 1][1]) / 2;
      ctx.quadraticCurveTo(pts[i][0], pts[i][1], mx, my);
    }
    if (pts.length >= 3) ctx.lineTo(pts[pts.length - 1][0], pts[pts.length - 1][1]);
    if (closed) ctx.closePath();
  }
  function style(item) { return item.kind === "stroke" ? item.style || "line" : item.kind; }
  function stroke(ctx, view, w, h, item, opts) {
    var pts = item.points.map(function (p) { return toScreen(view, w, h, p[0], p[1]); });
    var kind = style(item), paint = (COLORS[item.color] || COLORS.ink)[1], small = opts && opts.noLabels;
    ctx.lineCap = "round";
    ctx.lineJoin = "round";
    if (kind === "area") {
      trace(ctx, pts, true);
      ctx.globalAlpha = .5;
      ctx.fillStyle = paint;
      ctx.fill();
      ctx.globalAlpha = .85;
      ctx.strokeStyle = item.color === "mountain" ? "#8f8a80" : paint;
      ctx.lineWidth = small ? 1.5 : 2.5;
      ctx.stroke();
      ctx.globalAlpha = 1;
      return;
    }
    if (kind === "line") {
      ctx.strokeStyle = paint;
      ctx.lineWidth = Math.max(1, item.width * view.scale);
      ctx.globalAlpha = item.width * view.scale > 18 ? .78 : 1;
    } else {
      // Paths, rivers and borders keep the same weight at every zoom, like the symbols on a printed map.
      var thin = small ? .6 : 1;
      ctx.strokeStyle = kind === "path" ? PATH : kind === "river" ? RIVER : LABEL;
      ctx.lineWidth = (kind === "river" ? 4 : kind === "path" ? 3 : 2.5) * thin;
      ctx.globalAlpha = kind === "border" ? .7 : 1;
      if (kind === "path") ctx.setLineDash([9 * thin, 6 * thin]);
      if (kind === "border") { ctx.setLineDash([.1, 7 * thin]); ctx.lineWidth = 3.5 * thin; }
    }
    trace(ctx, pts, false);
    ctx.stroke();
    ctx.setLineDash([]);
    ctx.globalAlpha = 1;
  }
  function centre(points) {
    var x = 0, y = 0;
    points.forEach(function (p) { x += p[0]; y += p[1]; });
    return [x / points.length, y / points.length];
  }
  // A biome area names itself in small capitals when it is big enough on screen.
  function areaLabel(ctx, view, w, h, item) {
    var box = bounds([item]), size = Math.min((box.x1 - box.x0), (box.y1 - box.y0)) * view.scale;
    if (size < 70 || !COLORS[item.color] || item.color === "ink" || item.color === "danger") return;
    var c = centre(item.points), p = toScreen(view, w, h, c[0], c[1]);
    ctx.save();
    ctx.globalAlpha = .75;
    label(ctx, COLORS[item.color][0].toUpperCase(), p[0], p[1], Math.max(11, Math.min(22, size / 9)), true);
    ctx.restore();
  }
  function label(ctx, text, x, y, size, italic) {
    ctx.font = (italic ? "italic 600 " : "700 ") + size + 'px Gelasio, "Noto Serif Malayalam", Georgia, serif';
    ctx.textAlign = "center";
    ctx.textBaseline = "middle";
    ctx.lineJoin = "round";
    ctx.lineWidth = Math.max(3, size / 4);
    ctx.strokeStyle = HALO;
    ctx.strokeText(text, x, y);
    ctx.fillStyle = LABEL;
    ctx.fillText(text, x, y);
  }
  // The spawn point: a ring of standing stones at the origin that nobody can move or erase.
  function spawn(ctx, view, w, h, small) {
    var p = toScreen(view, w, h, 0, 0), r = small ? 8 : 11;
    if (p[0] < -100 || p[1] < -60 || p[0] > w + 100 || p[1] > h + 60) return;
    ctx.fillStyle = "rgba(246, 239, 217, .9)";
    ctx.strokeStyle = LABEL;
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    ctx.arc(p[0], p[1], r + 7, 0, Math.PI * 2);
    ctx.fill();
    ctx.setLineDash([3, 3]);
    ctx.stroke();
    ctx.setLineDash([]);
    ctx.fillStyle = "#6b6458";
    for (var i = 0; i < 6; i++) {
      var a = i / 6 * Math.PI * 2 - Math.PI / 2, sx = p[0] + Math.cos(a) * r, sy = p[1] + Math.sin(a) * r;
      ctx.beginPath();
      ctx.ellipse(sx, sy, 2.6, 4.2, 0, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
    }
    ctx.fillStyle = "#b5141c";
    ctx.beginPath();
    ctx.arc(p[0], p[1], 2.5, 0, Math.PI * 2);
    ctx.fill();
    if (!small) label(ctx, "Spawn", p[0], p[1] + r + 18, 13, false);
  }
  function textSize(item, view) { return item.size * view.scale; }
  function draw(ctx, items, view, w, h, opts) {
    opts = opts || {};
    background(ctx, view, w, h);
    // Biome areas lie under wide brushes, which lie under lines, names and pins.
    function layer(i) {
      if (i.kind === "pin") return 5;
      if (i.kind === "text") return 4;
      var kind = style(i);
      return kind === "area" ? 0 : kind === "line" && i.width * view.scale > 18 ? 1 : kind === "border" ? 2 : 3;
    }
    var sorted = items.slice().sort(function (a, b) { return layer(a) - layer(b); }), named = false;
    sorted.forEach(function (item) {
      // Biome names go on once every area is painted, under the lines, names and pins.
      if (!named && layer(item) > 0) {
        named = true;
        if (!opts.noLabels) sorted.forEach(function (area) { if (style(area) === "area") areaLabel(ctx, view, w, h, area); });
      }
      if (item.kind === "stroke") stroke(ctx, view, w, h, item, opts);
      else {
        var p = toScreen(view, w, h, item.x, item.y);
        if (p[0] < -200 || p[1] < -60 || p[0] > w + 200 || p[1] > h + 60) return;
        if (item.kind === "text") {
          var size = Math.min(90, textSize(item, view));
          if (size >= 7) label(ctx, item.label, p[0], p[1], size, true);
        } else {
          var pin = PINS[item.icon] || PINS.other, r = (opts.pinSize || PIN_SIZE) / 2;
          ctx.fillStyle = "#f6efd9";
          ctx.strokeStyle = item.icon === "death" ? "#b5141c" : LABEL;
          ctx.lineWidth = 2;
          ctx.beginPath();
          ctx.arc(p[0], p[1], r, 0, Math.PI * 2);
          ctx.fill();
          ctx.stroke();
          ctx.font = Math.round(r * 1.15) + 'px "Noto Color Emoji", "Apple Color Emoji", "Segoe UI Emoji", sans-serif';
          ctx.textAlign = "center";
          ctx.textBaseline = "middle";
          ctx.fillStyle = LABEL;
          ctx.fillText(pin[1], p[0], p[1] + 1);
          if (!opts.noLabels && item.label) label(ctx, item.label, p[0], p[1] + r + 10, 13, false);
        }
      }
    });
    if (!named && !opts.noLabels) sorted.forEach(function (area) { if (style(area) === "area") areaLabel(ctx, view, w, h, area); });
    spawn(ctx, view, w, h, opts.noLabels);
  }
  function inside(x, y, points) {
    var yes = false;
    for (var i = 0, j = points.length - 1; i < points.length; j = i++) {
      var a = points[i], b = points[j];
      if ((a[1] > y) !== (b[1] > y) && x < (b[0] - a[0]) * (y - a[1]) / (b[1] - a[1]) + a[0]) yes = !yes;
    }
    return yes;
  }
  function distToSegment(px, py, a, b) {
    var dx = b[0] - a[0], dy = b[1] - a[1], len = dx * dx + dy * dy;
    var t = len ? Math.max(0, Math.min(1, ((px - a[0]) * dx + (py - a[1]) * dy) / len)) : 0;
    return Math.hypot(px - (a[0] + t * dx), py - (a[1] + t * dy));
  }
  // The top item under a screen point, or null. Pins and names win over lines, and lines over biome areas;
  // an area counts only along its edge unless opts.inside is set, so a sweep of the eraser cannot wipe a whole biome.
  function hit(items, view, w, h, sx, sy, slop, opts) {
    for (var i = items.length - 1; i >= 0; i--) {
      var item = items[i];
      if (item.kind === "pin") {
        var p = toScreen(view, w, h, item.x, item.y);
        if (Math.hypot(sx - p[0], sy - p[1]) <= PIN_SIZE / 2 + slop) return item;
      } else if (item.kind === "text") {
        var q = toScreen(view, w, h, item.x, item.y), size = Math.min(90, textSize(item, view));
        if (Math.abs(sy - q[1]) <= size / 2 + slop && Math.abs(sx - q[0]) <= item.label.length * size * .3 + slop) return item;
      }
    }
    var world = toWorld(view, w, h, sx, sy);
    for (var j = items.length - 1; j >= 0; j--) {
      var s = items[j];
      if (s.kind !== "stroke") continue;
      var reach = (style(s) === "line" ? s.width / 2 : 3 / view.scale) + slop / view.scale;
      for (var k = 0; k < s.points.length; k++) {
        if (distToSegment(world[0], world[1], s.points[k], s.points[Math.min(k + 1, s.points.length - 1)]) <= reach) return s;
      }
    }
    if (opts && opts.inside) {
      for (var m = items.length - 1; m >= 0; m--) {
        if (style(items[m]) === "area" && inside(world[0], world[1], items[m].points)) return items[m];
      }
    }
    return null;
  }
  // Drop points that don't change the line's shape by more than epsilon.
  function simplify(points, epsilon) {
    if (points.length < 3) return points;
    var keep = new Array(points.length).fill(false), stack = [[0, points.length - 1]];
    keep[0] = keep[points.length - 1] = true;
    while (stack.length) {
      var span = stack.pop(), far = 0, index = -1;
      for (var i = span[0] + 1; i < span[1]; i++) {
        var d = distToSegment(points[i][0], points[i][1], points[span[0]], points[span[1]]);
        if (d > far) { far = d; index = i; }
      }
      if (far > epsilon) { keep[index] = true; stack.push([span[0], index], [index, span[1]]); }
    }
    return points.filter(function (_, i) { return keep[i]; });
  }

  window.Atlas = { COLORS: COLORS, PINS: PINS, STYLES: STYLES, Store: Store, bounds: bounds, fit: fit, draw: draw, hit: hit, simplify: simplify, toScreen: toScreen, toWorld: toWorld };
})();
