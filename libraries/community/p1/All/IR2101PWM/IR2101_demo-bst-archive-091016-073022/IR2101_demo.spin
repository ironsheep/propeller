{{

┌──────────────────────────────────────────────┐
│ IR2101_demo.spin                             │
│ tests dual H bridge driver                   │
│ Author: Eric Ratliff                         │               
│ Copyright (c) 2009 Eric Ratliff              │               
│ See end of file for terms of use.            │                
└──────────────────────────────────────────────┘
                                         
IR2101_demo.spin, to test H Bridge object for two International Rectifier 2101 driver ICs                                                                           
2008.4.4 Eric Ratliff, pulled from FullBridge.spin                                                                                       
2008.5.23 Eric Ratliff, derived from TestFullBridgePWM.spin                                                                              
2009.10.16 Eric Ratliff, releasing to Propeller Object Exchange

The tested object drives two International Rectifier IR2101 chips for PWM control of a DC motor via an H bridge.
The H bridge can generate DC output voltage from + to - with small incrments of value.  See "PWM drive schematic.pdf".
This was tested with MOSFETs, but could also be used with IGBTs for higher voltages
and currents.

The parameter "Duty" (input) is the how the voltage output is commanded as a fraction of the Period.  'Full' output is
internally limited to a little less than 100%, to allow some charging of the high voltage gate drive circuit at all times.
The parameter "Period" (output) is the pulse frequency in clocks.  It is 4000 at 20 KHz PWM frequency and 80 MHz clock rate.
The parameter called "Restraint" (input) is untested.  Just leave "Restraint" at 0 for normal motor control.  It is intended
for regeneration of high output voltage at low RPMs by using the inductance of the permanent magnet motor as a flyback power
supply.  "Restraint" creates a period of high impedance in the cycle.

The test program generates a voltage ramp from zero motor speed to full + direction, then ramps down to full - direction then
back to full + forever.
}}                                       
                                         
CON _clkmode = xtal1 + pll16x
    _xinfreq = 5_000_000
    IncStep = 2

OBJ
  PWM  :       "IR2101_PWM"

VAR
  long Duty                     ' commanded on time clock cycles in each period (clocks)
  long Restraint                ' for flyback regeneration, leave at zero for most applications
  long LowLeftPin               ' for positive active side Left on schematic, not in test circuit layout
  long LowRightPin              ' for negative active side Right on schematic, not in test circuit layout
  long RampDuration_ms          ' time to go thru entier ramp of dyty cycle (milliseconds)
  long StepsToFullOn            ' how many increments of duty cycle value it takes to get to full on
  long IncTime_C                ' wait between changes in duty cycle (clocks)
  long inc                      ' current duty increment for up or down, 1 or -1 likely, depending on specified step (clocks)
  long Period                   ' clock cycles of PWM period (clocks)
  long PWMCogID                 ' place for telling where the PWM cog is

PUB go | x          ' x is the 'duty model' loop increments it, duty cycle follows it within limits
''test main to call the Spin routing that starts the assembly routine

  RampDuration_ms := 7_500 ' ramp time

  ' for output to IR 2101 MOSFET driver chip
  'the left half bridge
  LowLeftPin := 6
  'the right half bridge
  LowRightPin := 10
  
  PWMCogID := PWM.Start(@Duty,@Restraint,@Period,LowLeftPin,LowRightPin) ' start a PWM cog

  StepsToFullOn := Period/IncStep  ' find how many steps it will take duty increment loop to go from 0 to full
  ' find out how many clocks are needed per step of increment loop
  IncTime_C := RampDuration_ms*(clkfreq/(1000*StepsToFullOn))
  
  x := 0                        ' start point
  inc := IncStep                ' start direction
  repeat
    'Duty := (40*Period)/100   'a constant assignment here makes voltage output constant (%)
    Duty := x                  ' (clocks)
    waitcnt(IncTime_C + cnt) 'wait a little while before next update
    if x => Period              ' at top?
      inc := -IncStep           ' start going down
    if x =< -Period             ' at bottom?
      inc := IncStep            ' start going up
    x := x + inc                ' change duty model one increment

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
