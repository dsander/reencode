class Reencode
  def self.work(options)
    Dir.glob(File.join(options[:path], '/**/*.{mkv,avi,mp4}')).sort.each do |f|
      path = f.gsub(options[:path], '').split('/').first
      begin
        file = MediaFile.new(f)
        next if file.hevc || file.failed?
        next unless file.worthit?
        next if file.mtime > (Time.now - (30*24*3600)).to_i

        c = Command.new(file, hardware_decode: options['hardware_decode'])
        next if File.exist?(c.destination)

        Reencode.shell.say File.basename(f), :green
        Reencode.shell.say "  Estimations:", :yellow
        Reencode.shell.say "    Freed space  : #{Reencode.kb_to_human(file.size - file.guessed_size)}"
        Reencode.shell.say "    Encoding time: #{file.guessed_encoding_time.to_i} seconds"

        yield file, c if block_given?

        if $stopping
          c.cleanup!
          break
        end
      rescue StandardError => e
        c.cleanup! if c
        Reencode.shell.say "Error processing '#{f}':", :red
        Reencode.shell.say e.message
        Reencode.shell.say e.backtrace.join("\n")
        break if $stopping
      end
    end
  end

  def self.shell
    @shell ||= Thor::Shell::Color.new
  end

  def self.kb_to_human(kb)
    ActiveSupport::NumberHelper.number_to_human_size(kb.kilobyte)
  end
end
