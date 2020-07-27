# Configuration of the show view for a new object
class RailsAdmin::Config::Model::Sections::Base
  include RailsAdmin::Config::Proxyable
  include RailsAdmin::Config::Configurable

  attr_reader :abstract_model
  attr_reader :model

  delegate :klass, to: :abstract_model

  def initialize(model)
    @model = model
    @abstract_model = model.abstract_model
  end

  # Provides accessor and autoregistering of model's description.
  def description(description = nil)
    # TODO put timezone here if configured
    @description ||= description
  end

  # Accessor for a group
  #
  # If group with given name does not yet exist it will be created. If a
  # block is passed it will be evaluated in the context of the group
  def group(name, &block)
    group = model.groups.find{ |g| name == g.name }
    group ||= (model.groups << RailsAdmin::Config::Model::Fields::Group.new(self, name)).last
    group.tap{ |g| g.section = self }.instance_eval(&block) if block
    group
  end

  # Reader for groups that are marked as visible
  def visible_groups
    model.groups.map{ |g| g.section = self; g.with(bindings) }.select(&:visible?).select do |g| # rubocop:disable Semicolon
      g.visible_fields.present?
    end
  end

  # Defines a configuration for a field.
  def field(name, type = nil, add_to_section = true, &block)
    field = _fields.find{ |f| name == f.name }

    # some fields are hidden by default (belongs_to keys, has_many associations in list views.)
    # unhide them if config specifically defines them
    if field
      field.show unless field.instance_variable_get("@#{field.name}_registered").is_a?(Proc)
    end
    # Specify field as virtual if type is not specifically set and field was not
    # found in default stack
    if field.nil? && type.nil?
      field = (_fields << RailsAdmin::Config::Model::Fields.load(:string).new(self, name, nil)).last

      # Register a custom field type if one is provided and it is different from
      # one found in default stack
    elsif type && type != (field.nil? ? nil : field.type)
      if field
        property = field.property
        field = _fields[_fields.index(field)] = RailsAdmin::Config::Model::Fields.load(type).new(self, name, property)
      else
        property = abstract_model.columns.find{ |c| name == c.name }
        property ||= abstract_model.associations.find{ |a| name == a.name }
        field = (_fields << RailsAdmin::Config::Model::Fields.load(type).new(self, name, property)).last
      end
    end

    # If field has not been yet defined add some default properties
    if add_to_section && !field.defined
      field.defined = true
      field.weight = _fields.count(&:defined)
    end

    # If a block has been given evaluate it and sort fields after that
    field.instance_eval(&block) if block
    field
  end

  # configure a field without adding it.
  def configure(name, type = nil, &block)
    field(name, type, false, &block)
  end

  # include fields by name and apply an optionnal block to each (through a call to fields),
  # or include fields by conditions if no field names
  def include_fields(*field_names, &block)
    if field_names.empty?
      _fields.select { |f| f.instance_eval(&block) }.each do |f|
        next if f.defined
        f.defined = true
        f.weight = _fields.count(&:defined)
      end
    else
      fields(*field_names, &block)
    end
  end

  # exclude fields by name or by condition (block)
  def exclude_fields(*field_names, &block)
    block ||= proc { |f| field_names.include?(f.name) }
    _fields.each { |f| f.defined = true } if _fields.select(&:defined).empty?
    _fields.select { |f| f.instance_eval(&block) }.each { |f| f.defined = false }
  end

  # API candy
  alias_method :exclude_fields_if, :exclude_fields
  alias_method :include_fields_if, :include_fields

  def include_all_fields
    include_fields_if { true }
  end

  # Returns all field configurations for the model configuration instance. If no fields
  # have been defined returns all fields. Defined fields are sorted to match their
  # order property. If order was not specified it will match the order in which fields
  # were defined.
  #
  # If a block is passed it will be evaluated in the context of each field
  def fields(*field_names, &block)
    return all_fields if field_names.empty? && !block

    if field_names.empty?
      defined = _fields.select(&:defined)
      defined = _fields if defined.empty?
    else
      defined = field_names.map{ |field_name| _fields.find{ |f| f.name == field_name } }
    end
    defined.map do |f|
      unless f.defined
        f.defined = true
        f.weight = _fields.count(&:defined)
      end
      f.instance_eval(&block) if block
      f
    end
  end

  # Defines configuration for fields by their type.
  def fields_of_type(type, &block)
    _fields.select { |f| type == f.type }.map! { |f| f.instance_eval(&block) } if block
  end

  # TODO rescue 'defined' in development and show undefined field name
  # Accessor for all fields
  def all_fields
    ((ro_fields = _fields(true)).select(&:defined).presence || ro_fields).map do |f|
      f.section = self
      f
    end
  end

  # Get all fields defined as visible, in the correct order.
  def visible_fields
    all_fields.map{ |f| f.with(bindings) }.select(&:visible?).stable_sort_by(&:weight)
  end

  protected

  # Raw fields.
  # Recursively returns model section's raw fields
  # Duping it if accessed for modification.
  def _fields(readonly = false)
    return @_fields if @_fields
    return @_ro_fields if readonly && @_ro_fields

    if self.class == RailsAdmin::Config::Model::Sections::Base
      @_ro_fields = @_fields = RailsAdmin::Config::Model::Fields.factory(self)
    else
      # model is RailsAdmin::Config::Model, recursion is on Section's classes
      @_ro_fields ||= begin
        section = self.class.superclass.to_s.demodulize.underscore
        model.send(section)._fields(true).clone.freeze
      end
    end
    readonly ? @_ro_fields : (@_fields ||= @_ro_fields.map(&:clone))
  end
end