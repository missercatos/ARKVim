#!/bin/bash
art_file="$HOME/.config/nvim/art_current.txt"
color_file="$HOME/.config/nvim/logo_color.txt"

cat "$art_file"

# Read logo color from file (hex format like #e8b878)
color=$(cat "$color_file" 2>/dev/null)
if [ -n "$color" ]; then
  # Strip the # prefix
  hex="${color#\#}"
  r=$((16#${hex:0:2}))
  g=$((16#${hex:2:2}))
  b=$((16#${hex:4:2}))
  
  # ANSI: save cursor, move to row 19 col 35, set color, print logo, restore
  printf '\e[s\e[19;35H\e[38;2;%d;%d;%dmⒶⓇⓀ Ⓥⓘⓜ\e[0m\e[u' $r $g $b
fi
sleep .1
