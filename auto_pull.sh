#!/bin/bash
while true; do
    cd ~/Tapr/tapr-trackpad/Tapr-Trackpad && git pull origin Adding_double-tap  --quiet
    cd ~/Tapr/Tapr-Backend-Controller && git pull origin Debugging --quiet
    sleep 30
done
