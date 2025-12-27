class ArticlesController < ApplicationController
  allow_unauthenticated_access only: [ :index, :show ]

  def index
    @articles = Article.where(published: true).order(published_at: :desc)
  end

  def show
    @article = Article.find_by!(slug: params[:id])
  end
end
