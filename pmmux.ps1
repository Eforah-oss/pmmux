function pmmux {
  function pm_choco {
    choco.exe install -y @Args
  }
  if ("-1" -ne $Args[0]) {
    throw "Please run as pmmux -1 ... for future compatibility"
  }
  :processArgs foreach ($arg in $Args[1..$Args.Length]) {
    $arg | ForEach-Object {
      if ($_ -match "^([a-z]*)\+(.*)$") {
        if (Get-Command "pm_$($Matches[1])") {
          & "pm_$($Matches[1])" ($Matches[2] -split " ")
          break processArgs
        }
      }
    }
  }
}

pmmux @args
