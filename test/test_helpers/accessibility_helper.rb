require "axe/configuration"

module AccessibilityHelper
  AXE_TAGS = %w[wcag2a wcag2aa wcag21a wcag21aa].freeze
  AXE_MAX_TARGETS = 5
  AXE_COLOR_SCHEMES = %w[light dark].freeze

  AXE_SCRIPT = <<~JS.freeze
    var done = arguments[arguments.length - 1];
    axe.run(document, arguments[0]).then(function (results) {
      done(results.violations.map(function (violation) {
        return {
          id: violation.id,
          impact: violation.impact,
          help: violation.help,
          helpUrl: violation.helpUrl,
          targets: violation.nodes.map(function (node) { return node.target.join(" "); })
        };
      }));
    });
  JS

  def assert_accessible
    inject_axe

    violations = AXE_COLOR_SCHEMES.flat_map do |scheme|
      emulate_color_scheme(scheme)
      audit_page.each { |violation| violation["scheme"] = scheme }
    end

    assert_empty violations, accessibility_failure_message(violations)
  ensure
    emulate_color_scheme(nil)
  end

  private

  def audit_page
    page.evaluate_async_script(AXE_SCRIPT, "runOnly" => { "type" => "tag", "values" => AXE_TAGS })
  end

  def emulate_color_scheme(scheme)
    features = scheme ? [ { name: "prefers-color-scheme", value: scheme } ] : []
    page.driver.browser.page.command("Emulation.setEmulatedMedia", features: features)
  end

  def inject_axe
    return if page.evaluate_script("typeof window.axe === 'object'")

    page.execute_script(Axe::Configuration.instance.jslib)
  end

  def accessibility_failure_message(violations)
    return "" if violations.empty?

    header = "#{violations.size} accessibility #{'violation'.pluralize(violations.size)} on #{page.current_path}:"
    [ header, *violations.map { |violation| accessibility_violation_message(violation) } ].join("\n\n")
  end

  def accessibility_violation_message(violation)
    targets = violation["targets"]
    shown = targets.first(AXE_MAX_TARGETS)
    shown << "(+#{targets.size - AXE_MAX_TARGETS} more)" if targets.size > AXE_MAX_TARGETS

    [
      "  #{violation['id']} (#{violation['impact']}, #{violation['scheme']} theme) — #{violation['help']}",
      "    #{violation['helpUrl']}",
      *shown.map { |target| "    #{target}" }
    ].join("\n")
  end
end
