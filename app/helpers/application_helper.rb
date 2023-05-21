module ApplicationHelper
  def show_abstractor_group_all_links?
    true
  end

  def show_abstractor_all_links?
    true
  end

  def show_abstractor_headers?
    false
  end

  def show_abstractor_history?
    false
  end

  def show_abstractor_edit_other_values?
    false
  end

  def show_abstractor_group_workflow_status_links?
    true
  end

  def active?(css_class, url_parameters)
    current_page?(url_parameters) ? css_class : ''
  end

  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = column == sort_column ? "current #{sort_direction}" : nil
    direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
    link_to title, params.permit(:abstraction_status, :sort, :direction, :search, :note_date, :abstraction_status, :namespace_id, :note_type, :note_title, :first_name, :last_name, :value, :vocabulary_code, :provider, :provider_speciality => []).merge({ sort: column, direction: direction }), { class: css_class }
  end

  def validation_errors?(object, field_name)
    object.errors.messages[field_name].any?
  end

  def format_validation_errors(object, field_name)
    if object.errors.any?
      if !object.errors.messages[field_name].blank?
        object.errors.messages[field_name].join(", ")
      end
    end
  end

  def checked?(param_value, value, default)
    if param_value.nil? && default
      true
    else
      param_value == value
    end
  end

  def human_boolean(boolean)
    boolean ? 'Yes' : 'No'
  end

  def format_date(date)
    date.present? ? date.to_s(:date) : nil
  end

  def generate_index(page, i)
    ((page.to_i - 1) * 10) + i
  end

  def validation_errors?(object, field_name)
    object.errors.messages[field_name].any?
  end

  def format_validation_errors(object, field_name)
    if object.errors.any?
      if !object.errors.messages[field_name].blank?
        object.errors.messages[field_name].join(", ")
      end
    end
  end
end