#/usr/bin/env bash
echo "#!/usr/bin/env fish" > install-fisher.fish.tmp
chmod 751 install-fisher.fish.tmp
curl -sL https://git.io/fisher >> install-fisher.fish.tmp

mv -f install-fisher.fish.tmp install-fisher.fish

