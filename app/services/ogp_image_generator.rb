# frozen_string_literal: true

class OgpImageGenerator
  OGP_WIDTH = 1200
  OGP_HEIGHT = 630
  OUTPUT_DIR = Rails.root.join("public", "ogp")

  def initialize(article)
    @article = article
  end

  def generate
    ensure_output_directory
    html = render_template
    png_data = generate_image(html)
    save_image(png_data)
    output_path
  end

  def output_path
    OUTPUT_DIR.join("#{@article.slug}.png")
  end

  def public_path
    "/ogp/#{@article.slug}.png"
  end

  def exists?
    File.exist?(output_path)
  end

  private

  def ensure_output_directory
    FileUtils.mkdir_p(OUTPUT_DIR)
  end

  def render_template
    ApplicationController.renderer.render(
      template: "ogp/article",
      layout: false,
      assigns: { article: @article }
    )
  end

  def generate_image(html)
    grover = Grover.new(
      html,
      viewport: { width: OGP_WIDTH, height: OGP_HEIGHT },
      full_page: false
    )
    grover.to_png
  end

  def save_image(png_data)
    File.binwrite(output_path, png_data)
    Rails.logger.info "Generated OGP image: #{output_path}"
  end
end
