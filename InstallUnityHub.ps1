Write-Host "$(Get-Date): Downloading Unity Hub..."

$baseUrl = "https://public-cdn.cloud.unity3d.com/hub/prod";
$outPath = $PSScriptRoot
$EditorRoot = ""
$UnityVersion = "2019.1.14f1"
$UnityVersionChangeSet = "148b5891095a"

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

  # Run Installer
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
  $package = "UnityHubSetup.dmg"
  $downloadPath = "$outPath/$package"
  $wc.DownloadFile("$baseUrl/$package", $downloadPath)

  $dmgVolume = (sudo hdiutil attach $downloadPath -nobrowse) | Select-String -Pattern '\/Volumes\/.*' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Value } | select-object -first 1
  Write-Host $dmgVolume
  $dmgAppPath = (find "$DMGVolume" -name "*.app" -depth 1)
  Write-Host $dmgAppPath
  sudo cp -rf "`"$dmgAppPath`"" "/Applications"
  hdiutil unmount $dmgVolume

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

  # UnityHub.AppImage -- --headless help
  $hubPath = "./UnityHub.AppImage"
  $EditorRoot = "~/Unity/Hub/Editor/"

  file ./UnityHub.AppImage

  # Accept License
  ./UnityHub.AppImage

  & "./UnityHub.AppImage" -- --headless help
}

Write-Host "Install Hub Complete: $hubPath"
Write-Host ""
Write-Host "Unity HUB CLI Options:"
$p = Start-Process -Verbose -NoNewWindow -PassThru -Wait -FilePath "$hubPath" -ArgumentList '--', '--headless', 'help'
Write-Host ""
Write-Host "Success? " ($p.ExitCode -eq 0)

Write-Host ""
$p = Start-Process -Verbose -NoNewWindow -PassThru -Wait -FilePath "$hubPath" -ArgumentList '--', '--headless', 'install', "--version $UnityVersion", "--changeset $UnityVersionChangeSet"
Write-Host ""
Write-Host "Success? " ($p.ExitCode -eq 0)
Write-Host ""
$p = Start-Process -Verbose -NoNewWindow -PassThru -Wait -FilePath "$hubPath" -ArgumentList '--', '--headless', 'editors', '-i'
Write-Host ""
Write-Host "Success? " ($p.ExitCode -eq 0)

$modulesPath = "$EditorRoot$UnityVersion"

if ( Test-Path $modulesPath )
{
  $modulesPath = '{0}{1}modules.json' -f $modulesPath,[IO.Path]::DirectorySeparatorChar

  if( Test-Path $modulesPath )
  {
    Write-Host "Modules Manifest: " $modulesPath

    Get-Content -Raw -Path $modulesPath | ConvertFrom-Json | Select-Object -Property id,name,visible | ForEach-Object
    {
      Write-Host $_.name $_.id $_.visible
    }
  } else
  {
    Write-Error "Failed to resolve modules path at $modulesPath"
    exit 1
  }
} else
{
  Write-Error "Failed to resolve editor installation path at $EditorRoot$UnityVersion"
  exit 1
}

exit 0 #Temp Return Until work below is completed

Write-Host ""
$p = Start-Process -Verbose -NoNewWindow -PassThru -Wait -FilePath $hubPath -ArgumentList '--', '--headless', 'im', "--version $UnityVersion", '-m', 'windows-il2cpp', '-m', 'universal-windows-platform', '-m', 'android','-m', 'android-sdk-ndk-tools'
Write-Host ""
Write-Host "Success? " ($p.ExitCode -eq 0)
Write-Host ""
Write-Host "Install Complete!"
exit 0