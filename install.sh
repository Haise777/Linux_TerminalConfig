#!/bin/bash
#GitHub: https://github.com/Haise777

# shellcheck disable=SC2059
script_path="$(find ~/ -name "TerminalConfig_Linux")/files"

#Define text color variables to use
rs='\033[0m'
detail='\033[0;36m'
yellow='\033[0;33m'
cyan='\033[0;96m'


# Early function definition
function print_cyan() { printf " \033[0;96m>${rs} $1\n"; }
function print_red() { printf " \033[0;91m>${rs} $1\n"; }

function check_dependency() {
	{ which "$1" &> /dev/null; } || {
		print_red "${yellow}'$1'${rs} not found, is it installed?"
		abort=true
	}
}

function print_nofont_message() {
	print_red "Could not install a nerd font"
	echo "   You may see missing characters being displayed, to fix it, you just need to install a nerd patched font"
	echo "   https://www.nerdfonts.com/font-downloads"
}

function check_font_dependency() {
	{ which "$1" &> /dev/null; } || { 
		print_red "${yellow}'$1'${rs} not found" 
		no_font=true; 
	}
}


# Passed arguments validation
powerline=false

case "$1" in
	"--powerline") powerline=true;;
	"" ) echo > /dev/null;;
	* ) "Invalid script argument"; exit 1;;
esac


# Print script introduction
printf "\n${cyan} Neatly terminal configuration installation script${rs}\n"
printf "        Config and script made by \033[1;36m\033[4;36mHaise777${rs}\n\n"


# Checks for needed dependencies
{ which which &> /dev/null; } || { 
	print_red "${yellow}'which'${rs} not found, it is needed to check for installed dependencies\n"
	exit 1; 
}

abort=false
check_dependency "make"
check_dependency "zsh"
check_dependency "git"
check_dependency "curl"
check_dependency "gcc"
if [ "$abort" == true ]; then
	echo
	print_red "Such dependencies must be resolved\n Exiting...\n"
	exit 1;
fi


# Prompts the user for the prompt choice
if [ "$powerline" == false ]; then
	print_cyan "What prompt should the terminal have?"
	printf " [1] Costumized lean style ${detail}(less misalignment prone)${rs}\n"
	printf " [2] Powerline style ${detail}(more stylish when it works)${rs}\n"
	echo
	while true; do
		read -p "[1/2] > " choice
		case $choice in
			1) should_powerline=false; break;;
			2) should_powerline=true; break;;
			*) echo " Not a valid input!";;
		esac
	done
	echo
fi


# Check if rust's cargo already exists, install it otherwise
{ which cargo &> /dev/null; } || {
	print_cyan "Rust's cargo not found, installing it now..."
	curl https://sh.rustup.rs -sSf | sh -s -- -y
	source "$HOME/.cargo/env"
} || { print_red "Failed to install rust's cargo, exiting..."; exit 1; }


# Install some commands with the cargo package manager
{
	print_cyan "Installing and building better terminal commands with cargo..."
	echo "   This might take a few minutes..."
	print_cyan "Building lsd..."
	cargo install lsd -q
	print_cyan "Building bat..."
	cargo install --locked bat -q
	print_cyan "Building fd-find..."
	cargo install fd-find -q

} || { 
	print_red "Failed to build from cargo"
	printf "   If you are on a ${cyan}Debian based${rs} distro, you could be missing ${cyan}'gcc-multilib'${rs}\n"
	echo "   Exiting..."
	exit 1
}


# Clone plugins from the git
{
	print_cyan "Cloning and installing zsh plugins from git"
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
	git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

} || { print_red "Failed to clone needed repositories from git, exiting..."; exit 1; }


# Move the configuration files to their destination
{
	print_cyan "Moving the config files to their destination"
	\cp -r "$script_path/.zshrc" "$HOME/"
	\cp -r "$script_path/custom/"*.zsh ~/.oh-my-zsh/custom/

	if [ "$should_powerline" == true ] || [ "$powerline" == true ]; then \cp -r "$script_path/.p10k.zsh" "$HOME/"
	else \cp -r "$script_path/.p10k-no-powerline.zsh" "$HOME/.p10k.zsh"; fi

	if [ ! -e ~/.config ]; then
		print_cyan ".config not found in your home directory, creating one"
		mkdir ~/.config
	fi
	\cp -r "$script_path/.config/"* "$HOME/.config/"
	
} || { print_red "Failed to copy essential config files, exiting..."; exit 1; }


#Install needed nerd font for symbols
print_cyan "Downloading and installing symbols font for custom icons"
check_font_dependency "wget"
check_font_dependency "unzip"
if [ "$no_font" == true ]; then
	print_nofont_message
else
	{
		font_path=~/.local/share/fonts/MesloLGS-Nerd
		if [ ! -e ~/.local/share/fonts ]; then
			print_cyan "User's fonts directory not found, creating one..."
			mkdir ~/.local/share/fonts
		fi
		mkdir "$font_path"
		curl -L https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf\
			--output "$font_path"/'MesloLGS NF Regular.ttf'
		curl -L https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf\
			--output "$font_path"/'MesloLGS NF Bold.ttf'
		curl -L https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf\
			--output "$font_path"/'MesloLGS NF Italic.ttf'
		curl -L https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf\
			--output "$font_path"/'MesloLGS NF Bold Italic.ttf'

		fc-cache -rf
		printf " ${cyan}Note:${rs} If you still see missing icons, you may also need to change your terminal to use a nerd font.\n\n"

	} || print_nofont_message
fi


# Prompts the user for changing their default terminal
print_cyan "You will be prompted to enter your password in order to change the default terminal to .zsh"
while true; do {
	chsh -s "$(which zsh)"

} || { print_red "Error, probably invalid password\n   Trying again (^C to cancel)\n"; continue; }
break
done


printf "${cyan} Finished installing your new terminal${rs}\n"
