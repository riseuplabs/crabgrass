# Edit at your own peril - it's recommended to regenerate this file
# in the future when you upgrade to a newer version of Cucumber.

# IMPORTANT: Setting config.cache_classes to false is known to
# break Cucumber's use_transactional_fixtures method.
# For more information see https://rspec.lighthouseapp.com/projects/16211/tickets/165
config.cache_classes = true

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false

# Disable request forgery protection in test environment
config.action_controller.allow_forgery_protection    = false

# Tell Action Mailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
config.action_mailer.delivery_method = :test

ASSET_PRIVATE_STORAGE = "#{RAILS_ROOT}/tmp/private_assets"
ASSET_PUBLIC_STORAGE  = "#{RAILS_ROOT}/tmp/public_assets"

MIN_PASSWORD_STRENGTH = 0

TEST_EMAIL_FILE = RAILS_ROOT + "/tmp/test_emails"

# rails engines are way too verbose, so set engines logging to info:
if defined? Engines
  Engines.logger = ActiveSupport::BufferedLogger.new(config.log_path)
  Engines.logger.level = Logger::INFO
end
