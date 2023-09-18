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
  }

  systemctl start "$SERVICE_NAME" || {
    echo "Unable to start the service"
    exit 1
  }

  echo "[ABORT]: Chaos Revert Completed"
  exit 1
}

# Trap abort signal
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

# Check if SERVICE_NAME, MASK, and DURATION are provided
if [[ -z "$SERVICE_NAME" || -z "$MASK" || -z "$DURATION" ]]; then
  echo "All of -s [SERVICE_NAME], -m [MASK], and -d [DURATION] must be provided"
  exit 1
fi

# Stop the service
echo "[Info]: Stopping service $SERVICE_NAME"
systemctl stop "$SERVICE_NAME" || {
  echo "Unable to stop the service"
  exit 1
}

# Mask the service if needed
if [[ "$MASK" == "enable" ]]; then
  echo "[Chaos]: Masking the $SERVICE_NAME service"
  systemctl mask "$SERVICE_NAME" || {
    echo "Error unable to mask the service"
    exit 1
  }
fi

# Wait for the given duration
echo "[Info]: Waiting for $DURATION seconds"
sleep "$DURATION"

# Unmask the service if needed
if [[ "$MASK" == "enable" ]]; then
  echo "[Chaos]: Unmasking the $SERVICE_NAME service"
  systemctl unmask "$SERVICE_NAME" || {
    echo "Error unable to unmask the service"
    exit 1
  }
fi

# Start the service back up
echo "[Info]: Starting service $SERVICE_NAME"
systemctl start "$SERVICE_NAME" || {
  echo "Unable to start the service"
  exit 1
}

echo "[Info]: Completed"
