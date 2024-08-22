#!/bin/bash

# Custom color codes
LIME_GREEN='\e[38;2;84;255;130m'
RESET='\e[0m'

# Prompt user to choose between using the current project or creating a new one
echo -e "${LIME_GREEN}Do you want to use the current project or create a new one?${RESET}"
echo -e "1. Use current project"
echo -e "2. Create new project"
read -r CHOICE

if [[ "$CHOICE" == "1" ]]; then
  # List available Google Cloud projects
  echo -e "${LIME_GREEN}Fetching list of available projects...${RESET}"
  PROJECTS=$(gcloud projects list --format="value(projectId)")

  # Check if any projects are available
  if [ -z "$PROJECTS" ]; then
    echo -e "${LIME_GREEN}No projects found. Exiting script.${RESET}"
    exit 1
  fi

  # Display projects and prompt user to select one
  echo -e "${LIME_GREEN}Select your Project:${RESET}"
  select PROJECT_ID in $PROJECTS; do
    if [ -n "$PROJECT_ID" ]; then
      echo -e "${LIME_GREEN}You selected project: $PROJECT_ID${RESET}"
      break
    else
      echo -e "${LIME_GREEN}Invalid selection. Please select a valid project ID.${RESET}"
    fi
  done

elif [[ "$CHOICE" == "2" ]]; then
  # Create a new project
  echo -e "${LIME_GREEN}Please enter the new project ID:${RESET}"
  read -r NEW_PROJECT_ID
  echo -e "${LIME_GREEN}Creating new project: $NEW_PROJECT_ID...${RESET}"
  gcloud projects create "$NEW_PROJECT_ID"
  PROJECT_ID="$NEW_PROJECT_ID"
else
  echo -e "${LIME_GREEN}Invalid choice. Exiting script.${RESET}"
  exit 1
fi

# Set the project as the active project
gcloud config set project "$PROJECT_ID"

# Generate a random name for the service account
SERVICE_ACCOUNT_NAME="service-account-$(date +%s)"  # Unique name using timestamp
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Create Service Account
echo -e "${LIME_GREEN}Creating service account: ${SERVICE_ACCOUNT_NAME}...${RESET}"
gcloud iam service-accounts create "${SERVICE_ACCOUNT_NAME}" \
    --description="Service Account with Owner role" \
    --display-name="${SERVICE_ACCOUNT_NAME}"

# Grant Owner role to the Service Account
echo -e "${LIME_GREEN}Granting Owner role to the service account...${RESET}"
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
    --role="roles/owner"

# List of APIs to enable
APIS=(
  "admin.googleapis.com"  # Admin SDK API
  "drive.googleapis.com"  # Google Drive API
  "gmail.googleapis.com"  # Gmail API
  "calendar-json.googleapis.com"  # Google Calendar API
  "people.googleapis.com"  # People API
  "tasks.googleapis.com"  # Tasks API
  "forms.googleapis.com"  # Google Forms API
  "groupsmigration.googleapis.com"  # Groups Migration API
  "vault.googleapis.com"  # Google Vault API
  "storage.googleapis.com"  # Cloud Storage API
  "sheets.googleapis.com"  # Google Sheets API
  "docs.googleapis.com"  # Google Docs API
  "groupssettings.googleapis.com"  # Groups Settings API
  "workspace.googleapis.com"  # Google Workspace Migrate API
)

# Total number of APIs
TOTAL_APIS=${#APIS[@]}

# Counter for progress
COUNT=0

# Enable each API
for API in "${APIS[@]}"; do
  COUNT=$((COUNT + 1))
  echo -n -e "Enabling $API [${COUNT}/${TOTAL_APIS}]..."
  if gcloud services enable "$API"; then
    echo -e "${LIME_GREEN} Done${RESET}"  # Lime green color for success
  else
    echo -e "\e[31m Failed${RESET}"  # Red color for failure
  fi
done

# Final status
if [ $COUNT -eq $TOTAL_APIS ]; then
  echo -e "${LIME_GREEN}All specified APIs have been successfully enabled for project $PROJECT_ID: ${COUNT}/${TOTAL_APIS}.${RESET}"
else
  echo -e "\e[31mSome APIs may not have been enabled successfully.${RESET}"
fi

# Print Service Account details
SERVICE_ACCOUNT_ID=$(gcloud iam service-accounts describe "${SERVICE_ACCOUNT_EMAIL}" --format='get(uniqueId)')
echo -e "====================================================="
echo -e ">>  Copy Detail below on your private note"
echo -e ">>  Service Account email "
echo -e "${LIME_GREEN}${SERVICE_ACCOUNT_EMAIL}${RESET}"
echo -e ">>  Service Account Unique ID "
echo -e "${LIME_GREEN}${SERVICE_ACCOUNT_ID}${RESET}"
echo -e "====================================================="

# Construct URL for manual key creation
KEY_CREATION_URL="https://console.cloud.google.com/iam-admin/serviceaccounts/details/${SERVICE_ACCOUNT_ID}/keys?project=${PROJECT_ID}"
echo -e "${LIME_GREEN}Please manually create and download the P12 key from the following URL:${RESET}"
echo -e "${KEY_CREATION_URL}"
