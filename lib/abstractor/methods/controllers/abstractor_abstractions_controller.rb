module Abstractor
  module Methods
    module Controllers
      module AbstractorAbstractionsController
        def self.included(base)
          base.send :before_action, :authenticate_user!
          base.send :before_action, :set_abstractor_abstraction, :only => [:show, :edit, :update, :clear]
        end

        def index
        end

        def show
          respond_to do |format|
            format.html { render :layout => false }
          end
        end

        def edit
          respond_to do |format|
            format.html { render :layout => false }
          end
        end

        def update
          respond_to do |format|
            begin
              abstractor_suggestion = nil
              if !abstractor_abstraction_params[:value].blank? || !abstractor_abstraction_params[:unknown].blank? || !abstractor_abstraction_params[:not_applicable].blank?
                Abstractor::AbstractorAbstraction.transaction do
                  @abstractor_abstraction.abstractor_suggestions.each do |abstractor_suggestion|
                    if abstractor_suggestion.abstractor_suggestion_sources.not_deleted.empty?
                      abstractor_suggestion.destroy
                    end
                  end
                  #Updating the values of an abstraction are handled by the insertion/updating of suggestions.  See the following line.
                  #But we stil need to support updating of other attributes.  Like abstractor_indirect_sources.
                  @abstractor_abstraction.update_attributes(abstractor_abstraction_params.except(:value, :unknown, :not_applicable))
                  abstractor_suggestion = @abstractor_abstraction.abstractor_subject.suggest(@abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, abstractor_abstraction_params[:value], abstractor_abstraction_params[:unknown].to_s.to_boolean, abstractor_abstraction_params[:not_applicable].to_s.to_boolean, nil, nil)
                  abstractor_suggestion.accepted = true
                  abstractor_suggestion.save!
                end
              end

              if abstractor_suggestion
                format.html { render "abstractor_abstractions/show", layout: false }
              else
                @abstractor_abstraction.clear
                @abstractor_abstraction.errors.add(:value, Abstractor::Enum::ABSTRACTOR_ABSTRACTION_VALIDATION_ERROR)
                raise "Error processing request to create abstractor suggestion"
              end
            rescue => e
              error = e
              Rails.logger.info(e.class)
              Rails.logger.info(e.message)
              Rails.logger.info(e.backtrace.join("\n"))
              format.html { render "abstractor_abstractions/edit", layout: false, status: :unprocessable_entity }
            end
          end
        end

        def clear
          respond_to do |format|
            @abstractor_abstraction.clear!
            format.html { render "abstractor_abstractions/show", layout: false }
          end
        end

        def update_all
          abstractor_abstraction_value = params[:abstractor_abstraction_value]
          case abstractor_abstraction_value
          when Abstractor::Enum::ABSTRACTION_OTHER_VALUE_TYPE_UNKNOWN
            unknown = true
            not_applicable = nil
          when Abstractor::Enum::ABSTRACTION_OTHER_VALUE_TYPE_NOT_APPLICABLE
            unknown = nil
            not_applicable = true
          end

          @about = params[:about_type].constantize.find(params[:about_id])
          abstractor_abstractions = @about.abstractor_abstractions
          Abstractor::AbstractorAbstraction.transaction do
            abstractor_abstractions.each do |abstractor_abstraction|
              abstractor_abstraction.abstractor_suggestions.each do |abstractor_suggestion|
                if abstractor_suggestion.abstractor_suggestion_sources.not_deleted.empty?
                  abstractor_suggestion.destroy!
                end
              end

              abstractor_suggestion = abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, nil, unknown, not_applicable, nil, nil)
              abstractor_suggestion.accepted = true
              abstractor_suggestion.save!
            end
          end

          respond_to do |format|
            format.html { redirect_back(fallback_location: root_path) }
          end
        end

        def discard
          @about = params[:about_type].constantize.find(params[:about_id])
          Abstractor::AbstractorAbstraction.update_abstractor_abstraction_workflow_status(@about.abstractor_abstractions.not_deleted, Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_DISCARDED, abstractor_user)

          respond_to do |format|
            format.html { redirect_to discard_redirect_to(params, @about) }
          end
        end

        def undiscard
          @about = params[:about_type].constantize.find(params[:about_id])
          Abstractor::AbstractorAbstraction.update_abstractor_abstraction_workflow_status(@about.abstractor_abstractions.not_deleted, Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_PENDING, nil)

          respond_to do |format|
            format.html { redirect_to undiscard_redirect_to(params, @about) }
          end
        end

        def update_wokflow_status
          @about = params[:about_type].constantize.find(params[:about_id])
          abstraction_workflow_status = params[:abstraction_workflow_status]
          respond_to do |format|
            if abstraction_workflow_status == Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_SUBMITTED && !@about.fully_set?
              flash[:abstractor_errors] = []
              flash[:abstractor_errors] << 'Validation Error: please set a value for all data points before submission.'
              format.html { redirect_back(falback_location: root_path) }
            else
              Abstractor::AbstractorAbstraction.update_abstractor_abstraction_workflow_status(@about.abstractor_abstractions.not_deleted, abstraction_workflow_status, abstractor_user)
              format.html { redirect_to update_workflow_status_redirect_to(params, @about) }
            end
          end
        end

        private
          def set_abstractor_abstraction
            @abstractor_abstraction = Abstractor::AbstractorAbstraction.find(params[:id])
            @about = @abstractor_abstraction.about
          end

          def abstractor_abstraction_params
            params.require(:abstractor_abstractor_abstraction).permit(:id, :abstractor_subject_id, :value, :about_type, :about_id, :unknown, :not_applicable, :deleted_at, :_destroy,
            abstractor_indirect_sources_attributes: [:id, :abstractor_abstraction_id, :abstractor_abstraction_source_id, :source_type, :source_id, :source_method, :deleted_at, :_destroy]
            )
          end
      end
    end
  end
end