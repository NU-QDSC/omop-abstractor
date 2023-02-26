class NotesController < ApplicationController
  before_action :authenticate_user!
  before_action :load_note, only: [:edit]
  helper_method :sort_column, :sort_direction

  def index
    if params[:provider_speciality].present?
      @provider_specialties = Concept.provider_specialties.where(concept_id: params[:provider_speciality])
    else
      @provider_specialties = []
    end

    if params[:secondary_provider_speciality].present?
      @secondary_provider_specialties = Concept.provider_specialties.where(concept_id: params[:secondary_provider_speciality])
    else
      @secondary_provider_specialties = []
    end

    if params[:provider].present?
      @providers = Provider.where(provider_name: params[:provider])
    else
      @providers = []
    end

    if params[:secondary_provider].present?
      @secondary_providers = Provider.where(provider_name: params[:secondary_provider])
    else
      @secondary_providers = []
    end

    session[:index_history] = request.url unless params[:next_note]
    params[:page]||= 1
    options = {}
    options[:sort_column] = sort_column
    options[:sort_direction] = sort_direction
    @abstractor_namespaces = Abstractor::AbstractorNamespace.where(subject_type: NoteStableIdentifier.to_s).order('name ASC')
    @namespace_type = Abstractor::AbstractorNamespace.to_s
    @namespace_id = params[:namespace_id].blank? ? 0 : params[:namespace_id]
    @abstractor_abstraction_status = params[:abstraction_status] || Abstractor::Enum::ABSTRACTION_STATUS_NEEDS_REVIEW
    @abstractor_site_status = params[:abstraction_site_status] || 'all'
    @abstractor_histology_status = params[:abstraction_histology_status] || 'all'
    @abstractor_site = params[:abstraction_site] || []
    @abstractor_histology = params[:abstraction_histology] || []

    abstractor_abstraction_schema_id_has_cancer_site = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_cancer_site' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", @namespace_type, @namespace_id).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
    @sites = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema => { :abstractor_abstraction_schema_object_values => :abstractor_object_value }).where("abstractor_abstraction_schemas.predicate = 'has_cancer_site'").select('DISTINCT abstractor_object_values.value').order(:value)

    abstractor_abstraction_schema_id_has_cancer_histology = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_cancer_histology' AND abstractor_subjects.namespace_type = ? AND abstractor_subjects.namespace_id = ?", @namespace_type, @namespace_id).select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
    @histologies = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema => { :abstractor_abstraction_schema_object_values => :abstractor_object_value }).where("abstractor_abstraction_schemas.predicate = 'has_cancer_histology'").select('DISTINCT abstractor_object_values.value').order(:value).to_a

    abstractor_abstraction_schema_id_has_metastatic_cancer_histology = Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema).where("abstractor_abstraction_schemas.predicate = 'has_metastatic_cancer_histology'").select('DISTINCT abstractor_subjects.abstractor_abstraction_schema_id').map(&:abstractor_abstraction_schema_id).first
    @histologies.concat(Abstractor::AbstractorSubject.joins(:abstractor_abstraction_schema => { :abstractor_abstraction_schema_object_values => :abstractor_object_value }).where("abstractor_abstraction_schemas.predicate = 'has_metastatic_cancer_histology'").select('DISTINCT abstractor_object_values.value').order(:value).to_a)

    @note_stable_identifiers = SqlAudit.find_and_audit(
      current_user.username,
      NoteStableIdentifier.search_across_fields(params[:search], params[:provider], params[:secondary_provider], params[:provider_speciality], params[:secondary_provider_speciality], options).by_abstractor_abstraction_status(@abstractor_abstraction_status, namespace_type: @namespace_type, namespace_id: @namespace_id).by_note_date(params[:date_from], params[:date_to]).having_site(namespace_type: @namespace_type, namespace_id: @namespace_id, abstractor_site_status: @abstractor_site_status, abstractor_site: @abstractor_site).having_histology(namespace_type: @namespace_type, namespace_id: @namespace_id, abstractor_histology_status: @abstractor_histology_status, abstractor_histology: @abstractor_histology)
    )

    if params[:next_note]
      index = params[:index].to_i
      notes = @note_stable_identifiers.map(&:note_id)
      record_history
      if notes.any?
        if notes.size > (index + 1)
          if notes[index] == params[:previous_note_id].to_i
            index = index + 1
          end
          next_case = notes[index]
        else
          index = 0
          next_case = notes[0]
        end

        redirect_to edit_note_url(next_case, index: index, namespace_type: @namespace_type, namespace_id: @namespace_id) and return
      else
        redirect_to notes_path and return
      end
    end

    respond_to do |format|
      format.html { @note_stable_identifiers = NoteStableIdentifier.search_across_fields(params[:search], params[:provider], params[:secondary_provider], params[:provider_speciality], params[:secondary_provider_speciality], options).by_abstractor_abstraction_status(@abstractor_abstraction_status, namespace_type: @namespace_type, namespace_id: @namespace_id).by_note_date(params[:date_from], params[:date_to]).having_site(namespace_type: @namespace_type, namespace_id: @namespace_id, abstractor_site_status: @abstractor_site_status, abstractor_site: @abstractor_site).having_histology(namespace_type: @namespace_type, namespace_id: @namespace_id, abstractor_histology_status: @abstractor_histology_status, abstractor_histology: @abstractor_histology).paginate(per_page: 10, page: params[:page]); record_history }
    end
  end

  def edit
    @namespace_type = Abstractor::AbstractorNamespace.to_s
    @namespace_id = params[:namespace_id].blank? ? 0 : params[:namespace_id]

    unless params[:previous_case]
      session[:previous_note] ||= []
      if session[:current_note]
        session[:previous_note] << session[:current_note]
      end
      session[:current_note] = params[:id]
    end

    respond_to do |format|
      format.html
    end
  end

  def next_note
    @namespace_type = Abstractor::AbstractorNamespace.to_s
    @namespace_id = params[:namespace_id].blank? ? 0 : params[:namespace_id]

    if session[:history]
      session[:history].gsub!("&next_case=true","")
      session[:history].gsub!(/&index=(\d*)/,"")
      session[:history].gsub!(/&previous_note_id=(\d*)/,"")
      session[:history].gsub!(/notes\?(\d*)/,"/notes\?")
      session[:history] = session[:history] + (session[:history].include?('?') ? "&next_note=true&index=#{params[:index]}&previous_note_id=#{params[:previous_note_id]}" : "?&next_case=true&index=#{params[:index]}&previous_pathology_case_id=#{params[:previous_note_id]}&namespace_type=#{@namespace_type}&namespace_id=#{@namespace_id}")
      redirect_to session[:history] and return
    else
      redirect_to notes_url and return
    end
  end

  def previous_note
    @namespace_type = Abstractor::AbstractorNamespace.to_s
    @namespace_id = params[:namespace_id].blank? ? 0 : params[:namespace_id]
    if session[:previous_note].any?
      redirect_to edit_note_url(session[:previous_note].pop, previous_note: true, namespace_type: @namespace_type, namespace_id: @namespace_id) and return
    else
      redirect_to notes_url and return
    end
  end

  private
    def load_note
      @note = SqlAudit.find_and_audit(current_user.username, Note.where(note_id: params[:id])).first
      @person = SqlAudit.find_and_audit(current_user.username, Person.where(person_id: @note.person_id)).first
      @mrns = SqlAudit.find_and_audit(current_user.username, @person.mrns)
      @provider = SqlAudit.find_and_audit(current_user.username, Provider.where(provider_id: @note.provider_id)).first
    end

    def sort_column
      ['note_date', 'note_type', 'note_title', 'first_name', 'last_name'].include?(params[:sort]) ? params[:sort] : 'note_date'
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
    end
end