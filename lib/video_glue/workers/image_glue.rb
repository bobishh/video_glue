require 'digest'
require 'concurrent'

module VideoGlue
  module Workers
    class ImageGlue
      class ImagesProcessingTask
        def self.call(first, second, working_path, &block)
          new(working_path, first, second).call(block)
        end

        def initialize(working_path, first, second)
          @first = first
          @second = second
          @working_path = working_path
          FileUtils.mkdir_p(working_path) unless File.exist?(working_path)
        end

        def output_filename
          @output_filename ||= begin
                                 hex = Digest::MD5.hexdigest("#{@first},#{@second}")
                                 "#{@working_path}/#{hex}.mp4"
                               end
        end

        def input_files_param
          [@first, @second].map { |item| "-i #{item}" }.join ' '
        end

        def call(block)
          @process = Concurrent::Future.execute do
            `ffmpeg -r 30 #{input_files_param} -c:v libx264 -f mp4 #{output_filename} &> /dev/null`
            block.call(output_filename)
          end
          self
        end
      end

      def initialize(working_path, video_worker, &on_finish)
        @on_finish = on_finish
        @working_path = working_path
        @video_worker = video_worker
      end

      def start
        @on = true
        @process = Concurrent::Future.execute do
          while @on && first = queue.pop
            second = queue.pop
            while second.nil? do
              sleep(0.1)
              second = queue.pop
            end
            process_images(first, second)
          end
        end
        self
      end

      def queue
        @queue ||= Queue.new
      end

      def image_published(image)
        queue << image
      end

      def await
        sleep 0.1 while @processing
      end

      def process_images(first, second)
        @processing = true
        ImagesProcessingTask.call(first,
                                  second,
                                  @working_path) do |result|
          @video_worker.video_created(result)
          FileUtils.rm_rf(first)
          FileUtils.rm_rf(second)
          @on_finish.call(first, second)
          @processing = false
        end
      end
    end
  end
end
