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

  #"Unity Hub.exe" -- --headless help
  #. 'C:\Program Files\Unity Hub\Unity Hub.exe' -- --headless help
  function unity-hub {
    $p = Start-Process -Verbose -NoNewWindow -PassThru -Wait -FilePath "$hubPath" -ArgumentList (@('--','--headless') + $args.Split(" "))
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

  $hubPath = "/Applications/Unity Hub.app/Contents/MacOS/Unity Hub"
  $editorPath = "/Applications/Unity/Hub/Editor/"
  $editorFileEx = "Unity.app"
  # /Applications/Unity\ Hub.app/Contents/MacOS/Unity\ Hub -- --headless help
  #. "/Applications/Unity Hub.app/Contents/MacOS/Unity Hub" -- --headless help
  function unity-hub {
    $p = Start-Process -Verbose -NoNewWindow -PassThru -Wait -FilePath "$hubPath" -ArgumentList (@('--','--headless') + $args.Split(" "))
  }
}
elseif ($global:PSVersionTable.OS.Contains("Linux")) {
  $hubPath = "$HOME/Unity Hub/UnityHub.AppImage"
  $editorPath = "$HOME/Unity/Hub/Editor/"
  $editorFileEx = "Editor/Unity"

  mkdir -pv "$HOME/Unity Hub" "$HOME/.config/Unity Hub" "$editorPath"
  sudo apt-get update
  sudo apt-get install -y libgconf-2-4 libglu1 libasound2 libgtk2.0-0 libgtk-3-0 libnss3 zenity xvfb

  #https://www.linuxdeveloper.space/install-unity-linux/
  $wc.DownloadFile("$baseUrl/UnityHub.AppImage", "$hubPath")
  chmod -v a+x "$hubPath"
  touch "$HOME/.config/Unity Hub/eulaAccepted"

  function unity-hub {
    xvfb-run --auto-servernum "$hubPath" --headless $args
  }

  # /UnityHub.AppImage --headless help
  # xvfb-run --auto-servernum "$HOME/Unity Hub/UnityHub.AppImage" --headless help
}

Write-Host "Install Hub Complete: $hubPath"
Write-Host ""
Write-Host "Unity HUB CLI Options:"
unity-hub help
Write-Host ""
unity-hub ip -g
Write-Host ""
unity-hub install --version $UnityVersion --changeset $UnityVersionChangeSet
Write-Host ""
unity-hub editors -i
Write-Host ""

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
    $modules = @('im',"--version $UnityVersion")

    foreach ($module in (Get-Content -Raw -Path $modulesPath | ConvertFrom-Json)) {
      if ( ($module.category -eq 'Platforms') -and ($module.visible -eq $true) ) {
        Write-Host "found platform module" $module.id
        $modules += '-m'
        $modules += $module.id
      }
    }

    Write-Host ""
    $hubArgs = [system.String]::Join(" ", $modules)
    unity-hub $hubArgs
    Write-Host ""
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
exit 0
