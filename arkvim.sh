#!/bin/bash
target="$HOME/.config/nvim"
if [-d"$target"]; then
  rm -rf "$target"
fi
mkdir -p "$target"
shopt -s dotglob
mv --*"$target"/
shopt -u dotglob
echo"完成"
