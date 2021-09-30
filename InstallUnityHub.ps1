$version = "m_EditorVersionWithRevision: 2019.1.14f1 (148b5891095a)"

Write-Host "$(Get-Date): Downloading Unity Hub..."

$baseUrl = "https://public-cdn.cloud.unity3d.com/hub/prod";
$outPath = $PSScriptRoot
$pattern = '(?<version>(?:(?<major>\d+)\.)?(?:(?<minor>\d+)\.)?(?:(?<patch>\d+[fab]\d+)\b))|((?:\((?<revision>\w+))\))'
$versonMatches = [regex]::Matches($version, $pattern)
$UnityVersion = $versonMatches[0].Groups['version'].Value.Trim()
$UnityVersionChangeSet = $versonMatches[1].Groups['revision'].Value.Trim()


if ( (-not $global:PSVersionTable.Platform) -or ($global:PSVersionTable.Platform -eq "Win32NT") ) {
  $hubPath = "C:\Program Files\Unity Hub\Unity Hub.exe"
  $editorRootPath = "C:\Program Files\Unity\Hub\Editor\"
  $editorFileEx = "\Editor\Unity.exe"
  $modules = @('windows-il2cpp', 'universal-windows-platform', 'lumin', 'webgl', 'android')

  #"Unity Hub.exe" -- --headless help
  #. 'C:\Program Files\Unity Hub\Unity Hub.exe' -- --headless help
  function unity-hub {
    $p = Start-Process -Verbose -NoNewWindow -PassThru -Wait -FilePath "$hubPath" -ArgumentList (@('--','--headless') + $args.Split(" "))
  }
}
elseif ( $global:PSVersionTable.OS.Contains("Darwin") ) {
  $hubPath = "/Applications/Unity Hub.app/Contents/MacOS/Unity Hub"
  $editorRootPath = "/Applications/Unity/Hub/Editor/"
  $editorFileEx = "/Unity.app"
  $modules = @('mac-il2cpp', 'ios', 'lumin', 'webgl', 'android')

  # /Applications/Unity\ Hub.app/Contents/MacOS/Unity\ Hub -- --headless help
  #. "/Applications/Unity Hub.app/Contents/MacOS/Unity Hub" -- --headless help
  function unity-hub {
    $p = Start-Process -Verbose -NoNewWindow -PassThru -Wait -FilePath "$hubPath" -ArgumentList (@('--','--headless') + $args.Split(" "))
  }
}
elseif ( $global:PSVersionTable.OS.Contains("Linux") ) {
  $hubPath = "$HOME/Unity Hub/UnityHub.AppImage"
  $editorRootPath = "$HOME/Unity/Hub/Editor/"
  $editorFileEx = "Editor/Unity"
  $modules = @('linux', 'lumin', 'webgl', 'android')

  # /UnityHub.AppImage --headless help
  # xvfb-run --auto-servernum "$HOME/Unity Hub/UnityHub.AppImage" --headless help
  function unity-hub {
    xvfb-run --auto-servernum "$hubPath" --headless $args
  }
}

# Install hub if not found
if ( -not (Test-Path -Path "$hubPath") ) {
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
  }
  elseif ($global:PSVersionTable.OS.Contains("Linux")) {

    mkdir -pv "$HOME/Unity Hub" "$HOME/.config/Unity Hub" "$editorRootPath"
    sudo apt-get update
    sudo apt-get install -y libgconf-2-4 libglu1 libasound2 libgtk2.0-0 libgtk-3-0 libnss3 zenity xvfb

    #https://www.linuxdeveloper.space/install-unity-linux/
    $wc.DownloadFile("$baseUrl/UnityHub.AppImage", "$hubPath")
    chmod -v a+x "$hubPath"
    touch "$HOME/.config/Unity Hub/eulaAccepted"
  }
}

if ( -not (Test-Path "$hubPath") ) {
  Write-Error "$hubPath path not found!"
  exit 1
}

Write-Host "Unity Hub found at `"$hubPath`""
Write-Host ""

Write-Host "Editor root path currently set to: `"$editorRootPath`""
Write-Host ""

unity-hub help
Write-Host ""

$editorPath = "{0}{1}{2}" -f $editorRootPath,$unityVersion,$editorFileEx

if ( -not (Test-Path -Path $editorPath) ) {
  Write-Host "Installing $unityVersion ($unityVersionChangeSet)..."
  Write-Host ""
  $installArgs = @('install',"--version $unityVersion","--changeset $unityVersionChangeSet",'--cm')

  foreach ( $module in $modules ) {
    $installArgs += '-m'
    $installArgs += $module
    Write-Host " + adding module: $module"
  }

  $installArgsString = $installArgs -join " "

  unity-hub $installArgsString
  Write-Host ""
  unity-hub editors -i
  Write-Host ""
}

if ( -not (Test-Path -Path $editorPath) ) {
  Write-Error "Failed to validate installed editor path at $editorPath"
  exit 1
}

Write-Host "UnityEditor path set to: $editorPath"
exit 0
