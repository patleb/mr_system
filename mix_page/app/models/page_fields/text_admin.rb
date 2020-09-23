module PageFields::TextAdmin
  extend ActiveSupport::Concern

  included do
    rails_admin do
      field :text, translated: :all
    end

    rails_admin :superclass, after: true do
      index do
        exclude_fields :text, translated: :all
      end

      edit do
        exclude_fields :text
      end
    end
  end
end