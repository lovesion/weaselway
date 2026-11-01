param([string]$Stage='baseline',[int]$Seconds=12)
$ErrorActionPreference='Stop'
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class CpuPdh {
 [StructLayout(LayoutKind.Explicit)] public struct Value { [FieldOffset(0)] public UInt32 Status; [FieldOffset(8)] public double Number; }
 [DllImport("pdh.dll",CharSet=CharSet.Unicode)] public static extern UInt32 PdhOpenQuery(string source,IntPtr user,out IntPtr query);
 [DllImport("pdh.dll",CharSet=CharSet.Unicode)] public static extern UInt32 PdhAddEnglishCounter(IntPtr query,string path,IntPtr user,out IntPtr counter);
 [DllImport("pdh.dll")] public static extern UInt32 PdhCollectQueryData(IntPtr query);
 [DllImport("pdh.dll")] public static extern UInt32 PdhGetFormattedCounterValue(IntPtr counter,UInt32 flags,out UInt32 type,out Value value);
 [DllImport("pdh.dll")] public static extern UInt32 PdhCloseQuery(IntPtr query);
 public static UInt32 OpenLive(out IntPtr query) { return PdhOpenQuery(null,IntPtr.Zero,out query); }
}
'@
$query=[IntPtr]::Zero
$openStatus=[CpuPdh]::OpenLive([ref]$query)
if($openStatus -ne 0){throw ('PdhOpenQuery: '+$openStatus.ToString('x8'))}
$paths=@{
 total='\Processor(_Total)\% Processor Time'
 viewer='\Process(sdl-freerdp)\% Processor Time'
 dwm='\Process(dwm)\% Processor Time'
 wsl='\Process(vmmemWSL)\% Processor Time'
 native_vm='\Process(vmmem)\% Processor Time'
}
$handles=@{}
foreach($name in $paths.Keys){
 $handle=[IntPtr]::Zero
 $status=[CpuPdh]::PdhAddEnglishCounter($query,$paths[$name],[IntPtr]::Zero,[ref]$handle)
 if($status -eq 0){$handles[$name]=$handle}else{Write-Output ($name+': '+$status.ToString('x8'))}
}
$cores=[Environment]::ProcessorCount
$rows=@()
$null=[CpuPdh]::PdhCollectQueryData($query)
for($i=0;$i -lt $Seconds;$i++){
 Start-Sleep -Milliseconds 1000
 $null=[CpuPdh]::PdhCollectQueryData($query)
 $row=[ordered]@{time=(Get-Date -Format o);stage=$Stage;logical_processors=$cores}
 foreach($name in $handles.Keys){
  $value=New-Object CpuPdh+Value
  [uint32]$type=0
  $status=[CpuPdh]::PdhGetFormattedCounterValue($handles[$name],0x8200,[ref]$type,[ref]$value)
  if($status -eq 0 -and $value.Status -le 1){
   $raw=$value.Number
   $row[$name+'_core_percent']=[Math]::Round($raw,3)
   $row[$name+'_machine_percent']=[Math]::Round($(if($name -eq 'total'){$raw}else{$raw/$cores}),3)
  }else{$row[$name+'_status']=$status.ToString('x8')+':'+$value.Status.ToString('x8')}
 }
 $rows += [pscustomobject]$row
}
$null=[CpuPdh]::PdhCloseQuery($query)
$path=Join-Path $PSScriptRoot ('cpu-'+$Stage+'.json')
$rows | ConvertTo-Json -Depth 4 | Set-Content $path
$summary=[ordered]@{stage=$Stage;samples=$rows.Count;logical_processors=$cores}
foreach($name in $paths.Keys){
 $vals=@($rows | ForEach-Object { $_.($name+'_machine_percent') } | Where-Object { $null -ne $_ })
 if($vals.Count){$m=$vals | Measure-Object -Average -Maximum -Minimum;$summary[$name]=@{avg=[Math]::Round($m.Average,2);max=$m.Maximum;min=$m.Minimum}}
}
$summary | ConvertTo-Json -Depth 4 -Compress
