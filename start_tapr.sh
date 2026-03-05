#!/bin/bash

cleanup() {
    echo ""
    echo "Shutting down Tapr..."
    kill $PYTHON_PID 2>/dev/null
    kill $JAVA_PID 2>/dev/null
    # Kill anything still holding port 8080
    kill $(lsof -t -i:8080) 2>/dev/null
    wait $PYTHON_PID 2>/dev/null
    wait $JAVA_PID 2>/dev/null
    echo "Tapr stopped."
    exit 0
}

trap cleanup SIGINT SIGTERM

echo "Tapr Watcher started. Waiting for trackpad..."

while true; do
    while ! grep -q "SINO WEALTH USB TOUCHPAD" /proc/bus/input/devices; do
        sleep 2
    done

    echo "Trackpad detected."
    read -p "Start Tapr? (y/n): " choice

    if [[ "$choice" != "y" ]]; then
        echo "Skipping. Will check again when trackpad is reconnected."
        while grep -q "SINO WEALTH USB TOUCHPAD" /proc/bus/input/devices; do
            sleep 2
        done
        continue
    fi

    echo "Starting Tapr..."

    cd ~/Tapr/Tapr-Backend-Controller
    java -jar target/Trackpad-Controller-0.0.1-SNAPSHOT.jar &
    JAVA_PID=$!

    echo "Waiting for Spring Boot..."
    until curl -s http://localhost:8080 > /dev/null 2>&1; do
        sleep 1
    done
    echo "Spring Boot is up."

    cd ~/Tapr/tapr-trackpad/Tapr-Trackpad
    sudo ~/Tapr/tapr-trackpad/venv/bin/python3 -m gesture_detector.main &
    PYTHON_PID=$!

    echo "Tapr is running. Press Ctrl+C to stop."

    while grep -q "SINO WEALTH USB TOUCHPAD" /proc/bus/input/devices; do
        sleep 2
    done

    echo "Trackpad disconnected. Shutting down..."
    kill $PYTHON_PID 2>/dev/null
    kill $JAVA_PID 2>/dev/null
    kill $(lsof -t -i:8080) 2>/dev/null
    wait $PYTHON_PID 2>/dev/null
    wait $JAVA_PID 2>/dev/null

    echo "Waiting for trackpad again..."
done
