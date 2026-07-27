/* global fetch */
(() => {
  const $ = (id) => document.getElementById(id);

  /** @type {any} */
  let inventory = null;
  /** @type {Map<string, any>} */
  let rulesById = new Map();
  /** @type {Map<string, any>} nodeId → atlas payload */
  let atlasByNode = new Map();
  /** @type {any} */
  let atlasMeta = null;
  /** @type {string | null} */
  let activePageId = null;
  /** @type {string | null} */
  let activeNodeId = null;
  /** @type {string | null} */
  let activeRuleId = null;
  /** @type {any} */
  let activeNode = null;

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
    if (!res.ok) {
      throw new Error(data.message || res.statusText || "Request failed");
    }
    return data;
  }

  async function loadAll() {
    setStatus("Loading…");
    const [inv, rulesPayload, atlas] = await Promise.all([
      api("/api/inventory"),
      api("/api/rules"),
      api("/api/atlas"),
    ]);
    inventory = inv;
    rulesById = new Map((rulesPayload.rules || []).map((r) => [r.id, r]));
    atlasMeta = atlas;
    atlasByNode = new Map();

    // Prefetch atlas payloads for all nodes (small JSON; enables tree camera icons)
    const ids = [];
    const walk = (nodes) => {
      for (const n of nodes || []) {
        ids.push(n.id);
        walk(n.children);
      }
    };
    for (const p of inv.pages || []) walk(p.nodes);

    await Promise.all(
      ids.map(async (id) => {
        try {
          const payload = await api(
            `/api/atlas/node?id=${encodeURIComponent(id)}`,
          );
          atlasByNode.set(id, payload);
        } catch {
          /* ignore */
        }
      }),
    );

    // Deep links: ?node=build.finish&page=build (from Atlas diagram links)
    const params = new URLSearchParams(location.search);
    const qNode = params.get("node");
    const qPage = params.get("page");
    if (qPage && (inv.pages || []).some((p) => p.id === qPage)) {
      activePageId = qPage;
    }
    if (qNode) {
      activeNodeId = qNode;
      if (!activePageId) {
        const page = pageForNode(qNode, inv);
        if (page) activePageId = page;
      }
    }

    if (!activePageId && inv.pages?.length) {
      activePageId = inv.pages[0].id;
    }
    renderPageTabs();
    renderTree();
    if (activeNodeId) selectNode(activeNodeId);
    const shotNote = atlas.captureHint
      ? ` · ${atlas.captureHint}`
      : ` · ${atlas.shotCount} screenshots`;
    setStatus(
      `Loaded ${inv.pages?.length || 0} pages · ${rulesById.size} rules · ${atlas.nodesWithDirectAtlas || 0} Atlas-linked screens${shotNote}`,
      atlas.captureHint ? "err" : "ok",
    );
  }

  function pageForNode(nodeId, inv) {
    for (const p of inv.pages || []) {
      let found = false;
      const walk = (nodes) => {
        for (const n of nodes || []) {
          if (n.id === nodeId) found = true;
          walk(n.children);
        }
      };
      walk(p.nodes);
      if (found) return p.id;
    }
    return null;
  }

  function renderPageTabs() {
    const tabs = $("pageTabs");
    tabs.innerHTML = "";
    for (const p of inventory.pages || []) {
      const b = document.createElement("button");
      b.type = "button";
      b.textContent = p.label || p.id;
      if (p.id === activePageId) b.classList.add("on");
      b.addEventListener("click", () => {
        activePageId = p.id;
        renderPageTabs();
        renderTree();
      });
      tabs.appendChild(b);
    }
  }

  function nodeMatchesFilter(node, q) {
    if (!q) return true;
    const atlas = atlasByNode.get(node.id);
    const hay = [
      node.id,
      node.title,
      node.path,
      node.notes,
      ...(node.rules || []),
      ...(atlas?.atlasIds || []),
    ]
      .filter(Boolean)
      .join(" ")
      .toLowerCase();
    if (hay.includes(q)) return true;
    return (node.children || []).some((c) => nodeMatchesFilter(c, q));
  }

  function hasDirectShot(nodeId) {
    const a = atlasByNode.get(nodeId);
    return Boolean(a?.atlasIds?.length && !a.inheritedFrom && a.hasAnyShots);
  }

  function hasAnyAtlas(nodeId) {
    const a = atlasByNode.get(nodeId);
    return Boolean(a?.atlasIds?.length);
  }

  function renderTree() {
    const tree = $("tree");
    tree.innerHTML = "";
    const page = (inventory.pages || []).find((p) => p.id === activePageId);
    if (!page) return;
    const q = ($("treeFilter").value || "").trim().toLowerCase();

    const walk = (nodes, parent) => {
      for (const node of nodes || []) {
        if (!nodeMatchesFilter(node, q)) continue;
        const hasKids = (node.children || []).length > 0;
        const cam =
          hasDirectShot(node.id)
            ? '<span class="cam" title="Atlas screenshot">📷</span>'
            : hasAnyAtlas(node.id)
              ? '<span class="cam" title="Atlas link (may inherit)">◦</span>'
              : "";
        if (hasKids) {
          const det = document.createElement("details");
          det.open = true;
          const sum = document.createElement("summary");
          const btn = document.createElement("button");
          btn.type = "button";
          btn.className = "node-btn" + (node.id === activeNodeId ? " on" : "");
          btn.innerHTML = `<span class="kind">${escapeHtml(node.kind || "node")}</span>${escapeHtml(node.title || node.id)}${cam}`;
          btn.addEventListener("click", (e) => {
            e.preventDefault();
            e.stopPropagation();
            selectNode(node.id);
          });
          sum.appendChild(btn);
          det.appendChild(sum);
          const wrap = document.createElement("div");
          walk(node.children, wrap);
          det.appendChild(wrap);
          parent.appendChild(det);
        } else {
          const btn = document.createElement("button");
          btn.type = "button";
          btn.className = "node-btn" + (node.id === activeNodeId ? " on" : "");
          btn.innerHTML = `<span class="kind">${escapeHtml(node.kind || "node")}</span>${escapeHtml(node.title || node.id)}${cam}`;
          btn.addEventListener("click", () => selectNode(node.id));
          parent.appendChild(btn);
        }
      }
    };

    walk(page.nodes, tree);
  }

  function findNode(id) {
    let found = null;
    const walk = (nodes) => {
      for (const n of nodes || []) {
        if (n.id === id) found = n;
        walk(n.children);
      }
    };
    for (const p of inventory.pages || []) walk(p.nodes);
    return found;
  }

  function selectNode(id) {
    activeNodeId = id;
    activeNode = findNode(id);
    renderTree();
    renderNode();
  }

  function openLightbox(src, caption) {
    $("lbImg").src = src;
    $("lbCap").textContent = caption || "";
    $("lightbox").hidden = false;
  }
  function closeLightbox() {
    $("lightbox").hidden = true;
    $("lbImg").src = "";
  }

  function renderShots(nodeId) {
    const el = $("shots");
    const atlas = atlasByNode.get(nodeId);
    if (!atlas || !atlas.atlasIds?.length) {
      el.hidden = true;
      el.innerHTML = "";
      return;
    }

    el.hidden = false;
    const inherit = atlas.inheritedFrom
      ? ` <span class="meta">(inherited from <code>${escapeHtml(atlas.inheritedFrom)}</code>)</span>`
      : "";

    if (!atlas.hasAnyShots) {
      el.innerHTML = `
        <div class="shots-head"><h3>Atlas</h3></div>
        <p class="shots-empty">
          Linked screen(s): <code>${escapeHtml(atlas.atlasIds.join(", "))}</code>${inherit}.
          No PNGs found — run <code>npm run atlas:capture</code> then reload.
        </p>`;
      return;
    }

    let cards = "";
    for (const screen of atlas.screens || []) {
      for (const shot of screen.shots || []) {
        const cap = `${screen.title} · ${shot.variant}`;
        cards += `
          <button type="button" class="shot-card" data-full="${escapeHtml(shot.url)}" data-cap="${escapeHtml(cap)}">
            <img src="${escapeHtml(shot.url)}" alt="${escapeHtml(cap)}" loading="lazy" />
            <div class="cap"><strong>${escapeHtml(screen.id)}</strong>${escapeHtml(shot.variant)}${screen.path ? " · " + escapeHtml(screen.path) : ""}</div>
          </button>`;
      }
    }

    el.innerHTML = `
      <div class="shots-head">
        <h3>Atlas screenshots${inherit}</h3>
        <span class="meta">${escapeHtml(atlas.atlasIds.join(", "))}</span>
      </div>
      <div class="shots-grid">${cards}</div>`;

    el.querySelectorAll("[data-full]").forEach((btn) => {
      btn.addEventListener("click", () => {
        openLightbox(btn.getAttribute("data-full"), btn.getAttribute("data-cap"));
      });
    });
  }

  function renderNode() {
    const title = $("nodeTitle");
    const meta = $("nodeMeta");
    const body = $("nodeBody");
    const linked = $("linkedRules");
    linked.innerHTML = "";

    if (!activeNode) {
      title.textContent = "Select a node";
      meta.textContent = "";
      body.innerHTML = `<p class="empty">Choose a screen, surface, or field from the tree.</p>`;
      $("shots").hidden = true;
      return;
    }

    title.textContent = activeNode.title || activeNode.id;
    meta.textContent = `${activeNode.kind || "node"} · ${activeNode.id}`;
    renderShots(activeNode.id);

    body.innerHTML = `
      <dl class="kv">
        <dt>ID</dt><dd><code>${escapeHtml(activeNode.id)}</code></dd>
        <dt>Kind</dt><dd>${escapeHtml(activeNode.kind || "—")}</dd>
        <dt>Path</dt><dd>${escapeHtml(activeNode.path || "—")}</dd>
        <dt>Auth</dt><dd>${escapeHtml(activeNode.auth || "—")}</dd>
        <dt>Atlas</dt><dd>${escapeHtml(
          (atlasByNode.get(activeNode.id)?.atlasIds || []).join(", ") || "—",
        )}</dd>
      </dl>
      ${
        activeNode.notes
          ? `<p class="notes">${escapeHtml(activeNode.notes)}</p>`
          : ""
      }
      <p class="meta">Linked rule IDs (from inventory; edit structure in inventory.yaml)</p>
    `;

    const ids = activeNode.rules || [];
    if (!ids.length) {
      linked.innerHTML = `<p class="empty">No rules linked on this node.</p>`;
      return;
    }

    for (const rid of ids) {
      const rule = rulesById.get(rid);
      const chip = document.createElement("button");
      chip.type = "button";
      chip.className = "rule-chip" + (rid === activeRuleId ? " on" : "");
      chip.dataset.ruleId = rid;
      const layer = rule?.layer || "missing";
      const titleText = rule?.title || (rule ? rid : "missing from docs");
      chip.innerHTML = `<span class="layer ${layer}">${layer}</span><span class="id">${escapeHtml(rid)}</span>${escapeHtml(String(titleText).slice(0, 80))}`;
      chip.addEventListener("click", () => selectRule(rid));
      linked.appendChild(chip);
    }

    // Keep editor in sync if current rule still applies to this node
    if (activeRuleId && ids.includes(activeRuleId)) {
      fillEditor(activeRuleId);
    }
  }

  function fillEditor(id) {
    const rule = rulesById.get(id);
    $("ruleId").value = id;
    $("btnSave").disabled = !rule || rule.missing;

    if (!rule) {
      $("ruleTitle").value = "";
      $("ruleBody").value = "";
      $("editorMeta").textContent = "Rule not found in markdown sources.";
      $("btnSave").disabled = true;
      return;
    }

    $("ruleTitle").value = rule.title || id;
    $("ruleBody").value = rule.body || "";
    $("editorMeta").textContent = `${rule.layer} · ${rule.sourcePath}${
      rule.section ? " · " + rule.section : ""
    }`;
    $("btnSave").disabled = false;
  }

  function selectRule(id) {
    activeRuleId = id;
    document.querySelectorAll(".rule-chip").forEach((chip) => {
      chip.classList.toggle("on", chip.dataset.ruleId === id);
    });
    fillEditor(id);
  }

  async function saveRule() {
    const id = $("ruleId").value;
    if (!id) return;
    const body = $("ruleBody").value;
    const title = $("ruleTitle").value;
    const regenerate = $("regenOnSave").checked;
    try {
      setStatus(`Saving ${id}…`);
      const result = await api(`/api/rules/${encodeURIComponent(id)}`, {
        method: "PUT",
        body: JSON.stringify({ body, title, regenerate }),
      });
      $("editorLog").hidden = false;
      $("editorLog").textContent = JSON.stringify(result, null, 2);
      const fresh = await api(`/api/rules/${encodeURIComponent(id)}`);
      rulesById.set(id, fresh);
      selectRule(id);
      setStatus(
        `Wrote ${id} → ${result.sourcePath} (not committed)` +
          (result.drawio ? " · draw.io regenerated" : ""),
        "ok",
      );
    } catch (e) {
      setStatus(String(e.message || e), "err");
      $("editorLog").hidden = false;
      $("editorLog").textContent = String(e);
    }
  }

  async function generate() {
    try {
      setStatus("Regenerating draw.io…");
      const out = await api("/api/generate", { method: "POST", body: "{}" });
      setStatus(`Generated ${out.path} (${out.pages} pages)`, "ok");
    } catch (e) {
      setStatus(String(e.message || e), "err");
    }
  }

  function escapeHtml(s) {
    return String(s)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  $("btnReload").addEventListener("click", () =>
    loadAll().catch((e) => setStatus(String(e), "err")),
  );
  $("btnGenerate").addEventListener("click", () => generate());
  $("btnSave").addEventListener("click", () => saveRule());
  $("treeFilter").addEventListener("input", () => renderTree());
  $("lbClose").addEventListener("click", closeLightbox);
  $("lightbox").addEventListener("click", (e) => {
    if (e.target === $("lightbox")) closeLightbox();
  });
  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape") closeLightbox();
  });

  loadAll().catch((e) => setStatus(String(e), "err"));
})();
