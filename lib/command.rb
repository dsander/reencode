class Command
  attr_reader :file

  def initialize(file, hardware_decode:)
    @hardware_decode = hardware_decode
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

  def destination_size
    File.stat(destination).size / 1000.0
  end

  def hardware_decode
    file.bit_depth == 8 && @hardware_decode ? '-hwaccel cuvid -c:v h264_cuvid' : ''
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
