# TODO slow map_associated_children
object = delete_notice
wording = @model.with(object: object).object_label

li_('.delete_notice', [
  span_('.label.label-info', @abstract_model.pretty_name),
  if (action = RailsAdmin.action(:show, @abstract_model, object))
    link_to(wording, @abstract_model.url_for(action.name, id: object.id), class: 'pjax')
  else
    wording
  end,
  ul_ do
    @abstract_model.map_associated_children(object) do |association, children|
      count = children.count
      limit = count > 12 ? 10 : count
      h_(
        children.first(limit).map do |child|
          child_model = RailsAdmin.model(child)
          wording = child_model.with(object: child).object_label
          li_({ class: dom_class(child) }, [
            b_(child.model_name.human),
            if child.id && (action = RailsAdmin.action(:show, child_model.abstract_model, child))
              link_to(wording, child_model.abstract_model.url_for(action.name, id: child.id), class: 'pjax')
            else
              wording
            end
          ])
        end,
        if count > limit
          model_name = @abstract_model.klass.human_attribute_name(association.name)
          li_ t('admin.misc.more', count: count - limit, model_name: model_name)
        end
      )
    end
  end
])
