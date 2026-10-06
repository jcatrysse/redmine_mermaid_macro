# Redmine 7 migration: redmine_mermaid_macro

Start a Claude Code (or Codex) session on this repository, branch `redmine70-migration`, with:

> Read CLAUDE.md and docs/REDMINE7-MIGRATION.md, then carry out the Redmine 7 migration of this
> plugin as described there, on branch redmine70-migration. Report to me in Dutch at the end.

This file is the plan and the memory of that work. Update it as you go: verdicts, results,
what is left. Written 2026-10-06 from a measured analysis (report at the bottom).

## Status

| | |
|---|---|
| Plugin id | `redmine_mermaid_macro` |
| GEOxyz runs today | `mermaid10` |
| Upstream | taikii/redmine_mermaid_macro master @ 4de453f56aea7aeff168014fdea3e97e8d4c1098 (2025-12-17, docs); upstream mermaid10 = ec1be0b (identical to GEOxyz) |
| Runs on Redmine 7 as is | JA |
| Upstream sync | NIET NODIG: nothing: upstream mermaid10 is what GEOxyz runs; upstream master is the older mermaid<=9 line plus a docs commit |
| After sync | n.v.t. |
| Complexity (1 trivial .. 5 rewrite) | 1 |
| Measured on | Redmine 7.0.1 (7.0-stable-GEOxyz + latest 7.0-stable), Rails 8.1.3.1, Ruby 3.3.6, PostgreSQL 16 and MariaDB 10.11 |
| Branch head when this file was written | `ec1be0b` |

## Already on this branch

- nothing: the branch equals the branch GEOxyz runs today.

## Work list for the migration session

In this order: things that break, security, the GEOxyz changes, the open items, then the checks.

**Open items from the analysis** (Dutch; where they repeat a priority item, the priority item wins)

1. Plugin injects a second <script type=importmap> after Redmine 7's own import map and module script (base.html.erb:12 vs :17); works in browsers that merge multiple import maps (measured Chromium 141), fails silently elsewhere - test GEOxyz's browsers or import mermaid from the URL directly and drop the importmap hook
2. lib/mermaid_macro_hook.rb defines view_layouts_base_html_head twice, so the plugin CSS never loads (pre-existing, cosmetic)
3. Mermaid comes from jsdelivr (floating mermaid@10); consider self-hosting

**Checks**

4. Run the plugin's whole test suite on Redmine 7.0-stable-GEOxyz with PostgreSQL AND MariaDB, and once on 5.1-stable if the branch is meant to stay 5.1-compatible.
5. Check Redmine 7 webhooks against this plugin (see "Rules"), and note the result here even if nothing is needed.
6. Verify every feature of the plugin by hand on a running Redmine 7 (screenshots).

## GEOxyz changes to review or re-apply

None: this branch carries no GEOxyz commits of its own (upstream code only).

## After the upgrade (production)

Actions the person doing the upgrade must take, or know about, for this plugin:

- None known. Add here what the session finds.

## How to test

```sh
./.codex/redmine_clone.sh 7.0-stable-GEOxyz      # or 5.1-stable / 6.1-stable / 7.0-stable
./.codex/test_setup.sh                                 # RMP_DB=mariadb for MariaDB, RMP_PROVISION_DB=0 if a server runs
./.codex/test_plugin.sh                                # minitest + rspec of this plugin
```
On GitHub the same runs by hand only: Actions > "Redmine tests (manual)" > Run workflow.

The coordinator's harness (`plugin-check.sh` in the migration kit, kept outside this repo) adds a
browser smoke test of every page the plugin adds and runs all GEOxyz plugins together; the
results quoted in the analysis come from it.

## How the migration session works (same for every plugin)

1. **Start**: `git fetch && git checkout redmine70-migration && git pull`. Read this whole file,
   including the analysis report at the bottom. Do not reopen decisions recorded here.
2. **Baseline**: set up Redmine 7.0-stable-GEOxyz and run the plugin's tests on PostgreSQL and
   on MariaDB (see "How to test"). Write the numbers here before you change anything.
3. **GEOxyz changes**: go through the table above, one item at a time. Each kept or re-made change
   is its own commit with a test that proves it. Record the verdict in the table.
4. **Work list**: then the numbered list, in order. One concern per commit.
5. **Portability**: everything must run on Redmine's supported databases (PostgreSQL,
   MySQL/MariaDB; SQLite where the plugin already supports it). Migrations must be reversible and
   are run down and up on PostgreSQL and MariaDB.
6. **Browser**: start a Redmine 7 with this plugin, exercise every feature as admin and as a
   normal user with and without the plugin's permissions, and save screenshots (before on 5.1 or
   the old branch, after on 7.0) where behaviour or layout matters.
7. **Together**: run with the other GEOxyz plugins installed (the migration kit's harness, or
   `RMP_EXTRA_PLUGINS`). A failure that only appears in combination is a finding to record here.
8. **After the upgrade**: anything the production upgrade must do for this plugin (data fixes,
   settings, cron, files, removed features) goes into the section "After the upgrade".
9. **Finish**: update "Status" and the work list in this file, push `redmine70-migration`, and
   report: what changed, test numbers on both databases, what is left, what needs Jan.

### Stop and ask Jan when
- a GEOxyz change would be lost or behave differently for users;
- a new gem, a new setting with user impact, or a schema change not required by Redmine 7 seems needed;
- the change would send data to an external service;
- upstream and GEOxyz disagree on behaviour and both are defensible.

## Rules

- **Target**: Redmine 7.0-stable-GEOxyz (https://github.com/jcatrysse/redmine), Rails 8.1, Ruby 3.3+.
  Core sources for comparison: branches `5.1-stable`, `6.1-stable`, `7.0-stable`, `7.0-stable-GEOxyz`.
- **Evidence**: never report a test, lint or browser check as passed without having seen it.
  Quote the summary lines. "Should work" is not a result.
- **Tests**: never skip, delete or weaken a test. A test that encodes Redmine 5 markup or
  behaviour is updated to Redmine 7, with the reason in the commit. Every fix gets a test that
  fails without it.
- **Minimal diffs** in the plugin's own style. No reformatting, no unrelated refactoring.
  Something wrong elsewhere: write it down here, do not fix it in passing.
- **Security**: authorization on every action and entry point; `safe_attributes`, never
  `to_unsafe_hash` into `update`; no SQL built from params; no secrets in logs; no `html_safe` on
  user input.
- **Webhooks (new in Redmine 7)**: core sends issue payloads (core `issues/show.api.rsb`, rendered
  as the webhook owner) to webhook endpoints, past plugin hooks and controller patches. If the
  plugin hides, adds or changes issue data, make webhooks consistent with that or record why not.
- **Redmine 7 conventions**: SVG icons through `sprite_icon` (the `icon icon-*` CSS is gone),
  Propshaft assets under `assets/` (`/assets/plugin_assets/<id>/...`), the new header and user menu,
  `ContextMenus::*Controller`, Loofah-based text formatting, Chart.js as an ES module.
  The breaker list is in the migration kit's CHECKLIST.md.
- **Locales**: keep the locales the plugin ships in sync; translate a new key by matching the
  closest existing key in the same file, not from scratch; do not add new languages.
- **5.1 compatibility**: prefer fixes that also run on Redmine 5.1 so they can be merged early;
  say so when a fix cannot.
- **Git**: work on `redmine70-migration` only; never push to the default branch; never force-push
  a branch someone else uses. Descriptive commit messages (what and why).
- **GitHub Actions**: manual only (`workflow_dispatch`). Do not add push, pull_request or schedule
  triggers.

## Definition of done

- All items of the work list are done or explicitly deferred with a reason, in this file.
- The plugin's tests are green on Redmine 7.0-stable-GEOxyz with PostgreSQL and MariaDB
  (numbers in this file); boot, production-like eager load, migrations up/down OK.
- Every feature verified by hand on Redmine 7; screenshots listed.
- No new failure when run together with the other GEOxyz plugins.
- "After the upgrade" lists every action production needs; "Status" is current.


## Analysis report (2026-10-06, Dutch)

# redmine_mermaid_macro
- Gebruikte branch: mermaid10 @ ec1be0b (2023-03-28) - plugin id redmine_mermaid_macro, versie 1.1.0
- Upstream: taikii/redmine_mermaid_macro - upstream HEAD master @ 4de453f (2025-12-17, alleen auteur/LICENSE in init.rb). Upstream `mermaid10` @ ec1be0b = exact wat GEOxyz draait.
- Fork t.o.v. upstream: 0 eigen commits. Upstream master heeft 1 commit die mermaid10 mist (4de453f, docs). mermaid10 heeft 4 commits die master mist (049c2d9 mermaid v10, 326ba9a, e53921a, ec1be0b).
- Andere relevante branches: upstream/fork `mermaid9` (= e48be41, oude UMD-lijn), `fix-preview-not-working`, `fix.gantt-rect-style` (al in master).
- Opbouw: geen Gemfile, geen migraties, geen tests. Mermaid wordt client-side geladen als ES-module vanaf de instelbare URL (standaard `https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs`, zwevende 10.x) via een eigen `<script type="importmap">` in de head-hook. Propshaft speelt geen rol.

## 1. Werkt out of the box op Redmine 7?   JA (Chromium gemeten)
- Harness (`results/1006-084926-s1-redmine_mermaid_macro_origin_mermaid10`): boot OK, eager OK, migraties OK, smoke 60/60.
- Rendering in de browser (Chromium 141 headless, mermaid 10.9.8 lokaal geserveerd omdat de headless browser het CDN niet bereikt, `mermaid_url` daarheen gezet): wikipagina met 2 diagrammen (flowchart + sequence) -> beide `div.mermaid` met `<svg>` (`data-processed=true`). Issue-description -> svg. Wiki-edit-preview -> svg. Labels: HTML in labels wordt door mermaid zelf (strict) gestript ("Yes & <ok>" -> "Yes &").
- Loofah (R7): macro-output wordt na de sanitizer ingevoegd, dus niet geraakt. De tekst gaat ge-escaped in `content_tag(:div, text)`.

## 2. Upstream sync?   NIET NODIG
- Upstream heeft geen nieuwere mermaid10-code. master is de oudere mermaid <=9-lijn plus een docs-commit.

## 3. Werkt na sync op Redmine 7?   n.v.t.

## 4. Complexiteit en blokkers   score 1
- Blokkers: geen gemeten.
- Risico (niet gefixt, niet geverifieerd buiten Chromium): R7 rendert `javascript_importmap_tags` (core import map + `<script type="module">import "application"</script>`) **vóór** `call_hook :view_layouts_base_html_head` (`app/views/layouts/base.html.erb:12` vs `:17`). De import map van de plugin (`lib/mermaid_macro_hook.rb:11-21`) is daardoor een tweede map die pas na het starten van een module-load komt. Browsers met ondersteuning voor meerdere import maps voegen die samen (gemeten: werkt in Chromium 141). Browsers zonder die ondersteuning negeren de tweede map, dan faalt `import mermaid from 'mermaid'` en verschijnt er geen enkel diagram. Op 5.1 had core geen import map. Firefox/Safari niet getest. Robuuste kleine fix: in de macro `import mermaid from '<mermaid_url>'` (URL ge-escaped) en de importmap-hook laten vallen.
- Stille breuk (bestaand, al op 5.1): `lib/mermaid_macro_hook.rb:5` en `:11` definiëren `view_layouts_base_html_head` twee keer. De tweede overschrijft de eerste, dus `redmine_mermaid_macro.css` (gantt-taakhoogte) wordt nooit geladen (gemeten: geen stylesheet-link).
- Externe afhankelijkheid: jsdelivr CDN, zwevende `mermaid@10`. Mermaid 11 bestaat; wisselen kan via de plugininstelling (niet getest).
- Overlap met Redmine 7 core: geen (core rendert geen mermaid).
- Open werk voor ansif:
  1. Testen in de browsers die GEOxyz gebruikt (Firefox/Edge/Safari-versies), of de import-from-URL-fix toepassen.
  2. Dubbele hookmethode samenvoegen zodat de CSS laadt (cosmetisch).
  3. Overwegen mermaid zelf te hosten i.p.v. jsdelivr (privacy/beschikbaarheid).

## Branch redmine70-migration
- Basis: origin/mermaid10 @ ec1be0b (geen wijzigingen nodig)
- Commits: geen (branch = origin/mermaid10)
- Eindresultaat harness (`results/1006-095656-s1-redmine_mermaid_macro_redmine70-migration`): boot OK, eager OK, migraties OK, smoke 60/60 (geen tests in de plugin)
- Rollback migraties: n.v.t. (geen migraties)

