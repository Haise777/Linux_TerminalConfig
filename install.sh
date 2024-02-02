#!/bin/bash
#GitHub: https://github.com/Haise777

# shellcheck disable=SC2059

#Define text color variables to use
rs='\033[0m'
cyan='\033[0;96m'
cyan_arrow=" \033[0;96m>${rs}"
red_arrow=" \033[0;91m>${rs}"

printf "\n${cyan} Neatly terminal configuration installation script${rs}\n"
printf "          Config and script made by \033[1;36m\033[4;36mHaise777${rs}\n\n"

SCRIPT_PATH="$(find ~/ -name "custom-terminal")/files"

# Checks for needed dependencies
ABORT=false
{ which which 2> /dev/null; } || { printf "${red_arrow} 'which' not found, it is needed to check for installed dependencies\n"; exit 1; }
{ which make 2> /dev/null; } || { printf "${red_arrow} 'make' not found, is it installed?\n"; ABORT=true; }
{ which zsh 2> /dev/null; } || { printf "${red_arrow} 'zsh' not found, is it installed?\n"; ABORT=true; }
{ which git 2> /dev/null; } || { printf "${red_arrow} 'git' not found, is it installed?\n"; ABORT=true; }
if [ "$ABORT" == true ]; then
	printf "${red_arrow} Such dependencies must be resolved\nExiting...\n"
	exit 1;
fi

# Prompts the user for the prompt choice
printf "${cyan_arrow} What prompt should the terminal have?\n"
echo " [1] Costumized lean style (less misalignment prone)"
echo " [2] Powerline style (more stylish)"
while true; do
	read choice
	case $choice in
		1) SHOULD_POWERLINE=false; break;;
		2) SHOULD_POWERLINE=true; break;;
		*) echo " Not a valid input!";;
	esac
done

# Check if rust's cargo already exists, install it otherwise
{ which cargo 2> /dev/null; } || {
	printf "${cyan_arrow} Rust's cargo not found, installing it now...\n"
	curl https://sh.rustup.rs -sSf | sh -s -- -y
	source "$HOME/.cargo/env"
} || { printf "${red_arrow} Failed to install rust's cargo, exiting...\n"; exit 1; }

# Install some commands with the cargo package manager
{
	printf "${cyan_arrow} Installing and building better basic terminal commands with cargo...\n"
	cargo install lsd
	cargo install --locked bat
	cargo install fd-find
} || { printf "${red_arrow} Failed to build from cargo, exiting...\n"; exit 1; }

# Clone plugins from the git
{
	printf "${cyan_arrow} Cloning and installing zsh plugins from git\n"
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
	git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

} || { printf "${red_arrow} Failed to clone needed repositories from git, exiting...\n"; exit 1; }

# Move the configuration files to their destination
{
	printf "${cyan_arrow} Moving the config files to their destination\n"
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
	
} || { printf "${red_arrow} Failed to copy essential config files, exiting...\n"; exit 1; }

# Prompts the user for changing their default terminal
echo
printf "${cyan_arrow} You will be prompted to enter your password in order to change the default terminal to .zsh\n"
while true; do
{
	chsh -s "$(which zsh)"
} || { printf "${red_arrow} Error, probably invalid password\n^C to cancel\n\n"; continue; }
break
done

printf "${cyan} Finished installing terminal${rs}\n"
