class SitemapsController < ApplicationController
  allow_unauthenticated_access

  def show
    @posts = Railspress::Post.published.order(published_at: :desc)
  end

  def robots
  end
end
