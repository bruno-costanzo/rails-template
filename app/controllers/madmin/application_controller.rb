module Madmin
  class ApplicationController < Madmin::BaseController
    include SuperadminAuthentication

    around_action :without_bullet if defined?(Bullet)

    private

    def without_bullet
      was_enabled = Bullet.enable?
      Bullet.enable = false
      yield
    ensure
      Bullet.enable = was_enabled
    end
  end
end
