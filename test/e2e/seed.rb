# Plugin data for the end-to-end scenarios, run after .codex/e2e/seed.rb. Idempotent.
admin = User.find_by!(login: 'admin')
User.current = admin

FLOW = "{{mermaid\ngraph TD;\n    A[Start]-->B{Ok?};\n    B-->|yes| C[Done];\n    B-->|no| D[Retry];\n}}"
SEQ = "{{mermaid\nsequenceDiagram\n    Alice->>Bob: Hello Bob\n    Bob-->>Alice: Hi Alice\n}}"

%w[e2e-project e2e-private].each do |identifier|
  project = Project.find_by!(identifier: identifier)
  wiki = project.wiki
  next if wiki.find_page('Diagrams')

  page = WikiPage.new(wiki: wiki, title: 'Diagrams')
  page.save_with_content(WikiContent.new(text: "Diagram page.\n\nFlowchart:\n\n#{FLOW}\n\nSequence:\n\n#{SEQ}", author: admin))
end

project = Project.find_by!(identifier: 'e2e-project')
unless Issue.where(project_id: project.id, subject: 'Mermaid issue').exists?
  Issue.create!(project: project, tracker: project.trackers.first, subject: 'Mermaid issue', author: admin,
                priority: IssuePriority.default || IssuePriority.first, status: IssueStatus.sorted.first,
                description: "Diagram in a description:\n\n#{FLOW}")
end
