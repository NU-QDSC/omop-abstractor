module Abstractor
  class AbstractorNamespace < ActiveRecord::Base
    has_many :abstractor_namespace_events, dependent: :destroy
    has_many :abstractor_namespace_sections, dependent: :destroy
  end
end