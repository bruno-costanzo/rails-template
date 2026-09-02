module GitIdentityHelper
  GIT_ENV_KEYS = %w[GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL GIT_CONFIG_GLOBAL].freeze

  def stub_git_identity
    @original_git_env = GIT_ENV_KEYS.to_h { |key| [ key, ENV[key] ] }
    ENV["GIT_AUTHOR_NAME"] = "Test"
    ENV["GIT_AUTHOR_EMAIL"] = "test@example.com"
    ENV["GIT_COMMITTER_NAME"] = "Test"
    ENV["GIT_COMMITTER_EMAIL"] = "test@example.com"
    ENV["GIT_CONFIG_GLOBAL"] = "/dev/null"
  end

  def restore_git_identity
    @original_git_env.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end
end
