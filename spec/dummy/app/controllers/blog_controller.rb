# Example blog controller demonstrating how to use RailsPress models
# in a host application's frontend
class BlogController < ApplicationController
  def index
    @posts = Railspress::Post.published
                             .with_rich_text_content
                             .includes(:category, :tags)
                             .ordered
  end

  def show
    @post = if params[:railspress_preview].present?
      Railspress::Post.find_preview!(slug: params[:slug], token: params[:railspress_preview])
    else
      Railspress::Post.published.find_by!(slug: params[:slug])
    end
    @related_posts = if @post.category
      @post.category.posts
           .published
           .where.not(id: @post.id)
           .ordered
           .limit(3)
    else
      []
    end
  end

  def category
    @category = Railspress::Category.find_by!(slug: params[:slug])
    @posts = @category.posts
                      .published
                      .includes(:tags)
                      .ordered
  end

  def tag
    @tag = Railspress::Tag.find_by!(slug: params[:slug])
    @posts = @tag.posts
                 .published
                 .includes(:category)
                 .ordered
  end

  def search
    @query = params[:q].to_s.strip
    @posts = if @query.present?
               Railspress::Post.published
                               .where("title LIKE ?", "%#{@query}%")
                               .includes(:category, :tags)
                               .ordered
    else
               Railspress::Post.none
    end
  end
end
