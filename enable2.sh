#!/bin/bash

# Custom color codes
LIME_GREEN='\e[38;2;84;255;130m'
RESET='\e[0m'

# List available Google Cloud projects
echo -e "${LIME_GREEN}Fetching list of available projects...${RESET}"
PROJECTS=$(gcloud projects list --format="value(projectId)")

# Check if any projects are available
if [ -z "$PROJECTS" ]; then
  echo -e "${LIME_GREEN}No projects found. Please make sure you have access to at least one Google Cloud project.${RESET}"
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

# Set the project as the active project
gcloud config set project $PROJECT_ID

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

# Create P12 Key
echo -e "${LIME_GREEN}Creating P12 key for the service account...${RESET}"
gcloud iam service-accounts keys create "${SERVICE_ACCOUNT_NAME}.p12" \
    --iam-account="${SERVICE_ACCOUNT_EMAIL}" \
    --key-file-type="p12"

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
  echo -n -e "Enabling $API [${COUNT}/${TOTAL_APIS}]..."
  if gcloud services enable $API; then
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
echo -e "=-=-=-=-=-=-=- Service Account email -=-=-=-=-=-=-=-"
echo -e "${LIME_GREEN}${SERVICE_ACCOUNT_EMAIL}${RESET}"
echo -e "=-=-=-=-=-=-=- Service Account Unique ID -=-=-=-=-=-=-=-"
echo -e "${LIME_GREEN}${SERVICE_ACCOUNT_ID}${RESET}"
