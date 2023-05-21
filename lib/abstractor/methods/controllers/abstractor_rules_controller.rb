module Abstractor
  module Methods
    module Controllers
      module AbstractorRulesController
        def self.included(base)
          base.send :helper, :all
          base.send :before_action, :authenticate_user!
          base.send :before_action, :set_abstractor_abstraction_schema, only: :show
        end

        def index
          abstractor_subject_ids = params[:abstractor_subject_ids].map(&:to_i)
          abstractor_rules = Abstractor::AbstractorRule.search_by_abstractor_subjects_ids(abstractor_subject_ids).order('id ASC')
          respond_to do |format|
            format.json { render json: Abstractor::Serializers::AbstractorRulesSerializer.new(abstractor_rules).as_json }
          end
        end
      end
    end
  end
end