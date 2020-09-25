module PageTemplateAdmin
  extend ActiveSupport::Concern

  # TODO form button french text breaks on mobile
  # TODO datetime picker doesn't switch to french
  included do
    rails_admin do
      configure :title, translated: :all do
        searchable false
      end
      configure :description, :text, translated: :all do
        searchable false
      end

      field :view do
        searchable false
        index_value{ primary_key_link(pretty_value) }
      end
      fields :title, :description, translated: :all
      fields :published_at, :updated_at, :updater, :created_at, :creator do
        searchable false
      end

      index do
        exclude_fields :title, :description, translated: true
      end

      edit do
        configure :view do
          enum_method :available_views
        end
        field :publish, :boolean do
          readonly false
        end
        exclude_fields :title, :description, :published_at
      end
    end
  end
end
