module Railspress
  module Taggable
    extend ActiveSupport::Concern

    included do
      has_many :taggings,
               as: :taggable,
               class_name: "Railspress::Tagging",
               dependent: :destroy
      has_many :tags,
               through: :taggings,
               class_name: "Railspress::Tag"
    end

    def tag_list
      tags.pluck(:name).join(", ")
    end

    def tag_list=(csv_string)
      self.tags = Railspress::Tag.from_csv(csv_string)
    end
  end
end
