require "axe/configuration"

module AccessibilityHelper
  AXE_TAGS = %w[wcag2a wcag2aa wcag21a wcag21aa].freeze
  AXE_MAX_TARGETS = 5

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
    violations = page.evaluate_async_script(AXE_SCRIPT, "runOnly" => { "type" => "tag", "values" => AXE_TAGS })
    assert_empty violations, accessibility_failure_message(violations)
  end

  private

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
      "  #{violation['id']} (#{violation['impact']}) — #{violation['help']}",
      "    #{violation['helpUrl']}",
      *shown.map { |target| "    #{target}" }
    ].join("\n")
  end
end
