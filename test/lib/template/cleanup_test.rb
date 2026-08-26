require "test_helper"
require "tmpdir"

class Template::CleanupTest < ActiveSupport::TestCase
  test "removes the tooling that only serves the template" do
    in_fixture_tree do |dir|
      Template::Cleanup.new(root: dir, app_name: "Demo").run

      Template::Cleanup::REMOVED_PATHS.each do |path|
        assert_not File.exist?(File.join(dir, path)), "expected #{path} to be removed"
      end
    end
  end

  test "keeps the application's own code" do
    in_fixture_tree do |dir|
      Template::Cleanup.new(root: dir, app_name: "Demo").run

      assert File.exist?(File.join(dir, "docs", "design-substrate.md"))
      assert File.exist?(File.join(dir, "bin", "setup"))
    end
  end

  test "drops the smoke step from the continuous integration script" do
    in_fixture_tree do |dir|
      Template::Cleanup.new(root: dir, app_name: "Demo").run

      ci = File.read(File.join(dir, "config", "ci.rb"))
      assert_not_includes ci, "Smoke:"
      assert_includes ci, "Tests: Rails"
    end
  end

  test "rewrites the readme so it describes an application rather than a template" do
    in_fixture_tree do |dir|
      Template::Cleanup.new(root: dir, app_name: "Demo").run

      readme = File.read(File.join(dir, "README.md"))
      assert_includes readme, "Demo is a Rails application built from"
      assert_not_includes readme, "starter template"
      assert_not_includes readme, "smoke_app"
      assert_not_includes readme, "SMOKE_PORT"
      assert_not_includes readme, "and a `bin/smoke-rename` step"
      assert_not_includes readme, "## Updating this template"
      assert_includes readme, "## Testing"
      assert_includes readme, "## Porting template improvements"
    end
  end

  test "this template's own readme still carries the anchors the cleanup depends on" do
    readme = Rails.root.join("README.md").read

    assert_match Template::Cleanup::INTRO_SECTION, readme
    assert_match Template::Cleanup::TEMPLATE_SECTION, readme
    assert_includes readme, Template::Cleanup::CI_CLAUSE
    Template::Cleanup::SMOKE_MARKERS.each { |marker| assert_includes readme, marker }
  end

  test "this template's own ci script still carries the step the cleanup removes" do
    assert_match Template::Cleanup::CI_STEP, Rails.root.join("config/ci.rb").read
  end

  private

  def in_fixture_tree
    Dir.mktmpdir do |dir|
      %w[bin lib/template test/lib/template docs/superpowers config].each { |path| FileUtils.mkdir_p(File.join(dir, path)) }
      FileUtils.touch(File.join(dir, "bin", "rename"))
      FileUtils.touch(File.join(dir, "bin", "smoke-rename"))
      FileUtils.touch(File.join(dir, "bin", "setup"))
      FileUtils.touch(File.join(dir, "lib", "template", "renamer.rb"))
      FileUtils.touch(File.join(dir, "test", "lib", "template", "renamer_test.rb"))
      FileUtils.touch(File.join(dir, "docs", "superpowers", "plan.md"))
      File.write(File.join(dir, "docs", "design-substrate.md"), "tokens")
      File.write(File.join(dir, "config", "ci.rb"), <<~RUBY)
        CI.run do
          step "Tests: Rails", "bin/rails test"
          step "Smoke: renamed app boots and serves", "bin/smoke-rename"
        end
      RUBY
      File.write(File.join(dir, "README.md"), <<~MARKDOWN)
        # Demo

        ## What is this

        Demo is a Rails starter template you clone and rename.

        ## Testing

        Run `bin/ci`: rubocop, `bin/rails test`, and a `bin/smoke-rename` step.

        That last step runs `bin/rename smoke_app` on a copy.

        Override the port with `SMOKE_PORT` if it is taken.

        Tests never hit the network.

        ## Updating this template

        Bump the Rails constraint and re-run everything.

        ## Porting template improvements

        Cherry-pick from the template remote.
      MARKDOWN
      yield dir
    end
  end
end
