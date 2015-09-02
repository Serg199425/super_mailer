module ApplicationHelper
  def errors_full_messages(record)
    return "" if !record || record.errors.full_messages.blank?
    content_tag(:div, class: "alert alert-danger centered") do
      record.errors.full_messages.collect do |message|
        content_tag(:p, message)
      end.join.html_safe
    end
  end
end
