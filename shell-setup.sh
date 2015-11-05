# switch to zsh instead of bash
sudo dscl . change /users/$USER UserShell /bin/bash $(which zsh)

#download my shell
git clone git://github.com/andsens/homeshick.git $HOME/.homesick/repos/homeshick
git clone https://github.com/PhantomPayne/dotfiles-core.git $HOME/.homesick/repos/dotfiles-core

#link my shell
$HOME/.homesick/repos/homeshick/bin/homeshick link

#dev tools
#pip install vex, virtualenv, fabric, ipython

#gem install foreman
#npm install -g gulp
