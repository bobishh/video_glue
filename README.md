# Video glue
Watches `ENV['VIDEO_GLUE_WORKDIR']` and constantly updates an mp4 timelapse of images that appear there

Used for creating timelapses with raspberry pi

## Usage: 
1) be sure to set `VIDEO_GLUE_WORKDIR` environment variable
2) cd into `video_glue` directory
3) `bundle install`
4) `bundle exec ruby bin/video_glue.rb start|stop|restart`  (`--help` or `-h` for more)

## TODO:
+ Write specs
+ Write logs to file
+ Refactor
+ Tune for batch image processing
+ Turn into a gem(?)
