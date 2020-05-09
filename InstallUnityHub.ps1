Write-Host "Downloading Unity Hub..."

$url = "https://public-cdn.cloud.unity3d.com/hub/prod/UnityHubSetup.exe";
$outpath = "$PSScriptRoot/UnityHubSetup.exe"

$wc = New-Object System.Net.WebClient
$wc.DownloadFile($url, $outpath)

Write-Host "Download Complete, Starting installation..."

if ((-not $global:PSVersionTable.Platform) -or ($global:PSVersionTable.Platform -eq "Win32NT")) {
  $startProcessArgs = @{
    'FilePath'     = $outpath;
    'ArgumentList' = @("/S", "/D=$Destination");
    'PassThru'     = $true;
    'Wait'         = $true;
  }
}
else {
  $startProcessArgs = @{
    'FilePath'     = 'sudo';
    'ArgumentList' = @("installer", "-package", $outpath);
    'PassThru'     = $true;
    'Wait'         = $true;
  }
}

$process = Start-Process @startProcessArgs
if ( $process ) {
  if ( $process.ExitCode -ne 0) {
    Write-Error "$(Get-Date): Failed with exit code: $($process.ExitCode)"
  }
  else {
    Write-Verbose "$(Get-Date): Succeeded."
  }
}
