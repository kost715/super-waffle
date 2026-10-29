// Converts textures/*_ca.png to addons/pmc_interactions/data/*_ca.paa with the Gruppe Adler
// converter (https://paa.gruppe-adler.de), driving it in headless Chromium. The site converts
// in the browser; files are not uploaded.
// Many files at once make some conversions fail, so files go in small batches, and a batch
// that does not return every file is retried one file at a time.
// Usage: node tools/paa_online.js [--missing] [png folder] [paa folder]   (needs the playwright package)
// --missing converts only the PNGs that have no PAA yet; otherwise all are converted again.
const { chromium } = require('playwright');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFileSync } = require('child_process');

const args = process.argv.slice(2);
const missingOnly = args.includes('--missing');
const [folderArg, outArg] = args.filter(a => a !== '--missing');
const folder = path.resolve(folderArg || path.join(__dirname, '..', 'textures'));
const out = path.resolve(outArg || path.join(__dirname, '..', 'addons', 'pmc_interactions', 'data'));
const BATCH = 4;

async function convert(browser, files) {
  const context = await browser.newContext({ acceptDownloads: true });
  const page = await context.newPage();
  try {
    await page.goto('https://paa.gruppe-adler.de/', { waitUntil: 'networkidle', timeout: 60000 });
    await page.setInputFiles('input[type=file]', files.map(f => path.join(folder, f)));
    const button = page.locator('button:has-text("Download all")');
    await button.waitFor({ state: 'visible', timeout: 300000 });
    for (let t = 0; t < 600; t++) {  // wait until no file shows the hourglass
      const icons = await page.evaluate(() => [...document.querySelectorAll('i.material-icons-round')].map(i => i.textContent.trim()));
      if (!icons.includes('hourglass_empty')) break;
      await page.waitForTimeout(1000);
    }
    const [download] = await Promise.all([page.waitForEvent('download', { timeout: 300000 }), button.click()]);
    const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'paa-'));
    const saved = path.join(temp, download.suggestedFilename());
    await download.saveAs(saved);
    if (saved.endsWith('.zip')) execFileSync('unzip', ['-o', '-q', saved, '-d', out]);
    else fs.copyFileSync(saved, path.join(out, path.basename(saved)));
    fs.rmSync(temp, { recursive: true, force: true });
  } finally {
    await context.close();
  }
  return files.filter(f => !fs.existsSync(path.join(out, f.replace(/\.png$/, '.paa'))));
}

(async () => {
  const paaOf = f => path.join(out, f.replace(/\.png$/, '.paa'));
  fs.mkdirSync(out, { recursive: true });
  const files = fs.readdirSync(folder).filter(f => /_ca\.png$/.test(f) && !(missingOnly && fs.existsSync(paaOf(f)))).sort();
  for (const f of files) fs.rmSync(path.join(out, f.replace(/\.png$/, '.paa')), { force: true });
  const browser = await chromium.launch();
  const failed = [];
  for (let i = 0; i < files.length; i += BATCH) {
    for (const f of await convert(browser, files.slice(i, i + BATCH))) {
      if ((await convert(browser, [f])).length) failed.push(f);
    }
  }
  await browser.close();
  console.log(`${files.length - failed.length} of ${files.length} converted into ${out}`);
  if (failed.length) { console.log('failed:', failed.join(', ')); process.exit(1); }
})().catch(e => { console.error(e); process.exit(1); });
