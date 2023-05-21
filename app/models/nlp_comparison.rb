class NlpComparison < ActiveRecord::Base
  has_many :nlp_comparison_suggestions, dependent: :destroy
end