import { state, send } from './state.js';

const GRAPH_WIDTH_KEY = 'cadenza.graphWidth';
let cy = null;
let graphSignature = '';
let cachedNormPos = new Map();
let relayoutTimer = null;

function mainRow() { return document.getElementById('mainRow'); }
function graphWin() { return document.getElementById('graphWindow'); }

export function graphVisible() {
  const row = mainRow();
  return row ? !row.classList.contains('graph-hidden') : false;
}

function clampGraphWidth(w) {
  return Math.min(Math.max(w, 180), Math.max(180, window.innerWidth - 420));
}

function setGraphWidth(w, persist) {
  const row = mainRow();
  if (!row) return;
  const clamped = clampGraphWidth(w);
  row.style.setProperty('--graph-w', clamped + 'px');
  if (persist) localStorage.setItem(GRAPH_WIDTH_KEY, String(Math.round(clamped)));
}

function syncMainRowHeight() {
  const row = mainRow();
  const h = document.querySelector('header');
  if (!h || !row) return;
  const headerBottom = h.getBoundingClientRect().bottom;
  const availHeight = Math.max(300, window.innerHeight - headerBottom - 44);
  row.style.height = availHeight + 'px';
}

export function setGraphVisible(on) {
  const row = mainRow();
  if (row) row.classList.toggle('graph-hidden', !on);
  const btn = document.getElementById('btnGraph');
  if (btn) btn.classList.toggle('active', on);
  if (on) updateGraph(true);
}

export function toggleGraphWindow() {
  setGraphVisible(!graphVisible());
}

function runGraphLayout(randomize) {
  if (!cy || cy.nodes().length === 0) return;
  const w = Math.max(180, cy.width());
  const h = Math.max(180, cy.height());
  const nodes = cy.nodes().toArray();
  const N = nodes.length;

  if (randomize || cachedNormPos.size !== N) {
    cy.layout({
      name: 'cose',
      animate: false,
      fit: false,
      randomize: true,
      boundingBox: { x1: 0, y1: 0, w, h },
      nodeRepulsion: () => 8000,
      idealEdgeLength: () => 80,
    }).run();

    cachedNormPos.clear();
    if (N === 1) {
      cachedNormPos.set(nodes[0].id(), { u: 0.5, v: 0.5 });
    } else {
      let cols = Math.round(Math.sqrt(N * (w / (h * 1.55))));
      if (N >= 4 && w >= 240) cols = Math.max(2, cols);
      if (N >= 15 && w >= 320) cols = Math.max(3, cols);
      cols = Math.max(1, Math.min(N, cols));
      const rows = Math.ceil(N / cols);

      const byY = nodes.slice().sort((a, b) => a.position('y') - b.position('y'));
      const basePerRow = Math.floor(N / rows);
      const extraRows = N % rows;
      let idx = 0;
      for (let r = 0; r < rows; r++) {
        const rowCols = basePerRow + (r < extraRows ? 1 : 0);
        const rowNodes = byY.slice(idx, idx + rowCols).sort((a, b) => a.position('x') - b.position('x'));
        idx += rowCols;
        const vBase = rows === 1 ? 0.5 : r / (rows - 1);
        const uStagger = (cols > 1 && rows > 1) ? ((r % 2 === 1 ? 1 : -1) * (0.12 / Math.max(1, cols - 1))) : 0;
        for (let c = 0; c < rowNodes.length; c++) {
          const uBase = rowCols === 1 ? 0.5 : c / (rowCols - 1);
          const vWave = (rowCols > 1 && rows > 1) ? ((c % 2 === 1 ? 1 : -1) * (0.10 / Math.max(1, rows - 1))) : 0;
          const u = Math.min(1, Math.max(0, uBase + uStagger));
          const v = Math.min(1, Math.max(0, vBase + vWave));
          cachedNormPos.set(rowNodes[c].id(), { u, v });
        }
      }
    }
  }

  cy.nodes().positions(n => {
    const p = cachedNormPos.get(n.id()) || { u: 0.5, v: 0.5 };
    return { x: p.u * w, y: p.v * h };
  });
  cy.fit(14);
}

function fmtProb(p) {
  return Math.round(p * 100) + '%';
}

function initCy() {
  if (cy) return;
  cy = cytoscape({
    container: document.getElementById('graphCanvas'),
    wheelSensitivity: 0.3,
    style: [
      { selector: 'node', style: {
          'label': 'data(label)', 'text-wrap': 'wrap', 'text-valign': 'center', 'text-halign': 'center',
          'color': '#ede9ff', 'font-size': 'data(fs)', 'font-family': 'JetBrains Mono, monospace',
          'background-color': '#1a1535', 'border-width': 1.5, 'border-color': '#4a4070',
          'shape': 'round-rectangle', 'width': 'label', 'height': 'label', 'padding': 'data(pad)' } },
      { selector: 'node.current', style: {
          'background-color': '#7c3aed', 'border-color': '#c4b5fd', 'border-width': 2.5, 'color': '#fff',
          'underlay-color': '#a78bfa', 'underlay-opacity': 0.45, 'underlay-padding': 6, 'z-index': 999 } },
      { selector: 'node.queued', style: {
          'background-color': '#0e3a47', 'border-color': '#22d3ee', 'border-width': 2.5, 'color': '#ecfeff',
          'underlay-color': '#06b6d4', 'underlay-opacity': 0.38, 'underlay-padding': 5, 'z-index': 998 } },
      { selector: 'node.looping', style: {
          'background-color': '#451a03', 'border-color': '#fbbf24', 'border-width': 3, 'color': '#fef3c7',
          'underlay-color': '#f59e0b', 'underlay-opacity': 0.5, 'underlay-padding': 7, 'z-index': 1000 } },
      { selector: 'node.current.looping', style: {
          'background-color': '#7c3aed', 'border-color': '#fbbf24', 'border-width': 3.5, 'color': '#fff',
          'underlay-color': '#f59e0b', 'underlay-opacity': 0.55, 'underlay-padding': 8, 'z-index': 1001 } },
      { selector: 'edge', style: {
          'curve-style': 'bezier', 'control-point-step-size': 50, 'loop-direction': '-45deg', 'loop-sweep': '40deg',
          'width': 'data(w)', 'line-color': '#5b4a9a', 'target-arrow-color': '#5b4a9a', 'target-arrow-shape': 'triangle',
          'arrow-scale': 1.1, 'label': 'data(label)', 'font-size': 'data(fs)', 'color': '#c9bff0', 'min-zoomed-font-size': 5,
          'font-family': 'JetBrains Mono, monospace', 'text-background-color': '#090614',
          'text-background-opacity': 0.9, 'text-background-padding': 2 } },
      { selector: 'edge.taken', style: {
          'line-color': '#22d3ee', 'target-arrow-color': '#22d3ee', 'width': 6, 'color': '#22d3ee', 'z-index': 10 } },
    ],
  });

  let tapTimer = null;
  let lastTapNodeId = null;
  cy.on('tap', 'node', (evt) => {
    const fragName = evt.target.id();
    if (!fragName) return;
    if (tapTimer && lastTapNodeId === fragName) {
      clearTimeout(tapTimer);
      tapTimer = null;
      lastTapNodeId = null;
      const curLoop = state.chuckState && state.chuckState.loopFragmentName;
      const nextVal = (curLoop === fragName) ? '' : fragName;
      if (state.chuckState) {
        state.chuckState.loopFragmentName = nextVal;
        if (nextVal) state.chuckState.nextFragmentName = '';
      }
      send('loopFragment', nextVal);
      updateGraph(false);
      return;
    }
    if (tapTimer) clearTimeout(tapTimer);
    lastTapNodeId = fragName;
    tapTimer = setTimeout(() => {
      tapTimer = null;
      lastTapNodeId = null;
      const curQueued = state.chuckState && state.chuckState.nextFragmentName;
      const nextVal = (curQueued === fragName) ? '' : fragName;
      if (state.chuckState) state.chuckState.nextFragmentName = nextVal;
      send('nextFragment', nextVal);
      updateGraph(false);
    }, 240);
  });

  cy.on('mouseover', 'node', () => {
    const el = document.getElementById('graphCanvas');
    if (el) el.style.cursor = 'pointer';
  });
  cy.on('mouseout', 'node', () => {
    const el = document.getElementById('graphCanvas');
    if (el) el.style.cursor = '';
  });
}

function nodeLabel(f, isCurrent, s) {
  if (f.repeat > 1) {
    return isCurrent && s && s.repeatIndex > 0
      ? `${f.name}\n${s.repeatIndex}/${f.repeat}`
      : `${f.name}\n×${f.repeat}`;
  }
  return f.name;
}

export function applyTakenEdge() {
  if (!cy) return;
  if (state.isSongReset || !state.lastTransition) {
    const taken = cy.edges('.taken');
    if (taken.length > 0) taken.removeClass('taken');
    return;
  }
  cy.edges().forEach(e => {
    const shouldBeTaken = e.data('source') === state.lastTransition.from && e.data('target') === state.lastTransition.to;
    if (e.hasClass('taken') !== shouldBeTaken) {
      e.toggleClass('taken', shouldBeTaken);
    }
  });
}

export function updateGraph(forceLayout) {
  if (!graphVisible()) return;
  const s = state.chuckState;
  const frags = state.chuckGraph;
  const empty = document.getElementById('graphEmpty');
  if (empty) empty.style.display = frags.length ? 'none' : 'flex';
  initCy();

  const cur = state.isSongReset ? null : (s && s.fragmentName);
  const queued = (s && s.nextFragmentName) ? s.nextFragmentName : null;
  const looping = (s && s.loopFragmentName) ? s.loopFragmentName : null;
  const sig = JSON.stringify(frags);
  if (forceLayout || sig !== graphSignature) {
    graphSignature = sig;
    cy.elements().remove();
    const fs = Math.min(14, Math.max(7, 16 - 0.35 * frags.length));
    const efs = Math.max(6, fs * 0.78);
    const pad = Math.round(fs * 0.7);
    const nodeIds = new Set();
    const nodeEls = [];
    const edgeEls = [];
    for (const f of frags) {
      if (!f || !f.name || nodeIds.has(f.name)) continue;
      nodeIds.add(f.name);
      nodeEls.push({
        group: 'nodes',
        data: { id: f.name, label: nodeLabel(f, f.name === cur, s), fs, pad },
      });
    }
    for (const f of frags) {
      if (!f || !f.name || !Array.isArray(f.edges)) continue;
      f.edges.forEach((e, i) => {
        if (!e || !e.to) return;
        if (!nodeIds.has(e.to)) {
          nodeIds.add(e.to);
          nodeEls.push({
            group: 'nodes',
            data: { id: e.to, label: e.to, fs, pad },
          });
        }
        const p = Number.isFinite(e.p) ? e.p : 0;
        edgeEls.push({
          group: 'edges',
          data: {
            id: `${f.name}->${e.to}#${i}`,
            source: f.name,
            target: e.to,
            label: fmtProb(p),
            w: 1.5 + 4 * p,
            fs: efs,
          },
        });
      });
    }
    cy.add(nodeEls);
    try {
      cy.add(edgeEls);
    } catch (_) {
      for (const edge of edgeEls) {
        try { cy.add(edge); } catch (_) {}
      }
    }
    if (nodeEls.length) {
      cy.resize();
      if (cy.width() > 0 && cy.height() > 0) {
        runGraphLayout(true);
      } else {
        requestAnimationFrame(() => {
          if (cy && graphVisible()) {
            cy.resize();
            runGraphLayout(true);
          }
        });
      }
    }
    applyTakenEdge();
  }

  if (state.isSongReset) {
    const curNodes = cy.nodes('.current');
    if (curNodes.length > 0) curNodes.removeClass('current');
  }
  for (const f of frags) {
    if (!f || !f.name) continue;
    const n = cy.getElementById(f.name);
    if (!n || n.empty()) continue;
    const isCur = f.name === cur;
    const isQueued = Boolean(queued && f.name === queued);
    const isLooping = Boolean(looping && f.name === looping);
    if (n.hasClass('current') !== isCur) n.toggleClass('current', isCur);
    if (n.hasClass('queued') !== isQueued) n.toggleClass('queued', isQueued);
    if (n.hasClass('looping') !== isLooping) n.toggleClass('looping', isLooping);
    const nextLbl = nodeLabel(f, isCur, s);
    if (n.data('label') !== nextLbl) n.data('label', nextLbl);
  }
  applyTakenEdge();
}

export function flashTransition(from, to) {
  state.lastTransition = { from, to };
  if (graphVisible()) applyTakenEdge();
}

export function initFragmentGraph() {
  const saved = parseInt(localStorage.getItem(GRAPH_WIDTH_KEY), 10);
  if (saved > 0) setGraphWidth(saved, false);

  syncMainRowHeight();
  window.addEventListener('resize', () => {
    syncMainRowHeight();
    if (graphVisible()) {
      const win = graphWin();
      if (win) {
        const cur = parseInt(getComputedStyle(win).width, 10);
        setGraphWidth(cur, false);
      }
    }
  });

  const graphDiv = document.getElementById('graphDivider');
  if (graphDiv) {
    let dragging = false;
    graphDiv.addEventListener('pointerdown', e => {
      dragging = true;
      graphDiv.setPointerCapture(e.pointerId);
      graphDiv.classList.add('dragging');
      document.body.classList.add('graph-resizing');
      e.preventDefault();
    });
    graphDiv.addEventListener('pointermove', e => {
      if (!dragging) return;
      const row = mainRow();
      if (!row) return;
      const rowRight = row.getBoundingClientRect().right;
      setGraphWidth(rowRight - e.clientX - 7, false);
    });
    const end = () => {
      if (!dragging) return;
      dragging = false;
      graphDiv.classList.remove('dragging');
      document.body.classList.remove('graph-resizing');
      const win = graphWin();
      if (win) setGraphWidth(parseInt(getComputedStyle(win).width, 10), true);
    };
    graphDiv.addEventListener('pointerup', end);
    graphDiv.addEventListener('pointercancel', end);
  }

  const graphBody = document.getElementById('graphBody');
  if (graphBody) {
    new ResizeObserver(() => {
      if (!graphVisible() || !cy) return;
      cy.resize();
      clearTimeout(relayoutTimer);
      relayoutTimer = setTimeout(() => runGraphLayout(false), 120);
    }).observe(graphBody);
  }

  document.addEventListener('visibilitychange', () => {
    if (!document.hidden) {
      syncMainRowHeight();
      if (cy && graphVisible()) {
        cy.resize();
        cy.forceRender();
      }
    }
  });
}
