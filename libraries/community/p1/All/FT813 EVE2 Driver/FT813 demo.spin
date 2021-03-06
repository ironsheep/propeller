{{┌──────────────────────────────────────────┐
  │ FT813 demo                               │
  │ Author: Chris Gadd                       │
  │ Copyright (c) 2020 Chris Gadd            │
  │ See end of file for terms of use.        │
  └──────────────────────────────────────────┘

}}
CON
  _clkmode  = xtal1 + pll16x                                               
  _xinfreq  = 5_000_000

  _CS   = 19
  _MOSI = 18
  _MISO = 17
  _SCK  = 16
  
' Touch tags
  DIAL_TAG   = 1
  SLIDER_TAG = 2
  TOGGLE_TAG = 3
  CLEAR_TAG  = 4

VAR
  long  tracker_val,angle_val,slider_val,toggle_val
  byte  hh,mm,ss
  byte  text_string[12], last_key

OBJ
  disp : "FT813 driver"
  
PUB Main | char, x, y
  disp.Start(_CS,_MISO,_MOSI,_SCK)

   Shapes_demo
'  Widgets_demo

CON
  #1,   RED, GREEN, BLUE

VAR
  long  redXY, greenXY, blueXY
  byte  n0,n1,n2
  
PRI shapes_demo | i, temp

  redXY   := 240 << 16 | 100
  greenXY := 210 << 16 | 150
  blueXY  := 270 << 16 | 150
  n0 := RED
  n1 := GREEN
  n2 := BLUE
  
  disp.setMultiTouch
  drawCircles
  repeat
    repeat i from 0 to 2
      case disp.getTag(i)
        RED:
          redXY := disp.getTagCoords(i)
          temp := lookdownz(RED: n0,n1,n2)
          bytemove(@n1, @n0, temp)
          n0 := RED        
        GREEN:
          greenXY := disp.getTagCoords(i)
          temp := lookdownz(GREEN: n0,n1,n2)
          bytemove(@n1, @n0, temp)
          n0 := GREEN        
        BLUE:
          blueXY := disp.getTagCoords(i)
          temp := lookdownz(BLUE: n0,n1,n2)
          bytemove(@n1, @n0, temp)
          n0 := BLUE        
    drawCircles

PRI drawCircles | i
  disp.dlstart
  disp.color($FF_FF_FF)
  disp.circle(240,136,100)
  disp.alpha($80)
  repeat i from 2 to 0          ' Draw circles in order of oldest touched to most recently touched
    case n0[i]
      RED:
        disp.tag(RED)
        disp.color($FF_00_00)
        disp.circle(redXY >> 16, redXY & $FFFF,50)
      GREEN:
        disp.tag(GREEN)                                   
        disp.color($00_FF_00)                             
        disp.circle(greenXY >> 16, greenXY & $FFFF,50)    
      BLUE: 
        disp.tag(BLUE)                                 
        disp.color($00_00_FF)                          
        disp.circle(blueXY >> 16, blueXY & $FFFF,50)   
  disp.dlswap

PRI Widgets_demo  | delay_target                                                                             
  angle_val := $8000
  slider_val := $0
  hh := mm := ss := 0
  disp.set_clearColor($80_80_00)                        ' Set background color of display - color format is red_green_blue
                                                        '  Black or white backgrounds diminish the 3D effect of widgets
  disp.addPropFont($1000)                               ' Copy the PropFont into the FT813 RAM @ address $1000 (must be long aligned)
                                                        '  adding the PropFont requires ~3.5s at startup (Spin limitation)
  disp.dlstart                                          ' Short command list that simply tells the FT813 the location of the new font
  disp.setFont2(1,$1000,0)                              '  and the identifier to use with it
  disp.dlswap                                           
                                                        
  repeat
    case disp.touchTag                                
      TOGGLE_TAG:                                       ' Handle toggle switch
        if (tracker_val := disp.tracker) & $FF == TOGGLE_TAG  ' Ensure that currently-touched object is the one being tracked             
          toggle_val := tracker_val >> 16               ' Upper 16 bits contain the value, low 8 bits contain tag                         
          if toggle_val > 32768                         ' The toggle widget allows the full range of 0 to 65535
            toggle_val := 65535                         '  and is able to draw the handle at any position          
            delay_target := cnt + 10000
          else                                          ' For this demonstation, the handle snaps to full on or off
            toggle_val := 0

      SLIDER_TAG:                                       ' Handle slider          
        if (tracker_val := disp.tracker) & $FF == SLIDER_TAG
          slider_val := tracker_val >> 16                                        

      DIAL_TAG:                                         ' Handle dial            
        if (tracker_val := disp.tracker) & $FF == DIAL_TAG
          angle_val := tracker_val >> 16
          disp.set_clearColor((angle_val >> 8) << 16 | ((!angle_val >> 8) & $FF) << 8)

      CLEAR_TAG:                                        ' Handle clear button    
        bytefill(@text_string,0,12)

      "a" .. "d":                                       ' Handle keys, keys are automatically assigned a tag value of their ASCII character
        if disp.touchTag <> last_key
          text_string[strsize(@text_string)] := disp.touchTag ' Append key to string
          if strsize(@text_string) == 11                      ' Keep string in range
            bytemove(@text_string[0],@text_string[1],11)
          last_key := disp.touchTag
      other: last_key := 0
      
    if toggle_val > 32768                                            
      if cnt - delay_target > 0                                      
        delay_target += clkfreq / ((slider_val / 1000) #> 1)         
        if ss++ == 60                                                
          ss := 1                                                    
          if mm++ == 60                                              
            mm := 1                                                  
            if hh++ == 12                                            
              hh := 0                                                
    Display

PRI Display                                             
           
  disp.dlstart                                          ' Always begin with dlstart
  disp.clock(75,75,50,0,hh,mm,ss,0)
  disp.toggle(60,135,30,23,0,toggle_val,string("off",$FF,"on"),TOGGLE_TAG)

  disp.tag(0)                                           ' Need to change tag back to 0, else touching the progress bar would affect the toggle above
  disp.progress(25,170,100,25,0,slider_val,65535) '        x & y coords, width, height, options, value, max_value
  disp.slider(25,220,100,25,0,slider_val,65535,SLIDER_TAG)
    
  disp.tag(0)                                           ' Other solution is to keep all of the control objects at the end of the command list
  disp.gauge(200,75,50,0,5,10,angle_val,$FFFF)
  disp.dial(200,200,50,0,angle_val,DIAL_TAG)            ' create a dial at 200x200 radius 50, with 3D effect, set to angle, returns 2 when touched

  disp.tag(0)                                           
  disp.color($00_00_00)                                 ' create 3D effect around text box 
  disp.rect(259,24,180,50,5)
  disp.color($C0_C0_80)
  disp.rect(261,26,180,50,5)
  
  disp.color($00_20_40)                                 ' change color to dark blue - default background color of widgets
  disp.rect(260,25,180,50,5)                            ' Draw rectangle
  disp.color($FF_FF_FF)                                 ' change color back to white
  disp.text(270,30,30,0,@text_string)                   ' write text inside rectangle

  disp.keys(260,85,180,50,23,disp.touchTag,string("abcd")) ' create a row of keys labeled 'a' 'b' 'c' and 'd' | setting option to disp.touchTag creates a 'pressed' appearance
  disp.button(260,140,180,50,23,0,string("clear"),CLEAR_TAG) ' create a single button labeled 'clear'

  disp.text(290,235,1,0,string("PropFont!!!"))          ' PropFont was assigned to font ID 1

  disp.dlswap                                           ' Always end with dlswap
  