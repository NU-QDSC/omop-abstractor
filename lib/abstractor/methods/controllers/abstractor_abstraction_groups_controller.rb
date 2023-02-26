module Abstractor
  module Methods
    module Controllers
      module AbstractorAbstractionGroupsController
        def self.included(base)
          base.send :helper, :all
          base.send :before_action, :authenticate_user!
          base.send :before_action, :set_abstractor_abstraction_group, only: [:destroy, :update, :update_wokflow_status]
        end

        def create
          @abstractor_abstraction_group = Abstractor::AbstractorAbstractionGroup.create_abstractor_abstraction_group(params[:abstractor_subject_group_id], params[:about_type], params[:about_id], params[:namespace_type], params[:namespace_id])

          unless params[:namespace_type].blank? || params[:namespace_id].blank?
            @namespace_id   = params[:namespace_id]
            @namespace_type = params[:namespace_type]
          end

          respond_to do |format|
            format.html { render action: "edit", layout: false }
          end
        end

        def destroy
          @abstractor_abstraction_group.soft_delete!
          respond_to do |format|
            format.js   { head :no_content }
            format.json { head :no_content }
          end
        end

        def update
          abstractor_abstraction_value = params[:abstractor_abstraction_value]
          Abstractor::AbstractorAbstraction.update_abstractor_abstraction_other_value(@abstractor_abstraction_group.abstractor_abstractions, abstractor_abstraction_value)
          respond_to do |format|
            format.html { render action: "edit", layout: false }
          end
        end

        def update_wokflow_status
          abstraction_workflow_status = params[:abstraction_workflow_status]
          Abstractor::AbstractorAbstraction.update_abstractor_abstraction_workflow_status(@abstractor_abstraction_group.abstractor_abstractions.not_deleted, abstraction_workflow_status, abstractor_user)
          respond_to do |format|
            format.html { render action: "edit", layout: false }
          end
        end

        private
          def set_abstractor_abstraction_group
            @abstractor_abstraction_group = Abstractor::AbstractorAbstractionGroup.find(params[:id])
          end
      end
    end
  end
end