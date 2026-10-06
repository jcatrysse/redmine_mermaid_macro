require File.expand_path('../test_helper', __dir__)

class MermaidMacroTest < Redmine::HelperTest
  include ApplicationHelper
  include ERB::Util

  def setup
    super
    @default_url = MermaidMacroHook::DEFAULT_MERMAID_URL
    set_url(@default_url)
  end

  def teardown
    set_url(@default_url)
  end

  def set_url(url)
    Setting.plugin_redmine_mermaid_macro = { 'mermaid_url' => url }
  end

  def render_macro(text = "graph TD;\n    A-->B;")
    textilizable("{{mermaid\n#{text}\n}}")
  end

  def test_macro_is_registered
    assert Redmine::WikiFormatting::Macros.available_macros.key?(:mermaid)
  end

  def test_macro_renders_div_with_escaped_source_and_module_script
    html = render_macro
    assert_select_in html, 'div.mermaid[id^=mermaid_]', text: /graph TD;\s+A-->B;/
    assert_select_in html, 'script[type=module]', 1
    assert_includes html, 'A--&gt;B;'
  end

  def test_macro_script_targets_its_own_div
    html = render_macro
    id = html[/<div class="mermaid" id="(mermaid_[^"]+)"/, 1] || html[/id="(mermaid_[^"]+)"/, 1]
    assert id
    assert_includes html, "mermaid.run({querySelector: '##{id}'})"
  end

  def test_macro_imports_mermaid_from_the_configured_url_without_import_map
    set_url('https://example.net/mermaid.esm.mjs')
    html = render_macro
    assert_includes html, 'import mermaid from "https://example.net/mermaid.esm.mjs";'
    assert_not_includes html, "from 'mermaid'"
  end

  def test_blank_setting_falls_back_to_default_url
    set_url('  ')
    assert_includes render_macro, %(import mermaid from "#{@default_url}";)
  end

  def test_url_is_escaped_in_script
    set_url(%q(https://x.net/a"; alert(1); //</script><b>))
    html = render_macro
    assert_not_includes html, '</script><b>'
    assert_includes html, %q(import mermaid from "https://x.net/a\\"; alert(1); //\\u003c/script\\u003e\\u003cb\\u003e";)
  end

  def test_diagram_text_is_escaped
    html = render_macro('<script>alert(1)</script>')
    assert_not_includes html, '<script>alert(1)</script>'
    assert_includes html, '&lt;script&gt;alert(1)&lt;/script&gt;'
  end

  def test_two_macros_get_distinct_ids
    html = textilizable("{{mermaid\nA-->B\n}}\n\n{{mermaid\nC-->D\n}}")
    ids = html.scan(/id="(mermaid_[^"]+)"/).flatten
    assert_equal 2, ids.uniq.size
  end

  def test_layout_hook_loads_stylesheet_only
    html = MermaidMacroHook.instance.view_layouts_base_html_head
    assert_includes html, 'redmine_mermaid_macro'
    assert_not_includes html, 'importmap'
  end

  private

  def assert_select_in(html, selector, equality)
    assert_select Nokogiri::HTML::DocumentFragment.parse(html), selector, equality
  end
end
