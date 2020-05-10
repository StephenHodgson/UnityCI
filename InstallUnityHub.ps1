Write-Host "$(Get-Date): Downloading Unity Hub..."

$baseUrl = "https://public-cdn.cloud.unity3d.com/hub/prod";
$outPath = $PSScriptRoot

$wc = New-Object System.Net.WebClient

Write-Host "$(Get-Date): Download Complete, Starting installation..."

if ((-not $global:PSVersionTable.Platform) -or ($global:PSVersionTable.Platform -eq "Win32NT")) {
  $wc.DownloadFile("$baseUrl/UnityHubSetup.exe", "$outPath/UnityHubSetup.exe")
  $startProcessArgs = @{
    'FilePath'     = $outpath;
    'ArgumentList' = @("/S");
    'PassThru'     = $true;
    'Wait'         = $true;
  }
}
elseif ($global:PSVersionTable.OS.Contains("Darwin")) {
  $wc.DownloadFile("$baseUrl/UnityHubSetup.dmg", "$outPath/UnityHubSetup.dmg")
  # Note that $Destination has to be a disk path.
  # sudo installer -package $Package.Path -target
  $startProcessArgs = @{
    'FilePath'     = 'sudo';
    'ArgumentList' = @("installer", "-package", "$outpath/UnityHubSetup.dmg", "-target", "/Applications/UnityHub");
    'PassThru'     = $true;
    'Wait'         = $true;
  }
}
elseif ($global:PSVersionTable.OS.Contains("Linux")) {
  $wc.DownloadFile("$baseUrl/UnityHub.AppImage", "$outPath/UnityHub.AppImage")
  #https://www.linuxdeveloper.space/install-unity-linux/
  #sudo chmod +x UnityHub.AppImage
  $startProcessArgs = @{
    'FilePath'     = 'sudo';
    'ArgumentList' = @("chmod", "+x", "$outPath/UnityHub.AppImage");
    'PassThru'     = $true;
    'Wait'         = $true;
  }
}

$process = Start-Process @startProcessArgs -Wait

if ( $process.ExitCode -ne 0) {
  Write-Error "$(Get-Date): Failed with exit code: $($process.ExitCode)"
}
else {
  Write-Host "$(Get-Date): Succeeded."
}
