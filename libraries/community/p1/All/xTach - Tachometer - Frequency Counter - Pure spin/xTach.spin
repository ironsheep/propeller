{{
┌───────────────────────────────────────────────────┐
│ xTach.spin version 1.0.0                          │
├───────────────────────────────────────────────────┤
│                                                   │               
│ Author: Mark M. Owen                              │
│                                                   │                 
│ Copyright (C)2014 Mark M. Owen                    │               
│ MIT License - see end of file for terms of use.   │                
└───────────────────────────────────────────────────┘

Description:
  Provides a simple set of methods for determining the activity on an input pin:
        Pulse width in system clock ticks
        Pulse frequency in Hz (cycles per second)
        Pulses per minute
        Revolutions per minute

  Has been tested using a signal generator from 1Hz to 50kHz and found to be
  accurate to better than 98% over the range tested with the largest errors at
  frequencies less than 30Hz (2%).

Revision History:
  Initial version               2014-10-16 MMOwen
  Added Decay function          2014-10-18 MMOwen

}}

VAR
  long  cog
  long  stack[8]
  long  dT           

PUB Start(pin) | i
{{
    Initiates a pulse timer in a new COG using a designated pin as input

    Parameters:
      pin - signal source input pin

    Returns:
      cog number + 1 if pulse timer is successfully started
      zero if no cog is available
}}                                                                                         
  dT~
  return (cog := cognew(PulseTimer(pin), @stack) + 1)

PUB Stop
{{
    Terminates the pulse timer

    Parameters:
      none

    Returns:
      nothing
}}                                                                                         
  if cog
    cogstop(cog~ - 1)

PUB PulsePktoPkTicks
{{
    Returns the number of system counter ticks between the peaks of
    the input signal.

    Parameters:
      nont

    Returns:
      number of system counter ticks between the peaks of the input signal
}}                                                                                         
  return dT

PUB Hz
{{
    Calculates and returns the input signal frequency in cycles
    per second (Hertz)

    Parameters:
      none

    Returns:
      input signal frequency in cycles per second (Hertz)
}}                                                                                         
  return clkfreq/dT

PUB PulsesPerMinute
{{
    Calculates and returns the number of pulses per minute
    occuring on the input signal.

    Parameters:
      none

    Returns:
      number of pulses per minute
}}                                                                                         
  return  60*Hz

PUB RevolutionsPerMinute(PulsesPerRev)
{{
    Calculates and returns the number of revolutions per minute
    represented by a given number of pulses per revolution and
    the number of pulses per minute of the input signal.

    Parameters:
      PulsesPerRev - number of pulses per revolution

    Returns:
      number of revolutions per minute
}}                                                                                         
  return 60*Hz/PulsesPerRev

PUB Decay
{{
    Decrements the cached output value to deal with loss of input signal.
    When the input signal settles at some DC state PulseTimer will hang
    awaiting a state change on the input pin resulting in a constant value
    being returned by the preceeding four functions.  Calling Decay after
    obtaining the result of these functions causes the return value to
    return to zero under lost signal conditions.
     
    Parameters:
      none

    Returns:
      nothing
      
}}
  dT-=clkfreq/1000
  dT#>=0

PRI PulseTimer(p) | t
{
    Repeatedly determines the duration of a pulse in system counter ticks
    and caches that value in a system memory location for use by the public
    functions above.

    Parameters:
      p - signal source input pin

    Returns:
      nothing - runs continuously until terminated by cogstop
}                                                                                         
  dira[p]~
  p := |< p           ' mask
  repeat
    waitpne(p,p,0)    ' await low state
    waitpeq(p,p,0)    ' await high state
    t := cnt          ' note current system counter value
    waitpne(p,p,0)    ' await low state 
    waitpeq(p,p,0)    ' await high state 
    dT := ||(cnt-t)   ' calculate pulse duration in system counter ticks
      
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