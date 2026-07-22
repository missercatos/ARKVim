#!/bin/bash

# === 解析 cava 配色 ===
COLORS=()
CAVA_CFG="$HOME/.config/cava/config"
if [[ -f "$CAVA_CFG" ]]; then
  THEME=$(grep -oP "theme\s*=\s*'\K[^']*" "$CAVA_CFG" 2>/dev/null)
  if [[ -n "$THEME" && -f "$HOME/.config/cava/themes/$THEME" ]]; then
    SRC="$HOME/.config/cava/themes/$THEME"
  else
    SRC="$CAVA_CFG"
  fi
  i=1
  while :; do
    c=$(grep -oP "gradient_color_$i\s*=\s*'\K[^']*" "$SRC" 2>/dev/null | head -1)
    [[ -z "$c" ]] && break
    COLORS+=("${c:1}")
    i=$((i + 1))
  done
  if [[ ${#COLORS[@]} -eq 0 ]]; then
    fg=$(grep -oP "foreground\s*=\s*'\K[^']*" "$SRC" 2>/dev/null | head -1)
    [[ -n "$fg" ]] && COLORS+=("${fg:1}")
  fi
fi

# === tokyonight 回退配色 ===
if [[ ${#COLORS[@]} -eq 0 ]]; then
  COLORS=(
    "7dcfff"  # cyan
    "7aa2f7"  # blue
    "bb9af7"  # purple
    "f7768e"  # red
    "ff9e64"  # orange
  )
fi

NUM=${#COLORS[@]}
SEG=$((NUM - 1))

# === 渲染渐变 ARKVIM ===
lines=(
  " █████╗ ██████╗ ██╗  ██╗██╗   ██╗██╗███╗   ███╗"
  "██╔══██╗██╔══██╗██║ ██╔╝██║   ██║██║████╗ ████║"
  "███████║██████╔╝█████╔╝ ██║   ██║██║██╔████╔██║"
  "██╔══██║██╔══██╗██╔═██╗ ╚██╗ ██╔╝██║██║╚██╔╝██║"
  "██║  ██║██║  ██║██║  ██╗ ╚████╔╝ ██║██║ ╚═╝ ██║"
  "╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚═╝     ╚═╝"
)

width=57
seg_w=$((1000 / SEG))

for row in "${lines[@]}"; do
  for ((col = 0; col < ${#row}; col++)); do
    char="${row:$col:1}"
    if [[ "$char" == " " ]]; then
      printf " "
    else
      t=$((col * 1000 / width))
      idx=$((t / seg_w))
      lt=$(((t - idx * seg_w) * 1000 / seg_w))
      if ((idx >= SEG)); then
        idx=$((SEG - 1))
        lt=1000
      fi
      nxt=$((idx + 1))

      h1="${COLORS[$idx]}"
      h2="${COLORS[$nxt]}"
      r1=$((16#${h1:0:2})); g1=$((16#${h1:2:2})); b1=$((16#${h1:4:2}))
      r2=$((16#${h2:0:2})); g2=$((16#${h2:2:2})); b2=$((16#${h2:4:2}))
      r=$((r1 + (r2 - r1) * lt / 1000))
      g=$((g1 + (g2 - g1) * lt / 1000))
      b=$((b1 + (b2 - b1) * lt / 1000))

      printf "\e[38;2;%d;%d;%dm%s\e[0m" $r $g $b "$char"
    fi
  done
  printf "\n"
done
while true; do sleep 3600; done
