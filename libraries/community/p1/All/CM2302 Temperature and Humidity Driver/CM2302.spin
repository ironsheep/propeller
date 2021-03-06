{{CM2302 Device Driver
                      
┌──────────────────────────────────────────┐
│ CM2302                                   │
│ Author: James Rike                       │               
│ Copyright (c) 2020 Seapoint Software     │               
│ See end of file for terms of use.        │                
└──────────────────────────────────────────┘

   ___________________
  |                   |
  |      CM2302       |
  |                   |
  |___________________|
               
     vdd sda  nc gnd
      │   │
      │   │
      │   │
      ││ 10kΩ
         
    +5v   p5 (Propeller)  
                 
}}

CON
  _clkmode = xtal1 + pll16x    'Standard clock mode * crystal frequency = 80 MHz
  _xinfreq = 5_000_000

VAR
  byte cog
  long ThVar[4]
   
OBJ
  num   :       "Simple_Numbers"
  pst   :       "Parallax Serial Terminal"
'  dbg   :       "PASDebug"      '<---- Add for Debugger

PUB Start                       'Cog start method
    Stop                                                                   
    cog := cognew(@entry, @ThVar) + 1

'    dbg.start(31,30,@entry)     '<---- Add for Debugger
    PrintData

PUB Stop                        'Cog stop method
    if cog
        cogstop(cog~ - 1)

PUB gettempf | tf

    tf := ThVar[0] * 9 / 5 + 320
    return tf

PUB gettempC | tc
    tc := ThVar[0]

PRI PrintData  | tf, th                                                                                                
    pst.Start(115_200)

    repeat
      THVar[2] := 0                                                             'Initialize the control flag set by driver
      repeat until ThVar[2] == %0001                                            'Wait for control flag to indicate good data
        pst.char(0)
        pst.str(string("----------- Temperature & Humidity  -----------"))
        pst.NewLine
        pst.NewLine
        tf := gettempf
        if tf > 178 AND ThVar[3] == %0001
          pst.str(string("Temp:   - "))
        else
          pst.str(string("Temp:     "))
        pst.str(num.decf(tf / 10, 3))
        pst.char(".")
        pst.str(num.dec(tf // 10))
        pst.str(string(" degrees F"))
        pst.NewLine
        
        if ThVar[3] == %0001
          pst.str(string("        - "))
        else
          pst.str(string("          "))
        pst.str(num.decf(ThVar[0] / 10, 3))
        pst.char(".")
        pst.str(num.dec(tf // 10))
        pst.str(string(" degrees C"))
        pst.NewLine
        pst.str(string("Humidity: "))
        th := ThVar[1]
        pst.str(num.decf(th / 10, 3))
        pst.char(".")
        pst.str(num.dec(th // 10))
        pst.str(string(" %"))
        pst.NewLine
        waitcnt (clkfreq * 2 + cnt)

DAT

        org 0
entry

'  --------- Debugger Kernel add this at Entry (Addr 0) ---------
'   long $34FC1202,$6CE81201,$83C120B,$8BC0E0A,$E87C0E03,$8BC0E0A
'   long $EC7C0E05,$A0BC1207,$5C7C0003,$5C7C0003,$7FFC,$7FF8
'  -------------------------------------------------------------- 

'
' Test code with modify, MainRAM access, jumps, subroutine and waitcnt.
'

        rdlong sfreq, #0                        'Get clock frequency
        mov dpin, #1
        shl dpin, data_pin

read    mov Delay, sfreq
        shl Delay, #1                           'Times 2
        mov Time, cnt                           'Get current time
        add Time, Delay                         'Adjust by 2 seconds
        waitcnt Time, Delay                     '2 second settling time
        
        or outa, dPin                           'PreSet DataPin HIGH
        or dira, dPin
        
        xor outa, dPin                          'PreSet DataPin LOW [Tbe] - START

        mov Delay, mSec_Delay                   'Set Delay to 1 mSec
        mov Time, cnt                           'Get current system clock
        add Time, Delay                         'Adjust by 1 mSec
        waitcnt Time, Delay                     '1 mSec duration of START signal [Tbe]

        or outa, dPin                           'PreSet DataPin HIGH [Tgo] - RELEASE
        xor dira, dPin                          'Set DataPin to INPUT - RELEASE the bus

        waitpne dPin, dPin                      'Catch the RESPONSE [Trel] LOW
        waitpeq dPin, dPin                      'Catch the RESPONSE [Treh] HIGH
        waitpne dPin, dPin                      'Catch [Tlow]

        mov data, #0
        mov counter, #32                        'Set the loop counter for upper 32 data bits

dloop   waitpeq dPin, dPin                      'Catch the data bit
        mov beginp, cnt                         'Store the time of the leading edge
        waitpne dPin, dPin                      'Catch [Tlow]
        mov endp, cnt                           'Store the time of the trailing edge
        sub endp, beginp wc                     'Calculate pulse width in tick counts
  if_nc cmp endp, uSec_Sample wc     
  if_nc add data, #1                            'if c = 0, data bit = 1
        cmp counter, #1 wz
  if_nz shl data, #1
        djnz counter, #dloop

        mov humid, data
        mov data, #0
        mov counter, #8                         'Set the loop counter for the 8 check sum bits
        
csloop  waitpeq dPin, dPin                      'Catch the data bit
        mov beginp, cnt                         'Store the time of the leading edge
        waitpne dPin, dPin                      'Catch [Tlow]
        mov endp, cnt                           'Store the time of the trailing edge
        sub endp, beginp wc                     'Calculate pulse width in tick counts
  if_nc cmp endp, uSec_Sample wc     
  if_nc add data, #1                            'if c = 0, data bit = 1
        cmp counter, #1 wz
  if_nz shl data, #1                            'Don't shift if the last data bit
        djnz counter, #csloop        

        mov temp, humid                         'Process the data
        shr humid, #16                          'Shift the humidity data into bytes 0 + 1
        and temp, tmp_mask                      'Mask the humidity data bits
        mov chk_sum, data                       'Read in the check sum data
        and chk_sum, chk_mask

        mov th_data, temp
        and th_data, neg_mask                   'Mask the negative temp data bit from the temp data
        mov th_data+1, humid
        mov addr, par                           'Move the data to main memory
        wrlong th_data, addr
        add addr, #4
        wrlong th_data+1, addr

        mov csum+0, temp                        'Get the high byte of temperature
        shr csum+0, #8
        mov csum+1, temp                        'Get the low byter of temperature
        and csum+1, chk_mask
        mov csum+2, humid                       'Get the high byte of humidity
        shr csum+2,#8
        mov csum+3, humid                       'Get the low byte of humidity
        and csum+3, chk_mask

        add csum, csum+1                        'Add all four data bytes (temp and humidity)
        add csum, csum+2
        add csum, csum+3

        mov th_data+2, #0                       'Intialize our control flag to the hub main memory
        cmp csum, chk_sum wz                    'Check the checksum
  if_z  mov th_data+2, #1                       'If checksum equals sum of the four data bytes, set control flag
        add addr, #4                            
        wrlong th_data+2, addr                  'Write checksum flag to main memory

        mov neg_temp, temp                      'Write negative temp flag to main memory
        shr neg_temp, #15
        add addr, #4
        wrlong th_data+3, addr
        
        waitpeq dPin, dPin                      'Catch T'en going high

        noop
        jmp #read                               

dpin          long 0
data_pin      long 5                            
mSec_Delay    long 80_000
uSec_Sample   long 2_400
tmp_mask      long $FFFF
chk_mask      long $00FF
neg_mask      long $7FFF
endp          long 0
beginp        long 0
sfreq         long 0
Time          long 0
Delay         long 0 
counter       long 0
data          long 0
temp          long 0
humid         long 0
chk_sum       long 0
addr          long 0
neg_temp      long 0
th_data       long 0[4]
csum          long 0[4]
fit

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