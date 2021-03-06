''****************************************
''*  AR1010 Demo                         *
''*  Authors: Nikita Kareev              *
''*  See end of file for terms of use.   *
''****************************************
''
'' Arioha AR1010 demo program
'' Tunes to different stations (Moscow radio -- modify TestStations in DAT section for your local radio)
'' Tested on this module: http://www.sparkfun.com/commerce/product_info.php?products_id=8770
''
'' Updated... 14 JUN 2009
''
CON 

  ' Processor Settings
  _clkmode = xtal1 + pll16x     'Use the PLL to multiple the external clock by 16
  _xinfreq = 5_000_000          'An external clock of 5MHz. is used (80MHz. operation)

  ' I2C definitions
  _I2C_SCL        = 14
  _I2C_SDA        = 15     

  _AR1010_ADDR = %0010_0000
  
OBJ 

  RADIO : "AR1010"                                      'AR1010
  TIME  : "Clock"                                       'Clock
  SER   : "FullDuplexSerialPlus"                        'Serial port

PUB Init | idx

  'Initialize clock object
  TIME.Init(5_000_000)

  'Initialize serial (use Parallax Debug Terminal for feedback)
  SER.start(31, 30, 0, 57600)
  waitcnt(clkfreq*2 + cnt)
  SER.tx(SER#CLS)

  SER.str(String("Init started..."))
  SER.str(String(SER#CR)) 
  
  'Initialize radio
  RADIO.Init(_AR1010_ADDR, _I2C_SCL, _I2C_SDA)

  SER.str(String("Inited!"))
  SER.str(String(SER#CR))
  
  RADIO.SetFrequency(TestStations[5])
  TIME.PauseMSec(3000)
  SER.str(String("Volume: "))
  SER.dec(21)
  SER.str(String(SER#CR))  
  RADIO.SetVolume(21)
  TIME.PauseMSec(3000)
  RADIO.SetVolume(15)
  SER.str(String("Volume: "))
  SER.dec(15)
  SER.str(String(SER#CR))  
  TIME.PauseMSec(3000)
  SER.str(String("Muted!"))
  SER.str(String(SER#CR))
  RADIO.Mute(true)
  TIME.PauseMSec(3000)
  SER.str(String("UnMuted!"))
  SER.str(String(SER#CR))
  RADIO.Mute(false)

  idx := 0
  
  repeat
    SER.str(String("Frequency: "))
    SER.dec(TestStations[idx])
    SER.str(String(SER#CR))  
    RADIO.SetFrequency(TestStations[idx])
    TIME.PauseMSec(3000)
    idx += 1
    if idx == 21
      idx := 0


  'SER.str(String("Original hex: ")) 
  'SER.hex(Regs[0], 4)
  'SER.str(String(SER#CR))
  'SER.str(String("First part: "))
  

DAT

TestStations long 1005, 1066, 903, 891, 1012, 1062, 1037, 1034, 1021, 1078, 1017, 887, 1025, 1047, 883, 1057, 107, 1001, 1052, 1074, 103, 1042, 912

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