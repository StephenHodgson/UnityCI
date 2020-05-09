Write-Host "Downloading Unity Hub..."

$url = "https://public-cdn.cloud.unity3d.com/hub/prod/UnityHubSetup.exe";
$outpath = "$PSScriptRoot/UnityHubSetup.exe"

$wc = New-Object System.Net.WebClient
$wc.DownloadFile($url, $outpath)

Write-Host "Download Complete, Starting installation..."

Start-Process -Filepath $outpath -ArgumentList "/S" -Verb runas- Wait -PassThru

Write-Host "Installation Complete!"
