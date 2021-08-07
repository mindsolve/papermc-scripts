#!/usr/bin/env python3

import requests

# === Settings

# Major Minecraft version, e.g. 1.16 instead of 1.16.5
# Comment out if latest should be used
MC_VERSION = "1.16"

# === End of settings

api_baseurl = "https://papermc.io/api/v2"
api_paper = api_baseurl + "/projects/paper"


def request_version_groups():
    res = requests.get(api_paper)
    return res.json()["version_groups"]


def request_version_group_info(version_group: str):
    res = requests.get(api_paper + "/version_group/" + version_group)
    return res.json()


def request_latest_build(version_group: str):
    res = requests.get(api_paper + "/version_group/" + version_group + "/builds")
    return res.json()["builds"][-1]


def download_build(mc_version: str, build: int):
    res = requests.get(api_paper)

def get_latest_build(version_group: str):
    # Use latest version if none is set
    if version_group is None:
        version_group = request_version_groups()[-1]

    latest_build = request_latest_build(version_group)
    return latest_build


def main():
    print("The latest build version for group", MC_VERSION, "is:", get_latest_build(MC_VERSION))
    print()

if __name__ == '__main__':
    main()
