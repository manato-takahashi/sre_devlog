namespace :articles do
  desc "Markdownファイルからデータベースに記事を同期する"
  task sync: :environment do
    articles_dir = Rails.root.join("articles")

    # *.md ファイルをすべて取得
    markdown_files = Dir.glob(articles_dir.join("*.md"))

    puts "Found #{markdown_files.count} article(s)"
    markdown_files.each do |path|
      slug = File.basename(path, ".md")
      content = File.read(path)

      # Front Matter と本文を分離
      if content.start_with?("---")
        parts = content.split("---", 3)
        front_matter = YAML.safe_load(parts[1], permitted_classes: [ Date ])
        body = parts[2].strip

        # 変換済み HTML ファイルがあればそれを使う (Zenn記法対応)
        html_path = path.sub(/\.md$/, ".html")
        if File.exist?(html_path)
          html = File.read(html_path)
        else
          # なければ従来通り Commonmarker で変換
          html = Commonmarker.to_html(body,
            options: {
              extension: {
                strikethrough: true,  # 取り消し線
                table: true,          # テーブル
                autolink: true,       # 自動リンク
                tasklist: true,       # タスクリスト
                footnotes: true       # 脚注
              }
            },
            plugins: {
              syntax_highlighter: {
                theme: "base16-ocean.dark"
              }
            }
          )
        end

        # コードブロックの後処理（Stimulus用data属性追加）
        doc = Nokogiri::HTML.fragment(html)
        doc.css("pre").each do |pre|
          lang = pre["lang"]

          # bashはターミナル風にする
          pre["data-terminal"] = "true" if lang == "bash"

          pre["data-controller"] = "code-block"
        end
        html = doc.to_html

        # DB保存処理
        article = Article.find_or_initialize_by(slug: slug)
        article.assign_attributes(
          title: front_matter["title"],
          emoji: front_matter["emoji"],
          tags: front_matter["tags"],
          published: front_matter["published"] || false,
          published_at: front_matter["published_at"],
          source: front_matter["source"],
          source_url: front_matter["source_url"],
          body: html
        )

        if article.new_record?
          article.save!
          puts "✨ Created: #{slug}"
        elsif article.changed?
          article.save!
          puts "♻️  Updated: #{slug}"
        else
          puts "⏩ Unchanged: #{slug}"
        end
      else
        puts "⚠️  #{slug}: Front Matter がありません"
      end
    end

    file_slugs = markdown_files.map { |path| File.basename(path, ".md") }

    # DBにあるけどファイルにないものを削除
    deleted_articles = Article.where.not(slug: file_slugs)
    deleted_articles.each do |article|
      article.destroy!
      puts "🗑️  Deleted: #{article.slug}"
    end
  end
end
