{{
  *************************************************
  *     VEX Receiver Demultiplexer Object         *  
  *     Demuxes all 6 channels of VEX receiver    *  
  *               Version 1.1                     *  
  *          Released: 05/31/2007                 *  
  *          Revised:  09/01/2007                 *  
  *          Author:   Scott Gray                 *  
  *                                               *  
  * Questions? Please post on the Propeller forum *
  *       http://forums.parallax.com/forums/      *
  *************************************************

This object is used to de-multiplex a VEX receiver output, or "tethered' VEX
transmitter output.  It uses one Cog full-time to continuously de-multiplex
the PPM pulse trains.  Although written in Spin, the resulting channel output pulse
width measurements appear very accurate.

The calling object must pass two pointers: one to an array of 6 longs to hold
the 6 channel output pulse widths in microseconds, and a pointer to a long to
hold a flag indicating that a VEX PPM pulse train is currently being de-multiplexed.

This object also limits the channel outputs to 1050 usecs minimum and 1950 usecs maximum to
prevent spurious reception of out of range conditions from affecting channel outputs.
Other limits could be applied by modifying the constants MAX_VALUE and MIN_VALUE.

VEX Connections:
============================================================================================
VEX Transmitter (radio) Tether Pinout (viewed from the back):
                          
                           
                          ┌┤├┐
          ┌───────────────┴┴┴┴───────────────┐
          │               Top                │
          │                                  │
          │                                  │
          │              ┌─────┐             │  
          │              │   = │ N/C         │  Not connected, (or +5V to +6V for use w/ receiver)      
          │       Tether │   = │ PPM Out     │  Connected to microcontroller for decode
          │        Conn  │   = │ GND         │  Ground                                 
          │              │   = │ RF Dis      │  Grounded to disable RF output                  
          │              └─────┘             │
          │                                  │
          │                                  │
          │       Back of Transmitter        │
          └──────────────────────────────────┘
                    VEX Transmitter
          

The PPM output is open collector, which means it requires a pull-up resistor (1 to 10Kohms)
to the microcontroller supply to generate a high (logic 1) signal.  When a cable is plugged
in between the VEX transmitter and the microcontroller (transmitter tethered), the RF disable
pin needs to be grounded to shut off the RF output of the transmitter. 

Receiver Pinout (viewed from end with modular locking lever slot on the left and the pins
on the right):
          ┌┐
          ││
          ├┴─────────────────────────┐
          │          ┌─────┐         │
          │          │   = │ Vdd     │  From the battery + side (+5V to +6V)
          │B  Modular│   = │ PPM Out │  Connected to microcontroller for decode
          │o   Conn  │   = │ GND     │  Ground
          │t         │   = │ N/C     │  Not Connected, (or ground for use w/ transmitter)
          │          └─────┘         │
          ├┬─────────────────────────┘
          ││
          └┘
                    VEX Receiver


Note that you can ground the N/C pin so that it will work with the transmitter when tethered.


VEX Receiver (or Transmitter on tether) Theory of Operation
=============================================================================================
The output from the VEX receiver is an open collector PPM (pulse position modulation) stream
that is common in the RC control world. The idle/spacing state of the output will be high via
a required pull-up resistor.

The PPM signal stream from the receiver into the microcontroller looks like this:

... //...
          <---~9 mSec--->|<--1st->|<-2nd->|<-3rd->|<--4th->|<-5th-->|<--6th-->|

A cycle begins with a low-going sync pulse that is about nine milliseconds in duration.
At the end of the sync pulse the PPM pin will go high; this is the beginning of the Channel 1
timing. At this point the Channel 1 output pulse is being timed until the next low-to-high
transition of the PPM pin; at this point the Channel 1 pulse time is captured and Channel 2
timing is started.  This pattern repeats for all 6 channels.

Note that only the low pulse width of each channel varies, the high part of the framing pulse
is relatively constant (~400 to ~500 uS).  The low portion will vary from ~500 to ~1500 uS.

After the first four received channels, this object measures the pulse width of channels 5 and 6
to determine which buttons (top = shorter pulse, bottom = longer pulse), if any, are pressed.

Measured results:
The measured separation pulse (high pulse) was a fixed 400usec (+/-) long.
Pushing the stick up shortens the channel's "low" pulse about 400usec.
Pushing the stick down lengthens the pulse about 420usec.
No deflection on the stick gives a 1.12msec low pulse
(for a total of 1.52msec from the beginning of the separation pulse.)

Every five counts of channel trim on transmitter adjusts the pulse length approximately 6 usec.

The top button (chans. 5 and 6) shortens the "low" pulse time 560usec
and the bottom button lengthens the "low" pulse 560usec.
Each packet of 6 channels repeats roughly every 18.5msec. 

============================================================================================
  To use this object:

  Include in calling object code:
  ------------------------------------------------
  CON                         
    _clkmode = xtal1 + pll16x
    _xinfreq = 5_000_000      
                        
  VAR           
                
  OBJ           
    VEX : "VEXDemux"                                    ' Create VEX Demux Object

  PUB Start 
    VEX.Start (VexRcvPin, @channelValues)               ' Initialize VEX Decoder Object
                                                        ' VexRcvPin - VEX Receiver PPM Output        
                                                        ' channelValues - current channel
                                                        ' values in microseconds
--------------------------------------------------------------------------------------------
Revision History:
05/31/2007 - Initial Release, tested and ready to use
09/01/2007 - Fixed picture of receiver for pinout information.
}}
    
con

' Global constants required, can be removed from here                         
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
    
' VEX channel pulse width values
  CENTER_STICK = 1520           ' initial center stick pulse width in usec                       
  MAX_VALUE    = 1950           ' max value pulse width in usec                          
  MIN_VALUE    = 1050           ' min value pulse width in usec                          

' Other constants
  SYNC_TIME    = 4000           ' time to wait to ensure sync pulse, in usec
  _1uS         = 1_000_000 / 1  ' divisor for 1 uS                 
                                                                
var

' Cog variables                                                                                    
  word started                  ' true if cog running decoder                

  byte DemuxCog                 ' holds which cog is running decoder         
                                                                          
' Object input variables
  long channelPtr               ' pointer to channel variables (6 longs)     
                                ' channel variables are in microseconds      

  long syncOutPtr               ' sync output that is true while receiving new pulse
                                ' train that can be used to keep track of reception
                                                                            
' Cog stack space
  long stack[128]               ' big stack space, could be reduced          


PUB Start (VexRcvPin, channelValuesPtr, syncPtr)| index

'' Initialize Vex Demuxer, start the de-mux cog

  Stop                                                  ' stop cog if already allocated
  started~                                              ' assume started is false
  if (VexRcvPin => 0) and (VexRcvPin < 28)              ' qualify VEX receiver pin
    started := (DemuxCog := cognew(DemuxVexCog(VexRcvPin,channelValuesPtr, syncPtr), @stack) + 1)
  if started
    dira[VexRcvPin] := 0                                ' set selected VEX receive pin as an INPUT
    channelPtr := channelValuesPtr                      ' set channel de-mux output pointer
    syncOutPtr := syncPtr                               ' set sync flag output pointer
  return started                                        ' return started success flag

PUB Stop

'' Unload DemuxVex Cog - frees a cog, potentially (if one was started)

  if started~                                          ' if method running, mark stopped
    cogstop(DemuxCog)                                  ' stop the cog


PRI DemuxVexCog (rcvPin, chanPtr, syncPtr) | channel[6], rPin, oldCnt, newCnt, deltaCnt, high, low, uS_tix, syncTime, index

'' Demux VEX receiver input to 6 channels continuously

  rPin := |< rcvPin                                     ' set receive pin location in a long
  high := |< rcvPin                                     ' set a high as a 1 in receive pin location
  low  := 0                                             ' set a low as 0
  uS_tix := clkfreq / _1uS                              ' set number of clocks per microsecond
  syncTime := SYNC_TIME * uS_tix                        ' set minimum time to determine sync pulse

  repeat index from 0 to 5                              ' initialize all channels to center position
    channel[index] := CENTER_STICK                       
    long[chanPtr + (index * 4)] := CENTER_STICK

' Main Loop 
  repeat                                                ' Main loop
    long[syncPtr]~                                      ' set sync flag to false

    repeat                                              ' wait for a sync period to come along...
      waitpeq(low,rPin,0)                               ' by finding a low-to-high transistion...                                                
      oldCnt := cnt                                     ' and determining the pulse time in clocks                                               
      waitpeq(high,rPin,0)                                                                              
      newCnt := cnt                                                                                     
      if oldCnt > newCnt                                ' handle counter wrap around
        deltaCnt := (newCnt - NegX) + (PosX - oldCnt)                                                   
      else                                                                                              
        deltaCnt := newCnt - oldCnt                                                                      
    while (deltaCnt < syncTime )                                                                  

    long[syncPtr]~~                                     ' if sync found set sync flag true...
    repeat index from 0 to 5                            ' and get all six channel pulse widths                                                
      waitpeq(low,rPin,0)                               ' by looking for new low transition...                                                 
      oldCnt := newCnt                                  ' and timing the clocks to next low-to-high transition                                                
                                                        ' (Note that the time is from last low-to-high
                                                        ' transition.  It is assigned here simply
                                                        ' because there is time to do some useful work...)
      waitpeq(high,rPin,0)                              ' transition to high detect                                                
      newCnt := cnt                                     ' get pulse time count                                               
      if oldCnt > newCnt                                ' handle counter wrap around                                                
        deltaCnt := (newCnt - NegX) + (PosX - oldCnt)                                                   
      else                                                                                              
        deltaCnt := newCnt - oldCnt                                                                     
      channel[index] := deltaCnt                        ' and store the channel pulse width in clocks                                       
    repeat index from 0 to 5                            ' Copy results and convert to microseconds 
      long[chanPtr + (index * 4)] := MIN_VALUE #> (channel[index] / uS_tix) <# MAX_VALUE
              