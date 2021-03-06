{{

┌──────────────────────────────────────────────┐
│ IR2101_PWM.spin                              │
│ driver for IR2010 chips which drive H bridge │
│ for bi directional DC motor PWM control      │
│ Author: Eric Ratliff                         │
│ Copyright (c) 2009 Eric Ratliff              │
│ See end of file for terms of use.            │
└──────────────────────────────────────────────┘
"d" version indicates version with 'with diagnostics'

IR2101_PWMd.spin, H Bridge object for two International Rectifier 2101 driver ICs
2008.4.4 Eric Ratliff, pulled from FullBridge.spin
2008.5.23 Eric Ratliff, derived from TestFullBridgePWM.spin
2009.8.23 Eric Ratliff, releasing to Propeller Object Exchange

The object drives two International Rectifier IR2101 chips for PWM control of a DC motor via an H bridge.
The H bridge can generate DC output voltage from + to - with small incrments of value.
'Full' output is not quite 100%, to allow some charging of the high voltage gate drive circuit at all
times. See "PWM drive schematic.pdf".  This was tested with MOSFETs, but could also be used with IGBTs for higher voltages and currents.
The parameter "Duty" is the how the voltage output is commanded as a fraction of the Period.
The parametere "Period" is the pulse frequency in clocks.  It is 4000 at 20 KHz PWM frequency and 80 MHz clock rate.
The parameter called "Restraint" is untested.  It is intended for regeneration of high output voltage at low RPMs by using
the inductance of the permanent magnet motor as a flyback power supply.
}}

CON
  NumDiag = 15                  ' how many diagnostic longs the assembly cog pushes to hub memory
  
VAR
  long HiLeftPin
  long HiRightPin
  long MinBootClocks            ' minimum clock cycles needed to keep bootstrap charged, about 125 nano seconds (clocks)
  long PWM_Freq                 ' (Hz)

PUB Start(pDuty,pRestraint,pPeriod,LowLeftPin,LowRightPin,pDiag): NewCogID                       '' start a PWM cog
'' change of contents of pPeriod to a non zero value signals that the cog has started
'' this routine is a bit slow because we wait for new cog to load and start
'' Duty is on cycles per period, is current build up time in powering quadrents, current falloff in regenerative quadrents
'' Restraint is a period of unidirectional high impedance that follows a period of charging in the two regenerative quadrents
'' Restraint should be set to zero in powering quadrents to avoid body diode heating due to conduction in the non high impedance direction
'' in the regenerative quadrents the period of free conduction is used to build up current to charge via flyback
'' the free conduction period preceeds charging and restraint periods
'' the duration of the free conduction period is approximately equal to the full PWM period less Duty and Restraint
'' non zero Restraint with zero Duty defines a bi directional high impedance mode, AKA 'towing' mode or 'freewheeling' mode
'  alternativly, I could make negative Restraint define high impedance mode
  PWM_Freq := 20_000
  PWM_Period := clkfreq/PWM_Freq ' calculate clocks per full PWM cycle, save locally
  ' min bootstrap time has been found to depend on load of bridge, so is conservative to allow very low current draw load
  'MinBootClocks := clkfreq/(1_000_000_000/63)  'last number is minimum time needed to charge bootstrap capacitor (ns) at 80 MHz min on=3976
  MinBootClocks := clkfreq/(1_000_000_000/280)  'last number is minimum time needed to charge bootstrap capacitor (ns) at 80 MHz min on=3976

  ' for output to IR 2102 MOSFET driver chip
  'the left half bridge
  HiLeftPin := LowLeftPin+1
  'the right half bridge
  HiRightPin := LowRightPin+1
  
  ' new method for passing by value to the assembly routine, initialize variables before cog load
  ' there's a risk here!  Another call to Start may happen before cog load finishes!
  ' however, it seems the same risk would exist if the assembly pulled parameters from the spin code area
  ' does execution return to calling routine before cog finishes starting?  Probably not.  Then either method is OK.
  ' note that the assembly instructon cognew does resume execution while the cog loads, hopefully the Spin version does not.
  HubPeriodAddress := pPeriod   ' let assembly routine know where in hub the period should be sent
  LowLeftNot    := LowLeftPin
  UpperLeftNot  := HiLeftPin
  LowRightNot   := LowRightPin
  UpperRightNot := HiRightPin
  DiagBaseHubAddress := pDiag
  RestraintHubAddress := pRestraint
  MinBootstrapClocks := MinBootClocks

  LONG[pPeriod] := 0 ' make sure period in calling routine is zero
  
  NewCogID := cognew(@entry, pDuty) ' start assembly cog and report back where it is
  ' wait here until cog starts running, just in case Spin version of cognew resumes execution immediately
  repeat while LONG[pPeriod] == 0 ' has cog not yet set this value?

DAT
''assembly cog which updates the PWM cycle
'for audio PWM, fundamental freq which must be out of auditory range (period < 50?S)
'in this case it is a silent (except for dogs) motor drive application, intended to run at 50?S period
'assumes a MOSFET driver chip such as International Rectifier's IR2102, which has two inverting inputs
'and is a 'high and low side driver' with need to ocassionally drive the high side to keep the bootstrap charged

'using counter a for low side MOSFETs
'using counter b for high side MOSFETs
        org                            ' begin code at address 0
entry
        ' prepare to notify Start routine that cog has loaded
        movd notify, #PWM_Period ' place the cog address to write from
        nop   ' avoid pre fetch of the next instruction
'hang   jmp #hang                               ' hang execution here, for debugging
notify  wrlong 0, HubPeriodAddress              'notify Start routine what period is in clocks, this also notifies that cog has started

        ' set the 4 output pins of this cog
        mov PinMaskHiL, #1                      'start with a 1 value in bit 0
        rol PinMaskHiL,UpperLeftNot             'shift value in bit zero to the bit position of the upper left MOSFET output
        mov DirectionMask, PinMaskHiL           'set output pin for upper left MOSFET
        mov PinMaskHiR, #1
        rol PinMaskHiR, UpperRightNot           
        or DirectionMask, PinMaskHiR            'add the upper right MOSFET's pin as an output
        ' at this time the direction mask holds just the high MOSFET pins
        mov outa, #0                            ' prepare to 'blank' the upper MOSFETS so they don't fire till timers make them do it
        mov PinMaskLoL, #1
        rol PinMaskLoL, LowLeftNot              
        or DirectionMask, PinMaskLoL            'add the lower left MOSFET's pin as an output
        mov PinMaskLoR, #1
        rol PinMaskLoR, LowRightNot             
        or DirectionMask, PinMaskLoR            'add the lower right MOSFET's pin as an output
        mov dira, DirectionMask                 ' now activate our four output pins as outputs, two will go high now

        ' set up control code and start the Low side MOSFET's counter for left side operation
        mov CtraCtrlL, CounterMode              'get mode of operation
        movs CtraCtrlL, LowLeftNot              'establish counter A pin A number, expect it to start in an off state
        mov ctra, CtraCtrlL                     'establish counter A mode and APIN
        mov frqa, #1                            'set counter to increment 1 each cycle, starts counting

        ' set up control code and start the Hi side MOSFET's counter for left side operation
        mov CtrbCtrlL, CounterMode              'get mode of operation
        movs CtrbCtrlL, UpperLeftNot            'establish counter B pin A number, expect it to start in an off state
        mov ctrb, CtrbCtrlL                     'establish counter B mode and APIN
        mov frqb, #1                            'set counter to increment 1 each cycle, starts counting

        ' set up control code for the right Low side MOSFET
        mov CtraCtrlR, CounterMode              'get mode of operation
        movs CtraCtrlR, LowRightNot             'establish counter A pin A number

        ' set up control code for the right Hi side MOSFET
        mov CtrbCtrlR, CounterMode              'get mode of operation
        movs CtrbCtrlR, UpperRightNot           'establish counter B pin A number

        'set up a constant we will use for low side timing
        mov DoubleBothOffDelay,BothOffDelay
        add DoubleBothOffDelay,BothOffDelay
        'set up a constant to ensure enough low cycles for boot charging
        mov MaxOn, PWM_Period
        sub MaxOn, DoubleBothOffDelay
        min MinBootstrapClocks, #1              ' limit the minimum to 1, makcs sure we have at least one clock of boot charging
        sub MaxOn, MinBootstrapClocks

        'mov outa, PinMaskHiR ' hold left upper MOSFET off by putting it's NOT pin high
        'record programming choice for case of 0+ maginitude duty cycles
        mov OriginalLastLoInst, lastlo

        ' we are starting counters in positive mode, so set this up
        call #GoPos

        mov time, cnt                  'record current time
        add time, PWM_Period               'establish next period

        'loop forever
loop          rdlong SDuty, par      'get an up to date pulse width
              mov OnCycles, SDuty wz 'copy pulse width to working variable, save zero check in Z flag
              rdlong Restraint, RestraintHubAddress 'get an up date to restraint
              if_z jmp #ZeroDutyCase 'jump in special case of zero duty cycle
              mov lastlo, OriginalLastLoInst ' restore the normal non zero logic
              jmp #CasesDone
ZeroDutyCase
              mov lastlo, lozero ' modify program logic to have constant low side firing
CasesDone
              abs OnCycles, OnCycles wc         'hide direction so we can limit magnitude, but saves direction in the C flag
SignChangeTest
              'conditional call based on C flag
              nop ' place holder command, to be overwritten by a real sign change test instruction
              'choose lower of commanded and boot charging limit ("limits the maximum", opposite of what "max" would be expected to do)
              max OnCycles, MaxOn

              ' move some sequential cog variables to hub for display on monitor
              mov LoopCount, #NumDiag
              sub LoopCount, #1 ' pre decrement to allow room for non sequential number
              mov DiagCogAddr, #SDuty ' move address of first value to be shown as diagnostic to working cog address variable
              mov DiagHubAddress, DiagBaseHubAddress
DiagLoop
                        movd Writer, DiagCogAddr
                        nop ' to avoid prefetch problem
Writer                  wrlong 0, DiagHubAddress ' note that 0 is a dummy field value here, it is overwritten every loop
                        add DiagCogAddr, #1 ' advance to cog address of next value to push
                        add DiagHubAddress, #4
                        sub LoopCount, #1 wz
                        if_nz jmp #DiagLoop
              'wrlong ctrb, DiagHubAddress ' push a non sequential value, the counter b control, to diagnostics
        
              waitcnt time, PWM_Period 'wait until next period, this instruction begins at time Y and ends at time Z of page 3/20 -1- notes, figure 1
        
              'prepare low side phase value
              mov PhaseLo, MaxNeg 'get at top of positive scale, which is 1 short of being negative, then go one more
              subs PhaseLo, OnCycles ' reduce by on cycles, to be high in positive range
              subs PhaseLo, DoubleBothOffDelay ' reduce more to allow two safe zones to prevent shoot thru
lastlo        subs PhaseLo, Restraint ' reduce more to allow some unidirectional high impedance time
              'prepare hi side phase value
              neg PhaseHi, OnCycles ' drop a measured amount below zero

              'between time T and Q here, may optionally change side of bridge that pulses
ModeChange    nop       'initial place holder command for where we will call a routine when changing modes
              'load phase values, this instructin defines time "Q" of page 3/15 -4- diagrams
              mov phsa, PhaseLo ' load low side phase value
              nop               ' delay 4 clocks
              'this instruction ends at time "R" of page 3/15 -4- notes, figure 2
              mov phsb, PhaseHi ' load hi side phase value
              jmp #loop         'loop for next cycle
'-------------------------------------------------------------------------
'special instructions intended for moving around at run time
lozero  mov PhaseLo, MaxNeg     ' load huge negative number to phase A preparation variable, for special case of zero duty cycle, to keep lower MOSFET on
CSetGoNeg     IF_C mov ModeChange, CallGN       ' conditionally replace nop with call to GoNeg at "ModeChange"
CSetGoPos     IF_NC mov ModeChange, CallGP      ' conditionally replace nop with call to GoPos at "ModeChange"
CallGN        call #GoNeg
CallGP        call #GoPos                       ' dummy command to hold place of the call that happens at time of mode change
ANop          nop
'-------------------------------------------------------------------------

' routine to implement change from positive to negative duty cycle
GoNeg   ' Right side will now become the active (pulsing) side of the bridge
        mov ctrb, #0 ' hold left upper MOSFET off by immediately disabling timer B
        ' note, we assume the upper MOSFET has not been fixed on by an output bit
        mov outa, PinMaskLoL ' hold left lower MOSFET on by putting it's pin high
        mov ctra, CtraCtrlR ' load counter A control Right version (for lower MOSFET)
        mov ctrb, CtrbCtrlR' load counter B control Right version  (for upper MOSFET)
        mov ModeChange, ANop' set "nop" at "ModeChange" (which is where calls to this routine originate)
        mov SignChangeTest, CSetGoPos ' set instruction at "SignChangeTest" for conditional insertion of call instruction at "ModeChange"
        add time, SignChangeTime ' extend this cycle exactly extra time spent changing sign
GoNeg_ret     ret
'-------------------------------------------------------------------------

' routine to ground IR2101 on left
Gnd2101L   ' to prepare for Right side becoming the active (pulsing) side of the bridge
        mov ctrb, #0 ' hold left upper MOSFET off by immediately disabling timer B
        ' note, we assume the upper MOSFET has not been fixed on by an output bit
        mov outa, PinMaskLoL ' hold left lower MOSFET on by putting it's pin high
Gnd2101L_ret  ret
'-------------------------------------------------------------------------

' routine to ground IR2101 on right
Gnd2101R   ' to prepare for left side becoming the active (pulsing) side of the bridge
        mov ctrb, #0 ' hold right upper MOSFET off by immediately disabling timer B
        ' note, we assume the upper MOSFET has not been fixed on by an output bit
        mov outa, PinMaskLoR ' hold left lower MOSFET on by putting it's pin high
Gnd2101R_ret  ret
'-------------------------------------------------------------------------

' routine to open IR2101 on left  or right
Open2101L ' to prepare for Right side becoming the active (pulsing) side of the bridge
        mov outa, #0 ' remove any holding of lower MOSFETs on (upper MOSFETS are never held on)
        mov ctrb, #0 ' stop any timed firing of upper MOSFETs by disabling timer B
        mov ctra, #0 ' stop any timed firing of lower MOSFETs by disabling timer A
Open2101L_ret ret
'-------------------------------------------------------------------------

' routine to implement change from positive to negative duty cycle
GoPos   ' Right side will now become the active (pulsing) side of the bridge
        mov ctrb, #0 ' hold right upper MOSFET off by immediately disabling timer B
        ' note, we assume the upper MOSFET has not been fixed on by an output bit
        mov outa, PinMaskLoR ' hold left lower MOSFET on by putting it's pin high
        mov ctra, CtraCtrlL ' load counter A control Left version (for lower MOSFET)
        mov ctrb, CtrbCtrlL' load counter B control Left version  (for upper MOSFET)
        mov ModeChange, ANop' set "nop" at "ModeChange" (which is where calls to this routine originate)
        mov SignChangeTest, CSetGoNeg ' set instruction at "SignChangeTest" for conditional insertion of call instruction at "ModeChange"
        add time, SignChangeTime ' extend this cycle exactly extra time spent changing sign 
GoPos_ret     ret
'-------------------------------------------------------------------------

' Constant Initialized data
CounterMode   long %00100 << 26 'counters mode, NCO/PWM, single-ended
BothOffDelay  long 8            'how long we must have both MOSFETs off to prevent shoot through (clocks, at 80 Mhz, i.e. units of 12.5 nano seconds)
MaxNeg        long $80000000    'lowest possible signed 32 bit integer
SignChangeTime          long 32 ' extra time used on a mode change cycle (clocks)    

' Data to be initialized by Spin prior to assembly cog launch
DiagBaseHubAddress long 0 'base of hub memory to push the current diagnostic value
RestraintHubAddress long 0 'hub memory where we will find restraint value
HubPeriodAddress long 0   ' where in hub memory to report full cycle length in clocks
MinBootstrapClocks long 0 'clocks required to charge bootstrap circuit

' Data in diagnostic order, fake initialized, spin initialized, or intentional design time initialized
' These are grouped by 3's because three integers fit across the video screen on each line
' these are in order of diagnostic reporting for display on TV monitor via simple loop                  diagnostic index
SDuty         long 0    'signed duty commanded, fake initialized so that address works                  0
OnCycles      long 0    'time of high voltage state (clocks)                                            1
PWM_Period    long 0    'time of full cycle (clocks)                                                    2

LowLeftNot    long 0    'pin for lower left MOSFET                                                      3
UpperLeftNot  long 0    'pin for upper left MOSFET                                                      4
LowRightNot   long 0    'pin for lower right MOSFET                                                     5

UpperRightNot long 0    'pin for upper right MOSFET                                                     6
PinMaskLoL    long 0    'mask showing where output pin for low side MOSFET is                           7
PinMaskHiL    long 0    'mask showing where output pin for high side MOSFET is                          8

PinMaskLoR    long 0    'mask showing where output pin for low side MOSFET is, right side               9
PinMaskHiR    long 0    'mask showing where output pin for high side MOSFET is, right side              10
PhaseLo       long 0    'phase load for high side's timer                                               11
              
PhaseHi       long 0    'phase load for high side's timer                                               12
MaxOn         long 0    'maximum on cycles that allow for boot charging                                 13
'             ctrb      'the counter B control register, added to diagnostics manually after loop       14

' Uninitialized data
' MOSFET driver pins
' "Not" indicates that the destination is an inverting input
time                    res 1
CtraCtrlL               res 1   'for fully constructed counter a control register value, left side
CtrbCtrlL               res 1   'for fully constructed counter a control register value, left side
CtraCtrlR               res 1   'for fully constructed counter a control register value, right side
CtrbCtrlR               res 1   'for fully constructed counter a control register value, right side
DoubleBothOffDelay      res 1   'time for two saftey periods to prevent shoot thru at two transitions (clocks)
OriginalLastLoInst      res 1   'place to store original contents of the last instruction preparing phase A value
DirectionMask           res 1   'bitmap value to push to the A direction register

LoopCount               res 1   'diagnostic push loop counter
DiagCogAddr             res 1   'working address for current diagnostic in cog that we are about to push to hub
' diagnostic hub addresses for repeated writing
DiagHubAddress          res 1   'hub memory to push the current diagnostic value
Restraint               res 1   'cog variable for unidirectional high impedance period

FIT 496 ' make compiler generate warning if program is too big
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
