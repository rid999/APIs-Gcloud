#!/bin/bash

# List available Google Cloud projects
echo "Fetching list of available projects..."
PROJECTS=$(gcloud projects list --format="value(projectId)")

# Check if any projects are available
if [ -z "$PROJECTS" ]; then
  echo "No projects found. Please make sure you have access to at least one Google Cloud project."
  exit 1
fi

# Display projects and prompt user to select one
echo "Available projects:"
select PROJECT_ID in $PROJECTS; do
  if [ -n "$PROJECT_ID" ]; then
    echo "You selected project: $PROJECT_ID"
    break
  else
    echo "Invalid selection. Please select a valid project ID."
  fi
done

# Set the project as the active project
gcloud config set project $PROJECT_ID

# List of APIs to enable
APIS=(
  "admin.googleapis.com"
  "drive.googleapis.com"
  "gmail.googleapis.com"
  "calendar-json.googleapis.com"
  "people.googleapis.com"
  "tasks.googleapis.com"
  "forms.googleapis.com"
  "groupsmigration.googleapis.com"
  "vault.googleapis.com"
  "storage.googleapis.com"
)

# Total number of APIs
TOTAL_APIS=${#APIS[@]}

# Counter for progress
COUNT=0

# Enable each API
for API in "${APIS[@]}"; do
  COUNT=$((COUNT + 1))
  echo -n "Enabling $API [${COUNT}/${TOTAL_APIS}]..."
  if gcloud services enable $API; then
    echo -e "\e[32m Done\e[0m"  # Green color for success
  else
    echo -e "\e[31m Failed\e[0m"  # Red color for failure
  fi
done

# Final status
if [ $COUNT -eq $TOTAL_APIS ]; then
  echo -e "\e[32mAll specified APIs have been successfully enabled for project $PROJECT_ID: ${COUNT}/${TOTAL_APIS}.\e[0m"
else
  echo "Some APIs may not have been enabled successfully."
fi
