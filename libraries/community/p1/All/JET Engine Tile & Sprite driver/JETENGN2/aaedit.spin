''Anti-aliasing table editor

CON

_clkmode = xtal1 + pll16x
_xinfreq = 5_000_000
 NUM_LINES = gfx#NUM_LINES
_stack   = 128 
_free    = ($8000-gfx#text_colors+3)/4 

 SCANLINE_BUFFER = gfx#SCANLINE_BUFFER
                                               
 request_scanline       = gfx#request_scanline 'address of scanline buffer for TV driver    
 border_color           = gfx#border_color 'address(!) of border color
 oam_adr                = gfx#oam_adr 'address of where sprite attribs are stored
 oam_in_use             = gfx#oam_in_use 'OAM adress feedback
 debug_shizzle          = gfx#debug_shizzle 'used for debugging, sometimes
 text_colors            = gfx#text_colors 'adress of text colors
 first_subscreen        = gfx#first_subscreen 'pointer to first subscreen
 buffer_attribs         = gfx#buffer_attribs 'array of 8 bytes
 aatable                = gfx#aatable 'array of 32 bytes
 aatable8               = gfx#aatable8 'array of 16 bytes
 text_colors            = gfx#text_colors 'array of 16 longs

 num_sprites    = gfx#num_sprites

VAR

OBJ

gfx : "JET_v02.spin"
kb  : "Keyboard"



VAR

long table_screen[16*8]
long title_screen[16*4]
long mode_screens[16*4]
long editor_screen[16*4]
byte cur_mode
byte colnow       
byte startchar
byte aaedit

PUB main | tileset_aligned, y, k, x, oam_length,s,t
  bytemove(aatable,@aatabvals,32)
  bytemove(aatable8,@aatab8vals,16)                     
  'pst.start(115_200)
  kb.start(8,9)
        
 
  tiletest(true)
  'longfill(@screen,%0000___000000_______0000_0__0_________0000___000001_______0000_0___0,32*12)

  word[first_subscreen] := @title_sub
  word[@title_sub+2] := @mode_sub
  word[oam_adr] := @oam1
  longmove(text_colors,@text_colos,16)
  word[@title_sub+12] := @title_screen
  word[@mode_sub+12] := @mode_screens
  word[@table_sub+12] := @table_screen
  word[@editor_sub+12] := @editor_screen
  word[@editor_sub+2] := @table_sub

  setmode(cur_mode)

  repeat x from 0 to 127
    k := byte[@title_str+x]
    word[@title_screen+(x<<1)] := $8000+((k>>1)<<7)+ ((k&1))
  repeat x from 0 to 127
    k := byte[@mode_strs+x]
    word[@mode_screens+(x<<1)] := $8000+((k>>1)<<7)+ ((k&1))
  
        
  ''set up graphics driver
  gfx.start(%001_0101,%00) 'start graphics driver
  oam_length := @oam1-@oam1_end
  repeat
    gfx.wait_vsync
    repeat 100

    if kb.keystate($C0)
      word[@table_sub+6] -= 2
    if kb.keystate($C1)
      word[@table_sub+6] += 2
  
    k := kb.key
    case k
      $09: 'Tab
        cur_mode := (cur_mode+1)&3
        setmode(cur_mode)
        aaedit~
        
      $C0: 'left
        'startchar--
        'word[@table_sub+6] -= 2
        k~
      $C1: 'right
        'startchar++
        'word[@table_sub+6] += 2
        k~
      $C2: 'up
        colnow--
      $C3: 'down
        colnow++
      $C4: 'home
        aaedit := (aaedit -1)&lookupz(cur_mode:15,31,0,0)
      $C5: 'end
        aaedit := (aaedit +1)&lookupz(cur_mode:15,31,0,0)
      $C6: 'page up
        if cur_mode
          byte[aatable+aaedit] := (byte[aatable+aaedit] -4)&(31<<2)
        else
          byte[aatable8+aaedit] := (byte[aatable8+aaedit] -4)&(31<<2)                     
      $C7: 'page down
        if cur_mode
          byte[aatable+aaedit] := (byte[aatable+aaedit] +4)&(31<<2)
        else
          byte[aatable8+aaedit] := (byte[aatable8+aaedit] +4)&(31<<2)
    if k
      tiletest (false)

PUB setmode(m)
  word[@table_sub+8] := ((m&7)<<1)+1
  word[@table_sub+16] := lookupz(m:16,32,16,32)<<2
  word[@table_sub+18] := lookupz(m:4,5,4,5)+2
  word[@table_sub+20] := lookupz(m:3,4,4,5)
  word[@mode_sub+4] := m<<3

  case m
    1:
      word[@mode_sub+2] := @editor_sub
      word[@table_sub+0] := 104
      word[@table_sub+4] := -104
    0:
      word[@mode_sub+2] := @editor_sub
      word[@table_sub+0] := 72
      word[@table_sub+4] := -72
    other:
      word[@mode_sub+2] := @table_sub
      word[@table_sub+0] := 40
      word[@table_sub+4] := -40
       
  

PUB tiletest(init) |  tbptr,y, x,b0,b1,c,n

repeat y from 0 to 7
  repeat x from 0 to 15
    c:= colnow &$f
    'b0 := test_str.byte[(x<<1)+((y-10)<<6)]
    b0 := ((x+((y-8)*16))*2 + startchar)&$FF
    'b1 := test_str.byte[(x<<1)+((y-10)<<6)+1]
    b1 := ((x+((y-8)*16))*2 + startchar +1)&$FF
    table_screen.word[(x<<1)+(y<<5)] := $8000+((b0>>1)<<7)+ ((b0&1)) + (c<<2)
    table_screen.word[(x<<1)+(y<<5)+1] := $8000+((b1>>1)<<7)+ ((b1&1)) + (c<<2)
   
  if cur_mode
    tbptr := aatable
  else
    tbptr := aatable8
   
repeat y from 0 to 3
   repeat x from 0 to 15
      
         if x&1
           b0 := hexchars.byte[byte[tbptr+(((x>>1)+((y-0)<<3)))]>>2]
           b1 := " "
         else
           b0 := hexchars.byte[((x>>1)+((y-0)<<3))>>1]
           if x&%10
            b1 := "t"
           else
            b1 := "b"
           
         c := 0 + (3&((x>>1)+((y-0)<<3) == aaedit))
         
         editor_screen.word[(x<<1)+(y<<5)] := $8000+((b0>>1)<<7)+ ((b0&1)) + (c<<2) 
         editor_screen.word[(x<<1)+(y<<5)+1] := $8000+((b1>>1)<<7)+ ((b1&1)) + (c<<2)
DAT


title_sub
word 0 'ystart
word 0  ' next 
word 0  ' yscroll
word 0  ' xscroll
word 0 ' mode
word 0  ' tile_base (must be 64-byte-aligned) (not needed in aaedit)
word 0  ' map_base (also gets set at run time)
word %11_1111_00 ' map_mask
word 16<<2 ' map_width in bytes (must be power of 2 for wraparound)
word 4+2 ' map_y_shift
word 3 'tile_height (well, technically log2(tile_height))

mode_sub
word 32 'ystart
word 0  ' next 
word 0  ' yscroll
word 0  ' xscroll
word 0 ' mode
word 0  ' tile_base (must be 64-byte-aligned) (not needed in aaedit)
word 0  ' map_base (also gets set at run time)
word %11_1111_00 ' map_mask
word 16<<2 ' map_width in bytes (must be power of 2 for wraparound)
word 4+2 ' map_y_shift
word 3 'tile_height (well, technically log2(tile_height))

table_sub
word 40 'ystart
word 0  ' next (none)
word -40 ' yscroll
word 0  ' xscroll
word 7 ' mode
word 0  ' tile_base (must be 64-byte-aligned) (not needed in aaedit)
word 0  ' map_base (also gets set at run time)
word %111_1111_00 ' map_mask
word 32<<2 ' map_width in bytes (must be power of 2 for wraparound)
word 5+2 ' map_y_shift
word 5 'tile_height (well, technically log2(tile_height))

editor_sub
word 40 'ystart
word 0  ' next (none)
word -40 ' yscroll
word 0  ' xscroll
word 4 ' mode
word 0  ' tile_base (must be 64-byte-aligned) (not needed in aaedit)
word 0  ' map_base (also gets set at run time)
word %111_1111_00 ' map_mask
word 16<<2 ' map_width in bytes (must be power of 2 for wraparound)
word 4+2 ' map_y_shift
word 4 'tile_height (well, technically log2(tile_height))

title_str
byte " JET ENGINE AntiAliasing Editor "
byte "Use Home/End/PgUp/PgDown to edit"
byte "Use Arrows to change preview    "
byte "Use TAB to switch modes         "
mode_strs
byte "  8-LINE ANTI-ALIASED TEXT MODE "
byte " 16-LINE ANTI-ALIASED TEXT MODE "
byte " 16-LINE  1:1         TEXT MODE "
byte " 32-LINE  2:1         TEXT MODE "

hexchars
byte "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"

''01213355
''789ACBED
''FGIHKJLM
''NOPQSSTU
aatabvals
byte  0<<2, 1<<2
byte  2<<2, 1<<2
byte  4<<2, 3<<2
byte  6<<2, 5<<2
byte  7<<2, 8<<2
byte  9<<2,10<<2   
byte 11<<2,12<<2
byte 14<<2,13<<2
byte 15<<2,16<<2
byte 18<<2,17<<2
byte 20<<2,19<<2
byte 22<<2,21<<2
byte 24<<2,23<<2
byte 25<<2,26<<2
byte 28<<2,28<<2
byte 29<<2,30<<2
''2467CBEF
''IHJLOQST
aatab8vals      
byte  2<<2, 4<<2
byte  6<<2, 7<<2
byte 12<<2,11<<2
byte 14<<2,15<<2
byte 18<<2,17<<2
byte 19<<2,21<<2
byte 24<<2,26<<2
byte 28<<2,29<<2


'org 0
oam1
oam1_enable    long %0
oam1_flip      long %0
oam1_mirror    long %0
oam1_yexpand    long %0
oam1_xexpand    long %0
oam1_solid     long %0
oam1_ypos      word 3[num_sprites]
oam1_xpos      word 2[num_sprites]
oam1_pattern   byte 2[num_sprites]
oam1_palette   byte 0[num_sprites]
oam1_end

text_colos
text_white     long $07_05_04_02
text_lessaa    long $07_04_03_02
text_grey      long $06_04_03_02
text_black     long $02_04_05_07
text_black2    long $02_05_06_07

text_red0      long $CC_CB_CA_02
text_red1      long $CD_CB_CA_02
text_red2      long $CE_CC_CB_02
text_red3      long $48_CC_CB_02

text_teal0     long $4C_4B_4A_02
text_teal1     long $4D_4B_4A_02
text_teal2     long $4E_4C_4B_02
'text_teal3    long $C8_4C_4B_02
text_or        long $07_07_07_02

text_and       long $07_02_02_02
text_xnor      long $02_07_07_02
'text_bold     long $07_07_03_02
'text_top      long $07_07_02_02
text_wtf       long $ED_6B_6A_02



{text_grey    long $06_03_03_02
text_white    long $07_03_03_02

text_white2   long $07_04_04_02
text_white3   long $07_05_05_02
text_noaa   long $07_02_02_02
text_or   long $07_07_07_02
text_t1   long $07_05_04_02
text_t2   long $07_04_05_02
text_rednew   long $CD_CC_CC_02

text_red    long $CD_CB_CB_02
'text_red2    long $48_CC_CC_02
text_purple    long $ED_EB_EB_02
'text_purple2    long $68_EC_EC_02
text_violet   long $0D_0B_0B_02
'text_violet2    long $88_0C_0C_02
text_blue   long $2D_2B_2B_02
'text_blue2    long $A8_2C_2C_02
text_teal   long $4D_4B_4B_02
'text_teal2    long $C8_4C_4C_02
text_green   long $6D_6B_6B_02
'text_green2    long $E8_6C_6C_02
text_yellow   long $8D_8B_8B_02
'text_yellow2    long $08_8B_8B_02}

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