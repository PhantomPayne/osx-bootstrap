
#####
#navigation
#####
defaults write NSGlobalDomain AppleEnableSwipeNavigateWithScrolls -bool TRUE
defaults write -g com.apple.swipescrolldirection -bool FALSE

#####
# XCODE
#####
# Always use spaces for indenting
defaults write com.apple.dt.Xcode DVTTextIndentUsingTabs -bool false

# Show tab bar
defaults write com.apple.dt.Xcode AlwaysShowTabBar -bool true


#####
#top menu bar
####
defaults write com.apple.menuextra.battery ShowPercent -string "YES"
defaults write com.apple.dock showhidden -bool true

####
# Sanity
####

# Disable Smart Quotes and Smart dashes!
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false


# Time Machine
defaults write com.apple.TimeMachine 'AutoBackup' -bool false
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true
sudo tmutil disablelocal

defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true


#setup the dock
defaults write com.apple.dock showhidden -bool true

# setup iterm2
defaults write com.googlecode.iterm2 PromptOnQuit -bool false

#########
# finder 
#########

# show all filenames
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# show all files
defaults write com.apple.finder AppleShowAllFiles YES
# search local file
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
# don't complain about changing extensions
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool true
# show ~/Library
chflags nohidden ~/Library

defaults write com.apple.finder QLEnableTextSelection -bool true
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
defaults write com.apple.finder ShowPathbar -bool true

defaults write com.apple.finder NewWindowTarget -string "PfLo"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}"


