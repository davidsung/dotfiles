#!/bin/sh
# .install-password-manager.sh  (at the root of the source dir)
# Exit early if already available
command -v op >/dev/null 2>&1 && exit 0

case "$(uname -s)" in
  Darwin)
    # Install Homebrew if needed
    if ! command -v brew >/dev/null 2>&1; then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      # Add brew to PATH for Apple Silicon / Intel
      eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
    fi
    # Install both 1Password App and CLI
    brew install --cask 1password-cli 1password
    ;;
  *)
    echo "Note: automatic 1Password CLI install not yet supported on $(uname -s)" >&2
    ;;
esac
