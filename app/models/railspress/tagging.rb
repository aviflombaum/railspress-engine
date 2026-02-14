module Railspress
  class Tagging < ApplicationRecord
    belongs_to :tag
    belongs_to :taggable, polymorphic: true

    validates :tag_id, uniqueness: {
      scope: [ :taggable_type, :taggable_id ],
      message: "has already been applied to this item"
    }
  end
end
