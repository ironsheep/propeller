{{

The driver is designed to run at 80MHz. For instance:

  _clkmode        = xtal1 + pll16x
  _xinfreq        = 5_000_000
  
The driver takes a pointer to four consecutive longs:

    long   command    ' Command trigger -- write non-zero value
    long   buffer     ' Pointer to the pixel data buffer
    long   numPixels  ' Number of pixels to write
    long   pin        ' The pin number to send data over

When you write a non-zero value to "command" then the driver
goes into action reading the pixel bytes from the pixel "buffer"
and writing them over the "pin". When all pixels have been written
the driver resets the "command" to zero.

The data for each pixel is stored in a single long. The upper byte
of the long is ignored. Only the lower three bytes are used:

$00_GG_RR_BB

Where "GG", "RR", and "BB" are the intensities for green, red, and blue.

You can use the same driver COG to update multiple NeoPixel strips
by changing the "pin" between update requests. Or you can spin up
separate driver COGs for each strip. Each COG would have its own
set of four parameter longs.
}}

pub start(paramBlock)
'' Start the NeoPixel driver cog
   return cognew(@NeoCOG,paramBlock)
   
DAT          
        org 0

NeoCOG   
        mov     comPtr,par        ' This is the "trigger" address
        mov     bufPtr,par        ' This is the ...
        add     bufPtr,#4         ' ... buffer address
        mov     numPtr,par        ' This is the ...
        add     numPtr,#8         ' ... number of pixels to send
        mov     pinPtr,par        ' This is the ...
        add     pinPtr,#12        ' ... data pin number                 

top     rdlong  com,comPtr wz     ' Has an update been triggered?
  if_z  jmp     #top              ' No ... wait until

        rdlong  com,pinPtr        ' Which pin for this update
        mov     pn,#1             ' Pin number ...
        shl     pn,com            ' ... to mask
        or      dira,pn           ' Make sure we can write to it

        rdlong  num,numPtr        ' Number of pixels to write

        rdlong  pPtr,bufPtr       ' Where the pixels come from      

refresh
        rdlong  com,pPtr          ' Get the next pixel value
        add     pPtr,#4           ' Ready for next pixel in buffer
        shl     com, #8           ' Ignore top 8 bits (3 bytes only)
        mov     bitCnt,#24        ' 24 bits to move

bitLoop
        shl     com, #1 wc        ' MSB goes first
  if_c  jmp     #doOne            ' Go send one if it is a 1
        call    #sendZero         ' It is a zero ... send a 0
        jmp     #bottomLoop       ' Skip over sending a 1
doOne   call    #sendOne

bottomLoop
        djnz    bitCnt,#bitLoop   ' Do all 24 bits in the pixel
        djnz    num,#refresh      ' Do all requested pixels

        call    #sendDone         ' Latch in the LEDs  

        jmp     #done             ' Clear the trigger               
        
sendZero                 
        or      outa,pn           ' Take the data line high
        mov     c,#$5             ' wait 0.4us (400ns)
loop3   djnz    c,#loop3          '
        andn    outa,pn           ' Take the data line low
        mov     c,#$B             ' wait 0.85us (850ns) 
loop4   djnz    c,#loop4          '                              
sendZero_ret                      '
        ret                       ' Done

sendOne
        or      outa,pn           ' Take the data line high
        mov     c,#$D             ' wait 0.8us 
loop1   djnz    c,#loop1          '                       
        andn    outa,pn           ' Take the data line low
        mov     c,#$3             ' wait 0.45us  36 ticks, 9 instructions
loop2   djnz    c,#loop2          '
sendOne_ret                       '
        ret                       ' Done

sendDone
        andn    outa,pn           ' Take the data line low
        mov     c,C_RES           ' wait 60us
loop5   djnz    c,#loop5          '
sendDone_ret                      '
        ret                       '

done    mov     com,#0            ' Clear ...
        wrlong  com,comPtr        ' ... the trigger
        jmp     #top              ' Go back and wait

C_RES   long $4B0                 ' Wait count for latching the LEDs

comPtr  long 0
bufPtr  long 0
numPtr  long 0
pinPtr  long 0

com     long 0
pPtr    long 0  
pn      long 0
num     long 0
c       long 0

bitCnt  long 0
pixCnt  long 0

CON
{{    
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                TERMS OF USE: MIT License                                │                                                            
├─────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this     │
│software and associated documentation files (the "Software"), to deal in the Software    │
│without restriction, including without limitation the rights to use, copy, modify, merge,│
│publish, distribute, sublicense, and/or sell copies of the Software, and to permit       │
│persons to whom the Software is furnished to do so, subject to the following conditions: │
│                                                                                         │
│The above copyright notice and this permission notice shall be included in all copies or │
│substantial portions of the Software.                                                    │
│                                                                                         │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESSED OR IMPLIED,    │
│INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR │
│PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE│
│FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR     │
│OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER   │
│DEALINGS IN THE SOFTWARE.                                                                │
└─────────────────────────────────────────────────────────────────────────────────────────┘
}}           