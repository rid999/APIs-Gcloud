#!/bin/bash

# Function to create a new service account
create_service_account() {
    echo -e "${LIME_GREEN}Please enter a custom name for the new project:${RESET}"
    read -r NEW_PROJECT_NAME
    echo -e "${LIME_GREEN}Creating new project with name: $NEW_PROJECT_NAME...${RESET}"
    
    # Create the new project and capture the generated project ID
    NEW_PROJECT_ID=$(gcloud projects create "$NEW_PROJECT_NAME" --format="value(projectId)")
    
    echo -e "${LIME_GREEN}New project created with ID: $NEW_PROJECT_ID${RESET}"
    
    # Create the service account
    echo -e "${LIME_GREEN}Creating service account...${RESET}"
    gcloud iam service-accounts create "${NEW_PROJECT_NAME}-sa" --display-name "${NEW_PROJECT_NAME} Service Account" --project "$NEW_PROJECT_ID"
    
    # Enable necessary APIs (example)
    gcloud services enable people.googleapis.com --project "$NEW_PROJECT_ID"
    gcloud services enable gmail.googleapis.com --project "$NEW_PROJECT_ID"
    gcloud services enable calendar.googleapis.com --project "$NEW_PROJECT_ID"
    
    echo -e "${LIME_GREEN}Service account created successfully!${RESET}"
}

# Main script logic
echo -e "${LIME_GREEN}Welcome to the Google Cloud Service Account Creator!${RESET}"
echo -e "${LIME_GREEN}Do you want to (1) use an existing project or (2) create a new project?${RESET}"
read -r CHOICE

if [[ "$CHOICE" == "1" ]]; then
    # Logic for using an existing project
    echo -e "${LIME_GREEN}Listing available projects...${RESET}"
    gcloud projects list
    echo -e "${LIME_GREEN}Please enter the project ID of the existing project:${RESET}"
    read -r PROJECT_ID
    # Continue with service account creation for the existing project
    create_service_account
elif [[ "$CHOICE" == "2" ]]; then
    create_service_account
else
    echo -e "${RED}Invalid choice. Please run the script again.${RESET}"
fi
