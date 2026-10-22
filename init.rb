require File.expand_path('lib/mermaid_macro_hook', __dir__)

Redmine::Plugin.register :redmine_mermaid_macro do
  name 'Redmine Mermaid Macro plugin'
  author 'Taiki IKEGAME'
  description 'Add mermaid graphs to your wiki.'
  version '1.1.0'
  url 'https://github.com/taikii/redmine_mermaid_macro'
  author_url 'https://taikii.github.io'

  settings :default => { 'mermaid_url' => MermaidMacroHook::DEFAULT_MERMAID_URL },
           :partial => 'settings/redmine_mermaid_macro_settings'

  Redmine::WikiFormatting::Macros.register do
    desc "Add mermaid graphs to your wiki. Example:\n\n" +
         "{{mermaid\n" +
         "graph TD;\n" +
         "    A-->B;\n" +
         "    A-->C;\n" +
         "    B-->D;\n" +
         "    C-->D;\n" +
         "}}"
    macro :mermaid do |obj, args, text|
      divid = "mermaid_" + SecureRandom.urlsafe_base64(8)

      # A dynamic import, so that a mermaid.js that cannot be loaded (CDN blocked) shows a
      # message above the diagram's source text instead of only the raw text.
      url = MermaidMacroHook.mermaid_url
      js = ""
      js << "import(#{url.to_json}).then(({ default: mermaid }) => {\n"
      js << "  mermaid.initialize({ startOnLoad: false });\n"
      js << "  mermaid.run({querySelector: '##{divid}'});\n"
      js << "}, () => {\n"
      js << "  const message = document.createElement('p');\n"
      js << "  message.className = 'flash warning mermaid-load-error';\n"
      js << "  message.textContent = #{l(:text_mermaid_load_failed, url: url).to_json};\n"
      js << "  document.getElementById('#{divid}').before(message);\n"
      js << "});\n"

      out = ''.html_safe
      out << content_tag(:div, text, id: divid, class: 'mermaid')
      out << javascript_tag(js, type: 'module')
      out
    end
  end
end
