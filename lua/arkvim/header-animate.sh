#!/bin/bash
# ARKVIM art animation — colored blocks appear like bubbles, then show final static art.
# Reads cava gradient colors, falls back to tokyonight palette.

# === Parse cava colors ===
COLORS=()
CAVA_CFG="$HOME/.config/cava/config"
if [[ -f "$CAVA_CFG" ]]; then
  THEME=$(grep -oP "theme\s*=\s*\K\S+" "$CAVA_CFG" 2>/dev/null | tr -d "'")
  if [[ -n "$THEME" && -f "$HOME/.config/cava/themes/$THEME" ]]; then
    SRC="$HOME/.config/cava/themes/$THEME"
  else
    SRC="$CAVA_CFG"
  fi
  i=1
  while :; do
    c=$(grep -oP "gradient_color_$i\s*=\s*'\K[0-9a-fA-F]+" "$SRC" 2>/dev/null | head -1)
    [[ -z "$c" ]] && break
    COLORS+=("$c")
    i=$((i + 1))
  done
fi

# === Fallback tokyonight ===
if [[ ${#COLORS[@]} -eq 0 ]]; then
  COLORS=("7dcfff" "7aa2f7" "bb9af7" "f7768e" "ff9e64")
fi

NUM=${#COLORS[@]}
SEG=$((NUM - 1))

# === ARKVIM art lines ===
LINES=(
  "       █████╗ ██████╗ ██╗  ██╗██╗   ██╗██╗███╗   ███╗"
  "      ██╔══██╗██╔══██╗██║ ██╔╝██║   ██║██║████╗ ████║"
  "      ███████║██████╔╝█████╔╝ ██║   ██║██║██╔████╔██║"
  "      ██╔══██║██╔══██╗██╔═██╗ ╚██╗ ██╔╝██║██║╚██╔╝██║"
  "      ██║  ██║██║  ██║██║  ██╗ ╚████╔╝ ██║██║ ╚═╝ ██║"
  "      ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚═╝     ╚═╝"
)

WIDTH=57

# === Helper: color a single char ===
color_char() {
  local char="$1" col="$2"
  local seg_w=$((1000 / SEG))
  local t=$((col * 1000 / WIDTH))
  local idx=$((t / seg_w))
  local lt=$(((t - idx * seg_w) * 1000 / seg_w))
  if ((idx >= SEG)); then idx=$((SEG - 1)); lt=1000; fi
  local nxt=$((idx + 1))

  local h1="${COLORS[$idx]}" h2="${COLORS[$nxt]}"
  local r1=$((16#${h1:0:2})) g1=$((16#${h1:2:2})) b1=$((16#${h1:4:2}))
  local r2=$((16#${h2:0:2})) g2=$((16#${h2:2:2})) b2=$((16#${h2:4:2}))
  local r=$((r1 + (r2 - r1) * lt / 1000))
  local g=$((g1 + (g2 - g1) * lt / 1000))
  local b=$((b1 + (b2 - b1) * lt / 1000))

  printf "\e[38;2;%d;%d;%dm%s\e[0m" "$r" "$g" "$b" "$char"
}

# === Build list of (row, col, char) for block chars ===
declare -a ANIM_R ANIM_C ANIM_CH
idx=0
for ((row = 0; row < ${#LINES[@]}; row++)); do
  line="${LINES[$row]}"
  for ((col = 0; col < ${#line}; col++)); do
    ch="${line:$col:1}"
    if [[ "$ch" == "█" || "$ch" == "╔" || "$ch" == "╗" || "$ch" == "╚" || "$ch" == "╝" || "$ch" == "║" || "$ch" == "═" ]]; then
      ANIM_R[$idx]=$row
      ANIM_C[$idx]=$col
      ANIM_CH[$idx]="$ch"
      idx=$((idx + 1))
    fi
  done
done

TOTAL=$idx

# === Phase 1: bubble appear (random order, fast) ===
# Shuffle indices
SHUFFLE=($(shuf -i 0 $((TOTAL - 1)) 2>/dev/null || seq 0 $((TOTAL - 1))))

# Create off-screen buffer
BUF=()
for ((r = 0; r < ${#LINES[@]}; r++)); do
  BUF[$r]="$(printf '%*s' ${#LINES[$r]} '')"
done

# Clear screen, move to top
printf "\e[2J\e[H"
sleep 0.3

# Render empty frame
for ((r = 0; r < ${#LINES[@]}; r++)); do
  printf "\n"
done
printf "\e[%dA" "${#LINES[@]}"

# Gradually reveal characters
STEP=8
for ((i = 0; i < TOTAL; i += STEP)); do
  for ((j = 0; j < STEP && (i + j) < TOTAL; j++)); do
    si=${SHUFFLE[$((i + j))]}
    r=${ANIM_R[$si]}
    c=${ANIM_C[$si]}
    ch="${ANIM_CH[$si]}"
    # Update buffer
    BUF[$r]="${BUF[$r]:0:$c}$(color_char "$ch" "$c")${BUF[$r]:$((c + 1))}"
  done
  # Redraw
  printf "\e[%d;1H" "$((r + 2))"
  for ((rr = 0; rr < ${#LINES[@]}; rr++)); do
    printf "\r\e[2K%s" "${BUF[$rr]}"
    if ((rr < ${#LINES[@]} - 1)); then printf "\n"; fi
  done
  sleep 0.02
done

sleep 0.3

# === Phase 2: final static render ===
printf "\e[2J\e[H"
for ((row = 0; row < ${#LINES[@]}; row++)); do
  line="${LINES[$row]}"
  for ((col = 0; col < ${#line}; col++)); do
    ch="${line:$col:1}"
    if [[ "$ch" == " " ]]; then
      printf " "
    else
      color_char "$ch" "$col"
    fi
  done
  printf "\n"
done

# Keep alive (dashboard expects persistent output)
while true; do sleep 3600; done
