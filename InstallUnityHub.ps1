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
    -command "`"C:\Program Files\Unity Hub\Unity Hub.exe`"-- --headless help"
  }
  else
  {
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

  $output = (sudo cp -R $dmgVolume $dmgAppPath /Applications)

  Write-Host "Installation Result: $output"

  #sudo cp -R /Volumes/<image>\ <image>.app /Applications
  # $startProcessArgs = @{
  #   'FilePath'     = 'sudo';
  #   'ArgumentList' = @("cp", "-R", "`"$dmgAppPath`"", "/Applications");
  #   'PassThru'     = $true;
  #   'Wait'         = $true;
  # }

  # $process = Start-Process @startProcessArgs

  # if ( $process.ExitCode -ne 0) {
  #   Write-Error "$(Get-Date): Failed with exit code: $($process.ExitCode)"
  #   exit 1
  # }

  hdiutil unmount $dmgVolume

  mdfind "kMDItemKind == 'Application'"

  #pwsh -noprofile -command "`"/Applications/Unity\ Hub.app/Contents/MacOS/Unity\ Hub-- --headless help`""
}
elseif ($global:PSVersionTable.OS.Contains("Linux")) {
  #https://www.linuxdeveloper.space/install-unity-linux/
  $wc.DownloadFile("$baseUrl/UnityHub.AppImage", "$outPath/UnityHub.AppImage")
  sudo chmod +x "$outPath/UnityHub.AppImage"
  #pwsh -noprofile -command "$outPath/UnityHub.AppImage-- --headless help"
}

Write-Host "$(Get-Date): Succeeded."
