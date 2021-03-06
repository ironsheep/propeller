{{
*****************************************
* Very Basic I2C Read/Write        v1.0 *
* Author: Beau Schwabe                  *
* Copyright (c) 2009 Parallax           *
* See end of file for terms of use.     *
*****************************************

 History:
          Version 1 - (04-08-2007) initial concept

Works with:

24LC256
24LC512
           
}}

CON
   SCL      = 28                          ' I2C Clock Pin                 
   SDA      = 29                          ' I2C Data Pin
   CONTROL  = $A0                         ' I2C EEPROM Device Address

PUB Initialize                            ' An I2C device may be left in an
    outa[SCL] := 1                        ' invalid state and may need to be
    dira[SCL] := 1                        ' reinitialized.  Drive SCL high.
    dira[SDA] := 0                        ' Set SDA as input
    repeat 9
      outa[SCL] := 0                      ' Put out up to 9 clock pulses
      outa[SCL] := 1
      if ina[SDA]                         ' Repeat if SDA not driven high
         quit                             '  by the EEPROM

PUB Start                                 ' SDA goes HIGH to LOW with SCL HIGH
    outa[SCL]~~                           ' Initially drive SCL HIGH
    dira[SCL]~~
    outa[SDA]~~                           ' Initially drive SDA HIGH
    dira[SDA]~~
    outa[SDA]~                            ' Now drive SDA LOW
    outa[SCL]~                            ' Leave SCL LOW
  
PUB Stop                                  ' SDA goes LOW to HIGH with SCL High
    outa[SCL]~~                           ' Drive SCL HIGH
    outa[SDA]~~                           '  then SDA HIGH
    dira[SCL]~                            ' Now let them float
    dira[SDA]~                            ' If pullups present, they'll stay HIGH

PUB Write(data) : ackbit
    ackbit := 0 
    data <<= 24
    repeat 8                              ' Output data to SDA
       outa[SDA] := (data <-= 1) & 1
       outa[SCL]~~                        ' Toggle SCL from LOW to HIGH to LOW
       outa[SCL]~
    dira[SDA]~                            ' Set SDA to input for ACK/NAK
    outa[SCL]~~
    ackbit := ina[SDA]                    ' Sample SDA when SCL is HIGH
    outa[SCL]~                     
    outa[SDA]~                            ' Leave SDA driven LOW
    dira[SDA]~~

PUB Read(ackbit): data
    data := 0
    dira[SDA]~                            ' Make SDA an input
    repeat 8                              ' Receive data from SDA
      outa[SCL]~~                         ' Sample SDA when SCL is HIGH
      data := (data << 1) | ina[SDA]
      outa[SCL]~
    outa[SDA] := ackbit                   ' Output ACK/NAK to SDA
    dira[SDA]~~
    outa[SCL]~~                           ' Toggle SCL from LOW to HIGH to LOW
    outa[SCL]~
    outa[SDA]~                            ' Leave SDA driven LOW

PUB ByteWrite(Address,Data)
    Start                                 ' Send Start Bit
    Write(CONTROL)                        ' Send Control Byte
    Write(Address>>8)                     ' Send Address HIGH Byte
    Write(Address&$FF)                    ' Send Address LOW Byte
    Write(Data)                           ' Send Data Byte
    Stop                                  ' Send Stop Bit
    waitcnt((clkfreq/1_000_000)*10000+cnt)' Wait 5ms for memory to write

PUB RandomRead(Address)
    Start                                 ' Send Start Bit
    Write(CONTROL)                        ' Send Control Byte
    Write(Address>>8)                     ' Send Address HIGH Byte
    Write(Address&$FF)                    ' Send Address LOW Byte
    Start                                 ' Send Start Bit
    Write(CONTROL|1)                      ' Send Control Byte
    Result := Read(0)                     ' Read Data Byte
    Stop                                  ' Send Stop Bit
    
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