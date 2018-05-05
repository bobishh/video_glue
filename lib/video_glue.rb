$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'video_glue/observer.rb'

module VideoGlue
  def self.start(working_path)
    Observer.new(working_path).start
  end
end
