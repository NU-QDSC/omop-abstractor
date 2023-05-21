module Abstractor
  module Methods
    module Controllers
      module AbstractorSuggestionsController
        def self.included(base)
          base.send :before_action, :authenticate_user!
          base.send :before_action, :set_abstractor_suggestion, :only => [:update]
          base.send :before_action, :set_abstractor_abstraction
        end

        def create
          respond_to do |format|
            begin
              suggestion = params[:abstractor_abstractor_suggestion]
              abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.find(suggestion[:abstractor_abstraction_source_id])
              abstractor_suggestion = nil
              Abstractor::AbstractorSuggestion.transaction do
                suggestion[:suggestion_sources].each do |suggestion_source|
                  abstractor_suggestion = @abstractor_abstraction.abstractor_subject.suggest(@abstractor_abstraction, abstractor_abstraction_source, suggestion_source[:match_value], suggestion_source[:sentence_match_value], suggestion[:source_id], suggestion[:source_type], suggestion[:source_method], suggestion_source[:section_name], suggestion[:value], suggestion[:unknown].to_s.to_boolean, suggestion[:not_applicable].to_s.to_boolean, nil, nil, suggestion[:negated].to_s.to_boolean)
                end
              end
              format.json { render json: abstractor_suggestion, status: :created }
            rescue => e
              format.json { render json: "Error processing request to create abstractor suggestions: #{e}", status: :unprocessable_entity }
            end
          end
        end

        def update
          respond_to do |format|
            if @abstractor_suggestion.update_attributes(abstractor_suggestion_params)
              format.html { render "abstractor_abstractions/show", layout: false }
            else
              format.html { render "abstractor_abstractions/show" }
            end
          end
        end

        private
          def set_abstractor_abstraction
            @abstractor_abstraction = Abstractor::AbstractorAbstraction.find(params[:abstractor_abstraction_id])
            @about = @abstractor_abstraction.about
          end

          def set_abstractor_suggestion
            @abstractor_suggestion = Abstractor::AbstractorSuggestion.find(params[:id])
          end

          def abstractor_suggestion_params
            params.require(:abstractor_abstractor_suggestion).permit(:id, :abstractor_abstraction_id, :accepted, :suggested_value, :unknown, :not_applicable, :deleted_at, :_destroy)
          end
      end
    end
  end
end