require "test_helper"
require "tmpdir"

class Template::RenamerTest < ActiveSupport::TestCase
  test "rewrites module, snake and dashed names in text files" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "application.rb"), "module CharcoTemplate\nend\n")
      File.write(File.join(dir, "deploy.yml"), "service: charco_template\nhost: charco-template.example.com\n")
      FileUtils.mkdir(File.join(dir, "tmp"))
      File.write(File.join(dir, "tmp", "skipped.rb"), "CharcoTemplate")
      Template::Renamer.new(root: dir, new_name: "acme_notes").run
      assert_includes File.read(File.join(dir, "application.rb")), "module AcmeNotes"
      assert_includes File.read(File.join(dir, "deploy.yml")), "service: acme_notes"
      assert_includes File.read(File.join(dir, "deploy.yml")), "acme-notes.example.com"
      assert_includes File.read(File.join(dir, "tmp", "skipped.rb")), "CharcoTemplate"
    end
  end

  test "treats empty files as text and leaves them untouched without raising" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, ".gitkeep")
      FileUtils.touch(path)

      Template::Renamer.new(root: dir, new_name: "acme_notes").run

      assert_equal "", File.read(path)
    end
  end

  test "leaves files without a template reference untouched" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "unrelated.txt")
      File.write(path, "hello world")
      mtime_before = File.mtime(path)

      Template::Renamer.new(root: dir, new_name: "acme_notes").run

      assert_equal "hello world", File.read(path)
      assert_equal mtime_before, File.mtime(path)
    end
  end
end
