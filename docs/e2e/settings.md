# settings

Run 2026-10-06T19:40:23.237Z against http://127.0.0.1:3000.

| screenshot | user | URL | shows |
|---|---|---|---|
| ![](settings-form-default.png) | admin | `/settings/plugin/redmine_mermaid_macro` | The plugin configuration form shows the default jsDelivr URL |
| ![](settings-broken-url.png) | admin | `/projects/e2e-project/wiki/Diagrams` | With a URL that does not exist no diagram is drawn; the source stays as plain text and the page works |
| ![](settings-blank-url-default.png) | admin | `/projects/e2e-project/wiki/Diagrams` | A blank URL falls back to the default: the diagrams render again |
| ![](settings-restored.png) | admin | `/settings/plugin/redmine_mermaid_macro` | The original URL is stored again |
| ![](settings-refused-manager.png) | manager | `/settings/plugin/redmine_mermaid_macro` | manager cannot open the plugin configuration |
| ![](settings-refused-reporter.png) | reporter | `/settings/plugin/redmine_mermaid_macro` | reporter cannot open the plugin configuration |
| ![](settings-refused-outsider.png) | outsider | `/settings/plugin/redmine_mermaid_macro` | outsider cannot open the plugin configuration |
