#!/bin/bash

SCRIPT_PATH="$(find ~/ -name "custom-terminal")/files"

# Checks for needed dependencies
ABORT=false
{ which which 2> /dev/null; } || { echo "'which' not found, is it installed?"; ABORT=true; }
{ which make 2> /dev/null; } || { echo "'make' not found, is it installed?"; ABORT=true; }
{ which zsh 2> /dev/null; } || { echo "'zsh' not found, is it installed?"; ABORT=true; }
{ which git 2> /dev/null; } || { echo "'git' not found, is it installed?"; ABORT=true; }
if [ "$ABORT" == true ]; then
	printf "Such dependencies must be resolved\nExiting...\n"
	exit 1;
fi

# Prompts the user for the prompt choice
printf "What prompt should the terminal have?"
echo "[1] Costumized lean style (less misalignment prone)"
echo "[2] Powerline style (more stylish)"
while true; do
	read choice
	case $choice in
		1) SHOULD_POWERLINE=false; break;;
		2) SHOULD_POWERLINE=true; break;;
		*) echo "Not a valid input!";;
	esac
done

# Check if rust's cargo already exists, install it otherwise
{ which cargo 2> /dev/null; } || {
	curl https://sh.rustup.rs -sSf | sh -s -- -y
	source "$HOME/.cargo/env"
}

# Install some commands with the cargo package manager
{
	cargo install lsd
	cargo install --locked bat
	cargo install fd-find
} || { printf "Failed to build from cargo, exiting..."; exit 1; }

# Clone plugins from the git
{
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
	git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
} || { printf "Failed to clone needed repositories from git, exiting..."; exit 1; }

# Move the configuration files to their destination
{
	\cp -r "$SCRIPT_PATH/.zshrc" "$HOME/"
	\cp -r "$SCRIPT_PATH/custom/"*.zsh ~/.oh-my-zsh/custom/

	if [ "$SHOULD_POWERLINE" == true ]; then 
		\cp -r "$SCRIPT_PATH/.p10k.zsh" "$HOME/"
	else 
		\cp -r "$SCRIPT_PATH/.p10k-no-powerline.zsh" "$HOME/.p10k.zsh"; 
	fi

	if [ ! -e ~/.config ]; then
		echo ".config not found in your home directory, creating one"
		mkdir ~/.config
	fi
	\cp -r "$SCRIPT_PATH/.config/"* "$HOME/.config/"
} || { printf "Failed to copy essential config files, exiting..."; exit 1; }

# Prompts the user for changing their default terminal
echo
echo "you will be prompted to enter your password in order to change the default terminal to .zsh"
while true; do
{
	chsh -s "$(which zsh)"
} || { printf "Error, probably invalid password\n^C to cancel\n\n"; continue; }
break
done

echo "Finished installing terminal"
