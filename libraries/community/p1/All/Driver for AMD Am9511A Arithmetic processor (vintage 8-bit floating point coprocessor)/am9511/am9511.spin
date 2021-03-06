{ am9511.spin - Object to interface with AMD Am9511 8-bit FPU (Intel i8231)  }
{     (c) zpekic@hotmail.com 2018 - 2019 - https://github.com/zpekic         }

CON
'Pin name       Propeller       Am9511                  direction/note
D0  =           0 '             8                       read/write  (keep these contiguous, or change code)
D1  =           1 '             9                       read/write
D2  =           2 '             10                      read/write
D3  =           3 '             11                      read/write
D4  =           4 '             12                      read/write
D5  =           5 '             13                      read/write
D6  =           6 '             14                      read/write
D7  =           7 '             15                      read/write

CnD     =       8 '             21                      write (keep these contiguous, or change code)
nRD     =       9 '             20                      write
nWR     =       10 '            19                      write
nCS     =       11 '            18                      write

nPAUSE  =       12 '            17                      read
SVREQ   =       13 '            5                       read
nSVACK  =       14 '            4                       write
RESET   =       15 '            22                      write
CLK     =       16 '            23                      write

'nEND   =       N/C             24                      read
'VSS    =       ground          1
'VCC    =       +5V (+/-5%)     2                       https://www.pololu.com/product/2115 or similar if boosted from 3.3V
'VDD    =       +12V (+/-5%)    16                      https://www.pololu.com/product/2117 or similar if boosted from 3.3V
'N/C    =       N/C             6                       do not connect
'N/C    =       N/C             7                       do not connect                      

' adjust based on the chip, these are for 4MHz version
minFreq = 200_000 'won't work reliably under 200kHz
maxFreq = 4_200_000 'allow up to 5% overclocking

CON
' status register bits
ST_BUSY         = %10000000
ST_SIGN         = %01000000
ST_ZERO         = %00100000
ST_ERROR_ANY    = %00011110
ST_ERROR_DIV0   = %00010000
ST_ERROR_ARGNEG = %00001000
ST_ERROR_ARGBIG = %00011000
ST_ERROR_UFLOW  = %00000100 '%000XX100
ST_ERROR_OFLOW  = %00000010 '%000XX010
ST_CARRY        = %00000001

CON
' Instruction set, 32-bit floating point (A = TOS, B = NOS, C, D)
ACOS  = $06 'ACOS(A), U, U, U
ASIN  = $05 'ASIN(A), U, U, U
ATAN  = $07 'ATAN(A), B, U, U
CHSF  = $15 '-A, B, C, D
COS   = $03 'COS(A), B, U, U
EXP   = $0A 'EXP(A), B, U, U
FADD  = $10 'A + B, C, D, U
FDIV  = $13 'B / A, C, D, U
FLTD  = $1C 'FLOAT(A), B, C, U
FLTS  = $1D 'FLOAT(AU), B, C, U
FMUL  = $12 'A * B, C, D, U
FSUB  = $11 'B - A, C, D, U
LOG   = $08 'LOG(A), B, U, U
LN    = $09 'LN(A), B, U, U
POPF  = $18 'B, C, D, A
PTOF  = $17 'A, A, B, C
PUPI  = $1A '3.1415927, A, B, C
PWR   = $0B 'B ^ A, C, U, U
SIN   = $02 'SIN(A), B, U, U  
SQRT  = $01 'SQRT(A), B, C, U
TAN   = $04 'TAN(A), B, U, U
XCHF  = $19 'B, A, C, D

' Instruction set, 32-bit signed integers (A = TOS, B = NOS, C, D)
CHSD  = $34 '-A, B, C, D
DADD  = $2C 'A + B, C, D, A
DDIV  = $2F 'B / A, C, D, U
DMUL  = $2E 'LOWER32(A * B), C, D, U
DMUU  = $36 'UPPER32(A * B), C, D, U
DSUB  = $2D 'B - A, C, D, A
FIXD  = $1E 'INT32(A), B, C, U
POPD  = $38 'B, C, D, A
PTOD  = $37 'A, A, B, C
XCHD  = $39 'B, A, C, D

' Instruction set, 16-bit signed integers (AU = TOS, AL = NOS, BU, BL, CU, CL, DU, DL)
CHSS  = $74 '-AU, AL, BU, BL, CU, CL, DU, DL, AU
FIXS  = $1F 'INT16(A), BU, BL, CU, CL, U, U, U
POPS  = $78 'AL, BU, BL, CU, CL, DU, DL, AU
PTOS  = $77 'AU, AU, BU, BL, CU, CL, DU
SADD  = $6C 'AL + AU, BU, BL, CU, CL, DU, DL, AU
SDIV  = $6F 'AL / AU, BU, BL, CU, CL, DU, DL, U
SMUL  = $6E 'LOWER16(AL * AU), BU, BL, CU, CL, DU, DL, U
SMUU  = $76 'UPPER16(AL * AU), BU, BL, CU, CL, DU, DL, U
SSUB  = $6D 'AL - AU, BU, BL, CU, CL, DU, DL, AU
XCHS  = $79 'AL, AU, BU, BL, CU, CL, DU, DL
NOOP  = $00 'A, B, C, D (Note: slighly changed name to avoid collision with reserved word)

' "Pseudo" instructions to push data to FPU stack
PUSHD1 = $40 
PUSHD2 = $41
PUSHD3 = $42
PUSHD4 = $43
PUSHZERO = $44
PUSHONE  = $45
PUSHMINUSONE = $46
' issue reset signal to FPU
INITIALIZE   = $47

' "Pseudo" instructions to pop data from FPU stack to 4 values
POPD1 = $48
POPD2 = $49
POPD3 = $4A
POPD4 = $4B

' "Pseudo" instructions to pop data from FPU stack and store to memory
POPI1 = $58
POPI2 = $59
POPI3 = $5A
POPI4 = $5B

' "Pseudo" instructions to copy status from FPU to 4 values
POPS1 = $4C 
POPS2 = $4D
POPS3 = $4E
POPS4 = $4F

CON
AM9511_PI   = $02C90FDA 'Pi value is slighly different and also in encoded differently as Am9511 does not follow standard IEEE754 standard
AM9511_ONE  = $01800000
AM9511_ZERO = $00000000
AM9511_MONE = $81800000
CMD_ERROR   = $FFFFFFFF
CMD_FREE    = $00000000 'same as 4 NOP operations

VAR
  long stack[64]
  byte cog
  long pdCmdAndParams

'--- for trace / debug only ---  
  byte traceLock
  byte pstCog
  byte trace
'------------------------------

OBJ
  pst      : "Parallax Serial Terminal"


PUB Start(desiredFreq, pdShared) : started |setFreq, dummy, init_lock
  trace := false
' limit clock frequency to physical boundary of the chip
  setFreq := desiredFreq
  if (setFreq > maxFreq)
    setFreq := maxFreq
  else
    if (setFreq < minFreq)
      setFreq := minFreq
  cog := cognew(runFPU(setFreq, pdShared), @stack) + 1
  if (cog)
    waitMs(10) 'wait 10ms
    repeat while long[pdShared]
    started := cog
  else
    started := 0

PUB Stop
  if cog
    cogstop(cog~ - 1)

PUB TraceOn
  trace := true

PUB TraceOff
  trace := false

PUB GetStatusMessage(pMessage, st) |pConcat, length
  if  (st & ST_BUSY)
    bytemove(pMessage, @stBusy, strsize(@stBusy))
  else
    if (st & ST_ERROR_ANY)
      if (st & ST_ERROR_ANY == ST_ERROR_DIV0)
        bytemove(pMessage, @stErrorDivByZero, strsize(@stErrorDivByZero))
        return 
      if (st & ST_ERROR_ANY == ST_ERROR_ARGNEG)
        bytemove(pMessage, @stErrorNegRoot, strsize(@stErrorNegRoot))
        return 
      if (st & ST_ERROR_ANY == ST_ERROR_ARGBIG)
        bytemove(pMessage, @stErrorArgTooLarge, strsize(@stErrorArgTooLarge))
        return 
      if (st & ST_ERROR_ANY == ST_ERROR_UFLOW)
        bytemove(pMessage, @stErrorUnderflow, strsize(@stErrorUnderflow))
        return 
      if (st & ST_ERROR_ANY == ST_ERROR_OFLOW)
        bytemove(pMessage, @stErrorOverflow, strsize(@stErrorOverflow))
        return 
    else
      pConcat := pMessage
      length :=  strsize(@stOk)
      bytemove(pMessage, @stOk, length + 1)
      if (st & ST_SIGN)
        pConcat += length
        length := strsize(@stNegative)
        bytemove(pConcat, @stNegative, length + 1)
      if (st & ST_ZERO)
        pConcat += length
        length := strsize(@stZero)
        bytemove(pConcat, @stZero, length + 1)
      if (st & ST_CARRY)
        pConcat += length
        length := strsize(@stCarry)
        bytemove(pConcat, @stCarry, length + 1)
      
'------------------------------------------------------------------------------------
'  Start new evaluation when the previous one finishes and return its status. Block otherwise
'------------------------------------------------------------------------------------
PUB StartEval(c0, c1, c2, c3, v1, v2, v3, v4) :previousError
  repeat 
    case long[pdCmdAndParams]
      CMD_ERROR:
        'traceShared(String("StartEval ERROR"), 0)
        longmove(pdCmdAndParams + 4, @v1, 4)
        'long[pdCmdAndParams][1] := v1
        'long[pdCmdAndParams][2] := v2
        'long[pdCmdAndParams][3] := v3
        'long[pdCmdAndParams][4] := v4
        long[pdCmdAndParams][5] := 0 'clear status
        long[pdCmdAndParams] := (c0 << 24) | (c1 << 16) | (c2 << 8) | c3
        return long[pdCmdAndParams][5]

      CMD_FREE:
        'traceShared(String("StartEval FREE"), 0)
        longmove(pdCmdAndParams + 4, @v1, 4)
        'long[pdCmdAndParams][1] := v1
        'long[pdCmdAndParams][2] := v2
        'long[pdCmdAndParams][3] := v3
        'long[pdCmdAndParams][4] := v4
        long[pdCmdAndParams][5] := 0 'clear status
        long[pdCmdAndParams] := (c0 << 24) | (c1 << 16) | (c2 << 8) | c3
        return long[pdCmdAndParams][5]

      other:         'dead loop until FPU process finished successfully or with error
        'traceShared(String("StartEval LOOP"), 0)
        'waitMs(1)

'------------------------------------------------------------------------------------
'  Wait for evaluation to finish, and return status long when it does, block otherwise
'------------------------------------------------------------------------------------
PUB AwaitEvalStatus
  repeat 
    case long[pdCmdAndParams]
      CMD_ERROR:
        traceShared(String("AwaitEval ERROR"), 0)
        long[pdCmdAndParams] := CMD_FREE
        return long[pdCmdAndParams][5]
      CMD_FREE:
        traceShared(String("AwaitEval FREE"), 0)
        return long[pdCmdAndParams][5]
      other:    'dead loop until FPU process finished successfully or with error
        traceShared(String("AwaitEval LOOP"), 0)
        'waitMs(1)

'------------------------------------------------------------------------------------
'  Return true if any operation result in the status long indicated an error
'------------------------------------------------------------------------------------
PUB GetFailedOperationIndex(status, errorMask) |i
  repeat i from 3 to 0
    if IsOperationError(status.byte[i], errorMask)
      return i
  return -1

PUB IsOperationError(status, errorMask)
  return (status & errorMask) <> 0
  
PUB ToIEEE(am9511Float, pbStatus) : ieeeFloat | sor, sand, x, m
    byte[pbStatus] := %00000000 'default to non-zero positive status
    if (am9511Float)
      if (am9511Float & $80_00_00_00)
        byte[pbStatus] := ST_SIGN 'fake negative status
        sor  := $80_00_00_00
        sand := $FF_FF_FF_FF
      else
        sor  := $00_00_00_00
        sand := $7F_FF_FF_FF
      m := am9511Float & $00_7F_FF_FF
      x := (am9511Float & $7F_00_00_00) ~> 24
      if (x & $00_00_00_40)
        x |= $FF_FF_FF_80
      x += $00_00_00_7E 'bias is 127
      ieeeFloat := (sor | (x << 23) | m) & sand
      'trace2(String("am9511="), am9511Float, String(" ieee="), ieeeFloat)
    else
      ieeeFloat := 0
      'trace2(String("am9511="), am9511Float, String(" ieee="), ieeeFloat)
      byte[pbStatus] := ST_ZERO 'fake zero positive status

PUB From9511(am9511Float, pbStatus)
  return ToIEEE(am9511Float, pbStatus)
    
PUB FromIEEE(ieeeFloat, pbStatus) : am9511Float | sor, sand, x, m
    if (ieeeFloat)
      if (ieeeFloat & $80_00_00_00)
        byte[pbStatus] := ST_SIGN 'fake negative status
        sor  := $80_00_00_00
        sand := $FF_FF_FF_FF
      else
        sor  := $00_00_00_00
        sand := $7F_FF_FF_FF
      m := ieeeFloat & $00_7F_FF_FF
      m |= $00_80_00_00
      x := (ieeeFloat & $7F_80_00_00) >> 23
      'TODO: handle overflow / underflow!
      x -= $00_00_00_7E 'bias is 127
      am9511Float := (sor | (x << 24) | m) & sand
      'trace2(String("ieee="), ieeeFloat, String(" am9511="), am9511Float)
    else
      am9511Float := 0
      'trace2(String("ieee="), ieeeFloat, String(" am9511="), am9511Float)
      byte[pbStatus] := ST_ZERO 'fake zero positive status

PUB To9511(ieeeFloat, pbStatus)
  return FromIeee(ieeeFloat, pbStatus)

'-------------------------------------------------------------
' These 2 methods can be removed if no debug display is needed
'-------------------------------------------------------------
PUB WaitForKey(prompt, value) | dummy
  if traceInit
     repeat until not lockset(traceLock)
     pst.NewLine
     pst.Str(prompt)
     pst.Dec(value)
     pst.Str(String(" 0x"))
     pst.Hex(value, 8)
     pst.Str(String(" Press any key to continue..."))
     dummy := pst.CharIn
     pst.NewLine
     lockclr(traceLock)
   
PUB DisplayValue(prompt, value, pstrValue)
  if traceInit
     repeat until not lockset(traceLock)
     pst.Str(prompt)
     pst.Str(String(" 0x"))
     pst.Hex(value, 8)
     if pstrValue
        pst.Str(String("["))
        pst.Str(pstrValue)
        pst.Str(String("]"))
     pst.NewLine
     lockclr(traceLock)
'--------------------------------------------
  
PRI execute(cmd, getStatus) :st| pdDest
  st := 0
  case cmd
    NOOP: 'small optimization to bypass issuing this command to FPU
      'trace2(String(" cmd="), cmd, String(" NOOP "), long[pdCmdAndParams + 4][cmd & $03]) 
      
    POPS1, POPS2, POPS3, POPS4:
      long[pdCmdAndParams + 4][cmd & $03] := readStatus
      'trace2(String(" cmd="), cmd, String(" POPS* "), long[pdCmdAndParams + 4][cmd & $03]) 
      
    POPD1, POPD2, POPD3, POPD4:
      long[pdCmdAndParams + 4][cmd & $03] := pop4
      'trace2(String(" cmd="), cmd, String(" POPD* "), long[pdCmdAndParams + 4][cmd & $03]) 
      
    PUSHD1, PUSHD2, PUSHD3, PUSHD4:
      push4(long[pdCmdAndParams + 4][cmd & $03])
      'trace2(String(" cmd="), cmd, String(" PUSHD* "), long[pdCmdAndParams + 4][cmd & $03]) 

    POPI1, POPI2, POPI3, POPI4:
      pdDest := long[pdCmdAndParams + 4][cmd & $03]
      long[pdDest] := pop4
      'trace2(String(" cmd="), cmd, String(" POPI* "), long[pdDest]) 
      
    INITIALIZE:
      dira[RESET]~~
      outa[RESET]~~ 'activate RESET pin
      waitMs(1)     'keep active for 1ms
      outa[RESET]~  'deactivete RESET pin
      'trace2(String(" cmd="), cmd, String(" RESET "), long[pdCmdAndParams][3]) 

    PUSHZERO:
      push4(AM9511_ZERO)
      'trace2(String(" cmd="), cmd, String(" PUSHZERO "), AM9511_ZERO) 
      
    PUSHONE:
      push4(AM9511_ONE)
      'trace2(String(" cmd="), cmd, String(" PUSHONE "), AM9511_ONE) 
      
    PUSHMINUSONE:
      push4(AM9511_MONE)    
      'trace2(String(" cmd="), cmd, String(" PUSHMINUSONE "), AM9511_MONE) 

    other:
      'setControlLines
      outa[nSVACK]~
      outa[nSVACK]~~
      writeByte(false, %10000000 | cmd)
      if getStatus 'tiny optimization to execute this if before blocking on FPU
        waitpeq(|< SVREQ, |< SVREQ, 0) 'wait for SVREQ to go high (which means fpu finished executing)
        st := readByte(false)
        'trace2(String("*cmd="), cmd, String(" status="), st)
      else
        waitpeq(|< SVREQ, |< SVREQ, 0) 'wait for SVREQ to go high (which means fpu finished executing)

PRI pop4 : val32
  setControlLines
  val32 := (readByte(true) << 24) | (readByte(true) << 16) | (readByte(true) << 8) | readByte(true)

PRI push4(val32)
  setControlLines
  writeByte(true, val32)
  writeByte(true, val32 >> 8)
  writeByte(true, val32 >> 16)
  writeByte(true, val32 >> 24)

PRI readStatus : st
  setControlLines
  st := readByte(false)

PRI runFPU(setFreq, pdShared)
  long[pdShared] := CMD_ERROR   'lock the caller (Start()) from returning
  long[pdShared][5] := 0        'clear status
  pdCmdAndParams := pdShared
  traceShared(String("Before FPU reset"), 0)
  'set CLK and RESET
  dira[RESET]~~
  dira[CLK]~~ 
  outa[RESET]~~ 'activate RESET while clock is being initialized 
' initialize counter A to drive clock
  phsa := 0
  ctra[5..0] := CLK
  frqa := (429 * setFreq) ~> 3
  ctra[30..26] := %00100 'NCO single ended 
  waitMs(1) 'clock is stable, keep RESET high for another 1ms
  outa[RESET]~ 'deactivete RESET, Am9511 works continutiously from this point on!
' initialize counter B to count clock, connect to CLK output and count for 1s, giving the actual frequency
  ctrb[5..0] := CLK
  ctrb[30..26] := %01010 'posedge detector with no feedback
  phsb := 0
  frqb := 1
  waitcnt(clkfreq + cnt) 'wait 1 second to accumulate the number which equals...
  ' Param 1 = running frequency in floating point
  push4(phsb)
  execute(FLTD, false)
  long[pdShared][1] := Pop4
  traceShared(String("FPU frequency stored"), 0)  
  ' Param 2 = PI
  execute(PUPI, false)
  long[pdShared][2] := Pop4
  traceShared(String("Pi stored"), 0)  
  ' Param 3 = e
  execute(PUPI, false)
  execute(PUPI, false)
  execute(FDIV, false)
  execute(EXP, false)
  execute(PTOF, false)
  long[pdShared][3] := Pop4
  traceShared(String("e stored"), 0)
  execute(LN, false)
  long[pdShared][4] := Pop4
  traceShared(String("0.9999999 stored"), 0)
  long[pdShared] := CMD_FREE 'caller can now return
  'Continue running to keep frequency
  repeat
    case long[pdShared]
      CMD_ERROR:   'stop executing until error cleared with new evaluation
        traceShared(String("LOOP ERROR"), 0)  
        'waitMs(1)
      CMD_FREE:    'nothing to do 
        traceShared(String("LOOP FREE"), 0)  
        'waitMs(1)
      other:
        traceShared(String("LOOP EXEC"), 0)  
        byte[pdShared][23] := execute(byte[pdShared][3], true)
        byte[pdShared][22] := execute(byte[pdShared][2], true)
        byte[pdShared][21] := execute(byte[pdShared][1], true)
        byte[pdShared][20] := execute(byte[pdShared], true)
        long[pdShared] := CMD_FREE
        'waitMs(1)
      
PRI writeByte(isData, commandOrData)
  dira[D7..D0]~~ 'set data bus to output mode
  if (isData)
    outa[nCS..CnD] := %0110 'select for data
  else
    outa[nCS..CnD] := %0111 'select for command 
  outa[D7..D0] := commandOrData
  outa[nWR]~
  waitpeq(|< nPAUSE, |< nPAUSE, 0) 'wait for the nPAUSE to go high (which means fpu is ready)
  outa[nWR]~~
  outa[nCS]~~

PRI readByte(isData) :statusOrData
  dira[D7..D0]~ 'set data bus to input mode
  if (isData) 'wait for BUSY bit to go low before reading data (this will also leave data bus in input mode)
    outa[nCS..CnD] := %0110 'select for data
  else 'no need to wait to read status
    outa[nCS..CnD] := %0111 'select for status 
  outa[nRD]~
  waitpeq(|< nPAUSE, |< nPAUSE, 0) 'wait for the nPAUSE to go high (which means fpu is ready)
  statusOrData := ina[D7..D0]
  outa[nRD]~~
  outa[nCS]~~

PRI setControlLines
  outa[nCS..CnD] := %1111 'deactivate control lines
  dira[nPAUSE]~     'input
  dira[SVREQ]~
  dira[nCS..CnD]~~  'output
  dira[nSVACK]~~

PRI waitMs(delayMs)
  if (delayMs)
    waitcnt((clkfreq * delayMs) / 1000 + cnt)

PRI traceCogAndPrompt(pbPrompt)
  pst.Str(String("["))
  pst.Hex(cogid, 1)
  pst.Str(String(":"))
  pst.Hex(pdCmdAndParams, 8)
  pst.Str(String("]"))
  pst.Str(pbPrompt)
   
PRI traceInit
  if pstCog
     return true
  else
    pstCog := pst.Start(115_200)
    pst.Clear
    traceLock := locknew
    return (pstCog > 0)
    
PRI traceShared(pbPrompt, delayMs)
if trace and traceInit
    repeat until not lockset(traceLock)
    traceCogAndPrompt(pbPrompt)
    pst.Str(String(" cmd="))
    pst.Hex(long[pdCmdAndParams][0], 8)
    pst.Str(String(" v1="))
    pst.Hex(long[pdCmdAndParams][1], 8)
    pst.Str(String(" v2="))
    pst.Hex(long[pdCmdAndParams][2], 8)
    pst.Str(String(" v3="))
    pst.Hex(long[pdCmdAndParams][3], 8)
    pst.Str(String(" v4="))
    pst.Hex(long[pdCmdAndParams][4], 8)
    pst.Str(String(" st="))
    pst.Hex(long[pdCmdAndParams][5], 8)
    pst.NewLine
    waitMs(delayMs)
    lockclr(traceLock)

PRI trace2(pbPrompt1, v1, pbPrompt2, v2)
if trace and traceInit
    repeat until not lockset(traceLock)
    traceCogAndPrompt(pbPrompt1)
    pst.Hex(v1, 8)
    pst.Str(pbPrompt2)
    pst.Hex(v2, 8)
    pst.NewLine
    lockclr(traceLock)

DAT
stBusy                  byte "BUSY", 0
stOk                    byte "OK", 0
stNegative              byte ", negative", 0
stZero                  byte ", zero", 0
stCarry                 byte ", carry", 0
stErrorDivByZero        byte "ERROR: divide by zero",0
stErrorNegRoot          byte "ERROR: negative argument", 0
stErrorArgTooLarge      byte "ERROR: argument too large", 0
stErrorUnderflow        byte "ERROR: underflow", 0
stErrorOverflow         byte "ERROR: overflow", 0
