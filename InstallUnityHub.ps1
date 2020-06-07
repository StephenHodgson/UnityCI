Write-Host "$(Get-Date): Downloading Unity Hub..."

$baseUrl = "https://public-cdn.cloud.unity3d.com/hub/prod";
$outPath = $PSScriptRoot
$EditorRoot = ""
$UnityVersion = "2019.1.14f1"
$UnityVersionChangeSet = "148b5891095a"

$wc = New-Object System.Net.WebClient

Write-Host "$(Get-Date): Download Complete, Starting installation..."

if ((-not $global:PSVersionTable.Platform) -or ($global:PSVersionTable.Platform -eq "Win32NT")) {
  exit 0
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

  $EditorRoot = "C:\Program Files\Unity\Hub\Editor\"
}
elseif ($global:PSVersionTable.OS.Contains("Darwin")) {
  exit 0
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
  $EditorRoot = "/Applications/Unity/Hub/Editor/"
  #. "/Applications/Unity Hub.app/Contents/MacOS/Unity Hub" -- --headless help
}
elseif ($global:PSVersionTable.OS.Contains("Linux")) {
  #https://www.linuxdeveloper.space/install-unity-linux/
  $wc.DownloadFile("$baseUrl/UnityHub.AppImage", "$outPath/UnityHub.AppImage")
  cd $outPath
  sudo chmod -v a+x UnityHub.AppImage
  sudo chmod -v a+x ./Install-Hub.sh

  # UnityHub.AppImage -- --headless help
  $hubPath = "./UnityHub.AppImage"
  $EditorRoot = "~/Unity/Hub/Editor/"

  file ./UnityHub.AppImage

  # Accept License
  ./UnityHub.AppImage

  Invoke-ExternalCommand -Command ./UnityHub.AppImage -Arguments '--','--headless','help'

  @'
#!/bin/sh
clear
echo "Try headless help from sh"
./UnityHub.AppImage -- --headless help
'@ > unityCli; chmod a+x unityCli
}

Write-Host "Install Hub Complete: $hubPath"
Write-Host ""
Write-Host "Unity HUB CLI Options:"
$p = Start-Process -Verbose -NoNewWindow -PassThru -Wait -FilePath "$hubPath" -ArgumentList '--', '--headless', 'help'
Write-Host ""
$p = Start-Process -Verbose -NoNewWindow -PassThru -Wait -FilePath "$hubPath" -ArgumentList '--', '--headless', 'install', "--version $UnityVersion", "--changeset $UnityVersionChangeSet"
Write-Host ""
$p = Start-Process -Verbose -NoNewWindow -PassThru -Wait -FilePath "$hubPath" -ArgumentList '--', '--headless', 'editors', '-i'

if ( Test-Path "$EditorRoot$UnityVersion" )
{
  #TODO Get editor installation path and search modules.json for a list of all valid modules available then download them all
} else
{
  Write-Error "Failed to resolve editor installation path at $EditorRoot$UnityVersion"
  exit 1
}

Write-Host ""
$p = Start-Process -Verbose -NoNewWindow -PassThru -Wait -FilePath $hubPath -ArgumentList '--', '--headless', 'im', "--version $UnityVersion", '-m', 'windows-il2cpp', '-m', 'universal-windows-platform', '-m', 'android','-m', 'android-sdk-ndk-tools'
Write-Host ""
Write-Host "Install Complete!"
exit 0