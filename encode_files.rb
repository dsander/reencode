require 'pp'
require 'mediainfo'
require 'active_record'
require 'shellwords'
require 'fileutils'

=begin
CREATE TABLE media (
 id integer PRIMARY KEY,
 path string NOT NULL UNIQUE,
 mtime integer NOT NULL,
 width integer NOT NULL,
 bit_depth integer NOT NULL,
 hevc boolean NOT NULL,
 size integer NOT NULL,
 duration integer NOT NULL,
 locked boolean DEFAULT 'f',
 failed boolean DEFAULT 'f'
);
CREATE UNIQUE INDEX media_path ON media(path);
=end

ActiveRecord::Base.establish_connection(database: 'data.sqlite3', adapter: 'sqlite3')

class Medium < ActiveRecord::Base
end

Struct.new('Quality', :kbits, :bitrate)
Sd     = Struct::Quality.new(   625 + 128,    625)
Hd     = Struct::Quality.new( 1_250 + 296,  1_250)
FullHd = Struct::Quality.new( 2_500 + 296,  2_500)
FourK  = Struct::Quality.new(15_000 + 296, 15_000)

class Filecache
  extend Forwardable
  def_delegators :@medium, :size, :width, :bit_depth, :duration, :hevc, :path, :locked?, :failed?, :mtime

  def initialize(f)
    stat = File.stat(f)

    @medium = Medium.find_or_initialize_by(path: f)
    unless @medium.mtime && @medium.mtime == stat.mtime.utc.to_i
      m = Mediainfo.new(f)
      @medium.width     = m.video.width
      @medium.bit_depth = m.video.streams.map { |s| s['bit_depth']}.sort.last.gsub(/\D/, '').to_i
      @medium.hevc      = m.video.streams.map(&:format).include?("HEVC")
      @medium.duration  = m.duration
      @medium.size      = stat.size / 1000.0
      @medium.mtime     = stat.mtime.utc.to_i
      @medium.save!
    end
  end

  def lock!
    @medium.transaction do
      @medium.reload
      return false if @medium.locked?
      @medium.update_attributes(locked: true)
    end
  end

  def unlock!
    @medium.update_attributes(locked: false)
  end

  def failed!
    @medium.update_attributes(failed: true)
  end
end

class MediaFile
  extend Forwardable
  def_delegators :@type, :kbits, :bitrate
  def_delegators :@file_cache, :size, :width, :bit_depth, :duration, :hevc, :path, :lock!, :unlock!, :failed?, :failed!, :mtime

  def initialize(f)
    @file_cache = Filecache.new(f)
    @type = type
  end

  def guessed_size
    (duration / 1_000.0) * kbits / 8
  end

  def worthit?
    size - guessed_size > 100_000
  end

  def saved
    size - guessed_size
  end

  def guessed_encoding_time
    (duration / 1_000.0) * 25.0 / 200.0
  end

  def type
    if width > 1920
      FourK
    elsif width > 1280
      FullHd
    elsif width > 768
      Hd
    else
      Sd
    end
  end
end

class Command
  attr_reader :file

  def initialize(file)
    @file = file
  end

  def command
    "ffmpeg -y #{hardware_decode} -i #{source} -vcodec hevc_nvenc -profile:v main10 -preset hq -2pass 1 -vb #{file.bitrate}k -rc vbr_2pass #{ten_bit} -rc-lookahead 32 -c:a libfdk_aac -vbr 3 #{destination} 2>&1"
  end

  def source
    file.path.shellescape
  end

  def destination
    File.basename file.path
  end

  def hardware_decode
    file.bit_depth == 8 && !(ARGV[2] == 'nohw') ? '-hwaccel cuvid -c:v h264_cuvid' : ''
  end

  def ten_bit
    file.bit_depth == 10 ? '-pix_fmt yuv420p10' : ''
  end

  def execute
    output = `#{command}`

    unless $?.success?
      puts "PROCESSING FAILED:"
      puts output
      file.failed!
      cleanup!
    end
    $?.success?
  end

  def cleanup!
    FileUtils.rm(destination) if File.exist?(destination)
    file.unlock!
  end
end

@stopping = false

%w(INT TERM QUIT).each do |signal|
  Signal.trap(signal) { @stopping = true }
end

time = 0
saved = 0

Dir.glob(File.join(ARGV[0], '/**/*.{mkv,avi,mp4}')).sort.each do |f|
  path = f.gsub(ARGV[0], '').split('/').first
  begin
    file = MediaFile.new(f)
    next if file.hevc || file.failed?
    next unless file.worthit?
    next if file.mtime > (Time.now - (30*24*3600)).to_i

    c = Command.new(file)
    next if File.exist?(c.destination)

    puts File.basename(f)
    if ARGV[1] == 'encode'
      next unless file.lock!
      c.execute
      file.unlock!
    end

    time += file.guessed_encoding_time
    saved += file.size - file.guessed_size

    if @stopping
      c.cleanup!
      break
    end
  rescue StandardError => e
    c.cleanup! if c
    puts "CAUGHT AN EXCEPTION!"
    puts e.message
    pp e.backtrace
    next
  end
end
puts time / 3600.0 / 24.0
puts saved / 1_000_000
