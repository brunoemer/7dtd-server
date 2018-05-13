FROM didstopia/base:nodejs-steamcmd-ubuntu-16.04

MAINTAINER Didstopia <support@didstopia.com>

# Fixes apt-get warnings
ARG DEBIAN_FRONTEND=noninteractive

# Install dependencies, mainly for SteamCMD
RUN apt-get update && \
	apt-get install -y --no-install-recommends \
    xvfb \
    curl \
    wget \
    telnet \
    expect \
    net-tools && \
    rm -rf /var/lib/apt/lists/*

#timezone
ENV TZ=America/Sao_Paulo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Run as root
USER root

# Create and set the steamcmd folder as a volume
RUN mkdir -p /steamcmd/7dtd

# Setup scheduling support
ADD scheduler_app/ /scheduler_app/
WORKDIR /scheduler_app
RUN npm install
WORKDIR /

# Add the steamcmd installation script
ADD install.txt /install.txt

# Copy scripts
ADD start_7dtd.sh /start.sh
ADD shutdown.sh /shutdown.sh
ADD update_check.sh /update_check.sh

# Copy the default server config in place
ADD serverconfig_original.xml /serverconfig.xml



#MOVED TO COMPOSE docker-compose.yml

# Expose necessary ports
#EXPOSE 26910
#EXPOSE 26911
#EXPOSE 26912
#EXPOSE 26913
#EXPOSE 8080
#EXPOSE 8081

# Setup default environment variables for the server
#ENV SEVEN_DAYS_TO_DIE_SERVER_STARTUP_ARGUMENTS "-configfile=server_data/serverconfig.xml -logfile /steamcmd/7dtd/log/output.log -quit -batchmode -nographics -dedicated"
#ENV SEVEN_DAYS_TO_DIE_TELNET_PORT 8081
#ENV SEVEN_DAYS_TO_DIE_TELNET_PASSWORD "kweiowejrt209@"
#ENV SEVEN_DAYS_TO_DIE_START_MODE "0"
#ENV SEVEN_DAYS_TO_DIE_UPDATE_CHECKING "0"
#ENV SEVEN_DAYS_TO_DIE_UPDATE_BRANCH "public"

# Start the server
#ENTRYPOINT ["./start.sh"]
