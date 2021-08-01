sudo sh -c 'echo /usr/local/bin/fish >> /etc/shells'
chsh -s /usr/local/bin/fish

$($0/../install-fisher.sh)

fisher install ilancosman/tide
fisher install jorgebucaran/nvm.fish
