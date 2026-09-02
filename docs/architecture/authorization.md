# Authorization

pundit is installed as a capability. **The app ships zero concrete policies**: scoping through `Current.user` remains the authorization until an app needs roles or shared resources.

`ApplicationController` includes `Pundit::Authorization`, overrides `pundit_user` to return `Current.user` — pundit defaults to a `current_user` method this app does not define — and rescues `Pundit::NotAuthorizedError` by redirecting back, falling back to the root path, with an alert. `ApplicationPolicy` (`app/policies/application_policy.rb`) is the generator's default-deny base with its comments stripped.

There is no `verify_authorized` or `verify_policy_scoped` anywhere. That strictness is opt-in per app and the README's Authorization section documents the knob.

The only policy in the repository is `PunditTestRecordPolicy` in `test/policies/`, for a test-only plain object, required by a glob in `test/test_helper.rb` and never loaded by app code — the same pattern as the test notifier. It is deliberately not a policy for a real model, so it can never silently merge with a policy a child app writes for that same model. `test/controllers/pundit_wiring_test.rb` exercises permit, deny with the rescue and alert, and scope filtering through a test-local controller and routes, touching no app controller.
