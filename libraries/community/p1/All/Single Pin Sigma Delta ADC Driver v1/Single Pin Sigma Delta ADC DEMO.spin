{{
*****************************************
* Single Pin Sigma Delta DEMO        v1 *
* Author: Beau Schwabe                  *
* Copyright (c) 2013 Parallax           *
* See end of file for terms of use.     *
*****************************************


 History:
                            Version 1 - 07-16-2013      initial release


Schematic:                            

                                          Vdd
                                           
              2.2k                         │      Note: Potentiometers are ideal for this type of ADC
          ┌─────────── Analog Input ── 10k
          │   1k                           │
IO Pin ──┻───────┐                      
                   0.047uF             Vss
                    
                   Vss

              
Theory of Operation:
 
A key feature with this sigma-delta ADC is that the drive pin is only an output for a brief amount of time, while the
remainder of the time it is an input and used as the feedback pin.  A Typical Sigma Delta configuration will have the
Drive pin always set as an output and driven either HIGH or LOW while another pin is always an input and used as
Feedback.  This technique combines the two methods so that only one pin is necessary.
                            

}}                            

CON

_CLKMODE = XTAL1 + PLL16X
_XINFREQ = 5_000_000

OBJ

PST             : "Parallax Serial Terminal"
SD_ADC          : "Single Pin Sigma Delta ADC Driver v1"

VAR

long    ADC_Sample

PUB start
    PST.Start(19200{<- Baud})

   'SD_ADC.Start(ADCpin,ADCsamples,VariableAddress)
    SD_ADC.Start(0,8191,@ADC_Sample)

    repeat
      PST.dec(ADC_Sample)
      PST.Char(13{<- Return character})


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