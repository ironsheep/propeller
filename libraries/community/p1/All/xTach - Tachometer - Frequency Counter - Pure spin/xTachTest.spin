{{
┌───────────────────────────────────────────────────┐
│ xTachTest.spin version 1.0.0                      │
├───────────────────────────────────────────────────┤
│                                                   │               
│ Author: Mark M. Owen                              │
│                                                   │                 
│ Copyright (C)2014 Mark M. Owen                    │               
│ MIT License - see end of file for terms of use.   │                
└───────────────────────────────────────────────────┘

Description:
  Demonstrates usage of the xTach methods for determining the activity
  on an input pin:
        Pulse width in system clock ticks
        Pulse frequency in Hz (cycles per second)
        Pulses per minute
        Revolutions per minute

  Uses the Parallax Serial Terminal for output at 115,200 baud for output.
  
  Written as a means of circumventing jitter found to be present when using
  assembly language frequency counters for low frequency signals (in my case
  a belt driven aircraft prpeller with 39 teeth per revolution on the main
  drive pully which runs at a maximum of 3600 revolutions per minute).

  Has been tested using a signal generator from 1Hz to 50kHz and found to be
  accurate to better than 98% over the range tested with the largest errors at
  frequencies less than 30Hz (2%).

Revision History:
  Initial version               2014-10-16 MMOwen
  Added Decay function          2014-10-18 MMOwen

}}
CON
  _clkmode = xtal1 + pll16x                  ' System clock → 80 MHz
  _xinfreq = 5_000_000                       ' external crystal 5MHz

  TACH_PULSES_PER_REVOLUTION    = 39
                                                 
OBJ
  TACH          : "xTach"
  pst           : "Parallax Serial Terminal"

PUB Main 
  EnablePST
 
  TACH.Start(8)

  pst.Position(0,0)
  pst.Str(string("PkPkTicks"))
  pst.Position(15,0)
  pst.Str(string("Hz"))
  pst.Position(30,0)
  pst.Str(string("Pulses/Min"))
  pst.Position(45,0)
  pst.Str(string("RPM"))
  repeat 
    pst.Position(0,1)
    pst.ClearEnd
    pst.Dec(TACH.PulsePktoPkTicks)
    pst.Position(15,1)
    pst.Dec(TACH.Hz)
    pst.Position(30,1)
    pst.Dec(TACH.PulsesPerMinute)
    pst.Position(45,1)
    pst.Dec(TACH.RevolutionsPerMinute(TACH_PULSES_PER_REVOLUTION))
    TACH.Decay
    waitcnt(clkfreq/5+cnt)

PRI EnablePST
  pst.start(115200)
  repeat 
    pst.Home
    pst.Clear
    pst.str(string("Start tests: press ."))
    pst.newline
    repeat while not pst.RxCount
      pst.Char("~")
      waitcnt(clkfreq+cnt)
    if pst.CharIn == "."
       quit
  pst.Home
  pst.Clear
        