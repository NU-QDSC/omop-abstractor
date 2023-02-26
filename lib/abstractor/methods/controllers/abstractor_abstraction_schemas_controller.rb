module Abstractor
  module Methods
    module Controllers
      module AbstractorAbstractionSchemasController
        def self.included(base)
          base.send :helper, :all
          base.send :helper_method, :sort_column
          base.send :helper_method, :sort_direction
          # base.send :before_action, :authenticate_user!
          base.send :before_action, :set_abstractor_abstraction_schema, only: :show
        end

        def index
          options = {}
          options[:sort_column] = sort_column
          options[:sort_direction] = sort_direction
          @abstractor_abstraction_schemas = Abstractor::AbstractorAbstractionSchema.not_deleted.not_deleted.search_across_fields(params[:search], options).paginate(per_page: 10, page: params[:page])
        end

        def show
          respond_to do |format|
            format.json { render json: Abstractor::Serializers::AbstractorAbstractionSchemaSerializer.new(@abstractor_abstraction_schema).as_json }
          end
        end

        private
          def set_abstractor_abstraction_schema
            @abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.find(params[:id])
          end

          def sort_column
            ['display_name', 'predicate'].include?(params[:sort]) ? params[:sort] : 'display_name'
          end

          def sort_direction
            %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
          end
      end
    end
  end
end