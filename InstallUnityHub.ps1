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
    #"Unity Hub.exe" -- --headless help
    $hubPath = "C:\Program Files\Unity Hub\Unity Hub.exe"
    #. 'C:\Program Files\Unity Hub\Unity Hub.exe' -- --headless help
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
  sudo cp -rf "`"$dmgAppPath`"" "/Applications"
  hdiutil unmount $dmgVolume

  #mdfind "kMDItemKind == 'Application'"

  # /Applications/Unity\ Hub.app/Contents/MacOS/Unity\ Hub -- --headless help
  $hubPath = "/Applications/Unity Hub.app/Contents/MacOS/Unity Hub"
  #. "/Applications/Unity Hub.app/Contents/MacOS/Unity Hub" -- --headless help
}
elseif ($global:PSVersionTable.OS.Contains("Linux")) {
  #https://www.linuxdeveloper.space/install-unity-linux/
  $wc.DownloadFile("$baseUrl/UnityHub.AppImage", "$outPath/UnityHub.AppImage")
  chmod -v +x "$outPath/UnityHub.AppImage"
  # UnityHub.AppImage -- --headless help
  $hubPath = "$outPath/UnityHub.AppImage"
  cd $outPath -v

  file ./UnityHub.AppImage

  # Accept License
  './UnityHub.AppImage'

  # Test inline calls
  './UnityHub.AppImage -- --headless help'
}

Write-Host "Install Hub Complete: $hubPath"
Write-Host ""
Write-Host "Unity HUB CLI Options:"
$p = Start-Process -Verbose -NoNewWindow -PassThru -Wait -FilePath \""$hubPath\"" -ArgumentList '--', '\"--headless help\"'
Write-Host ""
$p = Start-Process -FilePath "$hubPath" -ArgumentList "-- --headless install --version 2019.1.14f1 --changeset 148b5891095a" -Verbose -NoNewWindow -PassThru -Wait
Write-Host ""
$p = Start-Process -FilePath "$hubPath" -ArgumentList "-- --headless editors -i" -Verbose -NoNewWindow -PassThru -Wait

#TODO Get editor installation path and search modules.json for a list of all valid modules available then download them all

Write-Host ""
#$p = Start-Process -FilePath $hubPath -ArgumentList "-- --headless im --version 2019.1.14f1 -m windows-il2cpp -m universal-windows-platform -m android -m android-sdk-ndk-tools" -Verbose -NoNewWindow -PassThru -Wait
Write-Host ""
Write-Host "Install Complete!"
exit 0