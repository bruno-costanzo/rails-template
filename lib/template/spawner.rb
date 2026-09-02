require "open3"

module Template
  class Spawner
    class AlreadyExists < StandardError; end

    def initialize(root:, name:, github: false)
      @root = Pathname.new(root)
      @name = name
      @github = github
      @dest = @root.parent.join(name)
    end

    def run
      raise AlreadyExists, "#{@dest} already exists" if @dest.exist?

      clone
      detach_from_template
      rename
      commit
      register
      @github ? create_github_repo : print_github_command
    end

    private

    def clone
      system("git", "clone", "--quiet", @root.to_s, @dest.to_s, exception: true)
    end

    def detach_from_template
      system("git", "-C", @dest.to_s, "remote", "remove", "origin", exception: true)
    end

    def rename
      Bundler.with_unbundled_env do
        system("bin/rename", @name, chdir: @dest.to_s, exception: true)
      end
    end

    def commit
      system("git", "-C", @dest.to_s, "add", "-A", exception: true)
      system("git", "-C", @dest.to_s, "commit", "--quiet", "-m", "Rename template into #{@name}", exception: true)
    end

    def register
      stdout, stderr, status = Open3.capture3("git", "-C", @root.to_s, "rev-parse", "HEAD")
      raise "git rev-parse HEAD failed: #{stderr}" unless status.success?

      Children.new(root: @root).register(@name, path: "../#{@name}", sha: stdout.strip)
    end

    def create_github_repo
      system("gh", "repo", "create", @name, "--private", "--source=.", "--remote=origin", "--push", chdir: @dest.to_s, exception: true)
    end

    def print_github_command
      puts "gh repo create #{@name} --private --source=. --remote=origin --push"
    end
  end
end
