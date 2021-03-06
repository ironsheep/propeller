{{
────────────────────────────────────────────────────────────────────────────────────────
File: Map.spin
Version: 1.0
Copyright (c) 2012 Michael Daumling
See end of file for terms of use.

Map.spin is a simple string/value map that is organized as a simple, unbalanced tree.
It uses a user-defined buffer to store the map data. For efficiency, values are always
4 bytes.

Strings are Pascal-style strings, with the length as a byte prefix.

The memory, which must be LONG aligned, holds the max size in its first word, the
current size in its second word, and the root element offset as the third word.
Each element has the following structure:

  word  left, right             ' addresses of left and right subtree, 0 = none
  WORD  key                     ' the address or handle of the key ($8000 set = handle)
  WORD  value[2]

Since the S2 runs in the Tiny model, addresses fit into 16 bits.
        
────────────────────────────────────────────────────────────────────────────────────────
}}

CON
  DONT_CREATE   = 0             ' find: do not create
  DYNAMIC       = 1             ' find: allocate key on heap
  STATIC        = 2             ' find: key is static
  
CON
  HDR_HEAP      = 0             ' word index of heap to use for strings
  HDR_SIZEBYTES = 1             ' word index of size of buffer
  HDR_ROOT      = 2             ' word index of root element
  HDR_FREE      = 3             ' word index of free element chain
  HDR_FREE_CNT  = 4             ' number of free elements
  HDR_FREE_OFF  = 10            ' offset of first element
  
  ELEM_LEFT     = 0             ' word index of left subtree
  ELEM_RIGHT    = 1             ' word index of right subtree
  ELEM_KEY      = 2             ' word index of key handle
  ELEM_VALUE_LO = 3             ' word index of value's low 16 bits
  ELEM_VALUE_HI = 4             ' word index of value's high 16 bits

  HDR_SIZE      = 10            ' size of header
  ELEM_SIZE     = 10            ' size of an element

OBJ
  mem : "Heap"
  
PUB init(buf, sizeBytes, heap) | i, p
'
'' Initialize the entire map.
'' @buf       pointer to the map data buffer 
'' size       the size of that buffer in bytes
'' @heap      the heap to use for string allocations
'
  word[buf] := heap
  word[buf][HDR_ROOT] := 0
  word[buf][HDR_SIZEBYTES] := sizeBytes
  p := buf + HDR_FREE_OFF
  word[buf][HDR_FREE] := p
  ' set up the free chain
  i := (sizeBytes - HDR_FREE_OFF) / ELEM_SIZE
  word[buf][HDR_FREE_CNT] := i
  repeat i
    word[p] := p + ELEM_SIZE
    p += ELEM_SIZE
  word[p] := 0

PUB free_entries(buf)
'' Report the number of free entries left in this map
  result := word[buf][HDR_FREE_CNT]

PUB clear(buf)
'
'' Clear the entire map.
'' @ptr       pointer to the map data buffer 
'
  free_tree(buf, word[buf][HDR_ROOT])
  init(buf, word[buf][HDR_SIZEBYTES], word[buf])

PRI free_tree(buf, elem)
  if elem
    free_tree(buf, word[elem][ELEM_LEFT])
    free_tree(buf, word[elem][ELEM_RIGHT])
    free(buf, elem)
        
PUB get(buf, k) | elem
'
'' Get an element's value. Return the value or 0 if not found.
'' @buf       pointer to the map data buffer 
'' @k         the key
'
  ifnot word[buf][HDR_ROOT]
    return 0
  elem := find_elem(buf, word[buf][HDR_ROOT], k, 0, DONT_CREATE)
  if elem
    return value(elem)
  return 0
 
PUB put(buf, k, val) | elem
'
'' Put an element's value
'' @buf       pointer to the map data buffer 
'' @k         the key
'' val        the value
'
  ifnot word[buf][HDR_ROOT]
    elem := alloc(buf, k, DYNAMIC)
    word[buf][HDR_ROOT] := elem
  else
    elem := find_elem(buf, word[buf][HDR_ROOT], k, 0, DYNAMIC)
  set_value(elem, val)
 
PUB find(buf, k, create)
'
'' Find an element; create a new element if not found and create is not DONT_CREATE
'' return the element or 0 if not found. 
'' @buf       pointer to the map data buffer 
'' @k         the key
''  val       the value to store
'
  ifnot word[buf][HDR_ROOT]
    if create  
      result := alloc(buf, k, create)
      word[buf][HDR_ROOT] := result
  else
    result := find_elem(buf, word[buf][HDR_ROOT], k, 0, create)

PUB remove(buf, k) | elem, parent, child, l, r, i
'
'' Remove an element
'' @buf       pointer to the map data buffer 
'' @k         the key
'
  elem := word[buf][HDR_ROOT]
  ifnot elem
    return 0
  parent~
  elem := find_elem(buf, elem, k, @parent, DONT_CREATE)
  ifnot elem
    return
  if not word[elem][ELEM_LEFT]
    ' no left subtree: replace parent ptr with right subtree
    child := word[elem][ELEM_RIGHT]
    if parent
      if word[parent][ELEM_LEFT] == elem
        word[parent][ELEM_LEFT] := child
      else
        word[parent][ELEM_RIGHT] := child
    else
      word[buf][HDR_ROOT] := child
    free(buf, elem)
    
  elseifnot word[elem][ELEM_RIGHT]
    ' no right subtree: replace parent ptr with left subtree
    child := word[elem][ELEM_LEFT]
    if parent
      if word[parent][ELEM_LEFT] == elem
        word[parent][ELEM_LEFT] := child
      else
        word[parent][ELEM_RIGHT] := child
    else
      word[buf][HDR_ROOT] := child
    free(buf, elem)
    
  else
  ' In case the element that is to be deleted has two leaves,
  ' replace the element with the rightmost child of the left
  ' subtree, and delete the subtree element
  '
    l := word[elem][ELEM_LEFT]
    r := word[elem][ELEM_RIGHT]
    ifnot r
      ' no right subtree, replace left with this element
      bytemove(elem, l, ELEM_SIZE)
      word[elem][ELEM_LEFT] := word[l][ELEM_LEFT]
      free(buf, l)
      return
    ' if there is a right subtree, replace elem with the rightmost element
    parent := l
    repeat while word[r][ELEM_RIGHT]
      parent := r
      r := word[r][ELEM_RIGHT]
    bytemove(elem, r, ELEM_SIZE)
    word[parent][ELEM_RIGHT]~
    free(buf, r)

PUB root(buf)
'
'' Return the root element
'
  return word[buf][HDR_ROOT]

PUB left(elem)
'
'' return the left node of an element
'
  if elem
    result := word[elem][ELEM_LEFT]

PUB right(elem)
'
'' return the right node of an element
'
  if elem
    result := word[elem][ELEM_RIGHT]

PUB key_handle(elem)
'
'' return the key handle of an element; if $8000 is set, it is a memory handle
'
  if elem
    result := word[elem][ELEM_KEY]

PUB key_deref(buf, h)
'
'' Dereference the key handle of an element; if $8000 is set, it is a memory handle
'
  result := h
  if result & $8000
    result := mem.deref(word[buf], h & $7FFF)
    
PUB key(buf, elem)
'
'' Return the key of an element: The address may shift if the key is on the heap.
'
  if elem
    result := key_deref(buf, key_handle(elem))

PUB value(elem)
'
'' Return the value of an element
'
  if elem
    result := word[elem][ELEM_VALUE_LO] + (word[elem][ELEM_VALUE_HI] << 16)

PUB set_value(elem, val)
'
'' Set the value of an element
'
  if elem
    word[elem][ELEM_VALUE_LO] := val
    word[elem][ELEM_VALUE_HI] := val >> 16

  
PUB strcmp(str1, str2) | len1, len2, i
'
'' Compare two Pascal strings
'' Return > 0 if s1 is < s2, < 0 if s1 > s2
'' or 0 if the keys are the same
'
  len1 := byte[str1]
  len2 := byte[str2]
  repeat i from 0 to 255
    if len1 == i or len2 == i
      result := len1 - len2
      quit
    else
      result := BYTE[++str2] - BYTE[++str1]
      if result
        quit
        
PRI find_elem(buf, elem, k, parentp, create) | cmpres
'
' Find an element, and return that element if found after
' setting the parent ptr to the element's parent. If not
' found and create is not DONT_CREATE, create that element; otherwise,
' return 0. It is important to clear the parent location
' before calling the routine. This method is always called
' with elem <> 0.
'
  cmpres := strcmp(key(buf, elem), k)
  ifnot cmpres
    return elem
  if parentp
    word[parentp] := elem
  if cmpres < 0
    result := word[elem][ELEM_LEFT]
  else
    result := word[elem][ELEM_RIGHT]
  if result
    return find_elem(buf, result, k, parentp, create)
   
  if create
    ' element is not present
    result := alloc(buf, k, create)
    if result
      ' insert the element
      ifnot word [buf][HDR_ROOT]
        word [buf][HDR_ROOT] := result
      elseif cmpres < 0
        word[elem][ELEM_LEFT] := result
      else
        word[elem][ELEM_RIGHT] := result
     
PRI alloc(buf, k, cr) | p
'
' Allocate a new element. If no space is left,
' return 0, otherwise return the element.
'
  result := word[buf][HDR_FREE]
  if result
    word[buf][HDR_FREE] := word[result]
    bytefill(result, 0, ELEM_SIZE)
    if cr == DYNAMIC
      p := mem.alloc(word[buf], byte[k] + 1)
      bytemove(mem.deref(word[buf], p), k, byte[k] + 1)
      word[result][ELEM_KEY] := p | $8000
    else
      word[result][ELEM_KEY] := k
  word[buf][HDR_FREE_CNT]--

PRI free(buf, elem)
'
'' Release an element
'
  word[elem] := word[buf][HDR_FREE]
  word[buf][HDR_FREE] := elem
  if word[elem][ELEM_KEY] & $8000
    mem.free(word[buf], word[elem][ELEM_KEY] & $7FFF)
  word[buf][HDR_FREE_CNT]++

''=======[ License ]===========================================================
{{{
┌──────────────────────────────────────────────────────────────────────────────────────┐
│                            TERMS OF USE: MIT License                                 │                                                            
├──────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this  │
│software and associated documentation files (the "Software"), to deal in the Software │
│without restriction, including without limitation the rights to use, copy, modify,    │
│merge, publish, distribute, sublicense, and/or sell copies of the Software, and to    │
│permit persons to whom the Software is furnished to do so, subject to the following   │
│conditions:                                                                           │
│                                                                                      │
│The above copyright notice and this permission notice shall be included in all copies │
│or substantial portions of the Software.                                              │
│                                                                                      │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,   │
│INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A         │
│PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT    │
│HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF  │
│CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE  │
│OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                         │
└──────────────────────────────────────────────────────────────────────────────────────┘
}}