#!/bin/bash

abort() {
  echo "[ABORT]: Killing process started because of terminated signal received"
  echo "[ABORT]: Chaos Revert Started"
  
  if [[ "$MASK" == "enable" ]]; then
    echo "[Chaos]: Unmask the $SERVICE_NAME service"
    systemctl unmask "$SERVICE_NAME" || {
      echo "[ABORT]: Error unable to unmask the service"
      exit 1
    }
  fi

  systemctl start "$SERVICE_NAME" || {
    echo "unable to start the service"
    exit 1
  }
  
  echo "[ABORT]: Chaos Revert Completed"
  exit 1
}

# trap abort signal
trap "abort" SIGINT SIGTERM

# Initialize variables
SERVICE_NAME=""
MASK=""
DURATION=""

# Read the flags
while getopts "s:m:d:" opt; do
  case $opt in
    s) SERVICE_NAME="$OPTARG" ;;
    m) MASK="$OPTARG" ;;
    d) DURATION="$OPTARG" ;;
    *) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
  esac
done

echo "[Info]: Stopping service
