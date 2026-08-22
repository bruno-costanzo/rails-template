// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

import "lexxy"

import confirmDialog from "confirm_dialog"
import discardStaleStreamUpdates from "discard_stale_stream_updates"

Turbo.config.forms.confirm = confirmDialog
discardStaleStreamUpdates()
