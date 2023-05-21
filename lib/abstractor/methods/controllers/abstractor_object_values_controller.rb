module Abstractor
  module Methods
    module Controllers
      module AbstractorObjectValuesController
        def self.included(base)
          base.send :helper, :all
          base.send :helper_method, :sort_column
          base.send :helper_method, :sort_direction
          base.send :before_action, :authenticate_user!
          base.send :before_action, :set_abstractor_abstraction_schema
          base.send :before_action, :set_abstractor_object_value, except: [:index, :new, :create]
        end

        def index
          options = {}
          options[:sort_column] = sort_column
          options[:sort_direction] = sort_direction
          @abstractor_object_values = @abstractor_abstraction_schema.abstractor_object_values.not_deleted.search_across_fields(params[:search], options).paginate(per_page: 10, page: params[:page])
        end

        def new
          @path = Abstractor::UserInterface.abstractor_relative_path(abstractor_abstraction_schema_abstractor_object_values_path(@abstractor_abstraction_schema))
          @abstractor_object_value = Abstractor::AbstractorObjectValue.new
          @abstractor_object_value.abstractor_object_value_variants.build
        end

        def create
          @path = Abstractor::UserInterface.abstractor_relative_path(abstractor_abstraction_schema_abstractor_object_values_path(@abstractor_abstraction_schema))
          @abstractor_object_value = Abstractor::AbstractorObjectValue.new(abstractor_object_value_params)
          @abstractor_object_value.abstractor_abstraction_schemas << @abstractor_abstraction_schema
          if @abstractor_object_value.save
            redirect_to action: :index
          else
            render :new
          end
        end

        def edit
          @path = Abstractor::UserInterface.abstractor_relative_path(abstractor_abstraction_schema_abstractor_object_value_path(@abstractor_abstraction_schema, @abstractor_object_value))
        end

        def update
          @path = Abstractor::UserInterface.abstractor_relative_path(abstractor_abstraction_schema_abstractor_object_value_path(@abstractor_abstraction_schema, @abstractor_object_value))
          params[:abstractor_abstractor_object_value][:abstractor_object_value_variants_attributes].each do |key, values|
            values[:soft_delete] = values[:_destroy] if values[:id].present?
          end
          if @abstractor_object_value.update_attributes(abstractor_object_value_params)
            redirect_to action: :index
          else
            render :edit
          end
        end

        def destroy
          @abstractor_object_value.soft_delete!
          redirect_to action: :index
        end

        private
          def set_abstractor_abstraction_schema
            @abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.find(params[:abstractor_abstraction_schema_id])
          end

          def set_abstractor_object_value
            @abstractor_object_value = Abstractor::AbstractorObjectValue.find(params[:id])
          end

          def abstractor_object_value_params
            params.require(:abstractor_abstractor_object_value).permit(
              :id,
              :value,
              :vocabulary,
              :vocabulary_version,
              :vocabulary_code,
              :comments,
              :case_sensitive,
              abstractor_object_value_variants_attributes: [
                :id, :value, :case_sensitive, :_destroy
              ]
            )

          end

          def sort_column
            ['value', 'vocabulary_code'].include?(params[:sort]) ? params[:sort] : 'value'
          end

          def sort_direction
            %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
          end
      end
    end
  end
end