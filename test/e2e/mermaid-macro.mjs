// The {{mermaid}} macro: wiki page, issue description, wiki preview, a new wiki page, an issue note,
// an invalid diagram, and who can see what (manager, reporter, outsider).
import { e2e } from '../../.codex/e2e/lib.mjs';

const P = 'e2e-project';
const t = await e2e('mermaid-macro');

async function expectDiagrams(where, selector, n) {
  try {
    await t.page.waitForFunction(([sel, count]) => document.querySelectorAll(sel).length >= count,
      [`${selector} div.mermaid[data-processed=true] svg`, n], { timeout: 30000 });
  } catch {
    t.problems.push(`${where}: fewer than ${n} rendered diagram(s) (<svg> inside div.mermaid)`);
  }
}

await t.login('manager');

// 1. wiki page with two diagrams, plugin stylesheet loaded
await t.go(`/projects/${P}/wiki/Diagrams`);
await expectDiagrams('wiki page', '.wiki', 2);
if (!(await t.page.locator('link[href*="redmine_mermaid_macro"]').count())) t.problems.push('plugin stylesheet link missing in <head>');
if (await t.page.locator('script[type=importmap]:has-text("mermaid")').count()) t.problems.push('plugin import map is still injected');
await t.shot('wiki-page', 'A wiki page with a flowchart and a sequence diagram, both rendered as SVG');

// 2. issue description
await t.go(`/projects/${P}/issues?set_filter=1&f[]=subject&op[subject]=~&v[subject][]=Mermaid`);
await t.page.click('table.issues td.subject a');
await t.settle();
await expectDiagrams('issue description', '.issue .description', 1);
await t.shot('issue-description', 'The diagram in an issue description is rendered');

// 3. wiki edit preview
await t.go(`/projects/${P}/wiki/Preview_page/edit`);
await t.page.fill('#content_text', '{{mermaid\ngraph LR;\n    X-->Y;\n}}');
await t.page.click('a.tab-preview');
await expectDiagrams('wiki preview', '#wiki_form', 1);
await t.shot('wiki-preview', 'The Preview tab of the wiki editor renders the diagram');

// 4. save a new page, rendered after saving
await t.page.click('#wiki_form input[name=commit]');
await t.settle();
t.check('save wiki page');
await expectDiagrams('saved wiki page', '.wiki', 1);
await t.shot('wiki-saved', 'The saved page renders the diagram');

// 5. note on an issue
const issueUrl = (await (async () => {
  await t.go(`/projects/${P}/issues?set_filter=1&f[]=subject&op[subject]=~&v[subject][]=Mermaid`);
  return t.page.getAttribute('table.issues td.subject a', 'href');
})());
await t.go(`${issueUrl}/edit`);
await t.page.fill('#issue_notes', 'A note:\n\n{{mermaid\nsequenceDiagram\n    A->>B: note\n}}');
await t.page.click('#issue-form input[name=commit]');
await t.settle();
t.check('add note');
await expectDiagrams('issue note', '.journal', 1);
await t.shot('issue-note', 'A diagram in an issue note is rendered in the history');

// 6. invalid diagram: mermaid reports a syntax error, the page itself stays usable
await t.go(`/projects/${P}/wiki/Broken/edit`);
await t.page.fill('#content_text', 'Before.\n\n{{mermaid\nthis is not a diagram\n}}\n\nAfter the diagram.');
await t.page.click('#wiki_form input[name=commit]');
await t.settle();
await t.page.waitForTimeout(3000);
t.check('invalid diagram', { js: ['Object', 'UnknownDiagramError', 'No diagram type detected', 'Syntax error'], requests: [] });
if (!(await t.page.locator('.wiki', { hasText: 'After the diagram.' }).count())) t.problems.push('invalid diagram: rest of the page missing');
await t.shot('invalid-diagram', 'An invalid diagram shows mermaid\'s own error, the surrounding text is intact');

// 6b. gantt diagram, with the plugin stylesheet (.mermaid rect.task)
await t.go(`/projects/${P}/wiki/Gantt/edit`);
await t.page.fill('#content_text', '{{mermaid\ngantt\n    dateFormat YYYY-MM-DD\n    title Plan\n    section A\n    Task one :a1, 2026-01-01, 10d\n    Task two :after a1, 5d\n}}');
await t.page.click('#wiki_form input[name=commit]');
await t.settle();
await expectDiagrams('gantt', '.wiki', 1);
const cssLoaded = await t.page.evaluate(() => [...document.styleSheets].some(sheet => {
  try { return [...sheet.cssRules].some(r => (r.selectorText || '') === '.mermaid rect.task' && r.style.height === '20px'); } catch { return false; }
}));
if (!cssLoaded) t.problems.push('gantt: the plugin stylesheet rule ".mermaid rect.task" is not applied');
await t.shot('gantt', 'A gantt diagram; its the plugin stylesheet rule for task bars is loaded');

// 7. reporter: member without the plugin's permissions (the macro has none)
await t.login('reporter');
await t.go(`/projects/${P}/wiki/Diagrams`);
await expectDiagrams('reporter wiki', '.wiki', 2);
await t.shot('reporter-wiki', 'A member without plugin permissions sees the diagrams');

// 8. outsider: public project visible, private project refused
await t.login('outsider');
await t.go(`/projects/${P}/wiki/Diagrams`);
await expectDiagrams('outsider public wiki', '.wiki', 2);
await t.shot('outsider-public', 'A non-member sees the diagrams of a public project');
await t.go('/projects/e2e-private/wiki/Diagrams', { status: 403 });
if (await t.page.locator('div.mermaid').count()) t.problems.push('outsider: diagram visible in the private project');
await t.shot('outsider-private', 'The private project\'s diagram page is refused for a non-member');

await t.done();
