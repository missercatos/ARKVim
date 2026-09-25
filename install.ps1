<#
.SYNOPSIS
  ARKVim 一键安装（Windows）

.DESCRIPTION
  在 Windows 上装好 Neovim + ARKVim 配置，并把 nvim 加进用户 PATH，
  这样 cmd / PowerShell / Windows Terminal / Git Bash 里都能直接敲 nvim。

  默认会装：Neovim、ARKVim 配置、ripgrep、fd、JetBrainsMono Nerd Font。
  可选（-Tools）：各语言运行时与 LSP（node/python/go/rust/jdk/clang/cmake/ninja 等）。

  用法：
    # 一行命令（推荐）
    irm https://raw.githubusercontent.com/missercatos/ARKVim/master/install.ps1 | iex

    # 下载仓库后本地跑
    powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1

    # 只装 nvim + 配置
    .\install.ps1 -Minimal

    # 连语言工具链一起装
    .\install.ps1 -Tools

.PARAMETER Minimal
  只装 Neovim + 配置（不装 ripgrep/fd/字体）。

.PARAMETER Tools
  额外安装语言运行时与 LSP（会装不少东西，耗时较长）。

.PARAMETER NoFont
  不安装 Nerd Font。

.PARAMETER Dir
  配置目录，默认 %LOCALAPPDATA%\nvim
  （注意：Neovim 在 Windows 上默认就读这里；换成别的路径需要自己设 XDG_CONFIG_HOME）

.PARAMETER Repo
  仓库地址，默认 https://github.com/missercatos/ARKVim.git

.PARAMETER Branch
  分支，默认 master
#>
[CmdletBinding()]
param(
  [switch]$Minimal,
  [switch]$Tools,
  [switch]$NoFont,
  [string]$Dir = (Join-Path $env:LOCALAPPDATA 'nvim'),
  [string]$Repo = 'https://github.com/missercatos/ARKVim.git',
  [string]$Branch = 'master'
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

# ---------------------------------------------------------------------------
# 输出
# ---------------------------------------------------------------------------
function Write-Step2([string]$msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-Ok([string]$msg)    { Write-Host "  [ok]   $msg" -ForegroundColor Green }
function Write-Info([string]$msg)  { Write-Host "  [info] $msg" -ForegroundColor Gray }
function Write-Warn2([string]$msg) { Write-Host "  [warn] $msg" -ForegroundColor Yellow }
function Write-Err2([string]$msg)  { Write-Host "  [fail] $msg" -ForegroundColor Red }

function Test-Command([string]$name) {
  return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

$HasWinget = Test-Command 'winget'

# winget 是原生程序，失败不会抛异常，只能看 $LASTEXITCODE
$script:LastNativeOk = $true

function Install-Winget([string]$id, [string]$name) {
  if (-not $HasWinget) {
    Write-Warn2 "$name：没有 winget，跳过（可手动安装）"
    return $false
  }
  Write-Info "winget 安装 $name ($id) ..."
  winget install --id $id -e --silent --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
  $code = $LASTEXITCODE
  if ($code -eq 0) {
    Write-Ok "$name 安装完成"
    return $true
  }
  Write-Warn2 "$name 安装失败（exit $code），可手动安装"
  return $false
}

# ---------------------------------------------------------------------------
# PATH（用户级，所有终端共用）
# ---------------------------------------------------------------------------
function Add-UserPath([string]$path) {
  if (-not $path -or -not (Test-Path $path)) { return }
  $cur = [Environment]::GetEnvironmentVariable('Path', 'User')
  if (-not $cur) { $cur = '' }
  $parts = @($cur.Split(';') | Where-Object { $_ -ne '' })
  if ($parts -contains $path) {
    Write-Info "PATH 已有：$path"
  } else {
    [Environment]::SetEnvironmentVariable('Path', ($cur.TrimEnd(';') + ';' + $path), 'User')
    Write-Ok "已加入用户 PATH：$path"
  }
  if (-not (@($env:Path.Split(';')) -contains $path)) {
    $env:Path = $env:Path.TrimEnd(';') + ';' + $path
  }
}

# ---------------------------------------------------------------------------
# Neovim
# ---------------------------------------------------------------------------
function Find-Nvim {
  $candidates = @(
    (Join-Path $env:LOCALAPPDATA 'Programs\Neovim\bin\nvim.exe'),
    (Join-Path $env:LOCALAPPDATA 'Programs\Neovim\nvim.exe'),
    (Join-Path $env:ProgramFiles 'Neovim\bin\nvim.exe')
  )
  $pf86 = ${env:ProgramFiles(x86)}
  if ($pf86) { $candidates += (Join-Path $pf86 'Neovim\bin\nvim.exe') }
  foreach ($c in $candidates) {
    if ($c -and (Test-Path $c)) { return $c }
  }
  $cmd = Get-Command 'nvim' -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  return $null
}

function Install-NeovimPortable {
  $dest = Join-Path $env:LOCALAPPDATA 'Programs\Neovim'
  $zip = Join-Path $env:TEMP 'nvim-win64.zip'
  $url = 'https://github.com/neovim/neovim/releases/latest/download/nvim-win64.zip'
  Write-Info "下载 Neovim：$url"
  try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
    if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    Expand-Archive -Path $zip -DestinationPath $dest -Force
    Remove-Item -Force $zip -ErrorAction SilentlyContinue
    $inner = Get-ChildItem -Path $dest -Directory |
      Where-Object { Test-Path (Join-Path $_.FullName 'bin\nvim.exe') } |
      Select-Object -First 1
    if ($inner) { return (Join-Path $inner.FullName 'bin') }
    return (Join-Path $dest 'bin')
  } catch {
    Write-Err2 "下载 Neovim 失败：$($_.Exception.Message)"
    return $null
  }
}

function Ensure-Neovim {
  $existing = Find-Nvim
  if ($existing) {
    Write-Ok "已检测到 Neovim：$existing"
    Add-UserPath (Split-Path $existing -Parent)
    return $existing
  }

  Write-Step2 '安装 Neovim'
  if ($HasWinget) {
    [void](Install-Winget 'Neovim.Neovim' 'Neovim')
    $found = Find-Nvim
    if ($found) {
      Add-UserPath (Split-Path $found -Parent)
      return $found
    }
    Write-Warn2 'winget 装完但没找到 nvim.exe，改用便携版'
  }

  $bin = Install-NeovimPortable
  if ($bin) {
    Add-UserPath $bin
    return (Join-Path $bin 'nvim.exe')
  }
  return $null
}

# ---------------------------------------------------------------------------
# Nerd Font（图标）
# ---------------------------------------------------------------------------
function Install-NerdFont {
  $fontName = 'JetBrainsMono'
  $fontDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
  $zip = Join-Path $env:TEMP "$fontName.zip"
  $url = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$fontName.zip"

  New-Item -ItemType Directory -Force -Path $fontDir | Out-Null
  Write-Info "下载 Nerd Font：$url"
  try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
    $tmp = Join-Path $env:TEMP 'arkvim-font'
    if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }
    Expand-Archive -Path $zip -DestinationPath $tmp -Force
    Remove-Item -Force $zip -ErrorAction SilentlyContinue

    $key = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
    if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }

    $installed = 0
    foreach ($f in (Get-ChildItem -Path $tmp -Filter '*.ttf' -Recurse)) {
      $target = Join-Path $fontDir $f.Name
      Copy-Item -Path $f.FullName -Destination $target -Force
      $regName = [IO.Path]::GetFileNameWithoutExtension($f.Name) + ' (TrueType)'
      New-ItemProperty -Path $key -Name $regName -Value $target -PropertyType String -Force | Out-Null
      $installed++
    }
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
    Write-Ok "已安装 $installed 个字体到 $fontDir"
    Write-Info "终端字体设成 'JetBrainsMono Nerd Font'（Windows Terminal：设置 → 外观 → 字体）"
    return $true
  } catch {
    Write-Warn2 "Nerd Font 安装失败：$($_.Exception.Message)"
    Write-Info '可手动安装：https://www.nerdfonts.com/font-downloads （推荐 JetBrainsMono）'
    return $false
  }
}

# ---------------------------------------------------------------------------
# 配置仓库
# ---------------------------------------------------------------------------
function Install-Config([string]$dir, [string]$repo, [string]$branch) {
  if (Test-Path $dir) {
    $isRepo = (Test-Path (Join-Path $dir '.git')) -and (Test-Path (Join-Path $dir 'init.lua'))
    if ($isRepo) {
      Write-Step2 '更新已有 ARKVim 配置（git pull）'
      git -C $dir pull --ff-only 2>&1 | Out-Null
      if ($LASTEXITCODE -eq 0) {
        Write-Ok "已更新：$dir"
      } else {
        Write-Warn2 "git pull 失败（可能本地有改动），保留现有配置"
      }
      return $true
    }
    $bak = "$dir.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
    Write-Warn2 "配置目录已存在且不是 ARKVim，备份到：$bak"
    Move-Item -Path $dir -Destination $bak -Force
  }

  Write-Step2 "克隆 ARKVim 到 $dir"
  git clone --depth 1 --branch $branch $repo $dir 2>&1 | Out-Null
  if ($LASTEXITCODE -ne 0) {
    Write-Err2 "克隆失败（exit $LASTEXITCODE）：$repo"
    return $false
  }
  Write-Ok '配置已就位'
  return $true
}

# ---------------------------------------------------------------------------
# 主流程
# ---------------------------------------------------------------------------
Write-Host ''
Write-Host '  █████╗ ██████╗ ██╗  ██╗██╗   ██╗██╗███╗   ███╗' -ForegroundColor Cyan
Write-Host '  ARKVim installer (Windows)' -ForegroundColor Cyan
Write-Host ''

if ($PSVersionTable.PSVersion.Major -lt 5) {
  throw "需要 PowerShell 5.1+（当前 $($PSVersionTable.PSVersion)）"
}

Write-Info "配置目录：$Dir"
Write-Info "仓库：$Repo ($Branch)"
if (-not $HasWinget) { Write-Warn2 '没有检测到 winget，自动装工具会受限（Neovim 走便携版）' }

# 1. git
Write-Step2 '检查 git'
if (Test-Command 'git') {
  Write-Ok "git 已安装：$((Get-Command git).Source)"
} else {
  [void](Install-Winget 'Git.Git' 'Git')
  if (-not (Test-Command 'git')) {
    throw '缺少 git 且自动安装失败。请先装 git：https://git-scm.com/download/win'
  }
}

# 2. Neovim
$nvim = Ensure-Neovim
if (-not $nvim) { throw 'Neovim 安装失败' }

# 3. 基础工具（ripgrep/fd 是文件树搜索与 picker 依赖）
if (-not $Minimal) {
  Write-Step2 '安装基础工具'
  if (Test-Command 'rg') { Write-Ok 'ripgrep 已安装' } else { [void](Install-Winget 'BurntSushi.ripgrep.MSVC' 'ripgrep') }
  if (Test-Command 'fd') { Write-Ok 'fd 已安装' } else { [void](Install-Winget 'sharkdp.fd' 'fd') }
}

# 4. 字体
if (-not $Minimal -and -not $NoFont) {
  Write-Step2 '安装 Nerd Font（图标需要）'
  [void](Install-NerdFont)
}

# 5. 可选工具链
if ($Tools) {
  Write-Step2 '安装语言工具链（耗时较长）'
  $pkgs = @(
    [pscustomobject]@{ Id = 'jesseduffield.lazygit'; Name = 'lazygit' },
    [pscustomobject]@{ Id = 'GitHub.cli'; Name = 'GitHub CLI' },
    [pscustomobject]@{ Id = 'OpenJS.NodeJS.LTS'; Name = 'Node.js LTS' },
    [pscustomobject]@{ Id = 'Python.Python.3.12'; Name = 'Python 3.12' },
    [pscustomobject]@{ Id = 'GoLang.Go'; Name = 'Go' },
    [pscustomobject]@{ Id = 'Rustlang.Rustup'; Name = 'Rust' },
    [pscustomobject]@{ Id = 'EclipseAdoptium.Temurin.21.JDK'; Name = 'JDK 21' },
    [pscustomobject]@{ Id = 'LLVM.LLVM'; Name = 'LLVM (clang)' },
    [pscustomobject]@{ Id = 'Kitware.CMake'; Name = 'CMake' },
    [pscustomobject]@{ Id = 'Ninja-build.Ninja'; Name = 'Ninja' }
  )
  foreach ($p in $pkgs) { [void](Install-Winget $p.Id $p.Name) }
}

# 6. 配置
if (-not (Install-Config -dir $Dir -repo $Repo -branch $Branch)) {
  throw '配置部署失败'
}

# 7. 预装插件（best-effort）
Write-Step2 '预装 Neovim 插件（首次会下载，可能几分钟）'
& $nvim --headless '+Lazy! sync' +qa 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
  Write-Ok '插件同步完成'
} else {
  Write-Warn2 '插件预装未成功（不影响：首次启动 nvim 会自动装）'
}

Write-Host ''
Write-Host '  完成！' -ForegroundColor Green
Write-Host ''
Write-Info '请重开一个终端（让 PATH 生效），然后运行：nvim'
Write-Info '首次启动会自动装插件；进 nvim 后可用 :checkhealth 检查'
Write-Info '打开文件树：空格 e ；能力面板：空格 X h'
if (-not $Minimal -and -not $NoFont) {
  Write-Info '记得把终端字体设为 JetBrainsMono Nerd Font'
}
Write-Host ''
Write-Host '  卸载：' -ForegroundColor Yellow
Write-Host "    配置：  Remove-Item -Recurse -Force `"$Dir`""
Write-Host  '    数据：  Remove-Item -Recurse -Force "$env:LOCALAPPDATA\nvim-data"'
Write-Host  '    本体：  winget uninstall Neovim.Neovim'
Write-Host ''
