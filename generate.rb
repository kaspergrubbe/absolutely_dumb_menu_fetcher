require 'capybara'
require 'capybara/dsl'
require 'selenium-webdriver'
require 'erb'
require 'ostruct'
require 'base64'
require 'aws-sdk-s3'
require 'yell'

require_relative 'lib/array_compare'
require_relative 'lib/sample_match_data'
require_relative 'lib/search'

logger = Yell.new do |l|
  l.adapter $stdout, level: %i[debug info warn]
  l.adapter $stderr, level: %i[error fatal]
end

%w[
  AWS_REGION
  AWS_BUCKET
  AWS_ACCESS_KEY_ID
  AWS_SECRET_ACCESS_KEY
].each do |env_var|
  logger.info "Testing presence of #{env_var}"

  raise "Missing environment variable #{env_var}" if ENV[env_var].nil?
  raise "Empty environment variable #{env_var}" if ENV[env_var] == ''
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

# Capybara.register_driver :selenium do |app|
#   options = Selenium::WebDriver::Chrome::Options.new()
#   options.add_argument('headless')
#   options.add_argument('disable-gpu')
#   options.add_argument('window-size=1380,1280')
#   options.add_argument('disable-dev-shm-usage')
#
#   # Exclude switch 'enable-automation' to remove infobar. This stops the
#   # "Chrome is being controlled by automated software." infobar at the top of the
#   # browser window from animating and breaking clicks sporadically.
#   # https://bugs.chromium.org/p/chromedriver/issues/detail?id=1683
#   # https://github.com/GoogleChrome/chrome-launcher/blob/master/docs/chrome-flags-for-tools.md#--enable-automation
#   # options.add_option 'excludeSwitches', ['enable-automation']
#   # options.add_argument('enable-automation')
#
#   Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
# end

# Set the default driver to Selenium
Capybara.default_driver = :selenium

# Initialize Capybara
@host = 'https://meyers.dk'
Capybara.app_host = @host
Capybara.run_server = false

# This can be useful in situations where you need to access and manipulate elements that are not initially visible in the viewport.
# Capybara.ignore_hidden_elements = false

# Create a Capybara session
session = Capybara::Session.new(:selenium)

# Alternative page: https://meyers.dk/erhverv/frokostordning/almanak/
@path = '/erhverv/frokostordning/ugens-menuer/'

begin
  logger.info "Visiting #{@host}#{@path}"
  session.visit(@path)

  sleep(2)

  # Hide the scrollbar by changing the CSS of the body element
  logger.info 'Hide the scrollbar'
  session.execute_script('document.body.style.overflow = "hidden";')

  # Find and click the button with the ID "declineButton"
  logger.info 'Click the declinebutton on the cookiebanner'
  button = session.find('#declineButton')
  button.click

  sleep(2)

  # Find all div elements with the id "_elev_io"
  logger.info 'Hide the FAQ and help overlay'
  session.all('div#_elev_io').each do |element|
    session.execute_script('arguments[0].remove();', element)
  end

  sleep(2)

  meyers_menu = 'li.tns-nav-active'

  # Scroll down to the date
  session.execute_script("document.querySelector('#{meyers_menu}').scrollIntoView();")

  # Remove the class "controls"
  logger.info 'Hide the date controls'
  session.execute_script("document.querySelector('div.controls').remove();")

  # Scroll down to the date again because deleting "controls" pushes content up
  session.execute_script('window.scrollTo(0, 0);')
  session.execute_script("document.querySelector('#{meyers_menu}').scrollIntoView();")
  sleep(1)

  # Take a screenshot
  logger.info 'Save the screenshot at screenshot.png'
  session.save_screenshot('screenshot.png')

  # Quit the browser
  session.driver.quit

  # Open screenshot
  logger.info ''
  logger.info 'Open the screenshot and search for the allergen icon'
  search = Search.new
  haystack = ChunkyPNG::Image.from_file('screenshot.png')

  logger.info '.. searching for the allergen-icon in screenshot'
  allergen_icon = ['images/allergener_icon_ffox2.png', 'images/allergener_icon_ffox.png'].map do |path|
    cp = ChunkyPNG::Image.from_file(path)
    search.find_first_sample(haystack, cp)
  end.compact.first

  unless allergen_icon
    debug_file = "screenshot-#{Time.now.utc.to_i}.png"
    haystack.save(debug_file)
    raise "Couldn't find allergen-icon, debug with #{debug_file}"
  end
  logger.info ".. found the allergen-icon at (#{allergen_icon.x0}x#{allergen_icon.y0})!"

  logger.info ''
  logger.info 'Cropping the image'
  hc = haystack.crop(0, 0, haystack.width, (allergen_icon.y0 - 70))
  logger.info '.. saving the new cropped image at haystack.png'
  hc.save('haystack.png')

  logger.info ''
  logger.info 'Building the HTML template'
  @b64i = OpenStruct.new
  @b64i.width = hc.width
  @b64i.height = hc.height
  @b64i.data = Base64.strict_encode64(hc.to_blob)

  template = File.read('templates/template.html.erb')
  erb_template = ERB.new(template)
  html = erb_template.result(binding)
  logger.info '.. writing it to kitchen.html'
  File.open('kitchen.html', 'w') do |file|
    file.write(html)
  end

  # UPLOAD TO S3
  logger.info ''
  logger.info 'Sending the HTML-file to S3'
  Aws.config.update({
                      region: ENV['AWS_REGION'],
                      credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
                    })

  s3 = Aws::S3::Client.new
  logger.info '.. sending kitchen.html to S3'
  s3.put_object(
    bucket: ENV['AWS_BUCKET'],
    key: 'kitchen.html',
    body: File.open('kitchen.html'),
    acl: 'public-read',
    content_type: 'text/html'
  )
  logger.info '.. done!'
  logger.info "https://#{ENV['AWS_BUCKET']}.s3.#{ENV['AWS_REGION']}.amazonaws.com/kitchen.html"
ensure
  logger.info ''
  logger.info 'Cleaning up'

  if File.exist?('kitchen.html')
    logger.info '.. deleting kitchen.html'
    File.delete('kitchen.html')
  end

  if File.exist?('screenshot.png')
    logger.info '.. deleting screenshot.png'
    File.delete('screenshot.png')
  end

  if File.exist?('haystack.png')
    logger.info '.. deleting haystack.png'
    File.delete('haystack.png')
  end
end
