# Gridium

Welcome to Gridium! Gridium helps you build better automated tests using only Selenium and your advanced knowledge of page objects.  This is a replacement gem for Capybara.  I found it more difficult to use Capybara with Firefox and Selenium, and wanted to take advantage of everything that Selenium offered and Capybara lacked.

Before you get started you should understand how page objects work.  A primer on Page Objects:
[Template Design Pattern](http://www.electricsheepdreams.com/blog/2014/12/4/template-design-pattern-the-first-avenger)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'gridium'
```
Or install it yourself as:

    $ gem install gridium

## Usage

Gridium is built to support the Page Object Design pattern for automated User Interface tests.  Gridium works best when page objects are abstracted from the test files.  While Rspec is preferred, you should still be able to use Gridium with other test runners.  

In order to use Gridium, you will first need to need to add it to your automation suite.  Gridium comes with Selenium and is currently configured to run tests on Firefox only.  Future updates will be available to run tests on other browsers and Selenium Grid.

#### Spec Helper
To get started using Gridium add the Gem to your automated test library.  Include the following section in your `spec_helper.rb` file:

```ruby
Gridium.configure do |config|
  config.report_dir = '/path/to/automation/project'
  config.browser_source = :local
  config.selenium_log_level = 'OFF' #OFF, SEVERE, WARNING, INFO, DEBUG, ALL https://github.com/SeleniumHQ/selenium/wiki/Logging
  config.target_environment = "Integration"
  config.browser = :chrome
  config.url = "http://www.applicationundertest.com"
  config.page_load_timeout = 30
  config.page_load_retries = 0
  config.element_timeout = 30
  config.visible_elements_only = true
  config.log_level = :debug
  config.highlight_verifications = true
  config.highlight_duration = 0.100
  config.screenshot_on_failure = false
  config.screenshots_to_s3 = false
  config.project_name_for_s3 = 'gridium'
  config.subdirectory_name_for_s3 = '' #rely on GridiumS3 default
  config.testrail = false
end
```

Additionally, there are some options that should be configured in the `Rspec.configure` section of your `spec_helper.rb` file:

```ruby
RSpec.configure do |config|
include Gridium
tr = Gridium::TestRail.new  #this would only work if Gridium.config.testrail is set to true
  config.before :all do
    # Set up new testrail run
    tr.add_run("Test Run Name", "Test Run description")
    # Create the test report root directory
    report_root_dir = File.expand_path(File.join(Gridium.config.report_dir, 'spec_reports'))
    Dir.mkdir(report_root_dir) if not File.exist?(report_root_dir)

    # Create the sub-directory for the test suite run
    current_run_report_dir = File.join(report_root_dir, "spec_results__" +               DateTime.now.strftime("%m_%d_%Y__%H_%M_%S"))
    $current_run_dir = current_run_report_dir
    Dir.mkdir(current_run_report_dir)

    # Add the output log file for the rspec test run to the logger
    Log.add_device(File.open(File.join(current_run_report_dir, "spec_logging_output.log"), File::WRONLY | File::APPEND | File::CREAT))

    # Reset Suite statistics
    $verifications_total = 0
    $warnings_total = 0
    $errors_total = 0

    #Setup Gridium Spec Data
    Spec_data.load_suite_state
    Spec_data.load_spec_state
  end #end before:all

  config.after :example, testrail_id: proc { |value| !value.nil? } do |example|
    tr.add_case(example) #Add the results of the case to TestRail
  end

  config.after :all do
    tr.close_run #closes out the TestRun
  end

end #end Rspec.config
```

#### Settings Overview

You may be saying to yourself - 'Holy Crap that's a lot of settings!'.  Yeah.  It is.  Let me preface by saying, I would rather give to many configuration options than not enough.  That being said, we'll probably take some away at some point or make combine them into fewer configuration settings.  With that in Mind let's go over the settings we have now:

##### Gridium Configuration Options:  
`config.report_dir = '/path/to/automation/project'`: This setting tells Gridium where to write reports (i.e. Log files) out to.  This could and probably will be changed at some point to eliminate some required Rspec.configuration options.  
`config.browser_source = :local` = This to use a local or remote (with grid) webdriver
`config.selenium_log_level = 'OFF'`: This tells gridium which level to use for Selenium's loggingPrefs, which are then logged at the debug level.
`config.target_environment = "Stage"`: This is a simple log entry to tell remind you which environment you're testing.  
`config.browser = :firefox`: This tells gridium which browser you will be testing.  Only firefox is working currently.  Future browsers to come.  
`config.url = "http://www.applicationundertest.com"`: Where's the entry point for your web application?  
`config.page_load_timeout = 30` Along with Element Timeout, how long (in seconds) should Selenium wait when finding an element?  
`config.page_load_retries = 1` On a failure to load the requested page, Gridium will retry loading the page this many times.  
`config.visible_elements_only = true`: With this enabled Gridium will only find VISIBLE elements on the page.  Hidden elements or non-enabled elements will not be matched.  
`config.log_level = :debug`: There are a few levels here `:debug` `:info` `:warn` `:error` and `:fatal`.  Your Gridium tests objects can have different levels of logging.  Adjusting this setting will turn those log levels on or off depending on your needs at the time.  
`config.highlight_verifications = true`: Will highlight the element Gridium finds in the browser.  This makes watching tests run easier to follow, although it does slow the test execution time down.  Recommend this is turned off for automated tests running in Jenkins or headless mode.  
`config.highlight_duration = 0.100`: How long should the element be highlighted (in milliseconds) before the action is performed on the element.  
`config.screenshot_on_failure = false`: Take a screenshot on failure.  On or off. Obviously.  
`config.screenshots_to_s3 = false`: This option allows users to save screenshots to an s3 bucket.  AWS S3 buckets need to be setup and configured in AWS.  Environment variables needs to be set for S3.  See environment variables section.  
`config.project_name_for_s3 = 'GRIDIUM'`: This will be appended to the filename in the front of the file. Should not contain spaces.  
`config.subdirectory_name_for_s3 = 'TEST NAME'`: This will be the directory in S3 root to store the files.  Used primarily to differentiate between project artifacts in the same s3 bucket.  
`config.testrail = true`: This to enable TestRail integration. With this turned on, test results will be updated in your TestRail instance.

##### Environment variables

S3 Features require the following Environment variables be set on the machine running the Gridium Test:

```
S3_ACCESS_KEY_ID
S3_SECRET_ACCESS_KEY
S3_DEFAULT_REGION
S3_ROOT_BUCKET
```

For TestRail Integration the following Environment variables are required:

```
GRIDIUM_TR_URL
GRIDIUM_TR_USER
GRIDIUM_TR_PW
GRIDIUM_TR_PID
```


##### Rspec Configuration Options:  
The first bit of the Rspec configuration section is used to set up a log file directory.  I like to have log files kept in separate dated directories.  However, that may not be needed depending on your preference.  If you choose to use a single directory for your log files, you will need to make sure that the log file name is unique, as screenshots are saved into the same directory.  Whichever method you prefer, you will need to setup the Gridium Log Device.  
`Log.add_device(File.open(File.join(current_run_report_dir, "spec_logging_output.log"), File::WRONLY | File::APPEND | File::CREAT))`: This tells Gridium where to write the logs to for any particular test run.

The following is used for throughout the test execution and displayed in the logs to quickly access how many of each particular failure your tests are discovering.  This can be used for quick metrics and climate checks of your application under test.

```ruby
# Reset Suite statistics
$verifications_total = 0
$warnings_total = 0
$errors_total = 0

#Setup Gridium Spec Data
Spec_data.load_suite_state
Spec_data.load_spec_state
```
## Saving screenshots to S3

S3 support is available for persisting screenshots online. This is especially helpful when running tests in CI and/or Docker environments.

#### 1. Setup environment variables
```
export S3_ACCESS_KEY_ID="your access key"
export S3_SECRET_ACCESS_KEY="your secret access key"
export S3_DEFAULT_REGION="your region"
export S3_ROOT_BUCKET="your root bucket"
```
#### 2. Setup spec_helper file

```
  #inside Gridium.configure do |config|
  config.screenshots_to_s3 = true
  config.project_name_for_s3 = 'name the folder below the root bucket'
  config.subdirectory_name_for_s3 = 'name for folder just below that, probably dynamic to mitigate ginormous directories'

```

#### 3. Integrate into a test
```
Driver.visit('https://the-internet.herokuapp.com/')
driver.save_screenshot()
#based on your needs, choose how to publish this screenshot to your interested parties
```
## Page Objects

Page objects are required for Gridium.  Page objects abstract the functionality of the page away from the test.  There's a million reasons why page objects are the way to go.  Not the least of all is that it helps you maintain your tests.

#### Sample Page Object
```ruby
include Gridium
class LoginPage < Page

  def initialize   
    @username = Element.new("UserName - Stage", :css, "input#login_username")
    @password = Element.new("Password - Stage", :css, "input#login_password")
    @login = Element.new("Login Button", :xpath, "//a[@class='submit button']")
  end

  def login(user_name, password)
    Log.info("- Login to staging site Username: #{user_name} Password: #{password}")
    @username.text = user_name
    @password.text = password
    @login.click
  end
end
```

Notice that to use Gridium functionality, Gridium needs to be included at the top of the page object definition.  Also notice that the LoginPage inherits from the Gridium `Page`.  The `Page` object in Gridium provides methods that emulate some of Capybara's API.  For more information checkout the `lib/page.rb`.

Page object are made up of Elements.  The methods on the page object tells the test how interact with the elements.  For example, the Login method shown in the example sets the Username field, the password field and then clicks the login button.  

This action will return a new page, that our test is setup to handle.

## Logging
A log file will always be created with at least one line, showing whichever config.log_level is set to.
This file can be found in `spec_reports/spec_results_{timestamp}/{timestamp}_spec.log` alongside any screenshots taken.
Any log statements using a level equal or lower than config.log_level will be logged.

#### Selenium Logging
The supported log levels in selenium are OFF, SEVERE, WARNING, INFO, DEBUG, ALL
To open the firehose to selenium's logging (https://github.com/SeleniumHQ/selenium/wiki/Logging):
1. Set `config.selenium_log_level = 'ALL'` to  set each type of selenium logging (browser, driver, client, server) to 'ALL'  
2. Set `config.log_level = :debug` to have them picked up by gridium's logger.


## Testing with docker
Gridium's unit tests are run in docker using selenium grid and some helper images:
* [gprestes/the-internet](https://hub.docker.com/r/gprestes/the-internet/)
* [yetanotherlucas/mustadio](https://hub.docker.com/r/yetanotherlucas/mustadio/)

The bin folder contains helper scripts to setup and teardown the docker containers:
* `bin/pull`: Use this to pull the latest docker images prior to starting. 
* `bin/start`: Use this to start up all the docker containers.
  * `dev mode`: -d switch to map your local gridium (via $GRIDIUMPATH) to the gridium container
  * `$GRIDIUMPATH`: set this to point at your Gridium repo -> export GRIDIUMPATH="/path/to/gridium"
* `bin/cleanup`: Use this to cleanup any dangling containers afterward.

Once the containers are running, you can shell into the gridium container to kick off tests:
`docker exec -it gridium_gridium_1 /bin/bash`
`rake spec`
If a test does not pass, modify the spec locally and rerun it inside the gridium container again. Repeat until green.

## Elements

Elements are the building blocks of page objects.  Elements are anything that a user, or a test would care about on the page.  To create a new Element, you will need three things:  
* Element Name - A human readable string used to identify the element to the tester.  Used primarily in the log file.  
* Locator Type - `:css` `:xpath` `:link` `:link_text` `:id` `:class` `:class_name` `:name` `:tag_name` are all valid.  
* Locator - This is the chosen locator Type string to find the element.  

It's important to remember that Elements are not actually found on the page, until an action is attempted.  Only then will the element be attempted to be located.

## Helper Blog Posts:
[Beginner's Guide to Automated Testing](http://www.electricsheepdreams.com/2014/12/4/a-beginners-guide-to-automated-test-design)  
[How to build Xpath locators](http://www.electricsheepdreams.com/2014/12/4/1wq9pbds8m9vktez0qc2w0r0xxlhp6)  
[Browser Tools and Plugins](http://www.electricsheepdreams.com/2014/12/4/su5lssyi84k4ycrmuaceuswbf9ojwr)  
[Automation Pyramid - Theory](http://www.electricsheepdreams.com/2014/12/4/zje1wyef0621gv1w4r7tn3g7h3j19h)  


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sethuster/gridium. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
