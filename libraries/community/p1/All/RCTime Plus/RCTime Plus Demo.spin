CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  RCPIN = 25                   ' pin to use
  RCSTATE = 1                  ' the state to use (see RCTIME documentation)

  Capacity = 1.1e-6            ' 1.1 µF  -  substitute the value of your capacitor

  SampleSize = 1               ' # Measurements

  foreground = true

OBJ
  debug : "fullDuplexSerialPlus"
  RC    : "RCTIME Plus"
  fs    : "FloatString"

PUB main | RCValue 

  Debug.start(31, 30, 0, 57600)
  rc.Pause1ms(5000)
  debug.str(string("Start",13))

  if NOT foreground
      RC.startRC(Capacity,RCPIN,RCSTATE, @RCValue)
      debug.str(string("Started",13))
     
      repeat
        rc.Pause1ms(1000)
        debug.str(string("Background: "))
        debug.str(fs.FloatToMetric(RCValue,0))
        debug.str(string(13))
  else  
    repeat
      debug.str(string("Foreground: "))
      debug.str(fs.FloatToMetric(RC.getRCvalue(Capacity,RCPIN,RCSTATE,SampleSize),0))
      debug.str(string(13))
      rc.Pause1ms(500)
       
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