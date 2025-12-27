class Article < ApplicationRecord
  def to_param
    slug
  end
end
