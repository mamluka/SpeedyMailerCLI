sudo service rsyslog stop
tmux kill-session -t drone
git reset --hard
git pull
cd drones
bundle
bash configure-rsyslog-reader.sh
sudo service rsyslog start
cd ..
tmuxifier s drone