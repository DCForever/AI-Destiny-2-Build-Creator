const state = {
  manifest: null,
  observations: null,
  /** @type {null | { byScreen: Record<string, { primary: string, page: string|null, title: string, nodes: string[] }> }} */
  uiRulesLinks: null,
  mode: "report",
  selected: null,
};

async function loadJson(url) {
  try {
    const r = await fetch(url + "?t=" + Date.now());
    if (!r.ok) return null;
    return await r.json();
  } catch {
    return null;
  }
}

/**
 * Base URL for the UI rules companion + diagram.
 * - Served under companion (/atlas/... on :4174) → same origin
 * - Standalone atlas:view (:4173) → default companion port
 * Override: window.UI_RULES_BASE or ?uiRulesBase=
 */
function uiRulesBase() {
  const params = new URLSearchParams(location.search);
  if (params.get("uiRulesBase")) return params.get("uiRulesBase").replace(/\/?$/, "/");
  if (typeof window !== "undefined" && window.UI_RULES_BASE) {
    return String(window.UI_RULES_BASE).replace(/\/?$/, "/");
  }
  // Companion hosts Atlas at /atlas/
  if (/\/atlas(\/|$)/.test(location.pathname) || location.port === "4174") {
    return location.origin + "/";
  }
  return "http://127.0.0.1:4174/";
}

function uiRulesNodeUrl(nodeId, pageId) {
  const u = new URL(uiRulesBase());
  if (nodeId) u.searchParams.set("node", nodeId);
  if (pageId) u.searchParams.set("page", pageId);
  return u.toString();
}

function uiRulesDrawioUrl() {
  return new URL("ui-map.drawio", uiRulesBase()).toString();
}

function linkForScreen(screenId) {
  return state.uiRulesLinks?.byScreen?.[screenId] || null;
}

/** HTML for links into the rules diagram / companion for an Atlas screen id. */
function diagramLinksHtml(screenId, opts) {
  const compact = Boolean(opts?.compact);
  const link = linkForScreen(screenId);
  if (!link) {
    if (compact) return "";
    return (
      '<p class="diagram-links muted">No UI-rules node for this screen. ' +
      'Run <code>npm run ui-rules:generate</code> after inventory links exist.</p>'
    );
  }
  const nodeUrl = uiRulesNodeUrl(link.primary, link.page);
  const drawio = uiRulesDrawioUrl();
  if (compact) {
    return (
      '<a class="btn diagram" href="' +
      esc(nodeUrl) +
      '" target="_blank" rel="noopener" title="Open in UI rules map">Rules</a>'
    );
  }
  const more =
    link.nodes.length > 1
      ? '<span class="muted"> · ' +
        (link.nodes.length - 1) +
        " related node" +
        (link.nodes.length > 2 ? "s" : "") +
        "</span>"
      : "";
  return (
    '<div class="diagram-links">' +
    '<div class="diagram-label">Rules diagram</div>' +
    '<div class="btn-row">' +
    '<a class="btn accent" href="' +
    esc(nodeUrl) +
    '" target="_blank" rel="noopener">Open node · ' +
    esc(link.primary) +
    "</a>" +
    '<a class="btn" href="' +
    esc(drawio) +
    '" target="_blank" rel="noopener" download="ui-map.drawio">Download .drawio</a>' +
    "</div>" +
    '<p class="muted diagram-meta">' +
    esc(link.title) +
    (link.page ? " · page " + esc(link.page) : "") +
    more +
    "</p></div>"
  );
}

function obsList() {
  return (state.observations?.observations || []).filter((o) => o.file);
}
function obsFor(screenId) {
  return obsList().filter((o) => o.screenId === screenId);
}
function bestObs(screenId) {
  const list = obsFor(screenId);
  return list.find((o) => o.variant === "signed-in") || list[0] || null;
}
function screenById(id) {
  return state.manifest?.screens?.find((s) => s.id === id) || null;
}
function openLightbox(src, caption) {
  document.getElementById("lbImg").src = src;
  document.getElementById("lbCap").textContent = caption || "";
  document.getElementById("lightbox").hidden = false;
}
function closeLightbox() {
  document.getElementById("lightbox").hidden = true;
  document.getElementById("lbImg").src = "";
}
function esc(t) {
  return String(t ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}
function pill(n, label) {
  return '<div class="pill"><div class="n">' + n + '</div><div class="l">' + esc(label) + "</div></div>";
}
function renderTopStats() {
  const m = state.manifest;
  const shots = obsList().length;
  const el = state.observations?.elementTotals || {};
  const elTotal = Object.values(el).reduce((a, b) => a + (b || 0), 0);
  const linked = state.uiRulesLinks
    ? Object.keys(state.uiRulesLinks.byScreen || {}).length
    : "—";
  document.getElementById("topStats").innerHTML =
    pill(m.screens.length, "Screens") +
    pill(m.paths.length, "Paths") +
    pill(m.transitions.length, "Transitions") +
    pill(shots, "Shots") +
    pill(linked, "Rules links") +
    pill(elTotal || "—", "UI elements");
  document.getElementById("appTitle").textContent = m.app || "UI Atlas";
  document.getElementById("lede").textContent = m.description || "";
  const nav = document.getElementById("topNav");
  if (nav) {
    nav.innerHTML =
      '<a class="btn accent" href="' +
      esc(uiRulesBase()) +
      '" target="_blank" rel="noopener">UI rules map</a>' +
      '<a class="btn" href="' +
      esc(uiRulesDrawioUrl()) +
      '" target="_blank" rel="noopener" download="ui-map.drawio">.drawio</a>';
  }
}
function syncTabs() {
  document.querySelectorAll("#primaryTabs button").forEach((b) => {
    b.classList.toggle("on", b.dataset.mode === state.mode);
  });
}
function bindFull() {
  document.querySelectorAll("[data-full]").forEach((el) => {
    el.addEventListener("click", (e) => {
      e.stopPropagation();
      openLightbox(el.getAttribute("data-full"), el.getAttribute("data-cap") || "");
    });
  });
}
function renderReportHome() {
  const m = state.manifest;
  const density = [...m.screens]
    .map((s) => ({ s, total: bestObs(s.id)?.elements?.total || 0 }))
    .sort((a, b) => b.total - a.total)
    .slice(0, 12);
  const et = state.observations?.elementTotals || {};
  let html = "";
  html += '<div class="kicker">Research uses</div><h2 class="section">What this map helps inspect</h2>';
  html += '<p class="sub">' + (m.uses || []).map((u) => "· " + esc(u)).join("<br/>") + "</p>";
  html += '<div class="kicker">Key journeys</div><h2 class="section">Compose &amp; library detail flows</h2>';
  html += '<p class="sub">Build creation, armor/weapon set create &amp; edit, library detail—not only top-level routes.</p><div class="journey-grid">';
  m.paths.forEach((p, i) => {
    const chain = p.steps.slice(0, 4).map((st) => '<span class="chip">' + esc(st.label) + "</span>").join("");
    const more = p.steps.length > 4 ? '<span class="chip accent">+' + (p.steps.length - 4) + "</span>" : "";
    html +=
      '<button type="button" class="journey" data-path="' + esc(p.id) + '"><div class="idx">' +
      String(i + 1).padStart(2, "0") + " · " + esc(p.priority || "") + " · " + esc(p.type || "path") + " · " +
      p.steps.length + ' screens</div><div class="title">' + esc(p.title) + '</div><div class="meta">' +
      esc(p.description || "") + '</div><div class="chain">' + chain + more + "</div></button>";
  });
  html += "</div>";
  html += '<div class="kicker">Screen inventory</div><h2 class="section">High-density screens</h2><p class="sub">By captured interactive element counts.</p><div class="density">';
  density.forEach((d, i) => {
    html += '<div class="row"><span>' + (i + 1) + ". " + esc(d.s.title) + "</span><b>" + (d.total || "—") + " els</b></div>";
  });
  html += '</div><div class="kicker">UI inventory</div><h2 class="section">Elements across captures</h2><div class="elem-bars">';
  const entries = Object.entries(et);
  if (!entries.length) html += '<p class="empty">Re-run <code>npm run atlas:capture</code> to populate element totals and screenshots.</p>';
  else entries.forEach(([k, v]) => { html += '<div class="bar"><div class="n">' + v + '</div><div class="l">' + esc(k) + "</div></div>"; });
  html += "</div>";
  document.getElementById("body").innerHTML = html;
  document.querySelectorAll("[data-path]").forEach((btn) => {
    btn.addEventListener("click", () => {
      state.selected = { type: "path", id: btn.getAttribute("data-path") };
      render();
    });
  });
}
function renderPathDetail(pathId) {
  const m = state.manifest;
  const p = m.paths.find((x) => x.id === pathId);
  if (!p) return renderReportHome();
  let html =
    '<button type="button" class="btn back" id="backReport">← All journeys</button><div class="kicker">Flow · ' +
    esc(p.priority || "") + " · " + esc(p.type || "") + '</div><h2 class="section">' + esc(p.title) +
    '</h2><p class="sub">' + esc(p.description || "") + '</p><ol class="flow-steps">';
  p.steps.forEach((st, i) => {
    const sc = screenById(st.screenId);
    const o = bestObs(st.screenId);
    html +=
      '<li><div class="head"><div><div class="stepn">Step ' +
      String(i + 1).padStart(2, "0") +
      '</div><div class="stept">' +
      esc(st.label) +
      '</div><div class="muted">' +
      esc(sc?.title || st.screenId) +
      (o?.elements ? " · " + o.elements.total + " elements" : "") +
      '</div></div><div class="btn-row">' +
      (o
        ? '<button type="button" class="btn accent" data-full="' +
          esc(o.file) +
          '" data-cap="' +
          esc(st.label) +
          '">Full size</button>'
        : "") +
      diagramLinksHtml(st.screenId, { compact: true }) +
      "</div></div>" +
      (o
        ? '<img src="' +
          esc(o.file) +
          '" alt="" data-full="' +
          esc(o.file) +
          '" data-cap="' +
          esc(st.label) +
          '" />'
        : '<div class="empty" style="padding:16px">No screenshot for <code>' +
          esc(st.screenId) +
          "</code></div>") +
      diagramLinksHtml(st.screenId) +
      "</li>";
  });
  html += "</ol>";
  document.getElementById("body").innerHTML = html;
  document.getElementById("backReport")?.addEventListener("click", () => { state.selected = null; render(); });
  bindFull();
}
function renderScreens() {
  if (state.selected?.type === "screen") return renderScreenDetail(state.selected.id);
  const m = state.manifest;
  let html = '<div class="kicker">Screens</div><h2 class="section">Screen inventory</h2><p class="sub">Open a card for inventory, transitions, and full-size shot.</p><div class="screen-grid">';
  for (const s of m.screens) {
    const o = bestObs(s.id);
    const hasRules = Boolean(linkForScreen(s.id));
    html +=
      '<div class="card" data-screen="' + esc(s.id) + '"><div class="thumb">' +
      (o ? '<img src="' + esc(o.file) + '" alt="" loading="lazy" />' : '<span class="muted">No shot</span>') +
      '</div><div class="cap"><div class="t">' + esc(s.title) +
      (hasRules ? ' <span class="rules-badge" title="Linked to rules diagram">rules</span>' : "") +
      '</div><div class="s">' + esc(s.path) + " · " + esc(s.auth) +
      '</div><div class="e">' + (o?.elements ? o.elements.total + " elements" : "—") + "</div></div></div>";
  }
  html += "</div>";
  document.getElementById("body").innerHTML = html;
  document.querySelectorAll("[data-screen]").forEach((card) => {
    card.addEventListener("click", () => {
      state.selected = { type: "screen", id: card.getAttribute("data-screen") };
      render();
    });
  });
}
function renderScreenDetail(id) {
  const s = screenById(id);
  if (!s) { state.selected = null; return renderScreens(); }
  const shots = obsFor(id);
  const o = bestObs(id);
  const m = state.manifest;
  const incoming = m.transitions.filter((t) => t.to === id);
  const outgoing = m.transitions.filter((t) => t.from === id);
  const br = o?.elements?.byRole || {};
  let html =
    '<button type="button" class="btn back" id="backScreens">← All screens</button><div class="detail-layout"><div><div class="kicker">Screen</div><h2 class="section">' +
    esc(s.title) + '</h2><p class="sub">' + esc(s.path) + " · auth: " + esc(s.auth) +
    (s.notes ? " · " + esc(s.notes) : "") + '</p><div class="shot-stage">' +
    (o ? '<img src="' + esc(o.file) + '" alt="" data-full="' + esc(o.file) + '" data-cap="' + esc(s.title) + '" />' : '<span class="muted">Not captured</span>') +
    '</div><div class="btn-row">' +
    (o ? '<button type="button" class="btn accent" data-full="' + esc(o.file) + '" data-cap="' + esc(s.title) + '">Open full size</button>' : "");
  html += shots.map((sh) =>
    '<button type="button" class="btn" data-full="' + esc(sh.file) + '" data-cap="' + esc(s.title + " (" + (sh.variant || "default") + ")") + '">' +
    esc(sh.variant || "shot") + "</button>"
  ).join("");
  html +=
    '</div>' +
    diagramLinksHtml(id) +
    '</div><div class="sidebox"><h3>Rules diagram</h3>' +
    diagramLinksHtml(id) +
    '<h3 style="margin-top:16px">Element inventory</h3><div class="elem-bars">' +
    (Object.entries(br).map(([k, v]) => '<div class="bar"><div class="n">' + v + '</div><div class="l">' + esc(k) + "</div></div>").join("") ||
      '<p class="muted">No inventory — re-capture.</p>') +
    '</div><h3 style="margin-top:16px">Sample labels</h3><div class="labels">' +
    ((o?.elements?.sampleLabels || []).slice(0, 24).map((l) => '<span class="chip">' + esc(l) + "</span>").join("") || '<span class="muted">—</span>') +
    '</div><h3 style="margin-top:16px">Incoming</h3><p class="muted">' +
    (incoming.map((t) => esc(t.action) + " ← " + esc(t.from)).join("<br/>") || "—") +
    '</p><h3 style="margin-top:12px">Outgoing</h3><p class="muted">' +
    (outgoing.map((t) => esc(t.action) + " → " + esc(t.to)).join("<br/>") || "—") +
    '</p><h3 style="margin-top:12px">Used in paths</h3><p class="muted">' +
    (m.paths.filter((p) => p.steps.some((st) => st.screenId === id)).map((p) => esc(p.title)).join("<br/>") || "—") +
    "</p></div></div>";
  document.getElementById("body").innerHTML = html;
  document.getElementById("backScreens")?.addEventListener("click", () => { state.selected = null; render(); });
  bindFull();
}
function renderMap() {
  const m = state.manifest;
  let html = '<div class="kicker">Map</div><h2 class="section">Navigation transitions</h2><p class="sub">Edges between compose detail and library surfaces.</p><div class="map-panel"><ul class="map-list">';
  html += m.transitions.map((t) => {
    const a = screenById(t.from);
    const b = screenById(t.to);
    return (
      '<li><button type="button" class="linkish" data-screen="' + esc(t.from) + '">' + esc(a?.title || t.from) +
      '</button><div class="act">' + esc(t.action) +
      '</div><button type="button" class="linkish" data-screen="' + esc(t.to) + '">' + esc(b?.title || t.to) + "</button></li>"
    );
  }).join("");
  html += "</ul></div>";
  document.getElementById("body").innerHTML = html;
  document.querySelectorAll("[data-screen]").forEach((btn) => {
    btn.addEventListener("click", () => {
      state.mode = "screens";
      state.selected = { type: "screen", id: btn.getAttribute("data-screen") };
      syncTabs();
      render();
    });
  });
}
function render() {
  if (!state.manifest) {
    document.getElementById("body").innerHTML = '<p class="empty">Missing manifest.json</p>';
    return;
  }
  renderTopStats();
  if (state.mode === "report") {
    if (state.selected?.type === "path") renderPathDetail(state.selected.id);
    else renderReportHome();
  } else if (state.mode === "screens") renderScreens();
  else renderMap();
}
document.getElementById("primaryTabs").addEventListener("click", (e) => {
  const b = e.target.closest("button[data-mode]");
  if (!b) return;
  state.mode = b.dataset.mode;
  if (state.mode === "map") state.selected = null;
  if (state.mode === "screens" && state.selected?.type === "path") state.selected = null;
  if (state.mode === "report" && state.selected?.type === "screen") state.selected = null;
  syncTabs();
  render();
});
document.getElementById("lbClose").addEventListener("click", closeLightbox);
document.getElementById("lightbox").addEventListener("click", (e) => {
  if (e.target.id === "lightbox") closeLightbox();
});
document.addEventListener("keydown", (e) => {
  if (e.key === "Escape") closeLightbox();
});
(async () => {
  state.manifest = await loadJson("./manifest.json");
  state.observations = await loadJson("./observations.json");
  state.uiRulesLinks = await loadJson("./ui-rules-links.json");
  syncTabs();
  render();
})();
