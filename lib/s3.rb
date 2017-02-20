require 'aws-sdk'
module Gridium


    class GridiumS3

        DELIMITER = "/"

        def initialize(project_name, subdirectory_name='screenshots')
            Log.debug("initializing GridiumS3 with #{project_name} and #{subdirectory_name}")
            Aws.config.update({ credentials: Aws::Credentials.new(ENV['S3_ACCESS_KEY_ID'], ENV['S3_SECRET_ACCESS_KEY']) ,region: ENV['S3_DEFAULT_REGION']})
            _validate_string(project_name)
            _validate_string(subdirectory_name)
            @project_name = _sanitize_string(project_name)
            @subdirectory_name = _sanitize_string(subdirectory_name)
            @bucket = Aws::S3::Resource.new().bucket(ENV['S3_ROOT_BUCKET'])
        end

        def save_file(absolute_path_of_file)
            Log.debug("attempting to save #{absolute_path_of_file} to s3")
            _validate_path(absolute_path_of_file)
            file_name = File.basename(absolute_path_of_file)
            destination_name = create_s3_name(file_name)
            @bucket.object(destination_name).upload_file(absolute_path_of_file)
            @bucket.object(destination_name).wait_until_exists
            _verify_upload(destination_name, absolute_path_of_file)
            # @bucket.object(s3_name).presigned_url(:get, expires_in: 3600) #uncomment this if public url ends up not working out OPREQ-83850
            @bucket.object(destination_name).public_url
        end

        def create_s3_name(file_name)
            _validate_string(file_name)
            file_name = _sanitize_string(file_name)
            joined_name = [@project_name, @subdirectory_name, file_name].join(DELIMITER)
            joined_name
        end

        def _sanitize_string(input_string)
            #remove left/right whitespace, split and join to collapse contiguous white space, replace whitespace and non-period special chars with underscore
            input_string = input_string.strip().split.join(" ").gsub(/[^\w.]/i, '_') 
            input_string
        end

        def _validate_string(input_string)
            Log.debug("attempting to validate #{input_string} for use as a name") 
            if input_string.empty? or input_string.strip().empty? then
                raise(ArgumentError, "empty and/or whitespace file names are not wanted here.")
            end
        end

        def _validate_path(path_to_file)
            Log.debug("attmepting to validate #{path_to_file} as a legitimate path")
            if not File.exist? path_to_file then
                raise(ArgumentError, "this path doesn't resolve #{path_to_file}")
            end
        end

        def _verify_upload(s3_name, local_absolute_path)
            upload_size = @bucket.object(s3_name).content_length
            local_size = File.size local_absolute_path
            Log.debug("file upload verified: #{upload_size == local_size}. upload size is #{upload_size} and local size is #{local_size}")
            upload_size == local_size            
        end
    end
end
