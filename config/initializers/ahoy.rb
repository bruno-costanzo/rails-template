class Ahoy::Store < Ahoy::DatabaseStore
end

Ahoy.api = false
Ahoy.geocode = false
Ahoy.mask_ips = true
Ahoy.cookies = :none
Ahoy.user_method = ->(_controller) { Current.user }
