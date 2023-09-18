#!/bin/bash

abort() {
  echo "[ABORT]: Killing process started because of terminated signal received"
  echo "[ABORT]: Chaos Revert Started"
  
  cmd="systemctl"
  [[ "$ENABLE_SUDO" == "true" ]] && cmd="sudo $cmd"

  if [[ "$MASK" == "enable" ]]; then
    echo "[Chaos]: Unmask the $SERVICE_NAME service"
    $cmd unmask "$SERVICE_NAME" || {
      echo "[ABORT]: Error unable to unmask the service"
      exit 1
    }
  fi

  $cmd start "$SERVICE_NAME" || {
    echo "unable to start the service"
    exit 1
  }
  
  echo "[ABORT]: Chaos Revert Completed"
  exit 1
}

# trap abort signal
trap "abort" SIGINT SIGTERM

cmd="systemctl"
[[ "$ENABLE_SUDO" == "true" ]] && cmd="sudo $cmd"

echo "[Info]: Stopping service '$SERVICE_NAME' with mask '$MASK' and duration '$DURATION'"

if [[ "$MASK" == "enable" ]]; then
  echo "[Chaos]: Mask the $SERVICE_NAME service"
  $cmd mask "$SERVICE_NAME" || {
    echo "Error: Unable to mask the service"
    exit 1
  }
fi

echo "[Chaos]: Stopping the $SERVICE_NAME service"
$cmd stop "$SERVICE_NAME" || {
  echo "Error: Unable to stop the service"
  exit 1
}

echo "[Wait]: Wait for Chaos duration for $DURATION seconds"
sleep "$DURATION"

if [[ "$MASK" == "enable" ]]; then
  echo "[Chaos]: Unmask the $SERVICE_NAME service"
  $cmd unmask "$SERVICE_NAME" || {
    echo "Error: Unable to unmask the service"
    exit 1
  }
fi

echo "[Chaos]: Starting the $SERVICE_NAME service"
$cmd start "$SERVICE_NAME" || {
  echo "Error: Unable to start the service"
  exit 1
}

echo "[Info]: The service started successfully"
