# Model specific configuration object.
class RailsAdmin::Config::Model
  require_relative 'model/fields'
  require_relative 'model/sections'

  include RailsAdmin::Config::Configurable
  include RailsAdmin::Config::Hideable

  attr_reader :i18n_key, :model_name, :abstract_model
  attr_accessor :groups

  delegate :klass, to: :abstract_model, allow_nil: true

  def initialize(model_name)
    @i18n_key = model_name.underscore
    @model_name = model_name
    @abstract_model = RailsAdmin::AbstractModel.all[model_name]
    @groups = [Fields::Group.new(base, :default).tap{ |g| g.label{ I18n.translate('admin.form.basic_info') } }]
  end

  def i18n_scope
    :adminrecord
  end

  def object_label
    field = visible_fields.find{ |f| f.name == object_label_method }
    label = (field.with(object: object).pretty_value if field) \
      || object.send(object_label_method).presence \
      || (object.try("#{object_label_method}_was").presence if object.try("#{object_label_method}_changed?")) \
      || object.send(:rails_admin_object_label)
    label = "#{label} [#{I18n.t('admin.misc.discarded')}]" if object&.discarded?
    label
  end

  def pluralize(count)
    count == 1 ? label : label_plural
  end

  def weight
    "#{(navigation_weight + 32768).to_s}#{label.downcase}"
  end

  register_instance_option :visible? do
    !abstract_model.nil?
  end

  register_instance_option :discardable?, memoize: true do
    klass.discardable?
  end

  register_instance_option :listable?, memoize: true do
    klass.listable?
  end

  # TODO show time zone in list view if specified
  # https://github.com/onomojo/i18n-timezones
  register_instance_option :time_zone, memoize: true do
    nil
  end

  # The display for a model instance (i.e. a single database record).
  # Unless configured in a model config block, it'll try to use :name followed by :title methods, then
  # any methods that may have been added to the label_methods array via Configuration.
  # Failing all of these, it'll return the class name followed by the model's id.
  register_instance_option :object_label_method, memoize: true do
    RailsAdmin.config.label_methods.find{ |method| klass.method_defined? method } || :rails_admin_object_label
  end

  register_instance_option :label, memoize: :locale do
    abstract_model.pretty_name
  end

  register_instance_option :label_plural, memoize: :locale do
    if label != (label_plural = abstract_model.pretty_name(count: Float::INFINITY, default: label))
      label_plural
    else
      label.pluralize(Current.locale)
    end
  end

  register_instance_option :navigation_weight, memoize: true do
    0
  end

  register_instance_option :navigation_parent, memoize: true do
    parent_class = klass.superclass
    if parent_class.respond_to? :extended_record_base_class
      parent_class.extended_record_base_class.to_s
    elsif parent_class.abstract_class?
      nil
    else
      parent_class.to_s
    end
  end

  register_instance_option :navigation_label, memoize: :locale do
    if navigation_label_i18n_key
      I18n.t(navigation_label_i18n_key, scope: [i18n_scope, :navigation_labels], default:
        I18n.t('adminrecord.navigation_labels.object')
      )
    else
      I18n.t(i18n_key, scope: [i18n_scope, :navigation_labels], default:
        I18n.t((parent_module = klass.module_parent.name.underscore), scope: [i18n_scope, :navigation_labels], default:
          parent_module.humanize
        )
      )
    end.upcase
  end

  register_instance_option :navigation_label_i18n_key, memoize: true do
    nil
  end

  register_instance_option :navigation_icon, memoize: true do
    nil
  end

  register_instance_option :save_label?, memoize: :locale do
    I18n.t("#{i18n_key}.save", scope: [i18n_scope, :forms], default: I18n.t("admin.form.save"))
  end

  register_instance_option :save_and_add_another_label?, memoize: :locale do
    I18n.t("#{i18n_key}.save_and_add_another", scope: [i18n_scope, :forms], default: I18n.t("admin.form.save_and_add_another"))
  end

  register_instance_option :save_and_edit_label?, memoize: :locale do
    I18n.t("#{i18n_key}.save_and_edit", scope: [i18n_scope, :forms], default: I18n.t("admin.form.save_and_edit"))
  end

  register_instance_option :cancel_label?, memoize: :locale do
    I18n.t("#{i18n_key}.cancel", scope: [i18n_scope, :forms], default: I18n.t("admin.form.cancel"))
  end

  # Act as a proxy for the base section configuration that actually
  # store the configurations.
  def method_missing(...)
    base.with(bindings).__send__(...)
  end

  def respond_to_missing?(name, _include_private = false)
    base.with(bindings).respond_to?(name, true)
  end
end
