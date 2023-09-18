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

echo "[Info]: Stopping service '$SERVICE_NAME' with mask '$MASK' and duration '$DURATION'"

if [[ "$MASK" == "enable" ]]; then
  echo "[Chaos]: Mask the $SERVICE_NAME service"
  systemctl mask "$SERVICE_NAME" || {
    echo "Error: Unable to mask the service"
    exit 1
  }
fi

echo "[Chaos]: Stopping the $SERVICE_NAME service"
systemctl stop "$SERVICE_NAME" || {
  echo "Error: Unable to stop the service"
  exit 1
}

echo "[Wait]: Wait for Chaos duration for $DURATION seconds"
sleep "$DURATION"

if [[ "$MASK" == "enable" ]]; then
  echo "[Chaos]: Unmask the $SERVICE_NAME service"
  systemctl unmask "$SERVICE_NAME" || {
    echo "Error: Unable to unmask the service"
    exit 1
  }
fi

echo "[Chaos]: Starting the $SERVICE_NAME service"
systemctl start "$SERVICE_NAME" || {
  echo "Error: Unable to start the service"
  exit 1
}

echo "[Info]: The service started successfully"

