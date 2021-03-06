''************************************************
''*  74HC595 16 channel servo PWM driver         *
''*  Servo_74HC595 Version 3.0                   *
''*  Original Author: Jim Miller                 *
''*  Copyright (c) 2009 Cannibal Robotics, Inc.  *
''*  See end of file for terms of use.           *
''************************************************
'
'    Generic Circuit diagram
'                                            Vcc
'                                            16
'                                         ┌──┴───┐
'   { CLK }──────┳──────────────── 11 ────┤ 74HC ├─── 15 Qa → servo PWM 1  
'   { Data}──────┼──────────────── 14 ────┤  595 ├───  1 Qb → servo PWM 2
'   {~Sclr}──────┼───┳──────────── 10 ────┤      ├───  2 Qc → servo PWM 3                
'   { RCk }──────┼───┼─┳────────── 12 ────┤      ├───  3 Qd → servo PWM 4
'   {~G   }──────┼───┼─┼─┳──────── 13 ────┤      ├───  4 Qe → servo PWM 5
'                │   │ │ │ ┌{Qh'}─  9 ────┤      ├───  5 Qf → servo PWM 6
'                │   │ │ │ │              │      ├───  6 Qg → servo PWM 7
'                │   │ │ │ │              │      ├───  7 Qh → servo PWM 8 
'                │   │ │ │ │              └──┬───┘
'                │   │ │ │ │                 8
'                │   │ │ │ │                GND
'                │   │ │ │ │
'                │   │ │ │ │                 Vcc
'                │   │ │ │ │                 16
'                │   │ │ │ │              ┌──┴───┐
'                └───┼─┼─┼─┼────── 11 ────┤      ├─── 15 Qa → servo PWM 9  
'                    │ │ │ └────── 14 ────┤      ├───  1 Qb → servo PWM 10
'                    └─┼─┼──────── 10 ────┤      ├───  2 Qc → servo PWM 11                
'                      └─┼──────── 12 ────┤      ├───  3 Qd → servo PWM 12
'                        └──────── 13 ────┤      ├───  4 Qe → servo PWM 13
'                             {nc}  9 ────┤      ├───  5 Qf → servo PWM 14
'                                         │      ├───  6 Qg → servo PWM 15
'                                         │      ├───  7 Qh → servo PWM 16 
'                                         └──┬───┘
'                                           8
'                                          GND
'
CON
    _clkmode = xtal1 + pll16x
    _xinfreq = 5_000_000

VAR                    
  long  cog                     ' cog flag/id
  
  long  CLK_pin                 ' All 5 pin assignments Loaded by start command LONGMOVE
  long  Data_pin                
  long  SCLR_Pin               
  long  RCK_pin
  long  G_Pin
 
  long  buffer_ptr              ' Pointer to top of PWM buffer
                   
  LONG  Data_buffer[16]         ' 16 different PWM channels - All Longs
  
PUB start(CLKPin, DataPin, SCLRPin, RCKPin, GPin) : okay '' Start driver - starts a cog

  longmove(@CLK_pin, @CLKPin, 5)                        ' Move 5 longs to Data_pin location starting at location of DataPin in Start call
                                 
  buffer_ptr := @Data_buffer                            ' Establish the buffer location as the initial buffer pointer

  okay := cog := cognew(@entry, @CLK_pin) + 1           ' Start the cog
  
PUB stop                                                '' Stop driver - frees a cog
  if cog
    cogstop(cog~ - 1)
    longfill(@CLK_pin, 0, 5)

PUB ServoOut(ServoLong,Channel,mSec)                                      ' PulseLength in uSec,Channel Number 0 - 15 
    Data_buffer[Channel] := ServoLong * mSec

PUB ServoRep(Channel,mSec):ReturnData                                                           ' PulseLength in uSec,Channel Number 0 - 15 
    ReturnData := Data_buffer[Channel] / mSec
    
PUB CogOut : CogVar
  CogVar := cog
    
DAT
'***********************************
'* Assembly language Servo driver  *
'***********************************
                        org
entry                   mov     t1,par                  'get structure address (cog and Main memory sharred area offset)   
                                                      
                        rdlong  t2,t1                   '++++++++++ Clock Port
                        mov     CLKmask,#1              ' #1 means literal value of 1,ie: mov 1 to address in CLKmask
                        shl     CLKmask,t2              ' shift data in memory at CLKmask, t2 places to the left
                                                        ' This places a 1 in the right place for the CLKmask pin on the outa mask
                                                      
                                                        '++++++++++ Data Port
                        add     t1,#4                   ' Inrcement t1 by 4 so now Data port address in to t1
                        rdlong  t2,t1                   ' get Data port out of main memory into t2
                        mov     datamask,#1             ' put a one in the mask
                        shl     datamask,t2             ' move it to the left t2 times

                                                        '++++++++++ Shift register clear Port
                        add     t1,#4                   ' Inrcement t1 by 4 so now Sclr port address in to t1
                        rdlong  t2,t1                   ' get Sclr port out of main memory into t2
                        mov     SCLRmask,#1             ' put a one in the mask
                        shl     SCLRmask,t2             ' move it to the left t2 times
                        
                                                        ' +++++++++ Output register clock port
                        add     t1,#4                   ' Inrcement t1 by 4 so now RCK port address in to t1
                        rdlong  t2,t1                   ' get RCK port out of main memory into t2 
                        mov     RCKmask,#1              ' put a one in the mask
                        shl     RCKmask,t2              ' move it to the left t2 times
                        
                                                        ' +++++++++ Output enable port 
                        add     t1,#4                   ' Inrcement t1 by 4 so now G port address in to t1
                        rdlong  t2,t1                   ' get Data port out of main memory into t2 
                        mov     Gmask,#1                ' put a one in the mask
                        shl     Gmask,t2                ' move it to the left t2 times
                       
                        add     t1,#4                   ' Inrcement t1 by 4 so now buffer_ptr first address into t1
                        rdlong  buff,t1                 ' get buffer - Read value in t1(main memory address) and stores it
                                                        '  in buff for assembly lang ref  
'-------------------------------------------------------------------------------------------
                                                        ' Initialize the cog I/O enviroment
SetUp                   Call    #PinSet                 '  set up port direction, default values    
'-------------------------------------------------------------------------------------------
Main                    MOV     LtData,#0               ' Clear Latch Data
                        Call    #SendData               ' Clear Latch output
                        MOV     Chan,#0                 ' Set Chan to #0    
                                                        ' End of Loop setup
                                                        
MainLoop                MOV     t1,buff                 ' Put Incomming data buffer address on t1
                        ADD     t1,Chan                 ' Offset buffer Address by channel
                        rdlong  t2,t1                   ' Read value in address t1 into register t2
                        MIN     t2,#$1FF                ' Make sure the value in t2 is not too low
                                                        '  used mostly for start-up when 00's in buffer locations
                        ADD     t2,CNT                  ' Add system count to t2
                        CALL    #SetBit                 ' Turn the pulse on at Chan (16 clock cycles)
                        Call    #SendData               ' Put it out on the latch (4.7uSec)
                        WAITCNT t2,#0                   ' Wait until t2 matches CNT
                        CALL    #ReSetBit               ' Turn the pulse off (16 clock cycles)
                        ADD     ChanBit,#1              ' Increment the channel bit
                        ADD     Chan,#4                 ' Increment Channel (4 bytes = 1 long)
                        AND     Bits,#%0_0000_1111      ' Cut back down to 0-15
                        AND     Chan,#%0_0011_1111      ' Cut back down to 0-64
                        AND     ChanBit,#%0_0000_1111   ' Cut back down to 0-15                      
MainLoop_end            JMP     #MainLoop               ' Do it again

'-------------------------------------------------------------------------------------------
SendData                ' Routine sends 16 bits in LtData out to latches MSB first
                        ' execute time roughly 4.7 uSec
                        
:SendLoop               MOV     bits,#%0_0000_0001       ' position a 1 in LSB
                        SHL     bits,#15                 ' shift it left 15 times so 
                                                         ' now bits = %1000_0000_0000_0000
                                                         ' 'bits' is a counter and a comparitor  
                                                                                
:sendclock              TEST    LtData,bits     wz
                        muxnz   OUTA,datamask            ' Put result on data output
                        OR      OUTA,CLKmask             ' Clock UP to move the bit into the latch
                        ANDN    OUTA,CLKmask             ' Clock DN
                        SHR     bits,#1         wz       ' Shift bit tester to the right 1 bit
               if_nz    JMP     #:sendclock              ' If it's not a zero result go around again
               
                        ANDN    OUTA,datamask            'Put 0 on data output as we are now done
                        
                        OR      OUTA,RCKmask             'Pulse the RCK clock to move the data out
                        ANDN    OUTA,RCKmask                       
SendData_ret            Ret                                     
'---------------------------------------------------------------------------------------
SetBit                                                  ' Sets specific bit of LtData (ChanBit) to 1
                        Mov     BitMask,#1              ' Build the mask
                        ROL     BitMask,ChanBit         ' Rotate 1 to left it into position ChanBit times
                        OR      LtData,BitMask          ' OR the mask with the LtData
SetBit_ret              RET                             ' Return
'---------------------------------------------------------------------------------------
ReSetBit                                                ' Sets specific bit of LtData (ChanBit) to 0
                        Mov     BitMask,FFFE            ' Build the mask $FFFE (1111_1111_1111_1110)
                        ROL     BitMask,ChanBit         ' Rotate 0 to left it into position ChanBit times
                        AND     LtData,BitMask          ' AND the mask with the LtData to clear the bit
ReSetBit_ret            RET                             ' Return
'---------------------------------------------------------------------------------------
                                                        ' Set up port direction, default values
                                                        ' Set up 74HC595 shift register called at start-up only
PinSet                  OR      dira,CLKmask            ' Set as output 
                        OR      dira,SCLRmask           ' Set as output 
                        OR      dira,RCKmask            ' Set as output 
                        OR      dira,Gmask              ' Set as output 
                        OR      dira,Datamask           ' Set as output

                        ANDN    OUTA,CLKmask            ' 0 on clock line
                        ANDN    OUTA,SCLRmask           ' 0 on SClr line
                        OR      OUTA,RCKmask            ' Set Master Reset to 1 
                        OR      OUTA,Gmask              ' Set Output Enable to 1 for Tri-State  
                        ANDN    OUTA,Datamask           ' 0 on data line
                                               
                                                        ' Reset Shift register sequence
                        OR      OUTA,CLKmask            '  Clock ON
                        ANDN    OUTA,SCLRmask           '  SCLR OFF
                        ANDN    OUTA,CLKmask            '  Clock Off
                        OR      OUTA,CLKmask            '  Clock ON
                        OR      OUTA,SCLRmask           '  SCLR ON - reset complete
                        ANDN    OUTA,Gmask              ' Set output enable line to 0, outputs now enabled
                                                        ' Shift register now ready to go
PinSet_Ret              RET
'---------------------------------------------------------------------------------------
                        FIT
FFFE                    LONG    $FFFE
                           
' Uninitialized data

t1                      res     1                     ' RES = Reserve 1 long for symbol t1
t2                      res     1                     ' 
t3                      res     1
s                       res     1
c                       res     1

CLKmask                 res     1
SCLRmask                res     1
RCKmask                 res     1
Gmask                   res     1
DataMask                res     1 

ChanBit                 res     1
Bits                    res     1
BitMask                 res     1
ByteAdr                 res     1
ByteAdrInc              res     1
LtData                  res     1
BitNo                   res     1
'msec                    res     1
buff                    res     1
PWMBuff                 res     1
Chan                    res     1

't1                      res     1                      ' RES = Reserve 1 long for symbol t1
't2                      res     1                      ' t's are general purpose counters

'CLKmask                 res     1                      ' OUTA Masks for pins as indicated
'SCLRmask                res     1
'RCKmask                 res     1
'Gmask                   res     1
'DataMask                res     1 
                                                        ' Variables used in code
'ChanBit                 res     1                       ' General purpose bit manipulation space 
'Bits                    res     1                       ' General purpose bit manipulation space
'BitMask                 res     1                       ' General purpose bit manipulation space
'LtData                  res     1                       ' Data rotated out on to latch
'buff                    res     1                       ' Incomming data buffer base address 
'Chan                    res     1                       ' Channel offset to buffer base 'buff'

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