{{      4x4 Keypad driver
        Version - Check Version in the CON block
        2018.04.03

        This is for a 4x4 KeyPad 

        Created by John Harris - TheGrue
        Email: gruesnest@gmail.com
        Web Address: www.gruebotics.com

                            Column 1    2    3    4                
                                ┌────────────────────┐
                         Row 1  │                    │
                        ┌───────┼  1    2    3    A  │     
                        │       │                10  │
                        │    2  │                    │
                        │┌──────┼  4    5    6    B  │
                        ││      │                11  │
                        ││   3  │                    │
                        ││┌─────┼  7    8    9    C  │     
                        │││     │                12  │
                        │││  4  │                    │
                        │││┌────┼  *    O    #    D  │
                        ││││    │  14       15   13  │
                        ││││    │                    │
                        ││││    └──┼────┼────┼────┼──┘
                        ││││       │    └───┐│┌───┘
                        ││││       └───────┐│││
                        │││└──────────────┐││││
                        ││└──────────────┐│││││
                        │└──────────────┐││││││
                        └──────────────┐││││││┣──┐
                                       ││││││┣┼──┫ 10KΩ Pull-Down Resistors
                                       │││││┣┼┼──┫ on all Columns to Ground
                                       ││││┣┼┼┼──┫ 
                                       ││││││││    
                                       87654321
                                       └┬─┘└─┬┘
                                      Rows  Columns

        This will bring each Row HIGH one at a time and scan each Column individually.
        If a Column shows a HIGN then the KEY variable is assigned the value of that
        key. The non numerical buttons return 10-15 as shown in the above diagram.

        Usage: YourVariable := KP.ReadKey(Pin1, Pin8)         ' Scan the Keypad and wait for the user to press a key



        NOTE: This Method WILL keep scanning UNTIL a key is pressed. It forces the user
        to interact before a program continues. I designed it for a machine to wait for
        a user to set a value in a setup method or to have a user answer a question.
        
}}                                         
                                          
CON

  Version = 7
  
VAR

  long Key
  byte C1, C2, C3, C4, R1, R2, R3, R4
  

PUB ReadKey(Pin1, Pin8)

  dira[Pin1..Pin8] := %00001111                         ' Set inputs on pins

  C4 := Pin1                                            ' Calculate and set all pin variables
  C3 := Pin1 + 1
  C2 := Pin1 + 2
  C1 := Pin1 + 3
  R1 := Pin8
  R2 := Pin8 - 1
  R3 := Pin8 - 2
  R4 := Pin8 - 3

  key := -1                                             ' Assign KEY variable a negative number

  repeat while key < 0                                  ' Check if KEY variable is less than 0
    outa[R1]~~                                          ' Make Row 1 high
     
      if ina[C1] == 1                                   ' Check column 1 button is pushed
        Key := 1                                        ' Assign the value of the key pressed to KEY variable
        repeat until ina[C1] == 0                       ' Wait for key to become low
        outa[R1]~                                       ' Make Row 1 low
        Return Key                                      ' RETURN the value of the variable KEY to the method that called for it
         
      if ina[C2] == 1                                   ' Check column 2 button is pushed      
        Key := 2                                        ' Assign the value of the key pressed to KEY variable
        repeat until ina[C2] == 0                       ' Wait for key to become low
        outa[R1]~                                       ' Make Row 1 low
        Return Key                                      ' RETURN the value of the variable KEY to the method that called for it
         
      if ina[C3] == 1                                   ' Check column 3 button is pushed
        Key := 3                                        ' Assign the value of the key pressed to KEY variable
        repeat until ina[C3] == 0                       ' Wait for key to become low
        outa[R1]~                                       ' Make Row 1 low
        Return Key                                      ' RETURN the value of the variable KEY to the method that called for it
         
      if ina[C4] == 1                                   ' Check column 4 button is pushed
        Key := 10                                       ' Assign the value of the key pressed to KEY variable
        repeat until ina[C4] == 0                       ' Wait for key to become low
        outa[R1]~                                       ' Make Row 1 low
        Return Key                                      ' RETURN the value of the variable KEY to the method that called for it
         
    outa[R1]~                                           ' Make Row 1 low
    outa[R2]~~                                          ' Make Row 2 high
     
      if ina[C1] == 1                                   ' Check column 1 button is pushed
        Key := 4                                        ' Assign the value of the key pressed to KEY variable
        repeat until ina[C1] == 0                       ' Wait for key to become low
        outa[R2]~                                       ' Make Row 2 low
        Return Key                                      ' RETURN the value of the variable KEY to the method that called for it
         
      if ina[C2] == 1                                   ' Check column 2 button is pushed      
        Key := 5                                        ' Assign the value of the key pressed to KEY variable
        repeat until ina[C2] == 0                       ' Wait for key to become low
        outa[R2]~                                       ' Make Row 2 low
        Return Key                                      ' RETURN the value of the variable KEY to the method that called for it
         
      if ina[C3] == 1                                   ' Check column 3 button is pushed
        Key := 6                                        ' Assign the value of the key pressed to KEY variable
        repeat until ina[C3] == 0                       ' Wait for key to become low
        outa[R2]~                                       ' Make Row 2 low
        Return Key                                      ' RETURN the value of the variable KEY to the method that called for it
         
      if ina[C4] == 1                                   ' Check column 4 button is pushed
        Key := 11                                       ' Assign the value of the key pressed to KEY variable
        repeat until ina[C4] == 0                       ' Wait for key to become low
        outa[R2]~                                       ' Make Row 2 low
        Return Key                                      ' RETURN the value of the variable KEY to the method that called for it
         
    outa[R2]~                                           ' Make Row 2 low
    outa[R3]~~                                          ' Make Row 3 high
     
      if ina[C1] == 1                                   ' Check column 1 button is pushed
        Key := 7                                        ' Assign the value of the key pressed to KEY variable
        repeat until ina[C1] == 0                       ' Wait for key to become low
        outa[R3]~                                       ' Make Row 3 low
        Return Key                                      ' RETURN the value of the variable KEY to the method that called for it
         
      if ina[C2] == 1                                   ' Check column 2 button is pushed      
        Key := 8                                        ' Assign the value of the key pressed to KEY variable
        repeat until ina[C2] == 0                       ' Wait for key to become low
        outa[R3]~                                       ' Make Row 3 low
        Return Key                                      ' RETURN the value of the variable KEY to the method that called for it
         
      if ina[C3] == 1                                   ' Check column 3 button is pushed
        Key := 9                                        ' Assign the value of the key pressed to KEY variable
        repeat until ina[C3] == 0                       ' Wait for key to become low
        outa[R3]~                                       ' Make Row 3 low
        Return Key                                      ' RETURN the value of the variable KEY to the method that called for it
         
      if ina[C4] == 1                                   ' Check column 4 button is pushed
        Key := 12                                       ' Assign the value of the key pressed to KEY variable
        repeat until ina[C4] == 0                       ' Wait for key to become low
        outa[R3]~                                       ' Make Row 3 low
        Return Key                                      ' RETURN the value of the variable KEY to the method that called for it
         
    outa[R3]~                                           ' Make Row 3 low
    outa[R4]~~                                          ' Make Row 4 high
     
      if ina[C1] == 1                                   ' Check column 1 button is pushed
        Key := 14                                       ' Assign the value of the key pressed to KEY variable
        repeat until ina[C1] == 0                       ' Wait for key to become low
        outa[R4]~                                       ' Make Row 4 low
        Return Key                                      ' RETURN the value of the variable KEY to the method that called for it
         
      if ina[C2] == 1                                   ' Check column 2 button is pushed      
        Key := 0                                        ' Assign the value of the key pressed to KEY variable
        repeat until ina[C2] == 0                       ' Wait for key to become low
        outa[R4]~                                       ' Make Row 4 low
        Return Key                                      ' RETURN the value of the variable KEY to the method that called for it
         
      if ina[C3] == 1                                   ' Check column 3 button is pushed
        Key := 15                                       ' Assign the value of the key pressed to KEY variable
        repeat until ina[C3] == 0                       ' Wait for key to become low
        outa[R4]~                                       ' Make Row 4 low
        Return Key                                      ' RETURN the value of the variable KEY to the method that called for it
         
      if ina[C4] == 1                                   ' Check column 4 button is pushed
        Key := 13                                       ' Assign the value of the key pressed to KEY variable
        repeat until ina[C4] == 0                       ' Wait for key to become low
        outa[R4]~                                       ' Make Row 4 low
        Return Key                                      ' RETURN the value of the variable KEY to the method that called for it
         
    outa[R4]~                                           ' Make Row 4 low
     

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

    