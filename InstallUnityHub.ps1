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
}
elseif ($global:PSVersionTable.OS.Contains("Darwin")) {
  $image = "UnityHubSetup"
  $package = "$image.dmg"
  $downloadPath = "$outPath/$package"
  $wc.DownloadFile("$baseUrl/$package", $downloadPath)

  #sudo hdiutil attach <image>.dmg
  $startProcessArgs = @{
    'FilePath'     = 'sudo';
    'ArgumentList' = @("hdiutil", "attach", $downloadPath, "-nobrowse");
    'PassThru'     = $true;
    'Wait'         = $true;
  }

  $process = Start-Process @startProcessArgs

  if ( $process.ExitCode -ne 0) {
    Write-Error "$(Get-Date): Failed with exit code: $($process.ExitCode)"
    exit 1
  }

  Get-ChildItem -Path "/Volumes"

  #Select-String -Pattern "/Volumes/Unity Hub"

  #Write-Host $dmgVolume

  # $dmgApp = Get-ChildItem $dmgVolume | Select-String -Pattern ".app"
  # Write-Host $dmgApp

  # #TODO Check if installed

  # #sudo cp -R /Volumes/<image>\ <image>.app /Applications
  # $startProcessArgs = @{
  #   'FilePath'     = 'sudo';
  #   'ArgumentList' = @("cp", "-R", "$dmgVolume", "$dmgApp", "/Applications");
  #   'PassThru'     = $true;
  #   'Wait'         = $true;
  # }

  # $process = Start-Process @startProcessArgs

  # if ( $process.ExitCode -ne 0) {
  #   Write-Error "$(Get-Date): Failed with exit code: $($process.ExitCode)"
  #   exit 1
  # }

  # #sudo hdiutil detach /Volumes/<image>
  # $startProcessArgs = @{
  #   'FilePath'     = 'sudo';
  #   'ArgumentList' = @("hdiutil", "detach", "/Volumes/$image");
  #   'PassThru'     = $true;
  #   'Wait'         = $true;
  # }

  # $process = Start-Process @startProcessArgs

  # if ( $process.ExitCode -ne 0) {
  #   Write-Error "$(Get-Date): Failed with exit code: $($process.ExitCode)"
  #   exit 1
  # }
}
elseif ($global:PSVersionTable.OS.Contains("Linux")) {
  #https://www.linuxdeveloper.space/install-unity-linux/
  $wc.DownloadFile("$baseUrl/UnityHub.AppImage", "$outPath/UnityHub.AppImage")
  #sudo chmod +x UnityHub.AppImage
  $startProcessArgs = @{
    'FilePath'     = 'sudo';
    'ArgumentList' = @("chmod", "+x", "$outPath/UnityHub.AppImage");
    'PassThru'     = $true;
    'Wait'         = $true;
  }

  $process = Start-Process @startProcessArgs

  if ( $process.ExitCode -ne 0) {
    Write-Error "$(Get-Date): Failed with exit code: $($process.ExitCode)"
    exit 1
  }
}

Write-Host "$(Get-Date): Succeeded."
