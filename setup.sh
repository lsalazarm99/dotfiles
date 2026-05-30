#!/usr/bin/env bash

echo "⚙️ Setting up your environment..."

# Copy configuration files
if [ ! -d "$HOME"/.config ]; then mkdir "$HOME"/.config; fi
if [ ! -d "$HOME"/.ssh ]; then mkdir "$HOME"/.ssh; fi

cp -rf "$(dirname "$0")"/src/.config/* "$HOME"/.config
cp -rf "$(dirname "$0")"/src/.local/.bin/* "$HOME"/.local/.bin
cp -rf "$(dirname "$0")"/src/.ssh/* "$HOME"/.ssh
cp -f "$(dirname "$0")"/src/{.bash_aliases,.gitconfig,.gitignore,.npmrc} "$HOME"

echo "⚙️ Configuration files copied."

echo "⚙️ Setting up package repositories..."

# Create the keyrings directory if it doesn't exist
sudo install -dm 755 /etc/apt/keyrings

# Add the mise PPA if it's not already been added
if ! grep -q "mise.jdx.dev" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
  echo "⚙️ Adding mise PPA..."
  curl -fsSL https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | sudo tee /etc/apt/keyrings/mise-archive-keyring.gpg 1>/dev/null
  echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list
  echo "⚙️ mise PPA added."
fi

echo "⚙️ Package repositories setup completed."

# Update the packages list
echo "⚙️ Updating package list..."
sudo apt-get -qq update
echo "⚙️ Package list updated."

# Install packages
echo "⚙️ Installing packages..."
sudo apt-get -qq install -y bat btop eza mise micro
echo "⚙️ Packages installed."

# Add mise activation to interactive Bash shells
if ! grep -q "mise activate bash" "$HOME"/.bashrc; then
  # shellcheck disable=SC2016
  echo -e '\neval "$(mise activate bash)"' >>"$HOME"/.bashrc
fi

# Add mise activation to non-interactive Bash shells
if ! grep -q "mise activate bash" "$HOME"/.bash_profile; then
  # shellcheck disable=SC2016
  echo -e '\neval "$(mise activate bash --shims)"' >>"$HOME"/.bash_profile
fi

# Install starship if it doesn't exist
if [[ ! -f /usr/local/bin/starship ]]; then
  echo "⚙️ Installing starship..."
  curl -fsS https://starship.rs/install.sh | sh -s -- -y

  if ! grep -q "starship init bash" "$HOME"/.bashrc; then
    # shellcheck disable=SC2016
    echo -e '\neval "$(starship init bash)"' >>"$HOME"/.bashrc
  fi

  echo "⚙️ starship installation completed."
fi

# Install AWS CLI if it doesn't exist
if [[ ! -f /usr/local/bin/aws ]]; then
  echo "⚙️ Installing AWS CLI and plugins..."

  ARCH=$(uname -m)

  if [[ "$ARCH" == "x86_64" || "$ARCH" == "aarch64" ]]; then
    if [[ "$ARCH" == "x86_64" ]]; then
      curl -fsS "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
      curl -fsS "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "/tmp/session-manager-plugin.deb"
    else
      curl -fsS "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "/tmp/awscliv2.zip"
      curl -fsS "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_arm64/session-manager-plugin.deb" -o "/tmp/session-manager-plugin.deb"
    fi

    unzip -qq -o /tmp/awscliv2.zip -d /tmp
    sudo /tmp/aws/install
    rm -rf /tmp/aws /tmp/awscliv2.zip
    echo "⚙️ AWS CLI installation completed."

    sudo dpkg -i /tmp/session-manager-plugin.deb
    rm -f /tmp/session-manager-plugin.deb
    echo "⚙️ AWS Session Manager plugin installation completed."
  else
    echo "⚠️ Unsupported architecture: $ARCH. Skipping AWS CLI installation."
  fi
fi

echo "⚙️ Finished setting up your environment!"
