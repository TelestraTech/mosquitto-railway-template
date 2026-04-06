#!/bin/sh

# Shutdown on error
set -e

# Check if MOSQUITTO_USERNAME and MOSQUITTO_PASSWORD environment variables are defined
if [ -z "$MOSQUITTO_USERNAME" ] || [ -z "$MOSQUITTO_PASSWORD" ]; then
  echo "ERROR: Environment variables MOSQUITTO_USERNAME and MOSQUITTO_PASSWORD must be defined."
  exit 1
fi

# Create password file with the primary user (-c creates/overwrites the file)
mosquitto_passwd -b -c /mosquitto/config/password_file "$MOSQUITTO_USERNAME" "$MOSQUITTO_PASSWORD"

# Add the guest user (append to existing file, no -c flag)
mosquitto_passwd -b /mosquitto/config/password_file guest guest123

# Define "mosquitto" as owner of the password file
chown mosquitto:mosquitto /mosquitto/config/password_file

# Ensure the ACL file has correct ownership
chown mosquitto:mosquitto /mosquitto/config/acl_file

# Passes execution to the container's original command (starts Mosquitto)
# "$@" represents all arguments passed to the script, which in our case
# will be the command to start the broker defined in the Dockerfile.
exec "$@"