class CreateArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :articles do |t|
      t.string :title
      t.text :body
      t.string :slug
      t.boolean :published
      t.datetime :published_at

      t.timestamps
    end
  end
end
