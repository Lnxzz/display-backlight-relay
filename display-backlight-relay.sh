#!/bin/sh

#
# configuration
#

# initial state: 0=screen off; 1=screen on
INITIAL_STATE=1

# relay to use: 0=first relay; 1=second relay
RELAY_NR=1

# relay control: 0=do not set/unset relay; 1=set/unset relay
RELAY_CONTROL=1

# hdmi control: 0=do not enable/disable hdmi; 1=enable/disable hdmi
HDMI_CONTROL=0


#
# definitions
#

# define commands to turn the relay on, off and get its state
BACKLIGHT_CMD_ON="dbus-send --system --print-reply --dest=com.victronenergy.system /Relay/$RELAY_NR/State com.victronenergy.BusItem.SetValue variant:int32:1"
BACKLIGHT_CMD_OFF="dbus-send --system --print-reply --dest=com.victronenergy.system /Relay/$RELAY_NR/State com.victronenergy.BusItem.SetValue variant:int32:0"
BACKLIGHT_CMD_GET_STATE="dbus-send --system --print-reply --dest=com.victronenergy.system /Relay/$RELAY_NR/State com.victronenergy.BusItem.GetValue"

# control file to monitor whether the screen should be turned off (indicate by value 1)
BLANK_RUN_FILE="/run/venus/blank_display_device.value"

# get touch screen input path
TOUCHSCREEN_INPUT_PATH="/dev/$(udevadm info --export-db | awk '/ID_INPUT_TOUCHSCREEN=1/{f=1; next} f && /N: input\/event/{print $2; exit}')"
if [[ ! -c "$TOUCHSCREEN_INPUT_PATH" ]]; then
  echo "ERROR: cannot locate touchscreen input event file at $TOUCHSCREEN_INPUT_PATH"
  svc -d .
  exit 1
fi

# get hdmi status control path
HDMI_STATUS_PATH="/sys/class/drm/$(ls /sys/class/drm | grep -i hdmi | head -n 1)/status"
if [[ ! -f "$HDMI_STATUS_PATH" ]]; then
  echo "ERROR: cannot locate hdmi status file at $HDMI_STATUS_PATH"
  svc -d .
  exit 1
fi


#
# startup
#

# ensure presence of the control file
echo "1" > "$BLANK_RUN_FILE"
sync

# get current state of the relay
if [[ "$RELAY_CONTROL" == "1" ]]; then
  BACKLIGHT_VALUE=$($BACKLIGHT_CMD_GET_STATE | awk -F'int32 ' '{printf "%s",$2}END{print '\n'}')
  echo "display-backlight-relay: using relay $RELAY_NR with backlight state $BACKLIGHT_VALUE."

  # set initial state of the relay; toggle relay when needed
  if [[ "$INITIAL_STATE" != "$BACKLIGHT_VALUE" ]]; then
    if [[ "$INITIAL_STATE" == "1" ]]; then
      echo "display-backlight-relay: startup: switching relay $RELAY_NR to turn backlight on."
      $BACKLIGHT_CMD_ON
    else
      echo "display-backlight-relay: startup: switching relay $RELAY_NR to turn backlight off."
      $BACKLIGHT_CMD_OFF
    fi
  fi
fi


#
# control loop
#

# monitor the display control file
while true; do
  inotifywait -q -e modify "$BLANK_RUN_FILE"
  BLANK_CONTROL_VALUE=$(cat "$BLANK_RUN_FILE")
  
  if [[ "$BLANK_CONTROL_VALUE" == "1" ]]; then
    # turn off backlight relay
    if [[ "$RELAY_CONTROL" == "1" ]]; then
      echo "display-backlight-relay: switching relay $RELAY_NR to turn backlight off."
      $BACKLIGHT_CMD_OFF
    fi

    # turn off hdmi
    if [[ "$HDMI_CONTROL" == "1" ]]; then
      echo off > "$HDMI_BLANK_FILE_PATH"
    fi

    sleep 5
    
    # wait for touchscreen event
    echo "setting trigger for touchscreen wakeup"
    inotifywait -e access "$TOUCHSCREEN_INPUT_PATH"
    
    # turn on backlight relay
    if [[ "$RELAY_CONTROL" == "1" ]]; then
      echo "display-backlight-relay: switching relay $RELAY_NR to turn backlight on."
      $BACKLIGHT_CMD_ON
    fi
 
    # turn on hdmi
    if [[ "$HDMI_CONTROL" == "1" ]]; then
      echo on > "$HDMI_BLANK_FILE_PATH"
    fi
  elif [[ "$BLANK_CONTROL_VALUE" == "0" ]]; then
    # ensure backlight relay is turned on when the screen is active
    if [[ "$RELAY_CONTROL" == "1" ]]; then
      BACKLIGHT_VALUE=$($BACKLIGHT_CMD_GET_STATE | awk -F'int32 ' '{printf "%s",$2}END{print '\n'}')
      if [[ "$BACKLIGHT_VALUE" != "1" ]]; then
        echo "display-backlight-relay: screen active: switching relay $RELAY_NR to turn backlight on."
        $BACKLIGHT_CMD_ON
      fi
    fi
  else
    echo "WARN: received unknown control value: $BLANK_CONTROL_VALUE"
  fi
done
