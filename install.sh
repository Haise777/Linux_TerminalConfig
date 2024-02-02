#!/bin/bash
#GitHub: https://github.com/Haise777

# shellcheck disable=SC2059

#Define text color variables to use
rs='\033[0m'
detail='\033[0;36m'
yellow='\033[0;33m'
cyan='\033[0;96m'
cyan_arrow=" \033[0;96m>${rs}"
red_arrow=" \033[0;91m>${rs}"

printf "\n${cyan} Neatly terminal configuration installation script${rs}\n"
printf "        Config and script made by \033[1;36m\033[4;36mHaise777${rs}\n\n"

SCRIPT_PATH="$(find ~/ -name "TerminalConfig_Linux")/files"

# Checks for needed dependencies
ABORT=false
{ which which &> /dev/null; } || { printf "${red_arrow} ${yellow}'which'${rs} not found, it is needed to check for installed dependencies\n\n"; exit 1; }
{ which make &> /dev/null; } || { printf "${red_arrow} ${yellow}'make'${rs} not found, is it installed?\n"; ABORT=true; }
{ which zsh &> /dev/null; } || { printf "${red_arrow} ${yellow}'zsh'${rs} not found, is it installed?\n"; ABORT=true; }
{ which git &> /dev/null; } || { printf "${red_arrow} ${yellow}'git'${rs} not found, is it installed?\n"; ABORT=true; }
{ which curl &> /dev/null; } || { printf "${red_arrow} ${yellow}'curl'${rs} not found, is it installed?\n"; ABORT=true; }
{ which gcc &> /dev/null; } || { printf "${red_arrow} ${yellow}'gcc'${rs} not found, is it installed?\n"; ABORT=true; }
if [ "$ABORT" == true ]; then
	printf "\n${red_arrow} Such dependencies must be resolved\nExiting...\n\n"
	exit 1;
fi

# Prompts the user for the prompt choice
printf "${cyan_arrow} What prompt should the terminal have?\n"
printf " [1] Costumized lean style ${detail}(less misalignment prone)${rs}\n"
printf " [2] Powerline style ${detail}(more stylish when it works)${rs}\n"
echo
while true; do
	read -p "[1/2] > " choice
	case $choice in
		1) SHOULD_POWERLINE=false; break;;
		2) SHOULD_POWERLINE=true; break;;
		*) echo " Not a valid input!";;
	esac
done
echo

# Check if rust's cargo already exists, install it otherwise
{ which cargo &> /dev/null; } || {
	printf "${cyan_arrow} Rust's cargo not found, installing it now...\n"
	curl https://sh.rustup.rs -sSf | sh -s -- -y
	source "$HOME/.cargo/env"
} || { printf "${red_arrow} Failed to install rust's cargo, exiting...\n"; exit 1; }

# Install some commands with the cargo package manager
{
	printf "${cyan_arrow} Installing and building better basic terminal commands with cargo...\n"
	echo "   This might take a few minutes..."
	printf "${cyan_arrow} Building lsd...\n"
	cargo install lsd -q
	printf "${cyan_arrow} Building bat...\n"
	cargo install --locked bat -q
	printf "${cyan_arrow} Building fd-find...\n"
	cargo install fd-find -q
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
printf "${cyan_arrow} You will be prompted to enter your password in order to change the default terminal to .zsh\n"
while true; do
{
	chsh -s "$(which zsh)"
} || { printf "${red_arrow} Error, probably invalid password\n   Trying again (^C to cancel)\n\n"; continue; }
break
done

#Install needed nerd font for symbols
printf "${cyan_arrow} Downloading and installing symbols font for custom icons"
function print_nofont_message() {
	printf "${red_arrow} Could not install nerd font symbols\n"
	echo "   You may see missing characters being displayed, to fix it, you need to install a nerd patched font"
	echo "   https://www.nerdfonts.com/font-downloads"
}
{ which wget &> /dev/null; } || { printf "${red_arrow} ${yellow}'wget'${rs} not found\n"; NO_FONT=true; }
{ which unzip &> /dev/null; } || { printf "${red_arrow} ${yellow}'unzip'${rs} not found\n"; NO_FONT=true; }
if [ "$NO_FONT" == true ]; then
	print_nofont_message
else
	{
		wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/NerdFontsSymbolsOnly.zip
		if [ ! -e ~/.local/share/fonts ]; then
			printf "${cyan_arrow} User's fonts directory not found, creating one..."
			mkdir ~/.local/share/fonts
		fi
		unzip NerdFontsSymbolsOnly.zip -d ~/.local/share/fonts/nerdsymbols

	} || print_nofont_message
fi

printf "${cyan} Finished installing terminal${rs}\n\n"
