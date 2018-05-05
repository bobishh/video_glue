require 'digest'
require 'concurrent'

module VideoGlue
  module Workers
    class VideoGlue
      attr_reader :process

      def initialize(working_path, head_file = nil)
        @working_path = working_path
        @head_file = infer_head_file(head_file)
        @queue = Queue.new
        start_processing
      end

      def infer_head_file(file)
        return file unless file.nil?
        base = "#{@working_path}/base.mp4"
        return base if File.exist?(base)
      end

      def start_processing
        @process = Concurrent::Future.execute do
          loop do
            if video = @queue.pop
              await
              process_video(video)
            else
              sleep(0.1)
            end
          end
        end
      end

      def video_created(video)
        @queue << video
      end

      private

      def attach_to_head(video)
        path = write_to_tempfile(video)
        out = "#{@working_path}/res_#{Digest::MD5.hexdigest(video)}.mp4"
        `ffmpeg -r 30 -f concat -safe 0 -i #{path} -c copy #{out} &> /dev/null`
        FileUtils.mv(out, @head_file)
        FileUtils.rm_rf(video)
        FileUtils.rm_rf(path)
      end

      def write_to_tempfile(video)
        file = File.open "#{@working_path}/#{Digest::MD5.hexdigest(video)}_files_list.txt", 'w+'
        files = [@head_file, video]
        file.write(files.map { |p| "file '#{p}'" }.join("\n"))
        path = file.path
        file.close
        path
      end

      def await
        sleep(0.1) while @processing
      end

      def process_video(video)
        Concurrent::Future.execute do
          @processing = true
          if @head_file.nil?
            @head_file = video
          else
            attach_to_head(video)
          end
          @processing = false
        end
      end
    end
  end
end
