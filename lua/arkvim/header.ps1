<#
  ARKVim 启动页艺术字（Windows / PowerShell 版）

  与 header.sh 等效：渲染带渐变色的 ARKVIM ASCII 艺术字。
  Unix 上会去读 cava 配色；Windows 没有 cava，直接用 tokyonight 回退配色。
#>

$ErrorActionPreference = 'SilentlyContinue'
$OutputEncoding = [System.Text.Encoding]::UTF8

# tokyonight 回退配色（与 header.sh 一致）
$colors = @(
  '7dcfff', # cyan
  '7aa2f7', # blue
  'bb9af7', # purple
  'f7768e', # red
  'ff9e64'  # orange
)

$lines = @(
  '       █████╗ ██████╗ ██╗  ██╗██╗   ██╗██╗███╗   ███╗',
  '      ██╔══██╗██╔══██╗██║ ██╔╝██║   ██║██║████╗ ████║',
  '      ███████║██████╔╝█████╔╝ ██║   ██║██║██╔████╔██║',
  '      ██╔══██║██╔══██╗██╔═██╗ ╚██╗ ██╔╝██║██║╚██╔╝██║',
  '      ██║  ██║██║  ██║██║  ██╗ ╚████╔╝ ██║██║ ╚═╝ ██║',
  '      ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚═╝     ╚═╝'
)

$segments = $colors.Count - 1
$width = 57

function Get-Rgb([string]$hex) {
  @(
    [Convert]::ToInt32($hex.Substring(0, 2), 16),
    [Convert]::ToInt32($hex.Substring(2, 2), 16),
    [Convert]::ToInt32($hex.Substring(4, 2), 16)
  )
}

$rgb = $colors | ForEach-Object { , (Get-Rgb $_) }

$esc = [char]27

foreach ($row in $lines) {
  $sb = [System.Text.StringBuilder]::new()
  for ($col = 0; $col -lt $row.Length; $col++) {
    $ch = $row[$col]
    if ($ch -eq ' ') {
      [void]$sb.Append(' ')
      continue
    }

    $t = [int](($col * 1000) / $width)
    $segWidth = [int](1000 / $segments)
    $idx = [int]($t / $segWidth)
    $lt = [int]((($t - ($idx * $segWidth)) * 1000) / $segWidth)
    if ($idx -ge $segments) {
      $idx = $segments - 1
      $lt = 1000
    }
    $nxt = $idx + 1

    $c1 = $rgb[$idx]
    $c2 = $rgb[$nxt]
    $r = [int]($c1[0] + (($c2[0] - $c1[0]) * $lt / 1000))
    $g = [int]($c1[1] + (($c2[1] - $c1[1]) * $lt / 1000))
    $b = [int]($c1[2] + (($c2[2] - $c1[2]) * $lt / 1000))

    [void]$sb.Append("$esc[38;2;$r;$g;${b}m$ch$esc[0m")
  }
  Write-Host $sb.ToString()
}

# Snacks 的 terminal section 会等进程结束；保持一会儿让画面留着
Start-Sleep -Seconds 3600
