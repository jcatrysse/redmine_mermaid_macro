class MermaidMacroHook < Redmine::Hook::ViewListener
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::JavaScriptHelper

  DEFAULT_MERMAID_URL = 'https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs'

  # The configured mermaid.js URL, the default when the setting is blank.
  def self.mermaid_url
    url = Setting.plugin_redmine_mermaid_macro['mermaid_url'].to_s.strip
    url.empty? ? DEFAULT_MERMAID_URL : url
  end

  def view_layouts_base_html_head(context={})
    stylesheet_link_tag('redmine_mermaid_macro.css', :plugin => 'redmine_mermaid_macro', :media => 'all')
  end

end
