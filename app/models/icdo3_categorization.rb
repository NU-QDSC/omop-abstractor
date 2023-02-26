class Icdo3Categorization < ApplicationRecord
  belongs_to :icdo3_category
  belongs_to :categorizable, polymorphic: true
end