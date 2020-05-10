Write-Host "Downloading Unity Hub..."

$baseUrl = "https://public-cdn.cloud.unity3d.com/hub/prod/UnityHubSetup";
$outPath = $PSScriptRoot

$wc = New-Object System.Net.WebClient

Write-Host "Download Complete, Starting installation..."

if ((-not $global:PSVersionTable.Platform) -or ($global:PSVersionTable.Platform -eq "Win32NT")) {
  $wc.DownloadFile("$baseUrl.exe", "$outPath.exe")
  $startProcessArgs = @{
    'FilePath'     = $outpath;
    'ArgumentList' = @("/S");
    'PassThru'     = $true;
    'Wait'         = $true;
  }
}
elseif ($global:PSVersionTable.OS.Contains("Darwin")) {
  $wc.DownloadFile("$baseUrl.AppImage", "$outPath.AppImage")
  # Note that $Destination has to be a disk path.
  # sudo installer -package $Package.Path -target
  $startProcessArgs = @{
    'FilePath'     = 'sudo';
    'ArgumentList' = @("installer", "-package", $outpath, "-target", "/Applications/UnityHub");
    'PassThru'     = $true;
    'Wait'         = $true;
  }
}
elseif ($global:PSVersionTable.OS.Contains("Linux")) {
  $wc.DownloadFile("$baseUrl.dmg", "$outPath.dmg")
  #https://www.linuxdeveloper.space/install-unity-linux/
  #sudo chmod +x UnityHub.AppImage
  $startProcessArgs = @{
    'FilePath'     = 'sudo';
    'ArgumentList' = @("chmod", "+x", $outPath);
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
