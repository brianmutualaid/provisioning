## Overview

The most recent checklist of things to install and commands to run to set up macOS from a fresh install.

## Install

* 1Password
* App Cleaner
* GIMP
* Google Chrome
* iTerm2
* Little Snitch
* Magnet (App Store)
* Microsoft Office
* Slack (App Store)
* Transmission
* Tunnelblick
* Virtualbox
* VLC
* Wireshark
* Xcode (App Store)
* YubiKey Personalization Tool

## Run

```
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew install tmux
brew install gpg
brew tap caskroom/fonts
brew cask install font-source-code-pro
cd ~
curl -O https://raw.githubusercontent.com/brianreumere/provisioning/master/files/common/home/brian/.tmux.conf
curl -O https://raw.githubusercontent.com/brianreumere/provisioning/master/files/common/home/brian/.vimrc
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
defaults write com.apple.Dock showhidden -bool YES
```
