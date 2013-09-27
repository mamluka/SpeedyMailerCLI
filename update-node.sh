source ~/.bash_profile

cd ~/SpeedyMailerCLI-Cookbooks
git pull
cd ~
tmux kill-session -t drone
rvmsudo chef-solo -j node.json -c solo.rb
tmuxifier s drone
