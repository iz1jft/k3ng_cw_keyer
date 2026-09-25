param([string]$PortName='COM4',[string]$TracePath='morse-arcade-trace.json')
# Run with the radio disconnected and all serial clients closed.
$ErrorActionPreference = 'Stop'
$port = [System.IO.Ports.SerialPort]::new($PortName,1200,[System.IO.Ports.Parity]::None,8,[System.IO.Ports.StopBits]::Two)
$port.ReadTimeout=500
$port.WriteTimeout=2000
$trace=[System.Collections.Generic.List[object]]::new()
function Exchange($label,[byte[]]$bytes,$delay=300) {
  $port.Write($bytes,0,$bytes.Length)
  Start-Sleep -Milliseconds $delay
  $received=[System.Collections.Generic.List[int]]::new()
  while($port.BytesToRead -gt 0){$received.Add($port.ReadByte())}
  $trace.Add(@{label=$label;sent=@($bytes);received=@($received.ToArray())})
  Write-Host ($label+': '+(($received | ForEach-Object {$_.ToString('X2')}) -join ' '))
  return ,$received.ToArray()
}
try {
 $port.Open();Start-Sleep -Milliseconds 2500;$port.DiscardInBuffer()
 $null=Exchange 'open' ([byte[]](0,2))
 $null=Exchange 'normal_down' ([byte[]](11,1))
 $null=Exchange 'normal_up' ([byte[]](11,0))
 $null=Exchange 'enable' ([byte[]](0,225))
 $null=Exchange 'arcade_down' ([byte[]](11,1))
 $null=Exchange 'duplicate_down' ([byte[]](11,1))
 $null=Exchange 'arcade_up' ([byte[]](11,0))
 $null=Exchange 'disable' ([byte[]](0,224))
 $null=Exchange 'disabled_down' ([byte[]](11,1))
 $null=Exchange 'disabled_up' ([byte[]](11,0))
 $null=Exchange 'enable_again' ([byte[]](0,225))
 $null=Exchange 'reopen' ([byte[]](0,2))
 $null=Exchange 'reopened_down' ([byte[]](11,1))
 $null=Exchange 'reopened_up' ([byte[]](11,0))
 $null=Exchange 'close' ([byte[]](0,3))
 $null=Exchange 'closed_enable' ([byte[]](0,225))
} finally {
 if($port.IsOpen){$port.Write([byte[]](11,0,0,224,0,3),0,6);$port.Close()}
 $trace | ConvertTo-Json -Depth 5 | Set-Content $TracePath
}
$expected=@{open=@(23);normal_down=@();normal_up=@();enable=@(30,31,29);arcade_down=@(28);duplicate_down=@();arcade_up=@(29);disable=@();disabled_down=@();disabled_up=@();enable_again=@(30,31,29);reopen=@(23);reopened_down=@();reopened_up=@();close=@();closed_enable=@()}
foreach($record in $trace){
 if(($record.received -join ',') -ne ($expected[$record.label] -join ',')){throw ('Unexpected reply: '+$record.label)}
}
Write-Host 'PASS: 16 hardware exchanges'
