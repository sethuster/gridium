require 'aws-sdk'

module Gridium
  class GridiumS3
    def initialize(project_name, subdirectory_path='screenshots')
      Log.debug("[GRIDIUM::S3] initializing GridiumS3 with #{project_name} and #{subdirectory_path}")
      Aws.config.update({ credentials: Aws::Credentials.new(ENV['S3_ACCESS_KEY_ID'], ENV['S3_SECRET_ACCESS_KEY']) , region: ENV['S3_DEFAULT_REGION']})
      _validate_string(project_name)
      _validate_string(subdirectory_path)

      @project_name = _sanitize_string(project_name)
      @subdirectory_path = _sanitize_string(subdirectory_path)
      @bucket = Aws::S3::Resource.new.bucket(ENV['S3_ROOT_BUCKET'])
    end

    # Save local file to S3 bucket
    # @param [String] local_path
    # @return [String] s3 public url
    def save_file(local_path)
      Log.debug("[GRIDIUM::S3] attempting to save '#{local_path}' to s3")
      _validate_path(local_path)
      file_name = File.basename(local_path)
      destination_name = create_s3_name(file_name)
      begin
        @bucket.object(destination_name).upload_file(local_path)
        @bucket.object(destination_name).wait_until_exists
        _verify_upload(destination_name, local_path)
        # @bucket.object(s3_name).presigned_url(:get, expires_in: 3600) #uncomment this if public url ends up not working out OPREQ-83850
        return @bucket.object(destination_name).public_url
      rescue Aws::S3::Errors::InvalidAccessKeyId
        Log.error("[GRIDIUM::S3] unable to save file to s3 due to Aws::S3::Errors::InvalidAccessKeyId")
      rescue Seahorse::Client::NetworkingError => error
        Log.error("[GRIDIUM::S3] unable to save file to s3 due to underlying network error: #{error}")
      rescue StandardError => error
        Log.error("[GRIDIUM::S3] unable to save file to s3 due to unexpected error: #{error}")
      end
    end

    def create_s3_name(file_name)
      _validate_string(file_name)
      file_name = _sanitize_string(file_name)
      [@project_name, @subdirectory_path, file_name].join("/")
    end

    #
    # @note Strips whitespace, split and join to collapse contiguous white space,
    #       replace whitespace and special chars (not '.', '/') with an underscore
    #
    def _sanitize_string(input_string)
      input_string.strip.split.join(" ").gsub(/[^\w.\/]/i, '_')
    end

    def _validate_string(input_string)
      Log.debug("[GRIDIUM::S3] attempting to validate #{input_string} for use as a name")
      if input_string.empty? || input_string.strip.empty?
        raise(ArgumentError, "[GRIDIUM::S3] empty and/or whitespace file names are not wanted here.")
      end
    end

    def _validate_path(path_to_file)
      Log.debug("[GRIDIUM::S3]  attempting to validate #{path_to_file} as a legitimate path")
      unless File.exist? path_to_file
        raise(ArgumentError, "[GRIDIUM::S3] this path doesn't resolve #{path_to_file}")
      end
    end

    def _verify_upload(s3_name, local_absolute_path)
      upload_size = @bucket.object(s3_name).content_length
      local_size = File.size local_absolute_path
      Log.debug("[GRIDIUM::S3] file upload verified: #{upload_size == local_size}. upload size is #{upload_size} and local size is #{local_size}")
      upload_size == local_size
    end
  end
end
