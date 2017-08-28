class Bookmark < ApplicationRecord
  belongs_to :user
  belongs_to :event, polymorphic: true
end