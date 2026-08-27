#!/usr/bin/env bash
# macOS system settings. Re-runnable.
set -euo pipefail

echo "==> iTerm2"
it() { defaults write com.googlecode.iterm2 "$@"; }
it "Default Bookmark Guid" -string "D3V00000-1111-4222-8333-444455556666"  # the "Dev" dynamic profile
it PromptOnQuit -bool false
it QuitWhenAllWindowsClosed -bool false
it HideScrollbar -bool true
it UseBorder -bool false
it TabStyleWithAutomaticOption -int 5      # minimal tab bar
it HideTabCloseButton -bool true
it AlternateMouseScroll -bool true         # scroll wheel works in less/vim
it DimInactiveSplitPanes -bool true
it SplitPaneDimmingAmount -float 0.15
it CopySelection -bool true
it CopyLastNewline -bool false
it SoundForEsc -bool false
it AdjustWindowForFontSizeChange -bool true
it DisableFullscreenTransparency -bool true
it SmartPlacement -bool true
it NoSyncNeverRemindPrefsChangesLostForFile -bool true
it NoSyncDoNotWarnBeforeMultilinePaste -bool true

echo "==> Keyboard: Cmd+Space switches input source, Spotlight moves to Opt+Space"
# Space is ASCII 32 / keycode 49.  Cmd=1048576  Opt=524288  Ctrl+Opt=786432  Cmd+Opt=1572864
hk() {  # hk <id> <modifier>
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add "$1" "
  <dict><key>enabled</key><true/><key>value</key><dict>
    <key>parameters</key><array>
      <integer>32</integer><integer>49</integer><integer>$2</integer>
    </array><key>type</key><string>standard</string>
  </dict></dict>"
}
hk 60 1048576   # select previous input source -> Cmd+Space
hk 61 786432    # select next input source     -> Ctrl+Opt+Space
hk 64 524288    # Spotlight                    -> Opt+Space
hk 65 1572864   # Finder search                -> Cmd+Opt+Space

echo "==> Menu bar"
defaults write com.apple.TextInputMenu visible -bool true          # language indicator
defaults write com.apple.controlcenter BatteryShowPercentage -bool true
# These modules read visibility from the per-host domain as an int:
#   18 = always show in menu bar, 8 = hide, 2 = show only when active.
# The "NSStatusItem Visible <X>" booleans get pruned by ControlCenter on restart.
defaults -currentHost write com.apple.controlcenter.plist Sound     -int 18
defaults -currentHost write com.apple.controlcenter.plist Bluetooth -int 18
for item in NowPlaying ScreenMirroring Display; do
  defaults write com.apple.controlcenter "NSStatusItem Visible $item" -bool false
done

echo "==> Finder & misc"
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"      # list view
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"      # search current folder
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false       # key repeat over accents
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write com.apple.screencapture location -string "$HOME/Downloads"
defaults write com.apple.screencapture disable-shadow -bool true

echo "==> Applying"
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u 2>/dev/null || true
killall Finder ControlCenter TextInputMenuAgent 2>/dev/null || true
echo "Done. Some settings need a logout to take full effect."
