''**************************************
''
''  DMX Rx Driver Ver. 01.4
''
''  Timothy D. Swieter, E.I.
''  www.brilldea.com
''
''  Copyright (c) 2008 Timothy D. Swieter, E.I.
''  See end of file for terms of use. 
''
''  Updated: March 20, 2008
''
''Description:
''This program reads and parses the DMX serial data
''stream.  All 513 (it also captures the start byte)
''channels are read into an array.  There also is an
''LED that blinks to dispaly activity of arriving packets/slots.
''The LED I/O line can be monitored from other cogs
''to signal if DMX is coming in.  The LED is
''on while receiving a slot and off while waiting.
''Note that this status LED may appear to be solid
''depending on your update rate of DMX.  The LED should
''go out if a DMX stream stops coming in.
''
''The DMX signal is translated from DMX levels to TTL/CMOS
''levels by a MAX487E.  Some manufacturers also use
''the SN75156B chip.  DMX is connected with 5 Pin XLR
''connectors. Male is on receiving and female on sending.
''The following circuit is for receiving and sending
''but no code exists in this object for sending DMX.
''
''Note this objects does not check for a null start
''code ($00). This means the end users should check
''the zero element of the array to know if the data
''is 'dimmer' data or other type of data.  This routine
''captures all DMX data (dimmer, RDM, etc). One
''could make this routine check for the correct start
''code by adding ASM code in the dat section below or
''add it 'on top of' this object.
''
''This code should be run at 80MHz. to ensure the best
''performance. This code was tested at 80MHz. but it
''may work as slightly lower clock rates.
''
{{
Schematic                            MAX487E
────────────────────────────         ────────────────────────────
                +5V                      Pins   Names
          ┌────┐                        ────   ─────
P? ────┤1  8├─┘                          1   RO Receiver Output
     1k   │    │                            2   RE Receiver Enable (active-low)
P? ───┳──┤2  7├─── Pin 2 XLR Male         3   DE Driver Output Enable
       └──┤3  6├─── Pin 3 XLR Male         4   DI Driver Input
P? ──────┤4  5├┐ ┌ Pin 1 XLR Male         5   GND
          └────┘│ │                         6   A
           487E  └See note below           7   B
               GND                          8   VCC                                            
}}
''
''It is recommended to use a 0.1uF cap between pin 8 and pin 5.
''Pin 1 should not be connected to ground on receivers.  To avoid ground
''loops the pin should be connected to pin 1 of another XLR or left floating.
''Pin 1 should only be connected to gnd on a transmitter intended to command
''an entire system such as a lighting console or DMX playback machine.
''Your design may implement a jumper or 0 ohm resistor to allow the end
''user to chose if they want gnd connected to Pin 1 of the XLR or not
''(jumper means connected). 
''
''DMX Packet information:
''  250KHz. Clock for the data (each bit 4 usec)
''  88 usec break at start of packet (22 low bits), may be longer (88usec for receivers)
''  variable MAB signal, could be 8usec, cloud be longer
''  513 bytes (1 start code byte, 512 start bytes) - this is what the standard calls slots
'' 
''Reference:
''      ANSI E1.11 - 2004:  Entertainment Technology - USITT DMX512-A - Asynchronous Serial Digital Data Transmission Standard for Controlling Lighting Equipment and Accessories
''      http://www.erwinrol.com/index.php?stagecraft/dmx.php
''      http://www.dmx512-online.com/packt.html
''      http://www.maxim-ic.com/quick_view2.cfm/qv_pk/1112
''      John Huntington's book "Control Systems for Live Entertainment"
''              http://www.controlgeek.net/
''
''Revision Notes:
'' 1.0 Initial release (not labeled as 1.0)
'' 1.3 Made driver tolerant to short packets (less than 512 slots after start byte)
''     Updated documentation in code
''     Revised some variable names and method names
''     Added way to check for how long a packet is
'' 1.4 Revised schematic to better explain pin one of the XLR connection (thanks DynamoBen for pointing this out)
''     Revised some of the code description and comments
''     Add statistics for DMX packets.  The stats are gathered in the ASM routine and read by other code calling routines.
''     Started tracking revision notes
'' --- Update object to include MIT License
''      
''**************************************

CON               'Constants to be located here
'***************************************
'  System Definitions      
'***************************************

  _OUTPUT       = 1             'Sets pin to output in DIRA register
  _INPUT        = 0             'Sets pin to input in DIRA register  
  _HIGH         = 1             'High=ON=1=3.3v DC
  _ON           = 1
  _LOW          = 0             'Low=OFF=0=0v DC
  _OFF          = 0
  _ENABLE       = 1             'Enable (turn on) function/mode
  _DISABLE      = 0             'Disable (turn off) function/mode

VAR               'Variables to be located here

  'Processor
  long cog                      'Cog flag/ID

  'DMX
  long DataHead                 'Location within the buffer                 
  long rxpin                    'Pin for receiving data from converter chip
  long ledpin                   'LED for showing packet activity
  long BitTime                  'Clock ticks of length of bit
  long BreakTime                'Clock ticks of length of break
  long ChannelLoop              'Number of channels to aquire (remember this is zero based, a value of 512 acquires 513 channels)
  long DataPointer              'Point to the buffer
  long PacketLength             'Number of channel in DMX packet
  long BreakMTime               'Number of measured clock ticks in a break
  long MABMTime                 'Number of measured clock ticks in a MAB
  long PacketMTime              'Number of measured clock ticks in a packet
  long Br2BrMTime               'Number of measures clock ticks from start of break to start of break (of another packet)
  
  byte DMXdata[513]             'Array for all DMX values read including start code, channel loop should be the same as the array size
 
PUB start(_rxpin, _ledpin) : okay

'' Start DMX rx driver - setup I/O pins, initiate variables, starts a cog
'' returns cog ID (1-8) if good or 0 if no good

  stop                                                  'Keeps from two cogs running

  'Initilize Variables
  BitTime := 4*(clkfreq/1_000_000)                      '4 usec per bit @ 250K BAUD
  BreakTime := 88*(clkfreq/1_000_000)                   '88 usec break, @ 80MHz it is 7040 ticks, 22 bits, at least
  DataHead := 0                                         'Initialize location within buffer
  ChannelLoop := 512                                    'Aquire all channels plus the start code (zero based, aqcuires 513 bytes)
  DataPointer := @DMXdata                               'Memory pointer to data buffer

  'Qualify the I/O pins to make sure they are valid
  if lookdown(_rxpin: 31..0)
    if lookdown(_ledpin: 31..0)
      'Setup I/O pins
      rxpin := _rxpin                                   'Init variable holding receiving pin  
      ledpin := _ledpin                                 'Init variable holding led activity pin
                                                        'Variables direction must be set in each cog, so done in ASM routine       
      'Start a cog with assembly routine
      okay:= cog:= cognew(@Entry, @DataHead) + 1        'Returns 0-8 depending on success/failure

PUB stop

'' Stops DMX driver - frees a cog

  if cog                                                'Is cog non-zero?
    cogstop(cog~ - 1)                                   'Yes, stop the cog and then make value zero

PUB level(_channel) : value

'' Return value (0 to 255) of DMX channel requested
'' A call to this routine would be placed in your main looping code
'' It is recommended to verify the start card is what you expect it to be, i.e.zero

   value := DMXdata[_channel]

PUB slots : value

'' Returns the number of slots read in the DMX packet, 1 to 513 (includes start slot)

  value := PacketLength

PUB breaksize : value

'' Returns the length of break in microseconds (us)
'' The standard calls for at least an 88us break to be
'' detected by receivers

  value := BreakMTime/(clkfreq/1_000_000)

PUB MABsize : value

'' Returns the length of MAB in microseconds (us)
'' The stanard calls for at leat an 8us MAB

  value := MABMTime/(clkfreq/1_000_000)

PUB packetsize : value

'' Returns the length of the packet in milliseconds (ms)
'' The length of the packet is calculated from the start of
'' break to the end of the last byte received

  value := PacketMTime/(clkfreq/1_000)

PUB br2brsize : value

'' Returns the length from the start of one packet to the next
'' in milliseconds (ms).  1 second divided by this number
'' will be the approximate updates per second and is not to
'' exceed 44/sec

  value := Br2BRMTime/(clkfreq/1_000)
         
DAT

' Assembly Language DMX rx driver
'
                        org
'
'Start of routine
Entry                   mov t1, par             'Load address of parameter list into t1 (par contains first address of parameter list)

                        rdlong rxhead, t1       'Read value DataHead into rxhead (passed by value)

                        add t1, #4              'Increament address pointer by four bytes
                        rdlong rx, t1           'Read value of rxpin into rx
                        mov rmask, #1           'Load mask with a 1        
                        shl rmask, rx           'Create mask for the proper I/O pin by shifting

                        add t1, #4              'Increament address pointer by four bytes
                        rdlong led, t1          'Read value of ledpin into led
                        mov lmask, #1           'Load mask with a 1        
                        shl lmask, led          'Create mask for the proper I/O pin by shifting

                        add t1, #4              'Increament address pointer by four bytes
                        rdlong bitticks, t1     'Bring over value of BitTime

                        add t1, #4              'Increament address pointer by four bytes
                        rdlong brtime, t1       'Bring over value of BreakTime

                        add t1, #4              'Increament address pointer by four bytes
                        rdlong loop, t1         'Bring over value of ChannelLoop

                        add t1, #4              'Increament address pointer by four bytes
                        rdlong rxbuff, t1       'Bring over value of DataPointer

                        add t1, #4              'Increament address pointer by four bytes
                        mov pkadd, t1           'Move a pointer value for the PacketLength

                        add t1, #4              'Increament address pointer by four bytes
                        mov brMea, t1           'Move a pointer value for the 

                        add t1, #4              'Increament address pointer by four bytes
                        mov MABMea, t1          'Move a pointer value for the

                        add t1, #4              'Increament address pointer by four bytes
                        mov pkMea, t1           'Move a pointer value for the

                        add t1, #4              'Increament address pointer by four bytes
                        mov br2brMea, t1        'Move a pointer value for the

                        mov dira, lmask         'Set LED pin to output
                                                'By default rx pin is input
'                           
'Detect BREAK of >88us of low bits (the break can belonger so this part of the code
'waits for the pint to go high)
'
:PacketStart            waitpne rmask, rmask    'Wait for the rx pin to go low
                        mov t3, cnt             'Get current time
                        call #TimeCalc          'Go away and calculate the statistics
                        mov mea1, t3            'Record the start time of the break for statistics                        
:midbreak               add t3, brtime          'Add the 88us break
                        waitpeq rmask, rmask    'Wait for the rx pin to go high
                        mov mea2, cnt           'Get current time (and store for statistics of end of break and start of MAB)
                        sub t3, mea2            'Move current time to variable for processing                        
                                                'If t3 >= 0, time elapsed. If t3 < 0 not long enough        
                        cmps t3, #0        wc   'Compare and set C accordingly
              if_nc     jmp #:PacketStart       'Advance only if time elapsed otherwise try again
                      
'                        
'Process frames - total of 513 - includes the start byte and 512 channels of data
'Note that this routine does not check the start byte - could easily be done if need be.
'It is recommended to check the start byte in the main looping code checking values in the
'DMX array.
'
'First time into the packet start here (because of stastics and it makes logical sense)
:MAB                    waitpne rmask, rmask    'Wait for Mark After Break (MAB)
                        mov mea3, cnt           'Record the end time of MAB for statistics
                        mov t3, mea3            'Move current time to variable for processing
                        mov outa, lmask         'Turn on LED to signal the start of a slot
                        jmp #:slotmid           'We need to skip into the processing of the first byte


:slot                   mov outa, #0            'Reset the LED to an off state (the routine gets stuck here is DMX is unplugged)
                        waitpne rmask, rmask    'Wait for Mark After Break (MAB) or the Mark Time Between Frames (MTBF) to finish
                        mov outa, lmask         'Turn on LED to signal the start of a slot
                        mov t3, cnt             'Get the current timer value (used to detect break of new packet in case the entire
                                                'byte and the first stop bit is zero)

:slotmid                mov rxbits, #9          'Setup counter for receiving a byte (DMX has two stop bits, eight data bits)
                                                'Only nine bits are recieved to allow time for processing the received byte to
                                                'memory during the receiving of the 10th bit
                        mov rxcnt, bitticks     'Load rxcnt with bitticks
                        shr rxcnt, #1           'Divid by 2 to get a half bit period (shifting right divids by two)
                        add rxcnt, cnt          'Make it relative to current time

:bit                    add rxcnt, bitticks     'First time through places us in the middle of the first bit. other time add one bit length

:wait                   mov t2, rxcnt           'Mov rxcnt into a temp variable
                        sub t2, cnt             'Subtract current time
                        cmps t2, #0        wc   'Check to see if time has elapsed
              if_nc     jmp #:wait              'Keep waiting if not, otherwise continue

                        test rmask, ina    wc   'Anding mask and ina will produce a one or zero in C
                        rcr rxdata, #1          'It then rotates the value of C into rxdata by one bit
                        djnz rxbits, #:bit      'When rxbits = zero, move on, otherwise get another bit

                        mov mea4, cnt           'Record the end time of packet for statistics

                        shr rxdata, #32-9       'Move the byte all the way to the right a total of 23 (32-9) places
                        cmp rxdata, #0     wz   'Check if rxdata is zero. If it is zero that means the stop bit is 0 and may be new packet
              if_z      jmp #:shortpacket       'All 9 bits received were low, could be a new break for a short packet
                        and rxdata, #$FF        'Clean up the 32 bits in the register (remeber bits shifted in LSB first, so upper bits
                                                'are the stop bits and can be gotten rid of now that the check is complete)                                                                                               
                        
                        rdlong t1, par          'Get the value of DataHead (offset)
                        add t1, rxbuff          'Add in the base for the buffer (base+offset=location within buffer)
                        wrbyte rxdata, t1       'Write the value into the buffer
                        sub t1, rxbuff          'Get back to DataHead value
                        add t1, #1              'Increament DataHead value
                        wrlong t1, par          'Update stored value with the increment
                        
                        cmp loop, t1       wc   'Check if we have filled the buffer (this  line is where the 0 to 512 occures making 513)
              if_nc     jmp #:slot              'Receive another slot/byte if buffer is not filled (this routine expects 512 channels)


'The end code resets the variables used and prepares to receive another packet
:packetend              mov outa, #0            'Reset the LED to an off state, end of packet
                        rdlong t1, par          'Read in value of datahead
                        wrlong t1, pkadd        'Write the packet length value to the variable for access outside of ASM
                        mov t1, #0              'Reset DataHead variable to do another pass
                        wrlong t1, par          'Update value in the memory
                        jmp #:PacketStart       'Do it all again
                                                                                                         
                        

'The code jumps here if a short packet (less than 512 channels + 1 start byte) is detected.
'This portion of the code cleans up and then returns to waiting for the break to finish
'This is also where a value is stuffed into the packet length to detect a short packet
:shortpacket            mov outa, #0            'Reset the LED to an off state, end of packet
                        rdlong t1, par          'Read in value of datahead
                        wrlong t1, pkadd        'Write the packet length value to the variable for access outside of ASM
                        mov t1, #0              'Reset DataHead variable to do another pass
                        wrlong t1, par          'Update value in the memory
                        jmp #:midbreak          'Jump to the middle of waiting for a break to finish - VERY IMPORTANT

'
'This routine runs while waiting during the break.  It calculates the statistics
'for the DMX packet and stores them to hub ram for use in other programs.
'
TimeCalc                mov t4, mea2            'Move the end of break (start of MAB) value to variable for processing
                        sub t4, mea1            'Take away the start of break time = break time (in clock ticks)
                        wrlong t4, brMea        'Write the value to hub ram

                        mov t4, mea3            'Move the end of MAB value to variable for processing
                        sub t4, mea2            'Take away the start of the MAB = MAB time (in clock ticks)
                        wrlong t4, MABMea       'Write the value to hub ram

                        mov t4, mea4            'Move the end of packet value to variable for processing
                        sub t4, mea1            'Take away the start of packet time = total packet time (in clock ticks)
                        wrlong t4, pkMea        'Write the value to hub ram

                        mov t4, mea1            'Move the start of packet time value to variable for processing
                        sub t4, mea5            'Take away the start time of the previous packet = total packet start to packet start time
                        wrlong t4, br2brMea     'Write the value to hub ram
                        
                        mov mea5, mea1          'Store the current start of packet time to be used at the previous in next pass through
TimeCalc_ret            ret                     'end of routine, return to program                

'Uninitialized Data
rmask         res 1                             'mask for rx I/O pin
lmask         res 1                             'mask for LED I/O pin
t1            res 1                             'temp1
t2            res 1                             'temp2
t3            res 1                             'temp3
t4            res 1                             'temp4
mea1          res 1                             'store data for statistics (start of break/packet)
mea2          res 1                             'store data for statistics (end of break/start of MAB)
mea3          res 1                             'store data for statistics (end of MAB)
mea4          res 1                             'store data for statistics (end of packet)
mea5          res 1                             'store data for statistics (start of break/packet from previous time)
bitticks      res 1                             'Clock cycles per bit
brtime        res 1                             'Lenght of break in clock ticks      
rx            res 1                             'Pin number for receiving
led           res 1                             'Pin number for activity led
rxbits        res 1                             'Counter for receiving bits
rxcnt         res 1                             'Counter for bit timing           
rxdata        res 1                             'Storage of data received (contains 2 stop bits and 8 data bits)
rxbuff        res 1                             'Pointer to beginning of data buffer
rxhead        res 1                             'Location within data buffer
loop          res 1                             'Loop counter for checking number of times to loop
pkadd         res 1                             'A pointer to PacketLength
brMea         res 1                             'A point to BreakMTime
MABMea        res 1                             'A point to MABMTime
pkMea         res 1                             'A point to PacketMTime
br2brMea      res 1                             'A point to Br2BrMTime

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