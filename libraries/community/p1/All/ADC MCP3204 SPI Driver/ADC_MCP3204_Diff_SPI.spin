{{
________________________________________________________________________________________________

   File:        ADC_MCP3204_Diff_SPI.spin
   Version:     1.0
   Purpose:     SPI Driver For MCP3204 ADC, Single Ended Mode
   Author:      Zack Whitlow
                Copyright (c) 2013 Zack Whitlow
                See end of file for terms of use.
   E-mail:      zwhitlow@gmail.com
   Released:    20 DEC 2013
_________________________________________________________________________________________________
            
                              2.7-5.5 V
                  MCP3204        
            ┌─────────────────┐  │
 ch0 + ────┤1  CH0     VDD 14├──┫                
 ch0 - ────┤2  CH1    VREF 13├──┘           
 ch1 + ────┤3  CH2    AGND 12├──┐ 
 ch1 - ────┤4  CH3     CLK 11├──│──────── clk
           ─┤5  NC     DOUT 10├──│──────── miso
           ─┤6  NC      DIN  9├──│──────── mosi    
         ┌──┤7  DGND    /CS  8├──│──────── cs
         │  └─────────────────┘  │
                                                
}} 

VAR
  long  x, cog

PUB stop                        ' Stop driver - frees a cog
    if cog
       cogstop(cog)

PUB start(pin, repeats, volt0_addr, volt1_addr):okay
  cs := pin
  num_avg := repeats
  volt0 := volt0_addr
  volt1 := volt1_addr
  okay := cog := cognew(@ADC, volt1)

DAT
              org       0
ADC           mov       clk, cs                         'set pin parameters for clk, miso, and mosi
              add       clk, #1                         'clk = cs + 1   
              mov       miso, clk
              add       miso, #1                        'miso = clk + 1
              mov       mosi, miso
              add       mosi, #1                        'mosi = miso + 1
              
              shl       cs_mask, cs                     'set pin masks  
              shl       clk_mask, clk
              shl       miso_mask, miso
              shl       mosi_mask, mosi              
              
              or        pins, cs_mask                   'set mask to cs_mask
              mov       outa, pins                      'set cs pin to high
              mov       pins, #0                        'pins = 0  
              or        pins, cs_mask                   'set up mask that includes cs_mask  
              or        pins, clk_mask                  'also include clk_mask 
              or        pins, mosi_mask                 'also include mosi_mask  
              mov       dira, pins                      ' set cs, clk, and mosi pins to output             
              mov       frqa, frqconfig                 'set propeller counter to nco/pwm single ended to use for clk  
              mov       ctra, clk                       'frqa counter controls clk pin    

Manager       mov       time, cnt                       'time = cnt 
              add       time, del_short                 'add del_short to time, del_short is number of counts in half of clk period    
              waitcnt   time, #0                        'waitcnt but don't add anything to current time value
:run          mov       m, #1                           'initialize m to 1
              shl       m, num_avg                      'shift m right by num_avg bits to use as index for loop to get repeated measurements      
:repeat       mov       time, cnt                       'time = current cnt
              add       time, del_short                 'add half clk period
              waitcnt   time, del_short                 'wait half clk period and add another half clk period to time
              waitcnt   time, #0                        'wait half clk period
              mov       pak_o, ch0                      'set output data packet to value for channel 0 differential mode
              call      #ReadWrite                      'go to ReadWrite section
              and       pak_i, data_msk                 'get rid of extra bits, all but 12 LSBs. 
              add       ch0_sum, pak_i                  'add data to sum for channel 0
              mov       time, cnt                       'time = current cnt
              add       time, del_short                 'add half clk period
              waitcnt   time, del_short                 'wait half clk period and add another half period
              waitcnt   time, #0                        'wait half clk period                     
              mov       pak_o, ch1                      'set output data to value for channel 1 differential mode
              call      #ReadWrite                      'goto ReadWrite section and return when done
              and       pak_i, data_msk                 'get rid of extra bits, all but 12 LSBs.
              add       ch1_sum, pak_i                  'add to sum for channel 1
              djnz      m, #:repeat                     'decrement index and repeat loop if needed
              shr       ch0_sum, num_avg                'shift right by num_avg to divide by 2^num_avg
              shr       ch1_sum, num_avg
              wrlong    ch0_sum, volt0                  'write data to address
              wrlong    ch1_sum, volt1
              mov       ch0_sum, #0                     'reset sum to zero
              mov       ch1_sum, #0
              jmp       #:run                           'repeat

ReadWrite     mov       pak_i, #0                       'initialize input to zero   
              ror       pak_o, #4                       'roll pak_o right 4 places to transmit properly 
              mov       time, cnt                       'set time to current cnt 
              mov       outa, #0                        'set cs low for transfer 
              add       time, del_short                 'add half a clk period to time 
              mov       phsa, #0                        'reset counter to zero 
              movi      ctra, ctrconfig                 'set ctra 30...29 to ctraconfig to control clk  
              mov       n, #19                          'set loop index to 19    
:loop         shl       pak_i, #1                       'shift bits input left by one each loop
              mov       temp, #1                        'temp = 1   
              and       temp, pak_o                     'shift temp left to use as mask for mosi pin  
              shl       temp, mosi                      'shift left to mosi pin
              mov       outa, temp                      'set mosi pin to output temo (ie high or low dependent on pak_o)    
              rol       pak_o, #1                       'rol output bits left by one 
              waitcnt   time, del_short                 'wait for half clk period   
              mov       temp, ina                       'set temp to ina register to read pins  
              and       temp, miso_mask                 'and with miso_mask to read value of miso pin  
              shr       temp, miso                      'shift value of miso (1 or 0) right to lsb   
              or        pak_i, temp                     'include bit value in pak_i, ie input data   
              waitcnt   time, del_short                 'wait half a clk period      
              djnz      n, #:loop                       'decrement n and loop again if not zero    
              movi      ctra, #0                        'set ctra 30...29 to zero to turn off counter    
              mov       outa, cs_mask                   'set cs back to high to end transmission 
ReadWrite_ret ret                                       'go back to where section was called   

volt0         long  0
volt1         long  0
ch0_sum       long  0
ch1_sum       long  0
num_avg       long  0
cs            long  0
clk           long  0
miso          long  0
mosi          long  0          
cs_mask       long  1
clk_mask      long  1
miso_mask     long  1
mosi_mask     long  1

ch0           long  %10000
ch1           long  %10010
pins          long  0
pak_o         long  0
pak_i         long  0
n             long  0
m             long  0
ctrconfig     long  %0_00100_000
frqconfig     long  42949673                    '42949673 -> sample freq = 40 kHz = prop_clk_spd/(2*del_short)/(clk periods per transmission+1, ie 20) 
del_short     long  50                          '50 -> sample freq = 40 Hz  
time          long  0
temp          long  0
data_msk      long  %111111111111


{{

┌────────────────────────────────────────────────────────────────────────┐
│                        TERMS OF USE: MIT License                       │                                                            
├────────────────────────────────────────────────────────────────────────┤
│  Permission is hereby granted, free of charge, to any person obtaining │
│ a copy of this software and associated documentation files (the        │ 
│ "Software"), to deal in the Software without restriction, including    │
│ without limitation the rights to use, copy, modify, merge, publish,    │
│ distribute, sublicense, and/or sell copies of the Software, and to     │
│ permit persons to whom the Software is furnished to do so, subject to  │
│ the following conditions:                                              │
│                                                                        │
│  The above copyright notice and this permission notice shall be        │
│ included in all copies or substantial portions of the Software.        │  
│                                                                        │
│  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND        │
│ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     │
│ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. │
│ IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   │
│ CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   │
│ TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      │
│ SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 │
└────────────────────────────────────────────────────────────────────────┘
}}  