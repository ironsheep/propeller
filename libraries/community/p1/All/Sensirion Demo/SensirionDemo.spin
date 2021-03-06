''=============================================================================
''
'' @file     SensirionDemo
'' @target   Propeller
''
'' Demonstration routine that displays Sensirion SHT-11 values on a VGA display.
'' Other displays can easily be used by substituting the term display object.
'' Floating point routines are used to calculate temperature, relative humidity,
'' and dewpoint according to the Sensirion datasheet and application notes.
'' All low level functions for communicating with SHT-11 are contained in the
'' Sensirion object.
''
''   ───SensirionDemo
''        ├──Sensirion
''        ├──vga_text
''        ├──FloatString
''        └──Float32
''
'' @author   Cam Thompson, Micromega Corporation 
''
'' Copyright (c) 2006 Micromega Corporation
'' See end of file for terms of use.
''       
'' @version  V1.0 - July 12, 2006
'' @changes
''  - original version
''=============================================================================

CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  SHT_DATA      = 0                                     ' SHT-11 data pin
  SHT_CLOCK     = 1                                     ' SHT-11 clock pin

  CLS         = $0                                      ' clear screen
  CR          = $D                                      ' carriage return
  Deg         = $B0                                     ' degree symbol
  
OBJ

  term          : "vga_text"
  'term          : "tv_text"
  sht           : "Sensirion"
  fp            : "FloatString"
  f             : "Float32"
  
PUB main | rawTemp, rawHumidity, tempC, rh, dewC

  term.start(16)                                        ' start VGA terminal
  'term.start(12)                                        ' start TV terminal
  f.start                                               ' start floating point object
  sht.start(SHT_DATA, SHT_CLOCK)                        ' start sensirion object

  term.out(CLS)                                         ' display title
  setColor(6)
  displayString(0,  0, string("     Sensirion SHT-11 Demo     "))
  setColor(0)

  ' read SHT-11 sensor and update display every 2 seconds
  repeat
    setColor(3)
    displayString(2, 5, string("    Sensor Values    "))
    setColor(0)
    displayString(3, 5, string("Temp:"))
    rawTemp := f.FFloat(sht.readTemperature) 
    term.str(fp.FloatToFormat(rawTemp, 5, 0))
    term.str(string("   RH:"))
    rawHumidity := f.FFloat(sht.readHumidity)
    term.str(fp.FloatToFormat(rawHumidity, 5, 0))

    setColor(3)
    displayString(5, 1, string("      Calculated Values      "))
    setColor(0)
    term.str(string(CR, "┌─────────────┬───────┬───────┐"))   
    term.str(string(CR, "│Temperature  │"))
    tempC := celsius(rawTemp)  
    term.str(fp.FloatToFormat(tempC, 5, 1))
    term.str(string(deg, "C│"))
    term.str(fp.FloatToFormat(fahrenheit(tempC), 5, 1))
    term.str(string(deg, "F│"))
    term.str(string(CR, "├─────────────┼───────┼───────┤"))   
     
    term.str(string(CR, "│Rel. Humidity│"))
    rh := humidity(tempC, rawHumidity)
    term.str(fp.FloatToFormat(rh, 5, 1))
    term.str(string("% │       │"))
    term.str(string(CR, "├─────────────┼───────┼───────┤"))   
     
    term.str(string(CR, "│Dew Point    │"))
    dewC := dewpoint(tempC, rh)
    term.str(fp.FloatToFormat(dewC, 5, 1))
    term.str(string(deg, "C│"))
    term.str(fp.FloatToFormat(fahrenheit(dewC), 5, 1))
    term.str(string(deg, "F│"))
    term.str(string(CR, "└─────────────┴───────┴───────┘"))   

    waitcnt(cnt + clkfreq * 2)
     
PUB displayString(row, col, s)
  setPosition(row, col)
  term.str(s)

PUB setPosition(row, col)
  if row => 0
    term.out($B)
    term.out(row)
  if col => 0
    term.out($A)
    term.out(col)

PUB setColor(c)
  term.out($C)
  term.out(c)
   
PUB celsius(t)
  ' from SHT1x/SHT7x datasheet using value for 3.5V supply
  ' celsius = -39.66 + (0.01 * t)
  return f.FAdd(-39.66, f.FMul(0.01, t)) 

PUB fahrenheit(t)
  ' fahrenheit = (celsius * 1.8) + 32
  return f.FAdd(f.FMul(t, 1.8), 32.0)
  
PUB humidity(t, rh) | rhLinear
  ' rhLinear = -4.0 + (0.0405 * rh) + (-2.8e-6 * rh * rh)
  ' simplifies to: rhLinear = ((-2.8e-6 * rh) + 0.0405) * rh -4.0
  rhLinear := f.FAdd(f.FMul(f.FAdd(0.0405, f.FMul(-2.8e-6, rh)), rh), -4.0)
  ' rhTrue = (t - 25.0) * (0.01 + 0.00008 * rawRH) + rhLinear
  return f.FAdd(f.FMul(f.FSub(t, 25.0), f.FAdd(0.01, f.FMul(0.00008, rh))), rhLinear)

PUB dewpoint(t, rh) | h
  ' h = (log10(rh) - 2.0) / 0.4343 + (17.62 * t) / (243.12 + t)
  h := f.FAdd(f.FDiv(f.FSub(f.log10(rh), 2.0), 0.4343), f.FDiv(f.FMul(17.62, t), f.FAdd(243.12, t)))
  ' dewpoint = 243.12 * h / (17.62 - h)
  return f.FDiv(f.FMul(243.12, h), f.FSub(17.62, h))
  
PUB printRawValues
  term.hex(sht.readStatus, 2)
  term.str(string(", "))
  term.dec(sht.readTemperature)
  term.str(string(", "))
  term.dec(sht.readHumidity)
  term.out(13)

PUB printLong(n)
  term.hex(n, 8)
  term.str(string(", "))
  term.dec(n)
  term.out(13)
      
DAT
title   byte    CR, "   Sensirion SHT-11 Readings",0

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