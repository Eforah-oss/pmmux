function pmmux {
  $selfSource = "function $($MyInvocation.MyCommand.Name) {" +
    "$($MyInvocation.MyCommand.Definition)}`n`n" +
    "$($MyInvocation.MyCommand.Name) @args"
  function Add-Path {
    param (
      [Parameter(Mandatory = $true, Position = 0)]
      [string]$Path
    )
    $pathKey = `
      "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\"
    $paths = (Get-Item $pathKey).GetValue('Path', '',
      'DoNotExpandEnvironmentNames') -split ';' -ne ''
    if (!($Path -in $paths)) {
      Set-ItemProperty -Type ExpandString -LiteralPath $pathKey Path `
      (($paths + $Path) -join ';')
      #Broadcast env update signal
      $x = [guid]::NewGuid().ToString()
      [Environment]::SetEnvironmentVariable($x, $x, 'User')
      [Environment]::SetEnvironmentVariable($x, [NullString]::value, 'User')
    }
  }
  function pm_choco {
    choco.exe install -y @Args
  }
  function pm_pmmux {
    if ("pmmux" -eq $Args[0]) {
      $pmmuxPath = (Join-Path $env:ProgramFiles pmmux)
      if (!(Test-Path $pmmuxPath)) {
        New-Item -Type Directory $pmmuxPath >$null
      }
      Set-Content (Join-Path $pmmuxPath pmmux.ps1) $selfSource
      Set-Content (Join-Path $pmmuxPath pmmux.bat) `
        "powershell.exe -NoLogo -NoProfile -File ""$pmmuxPath\pmmux.ps1"" %*"
      Add-Path $pmmuxPath
    }
    elseif ("init-lazyloaders") {
      if (!($env:PMMUX_LAZY_HOME)) {
        $env:PMMUX_LAZY_HOME = `
          "$([Environment]::GetFolderPath('ApplicationData'))/pmmux/lazyloaders"
      }
      if (!($env:PMMUX_LAZY_BIN)) {
        $env:PMMUX_LAZY_BIN = `
          "$([Environment]::GetFolderPath('ApplicationData'))/pmmux/lazybin"
      }
      if (!(Test-Path $env:PMMUX_LAZY_BIN)) {
        New-Item -Type Directory $env:PMMUX_LAZY_BIN >$null
      }
      Get-ChildItem "$env:PMMUX_LAZY_HOME" | Foreach-Object {
        & {
          "@echo off"
          "pmmux$((Get-Content $_.FullName) -replace "^#!/.*pmmux$"," " ) --exec $($_.Name) %*"
        } | Set-Content -Path (Join-Path $env:PMMUX_LAZY_BIN "$($_.Name).bat") -Encoding ASCII
      }
      Add-Path "$env:PMMUX_LAZY_BIN"
    }
  }
  if ("-1" -ne $Args[0]) {
    throw "Please run as pmmux -1 ... for future compatibility"
  }
  :processArgs foreach ($arg in $Args[1..$Args.Length]) {
    if ($arg -match "^([a-z]*)\+(.*)$") {
      if (Get-Command "pm_$($Matches[1])" -ErrorAction SilentlyContinue) {
        & "pm_$($Matches[1])" @($Matches[2] -split " ")
        break processArgs
      }
    }
  }
  if (($idx = $Args.IndexOf("--exec")) -ge 0) {
    Start-Process -FilePath $args[$idx + 1] -ArgumentList $args[($idx + 2)..($args.Length - 1)] -NoNewWindow -Wait
  }
}

pmmux @args
