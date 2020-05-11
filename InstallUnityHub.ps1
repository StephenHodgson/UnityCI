Write-Host "$(Get-Date): Downloading Unity Hub..."

$baseUrl = "https://public-cdn.cloud.unity3d.com/hub/prod";
$outPath = $PSScriptRoot

$wc = New-Object System.Net.WebClient

Write-Host "$(Get-Date): Download Complete, Starting installation..."

if ((-not $global:PSVersionTable.Platform) -or ($global:PSVersionTable.Platform -eq "Win32NT")) {
  $wc.DownloadFile("$baseUrl/UnityHubSetup.exe", "$outPath/UnityHubSetup.exe")

  $startProcessArgs = @{
    'FilePath'     = "$outPath/UnityHubSetup.exe";
    'ArgumentList' = @("/S");
    'PassThru'     = $true;
    'Wait'         = $true;
  }

  $process = Start-Process @startProcessArgs

  if ( $process.ExitCode -ne 0) {
    Write-Error "$(Get-Date): Failed with exit code: $($process.ExitCode)"
    exit 1
  }

  if( Test-Path "C:\Program Files\Unity Hub\Unity Hub.exe" )
  {
    cmd /c "C:\Program Files\Unity Hub\Unity Hub.exe"-- --headless help
  }
  else
  {
    Write-Error "Unity Hub.exe path not found!"
    exit 1
  }
}
elseif ($global:PSVersionTable.OS.Contains("Darwin")) {
  $package = "UnityHubSetup.dmg"
  $downloadPath = "$outPath/$package"
  $wc.DownloadFile("$baseUrl/$package", $downloadPath)

  $dmgVolume = (sudo hdiutil attach $downloadPath -nobrowse) | Select-String -Pattern '\/Volumes\/.*' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Value } | select-object -first 1

  Write-Host $dmgVolume

  $dmgAppPath = (find "$DMGVolume" -name "*.app" -depth 1)

  Write-Host $dmgAppPath

  sudo cp -rvf "`"$dmgAppPath`"" "/Applications"

  hdiutil unmount $dmgVolume

  mdfind "kMDItemKind == 'Application'"

  # /Applications/Unity\ Hub.app/Contents/MacOS/Unity\ Hub -- --headless help
  $output = (& "/Applications/Unity\ Hub.app/Contents/MacOS/Unity\ Hub" -- --headless help)
  Write-Output $output
}
elseif ($global:PSVersionTable.OS.Contains("Linux")) {
  #https://www.linuxdeveloper.space/install-unity-linux/
  $wc.DownloadFile("$baseUrl/UnityHub.AppImage", "$outPath/UnityHub.AppImage")
  sudo chmod +x "$outPath/UnityHub.AppImage"
  # Unity\ Hub.AppImage -- --headless help
  $output = (& "Unity\ Hub.AppImage" -- --headless help)
  Write-Output $output
}

Write-Host "$(Get-Date): Succeeded."
