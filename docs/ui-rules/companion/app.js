/* global fetch */
(() => {
  const $ = (id) => document.getElementById(id);

  /** @type {any} */
  let inventory = null;
  /** @type {Map<string, any>} */
  let rulesById = new Map();
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
    const [inv, rulesPayload] = await Promise.all([
      api("/api/inventory"),
      api("/api/rules"),
    ]);
    inventory = inv;
    rulesById = new Map((rulesPayload.rules || []).map((r) => [r.id, r]));
    if (!activePageId && inv.pages?.length) {
      activePageId = inv.pages[0].id;
    }
    renderPageTabs();
    renderTree();
    if (activeNodeId) selectNode(activeNodeId);
    setStatus(
      `Loaded ${inv.pages?.length || 0} pages · ${rulesById.size} rules`,
      "ok",
    );
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
    const hay = [
      node.id,
      node.title,
      node.path,
      node.notes,
      ...(node.rules || []),
    ]
      .filter(Boolean)
      .join(" ")
      .toLowerCase();
    if (hay.includes(q)) return true;
    return (node.children || []).some((c) => nodeMatchesFilter(c, q));
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
        if (hasKids) {
          const det = document.createElement("details");
          det.open = true;
          const sum = document.createElement("summary");
          const btn = document.createElement("button");
          btn.type = "button";
          btn.className = "node-btn" + (node.id === activeNodeId ? " on" : "");
          btn.innerHTML = `<span class="kind">${escapeHtml(node.kind || "node")}</span>${escapeHtml(node.title || node.id)}`;
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
          btn.innerHTML = `<span class="kind">${escapeHtml(node.kind || "node")}</span>${escapeHtml(node.title || node.id)}`;
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
      return;
    }

    title.textContent = activeNode.title || activeNode.id;
    meta.textContent = `${activeNode.kind || "node"} · ${activeNode.id}`;

    body.innerHTML = `
      <dl class="kv">
        <dt>ID</dt><dd><code>${escapeHtml(activeNode.id)}</code></dd>
        <dt>Kind</dt><dd>${escapeHtml(activeNode.kind || "—")}</dd>
        <dt>Path</dt><dd>${escapeHtml(activeNode.path || "—")}</dd>
        <dt>Auth</dt><dd>${escapeHtml(activeNode.auth || "—")}</dd>
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
      chip.className =
        "rule-chip" + (rid === activeRuleId ? " on" : "");
      const layer = rule?.layer || "missing";
      const titleText = rule?.title || (rule ? rid : "missing from docs");
      chip.innerHTML = `<span class="layer ${layer}">${layer}</span><span class="id">${escapeHtml(rid)}</span>${escapeHtml(String(titleText).slice(0, 80))}`;
      chip.addEventListener("click", () => selectRule(rid));
      linked.appendChild(chip);
    }

    if (activeRuleId && ids.includes(activeRuleId)) {
      selectRule(activeRuleId);
    }
  }

  function selectRule(id) {
    activeRuleId = id;
    renderNode();
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
      // refresh rule from disk
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
      setStatus(
        `Generated ${out.path} (${out.pages} pages)`,
        "ok",
      );
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

  $("btnReload").addEventListener("click", () => loadAll().catch((e) => setStatus(String(e), "err")));
  $("btnGenerate").addEventListener("click", () => generate());
  $("btnSave").addEventListener("click", () => saveRule());
  $("treeFilter").addEventListener("input", () => renderTree());

  loadAll().catch((e) => setStatus(String(e), "err"));
})();
