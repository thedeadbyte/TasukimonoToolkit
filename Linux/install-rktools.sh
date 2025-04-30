#1/bin/bash
sudo apt update
sudo apt install chkrootkit rkhunter
sudo chkrootkit
sudo rkhunter --check
