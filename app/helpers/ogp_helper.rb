# frozen_string_literal: true

module OgpHelper
  def ogp_image_url(article)
    ogp_path = "/ogp/#{article.slug}.png"
    if File.exist?(Rails.root.join("public", "ogp", "#{article.slug}.png"))
      "#{request.base_url}#{ogp_path}"
    else
      "#{request.base_url}/icon.png"
    end
  end

  def article_description(article)
    truncate(strip_tags(article.body), length: 160)
  end
end
