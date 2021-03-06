{{
┌───────────────────────────────────────┐
│ Wintek WD-C2401P Parallel LCD Driver  │
├───────────────────────────────────────┴───────────┐
│  Width      : 24 Characters                       │
│  Height     :  1 Line                             │
│  Interface  :  8 Bit                              │
│  Controller :  HD66717-based                      │
├───────────────────────────────────────────────────┤
│  By      : davel@dsp-services.com                 │
│  Date    : 2010-10-22                             │
│  Version : 1.0                                    │
│  original: http://obex.parallax.com/objects/106/  │
│          : Simon Ampleman                         │
│          : sa@infodev.ca                          │
└───────────────────────────────────────────────────┘

Note: Simon did an awesome job documenting his particular
module and controller.  If there are errors in these docs,
it's likely something that I introduced trying to understand
the pretty underwhelming "data sheet" for the WD-C2401P.
This was definitely a learning experience for me, and I hope
that it's useful to somebody.

The first section of the PUBlic functions are to give you
direct low level access to the controller.  Then the rest
of the PUBlics are for easier general use.


Schematics

P8X32A (showing pins to LCD module to left and right)
        ┌────┬────┐ 
        ┤0      31├            
        ┤1      30├            
        ┤2      29├                                          
        ┤3      28├              
        ┤4      27├            
        ┤5      26├            
        ┤6      25├            
        ┤7      24├            
        ┤VSS   VDD├              
        ┤BOEn   XO├                           
        ┤RESn   XI├              
        ┤VDD   VSS├             
 14 DB7 ┤8      23├ 
 13 DB6 ┤9      22├ 
 12 DB5 ┤10     21├ 
 11 DB4 ┤11     20├
 10 DB3 ┤12     19├ 
  9 DB2 ┤13     18├ E   6
  8 DB1 ┤14     17├ RW  5
  7 DB0 ┤15     16├ RS  4
        └─────────┘ 
     
LCD module Wintek "LCD-111" WD-C2401P-1GNN
pin symbol  level  function
  1  VSS      -    GND (0v)
  2  VDD      -    VCC (+5v ±5%)
  3  RST      -    Controller Reset
  4   RS     H/L   Register Select (0 instruction / 1 data)
  5   RW     H/L   Read / Write Select (0 write / 1 read)
  6    E    H,H→L  Enable Signal
  7  DB0     H/L   Data Bit ┬ 0
  8  DB1     H/L            ├ 1
  9  DB2     H/L            ├ 2
 10  DB3     H/L            ├ 3
 11  DB4     H/L            ├ 4
 12  DB5     H/L            ├ 5
 13  DB6     H/L            ├ 6
 14  DB7     H/L            └ 7


INSTRUCTION SET
   ┌──────────────────────┬───┬───┬─────┬───┬───┬───┬───┬───┬───┬───┬───┬─────┬─────────────────────────────────────────────────────────────────────┐
   │  INSTRUCTION         │ RS│R/W│     │DB7│DB6│DB5│DB4│DB3│DB2│DB1│DB0│     │ Description                                                         │
   ├──────────────────────┼───┼───┼─────┼───┼───┼───┼───┼───┼───┼───┼───┼─────┼─────────────────────────────────────────────────────────────────────┤
   │ PW Power Control     │ 0 │ 0 │     │ 0 │ 0 │ 0 │ 1 │ 1 │AMP│SLP│STB│     │ Turns on voltage follower and booster (AMP), and sets sleep         │
   │                      │   │   │     │   │   │   │   │   │   │   │   │     │ mode (SLP) and standby mode (STB)                                   │
   │                      │   │   │     │   │   │   │   │   │   │   │   │     │                                                                     │
   │ DO Display On/Off    │ 0 │ 0 │     │ 0 │ 0 │ 0 │ 1 │ 0 │ 1 │ 0 │ 0 │     │ Sets character display on                                           │
   │                      │   │   │     │   │   │   │   │   │   │   │   │     │                                                                     │
   │ DC Display control   │ 0 │ 0 │     │ 0 │ 0 │ 1 │ 0 │ 1 │ 0 │ 0 │ 0 │     │ Sets number of display lines to 2                                   │
   │                      │   │   │     │   │   │   │   │   │   │   │   │     │                                                                     │
   │ CN Contrast control  │ 0 │ 0 │     │ 0 │ 1 │ 0 │ 0 │CT3│CT2│CT1│CT0│     │ Sets the display contrast adjust value (CT)                         │
   │                      │   │   │     │   │   │   │   │   │   │   │   │     │                                                                     │
   │ CR Cursor control    │ 0 │ 0 │     │ 0 │ 0 │ 0 │ 0 │ 1 │ BW│ C │ BL│     │ Sets black-white inverting cursor (BW), 8th raster row cursor (C),  │
   │                      │   │   │     │   │   │   │   │   │   │   │   │     │ blink (BL)                                                          │
   │                      │   │   │     │   │   │   │   │   │   │   │   │     │                                                                     │
   │ CL CLEAR DISPLAY     │ 0 │ 0 │     │ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ 1 │     │ Clears display and returns cursor to the home position (address 0). │
   │                      │   │   │     │   │   │   │   │   │   │   │   │     │                                                                     │
   │ CH CURSOR HOME       │ 0 │ 0 │     │ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ 1 │ 0 │     │ Returns cursor to home position (address 0).                        │
   │                      │   │   │     │   │   │   │   │   │   │   │   │     │                                                                     │
   │ SR READ BUSY FLAG    │ 0 │ 1 │     │ BF│ A │ A │ A │ A │ A │ A │ A │     │ Reads Busy-flag (BF) indicating internal operation is being         │
   │ and ADDRESS COUNTER  │   │   │     │   │   │   │   │   │   │   │   │     │ performed and reads CGRAM or DDRAM address counter contents.        │
   │                      │   │   │     │   │   │   │   │   │   │   │   │     │                                                                     │
   │ DA SET DDRAM ADDRESS │ 0 │ 0 │     │ 1 │ 1 │ 0 │ 0 │ 0 │ 0 │ A │ A │     │ Sets the DDRAM address (higher bits).                               │                                                             
   │ (upper bits)         │   │   │     │   │   │   │   │   │   │   │   │     │ DDRAM data is sent and received after this setting.                 │
   │                      │   │   │     │   │   │   │   │   │   │   │   │     │                                                                     │
   │ DA SET DDRAM ADDRESS │ 0 │ 0 │     │ 1 │ 1 │ 1 │ A │ A │ A │ A │ A │     │ Sets the DDRAM address (lower bits).                                │                                                             
   │ (lower bits)         │   │   │     │   │   │   │   │   │   │   │   │     │ DDRAM data is sent and received after this setting.                 │
   │                      │   │   │     │   │   │   │   │   │   │   │   │     │                                                                     │
   │ CA SET CGRAM ADDRESS │ 0 │ 0 │     │ 1 │ 0 │ 1 │ A │ A │ A │ A │ A │     │ Sets the CGRAM address.                                             │
   │                      │   │   │     │   │   │   │   │   │   │   │   │     │ CGRAM data is sent and received after this setting.                 │
   │                      │   │   │     │   │   │   │   │   │   │   │   │     │                                                                     │
   │ WD WRITE TO RAM      │ 1 │ 0 │     │ B │ B │ B │ B │ B │ B │ B │ B │     │ Writes data to RAM (based on address set with DA or CA)             │
   │                      │   │   │     │   │   │   │   │   │   │   │   │     │                                                                     │
   │ RD READ FROM RAM     │ 1 │ 1 │     │ B │ B │ B │ B │ B │ B │ B │ B │     │ Reads data from RAM (based on address set with DA or CA)            │
   │                      │   │   │     │   │   │   │   │   │   │   │   │     │                                                                     │
   └──────────────────────┴───┴───┴─────┴───┴───┴───┴───┴───┴───┴───┴───┴─────┴─────────────────────────────────────────────────────────────────────┘
   ┌──────────┬──────────────────────────────────────────────────────────────────────┐
   │ BIT NAME │                          SETTING STATUS                              │                                                              
   ├──────────┼─────────────────────────────────┬────────────────────────────────────┤
   │  AMP     │                                 │ 1 = Voltage follower and boost on  │
   │  SLP     │                                 │ 1 = Sleep mode                     │
   │  STB     │                                 │ 1 = Standby mode                   │
   │  BW      │ 0 = Invert Cursor off           │ 1 = Invert Cursor on               │
   │  C       │ 0 = Cursor off                  │ 1 = Cursor on                      │
   │  BL      │ 0 = Cursor blink off            │ 1 = Cursor blink on                │
   │  BF      │ 0 = Can accept instruction      │ 1 = Internal operation in progress │
   ├──────────┼─────────────────────────────────┴────────────────────────────────────┤
   │  CT      │ Contrast value bits, from 0000 (lightest) to 1111 (darkest)          │
   │  A       │ DDRAM / CGRAM address bits                                           │
   │  B       │ Data bits                                                            │
   └──────────┴──────────────────────────────────────────────────────────────────────┘
   Remarks :
        DDRAM = Display Data Ram - Corresponds to cursor position                  
        CGRAM = Character Generator Ram        
        On my display I couldn't even see anything below 1100 contrast setting

DDRAM ADDRESS USAGE FOR A 1-LINE DISPLAY
    01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24    <- CHARACTER POSITION
   ┌──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┐
   │00│01│02│03│04│05│06│07│08│09│0A│0B│10│11│12│13│14│15│16│17│18│19│1A│1B│   <- DDRAM ADDRESS
   └──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘
    Note in particular how we address that in the 'MOVE' command, so you can
    properly use the DAl() command
    
Notes on initializing:
http://www.electro-tech-online.com/microcontrollers/89605-problem-interfacing-lcd-module.html
http://www.serialwombat.com/parts/lcd111.htm
0x1C    (11100) - Turn on the lcd driver power
0x14    (10100) - Turn on the character display
0x28   (101000) - Set two display lines (The hd66717 considers 12 characters to be a line. Our 24 character display is actually two 12-character lines right next to each other).
0x4F  (1001111) - Set to darkest contrast
0xE0 (11100000) - Set the data address to the first character .MOVE(1)

}}      
        
        
        
CON

  ' Pin assignment
  RS = 16                   
  RW = 17                    
  E  = 18

  DB0 = 15
  DB1 = 14
  DB2 = 13
  DB3 = 12
  DB4 = 11
  DB5 = 10
  DB6 = 9 
  DB7 = 8

OBJ

  DELAY : "Timing"  ' from parallel lcd object by Dan Miller
                    ' http://obex.parallax.com/objects/113/

' The normal start routine, set the basics   
PUB START  
  ' Set everything to output
  DIRA[DB7..DB0] := %11111111                 
  DIRA[RS] := 1
  DIRA[RW] := 1
  DIRA[E] := 1
  ' Set everything low
  OUTA[DB7..DB0] := %00000000                              
  OUTA[RS] := 0
  OUTA[RW] := 0
  OUTA[E]  := 0
  

{{
Begin low level functions
}}

' Power Control
' PW (Amp on = 0|1, Sleep mode = 0|1, Standby mode = 0|1)
PUB PW (AMP,SLP,STB) | BITS
    ' PW 00011000 base (24)
    BITS := 24 + (AMP * 4) + (SLP * 2) + STB
    INST (BITS)

' Display on / off
' DO
PUB DO
    ' DO 00010100
    INST (%00010100)

' Display control
' DC 
PUB DC
    ' DC 00101000
    INST (%00101000)

' Contrast control
' CN (Contrast level = 0-15)
PUB CN (CONT) | BITS
    ' CN 01000000 base (64)
    BITS := 64 + CONT
    INST (BITS)

' Cursor Control
' note - you'll want to mess with different variations as it doesn't do what i'd predict
' CR (Invert = 0|1, 8th Raster Row Line = 0|1, Blink = 0|1)
PUB CR (BW,C,BL) | BITS
    ' CR 00001000 base (8)
    BITS := 8 + (BW * 4) + (C * 2) + BL
    INST (BITS)
 
' Clear Display - also homes cursor
' CL    
PUB CL
    INST (%00000001)                                                                               

' Cursor Home - really no need as you could just DAl(0)
' CH
PUB CH
    INST (%00000010)                                                                               

' Read busy flag and address counter
' note - we don't return the AC in this revision
' SR
PUB SR | ISBUSY,AC
    DIRA[DB7..DB0] := %00000000
    OUTA[RW] := 1                              
    OUTA[RS] := 0                              
    OUTA[E]  := 1
    ISBUSY := INA[DB7]
    AC := INA[DB6..DB0]
    OUTA[E]  := 0
    DIRA[DB7..DB0] := %11111111

' Set DDRAM address upper bits - unused here
' DAu (2 bits)
PUB DAu (BITS) | ADR
    ' DAu 11000000 base (192)
    ADR := 192 + BITS
    INST (ADR)

' Set DDRAM address lower bits
' DAl (5 bits)
PUB DAl (BITS) | ADR
    ' DAl 11100000 base (224)
    ADR := 224 + BITS
    INST (ADR)

' Set CGRAM address and write 8x8 bits
' CA (bit address = 0, 8, 16, 24, row data = 8 bits * 8)
PUB CA (CGADR,R1,R2,R3,R4,R5,R6,R7,R8) | ADR
    ' CA 10100000 base (160)
    ADR := 160 + CGADR
    INST (ADR)
    DELAY.pause1ms (10) ' if you don't pause here, you lose the first row
    OUTA[RS] := 1
    CAdata (R1)
    CAdata (R2)
    CAdata (R3)
    CAdata (R4)
    CAdata (R5)
    CAdata (R6)
    CAdata (R7)
    CAdata (R8)
    OUTA[RS] := 0

' subfunction for CA - send one row of bits for a custom char
' CAdata (8 bits)
PRI CAdata(BITS)
    OUTA[E]  := 1
    OUTA[DB7..DB0] := BITS
    OUTA[E]  := 0
    DELAY.pause1ms (10)
       
' Write to RAM (based on address set with DA)
' note - this is the "same" as the DATA () function
' WD (8 bits)
PUB WD (BITS)
    BUSY
     
    OUTA[RW] := 0                              
    OUTA[RS] := 1                              
    OUTA[E]  := 1
    OUTA[DB7..DB0] := BITS
    OUTA[E]  := 0  
     
' Read from RAM (based on address set with DA)
' RD
PUB RD | BITS
    BUSY
    DIRA[DB7..DB0] := %00000000
    OUTA[RW] := 1                              
    OUTA[RS] := 1                              
    OUTA[E]  := 1
    BITS := INA[DB7..DB0]
    OUTA[E]  := 0  
    DIRA[DB7..DB0] := %11111111

' Scroll control - useless, but here in case you poke the wrong bits somehow
' note - just resets to no scrolling/shifting
' SC
PUB SC
    ' base 1100000 (96)
    INST (96)


{{
Now the easier to use higher level stuff
}}

' Initialize to some sane values if you don't want to do it manually
' INIT
PUB INIT
    DELAY.pause1ms(15)
    PW (1,0,0)
    DO                                           
    DC                                            
    CN (15)                                                     
    CR (0,0,0)                                                     
    CL

' Move the cursor to a cell position on the display
' MOVE (position = 1-24)     
PUB MOVE (X) | ADR
    if (X > 12)
        ADR := 16       ' "2nd line" shift by 0x10 
        X := X - 12     ' and set X position accordingly
    else
        ADR := 0
    ADR += (X-1) + 224  ' command base of 11100000
    INST (ADR)

' Display strings
' STR (string)
PUB STR (STRINGPTR)
  REPEAT STRSIZE(STRINGPTR)
    DATA(BYTE[STRINGPTR++])

' Display integer numbers
' INT (integer)                              
PUB INT (VALUE) | TEMP
  IF (VALUE < 0)
    -VALUE
    DATA("-")

  TEMP := 1_000_000_000

  REPEAT 10
    IF (VALUE => TEMP)
      DATA(VALUE / TEMP + "0")
      VALUE //= TEMP
      RESULT~~
    ELSEIF (RESULT OR TEMP == 1)
      DATA("0")
    TEMP /= 10

' Display hexadecimal numbers, with digit places to display
' HEX (number, digits)
PUB HEX (VALUE, DIGITS)

  VALUE <<= (8 - DIGITS) << 2
  REPEAT DIGITS
    DATA(LOOKUPZ((VALUE <-= 4) & $F : "0".."9", "A".."F"))

' Display binary numbers, with digit places to display
' BIN (number, digits)
PUB BIN (VALUE, DIGITS)

  VALUE <<= 32 - DIGITS
  REPEAT DIGITS
    DATA((VALUE <-= 1) & 1 + "0")


{{
Functions that are used repeatedly
}}

' Send an instruction (rw and rs both low)
' INST (8 bits)
PRI INST (BITS)            
  BUSY
  OUTA[RW] := 0                              
  OUTA[RS] := 0                              
  OUTA[E]  := 1
  OUTA[DB7..DB0] := BITS
  OUTA[E]  := 0                              

' Send data (rw low, rs high)
' DATA (8 bits)
PRI DATA (BITS)
  BUSY
  OUTA[RW] := 0                              
  OUTA[RS] := 1                              
  OUTA[E]  := 1
  OUTA[DB7..DB0] := BITS
  OUTA[E]  := 0  

' Busy - ask the display if it's busy
' note this only reads the busy flag and ignores the address counter contents
' BUSY
PRI BUSY | IS_BUSY
    DIRA[DB7..DB0] := %00000000
    OUTA[RW] := 1                              
    OUTA[RS] := 0                              
    REPEAT
      OUTA[E]  := 1
      IS_BUSY := INA[DB7]     
      OUTA[E]  := 0
    WHILE (IS_BUSY == 1)
    DIRA[DB7..DB0] := %11111111



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