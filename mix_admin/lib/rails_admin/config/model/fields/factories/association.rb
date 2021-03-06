RailsAdmin::Config::Model::Fields.register_factory do |section, property, fields|
  association = section.abstract_model.associations.find do |a|
    [a.foreign_key, a.name].include?(property.name) && [:belongs_to, :has_and_belongs_to_many].include?(a.type)
  end
  if association
    type = case
      when association.polymorphic? then :polymorphic
      when association.list_parent? then :list_parent
      else association.type
      end
    type = "#{type}_association"
    field = RailsAdmin::Config::Model::Fields.load(type).new(section, association.name, association)
    fields << field

    child_columns = []
    possible_field_names = begin
      if association.polymorphic?
        [:foreign_key, :foreign_type]
      else
        [:foreign_key]
      end.map{ |k| association.send(k) }.compact
    end

    section.abstract_model.columns.select{ |c| possible_field_names.include? c.name }.each do |column|
      unless (child_field = fields.find{ |f| f.name.to_s == column.name.to_s })
        child_field = RailsAdmin::Config::Model::Fields.default_factory.call(section, column, fields)
      end
      child_columns << child_field
    end

    child_columns.each do |child_column|
      child_column.hide
      child_column.filterable(false)
    end

    if [:creator_id, :updater_id, :creator, :updater].include?(property.name)
      field.readonly true
    end

    field.children_fields child_columns.map(&:name)
    true
  else
    false
  end
end
