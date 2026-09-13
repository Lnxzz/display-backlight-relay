#!/bin/bash
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SERVICE_NAME=$(basename $SCRIPT_DIR)

BLANK_CONFIGURATION_FILE="/etc/venus/blank_display_device"
RUN_CONFIGURATION_FILE="/run/venus/blank_display_device"
BLANK_RUN_FILE="/run/venus/blank_display_device"

# restore venos os defaults if no configuration files are available
if [ ! -f "$BLANK_CONFIGURATION_FILE" ]; then
    echo "/sys/class/backlight/gxdisp-2-0051/bl_power" > "$BLANK_CONFIGURATION_FILE"
fi
if [ ! -f "$BLANK_CONFIGURATION_FILE.in" ]; then
    echo "/sys/class/backlight/gxdisp-2-0051/bl_power % victronenergy,cerbo-gx.*" > "$BLANK_CONFIGURATION_FILE.in"
fi

DEFAULT_CONF_VALUE=$(cat "$BLANK_CONFIGURATION_FILE")

# backup default configuration files, but keep existing when present
if [ ! -f "$BLANK_CONFIGURATION_FILE.bak" ]; then
    cp "$BLANK_CONFIGURATION_FILE" "$BLANK_CONFIGURATION_FILE.bak"
fi
if [ ! -f "$BLANK_CONFIGURATION_FILE.in.bak" ]; then
    cp "$BLANK_CONFIGURATION_FILE.in" "$BLANK_CONFIGURATION_FILE.in.bak"
fi
  
# create new configuration files
if [ -L "$BLANK_CONFIGURATION_FILE" ]; then
    cp -f "$(readlink $BLANK_CONFIGURATION_FILE)" "$BLANK_CONFIGURATION_FILE"
fi
sed -i -e "s|$DEFAULT_CONF_VALUE|$BLANK_RUN_FILE.value|g" "$BLANK_CONFIGURATION_FILE"
cp -f "$BLANK_CONFIGURATION_FILE" "$RUN_CONFIGURATION_FILE"
if [ -L "$BLANK_CONFIGURATION_FILE.in" ]; then
    cp -f "$(readlink $BLANK_CONFIGURATION_FILE.in)" "$BLANK_CONFIGURATION_FILE.in"
fi
sed -i -e "s|$DEFAULT_CONF_VALUE|$BLANK_RUN_FILE.value|g" "$BLANK_CONFIGURATION_FILE.in"
echo "0" > "$BLANK_RUN_FILE.value"

# set permissions for script files
chmod 744 $SCRIPT_DIR/install.sh
chmod 744 $SCRIPT_DIR/uninstall.sh
chmod 755 $SCRIPT_DIR/service/run
chmod 755 $SCRIPT_DIR/service/log/run

# create sym-link to run script in deamon
echo "creating symlink /service/$SERVICE_NAME to $SCRIPT_DIR/service"
ln -s $SCRIPT_DIR/service /service/$SERVICE_NAME

# add install-script to rc.local to reinstall after a firmware update
filename=/data/rc.local
if [ ! -f $filename ]
then
    touch $filename
    chmod 777 $filename
    echo "#!/bin/bash" >> $filename
    echo >> $filename
fi

# if not alreay added, then add to rc.local
grep -qxF "bash $SCRIPT_DIR/install.sh" $filename || echo "bash $SCRIPT_DIR/install.sh" >> $filename
