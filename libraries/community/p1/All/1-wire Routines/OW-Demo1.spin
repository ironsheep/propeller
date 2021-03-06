''=============================================================================
'' @file     OW-Demo1
'' @target   Propeller
''
'' Simple demo routine for DS1822 1-wire temperature sensor. Same functionality
'' as the Basic Stamp OWIN_OWOUT demo program. Uses floating point routines and
'' displays results using vga_text or tv_text.
''
''   ───OW-Demo1
''        ├──OneWire
''        ├──vga_text
''        ├──FloatString
''        └──Float32
''
'' @author   Cam Thompson, Micromega Corporation
''
'' Copyright (c) 2006 Parallax, Inc.
'' See end of file for terms of use.       
'' 
'' @version  V1.0 - July 18, 2006
'' @changes
''  - original version
''=============================================================================

CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  OW_DATA           = 0                                 ' 1-wire data pin

  SKIP_ROM          = $CC                               ' 1-wire commands
  READ_SCRATCHPAD   = $BE
  CONVERT_T         = $44

  CLS               = $00                               ' clear screen
  HOME              = $01                               ' home
  CR                = $0D                               ' carriage return
  DEG               = $B0                               ' degree symbol
  
OBJ

  term          : "vga_text"
  'term          : "tv_text"
  ow            : "OneWire"
  fp            : "FloatString"
  f             : "FloatMath"                           ' could also use Float32
  
PUB main | tempC, tempF

  term.start(16)                                        ' start VGA terminal
' term.start(12)                                        ' start TV terminal
' f.start                                               ' (required if Float32 used)

  ow.start(OW_DATA)                                     ' start 1-wire object, pin 0

  ' read temperature and update display every second
  repeat
    tempC := getTemperature                             ' get temperature in celsius
    tempF := f.FAdd(f.FMul(tempC, 1.8), 32.0)           ' fahrenheit = (celsius * 1.8) + 32 
    term.out(HOME)
    term.str(string("DS1822", CR))
    term.str(string("------", CR))
    term.str(fp.FloatToFormat(tempC, 5, 1))
    term.str(string(" ", DEG, "C", CR))
    term.str(fp.FloatToFormat(tempF, 5, 1))
    term.str(string(" ", DEG, "F", CR))
    waitcnt(cnt+clkfreq)
  
PUB getTemperature : temp
  ow.reset                                              ' send convert temperature command
  ow.writeByte(SKIP_ROM)
  ow.writeByte(CONVERT_T)

  repeat                                                ' wait for conversion
    waitcnt(cnt+clkfreq/1000*25)
    if ow.readBits(1)
      quit

  ow.reset                                              ' read DS1822 scratchpad
  ow.writeByte(SKIP_ROM)
  ow.writeByte(READ_SCRATCHPAD)
  temp := ow.readByte + ow.readByte << 8                ' read temperature
  temp := F.FDiv(F.FFloat(temp), 16.0)                  ' convert to floating point

{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}  