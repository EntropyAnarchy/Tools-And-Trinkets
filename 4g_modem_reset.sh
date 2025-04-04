#!/bin/bash

### Works on Sierra Wireless, Simtech, and Qualcomm modems ###

# Define the modem file to check
FILE="/dev/ttyUSB2"

# Check if the file exists and is a text file
if [ -f "$FILE" ] && file "$FILE" | grep -q "text"; then
    echo "$FILE is a text file. Beginning reset process."

    # Clear any text in /dev/ttyUSB2
    > /dev/ttyUSB2

    # Set modem to offline mode
    echo "Setting modem to 'offline' mode."
    if ! uqmi -d /dev/cdc-wdm0 --set-device-operating-mode offline; then
        echo "Failed to set modem offline."
	exit 1
    fi
    sleep 5

    # Reset the modem
    echo "Resetting modem, please wait."
    if ! uqmi -d /dev/cdc-wdm0 --set-device-operating-mode reset; then
        echo "Failed to reset modem."
	exit 1
    fi
    sleep 20

    # Set modem to online mode
    echo "Setting modem to 'online' mode."
    if ! uqmi -d /dev/cdc-wdm0 --set-device-operating-mode online; then
        echo "Failed to get modem online."
	exit 1
    fi

    # Retry checking connection status up to 2 times
    for i in {1..2}; do
        sleep 20
        OUTPUT=$(uqmi -d /dev/cdc-wdm0 --get-data-status 2>&1)

        if [ $? -eq 0 ]; then
            echo "Connection status: $OUTPUT"
	    break
        else
	    echo "Connection unsuccessful, attempting again."
        fi

	# If this is the last attempt and still failing, exit with an error
        if [ $i -eq 2 ]; then
            echo "Failed to retrieve data status after multiple attempts."
            exit 1
        fi
    done

else
    echo "$FILE does not exist or is not accessible. Aborting..."
    exit 1
fi
