'' JET ENGINE v2
'' (C)2019 IRQsome Software
'' TV output code
'' very loosley based on JT Cook's Ranquest driver (in turn based on TV.spin)
''
'' Specs:
'' Tilemap of 16x12 tiles
'' 32 Sprites per screen, lots of settings

''*****************************
''*  TV Driver v1.0           *
''*  (C) 2004 Parallax, Inc.  *
''*****************************

CON

  fntsc         = 3_579_545     'NTSC color frequency
  lntsc         = 3640          'NTSC color cycles per line * 16
  sntsc         = 624           'NTSC color cycles per sync * 16
  wntsc         = 5             'NTSC half-pixel width (for 256 pixel lines)

  fpal          = 4_433_618     'PAL60 color frequency
  lpal          = {4540}4508    'PAL60 color cycles per line * 16
  spal          = {848}773      'PAL60 color cycles per sync * 16
  wpal          = 6             'PAL60 half-pixel width (for 256 pixel lines)

  paramcount    = 20


 SCANLINE_BUFFER = $7800
 NUM_LINES = 224
 DISPLAY_LIST = SCANLINE_BUFFER - (32*4 + 36) ''$775C
 request_scanline       = DISPLAY_LIST-2      'address of scanline buffer for TV driver
 border_color           = DISPLAY_LIST-8 'border color      
 debug_shizzle          = DISPLAY_LIST-16
 buffer_attribs         = DISPLAY_LIST-28 'array of 8 bytes
VAR

  long  cogon, cog


PUB start(tvptr) : okay

'' Start TV driver - starts a cog
'' returns false if no cog available
''
''   tvptr = pointer to TV parameters

  stop                 
  okay := cogon := (cog := cognew(@entry,tvptr)) > 0


PUB stop

'' Stop TV driver - frees a cog

  if cogon~
    cogstop(cog)


DAT


'*******************************
'* Assembly language TV driver *
'*******************************

                        org
'
'
' Entry
'
entry

                        mov     taskptr,#tasks          'reset tasks

                        mov     x,#10                   'perform task sections initially
:init                   jmpret  taskret,taskptr
                        djnz    x,#:init
'
'
' Superfield
'
superfield              mov     taskptr,#tasks          'reset tasks

                        test    _mode,#%0001    wc      'if ntsc, set phaseflip
        if_nc           mov     phaseflip,#phasemask

                        test    _mode,#%0010    wz      'get interlace into z
'
'
' Field
'
field                   mov     x,vinv                  'do invisible back porch lines
:black                  'call   #hsync                  'do hsync
                        'waitvid burst,sync_high2       'do black
                        jmpret  taskret,taskptr         'call task section (z undisturbed)
                        djnz    x,#:black               'another black line?



                        ''Remark: interlaced mode currently unimplemented
                        mov pixels,#255
                        call #sendpixels
                        mov pixels,#0
                        call #sendpixels
                        mov pixels,bordercolour
                        shl pixels,#8
                        or pixels,#255
                        shl pixels,#8
                        or pixels,#1
                        shl pixels,#8
                        call #sendpixels
                        
                        

                        

                        {mov     current_line,#0
                        test    interlace,#1     wc
        if_z_and_c      mov     current_line,#1 
                        wrlong current_line,_nextline}

                        mov     x,vb                    'do visible back porch lines
                        call    #blank_lines
                        wrlong  visible,par     'unset VBLANK

                        'mov     y,_vt                   'set vertical tiles
nextline                mov     vx,#1                   'set vertical expand
                        wrword  line,_nextline
vert    'if_z           xor     interlace,#1            'interlace skip?
        'if_z           tjz     interlace,#lineskip
                        muxnz   z_store,#1

                        'call   #hsync                  'do hsync

                        'mov    vscl,hb                 'do visible back porch pixels
                        mov     ptr,_bordercolour
                        rdlong  bordercolour,ptr
                        xor     tile,bordercolour
                        'waitvid tile,#0

                        mov     t1,line         'add offset to line ptr
                        and     t1,#7
                        mov     t2,_tvbuffer_attribs
                        add     t2,t1
                        rdbyte  buffer_attrib,t2
                        shl     t1,#8
                        mov     ptr,_scanline
                        add     ptr,t1

                        rdlong ovls1,_ovls1_ptr 'handle overlay and sideborders (spaghetti-fied for speed)
                        add     _ovls1_ptr,#4
                        cmp     _ovls1_ptr,_ovls1_end wc,wz
                        rdlong  ovls2,_ovls2_ptr
        if_e            mov     _ovls1_ptr,_ovls1_start
                        add     _ovls2_ptr,#4
                        rdlong  scrollborder_pattern,_scrollborder_ptr
                        cmp     _ovls2_ptr,_ovls2_end wc,wz
        if_e            mov     _ovls2_ptr,_ovls2_start
                        add     _scrollborder_ptr,#4
                        cmp     _scrollborder_ptr,_scrollborder_end wc,wz
        if_e            mov     _scrollborder_ptr,_scrollborder_start

                        
        
                        
                        mov     x,#16                   'set horizontal frames
:nosmooth
                        shl     x,#2

                        mov pixels,#255
                        call #sendpixels
                        mov pixels,#0
                        call #sendpixels

                        mov     pixels,_bordercolour
                        shl     pixels,#8
                        or      pixels,buffer_attrib
                        shl     pixels,#16
                        call    #sendpixels

                        mov pixels,_borderpal
                        call #sendpixels
                        mov pixels,scrollborder_pattern
                        call #sendpixels
                        
                        and     buffer_attrib,#$80 wc,nr 'get text mode flag into c
                        
        if_c            jmp     #do_text

do_gfx
gfxloop                 rdlong pixels,ptr
                        add ptr,#4
ovli1_2                 and     pixels, ovls1 ''placeholder for screen filter
ovli2_2                 and     pixels, ovls2
                        call #sendpixels_int
                        djnz x,#gfxloop
                        call #endpixels
                        jmp #vis_done

                        
                        
do_text
textloop                rdlong pixels,ptr
                        add ptr,#4 
                        call #sendpixels_int
                        djnz x,#textloop
                        call #endpixels
                        'drop through to :vis_done
                        
                        
vis_done                neg pixels,#1
                        call #sendpixels

                        {add     current_line,#1
                        cmp     isinterlacedmode,#2    wc      'get interlace into z
        if_nc           add     current_line,#1
                        wrlong  current_line,_nextline}

                        and     z_store,#1 wz   'restore Z....
lineskip                muxnz   z_store,#1      '...and save it again? whatever.
                        djnz    vx,#vert                'vertical expand?
                        add     line,#1           'set next line
                        cmp     line,#NUM_LINES wc,wz   'done?
        if_b            jmp     #nextline         'no...

                        wrlong  invisible,par   'set VBLANK
                        'djnz    y,#nextline                 'another tile line?
                        
                        and     z_store,#1 wz   'restore Z....
        if_z            xor     interlace,#1    wz      'get interlace and field1 into z

                        test    _mode,#%0001    wc      'do visible front porch lines
                        mov     x,vf
        if_nz_and_c     add     x,#1
                        call    #blank_lines

                        mov     line,#0         'write zero into nextline.
                        wrword  line,_nextline

'        if_nz           wrlong  invisible,par           'unless interlace and field1, set status to invisible

        'if_z_eq_c      call    #hsync                  'if required, do short line
        if_z_eq_c       mov     vscl,hrest
        'if_z_eq_c      waitvid burst,sync_high2
        if_z_eq_c       xor     phaseflip,phasemask

                        'call   #vsync_high             'do high vsync pulses

                        'movs   vsync1,#sync_low1       'do low vsync pulses
                        'movs   vsync2,#sync_low2
                        'call   #vsync_low

                        'call   #vsync_high             'do high vsync pulses

        'if_nz          mov     vscl,hhalf              'if odd frame, do half line
        'if_nz          waitvid burst,sync_high2

        if_z            jmp     #field                  'if interlace and field1, display field2
                        jmp     #superfield             'else, new superfield
'
'
' Blank lines
'
blank_lines             'call   #hsync                  'do hsync

                        rdlong  bordercolour,_bordercolour
                        xor     tile,bordercolour
                        'waitvid tile,#0

                        djnz    x,#blank_lines
blank_lines_ret         ret



'
'
' Send 32 bits from pixels over serial.
'
sendpixels              call #sendpixels_int
endpixels               waitvid serial_allon,#0
                        or      outa,pin30
sendpixels_ret
endpixels_ret           ret
'
sendpixels_int          mov sitr,#4
:loop                   mov stmp,pixels
                        and     stmp,#$FF
                        shl     stmp,#2
                        or      stmp,#1
                        waitvid serial_pal,stmp
                        andn    outa,pin30
                        ror     pixels,#8
                        djnz sitr,#:loop
sendpixels_int_ret      ret

serial_pal              long $FF00FF00
serial_allon            long -1


'
'
' Horizontal sync
'
{hsync                  test    _mode,#%0001    wc      'if pal, toggle phaseflip
        if_c            xor     phaseflip,phasemask

                        mov     vscl,sync_scale1        'do hsync       
                        mov     tile,phaseflip
                        xor     tile,burst
                        waitvid tile,sync_normal

                        mov     vscl,hvis               'setup in case blank line
                        mov     tile,phaseflip

hsync_ret               ret }
'
'
' Vertical sync
'
{vsync_high             movs    vsync1,#sync_high1      'vertical sync
                        movs    vsync2,#sync_high2

vsync_low               mov     x,vrep

vsyncx                  mov     vscl,sync_scale1
vsync1                  waitvid burst,sync_high1

                        mov     vscl,sync_scale2
vsync2                  waitvid burst,sync_high2

                        djnz    x,#vsyncx
vsync_low_ret
vsync_high_ret          ret}
'
'
' Tasks - performed in sections during invisible back porch lines
'
tasks                   mov     t1,par                  'load parameters
                        movd    :par,#_enable           '(skip _status)
                        mov     t2,#paramcount - 1
:load                   add     t1,#4
:par                    rdlong  0,t1
                        add     :par,d0
                        djnz    t2,#:load               '+119


                        mov     vscl,serial_vscl
                        mov     vcfg,serial_vcfg
                        or      outa,pin30
                        or      dira,pin30

                        tjz     _enable,#disabled       '+2, disabled?

                        jmpret  taskptr,taskret         '+1=140, break and return later

                        movs    :rd,#wtab               'load ntsc/pal metrics from word table
                        movd    :wr,#hvis
                        mov     t1,#wtabx - wtab
                        test    _mode,#%0001    wc
:rd                     mov     t2,0
                        add     :rd,#1
        if_nc           shl     t2,#16
                        shr     t2,#16
:wr                     mov     0,t2
                        add     :wr,d0
                        djnz    t1,#:rd                 '+54

        if_nc           movs    :ltab,#ltab             'load ntsc/pal metrics from long table
        if_c            movs    :ltab,#ltab+1
                        movd    :ltab,#fcolor
                        mov     t1,#(ltabx - ltab) >> 1
:ltab                   mov     0,0
                        add     :ltab,d0s1
                        djnz    t1,#:ltab               '+17

                        rdlong  t1,#0                   'get CLKFREQ
                        shr     t1,#1                   'if CLKFREQ < 16MHz, cancel _broadcast
                        cmp     t1,m8           wc
        if_c            mov     _broadcast,#0
                        shr     t1,#1                   'if CLKFREQ < color frequency * 4, disable
                        cmp     t1,fcolor       wc
        if_c            jmp     #disabled               '+11

                        jmpret  taskptr,taskret         '+1=83, break and return later

                        mov     t1,fcolor               'set ctra pll to fcolor * 16
                        call    #divide                 'if ntsc, set vco to fcolor * 32 (114.5454 MHz)
                        test    _mode,#%0001    wc      'if pal, set vco to fcolor * 16 (70.9379 MHz)
                        movi    ctra,#%00001_111        'select fcolor * 16 output (ntsc=/2, pal=/1)
                        mov     frqa,t2                 '+147

                        jmpret  taskptr,taskret         '+1=148, break and return later

                        mov     t1,_broadcast           'set ctrb pll to _broadcast
                        mov     t2,#0                   'if 0, turn off ctrb
                        tjz     t1,:off
                        min     t1,m8                   'limit from 8MHz to 128MHz
                        max     t1,m128
                        mov     t2,#%00001_100          'adjust _broadcast to be within 4MHz-8MHz
:scale                  shr     t1,#1                   '(vco will be within 64MHz-128MHz)
                        cmp     m8,t1           wc
        if_c            add     t2,#%00000_001
        if_c            jmp     #:scale
:off                    'movi   ctrb,t2
                        call    #divide
                        'mov    frqb,t2                 '+165

                        jmpret  taskptr,taskret         '+1=166, break and return later

                        mov     t1,#16
                        mov     t2,_hx
                        call    #multiply
                        mov     hf,hvis
                        sub     hf,t1
                        shr     hf,#1           wc
                        mov     hb,_ho
                        addx    hb,hf
                        sub     hf,_ho                  '+52

                        mov     t1,#(NUM_LINES >> 4) 'compute vertical metrics
                        mov     t2,#1
                        call    #multiply
                        test    _mode,#%0010    wc      '(if interlace, halve lines)
        if_c            shr     t1,#1
                        mov     vf,vvis
                        sub     vf,t1
                        shr     vf,#1           wc
                        neg     vb,_vo
                        addx    vb,vf
                        add     vf,_vo                  '+48

                        xor     _mode,#%0010            '+1, flip interlace bit for display

                        jmpret  taskptr,taskret
                        
                                                        'prepare overlay/filter
                        movi    ovli1_2,_ovli1
                        movi    ovli2_2,_ovli2
'                       and     _scrollborder_end,_scrollborder_end wc
'             if_c      clkset clkreset
                        
                        
                        
:lasttask               jmpret  taskptr,taskret         '+1=112/160, break and return later

                        jmp     #:lasttask              '+1, keep loading colors
'
' Divide t1/CLKFREQ to get frqa or frqb value into t2
'
divide                  rdlong  m1,#0                   'get CLKFREQ

                        mov     m2,#32+1
:loop                   cmpsub  t1,m1           wc
                        rcl     t2,#1
                        shl     t1,#1
                        djnz    m2,#:loop

divide_ret              ret                             '+140
'
'
' Multiply t1 * t2 * 16 (t1, t2 = bytes)
'
multiply                shl     t2,#8+4-1

                        mov     m1,#8
:loop                   shr     t1,#1           wc
        if_c            add     t1,t2
                        djnz    m1,#:loop

multiply_ret            ret                             '+37

'
'
' Disabled - reset status, nap ~4ms, try again
'
disabled                mov     ctra,#0                 'reset ctra
                        mov     ctrb,#0                 'reset ctrb
                        mov     vcfg,#0                 'reset video


                        rdlong  t1,#0                   'get CLKFREQ
                        shr     t1,#8                   'nap for ~4ms
                        min     t1,#3
                        add     t1,cnt
                        waitcnt t1,#0

                        jmp     #entry                  'reload parameters
'
'
' Initialized data
'

bordercolour            long    $02

m8                      long    8_000_000
m128                    long    128_000_000
d0                      long    1 << 9 << 0
d6                      long    1 << 9 << 6
d0s1                    long    1 << 9 << 0 + 1 << 1
interlace               long    0
invisible               long    1
visible                 long    0
phaseflip               long    $00000000
phasemask               long    $F0F0F0F0
line                    long    $00000000
'test_pal              long $07_05_03_02
'lineinc                 long    $00000001
condition_bits          long    %1111<<18
pins0                   long    %11110000_01110000_00001111_00000111
pins1                   long    %11111111_11110111_01111111_01110111
sync_high1              long    %0101010101010101010101_101010_0101
sync_high2              long    %01010101010101010101010101010101       'used for black
sync_low1               long    %1010101010101010101010101010_0101
sync_low2               long    %01_101010101010101010101010101010

_scanline               long    SCANLINE_BUFFER 'buffer address read-only
_bordercolour           long    border_color 'long @border
_nextline               long    request_scanline 'line to fetch
_tvbuffer_attribs       long    buffer_attribs


serial_vcfg long (%%1<<29) | (0<<28) | (%011<<9) | (1<<6) ' 2 color output on pin 30
serial_vscl long (40<<12) | (40*10) ' 3 Mhz pixel clock, 10 pixels per waitvid
pin30       long 1<<30

'clkreset long 1<<7

'
'
' NTSC/PAL metrics tables
'                               ntsc                    pal
'                               ----------------------------------------------
wtab                    word    lntsc - sntsc,          lpal - spal     'hvis
                        word    lntsc / 2 - sntsc,      lpal / 2 - spal 'hrest
                        word    lntsc / 2,              lpal / 2        'hhalf
                        word    243,                    243{286}         'vvis
                        word    10,                     10{18}           'vinv
                        word    6,                      5{5}            'vrep
                        word    $02_7A,                 $02_AA          'burst
                        word    wntsc*2,                wpal*2          'hx
                        'VSCL values for GFX
                        {word   (wntsc<<13)+(wntsc*2),  (wpal<<13)+(wpal*2)
                        word    (wntsc<<13)+(wntsc*4),  (wpal<<13)+(wpal*4)
                        word    (wntsc<<13)+(wntsc*6),  (wpal<<13)+(wpal*6)
                        word    (wntsc<<13)+(wntsc*8),  (wpal<<13)+(wpal*8)
                        'VSCL values for Text
                        word    (wntsc<<12)+(wntsc*2),  (wpal<<12)+(wpal*2)
                        word    (wntsc<<12)+(wntsc*4),  (wpal<<12)+(wpal*4)
                        word    (wntsc<<12)+(wntsc*6),  (wpal<<12)+(wpal*6)
                        word    (wntsc<<12)+(wntsc*8),  (wpal<<12)+(wpal*8)
                        word    (wntsc<<12)+(wntsc*10), (wpal<<12)+(wpal*10)
                        word    (wntsc<<12)+(wntsc*12), (wpal<<12)+(wpal*12)
                        word    (wntsc<<12)+(wntsc*14), (wpal<<12)+(wpal*14)
                        word    (wntsc<<12)+(wntsc*16), (wpal<<12)+(wpal*16)}
                        
wtabx
ltab                    long    7_500_000                               'fcolor
                        long    7_500_000
                        long    sntsc >> 4 << 12 + sntsc                'sync_scale1
                        long    spal >> 4 << 12 + spal
                        long    67 << 12 + lntsc / 2 - sntsc            'sync_scale2
                        long    79 << 12 + lpal / 2 - spal
                        long    %0101_00000000_01_10101010101010_0101   'sync_normal
                        long    %010101_00000000_01_101010101010_0101
ltabx   
'
'
' Uninitialized data
'                               
taskptr                 res     1                       'tasks
taskret                 res     1
t1                      res     1
t2                      res     1
t3                      res     1
m1                      res     1
m2                      res     1

x                       res     1                       'display
'y                       res     1
hf                      res     1
hb                      res     1
vf                      res     1
vb                      res     1
'hx                     res     1
'hx_text                res     1
vx                      res     1
tile                    res     1
pixels                  res     1
stmp                    res     1
sitr                    res     1
pixscroll               res     1
'subscroll              res     1

hvis                    res     1                       'loaded from word table
hrest                   res     1
hhalf                   res     1
vvis                    res     1
vinv                    res     1
vrep                    res     1
burst                   res     1
_hx                     res     1

{hx_gfx_table                                           'Also loaded from word table (pixel width must be < 16 clocks)
hx_gfx_1                res     1
hx_gfx_2                res     1
hx_gfx_3                res     1
hx_gfx_4                res     1
hx_text_table
hx_text_2               res     1 
hx_text_4               res     1
hx_text_6               res     1
hx_text_8               res     1
hx_text_10              res     1 
hx_text_12              res     1 
hx_text_14              res     1 
hx_text_16              res     1}

fcolor                  res     1                       'loaded from long table
sync_scale1             res     1
sync_scale2             res     1
sync_normal             res     1
'
'
' Parameter buffer
'
_enable                 res     1       '0/non-0        read-only
_pins                   res     1       '%pppmmmm       read-only
_mode                   res     1       '%ccip          read-only
_ho                     res     1       '0+-            read-only
_vo                     res     1       '0+-            read-only
_broadcast              res     1       '0+             read-only
_auralcog               res     1       '0-7            read-only
_ovli1                  res     1
_ovls1_ptr              res     1
_ovls1_end              res     1
_ovls1_start            res     1
_ovli2                  res     1
_ovls2_ptr              res     1
_ovls2_end              res     1
_ovls2_start            res     1
_borderpal              res     1
_scrollborder_ptr       res     1
_scrollborder_end       res     1
_scrollborder_start     res     1                                  



ptr                     res     1
buffer_attrib           res     1
z_store                 res     1 ' A place to save Z...

'current_line            res     1
'isinterlacedmode        res     1


scrollborder_pattern    res     1
ovls1                   res     1
ovls2                   res     1


                        fit    ''496-49


''
''___
''VAR                   'TV parameters - 30 contiguous longs
''
'' 0  long  tv_status     '0/1/2 = off/invisible/visible           read-only
'' 1  long  tv_enable     '0/non-0 = off/on                        write-only
'' 2  long  tv_pins       '%pppmmmm = pin group, pin group mode    write-only
'' 3  long  tv_mode       '%ccip = chroma, interlace, ntsc/pal     write-only
'' 4  long  tv_hc         'horizontal count tiles                  write-only
'' 5  long  tv_vc         'vertical count tiles                    write-only
'' 6  long  tv_hx         'horizontal tile expansion               write-only
'' 7  long  tv_vx         'vertical tile expansion                 write-only
'' 8  long  tv_ho         'horizontal offset                       write-only
'' 9  long  tv_vo         'vertical offset                         write-only
''10  long  tv_broadcast  'broadcast frequency (Hz)                write-only
''11  long  tv_auralcog   'aural fm cog                            write-only
''12  long  tv_scanline   '256*8 bytes (64*8 longs) for display buffer write-only
''13  long  tv_bordercolour
''14  long  tv_nextline
''15  long  tv_DisplayList_ptr
''16  long  tv_vsync
''17  long  ovli1          
''19  long  ovls1_ptr   
''20  long  ovls1_end   
''21  long  ovls1_start 
''22  long  ovli2       
''23  long  ovls2_ptr   
''24  long  ovls2_end   
''25  long  ovls2_start 
''26  long  borderpal   
''27  long  scrollborder_ptr 
''28  long  scrollborder_end 
''29  long  scrollborder_start
''
''The preceding VAR section may be copied into your code.
''After setting variables, do start(@tv_status) to start driver.
''
''All parameters are reloaded each superframe, allowing you to make live
''changes. To minimize flicker, correlate changes with tv_status.
''
''Experimentation may be required to optimize some parameters.
''
''Parameter descriptions:
''  _________
''  tv_status
''
''    driver sets this to indicate status:
''      0: driver disabled (tv_enable = 0 or CLKFREQ < requirement)
''      1: currently outputting invisible sync data
''      2: currently outputting visible screen data
''  _________
''  tv_enable
''
''        0: disable (pins will be driven low, reduces power)
''    non-0: enable
''  _______
''  tv_pins
''
''    bits 6..4 select pin group:
''      %000: pins 7..0
''      %001: pins 15..8
''      %010: pins 23..16
''      %011: pins 31..24
''      %100: pins 39..32
''      %101: pins 47..40
''      %110: pins 55..48
''      %111: pins 63..56
''
''    bits 3..0 select pin group mode:
''      %0000: %0000_0111    -                    baseband
''      %0001: %0000_0111    -                    broadcast
''      %0010: %0000_1111    -                    baseband + chroma
''      %0011: %0000_1111    -                    broadcast + aural
''      %0100: %0111_0000    baseband             -
''      %0101: %0111_0000    broadcast            -
''      %0110: %1111_0000    baseband + chroma    -
''      %0111: %1111_0000    broadcast + aural    -
''      %1000: %0111_0111    broadcast            baseband
''      %1001: %0111_0111    baseband             broadcast
''      %1010: %0111_1111    broadcast            baseband + chroma
''      %1011: %0111_1111    baseband             broadcast + aural
''      %1100: %1111_0111    broadcast + aural    baseband
''      %1101: %1111_0111    baseband + chroma    broadcast
''      %1110: %1111_1111    broadcast + aural    baseband + chroma
''      %1111: %1111_1111    baseband + chroma    broadcast + aural
''      -----------------------------------------------------------
''            active pins    top nibble           bottom nibble
''
''      the baseband signal nibble is arranged as:
''        bit 3: chroma signal for s-video (attach via 560-ohm resistor)
''        bits 2..0: baseband video (sum 270/560/1100-ohm resistors to form 75-ohm 1V signal)
''
''      the broadcast signal nibble is arranged as:
''        bit 3: aural subcarrier (sum 560-ohm resistor into network below)
''        bits 2..0: visual carrier (sum 270/560/1100-ohm resistors to form 75-ohm 1V signal)
''  _______
''  tv_mode
''
''    bit 3 controls chroma mixing into broadcast:
''      0: mix chroma into broadcast (color)
''      1: strip chroma from broadcast (black/white)
''
''    bit 2 controls chroma mixing into baseband:
''      0: mix chroma into baseband (composite color)
''      1: strip chroma from baseband (black/white or s-video)
''
''    bit 1 controls interlace:
''      0: progressive scan (243 display lines for NTSC, 286 for PAL)
''           less flicker, good for motion
''      1: interlaced scan (486 display lines for NTSC, 572 for PAL)
''           doubles the vertical display lines, good for text
''
''    bit 0 selects NTSC or PAL format
''      0: NTSC
''           3016 horizontal display ticks
''           243 or 486 (interlaced) vertical display lines
''           CLKFREQ must be at least 14_318_180 (4 * 3_579_545 Hz)*
''      1: PAL
''           3692 horizontal display ticks
''           286 or 572 (interlaced) vertical display lines
''           CLKFREQ must be at least 17_734_472 (4 * 4_433_618 Hz)*
''
''      * driver will disable itself while CLKFREQ is below requirement
''  _____
''  tv_ht
''
''    horizontal number of 16 * 16 pixel tiles - must be at least 1
''    practical limit is 40 for NTSC, 50 for PAL
''  _____
''  tv_vt
''
''    vertical number of 16 * 16 pixel tiles - must be at least 1
''    practical limit is 13 for NTSC, 15 for PAL (26/30 max for interlaced NTSC/PAL)
''  _____
''  tv_hx
''
''    horizontal tile expansion factor - must be at least 3 for NTSC, 4 for PAL
''
''    make sure 16 * tv_ht * tv_hx + ||tv_ho + 32 is less than the horizontal display ticks
''  _____
''  tv_vx
''
''    vertical tile expansion factor - must be at least 1
''
''    make sure 16 * tv_vt * tv_vx + ||tv_vo + 1 is less than the display lines
''  _____
''  tv_ho
''
''    horizontal offset in ticks - pos/neg value (0 for centered image)
''    shifts the display right/left
''  _____
''  tv_vo
''
''    vertical offset in lines - pos/neg value (0 for centered image)
''    shifts the display up/down
''  ____________
''  tv_broadcast
''
''    broadcast frequency expressed in Hz (ie channel 2 is 55_250_000)
''    if 0, modulator is turned off - saves power
''
''    broadcasting requires CLKFREQ to be at least 16_000_000
''    while CLKFREQ is below 16_000_000, modulator will be turned off
''  ___________
''  tv_auralcog
''
''    selects cog to supply aural fm signal - 0..7
''    uses ctra pll output from selected cog
''
''    in NTSC, the offset frequency must be 4.5MHz and the max bandwidth +-25KHz
''    in PAL, the offset frequency is and max bandwidth vary by PAL type

{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                    TERMS OF USE: Parallax Object Exchange License                                            │                                                            
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