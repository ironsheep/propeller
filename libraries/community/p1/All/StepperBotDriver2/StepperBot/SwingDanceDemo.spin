


{{ **************************************************************************************
   *                                                                                    *     
   *  Stepper Motor Robot - Demo of Line Finding/Following Via Infrared Sensors with    *
   *                        Collision Avoidance via a Ping Sensor and Sound Effects via *
   *                        a Sound Pal                                                 *
   *                                                                                    *
   *  Using Propeller Board of Education, 28BYJ48-12-300 Motor, ULN2003 Motor Controller*
   *        SoundPal, ROHM RPR-359 Reflective Infrared Sensors, Ping Sensor,            *
   *        9.6 V Rechargable, Foam Rollers(for Feed Motor), Toy Wheels and Homemade    *
   *        Chassis                                                                     * 
   *                                                                                    *
   *  Each step is 5.626 degrees / 64 (gear reduction) or 0.087890625 degrees           *
   *  The coils are energized in 8 steps or 0.703125 degrees (8*0.087890625 degrees)    *
   *  Each revolution is 360 degrees/0.087890625 degrees/rev or 4096 steps or           *
   *  512 8-steps cycles.  This code uses a 4 step coil sequence which is slightly      *
   *  faster with less torque by skipping 1/2 steps.                                    *
   *                                                                                    *
   *  This code launches a control method for each motor in an independent cog.  The    *
   *  main code commands the motors by updating parameters of speed, distance, direction*
   *  distance to the target, and brakes.  The motor updates the main code and allows   *
   *  coordination by passing parameters back of remaining distance, remaining distance *
   *  to target and motor in motion.  The main code using a control loop to read        *
   *  sensors, determine status, define needed action and coordinate commands between   *
   *  motors.                                                                           *    
   *                                                                                    *
   *  Gregg Erickson - 2013 (MIT License)                                               *
   *                                                                                    *
   **************************************************************************************
                 
   Vdd(5.0v)--> ULN2003(s), SoundPal, Ping for Power
   P0..P3 --> ULN2003 Control Pins for Right Motor 
   P4..P7 --> ULN2003 Control Pins for Left Motor
   P8..P9 <-- 100 Ohm <-- Vdd(3.3) or <--Vss for Binary Selection of Mailbox 
   P10..P11 <-- 100 Ohms <-- IRSensor Output --> 100K ohms --> Vdd(5.0v)
   P12..P13 --> Sensor Indicator LEDs --> 100 Ohms --> Vss
   P14 <-- 1000K <-- Ping Signal Pin
   P16..P19 --> ULN2003 Control Pins for Feed Motor

                
}}

        

CON
        _clkmode = xtal1 + pll16x   ' Set Prop to Maximum Clock Speed
        _XinFREQ = 5_000_000
  
                                    ' Case Constants for Motor Commands of Move Methods Copied from StepperBotDriver
                                    
        RightTurn=1                 ' Pivot to the Right by Stopping the Right Wheel and Forward on the Left
        LeftTurn=0                  ' Pivot to the Left by Stopping the Left Wheel and Forward on the Right
        Straight=2                  ' Both Wheel Same Direction and Speed
        RightTwist=3                ' Twist Right by Reversing Right Wheel and Forward on the Left Wheel
        LeftTwist=4                 ' Twist Left by Reversing Left Wheel and Forward on the Right Wheel
        LeftCurve=5                 ' Curve Left by Running Left Wheel Proportionally Slower than the Right
        RightCurve=6                ' Curve Right by Running Right Wheel Proportionally Slower than the Left
        DumpRight=7                 ' Dump Right by Rotating Dispensing Motor
        DumpLeft=8                  ' Dump Left by Rotating Dispensing Motor 


                                    ' Stepper Motor Sequence to Distance Conversion Ratios Copied from StepperBotDriver
    
        InchTicks=53                ' Motor Sequences to Move a Wheel 1 inch
        CentiTicks=21               ' Motor Sequences to Move a Wheel 1 Centimeter
        RevTicks=512                ' Motor Sequences to Rotate a Wheel 360 Degrees
        TwistDegTicks=3             ' Motor Sequences to Rotate 1 Degree Using 2 Wheels
        TurnDegTicks=6              ' Motor Sequences to Pivot 1 Degree Using 1 Wheel  

        MailBoxSpacing=13           ' Target Distance in Centimeters from End of Line
        RotationOffset=9            ' Offset of Sensor from End of Line after 180 Degree Rotation
        DumpOffset=15               ' Offset from Sensor to Feed Dispensor

                                    ' Pins for Inputs and Outputs

        PingPin=15                  ' Pin for Ping Sensor 
        LeftIRPin=10                ' Pins for IR Sensor 
        RightIRPin=11         
        LeftLED=12                  ' Pins for (IR Sensor) Indicators
        RightLED=13

                                    ' Stepper Sequence Constants
        Full=0
        Half=1
        Wave=2                            
 
        
Var
      ' These Motor Variable MUST Be in Order of Left, Right, Feed

        Long LeftPin,RightPin,FeedPin                  ' First Pin of Each Motor
        Long LeftSteps,RightSteps,FeedSteps            ' Steps per Rotation 4 or 8
        Long LeftSpeed, RightSpeed,FeedSpeed           ' Speed of Each Motor, 0 to 500 (Max Limit for Specific Motor)
        Long LeftDist, RightDist,FeedDist              ' Primary Count for Maximum Distance for Motor to Drive, each step is ~1/4 inches
        Long LeftTarget,RightTarget,FeedTarget         ' Secondary Count of Distance for Motor Drive to Target, Secondary Maximum
        Long LeftBrake, RightBrake,FeedBrake           ' Set Brakes When Not in Motion by Energizing All Coils, 1=Energized, 0=Off
        Long LeftOdometer,RightOdometer,FeedOdometer   ' Odometer
        Long LeftTrip, RightTrip,FeedTrip              ' Trip Odometer 
        Long LeftLock,RightLock,FeedLock               ' In Motion Flags, True or False

      ' Line Sensor and Targeting Variables

        Long IRSensor,ActualIRSensor,LastValid         ' IR Sensor Value, Actual Reading and Previous Reading
                                                       ' where 0=Neither Sensor Sees the Line, 1=Line to Right, 2=Line to Left, 3=Both on Line                                                                                                                                                
        Byte EndofLine,BeginOfLine,BeginFinal          ' Status of Line Detection for Special Cases
        Long TargetDistance                            ' Distance to Target 


      ' Ranging Variables  
        Long Range                                     ' Range in Centimeters by Png Sensor
        Long MailBox,MailBoxDistance                   ' Mailbox Number and Calculated Distance
        Long TurnRatio, TurnCount                      ' Wheel Ratio and Counter
          
OBJ

       Drive: "StepperBotDriver2"                      ' Object to Run a Stepper Motor Robot with IR Line Sensor and Ping Ranging
       Serial: "FullDuplexSerial"                      ' Serial Object For Debugging
       SoundPal : "SoundPAL"                           ' SoundPal Object for Sound Effects


Pub Main  | i,j,k
                                                                                                         
'--------------------------------------------------------------------------------------------------------------
'-------------------- Set Initializing Variables --------------------------------------------------------------
'--------------------------------------------------------------------------------------------------------------

      LeftPin:=4                          ' Define First of 4 Pins for Each Motor
      RightPin:=0
      FeedPin:=16
            
      LeftSteps:=Full                        ' Define Number of Steps per Cycle for Each Motor
      RightSteps:=Full
      FeedSteps:=half                     

      TurnCount:=0                        ' Initial Zero for Rotation Counter
      TurnRatio:=100                        ' Initial Ratio of Opposite Side Wheel Rotations During Turns
      IRSensor:=0
      LastValid:=0                        ' Initial Last Valid Condition of IR Sensors, No Line Sensed

      BeginFinal:=false                   ' Initial Condition is Beginning of Line Not Found
      EndofLine:=false                    ' Initial Condition is End of Line Not Found

                                                                              
      Mailbox:=ina[9..8]+1                                                    ' Read MailBox Number in Binary from Pins 8 & 9
                                                                              ' The four mailboxes can now be selected ( 00,01,10,11)
                                                                              ' by setting the input to 2 pins. (The mailbox number -1 in binary)
                                                                              ' to ground or Vdd
      MailBoxDistance:=Mailbox*MailBoxSpacing                                 ' Calculate Offset of Mailbox from End of the Line  
      TargetDistance:=(MailBoxDistance-RotationOffset+DumpOffset)*Centiticks   'Distance of Target After End of Line Found, In Centimeters with Offset After Rotation

      LeftTarget:=16000                    ' Set Maximum Target Distance for Each Motor
      RightTarget:=16000
      FeedTarget:=16000
                                                   
'--------------------- Start Objects & Methods ------------------------------------------------------------------

      SoundPal.start(14)                                                                     ' Start SoundPal Object for Sound Effects
'      SoundPal.sendstr(string("=", SoundPal#play, SoundPal#cucaracha, SoundPal#EOF, "!"))       ' Play Charge While Objects Starting Up
      Drive.FlashBrakes(LeftPin,RightPin,5,3)                                               ' Flash Brakes to Indicate Power to All Drive Motor Coil
      Serial.start(31,30,0,115_200)                                                          ' Start Serial for Debugging 
                                                                                             ' Start StepperBotDriver Objects Methods for Robot Control
      Drive.StartPing(PingPin,@Range)                                                        ' Start Ping for Ranging
      Drive.StartIrLineSensor(LeftIRPin,RightIRPin,LeftLED,RightLED,@ActualIrSensor)         ' Start IR Line Sensor 
      Drive.StartMotor(@LeftSteps,@LeftPin,@LeftSpeed,@LeftDist,@LeftTarget,@LeftOdometer,@LeftTrip,@LeftBrake,@LeftLock)' Start Motors & Controller
 
                                                                                                        
'--------------------------------------------------------------------------------------------------------------
'----------------------------  Line Following Command Loop ----------------------------------------------------
'--------------------------------------------------------------------------------------------------------------  

Drive.Autobrake(false)                            ' Verify Both Brakes are Off

repeat  5
  Drive.move(LeftTwist,-500,10*twistdegticks,100)
  PauseTillDone
  Drive.move(RightTwist,-500,20*twistdegticks,100)
  PauseTillDone
  Drive.move(LeftTwist,-500,10*twistdegticks,100)
  PauseTillDone


Repeat i from 0 to 120 step 1
   drive.move(straight,120-i,500,100)
   Waitcnt(clkfreq/10+cnt)

Drive.move(rightturn,500,180*turndegticks,100)
PauseTillDone

Drive.move(RightTwist,500,180*twistdegticks,100)
PauseTillDone

Drive.move(rightturn,500,180*turndegticks,100)
PauseTillDone
  
Drive.move(straight,-25,250,100)
PauseTillDone

Drive.move(LeftTurn,500,180*turndegticks,100)
PauseTillDone

Drive.move(LeftTwist,500,360*twistdegticks,100)
PauseTillDone

Drive.move(Leftturn,500,180*turndegticks,100)
PauseTillDone

{
repeat i from 0 to 100 step 10

    Drive.move(rightcurve,200,500,100-i)
    waitcnt(clkfreq/4+cnt)

repeat j from 0 to 100 step 10

    Drive.move(Leftcurve,200,500,100-j)
    waitcnt(clkfreq/4+cnt)

Repeat i from 0 to 500 step 10
   drive.move(straight,500-i,500,100)
   Waitcnt(clkfreq/10+cnt)
}

{

Drive.move(lefttwist,500,360*twistdegticks,100)
PauseTillDone
    
drive.move(straight,500, 10*centiticks,100)
pausetilldone

drive.move(righttwist,500, 270*twistdegticks,100)
pausetilldone


drive.move(straight,500, 46*centiticks,100)
pausetilldone

drive.move(righttwist,500, 290*twistdegticks,100)
pausetilldone

}
repeat  3
  Drive.move(LeftTwist,-500,10*twistdegticks,100)
  PauseTillDone
  Drive.move(RightTwist,-500,20*twistdegticks,100)
  PauseTillDone
  Drive.move(LeftTwist,-500,10*twistdegticks,100)
  PauseTillDone


'SoundPal.sendstr(string("=", SoundPal#play, SoundPal#taps, SoundPal#EOF, "!"))       ' Play Charge While Objects Starting Up
repeat

Pub PauseTillDone  '' Wait for Motors to Complete Actions

     repeat                                      ' Loop
         waitcnt(clkfreq/1000+cnt)
     while LeftLock or RightLock or FeedLock     ' While Any of the Motors in Motion



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
 