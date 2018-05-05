require_relative '../lib/video_glue'
require 'daemons'

Daemons.run_proc('video_glue.rb') do
  VideoGlue.start(ENV['VIDEO_GLUE_WORKDIR'])
end
