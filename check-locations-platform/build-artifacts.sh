#!/bin/bash
# This script automates the build process for all artifacts in the project.
# It creates a clean 'artifacts' directory to store the final zip archives.

# Exit immediately if a command exits with a non-zero status for reliability.
set -e

# --- Configuration (zsh/bash compatible) ---
# Two separate arrays for source directories and artifact names.
# Make sure the order of items in both arrays matches!
SRC_DIRS=(
  "db_migrator"
  "check-workflow/proactive_monitoring_handlers/01-get-locations"
  "check-workflow/proactive_monitoring_handlers/02-check-location"
  "check-workflow/shared_handlers/send-notification"
  "check-workflow/proactive_monitoring_handlers/00-trigger-handler"
  "check-workflow/on_demand_check_handlers/01-check-location-against-events"
  "check-service"
)
ZIP_FILES=(
  "db_migrator.zip"
  "GetLocationsHandler.zip"
  "CheckLocationHandler.zip"
  "SendNotificationHandler.zip"
  "NotifyTriggerHandler.zip"
  "OnDemandCheckHandler.zip"
  "check_service.zip"
)

# Name of the artifacts directory
ARTIFACTS_DIR="artifacts"

# --- Script Logic ---
echo "Starting artifact build process..."

# Get the absolute path to the script's directory
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
ARTIFACTS_PATH="$SCRIPT_DIR/$ARTIFACTS_DIR"

# Clean and create the artifacts directory
echo "Preparing artifacts directory: $ARTIFACTS_PATH"
rm -rf "$ARTIFACTS_PATH"
mkdir -p "$ARTIFACTS_PATH"

# Loop through all defined artifacts by their indices
for i in "${!SRC_DIRS[@]}"; do
  SRC_DIR="${SRC_DIRS[$i]}"
  ZIP_FILE="${ZIP_FILES[$i]}"
  echo "--------------------------------------------------"
  echo "Processing artifact: $SRC_DIR"

  # Change into the source code directory
  cd "$SCRIPT_DIR/$SRC_DIR"

  # Check if package.json exists and if dependencies should be installed.
  # For check-service, installation is not needed as Docker will handle it.
  if [ -f "package.json" ] && [ "$SRC_DIR" != "check-service" ]; then
    echo "Found package.json, installing production dependencies for Lambda..."
    # Use 'npm ci' for fast and clean installation in CI/CD environments
    npm ci --only=production
  else
    echo "No package.json found or this is check-service, skipping dependency installation."
  fi

  # Archive the directory contents into the artifacts folder
  echo "Zipping source code into $ZIP_FILE..."
  # -r for recursive, -q for quiet mode
  # For Lambdas, exclude aws-sdk as it's already in their environment
  zip -r -q "$ARTIFACTS_PATH/$ZIP_FILE" . -x "*.git*" "node_modules/aws-sdk/*"
  
  echo "Successfully built $ZIP_FILE"

  # Return to the original directory
  cd "$SCRIPT_DIR"
done

echo "--------------------------------------------------"
echo "✅ All artifacts built successfully in '$ARTIFACTS_DIR' directory." 