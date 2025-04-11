#!/usr/bin/env bash

echo "⚙️ Setting up your environment..."

# Create the .config directory
if [ ! -d "$HOME"/.config ]; then
  mkdir "$HOME"/.config
  echo "⚙️ ~/.config directory created."
fi

# Copy configuration files
cp -f "$(dirname "$0")"/src/{.gitconfig,.lessfilter} "$HOME"
cp -rf "$(dirname "$0")"/src/.config/* "$HOME"/.config
echo "⚙️ Configuration files copied."

# Create the .ssh directory
if [ ! -d "$HOME"/.ssh ]; then
  mkdir "$HOME"/.ssh
  echo "⚙️ ~/.ssh directory created."
fi

# Create the .ssh/allowed_signers template file
if [ ! -f "$HOME"/.ssh/allowed_signers ]; then
  echo '# Add your keys here as "<email> <key>"' >"$HOME"/.ssh/allowed_signers
  echo "⚙️ ~/.ssh/allowed_signers template file created."
fi

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
sudo apt update
echo "⚙️ Package list updated."

# Install packages
echo "⚙️ Installing packages..."
for pkg in bat btop eza fd-find fish fzf jq mc mise micro ripgrep; do
  if ! dpkg -l | grep -qw "$pkg"; then
    echo "⚙️ Installing $pkg..."
    sudo apt install -y "$pkg"
  else
    echo "⚙️ $pkg is already installed."
  fi
done
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

# Add Coder SSH keys and set up git signing if running in a Coder workspace
if [[ -n "$CODER_AGENT_URL" ]] && [[ -n "$CODER_AGENT_TOKEN" ]]; then
  echo "⚙️ Adding Coder SSH keys..."

  SSH_KEY=$(
    curl --request GET \
      --url "${CODER_AGENT_URL}api/v2/workspaceagents/me/gitsshkey" \
      --header "Coder-Session-Token: ${CODER_AGENT_TOKEN}" \
      --silent --show-error
  )

  jq --raw-output ".public_key" >"$HOME"/.ssh/id_ed25519_coder.pub <<EOF
$SSH_KEY
EOF

  jq --raw-output ".private_key" >"$HOME"/.ssh/id_ed25519_coder <<EOF
$SSH_KEY
EOF

  chmod -R 644 ~/.ssh/id_ed25519_coder.pub
  chmod -R 600 ~/.ssh/id_ed25519_coder

  echo "⚙️ Coder SSH keys added."

  git config --global user.signingKey "$HOME"/.ssh/id_ed25519_coder.pub
  echo "⚙️ Git signing key set to Coder SSH key."

  # Add the Coder SSH key to the allowed signers file if it doesn't already exist
  if ! grep -q "42286051+lsalazarm99@users.noreply.github.com $(cat "$HOME"/.ssh/id_ed25519_coder.pub)" "$HOME"/.ssh/allowed_signers; then
    echo "42286051+lsalazarm99@users.noreply.github.com $(cat "$HOME"/.ssh/id_ed25519_coder.pub)" >>"$HOME"/.ssh/allowed_signers
    echo "⚙️ Signing key added to ~/.ssh/allowed_signers."
  fi

  unset SSH_KEY
fi

# Make any interactive shell use fish
if ! grep -q "exec fish" "$HOME"/.bashrc; then
  echo -e '\nif [[ $- == *i* ]] && [[ -z "$BASH_EXECUTION" ]] && [[ "$SHELL" != */fish ]]; then\n  export BASH_EXECUTION=1\n  exec fish\nfi' >>"$HOME"/.bashrc
fi

echo "⚙️ Finished setting up your environment!"
