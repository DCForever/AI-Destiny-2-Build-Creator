/**
 * Uncompressed draw.io (diagrams.net) multi-page generator.
 */

/**
 * @param {string} s
 */
export function xmlEscape(s) {
  return String(s)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;");
}

/**
 * @param {string} s
 * @param {number} max
 */
function wrapText(s, max = 48) {
  const words = String(s).replace(/\s+/g, " ").trim().split(" ");
  const lines = [];
  let cur = "";
  for (const w of words) {
    const next = cur ? `${cur} ${w}` : w;
    if (next.length > max && cur) {
      lines.push(cur);
      cur = w;
    } else {
      cur = next;
    }
  }
  if (cur) lines.push(cur);
  return lines.join("\n");
}

/**
 * Rough height for wrapped label.
 * @param {string} text
 * @param {number} lineH
 * @param {number} pad
 */
function textHeight(text, lineH = 14, pad = 20) {
  const lines = String(text).split("\n").length;
  return Math.max(36, lines * lineH + pad);
}

const KIND_STYLE = {
  page: "rounded=1;whiteSpace=wrap;html=1;fillColor=#1a1a2e;fontColor=#ffffff;strokeColor=#e2b714;fontStyle=1;fontSize=14;",
  screen:
    "rounded=1;whiteSpace=wrap;html=1;fillColor=#16213e;fontColor=#e8e8e8;strokeColor=#0f9b8e;fontStyle=1;fontSize=12;",
  subscreen:
    "rounded=1;whiteSpace=wrap;html=1;fillColor=#0f3460;fontColor=#e8e8e8;strokeColor=#533483;fontSize=11;",
  flow: "shape=rhombus;whiteSpace=wrap;html=1;fillColor=#2d4059;fontColor=#fff;strokeColor=#ea5455;fontSize=11;",
  field:
    "rounded=0;whiteSpace=wrap;html=1;fillColor=#1b262c;fontColor=#bbe1fa;strokeColor=#3282b8;fontSize=10;",
  surface:
    "rounded=1;whiteSpace=wrap;html=1;fillColor=#222831;fontColor=#eeeeee;strokeColor=#00adb5;fontSize=11;",
  gate: "rounded=1;whiteSpace=wrap;html=1;fillColor=#3d0000;fontColor=#ffcccc;strokeColor=#ff6b6b;fontSize=11;",
  auth: "rounded=1;whiteSpace=wrap;html=1;fillColor=#2c3333;fontColor=#e7f6f2;strokeColor=#a5c9ca;fontSize=10;dashed=1;",
  rule_dac:
    "rounded=0;whiteSpace=wrap;html=1;fillColor=#fff8e7;fontColor=#333;strokeColor=#e2b714;align=left;verticalAlign=top;spacingLeft=6;spacingTop=4;fontSize=9;",
  rule_dbr:
    "rounded=0;whiteSpace=wrap;html=1;fillColor=#e8f5e9;fontColor=#222;strokeColor=#43a047;align=left;verticalAlign=top;spacingLeft=6;spacingTop=4;fontSize=9;",
  rule_br:
    "rounded=0;whiteSpace=wrap;html=1;fillColor=#e3f2fd;fontColor=#222;strokeColor=#1e88e5;align=left;verticalAlign=top;spacingLeft=6;spacingTop=4;fontSize=9;",
  rule_slice:
    "rounded=0;whiteSpace=wrap;html=1;fillColor=#f3e5f5;fontColor=#222;strokeColor=#8e24aa;align=left;verticalAlign=top;spacingLeft=6;spacingTop=4;fontSize=9;",
  rule_missing:
    "rounded=0;whiteSpace=wrap;html=1;fillColor=#ffebee;fontColor=#b71c1c;strokeColor=#c62828;align=left;verticalAlign=top;spacingLeft=6;spacingTop=4;fontSize=9;dashed=1;",
  edge: "edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;strokeColor=#888;endArrow=block;endFill=1;",
  edge_rule:
    "edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;strokeColor=#bbb;dashed=1;endArrow=none;opacity=60;",
};

/**
 * @typedef {object} DrawNode
 * @property {string} id
 * @property {string} kind
 * @property {string} title
 * @property {string} [path]
 * @property {string} [auth]
 * @property {string} [notes]
 * @property {string[]} [rules]
 * @property {DrawNode[]} [children]
 * @property {string[]} [flowsTo]
 */

/**
 * Flatten tree to layout list with depth.
 * @param {DrawNode[]} nodes
 * @param {number} depth
 * @returns {{ node: DrawNode, depth: number }[]}
 */
function flatten(nodes, depth = 0) {
  /** @type {{ node: DrawNode, depth: number }[]} */
  const out = [];
  for (const n of nodes ?? []) {
    out.push({ node: n, depth });
    if (n.children?.length) {
      out.push(...flatten(n.children, depth + 1));
    }
  }
  return out;
}

/**
 * Build one diagram page XML (inner mxGraphModel).
 * @param {object} page
 * @param {Map<string, import('./parse-rules.mjs').RuleRecord>} ruleById
 * @param {(ids: string[]) => string[]} expandRefs
 * @param {{ atlasIndex?: Map<string, { ids: string[], inheritedFrom: string|null }> }} [opts]
 */
export function buildDiagramModel(page, ruleById, expandRefs, opts = {}) {
  const atlasIndex = opts.atlasIndex || null;
  let cellId = 2;
  const nextId = () => String(cellId++);

  /** @type {string[]} */
  const cells = [];
  cells.push('<mxCell id="0"/>');
  cells.push('<mxCell id="1" parent="0"/>');

  const title = page.label || page.id;
  const titleId = nextId();
  cells.push(
    `<mxCell id="${titleId}" value="${xmlEscape(title)}" style="${KIND_STYLE.page}" vertex="1" parent="1">` +
      `<mxGeometry x="40" y="20" width="320" height="48" as="geometry"/>` +
      `</mxCell>`,
  );

  if (page.description) {
    const dId = nextId();
    cells.push(
      `<mxCell id="${dId}" value="${xmlEscape(wrapText(page.description, 80))}" style="text;html=1;strokeColor=none;fillColor=none;align=left;fontSize=11;fontColor=#666;" vertex="1" parent="1">` +
        `<mxGeometry x="380" y="24" width="480" height="40" as="geometry"/>` +
        `</mxCell>`,
    );
  }

  const flat = flatten(page.nodes ?? []);
  const uiWidth = 220;
  const ruleWidth = 300;
  let y = 100;
  const xBase = 40;
  /** @type {Map<string, string>} inventory id → mx cell id for UI nodes */
  const uiCellByInv = new Map();
  /** @type {{ from: string, to: string }[]} */
  const flowEdges = [];

  for (const { node, depth } of flat) {
    const x = xBase + depth * 40;
    const kind = node.kind || "surface";
    const style = KIND_STYLE[kind] || KIND_STYLE.surface;
    const authNote = node.auth ? `\n[${node.auth}]` : "";
    const pathNote = node.path ? `\n${node.path}` : "";
    let atlasNote = "";
    if (atlasIndex) {
      const link = atlasIndex.get(node.id);
      if (link?.ids?.length && !link.inheritedFrom) {
        atlasNote = `\n📷 ${link.ids.join(", ")}`;
      } else if (link?.ids?.length && link.inheritedFrom) {
        // omit inherited noise on deep fields; screens already show direct ids
      }
    }
    const label = `${node.title}${authNote}${pathNote}${atlasNote}`;
    const h = textHeight(label, 13, 16);
    const uid = nextId();
    uiCellByInv.set(node.id, uid);
    cells.push(
      `<mxCell id="${uid}" value="${xmlEscape(label)}" style="${style}" vertex="1" parent="1">` +
        `<mxGeometry x="${x}" y="${y}" width="${uiWidth}" height="${h}" as="geometry"/>` +
        `</mxCell>`,
    );

    // custom data for round-trip / docs
    // (draw.io userObject optional — keep simple labels)

    const ruleIds = expandRefs(node.rules ?? []);
    let ruleY = y;
    let ruleX = x + uiWidth + 30 + (3 - Math.min(depth, 3)) * 10;

    for (const rid of ruleIds) {
      const rec = ruleById.get(rid);
      let ruleLabel;
      let rStyle;
      if (!rec) {
        ruleLabel = `${rid}\n(missing from docs)`;
        rStyle = KIND_STYLE.rule_missing;
      } else {
        const body = wrapText(`${rid} — ${rec.title}\n${rec.body}`, 46);
        ruleLabel = body.length > 900 ? body.slice(0, 897) + "…" : body;
        rStyle =
          KIND_STYLE[`rule_${rec.layer}`] || KIND_STYLE.rule_slice;
      }
      const rh = Math.min(220, textHeight(ruleLabel, 11, 14));
      const ridCell = nextId();
      cells.push(
        `<mxCell id="${ridCell}" value="${xmlEscape(ruleLabel)}" style="${rStyle}" vertex="1" parent="1">` +
          `<mxGeometry x="${ruleX}" y="${ruleY}" width="${ruleWidth}" height="${rh}" as="geometry"/>` +
          `</mxCell>`,
      );
      const eId = nextId();
      cells.push(
        `<mxCell id="${eId}" style="${KIND_STYLE.edge_rule}" edge="1" parent="1" source="${uid}" target="${ridCell}">` +
          `<mxGeometry relative="1" as="geometry"/>` +
          `</mxCell>`,
      );
      ruleY += rh + 8;
      // cascade rule columns if too many
      if (ruleY > y + 480) {
        ruleY = y;
        ruleX += ruleWidth + 16;
      }
    }

    const blockH = Math.max(
      h,
      ruleIds.length ? ruleY - y : h,
      ruleIds.length * 40,
    );
    y += blockH + 28;

    for (const target of node.flowsTo ?? []) {
      flowEdges.push({ from: node.id, to: target });
    }
  }

  for (const { from, to } of flowEdges) {
    const s = uiCellByInv.get(from);
    const t = uiCellByInv.get(to);
    if (!s || !t) continue;
    const eId = nextId();
    cells.push(
      `<mxCell id="${eId}" style="${KIND_STYLE.edge}" edge="1" parent="1" source="${s}" target="${t}">` +
        `<mxGeometry relative="1" as="geometry"/>` +
        `</mxCell>`,
    );
  }

  // Legend
  const legendY = y + 20;
  const legendItems = [
    ["DAC (acceptance)", KIND_STYLE.rule_dac],
    ["DBR (domain BR)", KIND_STYLE.rule_dbr],
    ["BR (feature BR)", KIND_STYLE.rule_br],
    ["Slice AC/SC", KIND_STYLE.rule_slice],
  ];
  let lx = 40;
  for (const [lab, st] of legendItems) {
    const id = nextId();
    cells.push(
      `<mxCell id="${id}" value="${xmlEscape(lab)}" style="${st}" vertex="1" parent="1">` +
        `<mxGeometry x="${lx}" y="${legendY}" width="140" height="32" as="geometry"/>` +
        `</mxCell>`,
    );
    lx += 150;
  }

  return {
    cellsXml: cells.join("\n        "),
    pageHeight: legendY + 80,
    pageWidth: 1600,
  };
}

/**
 * @param {object[]} pages - inventory pages
 * @param {Map<string, import('./parse-rules.mjs').RuleRecord>} ruleById
 * @param {(ids: string[]) => string[]} expandRefs
 * @param {{ atlasIndex?: Map<string, { ids: string[], inheritedFrom: string|null }> }} [opts]
 */
export function buildMxFile(pages, ruleById, expandRefs, opts = {}) {
  const diagrams = pages.map((page, idx) => {
    const { cellsXml, pageHeight, pageWidth } = buildDiagramModel(
      page,
      ruleById,
      expandRefs,
      opts,
    );
    const name = xmlEscape(page.label || page.id);
    const id = xmlEscape(page.id || `page-${idx}`);
    return `  <diagram id="${id}" name="${name}">
    <mxGraphModel dx="1200" dy="800" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="${pageWidth}" pageHeight="${Math.max(pageHeight, 1100)}" math="0" shadow="0">
      <root>
        ${cellsXml}
      </root>
    </mxGraphModel>
  </diagram>`;
  });

  return `<?xml version="1.0" encoding="UTF-8"?>
<mxfile host="app.diagrams.net" agent="d2bc-ui-rules" version="22.1.0" type="device" compressed="false">
${diagrams.join("\n")}
</mxfile>
`;
}
