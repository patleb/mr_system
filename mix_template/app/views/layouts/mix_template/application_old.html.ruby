# TODO https://github.com/rails/rails/pull/31251
html_('.no-js', lang: Current.locale) {[
  head_ {[
    unless Rails.env.dev_rack_profiling?
      content_for?(:javascripts) ? yield(:javascripts) : [
        javascript_include_tag(current_layout('vendor'), defer: true),
        javascript_include_tag(current_layout, defer: true),
      ]
    end,
    unless Rails.env.dev_rack_profiling?
      content_for?(:stylesheets) ? yield(:stylesheets) : [
        stylesheet_link_tag(current_layout, media: :all),
      ]
    end,
    area(:meta),
    meta_('http-equiv': 'X-PJAX-VERSION', content: MixTemplate.config.version),
    meta_(charset: 'utf-8'),
    meta_(name: 'viewport', content: 'width=device-width, initial-scale=1, shrink-to-fit=no'),
    # TODO make sure that navigation is self-sufficient
    # meta_(name: 'mobile-web-app-capable', content: 'yes'),
    meta_(name: 'description', content: @page_description),
    link_(rel: 'apple-touch-icon', href: '/apple-touch-icon.png'),
    csrf_meta_tag,
    csp_meta_tag,
    title_{ @page_title },
    browser_upgrade_css
  ]},
  body_(id: module_name) {[
    browser_upgrade_html,
    area(:body_begin),
    div_('.container-fluid') do
      div_('.row') {[
        nav_('.navbar.navbar-default.col-sm-3.col-md-2') do
          div_ '.container-fluid' do
            div_('.navbar-header') {[
              button_('.js_menu_toggle.navbar-toggle.collapsed', type: 'button', data: { toggle: 'collapse', target: '#navigation' }) {[
                span_('.sr-only', t('mix_template.toggle_navigation')),
                span_('.icon-bar', times: 3)
              ]},
              a_('.navbar-brand.pjax', @app_name, href: @root_path),
              div_('#js_page_title', @page_title)
            ]}
          end
        end,
        div_('#navigation.navbar-collapse.collapse', role: 'navigation') do
          div_ '.sidebar-nav.col-sm-3.col-md-2' do
            area(:sidebar)
          end
        end,
        div_('#js_page_window.col-sm-9.col-sm-offset-3.col-md-10.col-md-offset-2') {[
          div_('.js_menu_overlay'),
          div_('#js_pjax_container') do
            yield
          end
        ]}
      ]}
    end,
    area(:body_end)
  ]}
]}