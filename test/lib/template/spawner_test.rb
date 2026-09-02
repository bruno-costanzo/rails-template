require "test_helper"
require "tmpdir"

class Template::SpawnerTest < ActiveSupport::TestCase
  include GitIdentityHelper

  setup { stub_git_identity }
  teardown { restore_git_identity }

  test "clones the template, renames the clone, and registers it as a child" do
    in_template do |root|
      Template::Spawner.new(root: root, name: "demo").run

      dest = root.parent.join("demo")
      assert File.directory?(dest)
      assert_equal "", `git -C #{dest} remote`.strip
      assert File.exist?(dest.join("renamed-demo"))

      log = `git -C #{dest} log --oneline`.lines
      assert_equal 2, log.size
      assert_includes log.first, "Rename template into demo"

      registry = YAML.load(root.join("children.yml").read)
      assert_equal "../demo", registry["demo"]["path"]
      assert_equal registry["demo"]["born_from"], registry["demo"]["synced_to"]
    end
  end

  test "register raises when the template is not a git repository" do
    Dir.mktmpdir do |tmp|
      root = Pathname.new(tmp).join("root")
      FileUtils.mkdir_p(root)
      spawner = Template::Spawner.new(root: root, name: "demo")

      assert_raises(RuntimeError) { spawner.send(:register) }
    end
  end

  test "refuses to spawn into an already existing directory" do
    in_template do |root|
      FileUtils.mkdir_p(root.parent.join("demo"))

      assert_raises(Template::Spawner::AlreadyExists) do
        Template::Spawner.new(root: root, name: "demo").run
      end
    end
  end

  test "prints the gh command instead of running it without --github" do
    in_template do |root|
      output, = capture_io { Template::Spawner.new(root: root, name: "demo").run }

      assert_includes output, "gh repo create demo --private --source=. --remote=origin --push"
    end
  end

  test "creates the GitHub repository when --github is passed" do
    in_template do |root|
      with_fake_gh do |calls|
        Template::Spawner.new(root: root, name: "demo", github: true).run

        assert_equal 1, File.readlines(calls).size
        assert_includes File.read(calls), "repo create demo --private --source=. --remote=origin --push"
      end
    end
  end

  private

  def in_template
    Dir.mktmpdir do |tmp|
      root = Pathname.new(tmp).join("template")
      FileUtils.mkdir_p(root.join("bin"))
      File.write(root.join("first.txt"), "first")
      File.write(root.join("bin", "rename"), <<~'RUBY')
        #!/usr/bin/env ruby
        name = ARGV[0]
        File.write(File.join(Dir.pwd, "renamed-#{name}"), "")
      RUBY
      FileUtils.chmod("+x", root.join("bin", "rename"))
      system("git", "-C", root.to_s, "init", "--quiet", exception: true)
      system("git", "-C", root.to_s, "add", "-A", exception: true)
      system("git", "-C", root.to_s, "commit", "--quiet", "-m", "Initial commit", exception: true)
      yield root
    end
  end

  def with_fake_gh
    Dir.mktmpdir do |bin|
      calls = File.join(bin, "calls.log")
      File.write(File.join(bin, "gh"), <<~BASH)
        #!/usr/bin/env bash
        echo "$@" >> #{calls}
      BASH
      FileUtils.chmod("+x", File.join(bin, "gh"))
      original_path = ENV["PATH"]
      ENV["PATH"] = "#{bin}:#{original_path}"
      begin
        yield calls
      ensure
        ENV["PATH"] = original_path
      end
    end
  end
end
