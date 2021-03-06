{{PropBOE Wheel Calibration
Generates correction factors for the PropBOE-Bot Servo Drive.spin object.
For each target speed, this object will adjust the faster motor to match the slower motor speed.
When the testing is completed, the routine will write the code to be pasted into the
DAT block of the PropBOE-Bot Servo Drive.spin object to a microSD card.
Used a microSD card, as I could not copy the results from the Parallax Serial Terminal,
this also allows the routine to be run without the PropBOE being connected to a
Computer. 

See end of file for author, version, copyright and
terms of use.
}}


CON
'Change to set the pins used on the PropBOE-BOT
  LeftServo    = 18
  RightServo   = 19
  LeftEncoder  = 1
  RightEncoder = 0
  StartLED     = 6                        'Optional LED to indicate program start
  StopLED      = 5                        'Optional LED to indicate program complete
  speedCnt     = 13                       'Number of speed steps for Servo Object
  speedStep    = 25                       'Speed change per step
  speedStart   = -150                     'Initial Speed
VAR
   long Target[speedCnt], RightM[speedCnt], LeftM[speedCnt], i, Rticks[speedCnt], Lticks[speedCnt], Error

DAT
        HeadLine        byte 9,9,"Target",9,"Left",9,9,"Right",13,0
        RobotFileName   byte "Teachers.txt",0            'File name for microSD Card. 
OBJ
  system  : "Propeller Board of Education"               ' PropBOE configuration tools
  servo   : "PropBOE Servos"                             ' Servo control object
  pst     : "Parallax Serial Terminal Plus"              ' Debug Terminal
  time    : "Timing"                                     ' Timing convenience methods
  pin     : "Input Output Pins"                          ' I/O convenience methods
  Encoder : "PropBOE Wheel Encoders"                     ' Read routines for Wheel Encoders
  sd      : "PropBOE MicroSD"                            ' MicroSD Card to Store Code
PUB Go
'Set the Clock Speed
  System.clock(80_000_000)
'Start the Wheel Encoder
  Encoder.Start(RightEncoder,LeftEncoder)
'Flash Light for start - if the LED flashes during test => low batteries.
  repeat 5
    Pin.High(StartLED)
    time.pause(500)
    Pin.Low(StartLED)
    time.pause(500)
'Fill in the table with default speeds
pst.clear
pst.str(string("Starting Calibration"))
pst.NewLine
pst.str(@HeadLine)
  repeat i from 0 to speedCnt - 1
    Target[i]:= speedStart + i*speedStep
    RightM[i]:= speedStart + i*speedStep
    LeftM[i] := speedStart + i*speedStep
'Begin calibration
  repeat i from 0 to speedCnt - 1
        pst.str(string("Starting Cal for: "))
        DoReport
     RunTest
    'Deterime the faster motor and adjust speeds to match
     repeat until Error =< 1 
          pst.str(string("Adjusting Speeds: "))
          DoReport
        if Target[i] < 0                    'Need to Add 1 to move closer to 0                      
          if Lticks[i] > Rticks[i]          'Left faster 
            ++LeftM[i]
          else
            ++RightM[i]
        if Target[i] > 0                    'Need to Subtract 1 to move closer to 0                      
          if Lticks[i] > Rticks[i]          'Left faster
            --LeftM[i]
          else
            --RightM[i]
      RunTest
     pst.str(string("Finished Cal for: "))
     DoReport
          
    'Report the Results
  pst.str(string("Final Test Results:"))
  pst.NewLine
      repeat i from 0 to speedCnt - 1    
       DoReport
  pst.str(string("Saving Calibration to MicroSD Card"))
  pst.NewLine
'Write the calibration Numbers to the MicroSD card
  sd.Mount(0)
  sd.FileNew(@RobotFileName)
  sd.FileOpen(@RobotFileName, "W")
    sd.WriteStr(String("Calibration Data for:"))
    sd.WriteStr(@RobotFileName)
    sd.writeStr(String(13,10))  

    sd.WriteStr(String("  speedCnt        long "))
    sd.WriteDec(speedCnt)
    sd.WriteByte(13)                             ' Carriage return
    sd.WriteByte(10)                             ' New line

    sd.WriteStr(String("  targetSpeeds    long "))    
    repeat i from 0 to speedCnt - 1
       If i > 0
        sd.WriteStr(string(","))
       sd.WriteDec(Target[i])
    sd.WriteByte(13)                             ' Carriage return
    sd.WriteByte(10)                             ' New line

    sd.WriteStr(String("  leftSpeeds      long "))    
    repeat i from 0 to speedCnt - 1
       If i > 0
        sd.WriteStr(string(","))
       sd.WriteDec(LeftM[i])
    sd.WriteByte(13)                             ' Carriage return
    sd.WriteByte(10)                             ' New line

    sd.WriteStr(String("  rightSpeeds     long "))    
    repeat i from 0 to speedCnt - 1
       If i > 0
        sd.WriteStr(string(","))
       sd.WriteDec(RightM[i])
    sd.WriteByte(13)                             ' Carriage return
    sd.WriteByte(10)                             ' New line
  sd.FileClose  
  sd.Unmount  

pst.str(string("Run Completed"))
pst.str(string("Power Off Robot and remove MicroSD Card"))

'Flash Light to show the Calibration is Finished
  repeat 
    Pin.High(StopLED)
    time.pause(500)
    Pin.Low(StopLED)
    time.pause(500)
    

PRI AlingWheels
{This routine is used to set both wheels in the same position relative to the encoders}
  'Left Wheel
    servo.set(LeftServo,10)
    If pin.in(LeftEncoder) == 1
      repeat until pin.in(LeftEncoder)==0
    repeat until pin.in(LeftEncoder)==1
    servo.set(LeftServo,0)
  'Right Wheel
    servo.set(RightServo,-10)
    If pin.in(RightEncoder) == 1
      repeat until pin.in(RightEncoder)==0
    repeat until pin.in(RightEncoder)==1
    servo.set(RightServo,0)

PRI RunTest
    AlingWheels
    Error := 0                  
    servo.set(LeftServo,LeftM[i])
    servo.set(RightServo,-RightM[i])
    time.pause(500)             'allow motors to come up to speed
    Encoder.reset               'reset the encoders
    time.pause(10000)            'let it run
    Lticks[i] := Encoder.ReadLeft
    Rticks[i] := Encoder.ReadRight
    servo.set(LeftServo,0)
    servo.set(RightServo,0)
    Error := ||(Rticks[i] - Lticks[i])
    time.pause(3000)    'this allows the batteries to recover slightly between tests

PRI DoReport
        pst.dec(Target[i])
        pst.Tab
        pst.dec(LeftM[i])
        pst.Tab
        pst.dec(Lticks[i])
        pst.tab
        pst.dec(RightM[i])
        pst.Tab
        pst.dec(Rticks[i])
        pst.NewLine

DAT
{{
File: PropBOE-Bot Servo Drive.Spin
Date: September 6, 2012
Version: 1.0
Author: Richard Brockmeier

Copyright (c) 2012 Richard Brockmeier

┌────────────────────────────────────────────┐
│TERMS OF USE: MIT License                   │
├────────────────────────────────────────────┤
│Permission is hereby granted, free of       │
│charge, to any person obtaining a copy      │
│of this software and associated             │
│documentation files (the "Software"),       │
│to deal in the Software without             │
│restriction, including without limitation   │
│the rights to use, copy, modify,merge,      │
│publish, distribute, sublicense, and/or     │
│sell copies of the Software, and to permit  │
│persons to whom the Software is furnished   │
│to do so, subject to the following          │
│conditions:                                 │
│                                            │
│The above copyright notice and this         │
│permission notice shall be included in all  │
│copies or substantial portions of the       │
│Software.                                   │
│                                            │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT   │
│WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,   │
│INCLUDING BUT NOT LIMITED TO THE WARRANTIES │
│OF MERCHANTABILITY, FITNESS FOR A           │
│PARTICULAR PURPOSE AND NONINFRINGEMENT. IN  │
│NO EVENT SHALL THE AUTHORS OR COPYRIGHT     │
│HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR │
│OTHER LIABILITY, WHETHER IN AN ACTION OF    │
│CONTRACT, TORT OR OTHERWISE, ARISING FROM,  │
│OUT OF OR IN CONNECTION WITH THE SOFTWARE   │
│OR THE USE OR OTHER DEALINGS IN THE         │
│SOFTWARE.                                   │
└────────────────────────────────────────────┘
}}      