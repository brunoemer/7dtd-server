#!/usr/bin/env bash

child=0

trap 'exit_handler' SIGHUP SIGINT SIGQUIT SIGTERM
exit_handler()
{
	echo "Shut down signal received.."
	expect /shutdown.sh
	sleep 6
	echo "Forcefully terminating if necessary.."
	sleep 1
	kill $child 2>/dev/null
	wait $child 2>/dev/null
	exit
}

# add variables values from docker environment to SD2D config file before replacing default one and starting server.
# example:  if variable MaxSpawnedZombies=100 is defined in enviroment, it will change the config default value to 100.
# this variables can be passed when starting docker container with flag
#       --env MaxSpawnedZombies=100
echo "Changing serverconfig.xml"
for var in `env|grep -o .*=|sed 's/=//'`;
do 
        SD2D=`grep $var /serverconfig.xml`;
        if ! [ x"${SD2D}" = "x" ];
         then
                current_value=`echo $SD2D|grep -Eo "value=\".*\""`;
                new_value=`echo "value=\"${!var}\""`;
                
        #       echo $current_value
        #       echo $new_value
        #       echo $SD2D 

                new_SD2D=`echo $SD2D|sed "s/${current_value}/${new_value}/"`
                
        #       echo $new_SD2D          
                sed -i.bak "s#${SD2D}#${new_SD2D}#g" /serverconfig.xml
        fi
done

# Create the necessary folder structure
if [ ! -d "/steamcmd/7dtd/server_data" ]; then
	echo "Creating folder structure.."
	mkdir -p /steamcmd/7dtd/server_data
fi

# Copy the default config if necessary
if [ ! -f "/steamcmd/7dtd/server_data/serverconfig.xml" ]; then
	echo "Copying default server configuration.."
	cp /serverconfig.xml /steamcmd/7dtd/server_data/serverconfig.xml
fi

# Create an empty log file if necessary
if [ ! -f "/steamcmd/7dtd/server_data/7dtd.log" ]; then
	echo "Creating an empty log file.."
	touch /steamcmd/7dtd/server_data/7dtd.log
fi

# Create the necessary folder structure
if [ ! -d "/steamcmd/7dtd/log" ]; then
        echo "Creating folder log.."
        mkdir -p /steamcmd/7dtd/log
fi

# Disable auto-update if start mode is 2
if [ "$SEVEN_DAYS_TO_DIE_START_MODE" = "2" ]; then
	# Check that 7 Days to Die exists in the first place
	if [ ! -f "/steamcmd/7dtd/7DaysToDieServer.x86_64" ]; then
		# Install 7 Days to Die from install.txt
		echo "Installing/updating 7 Days to Die.. (this might take a while, be patient)"
		STEAMCMD_OUTPUT=$(bash /steamcmd/steamcmd.sh +runscript /install.txt | tee /dev/stdout)
		STEAMCMD_ERROR=$(echo $STEAMCMD_OUTPUT | grep -q 'Error')
		if [ ! -z "$STEAMCMD_ERROR" ]; then
			echo "Exiting, steamcmd install or update failed: $STEAMCMD_ERROR"
			exit
		fi
	else
		echo "7 Days to Die seems to be installed, skipping automatic update.."
	fi
else
	# Install/update 7 Days to Die from install.txt
	echo "Installing/updating 7 Days to Die.. (this might take a while, be patient)"
	STEAMCMD_OUTPUT=$(bash /steamcmd/steamcmd.sh +runscript /install.txt | tee /dev/stdout)
	STEAMCMD_ERROR=$(echo $STEAMCMD_OUTPUT | grep -q 'Error')
	if [ ! -z "$STEAMCMD_ERROR" ]; then
		echo "Exiting, steamcmd install or update failed: $STEAMCMD_ERROR"
		exit
	fi

	# Run the update check if it's not been run before
	if [ ! -f "/steamcmd/7dtd/build.id" ]; then
		./update_check.sh
	else
		OLD_BUILDID="$(cat /steamcmd/7dtd/build.id)"
		STRING_SIZE=${#OLD_BUILDID}
		if [ "$STRING_SIZE" -lt "6" ]; then
			./update_check.sh
		fi
	fi
fi

# Start mode 1 means we only want to update
if [ "$SEVEN_DAYS_TO_DIE_START_MODE" = "1" ]; then
	echo "Exiting, start mode is 1.."
	exit
fi

# Start cron
echo "Starting scheduled task manager.."
node /scheduler_app/app.js &

# Set the working directory
cd /steamcmd/7dtd

# Run the server
echo "Starting 7 Days to Die.."
/steamcmd/7dtd/7DaysToDieServer.x86_64 -logfile /steamcmd/7dtd/log/`date +%Y-%m-%d__%H-%M-%S`.log ${SEVEN_DAYS_TO_DIE_SERVER_STARTUP_ARGUMENTS} &

child=$!
wait "$child"
