class SpecData
  def self.load_suite_state
    screenshots_message
    screenshots_captured
  end

  def self.load_spec_state
    execution_warnings
    verification_errors
    $verification_passes = 0
    $fail_test_instantly = false
    $fail_test_at_end = false
  end

  def self.clear_spec_state
    execution_warnings.clear
    verification_errors.clear
    $verification_passes = 0
    $fail_test_instantly = false
    $fail_test_at_end = false
  end

  def self.reset_captured_screenshots
    screenshots_message.clear
    screenshots_captured.clear
    $screenshots_data = {}
    $fail_screenshot = nil
  end

  def self.determine_spec_result
    if execution_warnings.empty?
      Log.info("[GRIDIUM::SpecData] No warnings detected during test run.")
    else
      Log.info("[GRIDIUM::SpecData]Warnings detected during test run: (#{execution_warnings.length} total).")
      msg = "Warning detected during test execution:"
      execution_warnings.each { |error_message| msg << "\n\t" + error_message }
    end

    if verification_errors.empty?
      Log.info("[GRIDIUM::SpecData]No errors detected during test run.")
    else
      Log.info("[GRIDIUM::SpecData]Errors detected during test run: (#{verification_errors.length} total).")
      msg = "TEST FAILURE: Errors detected during test execution:"
      verification_errors.each { |error_message| msg << "\n\t" + error_message }
    end

    if $fail_test_instantly
      Log.info("[GRIDIUM::SpecData]TEST FAILED - CRITICAL ERROR DETECTED")
      Kernel.fail("TEST FAILED - CRITICAL ERROR DETECTED\n")
    elsif $fail_test_at_end
      Log.info("[GRIDIUM::SpecData]TEST FAILED - VERIFICATION ERRORS DETECTED")
      Kernel.fail("TEST FAILED - VERIFICATION ERRORS DETECTED\n")
    else
      Log.info("[GRIDIUM::SpecData]TEST PASSED\n")
    end
  end

  def self.add_spec_stats_to_suite_stats
    $verifications_total += $verification_passes
    $warnings_total += execution_warnings.length
    $errors_total += verification_errors.length
  end

  def self.clear_all_spec_stats
    $verifications_total = 0
    $warnings_total = 0
    $errors_total = 0
  end

  def self.screenshots_message
    @screenshots_message ||= Array.new
  end

  def self.screenshots_captured
    @screenshots_captured ||= Array.new
  end

  def self.execution_warnings
    @execution_warnings ||= Array.new
  end

  def self.verification_errors
    @verification_errors ||= Array.new
  end
end