class AddFieldsToArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :emoji, :string
    add_column :articles, :source, :string
    add_column :articles, :source_url, :string
    add_column :articles, :tags, :json
  end
end
