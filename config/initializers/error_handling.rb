ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
  class_attr_index = html_tag.index 'class="'
  if class_attr_index
    html_tag.insert class_attr_index+7, 'invalid '
  else
    html_tag.insert html_tag.index('>'), ' class="invalid"'
  end
end