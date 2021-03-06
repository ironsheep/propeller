{{
┌─────────────────────────────┬───────────────────┬──────────────────────┐
│ FPU64_MATRIX_Demo.spin v1.1 │ Author: I.Kövesdi │ Release: 30 Nov 2011 │
├─────────────────────────────┴───────────────────┴──────────────────────┤
│                    Copyright (c) 2011 CompElit Inc.                    │               
│                   See end of file for terms of use.                    │               
├────────────────────────────────────────────────────────────────────────┤
│  This terminal application demonstrates many procedures and the general│
│ usage of the "FPU64_MATRIX_Driver.spin" object. Starting with simple   │
│ matrix algebra, examples of eigen-decomposition and singular value     │
│ decomposition of random matrices and inversion of random square        │
│ matrices are displayed.                                                │
│                                                                        │ 
├────────────────────────────────────────────────────────────────────────┤
│ Background and Detail:                                                 │
│  The uM-FPU64 floating point coprocessor supports 64-bit IEEE 754      │
│ compatible floating point and integer operations, as well as 32-bit    │
│ IEEE 754 compatible floating point and integer operations.             │
│  Advanced instructions are provided for fast data transfer, matrix     │
│ operations, FFT calculations, serial input/output, NMEA sentence       │
│ parsing, string handling, digital input/output, analog input, and      │
│ control of local devices.                                              │
│  Local device support includes: RAM, 1-Wire, I2C, SPI, UART, counter,  │
│ servo controller, and LCD devices. A built-in real-time clock and      │
│ foreground/background processing is also provided. The uM-FPU64 can    │
│ act as a complete subsystem controller for sensor networks, robotic    │
│ subsystems, IMUs, and other applications. The chip is available in     │
│ 28-PIN  DIP package, too.                                              │
│  If your embedded application has anything to do with the physical     │
│ reality, e.g. it deals with position, speed, acceleration, rotation,   │
│ attitude or even with airplane navigation or UAV flight control then   │
│ you should use vectors and matrices in your calculations. A matrix can │
│ be a "storage" for a bunch of related numbers, e.g. a covariance matrix│
│ or can define a transform on a vector or on other matrices. The use of │
│ matrix algebra shines in many areas of computation mathematics as in   │
│ coordinate transformations, rotational dynamics, control theory        │
│ including the Kalman filter. Matrix algebra can simplify complicated   │
│ problems and its rules are not artificial mathematical constructions,  │
│ but come from the nature of the problems and their solutions. A good   │
│ summary that might give you some inspiration is as follows:            │
│                                                                        │
│ "In the worlds of math, engineering and physics, it's the matrix that  │ 
│ separates the men from the boys, the  women from the girls."           │
│                                                (Jack W. Crenshaw).     │
│                                                                        │
│  A matrix is an array of numbers organized in rows and columns. We     │
│ usually give the row number first, then the column. So a [3-by-4]      │
│ matrix has twelve numbers arranged in three rows where each row has a  │
│ length of four                                                         │
│                                                                        │
│                          ┌               ┐                             │
│                          │ 1  2  3   4   │                             │
│                          │ 2  3  4   5   │                             │
│                          │ 3  4  5  6.28 │                             │
│                          └               ┘                             │
│                                                                        │
│  Since computer RAM is organized sequentially, as we access it with a  │
│ single number that we call address, we have to find a way to map the   │
│ two dimensions of the matrix onto the one-dimensional, sequential      │
│ memory. In Propeller SPIN that is rather easy since we can use arrays. │
│ For the previous matrix we can declare an array of LONGs, e.g.         │
│                                                                        │
│                           VAR   LONG mA[12]                            │
│                                                                        │
│ that is large enough to contain the "three times four" 32 bit IEEE 754 │
│ float numbers of the  matrix. In SPIN language the indexing starts with│
│ zero, so the first row, first column element of this matrix is placed  │
│ in mA[0]. The second row, fourth column element is placed in mA[7]. The│
│ general convention that I used with the "FPU_Matrix_Driver.spin" object│
│ is that the ith row, jth column element is accessed at the index       │
│                                                                        │ 
│                        "mA[i,j]" = mA[index]                           │
│                                                                        │
│ where                                                                  │
│                                                                        │
│                    index = (i-1)*(#col) + (j-1)                        │
│                                                                        │
│ and #col = 4 in this example. There are the 'Matrix_Put' and the       │
│ 'Matrix_Get' procedures in the driver to aid the access to the elements│
│ of a matrix. In this example the second row, fourth column element of  │
│ mA can be set to 5.0 using                                             │
│                                                                        │
│            OBJNAME.Matrix_Put(@mA, 5.0, 2, 4, #row, #col)              │
│                                                                  │
│         Address of mA in HUB───┘    │   │  │    │     │                │
│         Float value─────────────────┘   │  │    │     │                │
│         Target indexes──────────────────┻──┘    │     │                │
│         Matrix dimensions───────────────────────┻─────┘                │
│                                                                        │
│ Like in the previous example, the bunch of data in matrices is accessed│
│ by the driver using the starting HUB memory address of the array. For  │
│ example, after you declared mB and mC matrices to be the same [3-by-4] │
│ size as mA                                                             │
│                                                                        │
│                           VAR   LONG mB[12]                            │
│                           VAR   LONG mC[12]                            │
│                                                                        │
│ you can add mB to mC and store the result in mA with the following     │
│ single procedure call                                                  │
│                                                                        │
│  OBJNAME.Matrix_Add(@mA, @mB, @mC, 3, 4)     (meaning mA := mB + mC)   │
│                                                                        │
│ You can't multiply mB with mC, of course, but you can multiply mB with │
│ the transpose of mC. To obtain this transpose use                      │
│                                                                        │
│  OBJNAME.Matrix_Transpose(@mCT, @mC, 3, 4)   (meaning mCT := Tr. of mC)│
│                                                                        │
│ mCT is a [4-by-3] matrix, which can be now multiplied from the left    │
│ with mB as                                                             │
│                                                                        │
│  OBJNAME.Matrix_Multiply(@mD,@mB,@mCT,3,4,3) (meaning mD := mB * mCT)  │
│                                                                        │
│ where the result mD is a [3-by-3] matrix. This matrix algebra coding   │
│ convention can yield compact and easy to debug code. The following 8   │      
│ lines of SPIN code (OBJNAME here is FPUMAT) were taken from the        │
│ 'FPU_ExtendedKF.spin' application and calculate the Kalman gain matrix │
│ from five other matrices (A, P, C, CT, Sz) at a snap                   │
│                                                                        │
│        (    Formula: K = A * P * CT * Inv[C * P * CT + Sz]   )         │
│                                                                        │            
│      FPUMAT.Matrix_Transpose(@mCT, @mC, _R, _N)                        │
│      FPUMAT.Matrix_Multiply(@mAP, @mA, @mP, _N, _N, _N)                │
│      FPUMAT.Matrix_Multiply(@mAPCT, @mAP, @mCT, _N, _N, _R)            │
│      FPUMAT.Matrix_Multiply(@mCP, @mC, @mP, _R, _N, _N)                │
│      FPUMAT.Matrix_Multiply(@mCPCT, @mCP, @mCT, _R, _N, _R)            │
│      FPUMAT.Matrix_Add(@mCPCTSz, @mCPCT, @mSz, _R, _R)                 │
│      FPUMAT.Matrix_Invert(@mCPCTSzInv, @mCPCTSz, _R)                   │       
│      FPUMAT.Matrix_Multiply(@mK, @mAPCT, @mCPCTSzInv, _N, _R, _R)      │
│                                                                        │ 
├────────────────────────────────────────────────────────────────────────┤
│ Note:                                                                  │
│  You can use HyperTerminal or PST with this application. When using PST│
│ uncheck the [10] = Line Feed option in the Preferences/Function window.│
│  SPIN can generate for you the 32 bit FLOAT representation of a number │
│ during compile time. But, during run time, the responsibility is upon  │
│ to you to convert LONGs to FLOATs, or vice versa. You can use native   │
│ FPU code for that and there are some conversion utilities in the       │
│ driver, too. Check that and take care.                                 │
│  The MATRIX driver is a member of a family of drivers for the uM-FPU64 │
│ with 2-wire SPI connection. The family has been placed on OBEX:        │
│                                                                        │
│  FPU64_SPI     (Core driver of the FPU64 family)                       │
│  FPU64_ARITH   (Basic arithmetic operations)                           │
│ *FPU64_MATRIX  (Basic and advanced matrix operations)                  │
│  FPU64_FFT     (FFT with advanced options as, e.g. ZOOM FFT)     (soon)│
│                                                                        │
│  The procedures and functions of these drivers can be cherry picked and│
│ used together to build application specific uM-FPU64 drivers.          │
│  Other specialized drivers, as GPS, MEMS, IMU, MAGN, NAVIG, ADC, DSP,  │
│ ANN, STR are in preparation with similar cross-compatibility features  │
│ around the instruction set and with the user defined function ability  │
│ of the uM-FPU64.                                                       │
│                                                                        │ 
└────────────────────────────────────────────────────────────────────────┘
}}


CON

_CLKMODE = XTAL1 + PLL16X
_XINFREQ = 5_000_000

{
Schematics
                                                3V3 
                                               (REG)                                                           
                                                 │                   
P   │                                     10K    │
  A0├1────────────────────────────┳───────────┫
R   │                              │             │
  A1├2────────────────────┐       │             │
O   │                      │       │             │
  A2├3────┳──────┐                          │
P   │       │      17     16       1             │
            │    ┌──┴──────┴───────┴──┐          │                             
          1K    │ SIN   SCLK   /MCLR │          │                
            │    │                    │          │  LED   (On while busy)
            └──18┤SOUT            AVDD├28──┳─────╋────┐
                 │                 VDD├13──┼─────┫      │
                 │      uM-FPU64      │     0u1       │
                 │    (28 PIN DIP)    │    │     │      │
                 │                    │               │
            ┌──15┤/SS                 │   GND   GND     │ 
            ┣───9┤SEL                 │                 │
            ┣──14┤SERIN          /BUSY├10─────────────┘
            ┣──27┤AVSS                │        200 
            ┣───8┤VSS     VCAP        │         
            │    └──────────┬─────────┘
            │              20               
            │               │                             
            │                6u2 tantalum   
            │               │               
                                     6u2: 6.2 microF       
           GND             GND         0u1: 100 nF, close to the VDD pins

The SEL pin(9) of the FPU64 is tied to LOW to select SPI mode at Reset and
must remain LOW during operation. In this Demo the 2-wire SPI connection
was used, where the SOUT pin(18) and SIN pin(17) were connected through a
1K resistor and the A2 DIO pin(3) of the Propeller was connected to the SIN
pin(17) of the FPU. Since in this demo only one uM-FPU64 chip is used, the
SPI Slave Select pin(15) of the FPU64 is tied to ground.
}

'                            Interface lines
'            On Propeller                           On FPU64
'-----------------------------------  ------------------------------------
'Sym.   A#/IO       Function            Sym.  P#/IO        Function
'-------------------------------------------------------------------------
_FCLR = 0 'Out  FPU Master Clear   -->  MCLR  1  In   Master Clear
_FCLK = 1 'Out  FPU SPI Clock      -->  SCLK 16  In   SPI Clock Input     
_FDIO = 2 ' Bi  FPU SPI In/Out     -->  SIN  17  In   SPI Data In 
'       └───────────────via 1K     <--  SOUT 18 Out   SPI Data Out

'Debug timing parameter
'_DBGDEL    = 80_000_000
_DBGDEL       = 40_000_000             'For faster run
                                                 
_FLOAT_SEED  = 0.31415927              'Change this (from [0,1]) to run 
                                       'the demo with other pseudorandom
                                       'data
'_FLOAT_SEED  = 0.27182818   


OBJ

PST     : "Parallax Serial Terminal"   'From Parallax Inc.
                                       'v1.0
                                       
FPUMAT  : "FPU64_MATRIX_Driver"        'v1.1

  
VAR

LONG  okay, fpu64, char
LONG  ptr, strPtr
LONG  cog_ID
LONG  cntr, time, dTime

LONG  m1_2x2[2 * 2]

LONG  m1_3x3[3 * 3]
LONG  m2_3x3[3 * 3]

LONG  m1_3x4[3 * 4]

LONG  m1_4x4[4 * 4]
  
LONG  m1_3x7[3 * 7]  
LONG  m2_3x7[3 * 7]
LONG  m3_3x7[3 * 7]

LONG  m1_5x2[5 * 2]
LONG  m2_5x2[5 * 2]
LONG  m3_5x2[5 * 2]
LONG    eVc2[5 * 2]

  
LONG  m1_5x5[5 * 5]
LONG  m2_5x5[5 * 5]
LONG  m3_5x5[5 * 5]
LONG     eVc[5 * 5]

LONG  m1_5x6[5 * 6]

LONG  m1_5x7[5 * 7]
    
LONG  m1_5x11[5 * 11]  

LONG  m1_7x6[7 * 6]

LONG  m1_9x9[9 * 9]
LONG  m2_9x9[9 * 9]

LONG  m1_11x5[11 * 5]

LONG  m1_11x11[11 * 11]
LONG  m2_11x11[11 * 11] 

LONG  magnNED[3]
LONG  magnBody[3]
LONG  gravNED[3]
LONG  gravBody[3]
LONG  t1b[3]
LONG  t2b[3]
LONG  t3b[3]
LONG  t1n[3]
LONG  t2n[3]
LONG  t3n[3]
LONG  dcmBT[3 * 3]
LONG  dcmNT[3 * 3]
LONG  dcmTN[3 * 3]
LONG  dcmBN[3 * 3]            
LONG  heading
LONG  pitch
LONG  roll


DAT '------------------------Start of SPIN code---------------------------

  
PUB StartApplication | addrCOG_ID_                                                      
'-------------------------------------------------------------------------
'---------------------------┌──────────────────┐--------------------------
'---------------------------│ StartApplication │--------------------------
'---------------------------└──────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: -Starts driver objects
''             -Makes a MASTER CLEAR of the FPU and
''             -Calls demo procedures
'' Parameters: None
''     Result: None
''+Reads/Uses: /fpu64, Hardware constants from CON section
''    +Writes: fpu64,
''      Calls: FullDuplexSerialPlus---->PST.Start
''             FPU_MATRIX_Driver ------>FPU. Most of the procedures
''             FPU_MATRIX_Demo         
'-------------------------------------------------------------------------
'Start FullDuplexSerialPlus PST terminal
PST.Start(57600)
  
WAITCNT(4 * CLKFREQ + CNT)

PST.Char(PST#CS)
PST.Str(STRING("FPU64_MATRIX_Driver Demo started..."))                      
PST.Char(PST#NL)

WAITCNT(CLKFREQ + CNT)

addrCOG_ID_ := @cog_ID

fpu64 := FALSE

'FPU Master Clear...
PST.Str(STRING(10, "FPU64 Master Clear..."))
OUTA[_FCLR]~~ 
DIRA[_FCLR]~~
OUTA[_FCLR]~
WAITCNT(CLKFREQ + CNT)
OUTA[_FCLR]~~
DIRA[_FCLR]~

fpu64 := FPUMAT.StartDriver(_FDIO, _FCLK, addrCOG_ID_)

PST.Chars(PST#NL, 2)  

IF fpu64

  PST.Str(STRING("FPU64_MATRIX_Driver started in COG "))
  PST.Dec(cog_ID)
  PST.Chars(PST#NL, 2)
  WAITCNT(CLKFREQ + CNT)

  FPU64_MATRIX_Demo

  PST.Char(PST#NL)
  PST.Str(STRING("FPU64_MATRIX_Driver demo terminated normally."))

  FPUMAT.StopDriver
   
ELSE

  PST.Char(PST#NL)
  PST.Str(STRING("FPU64_MATRIX_Driver start failed!"))
  PST.Chars(PST#NL, 2)
  PST.Str(STRING("Device not detected! Check hardware and try again..."))

WAITCNT(CLKFREQ + CNT)
  
PST.Stop  
'--------------------------End of StartApplication------------------------    


PRI FPU64_MATRIX_Demo | i, r, c, rnd, fV, fV2, fV3
'-------------------------------------------------------------------------
'-------------------------┌───────────────────┐---------------------------
'-------------------------│ FPU64_MATRIX_Demo │---------------------------
'-------------------------└───────────────────┘---------------------------
'-------------------------------------------------------------------------
'     Action: Demonstrates some uM-FPU64 features by calling 
'             FPU64_SPI_Driver procedures
' Parameters: None
'     Result: None
'+Reads/Uses: /okay, char, Some constants from the FPU object
'    +Writes: okay, char
'      Calls: FullDuplexSerialPlus->PST.Str
'                                   PST.Dec
'                                   PST.Hex
'                                   PST.Bin   
'             FPU64_SPI_Driver ---->FPU. Most of the procedures
'       Note: Emphasize is on 64-bit features 
'-------------------------------------------------------------------------
PST.Char(PST#CS) 
PST.Str(STRING("----uM-FPU64 with 2-wire SPI connection v1.1----"))
PST.Char(PST#NL)

WAITCNT(CLKFREQ + CNT)

okay := FALSE
okay := FPUMAT.Reset
PST.Char(PST#NL)   
IF okay
  PST.Str(STRING("FPU Software Reset done..."))
  PST.Char(PST#NL)
ELSE
  PST.Str(STRING("FPU Software Reset failed..."))
  PST.Char(PST#NL)
  PST.Str(STRING("Please check hardware and restart..."))
  PST.Char(PST#NL)
  REPEAT

WAITCNT(CLKFREQ + CNT)

char := FPUMAT.ReadSyncChar
PST.Char(PST#NL)
PST.Str(STRING("Response to _SYNC: $"))
PST.Hex(char, 2)
IF (char == FPUMAT#_SYNC_CHAR)
  PST.Str(STRING("    (OK)"))
  PST.Char(PST#NL)  
ELSE
  PST.Str(STRING("   Not OK!"))   
  PST.Char(PST#NL)
  PST.Str(STRING("Please check hardware and restart..."))
  PST.Char(PST#NL)
  REPEAT

PST.Char(PST#NL)
PST.Str(STRING("   Version String: "))
FPUMAT.WriteCmd(FPUMAT#_VERSION)
FPUMAT.Wait
PST.Str(FPUMAT.ReadStr)

PST.Char(PST#NL)
PST.Str(STRING("     Version Code: $"))
FPUMAT.WriteCmd(FPUMAT#_LREAD0)
PST.Hex(FPUMAT.ReadReg, 8)
  
PST.Char(PST#NL)
PST.Str(STRING(" Clock Ticks / ms: "))
PST.Dec(FPUMAT.ReadInterVar(FPUMAT#_TICKS))
PST.Char(PST#NL) 

QueryReboot

'Initialise random number sequence
rnd := FPUMAT.Rnd_Float_UnifDist(_FLOAT_SEED)  

PST.Char(PST#CS)
PST.Str(STRING("Create Identity matrices...", PST#NL))
PST.Str(STRING(PST#NL,  "{I} [2-by-2] :", PST#NL))

FPUMAT.Matrix_Identity(@m1_2x2, 2)

REPEAT r FROM 1 TO 2
  REPEAT c FROM 1 TO 2
    PST.Str(FloatToString(m1_2x2[((r-1)*2)+(c-1)], 30))
  PST.Char(PST#NL)
  WAITCNT((_DBGDEL/25) + CNT)

PST.Str(STRING(PST#NL,  "{I} [3-by-3] :", PST#NL))

FPUMAT.Matrix_Identity(@m1_3x3, 3)

REPEAT r FROM 1 TO 3
  REPEAT c FROM 1 TO 3
    PST.Str(FloatToString(m1_3x3[((r-1)*3)+(c-1)], 30))
  PST.Char(PST#NL)
  WAITCNT((_DBGDEL/25) + CNT)

PST.Str(STRING(PST#NL,  "{I} [11-by-11] :", PST#NL))

FPUMAT.Matrix_Identity(@m1_11x11, 11)

REPEAT r FROM 1 TO 11
  REPEAT c FROM 1 TO 11
    PST.Str(FloatToString(m1_11x11[((r-1)*11)+(c-1)], 30))
  PST.Char(PST#NL)
  WAITCNT((_DBGDEL/25) + CNT)

QueryReboot

PST.Char(PST#CS)   
PST.Str(STRING("Create a [9-by-9] Diagonal matrix..."))
PST.Chars(PST#NL, 2)

PST.Str(STRING("Lambda = "))
PST.Str(FloatToString(0.1234, 0))
PST.Char(PST#NL)

PST.Str(STRING(PST#NL,  "{D} = Lambda * {I} [9-by-9]", PST#NL))

FPUMAT.Matrix_Diagonal(@m1_9x9, 9, 1.234)       

REPEAT r FROM 1 TO 9
  REPEAT c FROM 1 TO 9
    PST.Str(FloatToString(m1_9x9[((r-1)*9)+(c-1)], 63))
  PST.Char(PST#NL)
  WAITCNT((_DBGDEL/25) + CNT)

QueryReboot

PST.Char(PST#CS)   
PST.Str(STRING("Check Put and Get procedures... "))
PST.Char(PST#NL)

PST.Str(STRING(PST#NL,  "Put 6.28 into [7,2]:", PST#NL)) 
FPUMAT.Matrix_Put(@m1_9x9, 6.28, 7, 2, 9, 9)

REPEAT r FROM 1 TO 9
  REPEAT c FROM 1 TO 9
    PST.Str(FloatToString(m1_9x9[((r-1)*9)+(c-1)], 63))
  PST.Char(PST#NL)
  WAITCNT((_DBGDEL/25) + CNT)

PST.Str(STRING("Transpose the matrix...", PST#NL))          
'Do matrix transposition
FPUMAT.Matrix_Transpose(@m2_9x9, @m1_9x9, 9, 9)

REPEAT r FROM 1 TO 9
  REPEAT c FROM 1 TO 9
    PST.Str(FloatToString(m2_9x9[((r-1)*9)+(c-1)], 63))
  PST.Char(PST#NL)
  WAITCNT((_DBGDEL/25) + CNT)                              

PST.Str(STRING("Get value from [2,7]:", PST#NL))          
fV := FPUMAT.Matrix_Get(@m2_9x9, 2, 7, 9, 9)
PST.Str(FloatToString(fV, 63))
PST.Char(PST#NL)

QueryReboot

PST.Char(PST#CS)
PST.Str(STRING("Add and subtract [3-by-7] random matrices..."))
PST.Char(PST#NL)

'Fill up  [7x3] random matrices
REPEAT i FROM 0 TO 20
  rnd := FPUMAT.Rnd_Float_UnifDist(rnd) 
  m2_3x7[i] := FPUMAT.Rnd_Long_UnifDist(rnd, -19, 19)

REPEAT i FROM 0 TO 20
  rnd := FPUMAT.Rnd_Float_UnifDist(rnd) 
  m3_3x7[i] := FPUMAT.Rnd_Long_UnifDist(rnd, -19, 19)

'Now convert them to float
FPUMAT.Matrix_LongToFloat(@m2_3x7, 3, 7)
FPUMAT.Matrix_LongToFloat(@m3_3x7, 3, 7)

'Do scalar matrix multiplication
FPUMAT.Matrix_ScalarMultiply(@m2_3x7, @m2_3x7, 3, 7, 0.123)
FPUMAT.Matrix_ScalarMultiply(@m3_3x7, @m3_3x7, 3, 7, 0.123)       

PST.Str(STRING(PST#NL,  "{B} [3-by-7]:", PST#NL))

REPEAT r FROM 1 TO 3
  REPEAT c FROM 1 TO 7
    PST.Str(FloatToString(m2_3x7[((r-1)*7)+(c-1)], 84))
  PST.Char(PST#NL)
  WAITCNT((_DBGDEL/25) + CNT)

PST.Str(STRING(PST#NL,  "{C} [3-by-7]:", PST#NL))

REPEAT r FROM 1 TO 3
  REPEAT c FROM 1 TO 7
    PST.Str(FloatToString(m3_3x7[((r-1)*7)+(c-1)], 84))
  PST.Char(PST#NL)
  WAITCNT((_DBGDEL/25) + CNT)

PST.Str(STRING(PST#NL,  "{A}={B}+{C} [3-by-7]:", PST#NL))

'Do matrix addition
FPUMAT.Matrix_Add(@m1_3x7, @m2_3x7, @m3_3x7, 3, 7) 

REPEAT r FROM 1 TO 3
  REPEAT c FROM 1 TO 7
    PST.Str(FloatToString(m1_3x7[((r-1)*7)+(c-1)], 84))
  PST.Char(PST#NL)
  WAITCNT((_DBGDEL/25) + CNT)

PST.Str(STRING(PST#NL,  "{A}={B}-{C} [3-by-7]:", PST#NL))

'Do matrix substraction
FPUMAT.Matrix_Subtract(@m1_3x7, @m2_3x7, @m3_3x7, 3, 7)

REPEAT r FROM 1 TO 3
  REPEAT c FROM 1 TO 7
    PST.Str(FloatToString(m1_3x7[((r-1)*7)+(c-1)], 84))
  PST.Char(PST#NL)
  WAITCNT((_DBGDEL/25) + CNT)

QueryReboot

PST.Char(PST#CS)
PST.Str(STRING("Multiply [5-by-7] and [7-by-6] random matrices..."))
PST.Char(PST#NL)

'Fill up random matrices
REPEAT i FROM 0 TO 34
  rnd := FPUMAT.Rnd_Float_UnifDist(rnd) 
  m1_5x7[i] := FPUMAT.Rnd_Long_UnifDist(rnd, -19, 19)

REPEAT i FROM 0 TO 41
  rnd := FPUMAT.Rnd_Float_UnifDist(rnd) 
  m1_7x6[i] := FPUMAT.Rnd_Long_UnifDist(rnd, -19, 19)

'Now convert them to float
FPUMAT.Matrix_LongToFloat(@m1_5x7, 5, 7)
FPUMAT.Matrix_LongToFloat(@m1_7x6, 7, 6)

'Do scalar * matrix multiplication
FPUMAT.Matrix_ScalarMultiply(@m1_5x7, @m1_5x7, 5, 7, 0.123)
FPUMAT.Matrix_ScalarMultiply(@m1_7x6, @m1_7x6, 7, 6, 0.123)       

PST.Str(STRING(PST#NL,  "{B} [5-by-7]:", PST#NL))

REPEAT r FROM 1 TO 5
  REPEAT c FROM 1 TO 7
    PST.Str(FloatToString(m1_5x7[((r-1)*7)+(c-1)], 84))
  PST.Char(PST#NL)
  WAITCNT((_DBGDEL/25) + CNT)

PST.Str(STRING(PST#NL,  "{C} [7-by-6]:", PST#NL))

REPEAT r FROM 1 TO 7
  REPEAT c FROM 1 TO 6
    PST.Str(FloatToString(m1_7x6[((r-1)*6)+(c-1)], 84))
  PST.Char(PST#NL)
  WAITCNT((_DBGDEL/25) + CNT)                                    

PST.Str(STRING(PST#NL,  "{A}={B}*{C} [5-by-6]:", PST#NL))

'Do matrix multiplication
FPUMAT.Matrix_Multiply(@m1_5x6, @m1_5x7, @m1_7x6, 5, 7, 6)

 REPEAT r FROM 1 TO 5
  REPEAT c FROM 1 TO 6
    PST.Str(FloatToString(m1_5x6[((r-1)*6)+(c-1)], 84))
  PST.Char(PST#NL)
  WAITCNT((_DBGDEL/25) + CNT)

QueryReboot

PST.Char(PST#CS) 
PST.Str(STRING("Eigen Decompositin of a random [5-by-5] matrix {A}")) 
PST.Str(STRING(PST#NL,  "in the form"))
PST.Str(STRING(PST#NL,  "             {A}={U}*{L}*{UT}"))
PST.Str(STRING(PST#NL, "where {U} is a [5-by-5] orthonormal matrix and"))
PST.Str(STRING(PST#NL,  "the diagonal of {L} contains the eigenvalues."))
PST.Char(PST#NL)

PST.Str(STRING(PST#NL,  "{A} [5-by-5]:", PST#NL))
'Fill up  [5x5] random matrix
REPEAT i FROM 0 TO 24
  rnd := FPUMAT.Rnd_Float_UnifDist(rnd) 
  m1_5x5[i] := FPUMAT.Rnd_Long_UnifDist(rnd, -19, 19)
  
'Now convert it to float
FPUMAT.Matrix_LongToFloat(@m1_5x5, 5, 5)

'Make a [5-by-5] symmetric, albeit random matrix
FPUMAT.Matrix_Transpose(@m2_5x5, @m1_5x5, 5, 5)
FPUMAT.Matrix_Add(@m1_5x5, @m1_5x5, @m2_5x5, 5, 5)
FPUMAT.Matrix_ScalarMultiply(@m1_5x5, @m1_5x5, 5, 5, 0.5)

REPEAT r FROM 1 TO 5
  REPEAT c FROM 1 TO 5
    PST.Str(FloatToString(m1_5x5[((r-1)*5)+(c-1)], 84))
  PST.Char(PST#NL)
  WAITCNT((_DBGDEL/25) + CNT)

'Do the eigen-decomposition
FPUMAT.Matrix_Eigen(@m1_5x5, @eVc, 5)

PST.Char(PST#NL)
PST.Str(STRING("Eigenvalues are in the diagonal of {L} [5-by-5]:"))
PST.Char(PST#NL) 
REPEAT r FROM 1 TO 5
  REPEAT c FROM 1 TO 5
    PST.Str(FloatToString(m1_5x5[((r-1)*5)+(c-1)], 84))
  PST.Char(PST#NL)
  WAITCNT((_DBGDEL/25) + CNT) 

PST.Char(PST#NL)
PST.Str(STRING("Eigenvectors are in the colums of {U} [5-by-5]:"))
PST.Char(PST#NL)      
REPEAT r FROM 1 TO 5
  REPEAT c FROM 1 TO 5
    PST.Str(FloatToString(eVc[((r-1)*5)+(c-1)], 84))
  PST.Char(PST#NL)
  WAITCNT((_DBGDEL/25) + CNT)

QueryReboot

PST.Char(PST#CS) 
PST.Str(STRING("{U} is an orthonormal matrix..."))
PST.Chars(PST#NL, 2)
PST.Str(STRING("So {U}*{UT}={I}:"))
PST.Char(PST#NL)

FPUMAT.Matrix_Transpose(@m3_5x5, @eVc, 5, 5)
FPUMAT.Matrix_Multiply(@m2_5x5, @eVc, @m3_5x5, 5, 5, 5)
    
REPEAT r FROM 1 TO 5
  REPEAT c FROM 1 TO 5
    PST.Str(FloatToString(m2_5x5[((r-1)*5)+(c-1)], 84))
  PST.Char(PST#NL)
  WAITCNT((_DBGDEL/25) + CNT)

PST.Char(PST#NL) 
PST.Str(STRING("{A} can be restored as", PST#NL))
PST.Str(STRING(PST#NL,  "{A}={U}*{L}*{UT}:",PST#NL))

'{A}={E}*{UT}
FPUMAT.Matrix_Multiply(@m2_5x5, @m1_5x5, @m3_5x5, 5, 5, 5)
'{A}={U}*{E}*{UT}
FPUMAT.Matrix_Multiply(@m2_5x5, @eVc, @m2_5x5, 5, 5, 5)

REPEAT r FROM 1 TO 5
  REPEAT c FROM 1 TO 5
    PST.Str(FloatToString(m2_5x5[((r-1)*5)+(c-1)], 84))
  PST.Char(PST#NL)
  WAITCNT((_DBGDEL/25) + CNT)

QueryReboot

PST.Char(PST#CS) 
PST.Str(STRING("Singular Value Decomposition (SVD) of a random"))
PST.Str(STRING(PST#NL,  "matrix {A} in the form"))
PST.Str(STRING(PST#NL,  "             {A}={U}*{SV}*{VT}"))
PST.Str(STRING(PST#NL, "where {U}, {VT} are orthonormal matrices and"))
PST.Char(PST#NL)
PST.Str(STRING("the diagonal of {SV} contains the singular values."))
PST.Char(PST#NL)

PST.Str(STRING(PST#NL,  "{A} [3-by-4]:", PST#NL))
'Fill up  [3-by-4] random matrix
REPEAT i FROM 0 TO 11
  rnd := FPUMAT.Rnd_Float_UnifDist(rnd) 
  m1_3x4[i] := FPUMAT.Rnd_Long_UnifDist(rnd, -9, 9)

'Now convert it to float
FPUMAT.Matrix_LongToFloat(@m1_3x4, 3, 4)

REPEAT r FROM 1 TO 3
  REPEAT c FROM 1 TO 4
    PST.Str(FloatToString(m1_3x4[((r-1)*4)+(c-1)], 94))
  PST.Char(PST#NL)
  WAITCNT((_DBGDEL/25) + CNT)

'Do singular value decomposition
FPUMAT.Matrix_SVD(@m1_3x4, @m1_3x3, @m1_4x4, 3, 4)

PST.Str(STRING(PST#NL,  "{U} [3-by-3]:", PST#NL))
REPEAT r FROM 1 TO 3
  REPEAT c FROM 1 TO 3
    PST.Str(FloatToString(m1_3x3[((r-1)*3)+(c-1)], 94))
  PST.Char(PST#NL)
  WAITCNT((_DBGDEL/25) + CNT)

PST.Str(STRING(PST#NL, "{SV} [3-by-4] (same size as {A}):", PST#NL))
REPEAT r FROM 1 TO 3
  REPEAT c FROM 1 TO 4
    PST.Str(FloatToString(m1_3x4[((r-1)*4)+(c-1)], 94))
  PST.Char(PST#NL)
  WAITCNT((_DBGDEL/25) + CNT)

PST.Str(STRING(PST#NL,  "{VT} [4-by-4]:", PST#NL))
REPEAT r FROM 1 TO 4
  REPEAT c FROM 1 TO 4
    PST.Str(FloatToString(m1_4x4[((r-1)*4)+(c-1)], 94))
  PST.Char(PST#NL)
  WAITCNT((_DBGDEL/25) + CNT)

QueryReboot

'Now restore {A} to check
PST.Char(PST#CS)
PST.Str(STRING("Check that {A} can be restored as"))
PST.Chars(PST#NL, 2)

PST.Str(STRING("{U}*{SV}*{VT}:", PST#NL))
'{A}={SV}*{VT}
FPUMAT.Matrix_Multiply(@m1_3x4, @m1_3x4, @m1_4x4, 3, 4, 4)
'{A}={U}*{SV}*{VT} 
FPUMAT.Matrix_Multiply(@m1_3x4, @m1_3x3, @m1_3x4, 3, 3, 4) 

REPEAT r FROM 1 TO 3
  REPEAT c FROM 1 TO 4
    PST.Str(FloatToString(m1_3x4[((r-1)*4)+(c-1)], 94))
  PST.Char(PST#NL)
  WAITCNT((_DBGDEL/25) + CNT)

QueryReboot

PST.Char(PST#CS)
PST.Str(STRING("Calculations with larger matrices."))
PST.Char(PST#NL)

PST.Str(STRING("Multiply [11-by-11] random matrices..."))
PST.Char(PST#NL)

'Fill up  [11x11] random matrix
REPEAT i FROM 0 TO 120
  rnd := FPUMAT.Rnd_Float_UnifDist(rnd) 
  m1_11x11[i] := FPUMAT.Rnd_Long_UnifDist(rnd, -9, 9)

'Now convert it to float
FPUMAT.Matrix_LongToFloat(@m1_11x11, 11, 11)

'Do scalar * matrix multiplication
FPUMAT.Matrix_ScalarMultiply(@m1_11x11,@m1_11x11,11,11,0.123)

PST.Str(STRING(PST#NL,  "{B} [11-by-11]:", PST#NL))

REPEAT r FROM 1 TO 11
  REPEAT c FROM 1 TO 11
    PST.Str(FloatToString(m1_11x11[((r-1)*11)+(c-1)], 62))
  PST.Char(PST#NL)
  WAITCNT((_DBGDEL/25) + CNT)
  
'Fill up  another [11x11] random matrix
REPEAT i FROM 0 TO 120
  rnd := FPUMAT.Rnd_Float_UnifDist(rnd) 
  m2_11x11[i] := FPUMAT.Rnd_Long_UnifDist(rnd, -9, 9)

'Now convert it to float
FPUMAT.Matrix_LongToFloat(@m2_11x11, 11, 11)

'Do scalar * matrix multiplication
FPUMAT.Matrix_ScalarMultiply(@m2_11x11,@m2_11x11,11,11,0.123)

PST.Str(STRING(PST#NL,  "{C} [11-by-11]:", PST#NL))

REPEAT r FROM 1 TO 11
  REPEAT c FROM 1 TO 11
    PST.Str(FloatToString(m2_11x11[((r-1)*11)+(c-1)], 62))
  PST.Char(PST#NL)
  WAITCNT((_DBGDEL/25) + CNT)                            

PST.Str(STRING(PST#NL,  "{A}={B}*{C} [11-by-11]:", PST#NL))

'Do matrix multiplication
FPUMAT.Matrix_Multiply(@m1_11x11,@m1_11x11,@m2_11x11,11,11,11)

 REPEAT r FROM 1 TO 11
  REPEAT c FROM 1 TO 11
    PST.Str(FloatToString(m1_11x11[((r-1)*11)+(c-1)], 62))
  PST.Char(PST#NL)
  WAITCNT((_DBGDEL/25) + CNT)

QueryReboot

PST.Char(PST#CS)
PST.Str(STRING("Invert the product matrix...", PST#NL))
PST.Str(STRING(PST#NL,  "{1/A} [11-by-11]:", PST#NL))

'Invert 
FPUMAT.Matrix_Invert(@m2_11x11, @m1_11x11, 11)

REPEAT r FROM 1 TO 11
  REPEAT c FROM 1 TO 11
    PST.Str(FloatToString(m2_11x11[((r-1)*11)+(c-1)], 62))
  PST.Char(PST#NL)
  WAITCNT((_DBGDEL/25) + CNT) 

PST.Str(STRING(PST#NL,  "Check that {A}*{1/A}={I} [11-by-11]:"))
PST.Char(PST#NL)
'Do matrix multiplication
FPUMAT.Matrix_Multiply(@m1_11x11,@m1_11x11,@m2_11x11,11,11,11)

REPEAT r FROM 1 TO 11
  REPEAT c FROM 1 TO 11
    PST.Str(FloatToString(m1_11x11[((r-1)*11)+(c-1)], 62))
  PST.Char(PST#NL)
  WAITCNT((_DBGDEL/25) + CNT)

QueryReboot

PST.Char(PST#CS)
PST.Str(STRING("Create a symmetric natrix", PST#NL))

PST.Char(PST#NL)
PST.Str(STRING("{A} [11-by-11]:"))
PST.Char(PST#NL)

'Make a symmetric matrix 
FPUMAT.Matrix_Transpose(@m1_11x11,@m2_11x11,11,11)
FPUMAT.Matrix_Add(@m2_11x11,@m2_11x11,@m1_11x11,11,11)

REPEAT r FROM 1 TO 11
  REPEAT c FROM 1 TO 11
    PST.Str(FloatToString(m2_11x11[((r-1)*11)+(c-1)], 62))
  PST.Char(PST#NL)
  WAITCNT((_DBGDEL/25) + CNT)    

PST.Str(STRING(PST#NL,  "Eigenvalues of this matrix [11-by-11]:"))
PST.Char(PST#NL)
  
FPUMAT.Matrix_Eigen(@m2_11x11, @m1_11x11, 11)

REPEAT r FROM 1 TO 11
  REPEAT c FROM 1 TO 11
    PST.Str(FloatToString(m2_11x11[((r-1)*11)+(c-1)], 62))
  PST.Char(PST#NL)
  WAITCNT((_DBGDEL/25) + CNT)

QueryReboot

PST.Char(PST#CS)
PST.Str(STRING("Somewhere on Earth our navigation computer 'knows'"))
PST.Char(PST#NL)
PST.Str(STRING("from from the GPS position the components of the"))
PST.Char(PST#NL)
PST.Str(STRING("magnetic and gravity vectors for that place:"))
PST.Chars(PST#NL, 2)

'NED components for a given Lat, Lon, Alt
magnNED[0] := 31.9     'North component of WMM2010 magn. vector
magnNED[1] := 12.3     'East component  of WMM2010 magn. vector
magnNED[2] := 18.2     'Down component  of WMM2010 magn. vector
                       'in uT (microTesla)

gravNED[0] := 0.0      'North component of WGS84 gravity vector
gravNED[1] := 0.0      'East component of  WGS84 gravity vector
gravNED[2] := 9.808    'Down component of  WGS84 gravity vector
                       'in m/s2

PST.Str(STRING("  B(North)[uT] = "))
PST.Str(FloatToString(magnNED[0], 51))
PST.Str(STRING(PST#NL, "  B(East) [uT] = "))
PST.Str(FloatToString(magnNED[1], 51))
PST.Str(STRING(PST#NL, "  B(Down) [uT] = "))
PST.Str(FloatToString(magnNED[2], 51))
PST.Char(PST#NL)
PST.Str(STRING(PST#NL, "G(North)[m/s2] = "))
PST.Str(FloatToString(gravNED[0], 73))
PST.Str(STRING(PST#NL, "G(East) [m/s2] = "))
PST.Str(FloatToString(gravNED[1], 73))
PST.Str(STRING(PST#NL, "G(Down) [m/s2] = "))
PST.Str(FloatToString(gravNED[2], 73))
PST.Char(PST#NL)     

QueryReboot 

PST.Char(PST#CS)
PST.Str(STRING("However, the strapped down sensors measure these"))
PST.Char(PST#NL)
PST.Str(STRING("vectors in Body frame components of our robot."))
PST.Char(PST#NL)
PST.Str(STRING("The measured values are:"))
PST.Chars(PST#NL, 2)

'The strapped down sensors of our plane, however, measure
magnBody[0] := -27.9   'Magn. component to nose direction
magnBody[1] := 20.6    'Magn. component to right wing direction
magnBody[2] := 18.9    'Magn. component to bely direction
                       'in uT

gravBody[0] := 0.67    'Grav. component to nose direction 
gravBody[1] := 0.85    'Grav. component to right wing direction 
gravBody[2] := 9.74    'Grav. component to bely direction 
                       'in m/s2
 
PST.Str(STRING("  B(Nose) [uT] = "))
PST.Str(FloatToString(magnBody[0], 51))
PST.Str(STRING(PST#NL,  "  B(Right)[uT] = "))
PST.Str(FloatToString(magnBody[1], 51))
PST.Str(STRING(PST#NL,  "  B(Bely) [uT] = "))
PST.Str(FloatToString(magnBody[2], 51))
PST.Char(PST#NL)
PST.Str(STRING(PST#NL, "G(Nose) [m/s2] = "))
PST.Str(FloatToString(gravBody[0], 73))
PST.Str(STRING(PST#NL, "G(Right)[m/s2] = "))
PST.Str(FloatToString(gravBody[1], 73))
PST.Str(STRING(PST#NL, "G(Bely) [m/s2] = "))
PST.Str(FloatToString(gravBody[2], 73))
PST.Char(PST#NL)    

QueryReboot

PST.Char(PST#CS) 
PST.Str(STRING("What are the Heading, Pitch and Roll Euler angles"))
PST.Char(PST#NL)
PST.Str(STRING("of the robot in a straightforward and accurate"))
PST.Char(PST#NL)
PST.Str(STRING("approximation? We will use the 'Triad' algorithm"))
PST.Char(PST#NL)
PST.Str(STRING("realised with the FPU64_MATRIX_Driver procedures."))
PST.Char(PST#NL)

QueryReboot

'Let us use the Triad algorithm to calculate the Body to NED
'Direction Cosine Matrix (DCM)

'First create an orthogonal, rigth handed frame using the Body
'frame coordinates of the two measured physical vector.

'Let us first start with the magnetic vector. We will repeat the
'algorithm starting with the gravity vector, an we will average
'the resulting attitudes for robust appproximation.
FPUMAT.Vector_Unitize(@t1b, @magnBody)
FPUMAT.Vector_CrossProduct(@t2b, @magnBody, @gravBody)
FPUMAT.Vector_Unitize(@t2b, @t2b)
FPUMAT.Vector_CrossProduct(@t3b, @t1b, @t2b)

'Then create the same frame (the triad) but calculate it from the
'NED frame physical vector components this time
FPUMAT.Vector_Unitize(@t1n, @magnNED)
FPUMAT.Vector_CrossProduct(@t2n, @magnNED, @gravNED)
FPUMAT.Vector_Unitize(@t2n, @t2n)
FPUMAT.Vector_CrossProduct(@t3n, @t1n, @t2n)

'Unit vector DCM matrices can now be created from these othogonal
'tb, tn unit vectors by putting the vector components into the
'columns of [3x3] DCM matrices

'Create {Body to Triad} rotation matrix
REPEAT i FROM 0 TO 2
  dcmBT[i * 3] := t1b[i]
  dcmBT[(i * 3) + 1] := t2b[i]
  dcmBT[(i * 3) + 2] := t3b[i]

'Create {NAV to Triad} rotation matrix
REPEAT i FROM 0 TO 2
  dcmNT[i * 3] := t1n[i]
  dcmNT[(i * 3) + 1] := t2n[i]
  dcmNT[(i * 3) + 2] := t3n[i]
'Transpose this matrix to obtain {Triad to NAV} rotation matrix
FPUMAT.Matrix_Transpose(@dcmTN, @dcmNT, 3, 3)

'Now we can calculate {Body to NAV} rotation matrix by multiplying
'{Body to Triad} * {Triad to NAV} rotation matrices
FPUMAT.Matrix_Multiply(@dcmBN, @dcmBT, @dcmTN, 3, 3, 3)
 
'Now we have the Body to NAV DCM. From this we can calculate
'an approximation to the attitude

'Psi = ArcTan(-DCM21/DCM11)
fV := dcmBN[0]                               '(1-1)*3 + (1-1)
FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 126)
FPUMAT.WriteCmdLONG(FPUMAT#_FWRITEA, fV) 
fV := dcmBN[3]                               '(2-1)*3 + (1-1)
FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 127)
FPUMAT.WriteCmdLONG(FPUMAT#_FWRITEA, fV)
FPUMAT.WriteCmd(FPUMAT#_FNEG)
FPUMAT.WriteCmdByte(FPUMAT#_ATAN2, 126)
FPUMAT.WriteCmd(FPUMAT#_DEGREES)
FPUMAT.Wait
FPUMAT.WriteCmd(FPUMAT#_FREADA)
heading := FPUMAT.ReadReg

'Theta = ArcTan(DCM31/SQRT(DCM11^2+DCM21^2))
fV := dcmBN[0]                               '(1-1)*3 + (1-1)
FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 125)
FPUMAT.WriteCmdLONG(FPUMAT#_FWRITEA, fV)
FPUMAT.WriteCmdByte(FPUMAT#_FMUL, 125)
fV := dcmBN[3]                               '(2-1)*3 + (1-1)
FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 126)
FPUMAT.WriteCmdLONG(FPUMAT#_FWRITEA, fV)
FPUMAT.WriteCmdByte(FPUMAT#_FMUL, 126)
FPUMAT.WriteCmdByte(FPUMAT#_FADD, 125)
FPUMAT.WriteCmd(FPUMAT#_SQRT)
fV := dcmBN[6]                               '(3-1)*3 + (1-1)
FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 127)
FPUMAT.WriteCmdLONG(FPUMAT#_FWRITEA, fV)
FPUMAT.WriteCmdByte(FPUMAT#_ATAN2, 126)
FPUMAT.WriteCmd(FPUMAT#_DEGREES)
FPUMAT.Wait
FPUMAT.WriteCmd(FPUMAT#_FREADA)
pitch := FPUMAT.ReadReg

'Phi = ArcTan(DCM32/DCM33)
fV := dcmBN[8]                               '(3-1)*3 + (3-1)
FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 126)
FPUMAT.WriteCmdLONG(FPUMAT#_FWRITEA, fV) 
fV := dcmBN[7]                               '(3-1)*3 + (2-1)
FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 127)
FPUMAT.WriteCmdLONG(FPUMAT#_FWRITEA, fV)
FPUMAT.WriteCmdByte(FPUMAT#_ATAN2, 126)
FPUMAT.WriteCmd(FPUMAT#_DEGREES)
FPUMAT.Wait 
FPUMAT.WriteCmd(FPUMAT#_FREADA)
roll := FPUMAT.ReadReg

'Now let us do it again starting with the gravity vector this time.
'Create an orthogonal, rigth handed frame using the two measured
'physical vector's Body frame coordinates
FPUMAT.Vector_Unitize(@t1b, @gravBody)
FPUMAT.Vector_CrossProduct(@t2b, @gravBody, @magnBody)
FPUMAT.Vector_Unitize(@t2b, @t2b)
FPUMAT.Vector_CrossProduct(@t3b, @t1b, @t2b)

'Then create the same frame (the triad) but now calculate with the
'NED frame physical vector components
FPUMAT.Vector_Unitize(@t1n, @gravNED)
FPUMAT.Vector_CrossProduct(@t2n, @gravNED, @magnNED)
FPUMAT.Vector_Unitize(@t2n, @t2n)
FPUMAT.Vector_CrossProduct(@t3n, @t1n, @t2n)

'Unit vector DCM matrices can now be created From these othogonal
'tb, tn unit vectors-by-putting the t vector components into the
'columns of [3x3] DCM matrices

'Create {Body to Triad} rotation matrix
REPEAT i FROM 0 TO 2
  dcmBT[i * 3] := t1b[i]
  dcmBT[(i * 3) + 1] := t2b[i]
  dcmBT[(i * 3) + 2] := t3b[i]

'Create {NAV to Triad} rotation matrix
REPEAT i FROM 0 TO 2
  dcmNT[i * 3] := t1n[i]
  dcmNT[(i * 3) + 1] := t2n[i]
  dcmNT[(i * 3) + 2] := t3n[i]
'Transpose it to obtain {Triad to NAV} rotation matrix
FPUMAT.Matrix_Transpose(@dcmTN, @dcmNT, 3, 3)

'Now we can calculate {Body to NAV} rotation matrix by multiplying
'{Body to Triad} * {Triad to NAV} rotation matrices
FPUMAT.Matrix_Multiply(@dcmBN, @dcmBT, @dcmTN, 3, 3, 3)

'Again we have the Body to NAV DCM. From this we can calculate
'another approximation to the attitude

'Psi = ArcTan(-DCM21/DCM11)
fV := dcmBN[0]                               '(1-1)*3 + (1-1)
FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 126)
FPUMAT.WriteCmdLONG(FPUMAT#_FWRITEA, fV) 
fV := dcmBN[3]                               '(2-1)*3 + (1-1)
FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 127)
FPUMAT.WriteCmdLONG(FPUMAT#_FWRITEA, fV)
FPUMAT.WriteCmd(FPUMAT#_FNEG)
FPUMAT.WriteCmdByte(FPUMAT#_ATAN2, 126)
FPUMAT.Wait
FPUMAT.WriteCmd(FPUMAT#_DEGREES)
'Take average with previous value
FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 126)
FPUMAT.WriteCmdLONG(FPUMAT#_FWRITEA, heading)
FPUMAT.WriteCmdByte(FPUMAT#_FADD, 127)
FPUMAT.WriteCmdByte(FPUMAT#_FDIVI, 2)
FPUMAT.Wait   
FPUMAT.WriteCmd(FPUMAT#_FREADA)
heading := FPUMAT.ReadReg

'Convert to compass bearing
oKay := FPUMAT.F32_GT(0.0, heading, 0.0)
IF oKay                 'Then give 360 to heading
  FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 127)
  FPUMAT.WriteCmdLONG(FPUMAT#_FWRITEA, heading)
  FPUMAT.WriteCmdByte(FPUMAT#_FADDI, 120)
  FPUMAT.WriteCmdByte(FPUMAT#_FADDI, 120)
  FPUMAT.WriteCmdByte(FPUMAT#_FADDI, 120)
  FPUMAT.Wait 
  FPUMAT.WriteCmd(FPUMAT#_FREADA)
  heading := FPUMAT.ReadReg 

'Theta = ArcTan(DCM31/SQRT(DCM11^2+DCM21^2))
fV := dcmBN[0]                               '(1-1)*3 + (1-1)
FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 125)
FPUMAT.WriteCmdLONG(FPUMAT#_FWRITEA, fV)
FPUMAT.WriteCmdByte(FPUMAT#_FMUL, 125)
fV := dcmBN[3]                               '(2-1)*3 + (1-1)
FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 126)
FPUMAT.WriteCmdLONG(FPUMAT#_FWRITEA, fV)
FPUMAT.WriteCmdByte(FPUMAT#_FMUL, 126)
FPUMAT.WriteCmdByte(FPUMAT#_FADD, 125)
FPUMAT.WriteCmd(FPUMAT#_SQRT)
fV := dcmBN[6]                               '(3-1)*3 + (1-1)
FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 127)
FPUMAT.WriteCmdLONG(FPUMAT#_FWRITEA, fV)
FPUMAT.WriteCmdByte(FPUMAT#_ATAN2, 126)
FPUMAT.Wait
FPUMAT.WriteCmd(FPUMAT#_DEGREES)
'Take average
FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 126)
FPUMAT.WriteCmdLONG(FPUMAT#_FWRITEA, pitch)
FPUMAT.WriteCmdByte(FPUMAT#_FADD, 127)
FPUMAT.WriteCmdByte(FPUMAT#_FDIVI, 2)
FPUMAT.Wait 
FPUMAT.WriteCmd(FPUMAT#_FREADA)
pitch := FPUMAT.ReadReg

'Phi = ArcTan(DCM32/DCM33)
fV := dcmBN[8]                               '(3-1)*3 + (3-1)
FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 126)
FPUMAT.WriteCmdLONG(FPUMAT#_FWRITEA, fV) 
fV := dcmBN[7]                               '(3-1)*3 + (2-1)
FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 127)
FPUMAT.WriteCmdLONG(FPUMAT#_FWRITEA, fV)
FPUMAT.WriteCmdByte(FPUMAT#_ATAN2, 126)
FPUMAT.Wait
FPUMAT.WriteCmd(FPUMAT#_DEGREES)
'Take average
FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 126)
FPUMAT.WriteCmdLONG(FPUMAT#_FWRITEA, roll)
FPUMAT.WriteCmdByte(FPUMAT#_FADD, 127)
FPUMAT.WriteCmdByte(FPUMAT#_FDIVI, 2)
FPUMAT.Wait
FPUMAT.WriteCmd(FPUMAT#_FREADA)
roll := FPUMAT.ReadReg

'Display results of TRIAD
PST.Char(PST#CS) 
PST.Str(STRING("Attitude of the robot obtained with the Triad"))
PST.Char(PST#NL)
PST.Str(STRING("algorithm:"))
PST.Char(PST#NL)

PST.Str(STRING(PST#NL,  "Heading = "))
PST.Str(FloatToString(heading, 50))
PST.Str(STRING(" degrees"))
PST.Str(STRING(PST#NL,  "  Pitch = "))
PST.Str(FloatToString(pitch, 50))
PST.Str(STRING(" degrees"))
PST.Str(STRING(PST#NL,  "   Roll = "))
PST.Str(FloatToString(roll, 50))
PST.Str(STRING(" degrees"))
PST.Char(PST#NL)  
  
QueryReboot
'-------------------------End of FPU64_MATRIX_Demo------------------------


PRI FloatToString(floatV, format)
'-------------------------------------------------------------------------
'------------------------------┌───────────────┐--------------------------
'------------------------------│ FloatToString │--------------------------
'------------------------------└───────────────┘--------------------------
'-------------------------------------------------------------------------
'     Action: Converts a HUB/floatV into string within FPU then loads it
'             back into HUB
' Parameters: - Float value
'             - Format code in FPU convention
'    Results: Pointer to string in HUB
'+Reads/Uses: /FPUMAT:FPU CONs                
'    +Writes: FPU Reg:127
'      Calls: FPU_Matrix_Driver------->FPUMAT.WriteCmdByte
'                                      FPUMAT.WriteCmdLONG
'                                      FPUMAT.ReadRaFloatAsStr
'       Note: Quick solution for debug and test purposes
'-------------------------------------------------------------------------
FPUMAT.WriteCmdByte(FPUMAT#_SELECTA, 127)
FPUMAT.WriteCmdLONG(FPUMAT#_FWRITEA, floatV) 
RESULT := FPUMAT.ReadRaFloatAsStr(format) 
'-------------------------------------------------------------------------


PRI QueryReboot | done, r
'-------------------------------------------------------------------------
'------------------------------┌─────────────┐----------------------------
'------------------------------│ QueryReboot │----------------------------
'------------------------------└─────────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Queries to reboot or to finish
' Parameters: None                                
'     Result: None                
'+Reads/Uses: PST#NL, PST#PX                     (OBJ/CON)
'    +Writes: None                                    
'      Calls: "Parallax Serial Terminal"--------->PST.Str
'                                                 PST.Char 
'                                                 PST.RxFlush
'                                                 PST.CharIn
'------------------------------------------------------------------------
PST.Char(PST#NL)
PST.Str(STRING("[R]eboot or press any other key to continue..."))
PST.Char(PST#NL)
done := FALSE
REPEAT UNTIL done
  PST.RxFlush
  r := PST.CharIn
  IF ((r == "R") OR (r == "r"))
    PST.Char(PST#PX)
    PST.Char(0)
    PST.Char(32)
    PST.Char(PST#NL) 
    PST.Str(STRING("Rebooting..."))
    WAITCNT((CLKFREQ / 10) + CNT) 
    REBOOT
  ELSE
    done := TRUE
'----------------------------End of QueryReboot---------------------------


DAT '---------------------------MIT License------------------------------- 


{{
┌────────────────────────────────────────────────────────────────────────┐
│                        TERMS OF USE: MIT License                       │                                                            
├────────────────────────────────────────────────────────────────────────┤
│  Permission is hereby granted, free of charge, to any person obtaining │
│ a copy of this software and associated documentation files (the        │ 
│ "Software"), to deal in the Software without restriction, including    │
│ without limitation the rights to use, copy, modify, merge, publish,    │
│ distribute, sublicense, and/or sell copies of the Software, and to     │
│ permit persons to whom the Software is furnished to do so, subject to  │
│ the following conditions:                                              │
│                                                                        │
│  The above copyright notice and this permission notice shall be        │
│ included in all copies or substantial portions of the Software.        │  
│                                                                        │
│  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND        │
│ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     │
│ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. │
│ IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   │
│ CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   │
│ TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      │
│ SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 │
└────────────────────────────────────────────────────────────────────────┘
}}