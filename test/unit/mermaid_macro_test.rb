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
    assert_includes html, 'import("https://example.net/mermaid.esm.mjs").then('
    assert_not_includes html, "from 'mermaid'"
  end

  def test_blank_setting_falls_back_to_default_url
    set_url('  ')
    assert_includes render_macro, %(import("#{@default_url}"))
  end

  def test_url_is_escaped_in_script
    set_url(%q(https://x.net/a"; alert(1); //</script><b>))
    html = render_macro
    assert_not_includes html, '</script><b>'
    assert_includes html, %q(import("https://x.net/a\\"; alert(1); //\\u003c/script\\u003e\\u003cb\\u003e"))
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

  # mermaid.js that cannot be loaded (CDN blocked) left only the raw text, without a word why
  def test_failed_load_shows_a_message_above_the_source_text
    html = render_macro
    id = html[/id="(mermaid_[^"]+)"/, 1]
    message = "The diagram cannot be shown: mermaid.js could not be loaded from #{@default_url}. " \
              "Below is the diagram's source text."
    assert_includes html, "}, () => {"
    assert_includes html, "message.textContent = #{message.to_json};"
    assert_includes html, "message.className = 'flash warning mermaid-load-error';"
    assert_includes html, "document.getElementById('#{id}').before(message);"
  end

  def test_failed_load_message_is_translated_and_escaped
    set_url(%q(https://x.net/</script><b>))
    html = ::I18n.with_locale(:nl) { render_macro }
    assert_includes html, 'Het diagram kan niet getoond worden: mermaid.js kon niet geladen worden van https://x.net/\u003c/script\u003e\u003cb\u003e.'
    assert_not_includes html, '</script><b>'
  end

  def test_layout_hook_loads_stylesheet_only
    html = MermaidMacroHook.instance.view_layouts_base_html_head
    assert_includes html, 'redmine_mermaid_macro'
    assert_not_includes html, 'importmap'
  end

  def test_settings_label_is_translated_for_en_nl_fr
    {'en' => 'Mermaid URL', 'nl' => 'Mermaid-URL', 'fr' => 'URL de Mermaid'}.each do |lang, label|
      assert_equal label, ::I18n.t(:label_mermaid_url, :locale => lang), lang
    end
  end

  def test_load_failed_message_exists_for_en_nl_fr
    %w[en nl fr].each do |lang|
      text = ::I18n.t(:text_mermaid_load_failed, :url => 'U', :locale => lang, :raise => true)
      assert_includes text, 'mermaid.js', lang
      assert_includes text, 'U', lang
    end
  end

  private

  def assert_select_in(html, selector, equality)
    assert_select Nokogiri::HTML::DocumentFragment.parse(html), selector, equality
  end
end
