<#
.SYNOPSIS
  把 install.ps1 打包成单文件 install.exe（Windows 上运行）

.DESCRIPTION
  用 PS2EXE 把 PowerShell 脚本编译成一个可双击运行的 .exe。
  在 Windows 上执行本脚本即可；CI 里也用同一个脚本（见 .github/workflows/windows-installer.yml）。

  注意：产物未签名，首次运行会被 SmartScreen 拦一下（"更多信息 → 仍要运行"）。
  不想用 exe 的话，直接用 install.cmd 或 `irm ... | iex` 也一样。

.USAGE
  Install-Module ps2exe -Scope CurrentUser -Force
  .\windows\build-exe.ps1
#>
[CmdletBinding()]
param(
  [string]$In  = (Join-Path (Split-Path $PSScriptRoot -Parent) 'install.ps1'),
  [string]$Out = (Join-Path $PSScriptRoot 'install.exe')
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Module -ListAvailable -Name ps2exe)) {
  Write-Host '安装 PS2EXE 模块 ...' -ForegroundColor Cyan
  Install-Module ps2exe -Scope CurrentUser -Force -AllowClobber
}
Import-Module ps2exe

if (-not (Test-Path $In)) {
  throw "找不到输入脚本：$In"
}

Write-Host "打包 $In -> $Out" -ForegroundColor Cyan

Invoke-PS2EXE `
  -InputFile   $In `
  -OutputFile  $Out `
  -Title       'ARKVim Installer' `
  -Description 'ARKVim for Windows — 安装 Neovim 与 ARKVim 配置' `
  -Product     'ARKVim' `
  -Company     'ARKVim' `
  -Version     '1.0.0.0' `
  -ErrorAction 'SilentlyContinue'

if (Test-Path $Out) {
  Write-Host "完成：$Out" -ForegroundColor Green
} else {
  throw '打包失败'
}
