# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
require 'webmock/rspec'
require './spec/spec_setup'
# require 'webdrivers/chromedriver'

# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join('spec', 'support', '**', '*.rb')].each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end
RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  options = Selenium::WebDriver::Chrome::Options.new
  options.add_preference(:download, prompt_for_download: false, default_directory: Rails.root.join('tmp/downloads'))
  options.add_preference(:browser, set_download_behavior: { behavior: 'allow' })

  Capybara.register_driver :chrome do |app|
    Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
  end

  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    # driven_by :selenium_chrome_headless
    driven_by :chrome
  end

  WebMock.disable_net_connect!(
    allow_localhost: true,
    allow: 'chromedriver.storage.googleapis.com'
  )
end

def scroll_to_bottom_of_the_page
  page.execute_script "window.scrollBy(0,10000)"
end

def scroll_to_half_of_the_page
  page.execute_script "window.scrollBy(0,2000)"
end

def logs_in(username, password)
  fill_in('Username', with: username)
  fill_in('Password', with: password)
  click_button('Submit')
end

def click_the_back_button
  page.go_back
end

def perform_match_highlighted_text(selector, text)
  elements_selector = "#{selector} [style*='background-color: yellow;']"
  match = false
  all(elements_selector, :visible => true).each do |e|
    match = true if e.text == text
  end
  match
end

def match_highlighted_text(selector, text)
  match = perform_match_highlighted_text(selector, text)
  expect(match).to be_truthy
end

def not_match_highlighted_text(selector, text)
  match = perform_match_highlighted_text(selector, text)
  expect(match).to be_falsy
end

def match_abstractor_object_value_row(value, vocabulary_code, index)
  expect(all('.abstractor_abstractor_object_value')[index].find('.abstractor_object_value_value')).to have_content(value)
  expect(all('.abstractor_abstractor_object_value')[index].find('.abstractor_object_value_vocabulary_code')).to have_content(vocabulary_code)
end

def match_abstractor_object_value_variant_row(value, case_sensitive, disabled, index)
  expect(all('.abstractor-object-value-variant .value')[index].has_field?(nil, with: value, disabled: disabled)).to be_truthy

  if case_sensitive
    expect(all('.abstractor-object-value-variant .case_sensitive')[index].has_checked_field?('Case Sensitive?', disabled: disabled, visible: false)).to be_truthy
  else
    expect(all('.abstractor-object-value-variant .case_sensitive')[index].has_unchecked_field?('Case Sensitive?', disabled: disabled, visible: false)).to be_truthy
  end
end