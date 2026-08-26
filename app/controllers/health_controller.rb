class HealthController < ApplicationController
  allow_unauthenticated_access

  def show
    checks = HealthCheck.call
    healthy = checks.values.all?

    render json: {
      status: healthy ? "ok" : "error",
      checks: checks.transform_values { |alive| alive ? "ok" : "error" }
    }, status: healthy ? :ok : :service_unavailable
  end
end
