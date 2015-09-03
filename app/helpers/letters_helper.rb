module LettersHelper
  def is_active?(page_name)
    "menu-active" if params[:action] == page_name
  end

  def html_filter(html)
    html = Nokogiri.HTML(html)
    html.css('style').remove if html.css('style').present?
    html.css('body').first.attributes.each { |key, attribute| attribute.remove } if html.css('body').present?
    html.to_s.html_safe
  end
end
