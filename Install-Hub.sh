#!/bin/bash
echo "Installing unity hub..."
wget https://public-cdn.cloud.unity3d.com/hub/prod/UnityHub.AppImage
sudo chmod -v a+x UnityHub.AppImage
./UnityHub.AppImage -- --headless help
./UnityHub.AppImage -- --headless install --version 2019.1.14f1 --changeset 148b5891095a