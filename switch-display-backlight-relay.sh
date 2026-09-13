#!/bin/sh

# configuration
# relay to use: 0=first relay; 1=second relay
RELAY_NR=1


# define commands to turn the relay on, off and get its state
BACKLIGHT_CMD_ON="dbus-send --system --print-reply --dest=com.victronenergy.system /Relay/$RELAY_NR/State com.victronenergy.BusItem.SetValue variant:int32:1"
BACKLIGHT_CMD_OFF="dbus-send --system --print-reply --dest=com.victronenergy.system /Relay/$RELAY_NR/State com.victronenergy.BusItem.SetValue variant:int32:0"
BACKLIGHT_CMD_GET_STATE="dbus-send --system --print-reply --dest=com.victronenergy.system /Relay/$RELAY_NR/State com.victronenergy.BusItem.GetValue"

# control file to monitor whether the screen is requested to turn off or on
BLANK_RUN_FILE="/run/venus/blank_display_device.value"

# get current state of the relay
BACKLIGHT_GET_STATE=$($BACKLIGHT_CMD_GET_STATE | awk -F'int32 ' '{printf "%s",$2}END{print '\n'}')
BACKLIGHT_VALUE=$BACKLIGHT_GET_STATE
echo "$0: using relay $RELAY_NR with backlight state $BACKLIGHT_VALUE."

# switch relay on/off, sync or toggle
NO_COMMAND=0
if [ $# -ne 0 ]; then
  if [[ "$1" == "on" ]]; then
    $BACKLIGHT_CMD_ON
    echo "explicit on"
  elif [[ "$1" == "off" ]]; then
    $BACKLIGHT_CMD_OFF
    echo "explicit off"
  elif [[ "$1" == "sync" ]]; then
    BLANK_CONTROL_VALUE=$(cat "$BLANK_RUN_FILE")
    if [[ "$BLANK_CONTROL_VALUE" == "0" ]]; then
      $BACKLIGHT_CMD_ON
      echo "sync screen to on"
    elif [[ "$BLANK_CONTROL_VALUE" == "1" ]]; then
      $BACKLIGHT_CMD_OFF
      echo "sync screen to off"
    fi
  elif [[ "$1" == "toggle" ]]; then
    if [[ "$BACKLIGHT_VALUE" == "1" ]]; then
      $BACKLIGHT_CMD_OFF
      echo "toggle off"
    else
      $BACKLIGHT_CMD_ON
      echo "toggle on"
    fi
  else
    NO_COMMAND=1
  fi
else
  NO_COMMAND=1
fi

if [[ "$NO_COMMAND" == "1" ]]; then
  echo "usage: $0 <on|off|sync|toggle>"
  echo "options:"
  echo "  off   : turn screen off"
  echo "  on    : turn screen on"
  echo "  sync  : synchronize screen state with gui"
  echo "  toggle: toggle screen on/off"
else
  # show final state
  NEW_VALUE=$($BACKLIGHT_CMD_GET_STATE | awk -F'int32 ' '{printf "%s",$2}END{print '\n'}')
  echo backlight state set to $NEW_VALUE.
fi
