{{

    Test 4x4 Matrix keypad

}}

CON

  _clkmode = xtal1 + pll16x                             ' use crystal x 16
  _xinfreq = 5_000_000                                  ' 5 MHz cyrstal (sys clock = 80 MHz)

'' Pins used 
  p_LCD         = 0             ' Parallax Serial LCD
  p_KP1         = 16            ' Pin 1 on the Keypad
  p_KP8         = 23            ' Pin 8 on the Keypad

'' General constants
  LCD_BAUD      = 19_200        ' LCD Baud rate
  LCD_LINES     = 4             ' Number of lines on the LCD (2 or 4)
  
  Version       = 7

OBJ

  LCD:          "Debug_Lcd"                             'LCD Display Object
  KP:           "4x4_Keypad"                            '4x4 Keypad Object

VAR

  long Keypad

PUB Init

  dira[p_LCD]~~

  LCD.init(p_LCD, LCD_BAUD, LCD_LINES)
  waitcnt(clkfreq +cnt)

  Main
  
PUB Main

 repeat
    lcd.cursor(2)                                       ' cursor off Blinking
    lcd.backLight(true)                                 ' backlight on (if available)
    LCD.display(1)                                      ' make sure the lcd display is on
    lcd.cls                                             ' clear the lcd
    lcd.str(string("--4x4 Keypad Test--",13))           ' display a string of text and a carrage return (13)
    lcd.str(string("Version: "))                        ' display a string of text
    LCD.dec(Version)                                    ' and display a value on the same line. No carrage return
    lcd.gotoxy(0,2)                                     ' goto column 0 line 2
    lcd.str(string("Input: "))                          ' display a string of text and a space

  repeat
    Keypad := KP.readkey(p_KP1, p_KP8)                  ' read a key from the keypad object
    lcd.clrln(2)                                        ' clear line 2
    lcd.gotoxy(0,2)                                     ' goto column 0 line 2
    lcd.str(string("Input: "))                          ' display a string of text and a space
    LCD.dec(Keypad)                                     ' and display a value on the same line. No carrage return

    waitcnt(clkfreq +cnt)                               ' pause 1 seconds


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