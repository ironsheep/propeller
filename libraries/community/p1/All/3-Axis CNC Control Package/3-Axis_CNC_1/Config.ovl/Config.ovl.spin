{{
Don Starkey
Email: Don@StarkeyMail.com
Ver. 1.0,  4/1/2012


Config.Ovl.Spin (Compile into .BIN file and save it as "Config.ovl" on the SD memory card)

2nd program file that gets swapped in for editing the settings and setup values.
Pass "0" or "1" as the "Chain" variable to tell this program what to do.
    "0" to run the Setup Menu
    "1" to run the Offsets Menu
    

    I/O P10 - X-Axis Home / +Overtravel (Normally HIGH, Active LOW with Axis HOME, +Overtravel)
    I/O P11 - X-Axis -Overtravel        (Normally HIGH, Active LOW with -Overtravel)
    I/O P12 - Y-Axis Home / +Overtravel (Normally HIGH, Active LOW with Axis HOME, +Overtravel)
    I/O P13 - Y-Axis -Overtravel        (Normally HIGH, Active LOW with -Overtravel)
    I/O P14 - Z-Axis Home / +Overtravel (Normally HIGH, Active LOW with Axis HOME, +Overtravel)
    I/O P15 - Z-Axis -Overtravel        (Normally HIGH, Active LOW with -Overtravel)

    ' Must be a contiguous block of 6 pins    
    I/O P16 - X-Axis Step Pin ' Movement happens on the Falling edge of our step pulse which is then    
                                '  inverted through driver transistor = rising edge ( Low for 0.5 uS)
                                '  for Superior SD200 step driver.  
    I/O P17 - X-Axis Direction Pin (Bit set for Negative direction Move, Bit clear for Positive direction move)

    I/O P18 - Y-Axis Step Pin ' Movement happens on the Falling edge of our step pulse which is then  
                                '  inverted through driver transistor = rising edge ( Low for 0.5 uS)
                                '  for Superior SD200 step driver.    

    I/O P19 - Y-Axis Direction Pin (Bit set for Negative direction Move, Bit clear for Positive direction move)

    I/O P20 - Z-Axis Step Pin ' Movement happens on the Falling edge of our step pulse which is then 
                                '  inverted through driver transistor = rising edge ( Low for 0.5 uS)
                                '  for Superior SD200 step driver.    

    I/O P21 - Z-Axis Direction Pin (Bit set for Negative direction Move, Bit clear for Positive direction move)

    I/O P22 -

    I/O P23 - Drive Enable (stepper drives enabled when HIGH)

    I/O P24 - SD Card DO Pin   
    I/O P25 - SD Card CLK Pin    
    I/O P26 - SD Card DI Pin   
    I/O P27 - SD Card CS Pin   

    I/O P28 - SCL I2C
    I/O P39 - SDA I2C
    I/O P30 - Serial Communications
    I/O P31 - Serial Communications

}}

CON                  
    _CLKMODE        = XTAL1 + PLL16X                     
    _XINFREQ        = 5_000_000
    _Stack          = 150
    

    ' Pin Usage Equates
    X_OT_Pos        = 10    ' X Overtravel Positive & Home     (Normally HIGH, Active LOW)
    X_OT_Neg        = 11    ' X Overtravel Negative Direction  (Normally HIGH, Active LOW)
    Y_OT_Pos        = 12    ' Y Overtravel Positive & Home     (Normally HIGH, Active LOW)
    Y_OT_Neg        = 13    ' Y Overtravel Negative Direction  (Normally HIGH, Active LOW)
    Z_OT_Pos        = 14    ' Z Overtravel Positive & Home     (Normally HIGH, Active LOW)
    Z_OT_Neg        = 15    ' Z Overtravel Negative Direction  (Normally HIGH, Active LOW) 
    
    StepXPin        = 16+0  ' Must be a contiguous block of 6 pins
'   DirXPin         = 16+1
'   StepYPin        = 16+2
'   DirYPin         = 16+3
'   StepZPin        = 16+4
'   DirZPin         = 16+5
'    OvertravelPin   = 22    ' Overtravel / Home 

    EnablePin       = 23    ' Stepper Driver Enable when HIGH
    DOPin           = 24    ' SD Card Data OUT
    ClkPin          = 25    ' SD Card Clock
    DIPin           = 26    ' SD Card Data IN
    CSPin           = 27    ' SD Card Chip Select
    I2CBase         = 28    ' ADS1000 12-Bit A/D Chip Clock 

    MinPulse        = 10
    MaxPulse        = 650   ' Don't know why but too long causes errors in output driver
    
    BufferSize      = 64    ' Buffer for CNC line import from file
    ShortBufSize    = 30
    
  ' i2c bus contants
    ADAddress       = 73    ' ADS1000 12-bit A/D for Feed-Rate override

    ' ADS1000BD1 12-Bit A/D converter   @ I2C address %1001001 @ 73
    ADS1000A0_Addr              = %100_1000             ' I2C Address of D/A converter BD0 @ 72                   '
    ADS1000A1_Addr              = %100_1001             ' I2C Address of D/A converter BD1 @ 73
    ADS1000_ContConv            = %00000                '  ADS1000 Continuous Conversion
    ADS1000_SingleConv          = %10000                ' ADS1000 Single Conversion
    ADS1000_PGA1                = %00                   ' ADS1000 PGA Gain of 1
    ADS1000_PGA2                = %01                   ' ADS1000 PGA Gain of 2
    ADS1000_PGA4                = %10                   ' ADS1000 PGA Gain of 4
    ADS1000_PGA8                = %11                   ' ADS1000 PGA Gain of 8

    AbsFloat                    = %0111_1111_1111_1111_1111_1111_1111_1111
    
OBJ

        Ser     : "VT100 Serial Terminal"                   ' Spin code interperter running in first COG
        FS      : "FloatString"                             ' Spin code          
        FM      : "FloatMath"                               ' Spin code
        F32     : "F32_pasm"                                ' Requires 1 COG  F32 V1.5a Floating Point Math Object Y Jonathan "lonesock" Dummer
        fat0    : "SD-MMC_FATEngine.spin"                   ' Requires 1 COG
        fat1    : "SD-MMC_FATEngine.spin"                   ' Requires 1 COG
VAR

' Dont rearrange the order of these variables as the PASM code need to know them in order

        long OT_Mode    ' -16 Overtravel Mode. 0 = norm: OT will stop all motion & reset the move
                        '                      1 = Home mode, OT will stop just the offending axis but the move will complete
        long F32_Cmd    ' -12
        long F32Arg1    ' -8
        long F32Arg2    ' -4
        long s_State    ' +0 Commanded State of Movement for Circular Interpolation cog
                        ' State of 0 = idle, awaiting a value from Spin program
                        ' State of 1 = move in linear mode G00 or G01. If overtravel all movement will stop.
                        ' State of +2 = move in  CW circular interpolation Direction = G02
                        ' State of -2 = move in CCW circular interpolation Direction = G03
                        ' Use this variable to pass the Interpolation cogs the address of the output
                        ' buffer located at the bottom of this cog.
                        ' When initializing the Circular Interpolation cog.
                        ' State = 92 to set the absolute position (G92)
                        ' State = OTCode if overtraveled
                        
        long s_FromX    ' +4  From X Coordinate (Float)
        long s_FromY    ' +8  From Y Coordinate (Float)
        long s_FromZ    ' +12 From Z Coordinate (Float) 
        long s_ToX      ' +16 To X Coordinate (Float)
        long s_ToY      ' +20 To Y Coordinate (Float)
        long s_ToZ      ' +24 To Z Coordinate (Float)
        long s_I        ' +28 Distance from Starting X to Center of Radius along X-Axis (Float)
        long s_J        ' +32 Distance from Starting Y to Center of Radius along Y-Axis (Float)        
        long s_K        ' +36 Distance from Starting Z to Center of Radius along Z-Axis (Float)        
        long s_SPM      ' +40 Speed of movement in Inches/Minutes (Float)

        long s_XAt      ' +44 Current location of X Axis (Integer Step Counts)
        long s_YAt      ' +48 Current location of Y Axis (Integer Step Counts)
        long s_ZAt      ' +52 Current location of Z Axis (Integer Step Counts)

        long s_PotRaw   ' +56 Feed Rate Potentiometer Value (0-2048)
        long s_PotScale ' +60 Feed Rate Potentiometer Value (0-2.0 for 200% override)
    

        long DebugVar1  ' +64  Debugging variables, can be deleted
        long DebugVar2  ' +68  Debugging variables, can be deleted
        long DebugVar3  ' +72  Debugging variables, can be deleted
        long DebugVar4  ' +76  Debugging variables, can be deleted
        long DebugVar5  ' +80  Debugging variables, can be deleted
        long DebugVar6  ' +84  Debugging variables, can be deleted


        long    OutputBuffer    ' Pass-through variable between Interpolation COGs and Output Driver

        long    X               ' X-Coordinate  (Long)
        long    Y               ' Y-Coordinate  (Long)
        long    Z               ' Z-Coordinate  (Long)
        long    I               ' I-Coordinate  (Long)
        long    J               ' J-Coordinate  (Long)
        long    K               ' K-Coordinate  (Long)
        long    U               ' Incremental X-Coordinate  (Long)
        long    V               ' Incremental Y-Coordinate  (Long)
        long    W               ' Incremental Z-Coordinate  (Long)
        long    R               ' R-Coordinate  (Long)
        long    F               ' Feed Rate     (Long)
        long    S               ' Spindle Speed
        
        long    GMode1          ' Group 1 Modal Commands G0, G1, G2, G3
        long    WorkOffset      ' 54 - 59 or 0 if none (when 92 is called)
        long    IncAbs          ' Either 90 for Absolute or 91 for incremental interpertation of X,Y & Z
        long    OffsetX         ' Total Workplane Offset X (Combination of G92 Offset + G54..59 Offset
        long    OffsetY         ' Total Workplane Offset Y (Combination of G92 Offset + G54..59 Offset
        long    OffsetZ         ' Total Workplane Offset Z (Combination of G92 Offset + G54..59 Offset
        long    G92X            ' X Offset
        long    G92Y            ' Y Offset
        long    G92Z            ' Z Offset
'        byte    OffsetActive    ' bitmask for active offsets b0=X, B1=Y, B2=Z    
        long    SourceBlockPtr
        word    TokenStringPointer

        byte    InComment
        byte    BufferedChar
        byte    LastChar
        long    lc
        word    i2cSDA, i2cSCL
        long    lHex
        long    qValue
        long    FileReadPos
        long    SerLine
        long    ProcessPtr    
        byte    EOF, NoScroll
        long    OpMode
        long    Interrupt
        long    JogInc
        long    line 
        
PUB Start | tmp 

    ser.start(115200)                   ' Start the serial port driver @ 115200 to display status of SD read

'ser.str(string(13,10,"Start reading config"))

    ReadConfig(0)   ' Silently load

'ser.str(string(13,10,"done reading config"))

    repeat tmp from StepXPin to StepXPin+5
     
'        ser.position(50,tmp-5)
        if (Var_Polarity & (|<tmp))
            outa[tmp]~
        else
            outa[tmp]~~

    dira[StepXPin..StepXPin+5]~~
'    DisableDrives

    if Var_Baud                         ' Only re-start serial if baudrate <> 0                        
        ser.stop                            ' If we got this far, the SD card was read so                                                   
        ser.start(fm.FTrunc(Var_Baud))         ' re-start the serial port driver at the right baud rate. 

    I2CInit                             ' Start SPIN I2C driver for A/D converter 

    GreenOnBlack

'SER.CLEAR
'ser.str(string(13,10,"done reading config"))
'ser.str(string(13,10,"Var_Chain: "))
'SER.DEC(VAR_CHAIN)
'WAITCNT(CLKFREQ*5+CNT)
    
    ser.clear

    case Var_Chain
        "0":
          SetupMenu
        "1":
          OffsetMenu

        other:
            ser.str(string(13,10,"Failed Chain Value: "))
            SER.DEC(VAR_CHAIN)
            waitcnt(clkfreq*2+cnt)

    ser.position(1,24)
    ser.ClearBelow
    ser.position(33,24)
    WhiteOnRed
    ser.str(string("Saving Settings"))

    writeconfig(0) ' Silently save

    RebootMe


PRI SetupMenu | ParamPtr, VarPtr, PrevLine, Col, PrevCol, Tmp, Width
' Edit configuration parameters

    ser.clear
    ser.home

'Param30    byte    "Feed Rate Override",0                  ' Feed Rate OverRide Value "200" = 200%
'Param31    byte    "Axis Steps Per Inch",0                 ' Steps Per Inch on All Axis 4000 = .00025 Resolution
'Param32    byte    "Rapid Feed Rate",0                     ' G0 feedrate 50 = 50 IPM
'Param33    byte    "Jog Feed Rate",0                       ' Jogging feedrate 50 = 50 IPM
'Param34    byte    "Step Driver Pulse Time",0              ' "400" clock cycles
'Param35    byte    "Serial Terminal Baud Rate",0           ' 115200 baud
'Param36    byte    "CNC File Extension",0                  ' ".TXT"
'Param37    byte    "Step Driver Polarity",0                ' bitmask

    Ser.position(15,1)
    WhiteOnRed
    ser.str(string("System Settings                      1.0 1/1/2013"))

    GreenOnBlack

    ParamPtr:=@Param30
    VarPtr:=@Var_Override
    Line:=0
    ser.position(75,1)
    ser.DecPad(Var_Polarity & %1_1111_1111,5)

    repeat while byte[ParamPtr]

        case ParamPtr

            @Param36:   ' Default Filename Extension
                ser.position(6,5+(Line*2))
                ser.str(@ValidExt)

            @Param37:   ' Polarity Bitmask
            
            '1                  23 = Enable Pin
            ' 0                 22 = nothing
            '  1                21 = DirZPin
            '   1               20 = StepZPin
            '    1              19 = DirYPin
            '     1             18 = StepYPin
            '      1            17 = DirXPin
            '       1           16 = StepXPin
            '        1          15 = Z_OT_Neg Pin
            '         1         14 = Z_OT_Pos Pin
            '          1        13 = Y_OT_Neg Pin
            '           1       12 = Y_OT_Pos Pin
            '            1      11 = X_OT_Neg Pin
            '             1     10 = X_OT_Pos Pin

                Ser.position(52,3)
            
                Ser.str(string("I/O Pin Polarity"))
            
                repeat tmp from 10 to 23
                
                    ser.position(50,tmp-5)
                    if (Var_Polarity & (|<tmp))
                        ser.str(string("High"))
                    else
                        ser.str(string(" Low"))

                    ser.position(55,tmp-5)
                    
                    case tmp
                        10..15: ' Print X, Y& Z O.T. Current Status
                            Ser.str(string("= "))                            
                            ser.char(43+(2*tmp & 1)) '43="+", 45="-"
                            ser.char("X"+((tmp-10)>>1)&3) ' print X, Y or Z

                        16..21: ' Print X, Y, & Z Step & Direction Levels
                            Ser.str(string("= "))
                            if (tmp & 1)
                                ser.char("-")
                            ser.char("X"+((tmp-16)>>1)&3) ' print X, Y or Z
                            if (tmp & 1)
                                ser.str(string(" Direction"))
                            else                            
                                ser.str(string(" Step"))
                        22:
                            Ser.str(string("= Reserved"))
                        23:
                            Ser.str(string("= Enable Steppers"))

                    UpdateOTStatus(0)  ' Update O.T. Current Status to description 

            @Param38: ' Do nothing for Chain value

            other:      ' Default to numeric display
                ser.position(2,5+(Line*2))
                if line==4 ' Pulse time only           
                    ser.str(fs.FloatToFormat(long[VarPtr+(line*4)],8,2))
                else
                    ser.str(fs.FloatToFormat(long[VarPtr+(line*4)],8,0))

        if (ParamPtr <> @Param37) and (ParamPtr <> @Param38) 
            ser.position(12,5+(Line*2))
            ser.str(ParamPtr)

        ParamPtr+=StrSize(ParamPtr)+1
        line++

    VarPtr:=@Var_Override
    Line:=0
    PrevLine:=-1    ' Force redraw of first field
    Width:=8
    Col:=0          ' Col 0 are numeric values on left, Col 1 are bit values on right
    PrevCol:=0


    WhiteOnRed
    ser.position(18,24)
    ser.str(string("Press <ESC> to return to main menu."))
    GreenOnBlack
     
    '=================== Edit Fields ===================     

    repeat

        ' Draw previous field
        if line <> PrevLine
        
            if PrevLine<>-1

                ' Display new updated value
                GreenOnBlack
                if PrevCol==0
                    case PrevLine
                        0..5: ' Numeric values
                            width:=8
                            ser.position(10-width,5+(PrevLine*2))
                            long[Varptr+(PrevLine*4)]:=fs.StringToFloat(@ShortBuf)
                            if PrevLine==4 ' Pulse time only                                
                                ser.str(fs.FloatToFormat(long[VarPtr+(PrevLine*4)],width,2))
                            else
                                ser.str(fs.FloatToFormat(long[VarPtr+(PrevLine*4)],width,0))

                     
                        6:  ' File extension
                            width:=4
                            ser.position(10-width,5+(PrevLine*2))
                            byte[@ShortBuf+width]:=0
                            repeat tmp from 0 to width-1
                                if byte[@ShortBuf+tmp]==0
                                    byte[@ShortBuf+tmp]:=32
                            UCase(@ShortBuf)
                            bytemove(VarPtr+(PrevLine*4),@ShortBuf,width)
                            bytemove(@ValidExt,VarPtr+(PrevLine*4),width)
                            ser.str(@ValidExt)

                else
                    
                    ser.position(50,Prevline+5)
                    if (Var_Polarity & |< ( Prevline + X_OT_Pos))

                        ser.str(string("High"))                        
                    else
                        ser.str(string(" Low"))

            ' Draw Editing field
            ' Left justify string, zero terminate at width
            ' Get new value from user

            if Col==0   ' Left column
                bytefill(@ShortBuf,32,ShortBufSize)
                case Line
                    0..5: ' prepare numeric field
                        width:=8
                        if line==4 ' Pulse Time Only
                            bytemove(@Block,fs.FloatToFormat(long[VarPtr+(line*4)],Width,2),Width)
                        else
                            bytemove(@Block,fs.FloatToFormat(long[VarPtr+(line*4)],Width,0),Width)
                        
                        repeat result from 0 to Width-1
                            if byte[@Block+result]<>32
                                bytemove(@ShortBuf,@Block+result,width-result)
                                quit

                    6:  ' Prepare file name extension
                        width:=4
                        bytemove(@ShortBuf,@ValidExt,width)

                GreenOnBlack
                FillZone(1,22,22,79)
                DispPot
    
                case Line

                    0: ' Feedrate override
                        ser.str(string("Maximum feedrate override percentage for pot.")) 

                    1:  ' Steps per inch
                        ser.str(string("How many steps per inch of travel.")) 

                    2,3:  ' Rapid Feedrate
                        ser.str(string("Feedrate in inches per minute.")) 

                    4:  ' Pulse Time (this number gets limited to between 10 and 650 clock cycles)
                        ser.str(string("Pulse time for stepper motor drivers (uS)."))

                    5:  ' Baud Rate
                        ser.str(string("Valid Baud Rates Are: 9600, 19200, 38400, 57600, 115200")) 

                    6:  ' CNC File Name Extension
                        ser.str(string("Enter the default CNC filename extension like '.TXT'")) 

                WhiteOnRed

                byte[@ShortBuf+width]:=0
                ser.position(10-width,5+(Line*2))
                ser.str(@ShortBuf)
                 
                ser.position(10-width,5+(Line*2))
                result:=GetString(@ShortBuf,width,1)          ' Get value from terminal, it returns a single byte key value

            else ' Right column of bit levels

                GreenOnBlack

                FillZone(1,22,22,79)

                case Line
                    0..5:
                        ser.str(string("Input level when an overtravel limit switch is activated. (Current state shown)")) 

                    6,8,10:
                        ser.str(string("Output level for step pulse necessary to cause the step driver to move one step.")) 

                    7,9,11:
                        ser.str(string("Output level to move step driver in the negative direction.")) 

                    12:       

                    13:
                        ser.str(string("Output level to enble stepper drives. (Drives currently disabled)."))
                    
                ' Get bit levels, toggle with space bar                 
                OutStatus
                    
                ' Get user input
                repeat
                    tmp:=0                         
                    repeat
                        if tmp <>  ina[Z_OT_Neg..X_OT_Pos]
                            tmp := ina[Z_OT_Neg..X_OT_Pos]
                            UpdateOTStatus(1)  ' Update O.T. Current Status to description                            
                                    
                        result:=GetKey
'                        DispPot
                                                            
                    while result == -1                         
                 
                    case result
                        32:
                            Var_Polarity ^= |< (Line + X_OT_Pos)
                            OutStatus

                            if line==13 ' Enable
                                DisableDrives

                             
                        13,27:
                            quit
                            
                        other:
                            quit
            

        PrevLine:=line

        case result
            13,366,367,9,414,50,54,51:                                             ' Y-
                Line++
         
            365,368,390,420,56,52,67:                                             ' Y+
                Line--
                        
            27:                                             ' Escape
                GreenOnBlack
                quit

            other: ' for any unrecognized keystroke, just ignore
                ser.position(1,1)
                ser.decpad(result,3)
                ser.chars(32,2)                
                PrevLine:=-1
            
                            
        if Col==0
            PrevCol:=0
            if Line > 6 ' Only 8 parameters to work with
                Line:=0
                Col:=1
                PrevLine:=6
                ser.hidecursor
        
            if Line < 0
                Line:=0
                PrevLine:=-1
        else
            PrevCol:=1
            if Line > 13 ' Only 8 parameters to work with
                Line:=13
                PrevLine:=-1
                
            if Line < 0
                Line:=6
                Col:=0
                PrevLine:=0
                ser.showcursor
                UpdateOTStatus(0)
                
'                repeat result from 0 to 5       ' Clear any highlighted Overtravel words.
'                    ser.position(60,result+5)
'                    GreenOnBlack
'                    ser.str(string("Overtravel State"))


PRI UpdateOTStatus(mode)
' If mode = 0 then just say the description adjacent to the titles
' If mode = 1 the show the current detected state
     
    repeat result from 0 to 5
        ser.position(60,result+5)
        if mode==1
            ifnot ((ina[Z_OT_Neg..0] ^ Var_Polarity) & |< (X_OT_Pos+result))
                WhiteOnRed
                ser.str(string("Overtravel Fault"))
            else
                GreenOnBlack
                ser.str(string("No Overtravel   "))
        else
            ser.str(string("Overtravel State"))                
             
PRI OffsetMenu | ParamPtr, VarPtr, PrevLine, DCol, DRow, Tmp, Width
' Edit Tool & Fixture Offsets
    ser.clear
    ser.home

'Param4      byte    "G54 X",0
'Param5      byte    "G54 Y",0
'Param6      byte    "G54 Z",0
'Param7      byte    "G55 X",0
'Param8      byte    "G55 Y",0
'Param9      byte    "G55 Z",0
'Param10     byte    "G56 X",0
'Param11     byte    "G56 Y",0
'Param12     byte    "G56 Z",0
'Param13     byte    "G57 X",0
'Param14     byte    "G57 Y",0
'Param15     byte    "G57 Z",0
'Param16     byte    "G58 X",0
'Param17     byte    "G58 Y",0
'Param18     byte    "G58 Z",0
'Param19     byte    "G59 X",0
'Param20     byte    "G59 Y",0
'Param21     byte    "G59 Z",0
'Param22     byte    "Tool 1 Offset",0
'Param23     byte    "Tool 2 Offset",0
'Param24     byte    "Tool 3 Offset",0
'Param25     byte    "Tool 4 Offset",0
'Param26     byte    "Tool 5 Offset",0
'Param27     byte    "Tool 6 Offset",0
'Param28     byte    "Tool 7 Offset",0
'Param29     byte    "Tool 8 Offset",0


    Ser.position(30,1)
    WhiteOnRed
    ser.str(string("Tool & Workplane Offsets"))

    GreenOnBlack

    ser.position(75,1)
    ser.DecPad(Var_Polarity & %1_1111_1111,5)

    ser.position(22,4)
    ser.str(string("Fixture Offsets"))

    ser.position(52,4)
    ser.str(string("Tool Length Offsets"))

    repeat result from 0 to 2
        ser.position((result*12)+17,6)        
        ser.char("X" + result)

        
    VarPtr:=@Var4
    Line:=0
    repeat 26 
        case line
            0..17:   ' Fixture Offsets            
                ser.position(8,8+((Line/3)*2))
                ser.str(string("G5"))
                ser.char("4"+(line/3))
                DRow:=8+((Line/3)*2)
                DCol:=((line//3)*12)+14


            18..25:   ' Tool Length Offsets
                tmp:=Line-18 ' Offset Number            
                ser.position(52,6+(tmp*2))
                ser.str(string("Tool "))
                ser.char("1" + tmp)
                DRow:=6+(tmp*2)
                DCol:=60
                
        ser.position(DCol,DRow)
        ser.str(fs.FloatToFormat(long[VarPtr+(line*4)],8,4))
        line++

    WhiteOnRed
    ser.position(18,24)
    ser.str(string("Press <ESC> to return to main menu."))
    GreenOnBlack

                       
    Line:=0
    PrevLine:=-1    ' Force redraw of first field
    Width:=8
    ParamPtr:=@Param4
    
    DCol:=((line//3)*12)+14
    DRow:=((Line/3)*2)+8
    ser.ShowCursor           
    
    '=================== Edit Fields ===================     
    repeat

        if PrevLine<>-1
            ' Display new updated value
            case PrevLine
                0..17:   ' Fixture Offsets
                    DCol:=((PrevLine//3)*12)+14
                    DRow:=((PrevLine/3)*2)+8            
             
                18..25:   ' Tool Length Offsets
                    DCol:=60
                    DRow:=((PrevLine-18)*2)+6          

            GreenOnBlack
            ser.position(DCol,DRow)                
            long[Varptr+(PrevLine*4)]:=fs.StringToFloat(@ShortBuf)
            ser.str(fs.FloatToFormat(long[VarPtr+(PrevLine*4)],8,4))


        ' Draw Editing field
        ' Left justify string, zero terminate at width
        ' Get new value from user
         
        bytefill(@ShortBuf,32,ShortBufSize)
        width:=8
        bytemove(@Block,fs.FloatToFormat(long[VarPtr+(line*4)],Width,4),Width)
                        
        repeat result from 0 to Width-1
            if byte[@Block+result]<>32
                bytemove(@ShortBuf,@Block+result,width-result)
                quit

        GreenOnBlack
        FillZone(1,22,22,79)

        case Line
         
            0..17:  
                DCol:=((line//3)*12)+14
                DRow:=((Line/3)*2)+8            
                ser.str(string("Enter the X, Y & Z values for this workplane offset.")) 
         
            18..25:  
                DCol:=60
                DRow:=((Line-18)*2)+6          
                ser.str(string("Enter the Z offset for the tool (Negative Cuts Deeper).")) 

        WhiteOnRed
         
        byte[@ShortBuf+width]:=0
        ser.position(DCol,DRow)                
        ser.str(@ShortBuf)
        ser.position(DCol,DRow)                
         
        result:=GetString(@ShortBuf,width,0)        ' Get value from terminal, it returns a single byte key value

        PrevLine:=line 

        case result
            13,367,9:                                       ' CR, Tab, Right Arrow
                Line++
         
            368,390:                                        ' Shift-Tab, Left Arrow
                Line--

            365:                                            ' Up Arrow
                if ((line>2) and (line<18))
                    Line-=3
                else
                    Line--                    
            366:                                            ' Down Arrow
                if line<15
                    Line+=3
                else
                    line++
                        
            27:                                             ' Escape
                GreenOnBlack
                quit

        if Line < 0
            Line:=0
            PrevLine:=0

        if Line > 25 
             Line:=25
             PrevLine:=25

PRI DispPot

    ser.SaveCurPos
'    ser.hidecursor     
    GreenOnBlack

    ' Read A/D converter
    lHex:=read(ADAddress & 255, 0, 0,16) ' NOTE: Must set R/W bit to 1 since we don't use an address register (*)
    qValue:=(lHex >> 15) & 1' Pad upper 19-bits with sign bit
    qValue:=qValue * %1111_1111_1111_1111_1111_0000_0000_0000
    qValue:=qValue + (lHex & %1111_1111_1111)
    qValue:= qValue+1024
    qValue #>= 0
    s_PotRaw:=qValue         
    s_PotScale:=fm.FMul(fm.FDiv(fm.FFloat(s_PotRaw),204800.0),Var_Override) ' A value between 0 and 2.0 for 200% override
     
    ser.Position(30,5)
    ser.str(fs.FloatToFormat(fm.FMul(s_PotScale,100.0),5,0))
    ser.char("%")

    ser.RestoreCurPos
'    ser.ShowCursor
            
PRI OutStatus
                
                WhiteOnRed
                ser.position(50,line+5)                
                if (Var_Polarity & ( |< (Line + X_OT_Pos)))
                
                    ser.str(string("High"))
                     
                    GreenOnBlack
                    FillZone(1,23,23,79)
                     
                    if ((line-6+StepXPin=>StepXPin) and (line-6+StepXPin=<StepXPin+5))  
                        outa[line-6+StepXPin]~
                        ser.str(string("Output Now Set To ",27,"[41m",27,"[37m","HIGH"))
                else
                    ser.str(string(" Low"))
                     
                    GreenOnBlack
                    FillZone(1,23,23,79)
                     
                    if ((line-6+StepXPin=>StepXPin) and (line-6+StepXPin=<StepXPin+5))  
                        outa[line-6+StepXPin]~~
                        ser.str(string("Output Now Set To ",27,"[41m",27,"[37m","LOW"))

PRI RebootMe
' Create file to signal main routine to start without splash screen

    fat0.fatEngineStart(DOPin, CLKPin, DIPin, CSPin, -1,-1,-1,-1,-1)
    
    \fat0.mountPartition(0)
    \fat0.deleteEntry(@RebootFile)
    \fat0.newFile(@RebootFile)
    \fat0.CloseFile
    \fat0.unmountPartition

    ser.stop
    reboot

                  
PRI ReadConfig(DisplayProgress) | ParamPtr, VarPtr, tmp, FilePtr, SaveChr

    if DisplayProgress
        PosString(@ConfigRead)
        
    ' Open configuration file
    fat0.fatEngineStart(DOPin, CLKPin, DIPin, CSPin, -1,-1,-1,-1,-1)
    \fat0.mountPartition(0)
    \fat0.openFile(@ConfigFile, "R")

    ' Read file entries formatted "Axis Steps Per Inch=4000<CR>"
    repeat

        FilePtr:=fat0.filetell
        
        \fat0.readstring(@Block,BufferSize-1)
        if strsize(@Block)==0
            quit
        
        ParamPtr:=@Param0
        VarPtr:=@Var1-4

            repeat result from 0 to strsize(@Block) ' trim out any leading non-printable characters
                if byte[@Block+result]<32
                    bytemove(@Block,@Block+1,strsize(@Block)-1)
                else
                    quit

            UCase(@Block)

        repeat 

            ' Find Param that matches string from file
            bytefill(@ShortBuf,0,ShortBufSize)
            bytemove(@ShortBuf,ParamPtr,strsize(ParamPtr)+1)
            UCase(@ShortBuf)

            SaveChr:=byte[@Block+strsize(ParamPtr)]
            byte[@Block+strsize(ParamPtr)]:=0

            result:=strcomp(@Block,@ShortBuf)
            byte[@Block+strsize(ParamPtr)]:=SaveChr                
            
            if result
            
                if DisplayProgress
                    ser.char(".")
            
                bytefill(@ShortBuf,0,ShortBufSize)
                bytemove(@ShortBuf,@Block+strsize(ParamPtr)+1,strsize(@block)-strsize(ParamPtr))

                case ParamPtr
                    @Param0:    ' Treat filename differently as a a string
                        bytemove(VarPtr-12,@ShortBuf,16)
                        NullFill(VarPtr-12,0,15)

                    @Param36:   ' Treat CNC file name extension as a a string
                        bytemove(VarPtr,@ShortBuf,4)
                        NullFill(VarPtr,0,3)                        

                    @Param37:   ' Read Hex value & convert to integer

                        '' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                        '' // Converts a hexadecimal string into an integer number. Expects a string with only "+-0123456789ABCDEFabdcef" characters.
                        '' // Characters - A pointer to the hexadecimal string to convert. The number returned will be 2's complement compatible.
                        '' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                           
                        tmp:=@ShortBuf
                        result:=0 
                        repeat (strsize(tmp) <# 8)
                            ifnot(checkDigit(tmp, "0", "9"))
                                ifnot(checkDigit(tmp, "A", "F") or checkDigit(tmp, "a", "f"))
                                    quit
                         
                                result += $90_00_00_00
                          result := ((result <- 4) + (byte[tmp++] & $F))

                        long[VarPtr]:=result

                    @Param38:   ' Chain value (single byte)
                        bytemove(VarPtr,@ShortBuf,4)
                        var_chain &= 255 ' Strip off CR/LF
    
                    other:
                        long[Varptr]:=fs.StringToFloat(@ShortBuf)
                quit
               
            else
            
                VarPtr += 4
                ParamPtr += (strsize(ParamPtr)+1)                 ' Terminating '0'+ 4 bytes for a long
                        
        while (strsize(ParamPtr)>0)

    bytemove(@ValidExt,@Var_CNCExt,4)
    byte[@ValidExt+4]:=0
    UCase(@ValidExt)   ' Change file extension to upper case

    \fat0.CloseFile
    DisableDrives    
    \fat0.unmountPartition

PRI WriteConfig(DisplayProgress) | ParamPtr, VarPtr, tmp
    if DisplayProgress
        ser.clear
        ser.home
        PosString(@ConfigWrite)

    ser.position(1,2)     
    GreenOnBlack
    
    ' Open configuration file
    
    fat0.fatEngineStart(DOPin, CLKPin, DIPin, CSPin, -1,-1,-1,-1,-1)

    \fat0.mountPartition(0)    
    \fat0.deleteEntry(@ConfigFile)    
    \fat0.newFile(@ConfigFile)
    \fat0.OpenFile(@ConfigFile, "W")

    ' Write file entries formatted "Axis Steps Per Inch=4000<CR>"

    VarPtr:=@Var0
    ParamPtr:=@Param0
    
    repeat
        ser.char(".")
        \fat0.WriteString(ParamPtr)
        \fat0.WriteByte("=")

        case ParamPtr
            @Param0: ' Treat filename as a a string
                \fat0.WriteString(VarPtr)
                VarPtr+=12
                 
            @Param36: ' Treat last CNC file name extension as a a string
                \fat0.WriteString(@ValidExt)

            @Param37: ' Save polarity mask as HEX
                ' Add 1 to the low 9-bits of Var_Polarity = save counter
                long[VarPtr] := (((long[VarPtr]+1) & %1_1111_1111) | (long[VarPtr] & $FFFF_FE00))
                
                repeat 8
                    \fat0.WriteByte(lookupz((long[VarPtr] <-= 4) & $F : "0".."9", "A".."F"))

            Other:
                \fat0.WriteString(fs.FloatToString(long[VarPtr]))

        \fat0.WriteString(String(13,10))
        VarPtr += 4 ' Point to next long
        ParamPtr += (strsize(ParamPtr)+1)
        
    while (strsize(ParamPtr)>0)

    \fat0.WriteByte(26)   ' Terminate file with Ctrl-Z    
    \fat0.CloseFile
    DisableDrives
    \fat0.unmountPartition

    if DisplayProgress
        ser.str(string(" - Done.",13,10))

PRI CheckDigit(characters, low, high) ' 5 Stack Longs
' return true if byte[character] is between low and high
  result := byte[characters]
  return ((low =< result) and (result =< high))

PRI UCase(StringAdr)
' Convert string to upper case
    repeat result from 0 to strsize(StringAdr)
        if (byte[StringAdr + result] > "@" and byte[StringAdr + result] < "{") 
            byte[StringAdr + result]:=byte[StringAdr + result] & %1101_1111                 
     

PRI EnableDrives

    if (Var_Polarity & (|< EnablePin))
        outa[EnablePin]~                                             ' Enable stepper drive
    else
        outa[EnablePin]~~                                            ' Enable stepper drive

PRI DisableDrives
    dira[EnablePin]~~

    if (Var_Polarity & (|< EnablePin))
        outa[EnablePin]~~                                            ' Disable stepper drive
    else
        outa[EnablePin]~                                             ' Disable stepper drive



PRI FillZone(Left,Top,Bottom,Width)
'Fill an area with spaces
    repeat result from Top to Bottom
        ser.position(Left,result)
        ser.chars(32,Width)
        ser.position(Left,result)
        
PRI PosString(Address)
' Locate cursor based on first 2 bytes of string @ Address
' Length of text is byte[Address+2) wide
    ser.position(byte[Address],byte[Address+1])
    ser.str(Address+3)       
    ser.chars(32,byte[address+2]-strsize(Address+3))

PRI NullFill(VarPtr,st,end)
' Replace characters lower than 32 with 0                        
    repeat result from st to end
        if byte[VarPtr+result]<32
            byte[VarPtr+result]:=0


PRI I2CInit

    dira[I2CBase..I2CBase+1]~

    ' setup i2cobject
    i2cSDA := (I2CBase+1)
    i2cSCL := I2CBase
    dira[i2cSDA] ~~          
    dira[i2cSCL] ~~
     
    outa[i2cSCL] ~~ ' Force stop condition         
    outa[i2cSDA] ~~ ' Set initial condition to both data and clock HIGH          

    if devicePresent(ADAddress)
    
        ' setup the config PGA x2, Continuous reading
        write(ADAddress & 127,0,ADS1000_ContConv | ADS1000_PGA2, 0)


PRI devicePresent(deviceAddress) : ackbit
  ' send the deviceAddress and listen for the ACK
  ' Return true if device is present, false if not present
  
    ackbit := false           
    i2cStart
    ackbit := i2cWrite((deviceAddress << 1) | 0,8)
    i2cStop
    if ackbit == 0 'Ack
        ackbit := true
    else
        ackbit := false
    return ackbit

  
PRI read(deviceAddress, deviceRegister, addressbits,databits) : i2cData | ackbit

  ' do a standard i2c address, then read
  ' read a device's register
    ackbit := 0 'Ack
    
    i2cStart     
    ackbit := (ackbit << 1) | i2cWrite((deviceAddress << 1) | 0,8)      ' Should be 0???
    ackbit := (ackbit << 1) | i2cWrite(deviceRegister << 24, 0)
    i2cStart
    ackbit := (ackbit << 1) | i2cWrite((deviceAddress << 1 ) | 1, 8)     
    i2cData := i2cRead(0) ' ACK
    i2cData := (i2cData <<8) | i2cRead(1)      
    i2cStop

    
PRI write(deviceAddress, deviceRegister, i2cDataValue, addressbits) : ackbit
  ' do a standard i2c address, then write
  ' return the ACK/NAK bit from the device address
    ackbit := 0 ' ACK=0
    i2cstart
    ackbit := (ackbit << 1) | i2cWrite(deviceAddress << 1 ,8)' r/w = 0 for write
    ackbit := (ackbit << 1) | i2cWrite(i2cDataValue,8)
    i2cStop
    return ackbit

  
' ******************************************************************************
' *   These are the low level routines                                         *
' ******************************************************************************  
 
PRI i2cStop
' i2c stop sequence - the SDA goes LOW to HIGH while SCL is HIGH
' must force both data and clock low to create stop condition

    outa[i2cSDA] ~    ' Set LOW
    dira[i2cSDA] ~~   ' Set to output
    outa[i2cSCL] ~~   ' Set HIGH
    dira[i2cSCL] ~~   ' Set to output
    outa[i2cSDA] ~~   ' Set HIGH
    dira[i2cSDA] ~~   ' Set to output

    
PRI i2cStart
    outa[i2cSCL] := 1       
    dira[i2cSCL] ~~
    dira[i2cSDA] ~~  
    outa[i2cSDA] := 1
    outa[i2cSDA] := 0     
    outa[i2cSCL] := 0       
  
PRI i2cWrite(i2cData, i2cBits) : ackbit
  ' Write i2c data.  Data byte is output MSB first, SDA data line is valid
  ' only while the SCL line is HIGH
  ' Return 0 if OK, return 1 if error
  
    ackbit := 1 'NAK=1 
    outa[i2cSDA]~
    dira[i2cSDA] ~~
    outa[i2cSCL]~
    dira[i2cSCL] ~~

    ' init the clock line                          

    ' send the data
    i2cData <<= (32 - i2cbits) ' Shift left
        
    repeat 8
        outa[i2cSDA] := (i2cData <-= 1) & 1         ' Rotate Left
        outa[i2cSCL] := 1
        outa[i2cSCL] := 0
       
    ' setup for ACK - pin to input immediately after falling edge of last bit            
    dira[i2cSDA] ~  ' Immediately Set data as input
    
    outa[i2cSCL] := 1
    ackbit := ina[i2cSDA]
    outa[i2cSCL] := 0      
    outa[i2cSDA] := 0    
    dira[i2cSDA] ~~   
    return ackbit' return the ackbit
            

PRI i2cRead(ackbit): i2cData
  ' Read in i2c data, Data byte is output MSB first, SDA data line is valid
  ' only while the SCL line is HIGH
  

    ' set the SCL to output and the SDA to input
    outa[i2cSCL] := 0
    dira[i2cSCL] ~~
    dira[i2cSDA] ~
     
    i2cData := 0
    repeat 8
        outa[i2cSCL] := 1
        i2cData := (i2cData << 1) | ina[i2cSDA]
        outa[i2cSCL] := 0
      
    ' send the ACK or NAK
    outa[i2cSDA] := ackbit
    dira[i2cSDA] ~~
    outa[i2cSCL] := 1
    outa[i2cSCL] := 0
         
    
    return i2cData ' return the data

    
PRI GreenOnBlack
    ser.str(string(27,"[32m",27,"[40m"))        ' Green Text / Black Background


PRI WhiteOnRed
    ser.str(string(27,"[41m",27,"[37m"))        ' White Letters / Red Background

PRI RedOnWhite
    ser.str(string(27,"[31m",27,"[47m"))        ' Red text /  White Background                

PRI OpMessage(MsgAddress)

    ser.position(8,2)
    GreenOnBlack
    ser.str(@MsgErase)
    ser.position(8,2)
    ser.str(MsgAddress)
    ser.HideCursor                

PRI GetKey : Input | tmp, timer
' Get key sequence from keyboard
' Convert to single numeric value
' Return -1 if empty or key value

    bytefill(@KeyBuffer,0,5)
    input:=ser.RXCheck
    if input > 0
        tmp:=0
        timer:=cnt+clkfreq/500
        repeat while timer>cnt
            if input>0
                byte[@KeyBuffer][tmp++]:=input
                input:=ser.RXCheck

                
        case tmp
           1:   input:=byte[@KeyBuffer]                     ' Single byte key sequence

           3:   input:=300+byte[@KeyBuffer][2]              ' add 300 to 3rd byte of 3-byte sequences

           4:   input:=400+byte[@KeyBuffer][2]              ' add 400 to 3rd byte of 4-byte sequences




PRI GetString(MemLoc,Count,Update) | tmp
' Edit string at MemLoc x Count bytes long
' Return a zero terminated string
' If Update = non-zero, the position displays and feed rate override fields are updated
' return the last keysrtoke result
' Position cursor prior to calling this routine

  
    tmp:=0 ' set tmp equal to the number of used characters
    repeat count
        if byte[MemLoc+tmp]<>32
            ser.char(byte[MemLoc+tmp])
            tmp++
        else
            quit
        
    ser.ShowCursor
    
    repeat
        repeat
            result:=GetKey
            if Update
                if line==0            
'                    ser.SaveCurPos
                    ser.HideCursor
'                    DispPos                 ' Display feedrate override value while waiting
                    DispPot            
'                ser.RestoreCurPos
                    ser.ShowCursor
            
        while result == -1                               

        case result
            "#".."~":
                if tmp < Count ' How many characters to accept                            
                    ser.char(result)
                    byte[MemLoc][tmp++]:=result
            
            8:    ' Backspace
                if tmp
                    byte[MemLoc][--tmp]:=0
                    ser.str(@BackSpace)
            13,27:
                byte[MemLoc][tmp+1]:=0
                ser.HideCursor                
                quit
                
            other:  ' return movement keystrokes
                quit
                

DAT
block       byte    0[BufferSize+1]     ' Parsing String Storage
ShortBuf    byte    0[ShortBufSize]     ' short buffer for string comparison
KeyBuffer   byte    0[8]                ' keyboard input buffer
ValidExt    byte    0[5]                ' valid CNC filename extension, zero terminated
BackSpace   byte    8,32,8,0

MsgErase    byte    32[16],0            '"                ",0

ConfigRead  byte    1,1,22,  "Reading Config File ",0
ConfigWrite byte    1,15,32,  "Saving The Config File",0


ConfigFile  byte    "CONFIG.DAT",0      ' Configuration data file
RebootFile  byte    "REBOOT.ING",0      ' 


' Parameter names Must be 30 bytes or shorter
Param0      byte    "Last CNC File",0
Param1      byte    "reserved 1",0
Param2      byte    "reserved 2",0   
Param3      byte    "reserved 3",0   
Param4      byte    "G54 X",0
Param5      byte    "G54 Y",0
Param6      byte    "G54 Z",0
Param7      byte    "G55 X",0
Param8      byte    "G55 Y",0
Param9      byte    "G55 Z",0
Param10     byte    "G56 X",0
Param11     byte    "G56 Y",0
Param12     byte    "G56 Z",0
Param13     byte    "G57 X",0
Param14     byte    "G57 Y",0
Param15     byte    "G57 Z",0
Param16     byte    "G58 X",0
Param17     byte    "G58 Y",0
Param18     byte    "G58 Z",0
Param19     byte    "G59 X",0
Param20     byte    "G59 Y",0
Param21     byte    "G59 Z",0
Param22     byte    "Tool 1 Offset",0
Param23     byte    "Tool 2 Offset",0
Param24     byte    "Tool 3 Offset",0
Param25     byte    "Tool 4 Offset",0
Param26     byte    "Tool 5 Offset",0
Param27     byte    "Tool 6 Offset",0
Param28     byte    "Tool 7 Offset",0
Param29     byte    "Tool 8 Offset",0

Param30     byte    "Feed Rate Override",0                  ' Feed Rate OverRide Value "200" = 200%
Param31     byte    "Axis Steps Per Inch",0                 ' Steps Per Inch on All Axis 4000 = .00025 Resolution
Param32     byte    "Rapid Feed Rate",0                     ' G0 feedrate 50 = 50 IPM
Param33     byte    "Jog Feed Rate",0                       ' Jogging feedrate 50 = 50 IPM
Param34     byte    "Step Driver Pulse Time",0              ' .5 = .5uS
Param35     byte    "Serial Terminal Baud Rate",0           ' 115200 baud
Param36     byte    "Default CNC File Extension",0          ' ".TXT"
Param37     byte    "Step Driver Polarity",0                ' bitmask
Param38     byte    "Chain",0                               ' Function to perform when chaining to overlay program
                                                            ' "0" = Edit Settings
                                                            ' "1" = Edit Offsets
                                                             
            byte    0                   ' end of param table

' These variables must be long aligned
Var0        long    0[4]    ' Last CNC File = 12 bytes
Var1        long    0       ' reserved 1 = 1 Long each variable
Var2        long    0       ' reserved 2              
Var3        long    0       ' reserved 3
Var4        long    0       ' G54 X
Var5        long    0       ' G54 Y
Var6        long    0       ' G54 Z
Var7        long    0       ' G55 X
Var8        long    0       ' G55 Y
Var9        long    0       ' G55 Z
Var10       long    0       ' G56 X
Var11       long    0       ' G56 Y
Var12       long    0       ' G56 Z
Var13       long    0       ' G57 X
Var14       long    0       ' G57 Y
Var15       long    0       ' G57 Z
Var16       long    0       ' G58 X
Var17       long    0       ' G58 Y
Var18       long    0       ' G58 Z
Var19       long    0       ' G59 X
Var20       long    0       ' G59 Y
Var21       long    0       ' G59 Z
Var22       long    0       ' Tool 1 Offset
Var23       long    0       ' Tool 2 Offset
Var24       long    0       ' Tool 3 Offset
Var25       long    0       ' Tool 4 Offset
Var26       long    0       ' Tool 5 Offset
Var27       long    0       ' Tool 6 Offset
Var28       long    0       ' Tool 7 Offset
Var29       long    0       ' Tool 8 Offset



Var_Override long   0       ' Feed Rate Override 
Var_SPI     long    0       ' Axis Steps Per Inch 
Var_Rapid   long    0       ' Rapid Feed Rate
Var_Jog     long    0       ' Jog Feed Rate
Var_Pulse   long    0       ' Step Driver Pulse Time .5uS for the Superior SD200)
Var_Baud    long    0       ' Serial Terminal Baud Rate (need to convert to an integer)    
Var_CNCExt  long    0       ' Default CNC File Extension "TXT"
Var_Polarity long   0       ' Step Driver Polarity bitmask to apply to INA & OUTA to invert step & direction pins as needed
Var_Chain   long    0       ' Function to perform when chaining to overlay program
                            ' "0" = Edit Settings
                            ' "1" = Edit Offsets
                             

 