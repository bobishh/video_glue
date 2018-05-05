require 'video_glue/workers/image_glue'
require 'video_glue/workers/video_glue'

module VideoGlue
  # manages workers and kicks off jobs
  class Observer
    attr_reader :workdir

    def initialize(workdir)
      @scandir = workdir
      @workdir = "#{workdir}/videos"
      @processing = []
      init_workers
    end

    def start
      loop do
        scan_images
        sleep(5)
      end
    end

    def init_workers
      @video_worker = Workers::VideoGlue.new(workdir)
      @image_worker = Workers::ImageGlue.new(workdir, @video_worker) do
        @processing.delete(first, second)
      end.start
    end

    private

    def scan_images
      puts "Scanning #{@scandir} ..."
      new_images.sort.map do |image|
        @image_worker.image_published(image)
        @processing << image
        sleep(0.2)
      end
    end

    def new_images
      Dir.glob("#{@scandir}/*.jpg") - @processing
    end
  end
end
