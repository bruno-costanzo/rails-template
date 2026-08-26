require "test_helper"

class SitemapsControllerTest < ActionDispatch::IntegrationTest
  test "the sitemap lists the home page, the blog index and every published post" do
    published = create_post(title: "Published", slug: "published", status: "published", published_at: 1.day.ago)

    get sitemap_url

    assert_response :success
    assert_equal "application/xml", response.media_type
    assert_includes response.body, root_url
    assert_includes response.body, blog_url
    assert_includes response.body, blog_post_url(published.slug)
  end

  test "the sitemap leaves drafts out" do
    draft = create_post(title: "Draft", slug: "draft", status: "draft", published_at: nil)

    get sitemap_url

    assert_not_includes response.body, blog_post_url(draft.slug)
  end

  test "robots points at the sitemap and keeps crawlers out of the panels" do
    get robots_url

    assert_response :success
    assert_equal "text/plain", response.media_type
    assert_includes response.body, "Sitemap: #{sitemap_url}"
    assert_includes response.body, "Disallow: /madmin"
  end

  test "both are reachable without a session" do
    get sitemap_url
    assert_response :success

    get robots_url
    assert_response :success
  end

  private

  def create_post(title:, slug:, status:, published_at:)
    Railspress::Post.create!(title: title, slug: slug, status: status, published_at: published_at)
  end
end
