require 'capybara'
require 'capybara/dsl'
require 'selenium-webdriver'
require 'yell'

logger = Yell.new do |l|
  l.adapter $stdout, level: %i[debug info warn]
  l.adapter $stderr, level: %i[error fatal]
end

Capybara.register_driver :selenium do |app|
  options = Selenium::WebDriver::Firefox::Options.new
  options.add_argument('-headless') # Run Firefox in headless mode

  options.add_preference('window-size', '1380,1280') # Set window size
  options.add_preference('gfx.webrender.enabled', false) # Disable GPU
  options.add_preference('security.sandbox.content.level', 1) # Disable sandbox
  options.add_preference('security.sandbox.logging.enabled', false) # Disable sandbox logging
  options.add_preference('devtools.console.stdout.chrome', true) # Enable console output for Chrome
  options.add_preference('devtools.console.stdout.content', true) # Enable console output for content

  Capybara::Selenium::Driver.new(app, browser: :firefox, options: options)
end

Capybara.default_driver = :selenium
@host = 'https://billetto.com'
Capybara.app_host = @host
Capybara.run_server = false
session = Capybara::Session.new(:selenium)
@path = '/'
logger.info "Visiting #{@host}#{@path}"
logger.info session.visit(@path)
