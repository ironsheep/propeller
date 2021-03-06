{{
****************************
*     OLED_Driver Test     *
*  Written by L. Wendell   *
*     3DogPottery.Com      *
****************************

      I2C IIC Serial 128X64 128*64 OLED Connections 
      -------------------------------------------------------------------
      Gnd   to     Gnd
      VCC   to     3.3 Volts
      SCL   to     Propeller P2   <------ Change these to the Propeller     
      SDA   to     Propeller P3           pins you are using

}}
CON
  _clkmode = xtal1 + pll16x   
  _xinfreq = 5_000_000

   R = 1    'Right Horizontal Scrolling
   L = 2    'Left Horizontal Scrolling

   CR  = 13 'Carriage Return
   CLS = 16 'Clear Screen
   
OBJ
   OLED:     "SSD1306_Driver_Plus"      'Driver for the OLED Display
   FS:       "FloatString-v1_2"         'Float to String library
   
VAR
   long A_Float
                                                
PUB Main  

'********* Configuration ****************************************************************

   OLED.DrivInit(2, 3)    'Initiates Driver with pins used for OLED
   OLED.WakeUp            'Wake UP OLED
   OLED.Pause(100)    
   OLED.Init              'Initalize OLED     
   OLED.Pause(100)
   OLED.Clear             'Clear the Screen
                       
'********* Main  ************************************************************************ 

        A_Float := 12.5

        OLED.Init
        OLED.Tx(CLS)
        OLED.Stop_Scroll
        OLED.Str(String("SSD1306_Driveer_Plus!"))
        OLED.Tx(CR)
        OLED.Tx(CR)
        OLED.Str(String("HERE'S A FLOAT: ")) 
        OLED.Str(FS.floattostring(A_Float))
        OLED.Tx(CR)
        OLED.TX(CR)
        OLED.Str(String("HERE'S A DECIMAL: "))
        OLED.Dec(123) 
        OLED.Tx(CR)
        OLED.TX(CR)
        OLED.Str(String("A BINARY: "))
        OLED.bin(56, 8)
        OLED.Pause(2000)
        OLED.Scroll(L, 0, 0, 5)  
                     
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