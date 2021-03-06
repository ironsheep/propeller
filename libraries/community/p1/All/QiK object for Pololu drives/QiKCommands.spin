''=============================================================================
'' Qic object nov 2010 H.J. Kiela Opteq R&D BV
'' V1.0
'' This objects holds all methods to operate the QiK drives
'' All drives can be daisy chained, by assigning them unique addresses.
'' The Rx lines can be joined. The Tx lines must be connected via open collector buffers (SN7407 f.e.)
''
'' Use program Qik SetParameters to set address and parameters
''=============================================================================

CON

'Pololu QiC serial protocol. For Pololu commands (High bit = 0 otherwise address is ignored)!
  'Serial in parameters
   BaudQ = 115200
   
   Drive0 = 10            ' Drive address constants
   Drive1 = 11            
   Drive2 = 12            
   Drive3 = 13            

  ' Commands
   cM0F = $88              'Motor M0 Forward 
   cM0R = $8A              'Motor M0 reverse 
   cM1F = $8C              'Motor M1 Forward 
   cM1R = $8E              'Motor M1 reverse
   cM0B = $86              'Motor M0 Brake
   cM1B = $87              'Motor M1 Brake
   
   'Get info
   cGetM0Current = $90     'Get motor 0 current 0-127 150mA/unit
   cGetM1Current = $91     'Motor 1
   cGetM0Speed   = $92
   cGetM1Speed   = $93
   cGetError     = $82     'Get Error Byte
   cGetFirmware  = $81     'Get Firmware Version
   cGetPar       = $83     'Get Configuration Parameter
   cSetPar       = $84     'Set Configuration Parameter
   
   'Error bits
   cMotor0Fault   = $01    'bit 0: Motor 0 Fault
   cMotor1Fault   = $02    'bit 1: Motor 1 Fault
   cMotor0Current = $04    'bit 2: Motor 0 Over Current
   cMotor1Current = $08    'bit 3: Motor 1 Over Current
   cSerialError   = $10    'bit 4: Serial Hardware Error
   cCRCError      = $20    'bit 5: CRC Error  
   cFormatError   = $40    'bit 6: Format Error
   cTimeOut       = $80    'bit 7: Timeout
   
  'Return constants on status request
  cDeviceID        = 0
  cPWMParameter    = 1
  cShutDownonError = 2
  cSerialTimeout   = 3
  cMotorM0Acc      = 4
  cMotorM1Acc      = 5
  cMotorM0BrakeDur = 6
  cMotorM1BrakeDur = 7
  cMotorM0CurLimit = 8
  cMotorM1CurLimit = 9
  cMotorM0CurLimResp = 10
  cMotorM1CurLimResp = 11
  MaxParameters = 11
  
OBJ
  qic           : "FullDuplexSerial"       ' Standard serial communication
  
Var Byte  ActQiK
    Byte  lTxPin, lRxPin
     
' ---------------------  Init QiK object  ------------------
PUB Init( RxPin, TxPin)
  lTxPin:=TxPin
  lRxPin:=RxPin
  qic.start(lRxPin, lTxPin, 0, BaudQ)  'Start serial port   start(rxpin, txpin, mode, baudrate)
  ActQiK :=0                           '0=Compact protocol 1=Pololu protocol, multi drop daisy chain
  AutoBaud
   
' ---------------------  'Auto baud Qik  ------------------
PUB AutoBaud             'Perform this command first to get baud rate rigth of all QiK drives
  qic.tx($AA)            'Auto baud character   

' ---------------------  'Set/Get communication protocol  ------------------
PUB SetProtocol(lQiK)    '0=Compact protocol 1=Pololu protocol for multi drop daisy chain
  ActQiK:=0 #> lQiK <# 1

PUB GetProtocol          'Return actual protocol
Return ActQiK

' ----------------  QiC commands motor commands pololu drivers -----
' ---------------------  'Set new speed motor 0   ------------------
PUB SetSpeedM0(Address,Speed) | lS, NewCommand 
  If Speed<0
    NewCommand:=cM0R
    lS:= 0 #> -Speed <# 127 'Limit range
  else
    NewCommand:=cM0F
    lS:= 0 #> Speed <# 127 'Limit range

  if ActQiK==1
    qic.tx($AA)    
    qic.tx(Address)
    NewCommand:=NewCommand - $80
  else
  qic.tx(NewCommand) 'Motor speed command
  qic.tx(lS)                        

' ---------------------  'Set new speed motor 1   ------------------
PUB SetSpeedM1(Address,Speed) | lS, NewCommand 
  If Speed<0
    NewCommand:=cM1R
    lS:= 0 #> -Speed <# 127 'Limit range
  else
    NewCommand:=cM1F
    lS:= 0 #> Speed <# 127 'Limit range

  if ActQiK==1
    qic.tx($AA)    
    qic.tx(Address)
    NewCommand:=NewCommand - $80

  qic.tx(NewCommand) 'Motor speed command
  qic.tx(lS)                        

' ---------------------  'Set Braking motor 0 ---------------------
PUB SetBrakeM0(Address,Brake) | lS, NewCommand 
  lS:= 0 #> Brake <# 127 'Limit range
  NewCommand:=cM0B  'Motor Brake command
  if ActQiK==1
    qic.tx($AA)    
    qic.tx(Address)
    NewCommand:=NewCommand - $80
  qic.tx(NewCommand) 
  qic.tx(lS)                        

' ---------------------  'Set Braking motor 1 ----------------------
PUB SetBrakeM1(Address,Brake) | lS, NewCommand 
  lS:= 0 #> Brake <# 127 'Limit range
  NewCommand:=cM1B  'Motor Brake command
  if ActQiK==1
    qic.tx($AA)    
    qic.tx(Address)
    NewCommand:=NewCommand - $80
  qic.tx(NewCommand) 
  qic.tx(lS)                        
                                    
' ---------------------  'Set Parameter  ---------------------------
PUB SetParameter(Address,Parameter, Value) | lS, NewCommand, R
  lS:= 0 #> Parameter <# 11 'Limit range
  NewCommand:=cSetPar 'Set parameter command
  if ActQiK==1
    qic.tx($AA)    
    qic.tx(Address)
    NewCommand:=NewCommand - $80
  qic.tx(NewCommand) 
  qic.tx(Parameter) 'Get requested parameter
  qic.tx(Value)
  qic.tx($55)      'extra bytes for security
  qic.tx($2A)
  R:=qic.rxtime(10) 'Wait for return charater before continuing max 10 ms
Return R           'Return result of parameter set     Check with SetParRes2str(Resnr) result

' --------------------- 'Get Parameter  ----------------------------
PUB GetParameter(Address, Parameter) | R, NewCommand
  NewCommand:=cGetPar 'Get parameter command
  if ActQiK==1
    qic.tx($AA)    
    qic.tx(Address)
    NewCommand:=NewCommand - $80
  qic.tx(NewCommand) 
  qic.tx(Parameter) 'Get requested parameter
  R:=qic.rxtime(10) 'Expect response within 10 ms
Return  R


' --------------------- 'Get motor 0 current -----------------------
PUB GetCurrentM0(Address) | R, NewCommand
  NewCommand:=cGetM0Current 'Get current M0
  if ActQiK==1
    qic.tx($AA)    
    qic.tx(Address)
    NewCommand:=NewCommand - $80
  qic.tx(NewCommand) 
  R:=qic.rxtime(10)     'Expect response within 10 ms
Return R*150            'Scale output to mA

' ---------------------  'Get  motor 1 current    ------------------
PUB GetCurrentM1(Address) | R, NewCommand
  NewCommand:=cGetM1Current 'Get current M1
  if ActQiK==1
    qic.tx($AA)    
    qic.tx(Address)
    NewCommand:=NewCommand - $80
  qic.tx(NewCommand) 
  R:=qic.rxtime(10)     'Expect response within 10 ms  
Return R*150            'Scale output to mA 

' ---------------------  'Get  motor 0 speed      ------------------
PUB GetSpeedM0(Address) | R, NewCommand
  NewCommand:=cGetM0Speed 'Get speed M0
  if ActQiK==1
    qic.tx($AA)    
    qic.tx(Address)
    NewCommand:=NewCommand - $80
  qic.tx(NewCommand) 
  R:=qic.rxtime(10)     'Expect response within 10 ms  
Return R

' ---------------------  'Get  motor 1 speed      ------------------
PUB GetSpeedM1(Address) | R, NewCommand
  NewCommand:=cGetM1Speed 'Get speed M1
  if ActQiK==1
    qic.tx($AA)    
    qic.tx(Address)
    NewCommand:=NewCommand - $80
  qic.tx(NewCommand) 
  R:=qic.rxtime(10)     'Expect response within 10 ms  
Return R

' ---------------------  'Get  firmware             ------------------
PUB GetFirmWare(Address) | R, NewCommand
  NewCommand:=cGetFirmware 'Get firmware
  if ActQiK==1
    qic.tx($AA)    
    qic.tx(Address)
    NewCommand:=NewCommand - $80
  qic.tx(NewCommand) 
  R:=qic.rxtime(10)     'Expect response within 10 ms  
Return R

' ---------------------  'Get  error              ------------------
PUB GetError(Address) | R, NewCommand
  NewCommand:=cGetError 'Get errors
  if ActQiK==1
    qic.tx($AA)    
    qic.tx(Address)
    NewCommand:=NewCommand - $80
  qic.tx(NewCommand) 
  R:=qic.rxtime(10)     'Expect response within 10 ms  
Return R

' ---------------------  'List Parameters Qik drive         ------------------
'PUB ListPars(Address) | R, i
'  ser.str(string(CR,"List parameters",CR))
'  repeat i from 0 to 11 '' MaxParameters
'    ser.dec(i)
'    ser.tx(" ")
'    R:=GetParameter(Address,i)  'get parameter value
'    ser.str(Par2Str(i))
'    ser.dec(R)
'    ser.tx(CR)
  
'  ser.tx(CR)

' ---------------------  Return QiC errorstring -----------------------------
PUB Error2Str(Error)
    if Error and cMotor0Fault   == cMotor0Fault
       Return @sMotor0Fault
    if Error and cMotor1Fault   == cMotor1Fault
       Return @sMotor1Fault
    if Error and cMotor0Current == cMotor0Current
       Return @sMotor0Current
    if Error and cMotor1Current == cMotor1Current
       Return @sMotor1Current
    if Error and cSerialError   == cSerialError
       Return @sSerialError
    if Error and cCRCError      == cCRCError
       Return @sCRCError
    if Error and cFormatError   == cFormatError
       Return @sFormatError
    if Error and cTimeOut       == cTimeOut
       Return @sTimeOut
    if Error == 0
       Return @sNoError

' ---------------------  Return QiC Parameter string -----------------------------
PUB Par2Str(ParNr)

    Case ParNr 
       cDeviceID:               Return @sDeviceID
       cPWMParameter:           Return @sPWMParameter
       cShutDownonError:        Return @sShutDownonError
       cSerialTimeout:          Return @sSerialTimeout
       cMotorM0Acc:             Return @sMotorM0Acc
       cMotorM1Acc:             Return @sMotorM1Acc
       cMotorM0BrakeDur:        Return @sMotorM0BrakeDur
       cMotorM1BrakeDur:        Return @sMotorM1BrakeDur
       cMotorM0CurLimit:        Return @sMotorM0CurLimit
       cMotorM1CurLimit:        Return @sMotorM0CurLimit
       cMotorM0CurLimResp:      Return @sMotorM0CurLimResp
       cMotorM1CurLimResp:      Return @sMotorM1CurLimResp
       Other :                  Return @sUnknown

' ---------------------  Return QiC command response string -----------------------------
PUB SetParRes2str(Resnr)
  Case Resnr
    0: Return @sCommandOK
    1: Return @sBadParameter
    2: Return @sBadvalue
    -1: Return @sNoResponse
    Other: Return @sUnknown
    
DAT
sMotor0Fault    Byte "Motor 0 Fault",0
sMotor1Fault    Byte "Motor 1 Fault",0
sMotor0Current  Byte "Motor 0 Over Current",0
sMotor1Current  Byte "Motor 1 Over Current",0
sSerialError    Byte "Serial Hardware Error",0
sCRCError       Byte "CRC Error",0
sFormatError    Byte "Format Error",0
sTimeOut        Byte "Timeout",0
sNoError        Byte "No Error",0

' Set par result. Wait for response before next command
sCommandOK      Byte "0: Command OK (success)",0
sBadParameter   Byte "1: Bad Parameter (failure due to invalid parameter number)",0
sBadvalue       Byte "2: Bad value (failure due to invalid parameter value for the specified parameter number)",0
sNoResponse     Byte "No Response",0

sDeviceID          Byte "DeviceID: ",0
sPWMParameter      Byte "PWMParameter: ",0
sShutDownonError   Byte "ShutDownon Error: ",0
sSerialTimeout     Byte "Serial Timeout Error: ",0
sMotorM0Acc        Byte "MotorM0Acc: ",0
sMotorM1Acc        Byte "MotorM1Acc: ",0
sMotorM0BrakeDur   Byte "MotorM0BrakeDur: ",0
sMotorM1BrakeDur   Byte "MotorM1BrakeDur: ",0
sMotorM0CurLimit   Byte "MotorM0CurLimit: ",0
sMotorM1CurLimit   Byte "MotorM1CurLimit: ",0
sMotorM0CurLimResp Byte "MotorM0CurLimResp: ",0
sMotorM1CurLimResp Byte "MotorM1CurLimResp: ",0
sUnknown           Byte "Unknown Parameter! ",0

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