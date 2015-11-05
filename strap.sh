#!/bin/bash
#/ Usage: bin/strap.sh [--debug]
#/ Install development dependencies on Mac OS X.
set -e

[ "$1" = "--debug" ] && STRAP_DEBUG="1"
STRAP_SUCCESS=""

cleanup() {
  rm -f "$CLT_PLACEHOLDER" "$STRAP_BREWFILE"
  if [ -z "$STRAP_SUCCESS" ]; then
    if [ -n "$STRAP_STEP" ]; then
      echo "!!! $STRAP_STEP FAILED" >&2
    else
      echo "!!! FAILED" >&2
    fi
    if [ -z "$STRAP_DEBUG" ]; then
      echo "!!! Run '$0 --debug' for debugging output." >&2
      echo "!!! If you're stuck: file an issue with debugging output at:" >&2
      echo "!!!   $STRAP_ISSUES_URL" >&2
    fi
  fi
}

trap "cleanup" EXIT

if [ -n "$STRAP_DEBUG" ]; then
  set -x
else
  STRAP_QUIET_FLAG="-q"
  Q="$STRAP_QUIET_FLAG"
fi

STDIN_FILE_DESCRIPTOR="0"
[ -t "$STDIN_FILE_DESCRIPTOR" ] && STRAP_INTERACTIVE="1"


abort() { STRAP_STEP="";   echo "!!! $@" >&2; exit 1; }
log()   { STRAP_STEP="$@"; echo "--> $@"; }
logn()  { STRAP_STEP="$@"; printf -- "--> $@ "; }
logk()  { STRAP_STEP="";   echo "OK"; }

sw_vers -productVersion | grep $Q -E "^10.(9|10|11)" || {
  abort "Run Strap on Mac OS X 10.9/10/11."
}

[ "$USER" = "root" ] && abort "Run Strap as yourself, not root."
groups | grep $Q admin || abort "Add $USER to the admin group."

# Initialise sudo now to save prompting later.
log "Enter your password (for sudo access):"
sudo -k
sudo /usr/bin/true
logk

# Set some basic security settings.
logn "Configuring security settings:"
defaults write com.apple.Safari \
  com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaEnabled \
  -bool false
defaults write com.apple.Safari \
  com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaEnabledForLocalFiles \
  -bool false
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0
sudo defaults write /Library/Preferences/com.apple.alf globalstate -int 1

if [ -n "$STRAP_GIT_NAME" ] && [ -n "$STRAP_GIT_EMAIL" ]; then
  sudo defaults write /Library/Preferences/com.apple.loginwindow \
    LoginwindowText \
    "Found this computer? Please contact $STRAP_GIT_NAME at $STRAP_GIT_EMAIL."
fi
logk

# Check and enable full-disk encryption.
logn "Checking full-disk encryption status:"
if fdesetup status | grep $Q -E "FileVault is (On|Off, but will be enabled after the next restart)."; then
  logk
elif [ -n "$STRAP_CI" ]; then
  echo
  logn "Skipping full-disk encryption for CI"
elif [ -n "$STRAP_INTERACTIVE" ]; then
  echo
  logn "Enabling full-disk encryption on next reboot:"
  sudo fdesetup enable -user "$USER" \
    | tee ~/Desktop/"FileVault Recovery Key.txt"
  logk
else
  echo
  abort 'Run `sudo fdesetup enable -user "$USER"` to enable full-disk encryption.'
fi

# Install the Xcode Command Line Tools if Xcode isn't installed.
DEVELOPER_DIR=$("xcode-select" -print-path 2>/dev/null || true)
[ -z "$DEVELOPER_DIR" ] || ! [ -f "$DEVELOPER_DIR/usr/bin/git" ] && {
  log "Installing the Xcode Command Line Tools:"
  CLT_PLACEHOLDER="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
  sudo touch "$CLT_PLACEHOLDER"
  CLT_PACKAGE=$(softwareupdate -l | \
                grep -B 1 -E "Command Line (Developer|Tools)" | \
                awk -F"*" '/^ +\*/ {print $2}' | sed 's/^ *//' | head -n1)
  sudo softwareupdate -i "$CLT_PACKAGE"
  sudo rm -f "$CLT_PLACEHOLDER"
  logk
}

# Check if the Xcode license is agreed to and agree if not.
/usr/bin/xcrun clang 2>&1 | grep $Q license && {
  if [ -n "$STRAP_INTERACTIVE" ]; then
    logn "Asking for Xcode license confirmation:"
    sudo xcodebuild -license
    logk
  else
    abort 'Run `sudo xcodebuild -license` to agree to the Xcode license.'
  fi
}

# Setup Git
logn "Configuring Git:"
if [ -n "$STRAP_GIT_NAME" ] && ! git config user.name >/dev/null; then
  git config --global user.name "$STRAP_GIT_NAME"
fi

if [ -n "$STRAP_GIT_EMAIL" ] && ! git config user.email >/dev/null; then
  git config --global user.email "$STRAP_GIT_EMAIL"
fi

# Setup Homebrew directories and permissions.
logn "Installing Homebrew:"
HOMEBREW_PREFIX="/usr/local"
HOMEBREW_CACHE="/Library/Caches/Homebrew"
for dir in "$HOMEBREW_PREFIX" "$HOMEBREW_CACHE"; do
  [ -d "$dir" ] || sudo mkdir -p "$dir"
  sudo chown -R $USER:admin "$dir"
done

# Download Homebrew.
export GIT_DIR="$HOMEBREW_PREFIX/.git" GIT_WORK_TREE="$HOMEBREW_PREFIX"
git init $Q
git config remote.origin.url "https://github.com/Homebrew/homebrew"
git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
git rev-parse --verify --quiet origin/master >/dev/null || {
  git fetch $Q origin master:refs/remotes/origin/master --no-tags --depth=1
  git reset $Q --hard origin/master
}
sudo chmod g+rwx "$HOMEBREW_PREFIX"/* "$HOMEBREW_PREFIX"/.??*
unset GIT_DIR GIT_WORK_TREE
logk

# Install Homebrew Bundle, Cask, Services and Versions tap.
log "Installing Homebrew taps and extensions:"
export PATH="$HOMEBREW_PREFIX/bin:$PATH"
brew update
brew tap | grep -i $Q Homebrew/bundle || brew tap Homebrew/bundle
STRAP_BREWFILE="/tmp/Brewfile.strap"
cat > "$STRAP_BREWFILE" <<EOF
tap 'caskroom/cask'
tap 'homebrew/services'
tap 'homebrew/versions'
brew 'caskroom/cask/brew-cask'
EOF
brew bundle --file="$STRAP_BREWFILE"
rm -f "$STRAP_BREWFILE"
logk

# Check and install any remaining software updates.
logn "Checking for software updates:"
if softwareupdate -l 2>&1 | grep $Q "No new software available."; then
  logk
else
  echo
  log "Installing software updates:"
  if [ -z "$STRAP_CI" ]; then
    sudo softwareupdate --install --all
  else
    echo "Skipping software updates for CI"
  fi
  logk
fi

# Revoke sudo access again.
sudo -k

STRAP_SUCCESS="1"
log 'Finished! Install additional software with `brew install` and `brew cask install`.'
