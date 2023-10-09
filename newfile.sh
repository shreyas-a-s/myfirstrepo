#!/bin/bash

# Function to prompt for user input with validation
function prompt_with_validation() {
  local prompt_text="$1"
  local validation_pattern="$2"
  local input

  while true; do
    read -p "$prompt_text: " input
    if [[ $input =~ $validation_pattern ]]; then
      echo "$input"
      break
    else
      echo "Invalid input. Please try again."
    fi
  done
}

# Function to download and install Drupal
function install_drupal() {
  # Download Drupal core
  wget https://www.drupal.org/files/projects/drupal-7.78.tar.gz
  tar -zxvf drupal-7.78.tar.gz
  mv drupal-7.78/* ./
  mv drupal-7.78/.htaccess ./
  
  # Drupal site-install command arguments and options
  args=("standard" "install_configure_form.update_status_module='array(FALSE,FALSE)'")
  db_url="$driver://$postgres_username:$postgres_password@$host:$port/$database"
  options=("--db-url=$db_url" "--account-name=$username" "--account-pass=$user_password" "--site-mail=$site_email" "--site-name=$site_name")
  
  # Install Drupal
  drush si "${args[@]}" "${options[@]}"
  
  # Check for installation errors
  if [ $? -ne 0 ]; then
    echo "An error occurred when attempting to install Drupal."
    exit 1
  fi
}

# Function to download and enable Drupal modules
function download_and_enable_modules() {
  modules=("field_group" "field_group_table" "field_formatter_class" "field_formatter_settings" "ctools" "date" "devel" "ds" "link" "entity" "libraries" "redirect" "token" "tripal-7.x-3.4" "uuid" "jquery_update" "views" "webform")
  
  # Download modules
  drush dl "${modules[@]}"
  
  # Enable modules
  drush en "${modules[@]}"
}

# Function to apply patches
function apply_patches() {
  # Download patches
  wget --no-check-certificate https://drupal.org/files/drupal.pgsql-bytea.27.patch
  patch -p1 < drupal.pgsql-bytea.27.patch
  cd sites/all/modules/views
  patch -p1 < ../tripal/tripal_chado_views/views-sql-compliant-three-tier-naming-1971160-30.patch
  cd -
}

# Function to enable Tripal modules
function enable_tripal_modules() {
  tripal_modules=("tripal" "tripal_chado" "tripal_ds" "tripal_ws")
  
  # Enable Tripal modules
  drush en "${tripal_modules[@]}"
  
  # Check for enabling errors
  if [ $? -ne 0 ]; then
    echo "An error occurred when attempting to enable Tripal modules."
    exit 1
  fi
}

# Main script
site_settings=false
while [ "$site_settings" != true ]; do
  site_name=$(prompt_with_validation "Name of the site" ".+")
  site_email=$(prompt_with_validation "Admin email for the site" "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}")
  username=$(prompt_with_validation "Name for your admin user on the site" ".+")
  user_password=$(prompt_with_validation "Password for the admin user (complex)" "^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]+$")
  
  echo -e "\nThese are the site settings provided, please review and confirm they are correct:"
  echo "Site Name: $site_name"
  echo "Site email address: $site_email"
  echo "Administrator username: $username"
  echo "Administrator password: $user_password"
  
  site_settings=$(prompt_with_validation "Is this information correct? (yes/no)" "^(yes|no)$")
done

# Database connection settings
settings_php=false
while [ "$settings_php" != true ]; do
  echo -e "\nNow we need to setup Drupal to connect to the database you want to use. These settings are added to Drupal's settings.php file."
  driver='pgsql'
  database=$(prompt_with_validation "Database name" ".+")
  postgres_username=$(prompt_with_validation "PostgreSQL username" ".+")
  postgres_password=$(prompt_with_validation "PostgreSQL password" ".+")
  host=$(prompt_with_validation "Host (e.g., localhost or 127.0.0.1)" ".+")
  port=$(prompt_with_validation "Port (usually 5432)" "^[0-9]+$")
  
  echo -e "\nThis is the database information provided, please review and confirm it is correct:"
  echo "Database name: $database"
  echo "Database username: $postgres_username"
  echo "Database user password: $postgres_password"
  echo "Database host: $host"
  echo "Database port: $port"
  
  settings_php=$(prompt_with_validation "Is this information correct? (yes/no)" "^(yes|no)$")
done

echo -e "\nNow installing Drupal..."
install_drupal

echo -e "\nDownloading modules..."
download_and_enable_modules

echo -e "\nApplying patches..."
apply_patches

echo -e "\nEnabling Tripal modules..."
enable_tripal_modules

echo -e "\nClearing cache..."
drush cc all

echo -e "\nInstallation is now complete. You may navigate to your new site."
echo "For more information on using Tripal, please see the installation guide on tripal.info."
