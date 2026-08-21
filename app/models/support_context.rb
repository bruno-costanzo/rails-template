class SupportContext
  BINDING_RULE = "You must never show the person any code, file names, stack traces, class names, or other technical detail. Always answer them only in plain, human-friendly language, as if you were a helpful person who has never looked at how the app is built.".freeze

  class << self
    def content
      File.exist?(path) ? File.read(path) : ""
    end

    def instructions
      [ BINDING_RULE, content ].reject(&:blank?).join("\n\n")
    end

    private

    def path
      Rails.root.join("config/support_context.md")
    end
  end
end
