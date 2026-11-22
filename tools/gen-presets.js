#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const CATALOG_PATH = path.join(ROOT, 'presets', 'catalog.json');
const GEN_CK_DIR = path.join(ROOT, 'framework', 'devices', 'presets', 'generated');
const GUI_CATALOG_PATH = path.join(ROOT, 'gui', 'js', 'catalog-data.js');

function escapeChuck(str) {
  return String(str).replace(/\\/g, '\\\\').replace(/"/g, '\\"');
}

function header(sourceDesc) {
  return [
    '// GENERATED from presets/catalog.json — do not edit manually.',
    `// Purpose: ${sourceDesc}`,
    '// Regenerate with: node tools/gen-presets.js',
    '',
  ].join('\n');
}

function genHydrasynth(entries) {
  const lines = [
    header('Hydrasynth preset catalog and HydraPresetCollection.'),
    '@import "../preset.ck"',
    '@import "../preset-collection.ck"',
    '',
    'public class HydrasynthPresetsData',
    '{',
    '    [',
  ];
  entries.forEach((p, idx) => {
    const comma = idx < entries.length - 1 ? ',' : '';
    lines.push(
      `        new HydraPreset(${p.program}, ${p.bank}, "${escapeChuck(p.code)}", "${escapeChuck(p.name)}", "${escapeChuck(p.category)}")${comma}`
    );
  });
  lines.push(
    '    ] @=> static Preset @ items[];',
    '}',
    '',
    'public class HydraPresetCollection extends PresetCollection',
    '{',
    '    fun HydraPresetCollection()',
    '    {',
    '        initItems(HydrasynthPresetsData.items);',
    '        0 => preferCurrentCategory;',
    '        1 => matchCode;',
    '    }',
    '}',
    ''
  );
  return lines.join('\n');
}

function genBankProgramPresetCollection({ desc, dataClass, presetClass, collectionClass, entries }) {
  const safeEntries = Array.isArray(entries) ? entries : [];
  const lines = [
    header(desc),
    '@import "../preset.ck"',
    '@import "../preset-collection.ck"',
    '',
    `public class ${dataClass}`,
    '{',
    '    [',
  ];
  safeEntries.forEach((p, idx) => {
    const comma = idx < safeEntries.length - 1 ? ',' : '';
    lines.push(
      `        new ${presetClass}(${p.program}, ${p.bank}, "${escapeChuck(p.name)}", "${escapeChuck(p.category)}")${comma}`
    );
  });
  lines.push(
    '    ] @=> static Preset @ items[];',
    '}',
    '',
    `public class ${collectionClass} extends PresetCollection`,
    '{',
    `    fun ${collectionClass}()`,
    '    {',
    `        initItems(${dataClass}.items);`,
    '        1 => preferCurrentCategory;',
    '        0 => matchCode;',
    '    }',
    '}',
    ''
  );
  return lines.join('\n');
}

function genMoogBanks(banks) {
  const lines = [
    header('Moog Messenger bank names.'),
    'public class MoogBanksData',
    '{',
    '    [',
  ];
  banks.forEach((b, idx) => {
    const comma = idx < banks.length - 1 ? ',' : '';
    lines.push(`        "${escapeChuck(b)}"${comma}`);
  });
  lines.push('    ] @=> static string BANK_NAMES[];', '}', '');
  return lines.join('\n');
}

function genSynthTable(synths) {
  const names = Object.keys(synths);
  const lines = [
    header('Synth registry metadata table (channel rules and default presets).'),
    'public class SynthTableData',
    '{',
    '    [',
  ];
  names.forEach((uiName, idx) => {
    const comma = idx < names.length - 1 ? ',' : '';
    lines.push(`        "${escapeChuck(uiName)}"${comma}`);
  });
  lines.push('    ] @=> static string UI_NAMES[];', '', '    [');
  names.forEach((uiName, idx) => {
    const comma = idx < names.length - 1 ? ',' : '';
    const fc = synths[uiName].fixedChannel === null ? -1 : synths[uiName].fixedChannel;
    lines.push(`        ${fc}${comma}`);
  });
  lines.push('    ] @=> static int FIXED_CHANNELS[];', '', '    [');
  names.forEach((uiName, idx) => {
    const comma = idx < names.length - 1 ? ',' : '';
    lines.push(`        ${synths[uiName].maxChannels}${comma}`);
  });
  lines.push('    ] @=> static int MAX_CHANNELS[];', '', '    [');
  names.forEach((uiName, idx) => {
    const comma = idx < names.length - 1 ? ',' : '';
    const dp = synths[uiName].defaultPreset || '';
    lines.push(`        "${escapeChuck(dp)}"${comma}`);
  });
  lines.push('    ] @=> static string DEFAULT_PRESETS[];', '}', '');
  return lines.join('\n');
}

function genGuiCatalogModule(catalog) {
  const moog = [];
  for (let b = 0; b < catalog.moogBanks.length; b++) {
    const category = catalog.moogBanks[b];
    for (let p = 0; p < 16; p++) {
      moog.push({
        program: p,
        bank: b,
        name: `${category}: ${p + 1}`,
        category,
      });
    }
  }
  const payload = Object.assign(
    {},
    catalog.presets,
    {
      Moog: moog,
      synths: Object.keys(catalog.synths),
      synthMeta: catalog.synths,
      moogBanks: catalog.moogBanks,
    }
  );
  return [
    '// GENERATED from presets/catalog.json — do not edit manually.',
    '// Regenerate with: node tools/gen-presets.js',
    `export const PRESET_CATALOG = ${JSON.stringify(payload)};`,
    '',
  ].join('\n');
}

function main() {
  const checkOnly = process.argv.includes('--check');
  const catalog = JSON.parse(fs.readFileSync(CATALOG_PATH, 'utf8'));

  const outputs = [
    [path.join(GEN_CK_DIR, 'hydrasynth-presets.ck'), genHydrasynth(catalog.presets.Hydrasynth)],
    [
      path.join(GEN_CK_DIR, 'sh4d-presets.ck'),
      genBankProgramPresetCollection({
        desc: 'Roland SH-4d tone preset catalog and SH4dPresetCollection.',
        dataClass: 'SH4dPresetsData',
        presetClass: 'SH4dPreset',
        collectionClass: 'SH4dPresetCollection',
        entries: catalog.presets['SH-4d'],
      }),
    ],
    [
      path.join(GEN_CK_DIR, 'v3-presets.ck'),
      genBankProgramPresetCollection({
        desc: 'V3 Grand Piano XXL preset catalog and V3PresetCollection.',
        dataClass: 'V3PresetsData',
        presetClass: 'V3Preset',
        collectionClass: 'V3PresetCollection',
        entries: catalog.presets.V3,
      }),
    ],
    [
      path.join(GEN_CK_DIR, 'acid-v-presets.ck'),
      genBankProgramPresetCollection({
        desc: 'Arturia Acid V preset catalog and AcidVPresetCollection.',
        dataClass: 'AcidVPresetsData',
        presetClass: 'AcidVPreset',
        collectionClass: 'AcidVPresetCollection',
        entries: catalog.presets['Acid V'],
      }),
    ],
    [
      path.join(GEN_CK_DIR, 'augmented-mallets-presets.ck'),
      genBankProgramPresetCollection({
        desc: 'Arturia Augmented Mallets preset catalog and AugmentedMalletsPresetCollection.',
        dataClass: 'AugmentedMalletsPresetsData',
        presetClass: 'AugmentedMalletsPreset',
        collectionClass: 'AugmentedMalletsPresetCollection',
        entries: catalog.presets['Augmented Mallets'],
      }),
    ],
    [path.join(GEN_CK_DIR, 'moog-banks.ck'), genMoogBanks(catalog.moogBanks)],
    [path.join(GEN_CK_DIR, 'synth-table.ck'), genSynthTable(catalog.synths)],
    [GUI_CATALOG_PATH, genGuiCatalogModule(catalog)],
  ];

  let stale = false;
  for (const [outPath, content] of outputs) {
    if (checkOnly) {
      let existing = null;
      try {
        existing = fs.readFileSync(outPath, 'utf8');
      } catch (_) {}
      if (existing !== content) {
        console.error(`Stale generated file: ${path.relative(ROOT, outPath)}`);
        stale = true;
      }
    } else {
      fs.mkdirSync(path.dirname(outPath), { recursive: true });
      fs.writeFileSync(outPath, content, 'utf8');
    }
  }

  if (checkOnly) {
    if (stale) {
      console.error('Run `node tools/gen-presets.js` to regenerate.');
      process.exit(1);
    }
    console.log(`OK: ${outputs.length} generated preset files match presets/catalog.json`);
  } else {
    console.log(`Generated ${outputs.length} preset files from presets/catalog.json`);
  }
}

main();
