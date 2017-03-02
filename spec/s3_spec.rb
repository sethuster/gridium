require_relative 'spec_helper'
require 'tmpdir'

describe GridiumS3 do

  let(:gridium_config) { Gridium.config }
  let(:project_name) { "spec" }
  let(:subdirectory_name) {"child_of_spec"}
  let(:empty_name) { "" }
  let(:whitespace_name) { "\t\r\n " } #tab, carriage return, newline, space
  let(:s3) { Gridium::GridiumS3.new(project_name, subdirectory_name) }
  let(:logger) { Log }

  describe 's3 instantiation' do
    it 'will fail without a project name' do
        no_arg_call = lambda {Gridium::GridiumS3.new}
        expect(&no_arg_call).to raise_error(ArgumentError)
    end

    it 'will succeed with a project name and without a subdirectory name' do
        s3 = Gridium::GridiumS3.new(project_name)
    end

    it 'will succeed with both a project name and a subdirectory name' do
        s3 = Gridium::GridiumS3.new(project_name, subdirectory_name)
    end
  end

  describe 's3 connectivity' do
    it 'will gracefully handle a loss in connectivity' do

    end
  end
  describe 's3 configuration' do

      let(:s3_access_key_id) {ENV['S3_ACCESS_KEY_ID']}
      let(:s3_secret_access_key) {ENV['S3_SECRET_ACCESS_KEY']}
      let(:s3_default_region) {ENV['S3_DEFAULT_REGION']}
      let(:s3_root_bucket) {ENV['S3_ROOT_BUCKET']}

    it 'requires that the S3_ACCESS_KEY_ID environment variable exists' do
        expect(s3_access_key_id).not_to be_nil
    end

    it 'requires that the S3_SECRET_ACCESS_KEY environment variable exists' do
        expect(s3_secret_access_key).not_to be_nil
    end
    it 'requires that the S3_DEFAULT_REGION environment variable exists' do
        expect(s3_default_region).not_to be_nil
    end
    it 'requires that the S3_ROOT_BUCKET environment variable exists' do
        expect(s3_root_bucket).not_to be_nil
    end
  end


  describe 's3 file naming'do
      let(:file_name) {"temp.txt"}

    it 'will fail without a file name' do
        no_arg_call = lambda {s3.create_s3_name}
        expect(&no_arg_call).to raise_error(ArgumentError)
    end

    it 'will fail with an empty file name' do
        empty_string_call = lambda {s3.create_s3_name empty_name}
        expect(&empty_string_call).to raise_error(ArgumentError)
    end

    it 'will fail with a white space file name' do
        whitespace_string_call = lambda {s3.create_s3_name whitespace_name}
        expect(&whitespace_string_call).to raise_error(ArgumentError)
    end

    it 'will sanitize whitespace in project name', :focus => true  do
        whitespaced_project_name = "\t\r\n spec \t\r\n project \t\r\n "
        sanitized_project_name = "spec_project"
        s3 = Gridium::GridiumS3.new(whitespaced_project_name, subdirectory_name)
        expected_s3_name = sanitized_project_name + "/" + subdirectory_name + "/" + file_name
        actual_s3_name = s3.create_s3_name(file_name)
        expect(actual_s3_name).to eq expected_s3_name
    end

    it 'will sanitize whitespace in subdirectory name', :focus => true  do
        whitespaced_subdirectory_name = "\t\r\n desc \t\r\n of \t\r\n spec \t\r\n "
        sanitized_subdirectory_name = "desc_of_spec"
        s3 = Gridium::GridiumS3.new(project_name, whitespaced_subdirectory_name)
        expected_s3_name = project_name + "/" + sanitized_subdirectory_name + "/" + file_name
        actual_s3_name = s3.create_s3_name(file_name)
        expect(actual_s3_name).to eq expected_s3_name
    end

    it 'will sanitize whitespace in file name', :focus => true  do
        whitespaced_file_name = "\t\r\n temp \t\r\n name.txt \t\r\n "
        sanitized_file_name = "temp_name.txt"
        expected_s3_name = project_name + "/" + subdirectory_name + "/" + sanitized_file_name
        actual_s3_name = s3.create_s3_name(whitespaced_file_name)
        expect(actual_s3_name).to eq expected_s3_name
    end

    it 'will default the subdirectory name to screenshots' do
      default_subdir_name = 'screenshots'
      sanitized_file_name = "temp_name.txt"
      s3 = Gridium::GridiumS3.new(project_name)
      actual_s3_name = s3.create_s3_name(sanitized_file_name)
      expect(actual_s3_name).to include default_subdir_name
    end

  end
  describe 's3 file saving' do
    before :all do
      #create a temp folder in the systems tmp directory
      tmp = Dir.tmpdir()
      temp_subdirectory = "gridium_#{Time.now.to_i}"
      @temp_path = File.join(tmp, temp_subdirectory)
      Dir.mkdir(@temp_path)
      @temp_files = []
    end

    before :each do
      #create temp files with token contents
      @file_name = "temp_#{Time.now.to_i}.txt"
      @full_path = File.join(@temp_path, @file_name)
      File.open(@full_path, File::WRONLY | File::APPEND | File::CREAT) do |temp_file|
         temp_file.write("hello world112233")
      end
      @temp_files.push @full_path
    end

    after :all do
      #delete the temp files
      @temp_files.each do |temp_file|
        if File.exist? temp_file then
          File.delete temp_file
          Log.debug("deleted #{temp_file} during teardown")
        end
      end
      #delete the temp folder
      Dir.delete(@temp_path)
      Log.debug("deleted #{@temp_path} during teardown")
    end

    it 'succeeds with a local file'  do
      s3_path = s3.save_file(@full_path)
      expect(s3_path).to include @file_name
    end

    it 'fails if the file doesn\'t exist' do
      non_existant_file = "nuke_me_#{Time.now.to_i}.txt"
      path_to_non_existant_file = File.join(@temp_path, non_existant_file)
      if File.exist? path_to_non_existant_file then
        File.delete path_to_non_existant_file
      end
      bad_file_call = lambda {s3.save_file(path_to_non_existant_file)}
      expect(bad_file_call).to raise_error ArgumentError
    end
    it 'fails if the file path is invalid' do
        non_existant_path = File.join(@temp_path, "#{Time.now.to_i}", @file_name)
        bad_path_call = lambda {s3.save_file(non_existant_path)}
        expect(bad_path_call).to raise_error ArgumentError
    end

    it 'gracefully handles invalid credentials' do
      ENV['S3_ACCESS_KEY_ID'] = 'medulla'
      ENV['S3_SECRET_ACCESS_KEY'] = 'oblongata'
      s3 = Gridium::GridiumS3.new(project_name, subdirectory_name)
      s3.save_file(@full_path)
    end

  end
end
