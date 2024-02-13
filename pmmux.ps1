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
  function Sync-Path {
    $env:PATH = "$((Get-ItemProperty -Path `
      'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\' `
      -Name 'PATH').Path);$((Get-ItemProperty -Path 'HKCU:\Environment' `
      -Name 'PATH').Path)"
  }
  function ConvertTo-PwshArgument {
    param (
      [string[]]$Arguments
    )

    $result = ""
    foreach ($arg in $Arguments) {
      # Escape PowerShell special characters
      $escapedArg = $arg -replace '\`', '``' -replace "'", "''"
      # Concatenate arguments
      $result += "'$escapedArg' "
    }
    return $result.TrimEnd()
  }

  function Invoke-ElevatedCommand {
    param (
      [Parameter(Position = 0, Mandatory = $true, ValueFromRemainingArguments = $true)]
      [string[]]$Command
    )

    # Convert command array to a single string with PowerShell argument escaping
    $quotedCommand = ConvertTo-PwshArgument -Arguments $Command

    # Command to be executed with elevation, ensuring it waits for completion
    $scriptBlock = "& { Invoke-Expression $quotedCommand }"
    # Invoke the command with elevation
    Start-Process powershell.exe -ArgumentList "/noprofile", "-Command", $scriptBlock -Verb RunAs -Wait -WindowStyle Hidden
  }

  function pm_powershell {
    param (
      [Parameter(Position = 0, ValueFromPipeline, ValueFromRemainingArguments)]
      [string[]]
      $Arguments
    )

    Invoke-ElevatedCommand -Command $Arguments
    Sync-Path
  }

  function pm_choco {
    param (
      [Parameter(Position = 0, ValueFromPipeline, ValueFromRemainingArguments)]
      [string[]] $Arguments
    )

    $ChocoArgs = @('install', '-y') + $Arguments
    $ChocoCommand = "choco.exe $ChocoArgs"

    Invoke-ElevatedCommand -Command $ChocoCommand
    Sync-Path
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
      Sync-Path
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
      Sync-Path
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
