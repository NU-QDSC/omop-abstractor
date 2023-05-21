class Provider < ApplicationRecord
  self.table_name = 'provider'
  self.primary_key = 'provider_id'
  belongs_to :gender, class_name: 'Concept', foreign_key: 'gender_concept_id'

  def self.search(search_token)
    all_providers = []
    search_tokens = search_token.split(' ')
    st = search_tokens.shift
    all_providers = Provider.where('lower(provider_name) like ?', "%#{st.downcase}%")
    search_tokens.each do |st|
      providers = Provider.where('lower(provider_name) like ?', "%#{st.downcase}%")
      all_providers = providers & all_providers
    end

    all_providers
  end
end
