param(
  [string]$FlutterCommand = "flutter",
  [string]$InnoSetupCompiler = ""
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Resolve-Path (Join-Path $scriptDir "..\..")
$issFile = Join-Path $scriptDir "jntool.iss"
$outputDir = Join-Path $projectDir "dist\windows"
$installerFile = Join-Path $outputDir "JNToolSetup-1.0.0.exe"

function Assert-WindowsHost {
  # 核心校验：Flutter Windows 桌面构建只能在 Windows 主机执行，提前失败可避免误判产物。
  if ($env:OS -ne "Windows_NT") {
    throw "Windows 安装包必须在 Windows 主机上构建。当前系统不支持 flutter build windows。"
  }
}

function Resolve-InnoSetupCompiler {
  param([string]$ExplicitPath)

  # 优先使用用户显式传入的 ISCC.exe，便于 CI 或自定义安装目录复用。
  if ($ExplicitPath) {
    if (-not (Test-Path $ExplicitPath)) {
      throw "找不到指定的 Inno Setup 编译器：$ExplicitPath"
    }
    return (Resolve-Path $ExplicitPath).Path
  }

  $command = Get-Command "ISCC.exe" -ErrorAction SilentlyContinue
  if ($command) {
    return $command.Source
  }

  $candidatePaths = @(
    (Join-Path ${env:ProgramFiles(x86)} "Inno Setup 6\ISCC.exe"),
    (Join-Path $env:ProgramFiles "Inno Setup 6\ISCC.exe")
  )

  foreach ($candidatePath in $candidatePaths) {
    if ($candidatePath -and (Test-Path $candidatePath)) {
      return (Resolve-Path $candidatePath).Path
    }
  }

  throw "未找到 Inno Setup 编译器 ISCC.exe。请安装 Inno Setup 6，或用 -InnoSetupCompiler 指定路径。"
}

Assert-WindowsHost
$iscc = Resolve-InnoSetupCompiler -ExplicitPath $InnoSetupCompiler

Push-Location $projectDir
try {
  Write-Host "==> 安装 Flutter 依赖"
  & $FlutterCommand pub get

  Write-Host "==> 构建 Windows Release 应用"
  & $FlutterCommand build windows --release

  Write-Host "==> 编译 Windows 安装包"
  & $iscc $issFile

  # 产物校验：确认安装包真实生成，避免上一步静默失败后继续输出错误路径。
  if (-not (Test-Path $installerFile)) {
    throw "安装包未生成：$installerFile"
  }

  $fileInfo = Get-Item $installerFile
  Write-Host "==> 打包完成：$($fileInfo.FullName)"
  Write-Host "==> 文件大小：$([Math]::Round($fileInfo.Length / 1MB, 2)) MB"
}
finally {
  Pop-Location
}
