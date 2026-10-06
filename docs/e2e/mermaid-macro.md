# mermaid-macro

Run 2026-10-06T20:23:55.530Z against http://127.0.0.1:3000.

| screenshot | user | URL | shows |
|---|---|---|---|
| ![](mermaid-macro-wiki-page.png) | manager | `/projects/e2e-project/wiki/Diagrams` | A wiki page with a flowchart and a sequence diagram, both rendered as SVG |
| ![](mermaid-macro-issue-description.png) | manager | `/issues/7` | The diagram in an issue description is rendered |
| ![](mermaid-macro-wiki-preview.png) | manager | `/projects/e2e-project/wiki/Preview_page/edit` | The Preview tab of the wiki editor renders the diagram |
| ![](mermaid-macro-wiki-saved.png) | manager | `/projects/e2e-project/wiki/Preview_page` | The saved page renders the diagram |
| ![](mermaid-macro-issue-note.png) | manager | `/issues/7` | A diagram in an issue note is rendered in the history |
| ![](mermaid-macro-invalid-diagram.png) | manager | `/projects/e2e-project/wiki/Broken` | An invalid diagram shows mermaid's own error, the surrounding text is intact |
| ![](mermaid-macro-gantt.png) | manager | `/projects/e2e-project/wiki/Gantt` | A gantt diagram; its the plugin stylesheet rule for task bars is loaded |
| ![](mermaid-macro-reporter-wiki.png) | reporter | `/projects/e2e-project/wiki/Diagrams` | A member without plugin permissions sees the diagrams |
| ![](mermaid-macro-outsider-public.png) | outsider | `/projects/e2e-project/wiki/Diagrams` | A non-member sees the diagrams of a public project |
| ![](mermaid-macro-outsider-private.png) | outsider | `/projects/e2e-private/wiki/Diagrams` | The private project's diagram page is refused for a non-member |
