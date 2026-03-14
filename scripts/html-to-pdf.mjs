#!/usr/bin/env node
/**
 * Convert an HTML file to PDF using Puppeteer (headless Chrome).
 * Supports inline base64 images and print-friendly CSS (@media print).
 *
 * Steps:
 *   1. Save your full HTML (e.g. BLOX User Journey) to a .html file in the repo.
 *   2. From repo root run:
 *
 *   node scripts/html-to-pdf.mjs <input.html> [output.pdf]
 *
 * Example:
 *   node scripts/html-to-pdf.mjs blox-journey.html blox-journey.pdf
 *
 * If output path is omitted, the PDF is written next to the HTML with .pdf extension.
 * Requires: puppeteer (already in devDependencies; npm install from repo root).
 */

import { readFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = resolve(__dirname, '..');

async function main() {
  const inputPath = process.argv[2];
  const outputPath = process.argv[3];

  if (!inputPath) {
    console.error('Usage: node scripts/html-to-pdf.mjs <input.html> [output.pdf]');
    process.exit(1);
  }

  const absInput = resolve(root, inputPath);
  const absOutput = outputPath
    ? resolve(root, outputPath)
    : absInput.replace(/\.html?$/i, '.pdf');

  let html;
  try {
    html = readFileSync(absInput, 'utf8');
  } catch (e) {
    console.error('Failed to read HTML file:', e.message);
    process.exit(1);
  }

  // Dynamic import so we only load Puppeteer when this script runs
  const puppeteer = await import('puppeteer');

  console.log('Launching browser...');
  const browser = await puppeteer.default.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });

  try {
    const page = await browser.newPage();

    await page.setContent(html, {
      waitUntil: 'load',
      timeout: 60000,
    });

    console.log('Generating PDF...');
    await page.pdf({
      path: absOutput,
      format: 'A4',
      printBackground: true,
      margin: { top: '12mm', right: '12mm', bottom: '12mm', left: '12mm' },
    });

    console.log('Written:', absOutput);
  } finally {
    await browser.close();
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
