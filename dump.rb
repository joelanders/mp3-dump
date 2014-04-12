#!/bin/env ruby

require './mp3_spec.rb'

public
def ary_to_hex
  self.map {|byte| "%02x" % byte}.join(' ')
end

#puts ARGV.first
#file = IO.read(ARGV.first).bytes.to_a
file = IO.read('thomasedison.mp3').bytes.to_a
puts "file byte size: " + file.count.to_s

id3_header = file[0..9]
puts "id3 header: " + id3_header.ary_to_hex

if id3_header[0..2].pack('C*') == 'ID3'
  puts "that *is* an ID3 header"
else
  puts "that *is not* an ID3 header"
  exit
end

# most sig. bit in each byte is 0 and ignored
# tag header size not incl., so + 10 bytes
id3_size = id3_header[6..9].map {|byte| "%07b" % byte}.join('').to_i(2) + 10
puts "id3 byte size: " + id3_size.to_s

# this is everything after the id3 tag
body = file[id3_size..-1]

frame_header_ary = body[0..3]
puts
puts "first frame header: " + frame_header_ary.ary_to_hex

# doing bit-checks like this feels kinda bad.
frame_header_bin = frame_header_ary.map {|byte| "%08b" % byte}.join('')

# checking the first 11 bits are 1s
if frame_header_bin[0..10].to_i(2) == 2047
  puts "the sync bits are in place"
else
  puts "the sync bits are not in place"
  exit
end

mpeg_version = frame_header_bin[11..12].to_i(2)
print "MPEG Version " + MPEG_VERSION[mpeg_version]

mpeg_layer = frame_header_bin[13..14].to_i(2)
puts ", Layer " + MPEG_LAYER[mpeg_layer]

crc_protected = frame_header_bin[15]

bit_key = frame_header_bin[16..19].to_i(2)
bitrate = MP2L3_BITRATE[bit_key]
puts "bitrate: " + bitrate.to_s + "kbps"

samp_key = frame_header_bin[20..21].to_i(2)
sampling_rate = MP2_SAMPLE[samp_key]
puts "sampling rate: " + sampling_rate.to_s + "Hz"

# layers 2&3: this means there is an extra byte
padding = frame_header_bin[22].to_i(2)
puts "padding: #{padding} bytes"

channel_bin = frame_header_bin[24..25].to_i(2)
channel = CHANNEL[channel_bin]
puts "channel: #{channel}"

# http://www.datavoyage.com/mpgscript/mpeghdr.htm says:
#   1152 samples per frame in layer 3
#   bits-per-second / samples-per-second gives bits-per-sample
#   1152 * bits-per-sample = bits-per-frame
#   bits-per-frame / 8 + padding gives bytes-per-frame
#   truncates down
# looking at other source code, looks like mp2l3, mp2.5l3 frames
# are half that size.

frame_bytes = ((72000.0*bitrate)/sampling_rate + padding).to_i
puts "frame bytes: #{frame_bytes}"

puts "id3 + first frame size = #{id3_size + frame_bytes}"

puts "next frame: #{body[frame_bytes-2..frame_bytes+2].ary_to_hex}"
