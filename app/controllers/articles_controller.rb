class ArticlesController < ApplicationController
  allow_unauthenticated_access only: [ :index, :show, :deploy ]
  before_action :set_article, only: [ :show, :edit, :update, :destroy, :deploy ]

  def index
    @articles = Article.where(published: true).order(published_at: :desc)
  end

  def show
  end

  def deploy
    @article.increment!(:deploys_count)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @article }
    end
  end

  def new
    @article = Article.new
  end

  def create
    @article = Article.new(article_params)
    if @article.save
      redirect_to @article, notice: "記事を作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @article.update(article_params)
      redirect_to @article, notice: "記事を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @article.destroy
    redirect_to articles_path, notice: "記事を削除しました"
  end

  private

  def set_article
    @article = Article.find_by!(slug: params[:id])
  end

  def article_params
    params.require(:article).permit(:title, :body, :slug, :published, :published_at)
  end
end
