#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SERVICE_NAME=$(basename $SCRIPT_DIR)
BLANK_CONFIGURATION_FILE="/etc/venus/blank_display_device"
BLANK_RUN_FILE="/run/venus/blank_display_device"
  
# stop service immediately to avoid a reboot
svc -d /service/$SERVICE_NAME
#kill $(pgrep -f "supervise $SERVICE_NAME")
sleep 1
rm -rf /service/$SERVICE_NAME
  
# delete configuration files
rm -f "$BLANK_CONFIGURATION_FILE"
rm -f "$BLANK_CONFIGURATION_FILE.in"
rm -f "$BLANK_RUN_FILE"
rm -f "$BLANK_RUN_FILE.value"
  
# restore default configuration files
mv "$BLANK_CONFIGURATION_FILE.bak" "$BLANK_CONFIGURATION_FILE"
mv "$BLANK_CONFIGURATION_FILE.in.bak" "$BLANK_CONFIGURATION_FILE.in"
cp -f "$BLANK_CONFIGURATION_FILE" "$BLANK_RUN_FILE"

# clear logs
rm -rf /var/log/display-backlight-relay

# remove service install from rc.local 
sed -i "/$SERVICE_NAME/d" /data/rc.local
