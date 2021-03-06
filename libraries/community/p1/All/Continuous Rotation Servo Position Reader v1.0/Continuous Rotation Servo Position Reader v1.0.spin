{{
********************************************************
* Using a continuous rotation Servo as an input device *
* Author: Beau Schwabe                                 *
* Copyright (c) 2013 Parallax                          *
* See end of file for terms of use.                    *
********************************************************
}}

CON
    _clkmode = xtal1 + pll16x                           
    _xinfreq = 5_000_000                                'Note Clock Speed for your setup!!

    ServoCh1 = 0                                        'Select DEMO servo
    SensePin = 1

    CalibrationSamples = 200



{{
Schematic:


Servo Connector:                  Propeller 

  Black ───────────────────────── Vss
                          100
  Red   ──────────────┳──────── +5V
                330    │
  White ────────────┼────────── Servo Signal   (Pin 0)
                       │
                        330
                       ┣────────── Sense Pin      (Pin 1)
                        330
                       │
                       
                      Vss

}}    

OBJ
  SERVO : "Servo32v9.spin"
  PST   : "Parallax Serial Terminal"

PUB Servo32_DEMO | ServoRead,ServoCal
    PST.Start(19200)

    SERVO.Start                                         'Start Servo handler
    SERVO.Set(ServoCh1,1500-20)                         'Force Servo to Center and add slight offset

                                ''Note: Manually calibrate servo so that a pulse of 1500
                                ''      Normally makes it stop using the set screw on the servo
                                

    Ctra := %01000<<26|SensePin                         'POS detector
    Ctrb := %01100<<26|SensePin                         'NEG detector

    repeat CalibrationSamples                           'Calibrate Servo
      PST.str(String("Calibrating Servo...",13))
      ServoCal += ReadServo
    ServoCal /= CalibrationSamples

    PST.str(String(13,"Servo is Ready.",13,"Try turning it with your hand",13))

    repeat
      ServoRead := ReadServo - ServoCal
      Case ServoRead
        100..2000   : PST.str(String("CW  direction : "))
                      PST.dec(ServoRead)
                      PST.char(13)

        -100..-2000 : PST.str(String("CCW direction :"))
                      PST.dec(ServoRead)
                      PST.char(13)                

      
PUB ReadServo
    frqa := 0                                           'Stop Counters
    frqb := 0
    phsa := 0                                           'Clear Counters
    phsb := 0
    frqa := 1                                           'Start Counters
    frqb := 1
    waitcnt(clkfreq/50+cnt)                             'Time Counters for 20ms  (1/50th of a second)
    result := (phsa - phsb)/1024                         'Read Counter difference

DAT
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