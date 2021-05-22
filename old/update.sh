#!/bin/bash

##
# Warning: This script uses the Paper API v1, which is deprecated!
##

## SETTINGS
MC_VERSION="1.16.5"


end="\033[0m"
lightblue="\033[0;36m"
lightbluebold="\033[1;36m"
yellow="\033[0;33m"
yellowbold="\033[1;33m"
green="\033[0;92m"
greenbold="\033[1;92m"


echo -e "=== PaperMC Server Update script ===\n"

LATEST_MC_VERSION=$(curl -s "https://papermc.io/api/v1/paper" | jq -r .versions[0])

# Check if a minecraft version was selected
if [[ -z ${MC_VERSION} ]]
then
        MC_VERSION_DISPLAY="None selected, using latest"
        MC_VERSION=${LATEST_MC_VERSION}
else
        MC_VERSION_DISPLAY=${MC_VERSION}
fi

LATEST_BUILD_ALLVERSIONS=$(curl -s "https://papermc.io/api/v1/paper/${LATEST_MC_VERSION}" | jq -r .builds.latest)
LATEST_BUILD_SELECTEDVERSION=$(curl "https://papermc.io/api/v1/paper/${MC_VERSION}" -s | jq -r .builds.latest)

CURRENT_BUILD=$(readlink server.jar | grep -oP '(?<=paper-)\d{1,}(?=\.jar$)')
if [[ -z ${CURRENT_BUILD} || ! ${CURRENT_BUILD} =~ ^[[:digit:]]{1,}$ ]]
then
        # Something is wrong with the directory structure,
        # using slow version detection
        CURRENT_BUILD=$(java -jar server.jar --version | grep -o -P '\d{1,}$')
fi

echo " --> Selected Minecraft Version: ${MC_VERSION_DISPLAY}"
echo " --> Installed Build Version: ${CURRENT_BUILD}"

# Check for new MC version
if [[ ${LATEST_MC_VERSION} != ${MC_VERSION} ]]
then
        echo -en "${yellowbold}A new Minecraft version is available!"
        echo -e " (${MC_VERSION} -> ${LATEST_MC_VERSION})${end}"
fi

# Check for new build
if [[ ${CURRENT_BUILD} != ${LATEST_BUILD_SELECTEDVERSION} ]]
then
        echo -en "${yellowbold}A new build version is available!"
        echo -e " (${CURRENT_BUILD} -> ${LATEST_BUILD_SELECTEDVERSION})${end}"
else
        echo -e " --> ${greenbold}No new build available.${end}"
        echo " -> Exiting."
        exit
fi



echo -e " - Checking server status/online players..."
# Check whether players are online
SERVER_PORT=$(grep -oP '(?<=server-port\=)\d{1,}' server.properties)
SERVER_IP=$(curl -s "https://api.ipify.org")


STATUS_JSON=$(curl -s "https://api.mcsrvstat.us/2/${SERVER_IP}:${SERVER_PORT}")
SERVER_ONLINE=$(echo "${STATUS_JSON}" | jq -r .online)

if nc -z localhost ${SERVER_PORT}
then
        NC_SERVERPORT_OPEN=true
else
        NC_SERVERPORT_OPEN=false
fi

if [[ "${SERVER_ONLINE}" = "true" && "${NC_SERVERPORT_OPEN}" = "true" ]]
then
        PLAYERS_ONLINE=$(echo "${STATUS_JSON}" | jq -r .players.online)
else
        PLAYERS_ONLINE=0
fi


if [[ ${PLAYERS_ONLINE} -ge 1 ]]
then
        echo -e " = ${yellowbold}WARNING: There are ${PLAYERS_ONLINE} players online!${end} ="
        echo " -> [TODO: Automate!]"
        echo -e " -> ${yellow}You will have to stop the server manually.${end}"
        read -p "Continue anyways? (Press Ctrl-C otherwise)"
else
        if [[ ${SERVER_ONLINE} = "false" && "${NC_SERVERPORT_OPEN}" = "false" ]]
        then
                echo -e " --> ${green}All good! The server doesn't seem to be running.${end}"
        else
                echo -e " --> ${yellow}WARNING: The server seems to be running!${end}"
                echo -e " -> ${yellow}You will have to stop the server manually.${end}"
                read -p "Continue anyways? (Press Ctrl-C otherwise)"
        fi
fi

# Check required folder structure for download
if ! [[ -d "paper-versions" ]]
then
        echo -e " - ${yellow}Creating paper-versions directory"
        mkdir -p "paper-versions"
fi

if ! [[ -d "paper-versions/${MC_VERSION}" ]]
then
        echo -e " - ${yellow}Creating directory for MC version"
        mkdir -p "paper-versions/${MC_VERSION}"
fi


SELECTED_DOWNLOAD_LINK="https://papermc.io/api/v1/paper/${MC_VERSION}/${LATEST_BUILD_SELECTEDVERSION}/download"



if [[ -f "paper-versions/${MC_VERSION}/paper-${LATEST_BUILD_SELECTEDVERSION}.jar" ]]
then
        echo -e " --> ${green}The newest build version was already downloaded.${end}"
else
        echo -e " - ${greenbold}Downloading newest build file...${end}"
        if ! wget -O "paper-versions/${MC_VERSION}/paper-${LATEST_BUILD_SELECTEDVERSION}.jar" -q --show-progress --progress=bar "${SELECTED_DOWNLOAD_LINK}"
        then
                echo -e "${redbold}ERROR: wget exited with an error.${end}"
                echo -e "${red}Exiting.${end}"
                exit 1
        else
                echo -e "${greenbold} --> File downloaded successfully.${end}"
        fi
fi

# Replace the server.jar link with the new version
echo " - Updating server file link..."

if ! rm "server.jar"
then
        echo -e " --> ${red}ERROR: rm failed to remove the server.jar file!${end}"

        if [[ ! -f "server.jar" ]]
        then
                echo -e " -- Trying to link anyways..."
        else
                echo -e " --> ${redbold}ERROR: File still exists! Please check your permissions and file type.${end}"
                echo -e " --> ${redbold}Exiting.${end}"
        fi
else
        echo -e " --> ${green}Removed old link${end}"
fi

if ! ln -s "paper-versions/${MC_VERSION}/paper-${LATEST_BUILD_SELECTEDVERSION}.jar"  "server.jar"
then
        echo -e " --> ${redbold}ERROR: New link could not be created!${end}"
        echo -e " --> ${redbold}Exiting.${end}"
else
        echo -e " --> ${green}Updated link created.${end}"
fi

echo -e "\n  ${greenbold}####################################${end}"
echo -e "  ${greenbold}FREUET EUCH, DENN ES IST VOLLBRACHT!${end}"
echo -e "  ${greenbold}####################################${end}\n"



#wget --content-disposition ''

# paper-versions/${mc-version}/paper-${build-id}.jar
