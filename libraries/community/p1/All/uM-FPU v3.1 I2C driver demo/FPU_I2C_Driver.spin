{{
┌───────────────────────────┬───────────────────┬────────────────────────┐
│ FPU_I2C_Driver.spin v1.2  │ Author: I.Kövesdi │ Release:   25 08 2008  │
├───────────────────────────┴───────────────────┴────────────────────────┤
│                    Copyright (c) 2008 CompElit Inc.                    │               
│                   See end of file for terms of use.                    │               
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  This is a driver object for uM-FPU V3.1 floating point coprocessor    │
│ using I2C protocol. It is implemented in SPIN and needs only the COG   │
│ for the SPIN interpreter. It uses a simple I2C driver object, which is │
│ coded also in SPIN.                                                    │
│                                                                        │
├────────────────────────────────────────────────────────────────────────┤
│ Background and Detail:                                                 │
│  This driver contains, beside the basic read/write functionalities,    │
│ many additional procedures to make the programming  and code-reading   │
│ of the uM-FPU easy.                                                    │
│                                                                        │
├────────────────────────────────────────────────────────────────────────┤
│ Note:                                                                  │
│  This driver object is designed to provide the user similar options and│
│ procedures as it's equivalent one with SPI protocol.                   │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
}}


CON

  _ACK    = 0    
  _NAK    = 1
  

'Delays
  _RESETDELAY = 800_000    '10 ms Reset Delay
  '_READDELAY  = 14_400     '180 us at 80 MHz / Debug trace enabled
  _READDELAY = 7200        '90 us at 80 MHz / Debug trace disabled 
  _FTOAD      = 10000

'uM-FPU I2C registers
  _0         = 0
  _1         = 1

  _MAXSTRL   = 16        'Default Max. Str Length for FPU operations
  

'uM-FPU V3.1 opcodes and indexes------------------------------------------
  _NOP       = $00       'No Operation
  _SELECTA   = $01       'Select register A  
  _SELECTX   = $02       'Select register X

  _CLR       = $03       'Reg[nn] = 0
  _CLRA      = $04       'Reg[A] = 0
  _CLRX      = $05       'Reg[X] = 0, X = X + 1
  _CLR0      = $06       'Reg[0] = 0

  _COPY      = $07       'Reg[nn] = Reg[mm]
  _COPYA     = $08       'Reg[nn] = Reg[A]
  _COPYX     = $09       'Reg[nn] = Reg[X], X = X + 1
  _LOAD      = $0A       'Reg[0] = Reg[nn]
  _LOADA     = $0B       'Reg[0] = Reg[A]
  _LOADX     = $0C       'Reg[0] = Reg[X], X = X + 1
  _ALOADX    = $0D       'Reg[A] = Reg[X], X = X + 1
  _XSAVE     = $0E       'Reg[X] = Reg[nn], X = X + 1
  _XSAVEA    = $0F       'Reg[X] = Reg[A], X = X + 1
  _COPY0     = $10       'Reg[nn] = Reg[0]
  _COPYI     = $11       'Reg[nn] = long(unsigned bb)
  _SWAP      = $12       'Swap Reg[nn] and Reg[mm]
  _SWAPA     = $13       'Swap Reg[A] and Reg[nn]
  
  _LEFT      = $14       'Left parenthesis
  _RIGHT     = $15       'Right parenthesis
  
  _FWRITE    = $16       'Write 32-bit float to Reg[nn]
  _FWRITEA   = $17       'Write 32-bit float to Reg[A]
  _FWRITEX   = $18       'Write 32-bit float to Reg[X], X = X + 1
  _FWRITE0   = $19       'Write 32-bit float to Reg[0]

  _FREAD     = $1A       'Read 32-bit float from Reg[nn]
  _FREADA    = $1B       'Read 32-bit float from Reg[A]
  _FREADX    = $1C       'Read 32-bit float from Reg[X], X = X + 1
  _FREAD0    = $1D       'Read 32-bit float from Reg[0]

  _ATOF      = $1E       'Convert ASCII string to float, store in Reg[0]
  _FTOA      = $1F       'Convert float in Reg[A] to ASCII string.
  
  _FSET      = $20       'Reg[A] = Reg[nn] 

  _FADD      = $21       'Reg[A] = Reg[A] + Reg[nn]
  _FSUB      = $22       'Reg[A] = Reg[A] - Reg[nn]
  _FSUBR     = $23       'Reg[A] = Reg[nn] - Reg[A]
  _FMUL      = $24       'Reg[A] = Reg[A] * Reg[nn]
  _FDIV      = $25       'Reg[A] = Reg[A] / Reg[nn]
  _FDIVR     = $26       'Reg[A] = Reg[nn] / Reg[A]
  _FPOW      = $27       'Reg[A] = Reg[A] ** Reg[nn]
  _FCMP      = $28       'Float compare Reg[A] - Reg[nn]
  
  _FSET0     = $29       'Reg[A] = Reg[0]
  _FADD0     = $2A       'Reg[A] = Reg[A] + Reg[0]
  _FSUB0     = $2B       'Reg[A] = Reg[A] - Reg[0]
  _FSUBR0    = $2C       'Reg[A] = Reg[0] - Reg[A]
  _FMUL0     = $2D       'Reg[A] = Reg[A] * Reg[0]
  _FDIV0     = $2E       'Reg[A] = Reg[A] / Reg[0]
  _FDIVR0    = $2F       'Reg[A] = Reg[0] / Reg[A]
  _FPOW0     = $30       'Reg[A] = Reg[A] ** Reg[0]
  _FCMP0     = $31       'Float compare Reg[A] - Reg[0]  

  _FSETI     = $32       'Reg[A] = float(bb)
  _FADDI     = $33       'Reg[A] = Reg[A] + float(bb)
  _FSUBI     = $34       'Reg[A] = Reg[A] - float(bb)
  _FSUBRI    = $35       'Reg[A] = float(bb) - Reg[A]
  _FMULI     = $36       'Reg[A] = Reg[A] * float(bb)
  _FDIVI     = $37       'Reg[A] = Reg[A] / float(bb) 
  _FDIVRI    = $38       'Reg[A] = float(bb) / Reg[A]
  _FPOWI     = $39       'Reg[A] = Reg[A] ** bb
  _FCMPI     = $3A       'Float compare Reg[A] - float(bb)
  
  _FSTATUS   = $3B       'Float status of Reg[nn]
  _FSTATUSA  = $3C       'Float status of Reg[A]
  _FCMP2     = $3D       'Float compare Reg[nn] - Reg[mm]

  _FNEG      = $3E       'Reg[A] = -Reg[A]
  _FABS      = $3F       'Reg[A] = | Reg[A] |
  _FINV      = $40       'Reg[A] = 1 / Reg[A]
  _SQRT      = $41       'Reg[A] = sqrt(Reg[A])    
  _ROOT      = $42       'Reg[A] = root(Reg[A], Reg[nn])
  _LOG       = $43       'Reg[A] = log(Reg[A])
  _LOG10     = $44       'Reg[A] = log10(Reg[A])
  _EXP       = $45       'Reg[A] = exp(Reg[A])
  _EXP10     = $46       'Reg[A] = exp10(Reg[A])
  _SIN       = $47       'Reg[A] = sin(Reg[A])
  _COS       = $48       'Reg[A] = cos(Reg[A])
  _TAN       = $49       'Reg[A] = tan(Reg[A])
  _ASIN      = $4A       'Reg[A] = asin(Reg[A])
  _ACOS      = $4B       'Reg[A] = acos(Reg[A])
  _ATAN      = $4C       'Reg[A] = atan(Reg[A])
  _ATAN2     = $4D       'Reg[A] = atan2(Reg[A], Reg[nn])
  _DEGREES   = $4E       'Reg[A] = degrees(Reg[A])
  _RADIANS   = $4F       'Reg[A] = radians(Reg[A])
  _FMOD      = $50       'Reg[A] = Reg[A] MOD Reg[nn]
  _FLOOR     = $51       'Reg[A] = floor(Reg[A])
  _CEIL      = $52       'Reg[A] = ceil(Reg[A])
  _ROUND     = $53       'Reg[A] = round(Reg[A])
  _FMIN      = $54       'Reg[A] = min(Reg[A], Reg[nn])
  _FMAX      = $55       'Reg[A] = max(Reg[A], Reg[nn])
  
  _FCNV      = $56       'Reg[A] = conversion(nn, Reg[A])
    _F_C       = 0       '├─>F to C
    _C_F       = 1       '├─>C to F
    _IN_MM     = 2       '├─>in to mm
    _MM_IN     = 3       '├─>mm to in
    _IN_CM     = 4       '├─>in to cm
    _CM_IN     = 5       '├─>cm to in
    _IN_M      = 6       '├─>in to m
    _M_IN      = 7       '├─>m to in
    _FT_M      = 8       '├─>ft to m
    _M_FT      = 9       '├─>m to ft
    _YD_M      = 10      '├─>yd to m
    _M_YD      = 11      '├─>m to yd
    _MI_KM     = 12      '├─>mi to km
    _KM_MI     = 13      '├─>km to mi
    _NMI_M     = 14      '├─>nmi to m
    _M_NMI     = 15      '├─>m to nmi
    _ACR_M2    = 16      '├─>acre to m2
    _M2_ACR    = 17      '├─>m2 to acre
    _OZ_G      = 18      '├─>oz to g
    _G_OZ      = 19      '├─>g to oz
    _LB_KG     = 20      '├─>lb to kg
    _KG_LB     = 21      '├─>kg to lb
    _USGAL_L   = 22      '├─>USgal to l
    _L_USGAL   = 23      '├─>l to USgal
    _UKGAL_L   = 24      '├─>UKgal to l
    _L_UKGAL   = 25      '├─>l to UKgal
    _USOZFL_ML = 26      '├─>USozfl to ml
    _ML_USOZFL = 27      '├─>ml to USozfl
    _UKOZFL_ML = 28      '├─>UKozfl to ml
    _ML_UKOZFL = 29      '├─>ml to UKozfl
    _CAL_J     = 30      '├─>cal to J
    _J_CAL     = 31      '├─>J to cal
    _HP_W      = 32      '├─>hp to W
    _W_HP      = 33      '├─>W to hp
    _ATM_KP    = 34      '├─>atm to kPa
    _KP_ATM    = 35      '├─>kPa to atm
    _MMHG_KP   = 36      '├─>mmHg to kPa
    _KP_MMHG   = 37      '├─>kPa to mmHg
    _DEG_RAD   = 38      '├─>degrees to radians
    _RAD_DEG   = 39      '└─>radians to degrees    

  _FMAC      = $57       'Reg[A] = Reg[A] + (Reg[nn] * Reg[mm])
  _FMSC      = $58       'Reg[A] = Reg[A] - (Reg[nn] * Reg[mm])

  _LOADBYTE  = $59       'Reg[0] = float(signed bb)
  _LOADUBYTE = $5A       'Reg[0] = float(unsigned byte)
  _LOADWORD  = $5B       'Reg[0] = float(signed word)
  _LOADUWORD = $5C       'Reg[0] = float(unsigned word)
  
  _LOADE     = $5D       'Reg[0] = 2.7182818             
  _LOADPI    = $5E       'Reg[0] = 3.1415927
  
  _LOADCON   = $5F       'Reg[0] = float constant(nn)                        
    _ONE      = 0        '├─>1e0 one
    _1E1      = 1        '├─>1e1
    _1E2      = 2        '├─>1e2
    _KILO     = 3        '├─>1e3 kilo
    _1E4      = 4        '├─>1e4
    _1E5      = 5        '├─>1e5
    _MEGA     = 6        '├─>1e6 mega
    _1E7      = 7        '├─>1e7
    _1E8      = 8        '├─>1e8
    _GIGA     = 9        '├─>1e9 giga
    _MAXFLOAT = 10       '├─>3.4028235e38   :Largest 32-bit f.p. value                                   
    _MINFLOAT = 11       '├─>1.4012985e-45  :Smallest nonzero 32-bit f.p.
    _C        = 12       '├─>299792458.0    :Speed of light in vaccum[m/s]
    _GRAVCON  = 13       '├─>6.6742e-11     :Const. of grav. [m3/(kg*s2)]
    _MEANG    = 14       '├─>9.80665        :Mean accel. of gravity [m/s2]
    _EMASS    = 15       '├─>9.1093826e-31  :Electron mass [kg]
    _PMASS    = 16       '├─>1.67262171e-27 :Proton mass [kg]
    _NMASS    = 17       '├─>1.67492728e-27 :Neutron mass [kg]
    _A        = 18       '├─>6.0221415e23   :Avogadro constant [1/mol]
    _ELCHRG   = 19       '├─>1.60217653e-19 :Elementary charge [coulomb]
    _STDATM   = 20       '└─>101.325        :Standard atmosphere [kPa]

  _FLOAT     = $60       'Reg[A] = float(Reg[A])     :long to float  
  _FIX       = $61       'Reg[A] = fix(Reg[A])       :float to long
  _FIXR      = $62       'Reg[A] = fix(round(Reg[A])):rounded float to lng
  _FRAC      = $63       'Reg[A] = fraction(Reg[A])  
  _FSPLIT    = $64       'Reg[A] = int(Reg[A]), Reg[0] = frac(Reg[A])
  
  _SELECTMA  = $65       'Select matrix A
  _SELECTMB  = $66       'Select matrix B
  _SELECTMC  = $67       'Select matrix C
  _LOADMA    = $68       'Reg[0] = matrix A[bb, bb]
  _LOADMB    = $69       'Reg[0] = matrix B[bb, bb]
  _LOADMC    = $6A       'Reg[0] = matrix C[bb, bb]
  _SAVEMA    = $6B       'Matrix A[bb, bb] = Reg[0] Please correct TFM!                     
  _SAVEMB    = $6C       'Matrix B[bb, bb] = Reg[0] Please correct TFM!                         
  _SAVEMC    = $6D       'Matrix C[bb, bb] = Reg[0] Please correct TFM!

  _MOP       = $6E       'Matrix operation
    '-------------------------For each r(ow), c(olumn)--------------------
    _SCALAR_SET  = 0     '├─>MA[r, c] = Reg[0]
    _SCALAR_ADD  = 1     '├─>MA[r, c] = MA[r, c] + Reg[0]
    _SCALAR_SUB  = 2     '├─>MA[r, c] = MA[r, c] - Reg[0]
    _SCALAR_SUBR = 3     '├─>MA[r, c] = Reg[0] - MA[r, c] 
    _SCALAR_MUL  = 4     '├─>MA[r, c] = MA[r, c] * Reg[0]
    _SCALAR_DIV  = 5     '├─>MA[r, c] = MA[r, c] / Reg[0]
    _SCALAR_DIVR = 6     '├─>MA[r, c] = Reg[0] / MA[r, c]
    _SCALAR_POW  = 7     '├─>MA[r, c] = MA[r, c] ** Reg[0]
    _EWISE_SET   = 8     '├─>MA[r, c] = MB[r, c]
    _EWISE_ADD   = 9     '├─>MA[r, c] = MA[r, c] + MB[r, c]
    _EWISE_SUB   = 10    '├─>MA[r, c] = MA[r, c] - MB[r, c]                                 
    _EWISE_SUBR  = 11    '├─>MA[r, c] = MB[r, c] - MA[r, c]
    _EWISE_MUL   = 12    '├─>MA[r, c] = MA[r, c] * MB[r, c]
    _EWISE_DIV   = 13    '├─>MA[r, c] = MA[r, c] / MB[r, c]
    _EWISE_DIVR  = 14    '├─>MA[r, c] = MB[r, c] / MA[r, c]
    _EWISE_POW   = 15    '├─>MA[r, c] = MA[r, c] ** MB[r, c]
    '---------------------------------------------------------------------
    _MX_MULTIPLY = 16    '├─>MA = MB * MC 
    _MX_IDENTITY = 17    '├─>MA = I = Identity matrix (Diag. of ones)
    _MX_DIAGONAL = 18    '├─>MA = Reg[0] * I
    _MX_TRANSPOSE= 19    '├─>MA = Transpose of MB
    '---------------------------------------------------------------------
    _MX_COUNT    = 20    '├─>Reg[0] = Number of elements in MA 
    _MX_SUM      = 21    '├─>Reg[0] = Sum of elements in MA
    _MX_AVE      = 22    '├─>Reg[0] = Average of elements in MA
    _MX_MIN      = 23    '├─>Reg[0] = Minimum of elements in MA 
    _MX_MAX      = 24    '├─>Reg[0] = Maximum of elements in MA
   '----------------------------------------------------------------------
    _MX_COPYAB   = 25    '├─>MB = MA 
    _MX_COPYAC   = 26    '├─>MC = MA
    _MX_COPYBA   = 27    '├─>MA = MB 
    _MX_COPYBC   = 28    '├─>MC = MB
    _MX_COPYCA   = 29    '├─>MA = MC 
    _MX_COPYCB   = 30    '├─>MB = MC
    '---------------------------------------------------------------------
    _MX_DETERM   = 31    '├─>Reg[0]=Determinant of MA (for 2x2 or 3x3 MA)
    _MX_INVERSE  = 32    '├─>MA = Inverse of MB (for 2x2 or 3x3 MB)
    '---------------------------------------------------------------------
    _MX_ILOADRA  = 33    '├─>Indexed Load Registers to MA
    _MX_ILOADRB  = 34    '├─>Indexed Load Registers to MB
    _MX_ILOADRC  = 35    '├─>Indexed Load Registers to MC
    _MX_ILOADBA  = 36    '├─>Indexed Load MB to MA
    _MX_ILOADCA  = 37    '├─>Indexed Load MC to MA 
    _MX_ISAVEAR  = 38    '├─>Indexed Load MA to Registers
    _MX_ISAVEAB  = 39    '├─>Indexed Load MA to MB
    _MX_ISAVEAC  = 40    '└─>Indexed Load MA to MC

  _FFT       = $6F       'FFT operation
    _FIRST_STAGE = 0     '├─>Mode : First stage 
    _NEXT_STAGE  = 1     '├─>Mode : Next stage 
    _NEXT_LEVEL  = 2     '├─>Mode : Next level
    _NEXT_BLOCK  = 3     '├─>Mode : Next block
    '---------------------------------------------------------------------
    _BIT_REVERSE = 4     '├─>Mode : Pre-processing bit reverse sort 
    _PRE_ADJUST  = 8     '├─>Mode : Pre-processing for inverse FFT
    _POST_ADJUST = 16    '└─>Mode : Post-processing for inverse FFT
  
  _WRBLK     = $70       'Write register block
  _RDBLK     = $71       'Read register block

  _LOADIND   = $7A       'Reg[0] = Reg[Reg[nn]]
  _SAVEIND   = $7B       'Reg[Reg[nn]] = Reg[A]
  _INDA      = $7C       'Select A using Reg[nn]
  _INDX      = $7D       'Select X using Reg[nn]

  _FCALL     = $7E       'Call function in Flash memory
  _EECALL    = $7F       'Call function in EEPROM memory
  
  _RET       = $80       'Return from function
  _BRA       = $81       'Unconditional branch
  _BRACC     = $82       'Conditional branch
  _JMP       = $83       'Unconditional jump
  _JMPCC     = $84       'Conditional jump
  _TABLE     = $85       'Table lookup
  _FTABLE    = $86       'Floating point reverse table lookup
  _LTABLE    = $87       'Long integer reverse table lookup
  _POLY      = $88       'Reg[A] = nth order polynomial
  _GOTO      = $89       'Computed goto
  _RETCC     = $8A       'Conditional return from function
 
  _LWRITE    = $90       'Write 32-bit long integer to Reg[nn]
  _LWRITEA   = $91       'Write 32-bit long integer to Reg[A]
  _LWRITEX   = $92       'Write 32-bit long integer to Reg[X], X = X + 1
  _LWRITE0   = $93       'Write 32-bit long integer to Reg[0]

  _LREAD     = $94       'Read 32-bit long integer from Reg[nn] 
  _LREADA    = $95       'Read 32-bit long integer from Reg[A]
  _LREADX    = $96       'Read 32-bit long integer from Reg[X], X = X + 1   
  _LREAD0    = $97       'Read 32-bit long integer from Reg[0]

  _LREADBYTE = $98       'Read lower 8 bits of Reg[A]
  _LREADWORD = $99       'Read lower 16 bits Reg[A]
  
  _ATOL      = $9A       'Convert ASCII to long integer
  _LTOA      = $9B       'Convert long integer to ASCII

  _LSET      = $9C       'reg[A] = reg[nn]
  _LADD      = $9D       'reg[A] = reg[A] + reg[nn]
  _LSUB      = $9E       'reg[A] = reg[A] - reg[nn]
  _LMUL      = $9F       'reg[A] = reg[A] * reg[nn]
  _LDIV      = $A0       'reg[A] = reg[A] / reg[nn]
  _LCMP      = $A1       'Signed long compare reg[A] - reg[nn]
  _LUDIV     = $A2       'reg[A] = reg[A] / reg[nn]
  _LUCMP     = $A3       'Unsigned long compare of reg[A] - reg[nn]
  _LTST      = $A4       'Long integer status of reg[A] AND reg[nn] 
  _LSET0     = $A5       'reg[A] = reg[0]
  _LADD0     = $A6       'reg[A] = reg[A] + reg[0]
  _LSUB0     = $A7       'reg[A] = reg[A] - reg[0]
  _LMUL0     = $A8       'reg[A] = reg[A] * reg[0]
  _LDIV0     = $A9       'reg[A] = reg[A] / reg[0]
  _LCMP0     = $AA       'Signed long compare reg[A] - reg[0]
  _LUDIV0    = $AB       'reg[A] = reg[A] / reg[0]
  _LUCMP0    = $AC       'Unsigned long compare reg[A] - reg[0]
  _LTST0     = $AD       'Long integer status of reg[A] AND reg[0] 
  _LSETI     = $AE       'reg[A] = long(bb)
  _LADDI     = $AF       'reg[A] = reg[A] + long(bb)
  _LSUBI     = $B0       'reg[A] = reg[A] - long(bb)
  _LMULI     = $B1       'Reg[A] = Reg[A] * long(bb)
  _LDIVI     = $B2       'Reg[A] = Reg[A] / long(bb); Remainder in Reg0

  _LCMPI     = $B3       'Signed long compare Reg[A] - long(bb)
  _LUDIVI    = $B4       'Reg[A] = Reg[A] / unsigned long(bb)
  _LUCMPI    = $B5       'Unsigned long compare Reg[A] - ulong(bb)
  _LTSTI     = $B6       'Long integer status of Reg[A] AND ulong(bb)
  _LSTATUS   = $B7       'Long integer status of Reg[nn]
  _LSTATUSA  = $B8       'Long integer status of Reg[A]
  _LCMP2     = $B9       'Signed long compare Reg[nn] - Reg[mm]
  _LUCMP2    = $BA       'Unsigned long compare Reg[nn] - Reg[mm]
  
  _LNEG      = $BB       'Reg[A] = -Reg[A]
  _LABS      = $BC       'Reg[A] = | Reg[A] |
  _LINC      = $BD       'Reg[nn] = Reg[nn] + 1
  _LDEC      = $BE       'Reg[nn] = Reg[nn] - 1
  _LNOT      = $BF       'Reg[A] = NOT Reg[A]

  _LAND      = $C0       'reg[A] = reg[A] AND reg[nn]
  _LOR       = $C1       'reg[A] = reg[A] OR reg[nn]
  _LXOR      = $C2       'reg[A] = reg[A] XOR reg[nn]
  _LSHIFT    = $C3       'reg[A] = reg[A] shift reg[nn]
  _LMIN      = $C4       'reg[A] = min(reg[A], reg[nn])
  _LMAX      = $C5       'reg[A] = max(reg[A], reg[nn])
  _LONGBYTE  = $C6       'reg[0] = long(signed byte bb)
  _LONGUBYTE = $C7       'reg[0] = long(unsigned byte bb)
  _LONGWORD  = $C8       'reg[0] = long(signed word wwww)
  _LONGUWORD = $C9       'reg[0] = long(unsigned word wwww)
  _SETSTATUS = $CD       'Set status byte
  _SEROUT    = $CE       'Serial output
  _SERIN     = $CF       'Serial Input
  _SETOUT    = $D0       'Set OUT1 and OUT2 output pins
  _ADCMODE   = $D1       'Set A/D trigger mode
  _ADCTRIG   = $D2       'A/D manual trigger
  _ADCSCALE  = $D3       'ADCscale[ch] = B
  _ADCLONG   = $D4       'reg[0] = ADCvalue[ch]
  _ADCLOAD   = $D5       'reg[0] = float(ADCvalue[ch]) * ADCscale[ch]
  _ADCWAIT   = $D6       'wait for next A/D sample
  _TIMESET   = $D7       'time = reg[0]
  _TIMELONG  = $D8       'reg[0] = time (long)
  _TICKLONG  = $D9       'reg[0] = ticks (long)
  _EESAVE    = $DA       'EEPROM[nn] = reg[mm]
  _EESAVEA   = $DB       'EEPROM[nn] = reg[A]
  _EELOAD    = $DC       'reg[nn] = EEPROM[mm]
  _EELOADA   = $DD       'reg[A] = EEPROM[nn]
  _EEWRITE   = $DE       'Store bytes in EEPROM
  _EXTSET    = $E0       'external input count = reg[0]
  _EXTLONG   = $E1       'reg[0] = external input counter (long)
  _EXTWAIT   = $E2       'wait for next external input
  _STRSET    = $E3       'Copy string to string buffer
  _STRSEL    = $E4       'Set selection point
  _STRINS    = $E5       'Insert string at selection point
  _STRCMP    = $E6       'Compare string with string buffer
  _STRFIND   = $E7       'Find string and set selection point
  _STRFCHR   = $E8       'Set field separators
  _STRFIELD  = $E9       'Find field and set selection point
  _STRTOF    = $EA       'Convert string selection to float
  _STRTOL    = $EB       'Convert string selection to long
  _READSEL   = $EC       'Read string selection
  _STRBYTE   = $ED       'Insert 8-bit byte at selection point
  _STRINC    = $EE       'increment selection point
  _STRDEC    = $EF       'decrement selection point  
 
  _SYNC      = $F0       'Get synchronization character 
    _SYNC_CHAR = $5C     '└─>Synchronization character(Decimal 92)
    
  _READSTAT  = $F1       'Read status byte 
  _READSTR   = $F2       'Read string from string buffer    
  _VERSION   = $F3       'Copy version string to string buffer     
  _CHECKSUM  = $F6       'Calculate checksum for uM-FPU   

  _READVAR   = $FC       'Read internal variable, store in Reg[0]
    _A_REG    = 0        '├─>Reg[0] = A register
    _X_REG    = 1        '├─>Reg[0] = X register
    _MA_REG   = 2        '├─>Reg[0] = MA register
    _MA_ROWS  = 3        '├─>Reg[0] = MA rows
    _MA_COLS  = 4        '├─>Reg[0] = MA columns
    _MB_REG   = 5        '├─>Reg[0] = MB register
    _MB_ROWS  = 6        '├─>Reg[0] = MB rows
    _MB_COLS  = 7        '├─>Reg[0] = MB columns
    _MC_REG   = 8        '├─>Reg[0] = MC register
    _MC_ROWS  = 9        '├─>Reg[0] = MC rows
    _MC_COLS  = 10       '├─>Reg[0] = MC columns
    _INTMODE  = 11       '├─>Reg[0] = Internal mode word
    _STATBYTE = 12       '├─>Reg[0] = Last status byte
    _TICKS    = 13       '├─>Reg[0] = Clock ticks per milisecond
    _STRL     = 14       '├─>Reg[0] = Current length of string buffer
    _STR_SPTR = 15       '├─>Reg[0] = String selection starting point
    _STR_SLEN = 16       '├─>Reg[0] = String selection length
    _STR_SASC = 17       '├─>Reg[0] = ASCII char at string selection point
    _INSTBUF  = 18       '└─>Reg[0] = Number of bytes in instr. buffer

  _RESET      = $FF      'NOP (but 9 consecutive $FF bytes cause a reset
                         'in SPI protocol)

                         
VAR

  long  fpu
  long  chars[_MAXSTRL] 'Long array
  byte  str[_MAXSTRL]   'Byte array   

'Data Flow within FPU_I2C_Driver object:
'=======================================
'This Driver object is implemented fully in SPIN. It calls the procedures
'of a SPIN implemented I2C driver via SPIN procedure calls where
'parameters are passed by value and the returns are by value. Only
'exceptions to this are the procedures that write of read a string or a 32
'bit array to or from the FPU. In these cases the pointer to the string or
'register array is passed and returned. None of the procedures of this
'driver uses directly "atomic" I2C routines (i.e. Start, Stop,
'Write(byte), WriteChar, Read(byte)).They are calling I2C routines where
'FPU addressing, start/stop and read/write control is implicitly coded for
'the convenience of the user.
'
'Data Flow between FPU_SPI_Driver object and a calling SPIN code object:
'========================================================================
'External SPIN code objects can call the available PUB procedures of this
'FPU_I2C_Driver object in the standard way. Except for the strings or 32
'bit variable arrays all parameters are passed by value. Strings and
'register arrays are passed by reference. 


  
OBJ

  I2C      : "I2C_Driver" 

  
PUB Init(addr, sda, scl): okay
'-------------------------------------------------------------------------
'--------------------------------┌──────┐---------------------------------
'--------------------------------│ Init │---------------------------------
'--------------------------------└──────┘---------------------------------
'-------------------------------------------------------------------------
''     Action: Initialize I2C lines and check for FPU present                                                       
'' Parameters: Device Address and I2C lines                                         
''    Results: Okay if idle I2C lines are stable High and FPU on board                            
''+Reads/Uses: /fpu
''    +Writes: fpu
''      Calls: I2C_Driver--->I2C.PingDeviceAt
'-------------------------------------------------------------------------

  fpu := addr
  okay := I2C.Init(sda, scl)

  if okay == true
    okay := I2C.PingDeviceAt(fpu)        

  return okay
'-------------------------------------------------------------------------  


PUB Reset : ackBit
'-------------------------------------------------------------------------
'---------------------------------┌───────┐-------------------------------
'---------------------------------│ Reset │-------------------------------
'---------------------------------└───────┘-------------------------------
'-------------------------------------------------------------------------
''     Action: Causes a Software Reset of the FPU                                                      
'' Parameters: None                                         
''    Results: None                             
''+Reads/Uses: /fpu
''    +Writes: None
''      Calls: I2C_Driver--->I2C.WriteByteTo
'-------------------------------------------------------------------------
  'FPU I2C software reset
  ackBit := I2C.WriteByteTo(fpu, _1, 0) 'Zero to reg1 causes Sotware Reset
  waitcnt(_RESETDELAY + cnt)            'Wait 10 ms (>8 ms)
'-------------------------------------------------------------------------


PUB Wait | i2cData
'-------------------------------------------------------------------------
'--------------------------------┌──────┐---------------------------------
'--------------------------------│ Wait │---------------------------------
'--------------------------------└──────┘---------------------------------
'-------------------------------------------------------------------------
''     Action: Waits for FPU ready                                                      
'' Parameters: None                                         
''    Results: None                             
''+Reads/Uses: /fpu
''    +Writes: None
''      Calls: I2C_Driver--->I2C.ReadByteFrom
'-------------------------------------------------------------------------
  i2cData := I2C.ReadByteFrom(fpu, _0)
  repeat until (i2cData == 0)
    i2cData := I2C.ReadByteFrom(fpu, _0)
'-------------------------------------------------------------------------

  
PUB ReadSyncChar : syncChar | ackBits
'-------------------------------------------------------------------------
'-----------------------------┌──────────────┐----------------------------
'-----------------------------│ ReadSyncChar │----------------------------
'-----------------------------└──────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Reads Syncronization Character from FPU                             
'' Parameters: None                      
''    Results: Sync Char (Should be $5C:decimal 92) 
''+Reads/Uses: /_SYNC   
''    +Writes: None        
''      Calls: WriteCmd, ReadByte
''       Note: No Wait here before ReadByte
'-------------------------------------------------------------------------
  ackBits := WriteCmd(_SYNC)  
  syncChar := ReadByte
                    
  return syncChar  
'-------------------------------------------------------------------------



PUB ReadInterVar(index) : intVar | ackBits
'-------------------------------------------------------------------------
'-----------------------------┌──────────────┐----------------------------
'-----------------------------│ ReadInterVar │----------------------------
'-----------------------------└──────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Reads an Internal Variable                                                      
'' Parameters: Index of variable                                         
''    Results: Internal Variable                             
''+Reads/Uses: /_READVAR, _LREAD0
''    +Writes: None
''      Calls: WriteCmdByte, Wait, ReadReg
'-------------------------------------------------------------------------
  ackBits := WriteCmdByte(_READVAR, index)
  Wait
  ackBits := WriteCmd(_LREAD0)
  intVar := ReadReg 
  
  return intVar
'-------------------------------------------------------------------------


PUB ReadRaFloatAsStr(format) : strPtr | ackBits
'-------------------------------------------------------------------------
'-----------------------------┌──────────────────┐------------------------
'-----------------------------│ ReadRaFloatAsStr │------------------------
'-----------------------------└──────────────────┘------------------------
'-------------------------------------------------------------------------
''     Action: Reads the float value from Reg[A] as string into the string
''             buffer of the FPU then loads it into HUB                           
'' Parameters: Format of string in FPU convention        
''    Results: strPtr pointer to string in HUB
''+Reads/Uses: /_FTOA, _FTOAD, _READSTR   
''    +Writes: None        
''      Calls: WriteCmdByte, Wait, WriteCmd, ReadStr
'-------------------------------------------------------------------------
  ackBits := WriteCmdByte(_FTOA, format)
  waitcnt(_FTOAD + cnt)
  Wait
  ackBits := WriteCmd(_READSTR)
  strPtr := ReadStr
  
  return strPtr
'-------------------------------------------------------------------------

  
PUB ReadRaLongAsStr(format) : strPtr | ackBits
'-------------------------------------------------------------------------
'---------------------------┌─────────────────┐---------------------------
'---------------------------│ ReadRaLongAsStr │---------------------------
'---------------------------└─────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Reads the long value from Reg[A] as string into the string
''             buffer of the FPU then loads it into HUB                           
'' Parameters: Format of string in FPU convention        
''    Results: strPtr pointer to string in HUB
''+Reads/Uses: /_LTOA, _FTOAD, _READSTR   
''    +Writes: None        
''      Calls: WriteCmdByte, Wait, WriteCmd, ReadStr
'-------------------------------------------------------------------------
  ackBits := WriteCmdByte(_LTOA, format)
  waitcnt(_FTOAD + cnt)
  Wait
  ackBits := WriteCmd(_READSTR)
  strPtr := ReadStr
  
  return strPtr
'-------------------------------------------------------------------------


PUB WriteCmd(cmd) : ackBit
'-------------------------------------------------------------------------
'------------------------------┌──────────┐-------------------------------
'------------------------------│ WriteCmd │-------------------------------
'------------------------------└──────────┘-------------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte to FPU                           
'' Parameters: Command byte                      
''    Results: ACK bits
''+Reads/Uses: /fpu    
''    +Writes: None        
''      Calls: I2C_Driver--->I2C.WriteByteTo
'-------------------------------------------------------------------------
  ackBit := I2C.WriteByteTo(fpu, _0, cmd)

  return ackBit
'-------------------------------------------------------------------------

  
PUB WriteCmdByte(cmd, b) : ackBits
'-------------------------------------------------------------------------
'-----------------------------┌──────────────┐----------------------------
'-----------------------------│ WriteCmdByte │----------------------------
'-----------------------------└──────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte + Data byte to FPU                           
'' Parameters: Command byte, Data byte                      
''    Results: ACK bits
''+Reads/Uses: /fpu    
''    +Writes: None        
''      Calls: I2C_Driver--->I2C.Write2BytesTo
'-------------------------------------------------------------------------
  ackBits := I2C.Write2BytesTo(fpu, _0, cmd, b)
  
  return ackBits
'-------------------------------------------------------------------------

  
PUB WriteCmd2Bytes(cmd, b1, b2) : ackBits
'-------------------------------------------------------------------------
'----------------------------┌────────────────┐---------------------------
'----------------------------│ WriteCmd2Bytes │---------------------------
'----------------------------└────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte + 2 Data bytes to FPU                           
'' Parameters: Command byte, 2 Data bytes                      
''    Results: ACK bits
''+Reads/Uses: /fpu    
''    +Writes: None        
''      Calls: I2C_Driver--->I2C.Write3BytesTo
'-------------------------------------------------------------------------
  ackBits := I2C.Write3BytesTo(fpu, _0, cmd, b1, b2)

  return ackBits
'-------------------------------------------------------------------------
  

PUB WriteCmd3Bytes(cmd, b1, b2, b3) : ackBits
'-------------------------------------------------------------------------
'-----------------------------┌────────────────┐--------------------------
'-----------------------------│ WriteCmd3Bytes │--------------------------
'-----------------------------└────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte + 3 Data bytes to FPU                           
'' Parameters: Command byte, 3 Data bytes                      
''    Results: ACK bits
''+Reads/Uses: /fpu    
''    +Writes: None        
''      Calls: I2C_Driver--->I2C.Write4BytesTo
'-------------------------------------------------------------------------
  ackBits := I2C.Write4BytesTo(fpu, _0, cmd, b1, b2, b3)

  return ackBits
'-------------------------------------------------------------------------


PUB WriteCmd4Bytes(cmd, b1, b2, b3, b4) : ackBits
'-------------------------------------------------------------------------
'-----------------------------┌────────────────┐--------------------------
'-----------------------------│ WriteCmd4Bytes │--------------------------
'-----------------------------└────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte + 4 Data bytes to FPU                           
'' Parameters: Command byte, 4 Data bytes                      
''    Results: ACK bits
''+Reads/Uses: /fpu    
''    +Writes: None        
''      Calls: I2C_Driver--->I2C.Write5BytesTo
'-------------------------------------------------------------------------
  ackBits := I2C.Write5BytesTo(fpu, _0, cmd, b1, b2, b3, b4)                    
    
  return ackbits
'-------------------------------------------------------------------------


PUB WriteCmdLong(cmd, longVal) : ackBits | b1, b2, b3, b4
'-------------------------------------------------------------------------
'------------------------------┌──────────────┐---------------------------
'------------------------------│ WriteCmdLong │---------------------------
'------------------------------└──────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte + Long (32 bit) Data to FPU                           
'' Parameters: Command byte, Long Data                      
''    Results: ACK bits
''+Reads/Uses: /fpu    
''    +Writes: None        
''      Calls: I2C_Driver--->I2C.Write5BytesTo
'-------------------------------------------------------------------------

  b4 := longVal & $000000FF
  b3 := (longVal ->= 8) & $000000FF
  b2 := (longVal ->= 8) & $000000FF
  b1 := (longVal ->= 8) & $000000FF    
  ackBits := I2C.Write5BytesTo(fpu, _0, cmd, b1, b2, b3, b4)

  return ackBits
'-------------------------------------------------------------------------
  
  
PUB WriteCmdFloat(cmd, floatVal) : ackBits | b1, b2, b3, b4
'-------------------------------------------------------------------------
'-----------------------------┌───────────────┐---------------------------
'-----------------------------│ WriteCmdFloat │---------------------------
'-----------------------------└───────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte + Float (32 bit) Data to FPU                           
'' Parameters: Command byte, Float Data                      
''    Results: ACK bits
''+Reads/Uses: /fpu    
''    +Writes: None        
''      Calls: I2C_Driver--->I2C.Write5BytesTo
'-------------------------------------------------------------------------
  b4 := floatVal & $000000FF
  b3 := (floatVal ->= 8) & $000000FF
  b2 := (floatVal ->= 8) & $000000FF
  b1 := (floatVal ->= 8) & $000000FF    
  ackBits := I2C.Write5BytesTo(fpu, _0, cmd, b1, b2, b3, b4)

  return ackBits
'-------------------------------------------------------------------------


PUB WriteCmdRnLong(cmd, regN, longVal) : ackBits | b1, b2, b3, b4
'-------------------------------------------------------------------------
'---------------------------┌────────────────┐---─------------------------
'---------------------------│ WriteCmdRnLong │----------------------------
'---------------------------└────────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte + RegNo byte + Long Data to FPU                          
'' Parameters: Command byte, RegNo byte, Long (32 bit) Data                      
''    Results: ACK bits
''+Reads/Uses: /fpu    
''    +Writes: None        
''      Calls: I2C_Driver--->I2C.Write6BytesTo
'-------------------------------------------------------------------------
  b4 := longVal & $000000FF
  b3 := (longVal ->= 8) & $000000FF
  b2 := (longVal ->= 8) & $000000FF
  b1 := (longVal ->= 8) & $000000FF 
  ackBits := I2C.Write6BytesTo(fpu, _0, cmd, regN, b1, b2, b3, b4)

  return ackBits
'-------------------------------------------------------------------------


PUB WriteCmdRnFloat(cmd, regN, floatVal) : ackBits | b1, b2, b3, b4
'-------------------------------------------------------------------------
'---------------------------┌─────────────────┐---------------------------
'---------------------------│ WriteCmdRnFloat │---------------------------
'---------------------------└─────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte + RegNo byte + Float Data to FPU                          
'' Parameters: Command byte, RegNo byte, Float (32 bit) Data                      
''    Results: ACK bits
''+Reads/Uses: /fpu    
''    +Writes: None        
''      Calls: I2C_Driver--->I2C.Write6BytesTo
'-------------------------------------------------------------------------
  b4 := floatVal & $000000FF
  b3 := (floatVal ->= 8) & $000000FF
  b2 := (floatVal ->= 8) & $000000FF
  b1 := (floatVal ->= 8) & $000000FF 
  ackBits := I2C.Write6BytesTo(fpu, _0, cmd, regN, b1, b2, b3, b4)

  return ackBits
'-------------------------------------------------------------------------


PUB WriteCmdCntLongs(cmd, cntr, longPtr) : ackBits
'-------------------------------------------------------------------------
'---------------------------┌──────────────────┐--------------------------
'---------------------------│ WriteCmdCntLongs │--------------------------
'---------------------------└──────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command + Counter byte + Long Data array into FPU                          
'' Parameters: Command byte, Counter, Pointer to Long (32 bit) Data array                      
''    Results: ACK bits
''+Reads/Uses: /fpu    
''    +Writes: None        
''      Calls: I2C_Driver--->I2C.Write2BytesRegsTo
''       Note: Counter byte is the size of the Long data array
'-------------------------------------------------------------------------
  ackBits := I2C.Write2BytesRegsTo(fpu, _0, cmd, cntr, longPtr)

  return ackBits
'-------------------------------------------------------------------------


PUB WriteCmdCntFloats(cmd, cntr, floatPtr) : ackBits
'-------------------------------------------------------------------------
'--------------------------┌───────────────────┐--------------------------
'--------------------------│ WriteCmdCntFloats │--------------------------
'--------------------------└───────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command + Counter byte + Float Data array into FPU                          
'' Parameters: Command byte, Counter, Pointer to Float (32 bit) Data array                      
''    Results: ACK bits
''+Reads/Uses: /fpu    
''    +Writes: None        
''      Calls: I2C_Driver--->I2C.Write2BytesRegsTo
''       Note: Counter byte is the size of the Float data array
'-------------------------------------------------------------------------
  ackBits := I2C.Write2BytesRegsTo(fpu, _0, cmd, cntr, floatPtr)

  return ackBits
'-------------------------------------------------------------------------

  
PUB WriteCmdStr(cmd, strPtr) : ackBits | char, cntr
'-------------------------------------------------------------------------
'-------------------------------┌─────────────┐---------------------------
'-------------------------------│ WriteCmdStr │---------------------------
'-------------------------------└─────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte + a String into FPU                          
'' Parameters: Command byte + Pointer to String                      
''    Results: ACK bits
''+Reads/Uses: /fpu, chars    
''    +Writes: chars        
''      Calls: I2C_Driver--->I2C.WriteByteStrTo
'-------------------------------------------------------------------------
  cntr := 0
  repeat
    char := byte[strPtr][cntr]
    chars[cntr++] := char
  until (char == 0)
       
  ackBits := I2C.WriteByteStrTo(fpu, _0, cmd, @chars)
  
  return ackBits
'-------------------------------------------------------------------------


PUB ReadByte : byteVal
'-------------------------------------------------------------------------
'--------------------------------┌──────────┐-----------------------------
'--------------------------------│ ReadByte │-----------------------------
'--------------------------------└──────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Reads a byte from the FPU                                                      
'' Parameters: None                                         
''    Results: Byte value                             
''+Reads/Uses: /_READDELAY, fpu
''    +Writes: None
''      Calls: I2C_Driver--->I2C.ReadByteFrom
'-------------------------------------------------------------------------
  waitcnt(_READDELAY+cnt)
  byteVal := I2C.ReadByteFrom(fpu, _0)       

  return byteVal
'-------------------------------------------------------------------------


PUB ReadReg : longVal
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ ReadReg │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Reads a 32 bit value from the FPU                                                      
'' Parameters: None                                         
''    Results: 32 bit value                             
''+Reads/Uses: /_READDELAY, fpu
''    +Writes: None
''      Calls: I2C_Driver--->I2C.ReadRegFrom
'-------------------------------------------------------------------------
  waitcnt(_READDELAY+cnt)
  longVal := I2C.ReadRegFrom(fpu, _0)

  return longVal
'-------------------------------------------------------------------------


PUB ReadRegs(regX, cntr, floatPtr) | i                                    
'-------------------------------------------------------------------------
'--------------------------------┌──────────┐-----------------------------
'--------------------------------│ ReadRegs │-----------------------------
'--------------------------------└──────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Reads 32 bit Registers from FPU starting from Reg[X]                           
'' Parameters: Reg[X], Number of registers to read, pointer to HUB address
''             of register array                      
''    Results: FPU registers from Reg[X] stored in HUB sequentially
''+Reads/Uses: None
''    +Writes: None    
''      Calls: None
'-------------------------------------------------------------------------
  I2C.Write2BytesTo(fpu, _0, _SELECTX, regX)
  Wait
  I2C.Write2BytesTo(fpu, _0, _RDBLK, cntr)
  repeat i from 0 to (cntr - 1)
    long[floatPtr + 4 * i] := ReadReg
'-------------------------------------------------------------------------


PUB ReadStr : strPtr
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ ReadStr │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Reads a String from the FPU                                                      
'' Parameters: None                                         
''    Results: Pointer to String in HUB memory                             
''+Reads/Uses: /_READDELAY, fpu
''    +Writes: None
''      Calls: I2C_Driver--->I2C.ReadStrFrom
'-------------------------------------------------------------------------
  waitcnt(_READDELAY+cnt)
  strPtr := I2C.ReadStrFrom(fpu, _0)

  return strPtr
'-------------------------------------------------------------------------


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