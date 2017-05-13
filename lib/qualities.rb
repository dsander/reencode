Struct.new('Quality', :kbits, :bitrate)
Sd     = Struct::Quality.new(   625 + 128,    625)
Hd     = Struct::Quality.new( 1_250 + 296,  1_250)
FullHd = Struct::Quality.new( 2_500 + 296,  2_500)
FourK  = Struct::Quality.new(15_000 + 296, 15_000)
