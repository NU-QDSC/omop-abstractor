module Abstractor
  class AbstractorRule < ActiveRecord::Base
    include Abstractor::Methods::Models::AbstractorRule
    # @!parse extend Moo::ClassMethods
  end
end