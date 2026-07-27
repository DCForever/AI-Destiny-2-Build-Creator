/* global fetch */
(() => {
  const $ = (id) => document.getElementById(id);

  /** @type {any} */
  let state = {
    mode: "flows",
    hub: null,
    flows: [],
    rulesById: new Map(),
    rules: [],
    atlasMeta: null,
    manifest: null,
    inventory: null,
    atlasByNode: new Map(),
    activeFlowId: null,
    activePhaseId: null,
    activeNodeId: null,
    activeRuleId: null,
    screenArea: null,
    platform: "nextjs",
  };

  function setStatus(msg, kind = "ok") {
    const el = $("status");
    el.hidden = !msg;
    el.textContent = msg || "";
    el.className = `status ${kind}`;
  }

  async function api(path, opts) {
    const res = await fetch(path, {
      headers: { "Content-Type": "application/json", ...(opts?.headers || {}) },
      ...opts,
    });
    const data = await res.json().catch(() => ({}));
    if (!res.ok) throw new Error(data.message || res.statusText || "Request failed");
    return data;
  }

  function esc(s) {
    return String(s ?? "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function syncModeTabs() {
    document.querySelectorAll("#modeTabs button").forEach((b) => {
      b.classList.toggle("on", b.dataset.mode === state.mode);
    });
  }

  function setMode(mode) {
    state.mode = mode;
    const u = new URL(location.href);
    u.searchParams.set("mode", mode);
    history.replaceState(null, "", u);
    syncModeTabs();
    render();
  }

  function openLightbox(src, cap) {
    $("lbImg").src = src;
    $("lbCap").textContent = cap || "";
    $("lightbox").hidden = false;
  }
  function closeLightbox() {
    $("lightbox").hidden = true;
    $("lbImg").src = "";
  }

  async function loadAll() {
    setStatus("Loading…");
    const [hub, flowPack, rulesPayload, atlas, manifest, inv] = await Promise.all([
      api("/api/hub"),
      api("/api/hub/flows"),
      api("/api/rules"),
      api("/api/atlas"),
      api("/api/atlas/manifest").catch(() => null),
      api("/api/inventory"),
    ]);
    state.hub = hub;
    state.flows = flowPack.flows || [];
    state.rules = rulesPayload.rules || [];
    state.rulesById = new Map(state.rules.map((r) => [r.id, r]));
    state.atlasMeta = atlas;
    state.manifest = manifest;
    state.inventory = inv;

    // Prefetch shots for surfaces with capture ids (batch by inventory nodes)
    state.atlasByNode = new Map();
    const ids = (hub.surfaces || [])
      .filter((s) => s.platforms?.nextjs?.captureId || s.kind === "screen")
      .map((s) => s.id)
      .slice(0, 120);
    await Promise.all(
      ids.map(async (id) => {
        try {
          state.atlasByNode.set(
            id,
            await api(`/api/atlas/node?id=${encodeURIComponent(id)}`),
          );
        } catch {
          /* ignore */
        }
      }),
    );

    applyDeepLinks();
    setStatus(
      `${hub.surfaceCount} surfaces · ${hub.flowCount} flows · ${state.rules.length} rules · ${atlas.shotCount || 0} shots`,
      atlas.captureHint ? "err" : "ok",
    );
    render();
  }

  function applyDeepLinks() {
    const params = new URLSearchParams(location.search);
    const mode = params.get("mode");
    if (mode && ["flows", "screens", "map", "rules", "export"].includes(mode)) {
      state.mode = mode;
    }
    if (params.get("platform")) state.platform = params.get("platform");
    if (params.get("flow")) state.activeFlowId = params.get("flow");
    if (params.get("phase")) state.activePhaseId = params.get("phase");
    if (params.get("node")) {
      state.activeNodeId = params.get("node");
      if (!mode) state.mode = "screens";
    }
    if (params.get("rule")) {
      state.activeRuleId = params.get("rule");
      if (!mode) state.mode = "rules";
    }
    if (!state.activeFlowId && state.flows[0]) {
      state.activeFlowId = state.flows[0].id;
    }
    syncModeTabs();
  }

  function render() {
    const app = $("app");
    if (state.mode === "flows") app.innerHTML = renderFlows();
    else if (state.mode === "screens") app.innerHTML = renderScreens();
    else if (state.mode === "map") app.innerHTML = renderMap();
    else if (state.mode === "rules") app.innerHTML = renderRules();
    else app.innerHTML = renderExport();
    bindApp();
  }

  // ─── Flows ─────────────────────────────────────────────
  function renderFlows() {
    const list = state.flows
      .map((f) => {
        const on = f.id === state.activeFlowId ? " on" : "";
        return `<button type="button" class="list-item${on}" data-flow="${esc(f.id)}">
          <span class="idx">${esc(f.priority || f.type || "")}</span>
          <span class="t">${esc(f.title || f.id)}</span>
          <span class="meta">${esc(f.id)}</span>
        </button>`;
      })
      .join("");
    const flow = state.flows.find((f) => f.id === state.activeFlowId);
    let detail = `<p class="empty">Select a flow</p>`;
    if (flow) {
      detail = `
        <div class="detail-head">
          <h2>${esc(flow.title || flow.id)}</h2>
          <p class="meta">${esc(flow.id)} · ${esc(flow.type || "")} · ${esc(flow.priority || "")}</p>
          <p class="lede-inline">${esc(flow.description || "")}</p>
          <div class="chips">${(flow.rules || []).map((r) => `<button type="button" class="chip" data-open-rule="${esc(r)}">${esc(r)}</button>`).join("")}</div>
        </div>
        <div class="phase-panel">${renderPhaseTree(flow.tree || [], 0)}</div>
        <div class="struct-box">
          <h3>Add phase stub</h3>
          <div class="form-row">
            <input id="phaseId" placeholder="phase-id" />
            <input id="phaseTitle" placeholder="Title" />
            <input id="phaseSurface" placeholder="surface.id (optional)" />
          </div>
          <button type="button" class="btn primary" id="btnAddPhase">Add phase to flow</button>
        </div>`;
    }
    return `<div class="split">
      <aside class="list-pane"><div class="pane-head"><h2>Flows</h2>
        <input type="search" id="flowFilter" placeholder="Filter flows…" /></div>
        <div id="flowList" class="list">${list}</div></aside>
      <main class="detail-pane">${detail}</main>
    </div>`;
  }

  function renderPhaseTree(nodes, depth) {
    if (!nodes?.length) return `<p class="empty">No phases</p>`;
    let html = `<ul class="phase-tree d${depth}">`;
    for (const n of nodes) {
      const on = n.id === state.activePhaseId ? " on" : "";
      html += `<li class="phase kind-${esc(n.kind || "step")}${on}">
        <div class="phase-head">
          <span class="pk">${esc(n.kind || "step")}</span>
          <strong>${esc(n.title || n.id)}</strong>
          ${n.include ? `<span class="meta">→ ${esc(n.include)}</span>` : ""}
          ${n.loop ? `<span class="meta">↻ ${esc(n.loop)}</span>` : ""}
          ${n.gate ? `<span class="meta">⛔ ${esc(n.gate)}</span>` : ""}
        </div>`;
      if (n.surfaceId) {
        html += `<div class="meta"><button type="button" class="linkish" data-open-node="${esc(n.surfaceId)}">${esc(n.surfaceId)}</button>
          ${n.screenId ? ` · ${esc(n.screenId)}` : ""}</div>`;
        const shots = state.atlasByNode.get(n.surfaceId);
        if (shots?.hasAnyShots) {
          const sh = shots.screens?.[0]?.shots?.[0];
          if (sh) {
            html += `<button type="button" class="thumb-btn" data-full="${esc(sh.url)}" data-cap="${esc(n.title)}">
              <img src="${esc(sh.url)}" alt="" loading="lazy" /></button>`;
          }
        }
      }
      if (n.rules?.length) {
        html += `<div class="chips">${n.rules.map((r) => `<button type="button" class="chip" data-open-rule="${esc(r)}">${esc(r)}</button>`).join("")}</div>`;
      }
      if (n.children?.length) html += renderPhaseTree(n.children, depth + 1);
      html += `</li>`;
    }
    html += `</ul>`;
    return html;
  }

  // ─── Screens ───────────────────────────────────────────
  function renderScreens() {
    const surfaces = state.hub?.surfaces || [];
    const areas = [...new Set(surfaces.map((s) => s.area || "other"))].sort();
    const area = state.screenArea || areas[0];
    const filtered = surfaces.filter((s) => (s.area || "other") === area);
    const tabs = areas
      .map(
        (a) =>
          `<button type="button" class="page-tab${a === area ? " on" : ""}" data-area="${esc(a)}">${esc(a)}</button>`,
      )
      .join("");
    const list = filtered
      .map((s) => {
        const on = s.id === state.activeNodeId ? " on" : "";
        const cam = state.atlasByNode.get(s.id)?.hasAnyShots ? "📷" : "";
        return `<button type="button" class="list-item${on}" data-node="${esc(s.id)}">
          <span class="idx">${esc(s.kind || "")}</span>
          <span class="t">${esc(s.title || s.id)} ${cam}</span>
          <span class="meta">${esc(s.id)}</span>
        </button>`;
      })
      .join("");

    const s = surfaces.find((x) => x.id === state.activeNodeId);
    let detail = `<p class="empty">Select a surface</p>`;
    if (s) {
      const atlas = state.atlasByNode.get(s.id);
      const shotHtml = atlas?.hasAnyShots
        ? `<div class="shots-grid">${(atlas.screens || [])
            .flatMap((sc) =>
              (sc.shots || []).map(
                (sh) =>
                  `<button type="button" class="shot-card" data-full="${esc(sh.url)}" data-cap="${esc(sc.title)} · ${esc(sh.variant)}">
                    <img src="${esc(sh.url)}" alt="" loading="lazy" />
                    <div class="cap"><strong>${esc(sc.id)}</strong>${esc(sh.variant)}</div>
                  </button>`,
              ),
            )
            .join("")}</div>`
        : `<p class="empty">No screenshot — captureId: ${esc(s.platforms?.nextjs?.captureId || "—")}</p>`;

      detail = `
        <div class="detail-head">
          <h2>${esc(s.title || s.id)}</h2>
          <p class="meta">${esc(s.kind)} · ${esc(s.id)} · ${esc(s.auth || "—")} · ${esc(s.platforms?.nextjs?.path || "—")}</p>
          ${s.notes ? `<p class="lede-inline">${esc(s.notes)}</p>` : ""}
        </div>
        <div class="shots">${shotHtml}</div>
        <div class="struct-box">
          <h3>Attached rules</h3>
          <div class="chips">${(s.rules || []).map((r) => `<button type="button" class="chip" data-open-rule="${esc(r)}">${esc(r)}</button>`).join("") || "<span class='meta'>None</span>"}</div>
          <label class="field-label">Edit rule IDs (one per line or comma-separated)</label>
          <textarea id="surfaceRules" rows="5">${esc((s.rules || []).join("\n"))}</textarea>
          <div class="form-row">
            <label class="check"><input type="checkbox" id="regenAttach" checked /> Regenerate on save</label>
            <button type="button" class="btn primary" id="btnAttachRules">Save attachments</button>
          </div>
        </div>`;
    }

    return `<div class="split">
      <aside class="list-pane">
        <div class="pane-head"><h2>Screens / surfaces</h2>
          <div class="page-tabs">${tabs}</div>
          <input type="search" id="screenFilter" placeholder="Filter…" /></div>
        <div id="screenList" class="list">${list}</div>
      </aside>
      <main class="detail-pane">${detail}</main>
    </div>`;
  }

  // ─── Map ───────────────────────────────────────────────
  function renderMap() {
    const edges = state.hub?.transitions || [];
    const rows = edges
      .map(
        (t) =>
          `<tr>
            <td><button type="button" class="linkish" data-open-node="${esc(t.from)}">${esc(t.from)}</button></td>
            <td class="act">${esc(t.action || "")}</td>
            <td><button type="button" class="linkish" data-open-node="${esc(t.to)}">${esc(t.to)}</button></td>
          </tr>`,
      )
      .join("");
    return `<div class="full-pane">
      <div class="pane-head"><h2>Navigation map</h2>
        <p class="meta">${edges.length} transitions from product-map</p></div>
      <table class="map-table"><thead><tr><th>From</th><th>Action</th><th>To</th></tr></thead>
      <tbody>${rows || '<tr><td colspan="3">No transitions</td></tr>'}</tbody></table>
    </div>`;
  }

  // ─── Rules ─────────────────────────────────────────────
  function renderRules() {
    const q = "";
    const list = state.rules
      .slice(0, 500)
      .map((r) => {
        const on = r.id === state.activeRuleId ? " on" : "";
        return `<button type="button" class="list-item${on}" data-rule="${esc(r.id)}">
          <span class="idx layer-${esc(r.layer)}">${esc(r.layer)}</span>
          <span class="t">${esc(r.id)}</span>
          <span class="meta">${esc((r.title || "").slice(0, 60))}</span>
        </button>`;
      })
      .join("");
    const rule = state.rulesById.get(state.activeRuleId);
    let editor = `<p class="empty">Select a rule to edit wording (writes domain markdown)</p>`;
    if (rule) {
      editor = `
        <label class="field-label">Rule ID</label>
        <input id="ruleId" type="text" readonly value="${esc(rule.id)}" />
        <label class="field-label">Title</label>
        <input id="ruleTitle" type="text" value="${esc(rule.title || "")}" />
        <label class="field-label">Body</label>
        <textarea id="ruleBody" rows="14">${esc(rule.body || "")}</textarea>
        <p class="meta">${esc(rule.sourcePath || "")}${rule.section ? " · " + esc(rule.section) : ""}</p>
        <div class="form-row">
          <label class="check"><input type="checkbox" id="regenOnSave" checked /> Regenerate diagram</label>
          <button type="button" class="btn primary" id="btnSaveRule">Save to markdown</button>
        </div>
        <pre id="editorLog" class="log" hidden></pre>`;
    }
    return `<div class="split">
      <aside class="list-pane">
        <div class="pane-head"><h2>Rules</h2>
          <input type="search" id="ruleFilter" placeholder="Filter DAC / DBR / BR / slice…" /></div>
        <div id="ruleList" class="list">${list}</div>
      </aside>
      <main class="detail-pane editor-pane-inner">${editor}</main>
    </div>`;
  }

  // ─── Export ────────────────────────────────────────────
  function renderExport() {
    return `<div class="full-pane export-pane">
      <h2>Export &amp; generate</h2>
      <p class="lede-inline">Structure SSoT: <code>docs/product-map/</code>. Generated artifacts should not be hand-edited.</p>
      <ul class="export-list">
        <li><a href="/ui-map.drawio" download>ui-map.drawio</a> — multi-page Draw.io</li>
        <li><a href="/inventory.yaml" download>inventory.yaml</a> — generated projection</li>
        <li><a href="/atlas/manifest.json" download>atlas manifest</a></li>
        <li><a href="/atlas/ui-rules-links.json" download>atlas ↔ node links</a></li>
      </ul>
      <div class="form-row">
        <button type="button" class="btn primary" id="btnSync2">Run product-map:sync</button>
        <button type="button" class="btn" id="btnGenerate2">Generate only</button>
      </div>
      <pre id="exportLog" class="log" hidden></pre>
      <h3>Deep links</h3>
      <pre class="log">?mode=flows&amp;flow=journey.p1.intent-compose-equip
?mode=screens&amp;node=build.finish
?mode=rules&amp;rule=DAC-P1-007
?platform=nextjs</pre>
      <h3>Structure edits</h3>
      <p class="meta">Screens mode: attach rule IDs. Flows mode: add phase stubs. Or use CLI scaffold.</p>
      <div class="struct-box">
        <h3>Quick add surface</h3>
        <div class="form-row">
          <input id="newSurfaceId" placeholder="area.name" />
          <input id="newSurfaceTitle" placeholder="Title" />
          <input id="newSurfacePath" placeholder="/path" />
        </div>
        <button type="button" class="btn" id="btnAddSurface">Add surface to hub</button>
      </div>
    </div>`;
  }

  function bindApp() {
    // mode-specific
    document.querySelectorAll("[data-flow]").forEach((b) =>
      b.addEventListener("click", () => {
        state.activeFlowId = b.getAttribute("data-flow");
        const u = new URL(location.href);
        u.searchParams.set("flow", state.activeFlowId);
        history.replaceState(null, "", u);
        render();
      }),
    );
    document.querySelectorAll("[data-node]").forEach((b) =>
      b.addEventListener("click", () => {
        state.activeNodeId = b.getAttribute("data-node");
        render();
      }),
    );
    document.querySelectorAll("[data-area]").forEach((b) =>
      b.addEventListener("click", () => {
        state.screenArea = b.getAttribute("data-area");
        render();
      }),
    );
    document.querySelectorAll("[data-rule]").forEach((b) =>
      b.addEventListener("click", () => {
        state.activeRuleId = b.getAttribute("data-rule");
        render();
      }),
    );
    document.querySelectorAll("[data-open-rule]").forEach((b) =>
      b.addEventListener("click", () => {
        state.activeRuleId = b.getAttribute("data-open-rule");
        setMode("rules");
      }),
    );
    document.querySelectorAll("[data-open-node]").forEach((b) =>
      b.addEventListener("click", () => {
        state.activeNodeId = b.getAttribute("data-open-node");
        setMode("screens");
      }),
    );
    document.querySelectorAll("[data-full]").forEach((b) =>
      b.addEventListener("click", () => {
        openLightbox(b.getAttribute("data-full"), b.getAttribute("data-cap"));
      }),
    );

    $("btnAddPhase")?.addEventListener("click", async () => {
      try {
        const result = await api("/api/hub/add-phase", {
          method: "POST",
          body: JSON.stringify({
            flowId: state.activeFlowId,
            phase: {
              id: $("phaseId")?.value,
              title: $("phaseTitle")?.value,
              surface: $("phaseSurface")?.value || null,
            },
            regenerate: true,
          }),
        });
        setStatus(`Added phase ${result.phase?.id} (not committed)`, "ok");
        await loadAll();
      } catch (e) {
        setStatus(String(e.message || e), "err");
      }
    });

    $("btnAttachRules")?.addEventListener("click", async () => {
      try {
        const raw = $("surfaceRules")?.value || "";
        const rules = raw
          .split(/[\n,]+/)
          .map((x) => x.trim())
          .filter(Boolean);
        const result = await api("/api/hub/attach-rules", {
          method: "PUT",
          body: JSON.stringify({
            surfaceId: state.activeNodeId,
            rules,
            regenerate: $("regenAttach")?.checked,
          }),
        });
        setStatus(
          `Updated rules on ${result.surfaceId} → ${result.sourcePath}`,
          "ok",
        );
        await loadAll();
      } catch (e) {
        setStatus(String(e.message || e), "err");
      }
    });

    $("btnSaveRule")?.addEventListener("click", async () => {
      try {
        const id = $("ruleId")?.value;
        const result = await api(`/api/rules/${encodeURIComponent(id)}`, {
          method: "PUT",
          body: JSON.stringify({
            body: $("ruleBody")?.value,
            title: $("ruleTitle")?.value,
            regenerate: $("regenOnSave")?.checked,
          }),
        });
        const log = $("editorLog");
        if (log) {
          log.hidden = false;
          log.textContent = JSON.stringify(result, null, 2);
        }
        setStatus(`Wrote ${id} → ${result.sourcePath}`, "ok");
        const fresh = await api(`/api/rules/${encodeURIComponent(id)}`);
        state.rulesById.set(id, fresh);
        state.rules = state.rules.map((r) => (r.id === id ? fresh : r));
      } catch (e) {
        setStatus(String(e.message || e), "err");
      }
    });

    const filterList = (inputId, listId) => {
      const input = $(inputId);
      const list = $(listId);
      if (!input || !list) return;
      input.addEventListener("input", () => {
        const q = input.value.trim().toLowerCase();
        list.querySelectorAll(".list-item").forEach((el) => {
          el.style.display = !q || el.textContent.toLowerCase().includes(q)
            ? ""
            : "none";
        });
      });
    };
    filterList("flowFilter", "flowList");
    filterList("screenFilter", "screenList");
    filterList("ruleFilter", "ruleList");

    $("btnSync2")?.addEventListener("click", () => runSync());
    $("btnGenerate2")?.addEventListener("click", () => runGenerate());
    $("btnAddSurface")?.addEventListener("click", async () => {
      try {
        const id = $("newSurfaceId")?.value?.trim();
        const result = await api("/api/hub/add-surface", {
          method: "POST",
          body: JSON.stringify({
            surface: {
              id,
              title: $("newSurfaceTitle")?.value,
              path: $("newSurfacePath")?.value,
              captureId: id?.replace(/\./g, "-"),
            },
            regenerate: true,
          }),
        });
        setStatus(`Added surface ${result.surface?.id}`, "ok");
        await loadAll();
      } catch (e) {
        setStatus(String(e.message || e), "err");
      }
    });
  }

  async function runSync() {
    try {
      setStatus("Running product-map:sync…");
      const out = await api("/api/sync", { method: "POST", body: "{}" });
      const log = $("exportLog");
      if (log) {
        log.hidden = false;
        log.textContent = (out.stdout || "") + (out.stderr || "");
      }
      setStatus(out.ok ? "Sync OK" : "Sync failed", out.ok ? "ok" : "err");
      if (out.ok) await loadAll();
    } catch (e) {
      setStatus(String(e.message || e), "err");
    }
  }

  async function runGenerate() {
    try {
      setStatus("Generating…");
      const out = await api("/api/generate", { method: "POST", body: "{}" });
      setStatus(`Generated ${out.path} (${out.pages} pages)`, "ok");
    } catch (e) {
      setStatus(String(e.message || e), "err");
    }
  }

  $("modeTabs").addEventListener("click", (e) => {
    const b = e.target.closest("button[data-mode]");
    if (b) setMode(b.dataset.mode);
  });
  $("btnReload").addEventListener("click", () => loadAll().catch((e) => setStatus(String(e), "err")));
  $("btnSync").addEventListener("click", () => runSync());
  $("lbClose").addEventListener("click", closeLightbox);
  $("lightbox").addEventListener("click", (e) => {
    if (e.target === $("lightbox")) closeLightbox();
  });
  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape") closeLightbox();
  });

  loadAll().catch((e) => setStatus(String(e), "err"));
})();
