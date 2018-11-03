class Gpus < Array
  class Encoder
    attr_reader :id, :name, :file, :c

    def initialize(id:, name:)
      @id = id
      @name = name
    end

    def join
      return unless @thread
      @thread.join
    end

    def kill
      c.kill
    end

    def run(file, c, options)
      @file = file
      @c = c
      @thread = Thread.new do
        c.gpu = id
        (success, time) = c.execute
        yield file, c, success, time
        @file = @c = nil
      end
    end
  end

  def initialize
    super
    get_config
  end

  def join
    each(&:join)
  end

  def kill
    each(&:kill)
  end

  def status
    each do |e|
      next if e.file.nil?
      Reencode.shell.say "      #{File.basename(e.file.path)} gpu: #{e.id} fps: #{e.c.fps} frame: #{e.c.frame} speed: #{e.c.speed}"
    end
  end

  def get
    while true
      if encoder = find { |e| e.file.nil? }
        return encoder
      end
      sleep 0.25
    end
  end

  def get_config
    output = `ffmpeg -f lavfi -i nullsrc -c:v hevc_nvenc -gpu list -f null - 2>&1`
    output.scan(/\[hevc_nvenc @ .+?\] \[ GPU #(\d+) - < (.+?) > has Compute SM 6.1 \]/).each do |m|
      encoder_count(m[1]).times do
        self << Encoder.new(id: m[0].to_i, name: m[1])
      end
    end
  end

  def encoder_count(name)
    return 2 if name == 'GeForce GTX 1080 Ti'
    1
  end
end
