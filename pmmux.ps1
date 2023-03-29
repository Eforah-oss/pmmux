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
        switch ($Matches[1]) {
          "choco" {
            pm_choco $Matches[2]
            break processArgs
          }
        }
      }
    }
  }
}

pmmux @args
