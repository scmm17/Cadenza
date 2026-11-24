'use strict';

const fs = require('fs');
const path = require('path');

const CATALOG_PATH = path.join(__dirname, '..', '..', 'presets', 'catalog.json');

let cachedCatalog = null;
let cachedMtimeMs = -1;

function loadPresetCatalog() {
  try {
    const stat = fs.statSync(CATALOG_PATH);
    if (cachedCatalog && stat.mtimeMs === cachedMtimeMs) {
      return cachedCatalog;
    }
    const catalog = JSON.parse(fs.readFileSync(CATALOG_PATH, 'utf8'));
    const moogBanks = Array.isArray(catalog.moogBanks) ? catalog.moogBanks : [];
    const moog = [];
    for (let b = 0; b < moogBanks.length; b++) {
      const category = moogBanks[b];
      for (let p = 0; p < 16; p++) {
        moog.push({
          program: p,
          bank: b,
          name: `${category}: ${p + 1}`,
          category,
        });
      }
    }
    cachedCatalog = Object.assign(
      {},
      catalog.presets || {},
      {
        V3: (catalog.presets && catalog.presets.V3) || [],
        Hydrasynth: (catalog.presets && catalog.presets.Hydrasynth) || [],
        'SH-4d': (catalog.presets && catalog.presets['SH-4d']) || [],
        Moog: moog,
        synths: catalog.synths ? Object.keys(catalog.synths) : ['V3', 'Hydrasynth', 'SH-4d', 'S-1', 'Moog', 'RD-6'],
        synthMeta: catalog.synths || {},
        moogBanks,
      }
    );
    cachedMtimeMs = stat.mtimeMs;
    return cachedCatalog;
  } catch (err) {
    console.error('Failed to load presets/catalog.json:', err.message);
    return {
      V3: [],
      Hydrasynth: [],
      'SH-4d': [],
      Moog: [],
      synths: ['V3', 'Hydrasynth', 'SH-4d', 'S-1', 'Moog', 'RD-6'],
      synthMeta: {},
      moogBanks: [],
    };
  }
}

module.exports = { loadPresetCatalog };
