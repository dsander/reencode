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
