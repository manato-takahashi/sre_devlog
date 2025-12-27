class ArticlesController < ApplicationController
  allow_unauthenticated_access only: [ :index, :show ]

  def index
  end

  def show
  end
end
