module Abstractor
  class AbstractorNamespaceSection < ActiveRecord::Base
    include Abstractor::Methods::Models::SoftDelete
    belongs_to :abstractor_namespace
    belongs_to :abstractor_section
  end
end