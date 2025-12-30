class AddDeploysCountToArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :deploys_count, :integer, default: 0
  end
end
