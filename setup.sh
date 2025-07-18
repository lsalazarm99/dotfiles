#!/usr/bin/env bash

echo "⚙️ Setting up your environment..."

# Copy configuration files
if [ ! -d "$HOME"/.config ]; then mkdir "$HOME"/.config; fi
if [ ! -d "$HOME"/.ssh ]; then mkdir "$HOME"/.ssh; fi

cp -rf "$(dirname "$0")"/src/.config/* "$HOME"/.config
cp -rf "$(dirname "$0")"/src/.ssh/* "$HOME"/.ssh
cp -f "$(dirname "$0")"/src/{.gitconfig,.lessfilter} "$HOME"

echo "⚙️ Configuration files copied."

# Create the keyrings directory if it doesn't exist
sudo install -dm 755 /etc/apt/keyrings

# Add the fish PPA if it's not already been added
if ! grep -q "fish-shell" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
  echo "⚙️ Adding fish PPA..."
  curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x88421e703edc7af54967ded473c9fcc9e2bb48da" | gpg --dearmor | sudo tee /etc/apt/keyrings/shells_fish_release_4.gpg 1>/dev/null
  echo "deb [signed-by=/etc/apt/keyrings/shells_fish_release_4.gpg] https://ppa.launchpadcontent.net/fish-shell/release-4/ubuntu $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/shells:fish:release:4.list
  echo "⚙️ fish PPA added."
fi

# Add the mise PPA if it's not already been added
if ! grep -q "mise.jdx.dev" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
  echo "⚙️ Adding mise PPA..."
  curl -fsSL https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | sudo tee /etc/apt/keyrings/mise-archive-keyring.gpg 1>/dev/null
  echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list
  echo "⚙️ mise PPA added."
fi

# Update the packages list
echo "⚙️ Updating package list..."
sudo apt-get update
echo "⚙️ Package list updated."

# Install packages
echo "⚙️ Installing packages..."
sudo apt-get install -y bat btop eza fd-find fish fzf mc mise micro ripgrep
echo "⚙️ Packages installed."

# Add lesspipe.sh if it doesn't exist
if [[ ! -f /usr/local/bin/lesspipe.sh ]]; then
  echo "⚙️ Installing lesspipe..."
  sudo curl https://raw.githubusercontent.com/wofr06/lesspipe/refs/heads/lesspipe/lesspipe.sh -o /usr/local/bin/lesspipe.sh
  echo "⚙️ lesspipe installation completed."
fi

# Install starship if it doesn't exist
if [[ ! -f /usr/local/bin/starship ]]; then
  echo "⚙️ Installing starship..."
  curl -sS https://starship.rs/install.sh | sh -s -- -y
  echo "⚙️ starship installation completed."
fi

# Install fish plugins
echo "⚙️ Installing fish plugins..."
fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher update </dev/null'
echo "⚙️ fish plugins installed."

# Make any interactive shell use fish
if ! grep -q "exec fish" "$HOME"/.bashrc; then
  echo -e '\nif [[ $- == *i* ]] && [[ -z "$BASH_EXECUTION" ]] && [[ "$SHELL" != */fish ]]; then\n  export BASH_EXECUTION=1\n  exec fish\nfi' >>"$HOME"/.bashrc
fi

# Install gemini-cli
if ! command -v gemini &> /dev/null; then
  echo "⚙️ Installing gemini-cli..."
  mise exec node -- npx https://github.com/google-gemini/gemini-cli
  echo "⚙️ gemini-cli installation completed."
fi

echo "⚙️ Finished setting up your environment!"
