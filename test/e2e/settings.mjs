// The plugin setting "Mermaid URL" (Administration > Plugins > Configure): who may change it,
// a broken URL (diagrams stay raw text), a blank URL (falls back to the default), restore.
import { e2e } from '../../.codex/e2e/lib.mjs';

const P = 'e2e-project';
const SETTINGS = '/settings/plugin/redmine_mermaid_macro';
const t = await e2e('settings');

async function save(url) {
  await t.go(SETTINGS);
  await t.sudo();
  if (!(await t.page.locator('#settings_mermaid_url').count())) { await t.go(SETTINGS); }
  await t.page.fill('#settings_mermaid_url', url);
  await t.page.click('#settings-form input[type=submit], form.edit_settings input[type=submit], #content input[type=submit]');
  await t.settle();
  await t.sudo();
  t.check(`save ${url}`);
}

async function svgCount() {
  await t.go(`/projects/${P}/wiki/Diagrams`, { allow: { js: ['Failed to fetch', 'Failed to load', 'error loading dynamically imported module', 'Failed to resolve module', 'Unexpected token'], requests: ['/nonexistent'] } });
  await t.page.waitForTimeout(4000);
  return t.page.locator('div.mermaid svg').count();
}

await t.login('admin');
await t.go(SETTINGS);
await t.sudo();
await t.shot('form-default', 'The plugin configuration form shows the default jsDelivr URL');
const original = await t.page.inputValue('#settings_mermaid_url');
if (!/mermaid\.esm\.min\.mjs$/.test(original)) t.problems.push(`unexpected stored URL: ${original}`);

// broken URL
await save(`${t.BASE}/nonexistent/mermaid.mjs`);
if ((await svgCount()) !== 0) t.problems.push('broken URL: diagrams rendered anyway');
await t.shot('broken-url', 'With a URL that does not exist no diagram is drawn; the source stays as plain text and the page works');

// blank URL: default
await save('');
const rendered = await svgCount();
if (rendered < 2) t.problems.push(`blank URL: expected the default URL to be used, ${rendered} diagram(s) rendered`);
await t.shot('blank-url-default', 'A blank URL falls back to the default: the diagrams render again');

// restore
await save(original);
await t.go(SETTINGS);
await t.shot('restored', 'The original URL is stored again');

// without permission
for (const user of ['manager', 'reporter', 'outsider']) {
  await t.login(user);
  await t.go(SETTINGS, { status: 403 });
  await t.shot(`refused-${user}`, `${user} cannot open the plugin configuration`);
}
await t.done();
