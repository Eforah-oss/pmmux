function pmmux {
  $selfSource = "function $($MyInvocation.MyCommand.Name) {" +
    "$($MyInvocation.MyCommand.Definition)}`n`n" +
    "$($MyInvocation.MyCommand.Name) @args"
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
      $pathKey = "registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\" +
        "Control\Session Manager\Environment"
      $paths = (Get-Item $pathKey).GetValue('Path', '',
        'DoNotExpandEnvironmentNames') -split ';' -ne ''
      if (!($pmmuxPath -in $paths)) {
        Set-ItemProperty -Type ExpandString -LiteralPath $pathKey Path `
          (($paths + $pmmuxPath) -join ';')
        #Broadcast env update signal
        $x = [guid]::NewGuid().ToString()
        [Environment]::SetEnvironmentVariable($x, 'foo', 'User')
        [Environment]::SetEnvironmentVariable($x, [NullString]::value, 'User')
      }
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
}

pmmux @args
