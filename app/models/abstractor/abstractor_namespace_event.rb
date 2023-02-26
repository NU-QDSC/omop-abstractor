module Abstractor
  class AbstractorNamespaceEvent < ActiveRecord::Base
    belongs_to :abstractor_namespace
    belongs_to :eventable, polymorphic: true
  end
end