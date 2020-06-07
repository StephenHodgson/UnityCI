#!/bin/bash
echo "Installing unity hub..."
wget https://public-cdn.cloud.unity3d.com/hub/prod/UnityHub.AppImage
sudo chmod -v a+x UnityHub.AppImage
echo "Accept License"
./UnityHub.AppImage
echo "Test Help Command"
./UnityHub.AppImage -- --headless help
echo "Install Editor"
./UnityHub.AppImage -- --headless install --version 2019.1.14f1 --changeset 148b5891095a