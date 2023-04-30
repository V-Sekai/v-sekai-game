# README

Tested on msys2 Windows 11, Popos and Mac.

## Readme for fire

```
scoop install msys2
msys2
pacman -S git python3 ssh-pageant
# copy
# eval $(/usr/bin/ssh-pageant -r -a "/tmp/.ssh-pageant-$USERNAME")
# export PATH=/mingw64/bin/:$PATH
# To the end of ~/.bashrc
git config --global user.name "K. S. Ernest (iFire) Lee"
git config --global user.email "ernest.lee@chibifire.com"
mkdir -p ~/.ssh
ssh-keyscan github.com >> ~/.ssh/known_hosts
git clone https://github.com/ingydotnet/git-subrepo ~/git-subrepo
echo 'source ~/git-subrepo/.rc' >> ~/.bashrc
```