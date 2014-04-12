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
# header size not incl., so + 10 bytes
class Array
  def to_id3_size
    self.map {|byte| "%07b" % byte}.join('').to_i(2) + 10
  end
end

id3_size = id3_header[6..9].to_id3_size
puts "id3 byte size: " + id3_size.to_s

# this is the whole id3 tag
id3_tag = file[0...id3_size]

class Id3Frame
  attr_accessor :header, :ident, :size, :body
  def self.from_bytes(bytes)
    frame = self.new(bytes)
    return frame if frame.ident.match /[A-Z0-9]{4}/
    return nil
  end
  def initialize(bytes)
    @header = bytes[0..9]
    @ident  = header[0..3].pack('C*')
    @size   = header[4..7].to_id3_size
    @body   = bytes[0...(size+10)]
  end
end

id3_frames = []
rem_bytes = id3_tag[10..-1]
while rem_bytes
  new_frame = Id3Frame.from_bytes(rem_bytes)
  break unless new_frame
  id3_frames << new_frame
  rem_bytes = rem_bytes[new_frame.size..-1]
end

puts "num of id3_frames: #{id3_frames.count}"
puts "id3 identifiers: #{id3_frames.map(&:ident).join(', ')}"

# this is everything after the id3 tag
body = file[id3_size..-1]

class Mp3Frame
  attr_accessor :header, :header_bin, :version, :layer, :bitrate
  attr_accessor :sampling, :padding, :channel, :size
  def self.from_bytes(bytes)
    frame = self.new(bytes)
    return frame if frame.sync_bits_good?
    return nil
  end
  def sync_bits_good?
    # checking first 11 bits are 1s
    header_bin[0..10].to_i(2) == 2047
  end
  def initialize(bytes)
    @header = bytes[0..3]
    # doing bit-checks like this feels kinda bad.
    @header_bin = header.map {|byte| "%08b" % byte}.join('')
    @version =  MPEG_VERSION[header_bin[11..12].to_i(2)]
    @layer =      MPEG_LAYER[header_bin[13..14].to_i(2)]
    @crc =                   header_bin[15].to_i(2)
    @bitrate = MP2L3_BITRATE[header_bin[16..19].to_i(2)]
    @sampling =   MP2_SAMPLE[header_bin[20..21].to_i(2)]
    @padding =               header_bin[22].to_i(2)
    @channel =       CHANNEL[header_bin[24..25].to_i(2)]
    # http://www.datavoyage.com/mpgscript/mpeghdr.htm says:
    #   1152 samples per frame in layer 3
    #   bits-per-second / samples-per-second gives bits-per-sample
    #   1152 * bits-per-sample = bits-per-frame
    #   bits-per-frame / 8 + padding gives bytes-per-frame
    #   truncates down
    # looking at other source code, looks like mp2l3, mp2.5l3 frames
    # are half that size.
    @size = ((72000.0*bitrate)/sampling + padding).to_i
  end
end

first_frame = Mp3Frame.from_bytes body

puts
puts "first frame header: #{first_frame.header.ary_to_hex}"
puts "MPEG Version #{first_frame.version}, Layer #{first_frame.layer}"
puts "bitrate: #{first_frame.bitrate}kbps"
puts "sampling rate: #{first_frame.sampling}Hz"
puts "padding: #{first_frame.padding} bytes"
puts "channel: #{first_frame.channel}"
puts "frame size: #{first_frame.size}"

frame_bytes = first_frame.size
puts "id3 + first frame size = #{id3_size + frame_bytes}"

puts "next frame: #{body[frame_bytes-2..frame_bytes+2].ary_to_hex}"

mp3_frames = [first_frame]
rem_bytes = body[first_frame.size..-1]
while rem_bytes
  new_frame = Mp3Frame.from_bytes(rem_bytes)
  break unless new_frame
  mp3_frames << new_frame
  rem_bytes = rem_bytes[new_frame.size..-1]
end

puts
puts "num of mp3_frames: #{mp3_frames.count}"
puts "at 38fps, that's #{mp3_frames.count / 38.0} seconds"
puts "bytes remaining: #{rem_bytes.count}"
