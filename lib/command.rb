class Command
  attr_reader :file, :output, :fps, :frame, :speed
  attr_accessor :gpu

  def initialize(file, hardware_decode:)
    @hardware_decode = hardware_decode
    @file = file
    @speed = @fps = @frame = 0
  end

  def command
    "ffmpeg -y #{hardware_decode} -i #{source.shellescape} -map_chapters -1 -vcodec hevc_nvenc -gpu #{gpu} -profile:v main10 -preset hq -2pass 1 -vb #{file.bitrate}k -rc vbr_hq #{ten_bit} -rc-lookahead 32 -c:a libfdk_aac -vbr 3 #{destination.shellescape}"
  end

  def source
    file.path
  end

  def gpu
    return 'any' unless @gpu
    @gpu
  end

  def destination
    File.basename(file.path)
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
    @process = Komenda.create(command)
    @process.on(:output) { |o| handle(o) }

    result = nil
    time = Benchmark.realtime do
      result = @process.run
    end

    unless result.success?
      file.failed! unless @killed
      cleanup!
    end

    [result.success?, time]
  end

  def handle(output)
    @output ||= ""
    @output += output
    if m = output.match(/frame=\s*(?<frame>\d+).+?fps=\s*(?<fps>\d+).+?speed=\s*(?<speed>\d+.\d+).+?/)
      @frame = m[:frame].to_i
      @fps = m[:fps].to_i
      @speed = m[:speed].to_f
    end
  end

  def kill
    @killed = true
    @process.kill
  end

  def cleanup!
    FileUtils.rm(destination) if File.exist?(destination)
    file.unlock!
  end
end
