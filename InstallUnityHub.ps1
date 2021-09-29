Write-Host "$(Get-Date): Downloading Unity Hub..."

$baseUrl = "https://public-cdn.cloud.unity3d.com/hub/prod";
$outPath = $PSScriptRoot
$editorPath = ""
$editorFileEx = ""
$version = "m_EditorVersionWithRevision: 2019.1.14f1 (148b5891095a)"
$pattern = '(?<version>(?:(?<major>\d+)\.)?(?:(?<minor>\d+)\.)?(?:(?<patch>\d+[fab]\d+)\b))|((?:\((?<revision>\w+))\))'
$versonMatches = [regex]::Matches($version, $pattern)
$UnityVersion = $versonMatches[0].Groups['version'].Value.Trim()
$UnityVersionChangeSet = $versonMatches[1].Groups['revision'].Value.Trim()

$wc = New-Object System.Net.WebClient

Write-Host "$(Get-Date): Download Complete, Starting installation..."

$baseArgs = @('--headless')

if ((-not $global:PSVersionTable.Platform) -or ($global:PSVersionTable.Platform -eq "Win32NT")) {
  $wc.DownloadFile("$baseUrl/UnityHubSetup.exe", "$outPath/UnityHubSetup.exe")
  $startProcessArgs = @{
    'FilePath'     = "$outPath/UnityHubSetup.exe";
    'ArgumentList' = @('/S');
    'PassThru'     = $true;
    'Wait'         = $true;
  }

  # Run Installer
  $process = Start-Process @startProcessArgs

  if ( $process.ExitCode -ne 0) {
    Write-Error "$(Get-Date): Failed with exit code: $($process.ExitCode)"
    exit 1
  }

  $hubPath = "C:\Program Files\Unity Hub\Unity Hub.exe"
  $editorPath = "C:\Program Files\Unity\Hub\Editor\"
  $editorFileEx = "Editor\Unity.exe"

  if ( -not (Test-Path "$hubPath") ) {
    Write-Error "Unity Hub.exe path not found!"
    exit 1
  }

  $baseArgs = @('--','--headless')
  #"Unity Hub.exe" -- --headless help
  #. 'C:\Program Files\Unity Hub\Unity Hub.exe' -- --headless help
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

  $hubPath = "/Applications/Unity Hub.app/Contents/MacOS/Unity Hub"
  $editorPath = "/Applications/Unity/Hub/Editor/"
  $editorFileEx = "Unity.app"
  $baseArgs = @('--','--headless')
  # /Applications/Unity\ Hub.app/Contents/MacOS/Unity\ Hub -- --headless help
  #. "/Applications/Unity Hub.app/Contents/MacOS/Unity Hub" -- --headless help
}
elseif ($global:PSVersionTable.OS.Contains("Linux")) {
  $hubInstallationPath = "$HOME/Unity Hub/UnityHub.AppImage"
  $hubPath = "$HOME/Unity/unity-hub.sh"
  $editorPath = "$HOME/Unity/Hub/Editor/"
  $editorFileEx = "Unity"

  mkdir -pv "$HOME/Unity Hub" "$HOME/.config/Unity Hub" "$editorPath"
  sudo apt-get update
  sudo apt-get install -y libgconf-2-4 libglu1 libasound2 libgtk2.0-0 libgtk-3-0 libnss3 zenity xvfb

  #https://www.linuxdeveloper.space/install-unity-linux/
  $wc.DownloadFile("$baseUrl/UnityHub.AppImage", "$hubInstallationPath")
  chmod -v a+x "$hubInstallationPath"
  touch "$HOME/.config/Unity Hub/eulaAccepted"
  touch "$hubPath"
  sudo echo "#!/bin/bash\necho `"`"Hi`"`"\nxvfb-run --auto-servernum `"`"$hubInstallationPath`"`" `"`"$@`"`"" > "$hubPath"
  echo "$(cat $hubPath)"
  sudo chmod -v a+x "$hubPath"
  # /UnityHub.AppImage --headless help
  . "$hubPath" --headless help
}

Write-Host "Install Hub Complete: $hubPath"
Write-Host ""
Write-Host "Unity HUB CLI Options:"
$p = Start-Process -Verbose -NoNewWindow -PassThru -Wait -FilePath "$hubPath" -ArgumentList ($baseArgs + @('help'))
Write-Host ""
Write-Host "Successful exit code? " ($p.ExitCode -eq 0)
Write-Host ""
$p = Start-Process -Verbose -NoNewWindow -PassThru -Wait -FilePath "$hubPath" -ArgumentList ($baseArgs + @('install',"--version $UnityVersion","--changeset $UnityVersionChangeSet"))
Write-Host ""
Write-Host "Successful exit code? " ($p.ExitCode -eq 0)
Write-Host ""
$p = Start-Process -Verbose -NoNewWindow -PassThru -Wait -FilePath "$hubPath" -ArgumentList ($baseArgs + @('editors','-i'))
Write-Host ""
Write-Host "Successful exit code? " ($p.ExitCode -eq 0)

$modulesPath = "$editorPath$UnityVersion"
$editorPath = '{0}{1}{2}' -f $modulesPath,[IO.Path]::DirectorySeparatorChar,$editorFileEx

if ( -not (Test-Path -Path $editorPath) ) {
  Write-Error "Failed to validate installed editor path at $editorPath"
  exit 1
}

if ( Test-Path -Path $modulesPath ) {
  $modulesPath = '{0}{1}modules.json' -f $modulesPath,[IO.Path]::DirectorySeparatorChar

  if ( Test-Path -Path $modulesPath ) {
    Write-Host "Modules Manifest: "$modulesPath
    $modules = ($baseArgs + @('im',"--version $UnityVersion"))

    foreach ($module in (Get-Content -Raw -Path $modulesPath | ConvertFrom-Json)) {
      if ( ($module.category -eq 'Platforms') -and ($module.visible -eq $true) ) {
        Write-Host "found platform module" $module.id
        $modules += '-m'
        $modules += $module.id
      }
    }

    Write-Host ""
    $p = Start-Process -Verbose -NoNewWindow -PassThru -Wait -FilePath "$hubPath" -ArgumentList $modules
    Write-Host ""
    Write-Host "Successful exit code? " ($p.ExitCode -eq 0)
  } else {
    Write-Error "Failed to resolve modules path at $modulesPath"
    exit 1
  }
} else {
  Write-Error "Failed to resolve editor installation path at $modulesPath"
  exit 1
}

Write-Host "Install Complete!"
Write-Host "UnityEditor path set to: $editorPath"
Write-Output "##vso[task.setvariable variable=EditorPath]$editorPath"
exit 0
