module Abstractor
  module Methods
    module Controllers
      module AbstractorObjectValueVariantsController
        def self.included(base)
          base.send :helper, :all
          base.send :before_action, :authenticate_user!
        end

        def new
          @abstractor_object_value_variant = Abstractor::AbstractorObjectValueVariant.new()
          params[:index] = DateTime.now.to_i

          respond_to do |format|
            format.html { render layout: false }
            format.js
          end
        end
      end
    end
  end
end