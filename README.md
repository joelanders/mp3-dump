I grabbed this thomasedison.mp3 file from [archive.org](https://archive.org/details/ThomasAlvaEdison-speaking). (it's public domain)
This only works for Version 2, Layer 3 right now.
Not sure what I'll do with it.

remix.mp3 is the result of grouping the frames into segments of 20
frames each, then repeating each segment three times, then writing
the file back out. I'm not really allowed to play frames out-of-order
(look up "byte reservoir"), and VLC gives errors, but it will play!


output:
```
file byte size: 40960
id3 header: 49 44 33 04 00 00 00 00 4b 06
that *is* an ID3 header
id3 byte size: 9616
num of id3_frames: 11
id3 identifiers: TIT2, TPE1, TCON, TDRC, APIC, PRIV, PRIV, TCOP, TLAN, TPUB, TXXX

first frame header: ff f2 52 50
MPEG Version 2, Layer 3
bitrate: 40kbps
sampling rate: 22050Hz
padding: 1 bytes
channel: joint stereo
frame size: 131
id3 + first frame size = 9747
next frame: 53 80 ff f2 50

num of mp3_frames: 239
at 38fps, that's 6.2894736842105265 seconds
bytes remaining: 128
```

code is MIT Licensed
