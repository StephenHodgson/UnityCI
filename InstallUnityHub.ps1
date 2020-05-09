Write-Host "Downloading Unity Hub..."

$url = "https://public-cdn.cloud.unity3d.com/hub/prod/UnityHubSetup.exe";
$outpath = "$PSScriptRoot/UnityHubSetup.exe"

$wc = New-Object System.Net.WebClient
$wc.DownloadFile($url, $outpath)

Write-Host "Download Complete, Starting installation..."

if ((-not $global:PSVersionTable.Platform) -or ($global:PSVersionTable.Platform -eq "Win32NT")) {
  Start-Process -Filepath $outpath -ArgumentList '/S' -Verb runas -Wait
}
else {
  Start-Process -Filepath $outpath -Verb runas -Wait
}


Write-Host "Installation Complete!"
