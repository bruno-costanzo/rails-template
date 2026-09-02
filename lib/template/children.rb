require "open3"

module Template
  class Children
    def initialize(root:)
      @root = Pathname.new(root)
      @path = @root.join("children.yml")
    end

    def register(name, path:, sha:)
      data = load
      data[name] = { "path" => path, "born_from" => sha, "synced_to" => sha }
      save(data)
    end

    def mark_synced(name, sha = head)
      data = load
      entry = data.fetch(name)
      entry["synced_to"] = sha
      save(data)
    end

    def report
      load.map { |name, entry| report_line(name, entry) }.join("\n\n")
    end

    private

    def report_line(name, entry)
      child_path = @root.join(entry["path"])
      return "#{name} (#{entry["path"]}): missing" unless child_path.directory?

      pending = pending_commits(entry["synced_to"])
      return "#{name} (#{entry["path"]}): present, up to date" if pending.empty?

      lines = [ "#{name} (#{entry["path"]}): present, #{pending.size} pending commit(s)" ]
      lines += pending.map { |commit| "  #{commit}" }
      lines << "  git -C #{entry["path"]} fetch #{@root} main && git -C #{entry["path"]} cherry-pick #{pending.first.split.first}"
      lines << "  bin/children synced #{name}"
      lines.join("\n")
    end

    def pending_commits(synced_to)
      stdout, = Open3.capture2("git", "-C", @root.to_s, "log", "--oneline", "#{synced_to}..HEAD")
      stdout.lines.map(&:strip)
    end

    def head
      stdout, = Open3.capture2("git", "-C", @root.to_s, "rev-parse", "HEAD")
      stdout.strip
    end

    def load
      return {} unless @path.exist?

      YAML.load(@path.read)
    end

    def save(data)
      @path.write(data.to_yaml)
    end
  end
end
