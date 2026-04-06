#!/bin/sh

# Shutdown on error
set -e

# Check if MOSQUITTO_USERNAME and MOSQUITTO_PASSWORD environment variables are defined
if [ -z "$MOSQUITTO_USERNAME" ] || [ -z "$MOSQUITTO_PASSWORD" ]; then
  echo "ERROR: Environment variables MOSQUITTO_USERNAME and MOSQUITTO_PASSWORD must be defined."
  exit 1
fi

# Check if GUEST_USERNAME and GUEST_PASSWORD environment variables are defined
if [ -z "$GUEST_USERNAME" ] || [ -z "$GUEST_PASSWORD" ]; then
  echo "ERROR: Environment variables GUEST_USERNAME and GUEST_PASSWORD must be defined."
  exit 1
fi

# Remove old password file if it exists (prevents write-permission errors on restart)
rm -f /mosquitto/config/password_file

# Create password file with the primary user (-c creates/overwrites the file)
mosquitto_passwd -b -c /mosquitto/config/password_file "$MOSQUITTO_USERNAME" "$MOSQUITTO_PASSWORD"

# Add the guest user (append to existing file, no -c flag)
mosquitto_passwd -b /mosquitto/config/password_file "$GUEST_USERNAME" "$GUEST_PASSWORD"

# Define "mosquitto" as owner of the password file
chown mosquitto:mosquitto /mosquitto/config/password_file

# Create the ACL file from scratch if it doesn't exist
if [ ! -f /mosquitto/config/acl_file ]; then
  echo "ACL file not found — creating it now."
  cat > /mosquitto/config/acl_file <<'EOF'
user guest
topic readwrite Telestra\ DQM\ Data
EOF
fi

# Ensure the ACL file has correct ownership
chown mosquitto:mosquitto /mosquitto/config/acl_file

# Verify both files exist and are non-empty before starting the broker
if [ ! -s /mosquitto/config/password_file ]; then
  echo "ERROR: password_file is missing or empty."
  exit 1
fi

if [ ! -s /mosquitto/config/acl_file ]; then
  echo "ERROR: acl_file is missing or empty."
  exit 1
fi

echo "password_file and acl_file verified — starting Mosquitto."

# Passes execution to the container's original command (starts Mosquitto)
# "$@" represents all arguments passed to the script, which in our case
# will be the command to start the broker defined in the Dockerfile.
exec "$@"
