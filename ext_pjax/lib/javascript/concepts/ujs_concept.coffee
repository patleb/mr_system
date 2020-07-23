class Js.UjsConcept
  document_on: -> [
    'click.continue change.continue submit.continue', '[data-confirm]', (event) ->
      confirm = $(document.activeElement).data('confirm') ? $(event.currentTarget).data('confirm')
      unless confirm? && confirm != false && window.confirm(I18n?.t('confirmation') || confirm)
        event.stopImmediatePropagation()
        false

    # Workaround for jquery-ujs formnovalidate issue: https://github.com/rails/jquery-ujs/issues/316
    'click.continue', '[formnovalidate]', ->
      $(this).closest('form').attr(novalidate: true).data(novalidate: true)

    'click', 'a[data-method]', (event) ->
      link = $(event.currentTarget)
      href = link[0].href
      form = $('<form>', method: 'post', action: href)
      inputs = "<input name='_method' value='#{link.data('method')}' type='hidden' />"
      csrf_token = $.csrf_token()
      csrf_param = $.csrf_param()
      if csrf_param? && csrf_token? && !$.is_cross_domain(href)
        inputs += "<input name='#{csrf_param}' value='#{csrf_token}' type='hidden' />"
      target = link.attr('target')
      form.attr(target: target) if target
      form.hide().append(inputs).appendTo('body')
      form.submit()
      false
  ]

  ready_once: ->
    $.error('cannot be used with rails-ujs!') if window.Rails?
    window.Rails = {}

    $.error('cannot be used with jquery-ujs!') if $.rails?
    $.rails = {}

  ready: ->
    $("form input[name='#{$.csrf_param()}']").val($.csrf_token())