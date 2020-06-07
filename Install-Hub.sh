#!/bin/bash
echo "Installing dependancies..."

echo "Installing unity hub..."
wget https://public-cdn.cloud.unity3d.com/hub/prod/UnityHub.AppImage
sudo chmod -v a+x UnityHub.AppImage
./UnityHub.AppImage
zenity --text-info --title="Unity Hub" --filename=/app/extra/eula.txt --ok-label=Agree --cancel-label=Disagree || exit 1
touch /var/data/eula-accept
./UnityHub.AppImage -- --headless help
./UnityHub.AppImage -- --headless install --version 2019.1.14f1 --changeset 148b5891095a