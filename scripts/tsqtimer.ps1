#!/usr/bin/env pwsh

[CmdletBinding(DefaultParameterSetName = 'Path')]
Param (
  [SupportsWildCards()]
  [Parameter(
    Position = 0,
    ParameterSetName = 'Path',
    ValueFromPipeline = $false,
    ValueFromPipelineByPropertyName = $true
  )]
  [String[]]$Path,

  [Alias('LP')]
	[Alias('PSPath')]
  [Parameter(
    Position = 0,
    ParameterSetName = 'LiteralPath',
    ValueFromPipeline = $true,
    ValueFromPipelineByPropertyName = $true
  )]
  [String[]]$LiteralPath,

  [Int32]$Song = 1,
  [Int32]$Loop = 2
)

Begin {
  $fps = 60.0
  $channel = 0
}

Process {
  trap {
    break
  }

  switch ($PSCmdlet.ParameterSetName) {
    'Path' {
      if ($PSVersionTable.PSVersion.Major -lt 6) {
        $TSQCollection = @(Get-Content -Path $Path -Raw -Encoding Byte)
      }
      else {
        $TSQCollection = @(Get-Content -Path $Path -Raw -AsByteStream)
      }
      break
    }
    'LiteralPath' {
      if ($PSVersionTable.PSVersion.Major -lt 6) {
        $TSQCollection = @(Get-Content -LiteralPath $LiteralPath -Raw -Encoding Byte)
      }
      else {
        $TSQCollection = @(Get-Content -LiteralPath $LiteralPath -Raw -AsByteStream)
      }
      break
    }
    Default {
      Write-Error -Message "Invalid parameter."
      return
    }
  }

  $result = @{}
  foreach ($rawTSQ in $TSQCollection) {
    $trackLength = 0
    $loopCount = $Loop

    $offset  = [BitConverter]::ToUInt16($rawTSQ, 4 * $Song + 2)
    $offset += [BitConverter]::ToUInt16($rawTSQ, $offset + 4 * $channel + 2)

    while (($loopCount -gt 0) -and ($offset -lt $rawTSQ.Length)) {
      if (($rawTSQ[$offset] -ge 0x00) -and ($rawTSQ[$offset] -le 0x7F)) {
        $trackLength += $rawTSQ[$offset]
        $offset += 1
      }
      elseif ((($rawTSQ[$offset] -ge 0x80) -and ($rawTSQ[$offset] -le 0xDF)) -or ($rawTSQ[$offset] -in (0xE8,0xE9,0xF0,0xF9))) {
        $offset += 1
      }
      elseif ($rawTSQ[$offset] -in (0xE0,0xE2,0xE6,0xE7,0xF1)) {
        $offset += 2
      }
      elseif ($rawTSQ[$offset] -in (0xE1,0xE3,0xE4,0xE5,0xEA)) {
        $offset += 3
      }
      elseif ($rawTSQ[$offset] -eq 0xF8) {  # data_jump
        $offset += 3 + [BitConverter]::ToInt16($rawTSQ, $offset + 1)
        $loopCount -= 1
      }
      elseif ($rawTSQ[$offset] -eq 0xFF) {  # data_end
        break
      }
      else {
        Write-Error -Message "Unknown control code: 0x$($rawTSQ[$offset].ToString("X2")) ($($rawTSQ.PSChildName), 0x$($offset.ToString("X4")))"
        return
      }
    }

    $time = [TimeSpan]::FromSeconds($trackLength / $fps)
    $result.Add("$($rawTSQ.PSChildName) ($Song)", $time.ToString("m\:ss\.f"))
  }
  return $result.GetEnumerator() | Sort-Object -Property Key
}
