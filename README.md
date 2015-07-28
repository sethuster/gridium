# Gridium

Welcome to Gridium! Gridium helps you build better automated tests using only Selenium and your advanced knowledge of page objects.  This is a replacement gem for Capybara.  I found it more difficult to use Capybara with Firefox and Selenium, and wanted to take advantage of everything that Selenium offered and Capybara lacked.

Before you get started you should understand how page objects work.  A primer on Page Objects:
[Template Design Pattern](http://www.electricsheepdreams.com/blog/2014/12/4/template-design-pattern-the-first-avenger)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'gridium'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install gridium

## Usage

Gridium is built to support the Page Object Design pattern for automated User Interface tests.  Gridium works best when page objects are abstracted from the test files.  While Rspec is preferred, you should still be able to use Gridium with other test runners.  

In order to use Gridium, you will first need to need to add it to your automtion suite.  Gridium comes with Selenium and is currently configured to run tests on Firefox only.  Future updates will be available to run tests on other browsers and Selenium Grid.

#### Spec Helper
To get started using Gridium add the Gem to your automated test library.  Include the following section in your `spec_helper.rb` file:

```ruby
Gridium.configure do |config|
  config.report_dir = '/path/to/automation/project'
  config.target_environment = "Integration"
  config.browser = :firefox
  config.url = "http://www.applicationundertest.com"
  config.page_load_timeout = 30
  config.element_timeout = 30
  config.visible_elements_only = true
  config.log_level = :debug
  config.highlight_verifications = true
  config.highlight_duration = 0.100
  config.screenshot_on_failure = false
end
```

Additionally, there are some options that should be configured in the `Rspec.configure` section of your `spec_helper.rb` file:

```ruby
RSpec.configure do |config|
include Gridium
  config.before :all do
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
end #end Rspec.config
```

#### Settings Overview

You may be saying to yourself - 'Holy Crap that's a lot of settings!'.  Yeah.  It is.  Let me preface by saying, I would rather give to many configuration options than not enough.  That being said, we'll probably take some away at some point or make combine them into fewer configuration settings.  With that in Mind let's go over the settings we have now:

##### Gridium Configuration Options:  
`config.report_dir = '/path/to/automation/project'`: This setting tells Gridium where to write reports (i.e. Log files) out to.  This could and probably will be changed at some point to eliminate some required Rspec.configuration options.  
`config.target_environment = "Stage"`: This is a simple log entry to tell remind you which environment you're testing.  
`config.browser = :firefox`: This tells gridium which browser you will be testing.  Only firefox is working currently.  Future browsers to come.  
`config.url = "http://www.applicationundertest.com"`: Where's the entry point for your web application?  
`config.page_load_timeout = 30` Along with Element Timeout, how long (in seconds) should Selenium wait when finding an element?  
`config.visible_elements_only = true`: With this enabled Gridium will only find VISIBLE elements on the page.  Hidden elements or non-enabled elements will not be matched.  
`config.log_level = :debug`: There are a few levels here `:debug` `:info` `:warn` `:error` and `:fatal`.  Your Gridium tests objects can have different levels of logging.  Adjusting this setting will turn those log levels on or off depending on your needs at the time.  
`config.highlight_verifications = true`: Will highlight the element Gridium finds in the browser.  This makes watching tests run easier to follow, although it does slow the test execution time down.  Recommend this is turned off for automated tests running in Jenkins or headless mode.
`config.highlight_duration = 0.100`: How long should the element be highlighted (in miliseconds) before the action is performed on the element.
`config.screenshot_on_failure = false`: Take a screenshot on failure.  On or off. Obviously.

##### Rspec Configuration Options:  
The first bit of the Rspec configuration section is used to set up a log file directory.  I like to have log files kept in seperate dated directories.  However, that may not be needed depending on your preference.  If you choose to use a single directory for your log files, you will need to make sure that the log file name is unique, as screenshots are saved into the same directory.  Whichever method you prefer, you will need to setup the Gridium Log Device.  
`Log.add_device(File.open(File.join(current_run_report_dir, "spec_logging_output.log"), File::WRONLY | File::APPEND | File::CREAT))`: This tells Gridium where to write the logs to for any paticular test run.

The following is used for throughout the test execution and displayed in the logs to quickly access how many of each paticular failure your tests are discovering.  This can be used for quick metrics and climate checks of your aplication under test.
```ruby
# Reset Suite statistics
$verifications_total = 0
$warnings_total = 0
$errors_total = 0

#Setup Gridium Spec Data
Spec_data.load_suite_state
Spec_data.load_spec_state
```

##Page Objects

Page objects are required for Gridium.  Page objects abstract the functionality of the page away from the test.  There's a million reasons why page objects are the way to go.  Not the least of all is that it helps you maintain your tests.

###Example Page Object



##Helper Blog Posts:
[Beginner's Guide to Automated Testing](http://www.electricsheepdreams.com/2014/12/4/a-beginners-guide-to-automated-test-design)  
[How to build Xpath locators](http://www.electricsheepdreams.com/2014/12/4/1wq9pbds8m9vktez0qc2w0r0xxlhp6)  
[Browser Tools and Plugins](http://www.electricsheepdreams.com/2014/12/4/su5lssyi84k4ycrmuaceuswbf9ojwr)  
[Automation Pyramid - Theory](http://www.electricsheepdreams.com/2014/12/4/zje1wyef0621gv1w4r7tn3g7h3j19h)  


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sethuster/gridium. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

