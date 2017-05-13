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
