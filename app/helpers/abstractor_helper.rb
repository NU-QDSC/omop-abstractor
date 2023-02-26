module AbstractorHelper
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

  def format_text(text, html_options = {}, options = {})
    wrapper_tag = options.fetch(:wrapper_tag, :p)

    text = sanitize(text) if options.fetch(:sanitize, true)
    formatted_text = text.to_str.gsub(/\r\n?/, "\n").gsub(/\n/, '\1<br />')
    content_tag(wrapper_tag, raw(formatted_text), html_options)
  end
end
