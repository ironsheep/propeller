{{
WWVB Time Data Decoder Demonstration

V.1.0
Copyright(C)2015, Steven R. Stuart, W8AN, Feb 2015
Terms of use are stated at the end of this file.

This software requires a WWVB 60kHz time receiver module.

Real time terminal display is presented in the following format:

Line ┌──────────────────────────────────────────────────────────────────┐
  1  │ Latest WWVB received data                                        │
  2  │ Hour:2 Minute:33 Sec:4  DoY:55 Year:2015  Dst/St:00              │
  3  │                                                                  │
  4  │ Time Frame:                                                      │
  5  │ PMMMrmmmmPrrHHrhhhhPrrDDrDDDDPddddrrUUUPuuuurYYYYPyyyyrllttP     │
  6  │ S01100100S000000010S000000101S010100010S010100_01S010100000S     │
  7  │     ^                                                            │
  8  │ Pulse Frame:                                                     │
  9  │ 100100200000001020000001012010100010201010030120101000002201     │
 10  │                                                          ^       │
 11  │ Pulse Buffer (coded):              Pulse width: 210ms            │
 12  │ 1S010100000SS0110_1100100S000000010S000000101S010100010S010100_0 │
 13  │                 ^                                                │
 14  │ History Data:           Quality: 49                              │
 15  │  Min   Hour  DoY   Year                                          │
 16  │   0     2     55    0                                            │
 17  │   33    2     55    2015                                         │
 18  │   32    2     55    2015                                         │
 19  │   31    2     55    2015                                         │
 20  │   30    0     55    2015                                         │
 21  │   29    2     55    0                                            │
 22  │   0     0     0     0                                            │
 23  │   0     0     0     0                                            │
 24  │   0     0     0     0                                            │
 25  │   0     0     0     0                                            │
 26  │                                                                  │
 27  │ Clock Time: 02:35:04z  Date: 2/24/2015                           │
     └──────────────────────────────────────────────────────────────────┘                  
Line 2: Most recent valid content of the frame buffer 
Line 5: A static frame buffer indicator showing the bit type and position (See
        wwvb decoder for a legend of the bit types)
Line 6: The real time data stored in the frame buffer
Line 7: Pointer to the current bit being received in the frame buffer
Line 9: Last 60 decoded pulse types. 0,1=logic bit. 2=sync, 3=error
Line 10: Pointer to the frame reference bit in the pulse frame, the start bit
Line 11: Latest received pulse width in milliseconds
Line 12: The 64-bit pulse time buffer coded to the bit type. 0,1=logic, S=sync, _=error
Line 13: Pointer to the latest received bit in the pulse buffer
Line 14: Quality of the history data. See the wwvb decoder source for description
Line 16-25: The recent history of the received data
Line 27: Current content of the decoder's running clock 
                                                                                   
}}

OBJ
     wwvb : "WWVB Decoder"
     term : "Parallax Serial Terminal"         

CON
     _xinfreq   = 5_000_000              '80MHz clkfreq
     _clkmode   = xtal1 + pll16x         'Clock multiplier

     WWVB_PIN   = 17

VAR                                           
    long stack[32] 
    long runningCogID

PUB Main|pfa,pba,hda,pbp,prev,frb,i,j,t

  wwvb.Start(WWVB_PIN)          'launch the decoder
  wwvb.StartRcvr                'start the receiver
  
  waitcnt(clkfreq*2 + cnt)      'give user 2 seconds to enable terminal  
  term.start(115_200)
  term.clear

  pfa := wwvb.PulseFrameAddr    'get data structure addresses
  pba := wwvb.PulseBufferAddr
  hda := wwvb.HistoryDataAddr
  pbp := wwvb.PulseBufferPtrAddr

  repeat
    
      waitcnt(clkfreq/2 + cnt)   'run about twice a second

      if wwvb.GetClockSecond == 5 'refresh screen each minute       
          waitcnt(clkfreq + cnt)       
          term.clear             

      frb := wwvb.GetFrameRefBit

      ''show current decoder values 
      term.home
      term.str(string("Latest WWVB received data"))
      term.newline
      term.str(string("Hour:"))      
      term.dec(wwvb.GetHour)
      term.str(string(" Minute:"))
      term.dec(wwvb.GetMinute)                                                                                                                                   
      term.str(string(" Sec:"))
      term.dec(wwvb.GetSecond)
      term.str(string("  DoY:"))
      term.dec(wwvb.GetDoY)
      term.str(string(" Year:"))
      term.dec(wwvb.GetYear)
      term.str(string("  Dst/St:"))
      term.dec(wwvb.GetDstBit)
      term.dec(wwvb.GetStBit)      
      term.clearend
      term.newline
      'term.str(string("Frame Ptr:"))
      'term.dec(wwvb.GetFramePtr)
      'term.clearend 
      'term.newline
                        
      ''show the FRAME_BUFFER contents   
      term.newline
      term.str(string("Time Frame:"))
      term.newline
      term.str(string("PMMMrmmmmPrrHHrhhhhPrrDDrDDDDPddddrrUUUPuuuurYYYYPyyyyrllttP"))
      term.newline
      term.str(wwvb.FrameBufferAddr)   
      term.newline
      term.clearend
      term.positionx(60-frb)
      term.str(string("^"))
      term.newline
      
      ''show the pulse_frame contents        
      term.str(string("Pulse Frame:"))
      term.newline
      repeat i from 0 to 59               
          term.dec(byte[pfa+i])
      term.newline
      term.clearend
      term.positionx(frb)
      term.str(string("^"))
      term.newline

      ''convert the pulse_buffer pulse times to types and show them      
      term.str(string("Pulse Buffer (coded):"))  
      term.positionx(35)
      term.str(string("Pulse width: "))
      prev := byte[pbp]-1
      if prev == -1
          prev := 63
      term.dec(long[pba+(prev*4)]/100_000)
      term.str(string("ms"))
      term.clearend
      term.newline
      repeat i from 0 to 63
          PulseType(long[pba+(i*4)])
          term.str(@PULSE_TYPE)
      term.newline
      term.clearend
      term.positionx(byte[pbp])
      term.str(string("^"))                          

      ''show the data quality and history 
      term.newline
      term.str(string("History Data:"))
      term.positionx(24)
      term.str(string("Quality: "))
      term.dec(wwvb.Quality)
      term.clearend
      term.newline
      term.str(string(" Min   Hour  DoY   Year"))
      term.newline
      repeat i from 0 to wwvb#HISTORY_SIZE-1    'rows, 
          term.clearend                   
          repeat j from wwvb#INDEX_MINUTE to wwvb#INDEX_YEAR 'cols, 
              term.positionx(j*6+2)
              term.dec(word[hda+((i*4+j)*2)])    
          term.newline                                                                                                                                       

      ''show decoder internal time clock
      term.newline
      term.str(string("Clock Time: "))
      t := wwvb.GetClockHour
      if t < 10
          term.str(string("0"))
      term.dec(t)
      term.str(string(":"))
      t := wwvb.GetClockMinute
      if t < 10
          term.str(string("0"))
      term.dec(t)
      term.str(string(":"))
      t := wwvb.GetClockSecond
      if t < 10
          term.str(string("0"))
      term.dec(t)
      term.str(string("z"))         'zulu time zone
   
      term.str(string("  Date: ")) 
      term.dec(wwvb.GetClockMonth)                                                                                                                                   
      term.str(string("/"))
      term.dec(wwvb.GetClockDay)
      term.str(string("/"))
      term.dec(wwvb.GetClockYear)
      term.clearend
      term.newline

PRI PulseType(pulse_width)
{{
  Estimate the pulse type based on a range of pulse_width time values (same as decoder uses) 
  logic 0 is type 0, logic 1 is type 1
  sync bit is 'S'
  error is '_'
}}
    case pulse_width                                                            

       19_000_000..22_000_000:               '190ms-220ms assume it's a logic 0 - 200ms optimal                                                          
           byte[@PULSE_TYPE] := "0"                                                                                              
       40_000_000..60_000_000:               '400ms-600ms assume it's a logic 1 - 500ms optimal                                                                           
           byte[@PULSE_TYPE] := "1"                                                                                              
       70_000_000..90_000_000:               '700ms-900ms assume it's a frame sync pulse - 800ms optimal                                                                   
           byte[@PULSE_TYPE] := "S"  'sync                                                                                             
       other:                                'unreadable, noise, or static                                                                                                               
           byte[@PULSE_TYPE] := "_"  'error                                                                                              
                                                                                                                                                 
DAT
    PULSE_TYPE    byte    "_",0

DAT    
{{
┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                             TERMS OF USE: MIT License                                         │                                                                           
├───────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated   │
│documentation files (the "Software"), to deal in the Software without restriction, including without limitation│
│the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,   │
│and to permit persons to whom the Software is furnished to do so, subject to the following conditions:         │                                                         │
│                                                                                                               │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions  │
│of the Software.                                                                                               │
│                                                                                                               │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED  │
│TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL  │
│THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF  │
│CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER       │
│DEALINGS IN THE SOFTWARE.                                                                                      │
└───────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}                      