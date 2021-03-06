''*******************************************************************
''*  v1.2                                                           *
''*  Author : Hugh Neve                                             *
''*  See end of file for terms of use.                              *
''*******************************************************************

'Driver for the 4 figure, seven segment 0.8" LED sold by Embedded Adventures
' (e.g. http://www.embeddedadventures.com/4_digit_7_segment_led_display_dsp-7s04b-yellow.html)
' Quick and dirty driver to get people up and running with displaying numbers

{{Connection Diagram:

┌─────────────────┐                ┌──────────────┐
│  Prop circuit   │                │     LED      │
│             +5V ├────────────────┤VCC           │
│             VSS ├────────────────┤GND           │
│          Pin_TX ├────────────────┤RX            │
└─────────────────┘           N/C ─┤TX            │
                                   └──────────────┘

Call 'Start' and then other methods from a higher-level object

}}
 
CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
  Pin_TX   = 23                                         ' Output pin for the LED
VAR
    'No variables                 
OBJ
  Seg7      :  "FullDuplexSerial"                       ' http://obex.parallax.com/object/247             

PUB Start
  seg7.start(-1, Pin_TX, 0, 115_200)                     ' Starts the serial communications on the specified pin.
       
PUB setBrightness(n)                                    ' Sets the brightness between 0 (very dim) and 255 (full brightness)
                                                        ' NB: this only works once (after power on) and cannot be changed subsequently
  seg7.str(string("level "))
  seg7.dec(n)
  
PUB printNumber(n)                                      ' Prints the number 'n' on the display

  seg7.str(string("print "))
  sendComma
  seg7.dec(n)                                           ' If padding with spaces is required use the decf() method in the Simple_Numbers object, http://obex.parallax.com/object/536.
  sendComma
  sendCR

PUB testLED                                                 'NB: this only works once (after power on) and cannot be re-run

  seg7.str(string("test"))
  sendCR
  
PUB sendComma                                            ' Sends a comma (ASCII 34) to the LED

  seg7.tx(34)
  
PUB sendCR                                               ' Sends a carriage return (ASCII 13) to the LED
  seg7.tx(13)

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