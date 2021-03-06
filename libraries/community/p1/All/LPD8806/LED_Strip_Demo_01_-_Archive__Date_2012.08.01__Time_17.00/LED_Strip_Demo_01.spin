{{LED_Strip_Demo_01.spin

#######################################
#                                     #
# Copyright (c) 2012 Fredrik Safstrom #
#                                     #
# See end of file for terms of use.   #
#                                     #
#######################################


############################# DESCIPTION ########################

This is a demo for the LED Strip from adafruit.com
https://www.adafruit.com/products/306

This is my adaptation of the Arduino demo...


########################### PIN ASSIGNMENTS #####################

  P0  - DAT
  P1  - CLK 

########################### REVISIONS ###########################

1.0 Got to start somewhere...

}}

CON
        _clkmode        = xtal1 + pll16x
        _xinfreq        = 5_000_000

        '' Assign pins and number of LEDs on Strip
        DAT_PIN = 0
        CLK_PIN = 1
        NUM_LED = 64

OBJ

        '' Decalre driver
        LPD8806_Driver : "LPD8806_20120731"

VAR

        '' The driver takes an array of longs for the LED data.
        long LED_Data[NUM_LED]
        long i, j

PUB Main

    ' Start driver and pass pointer to array.
    LPD8806_Driver.start(CLK_PIN, DAT_PIN, NUM_LED, @LED_Data)  


    ' Clear LEDs
    LPD8806_Driver.clear

    '' Color chase
    ColorChase( LPD8806_Driver.rgbColor(127, 127, 127) )  
    ColorChase( LPD8806_Driver.rgbColor(127, 0, 0) )  
    ColorChase( LPD8806_Driver.rgbColor(127, 127, 0) )  
    ColorChase( LPD8806_Driver.rgbColor(0, 127, 0) )  
    ColorChase( LPD8806_Driver.rgbColor(0, 127, 127) )  
    ColorChase( LPD8806_Driver.rgbColor(0, 0, 127) )  
    ColorChase( LPD8806_Driver.rgbColor(127, 0, 127) )  
    ColorChase( LPD8806_Driver.rgbColor(100, 20, 20) )  

    '' Rainbow
    Rainbow     

    '' ColorWipe
    ColorWipe( LPD8806_Driver.rgbColor(127, 127, 127) )  
    ColorWipe( LPD8806_Driver.rgbColor(127, 0, 0) )  
    ColorWipe( LPD8806_Driver.rgbColor(127, 127, 0) )  
    ColorWipe( LPD8806_Driver.rgbColor(0, 127, 0) )  
    ColorWipe( LPD8806_Driver.rgbColor(0, 127, 127) )  
    ColorWipe( LPD8806_Driver.rgbColor(0, 0, 127) )  
    ColorWipe( LPD8806_Driver.rgbColor(127, 0, 127) )  
    ColorWipe( LPD8806_Driver.rgbColor(100, 20, 20) )  

    '' Do the Rainbow forever...
    repeat
      rainbowCycle

PUB ColorChase(color)

      repeat i from 0 to NUM_LED-1
        LED_Data[i]:= color  
        waitcnt(clkfreq/150 + cnt)   
        LED_Data[i]:= 0  

PUB ColorWipe(color)

      repeat i from 0 to NUM_LED-1
        LED_Data[i]:= color  
        waitcnt(clkfreq/150 + cnt)   


PUB rainbow  

    repeat j from 0 to 384
      repeat i from 0 to NUM_LED-1
        LED_Data[i]:= Wheel((i+j) // 384)  
        waitcnt(clkfreq/1000 + cnt)


PUB rainbowCycle  

    repeat j from 0 to 384*5
      repeat i from 0 to NUM_LED-1
        LED_Data[i]:= Wheel(((i * 384 / NUM_LED) + j) // 384)  

        

PUB Wheel(WheelPos) : color | r, g, b, switch

  switch := WheelPos / 128

  case switch

    0:
      r := 127 - (WheelPos // 128)
      g := WheelPos // 128
      b := 0

    1:
      g := 127 - (WheelPos // 128)
      b := WheelPos // 128
      r := 0

    2:
      b := 127 - (WheelPos // 128)
      r := WheelPos // 128
      g := 0

  color := LPD8806_Driver.rgbColor(r, g, b)

DAT

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