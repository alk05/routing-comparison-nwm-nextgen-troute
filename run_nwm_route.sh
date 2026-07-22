#!/usr/bin/env bash
# =============================================================================
# run_nwm_route.sh
#
# Fetch NWM channel routing forecast output files from Google Cloud Storage,
# rename the files so they work with t-route, and place in the channel_forcing
# directory.
#
# Next, fetch NWM analysis_assim channel routing output files from Google Cloud
# Storage, reformat the files using restart.ipynb code to generate a working
# restart file, and place the restart file in the restart folder.
#
# Then, edit the t-route config file to have the appropriate start_datetime
# and nts. Use python3 -m nwm_routing -f -V4 troute.yaml to run t-route.
#
# Finally, run some code that comes from visualizing_outputs.ipynb to recast
# NWM t-route outputs to NextGen catchment resolution.
#
# Defaults to short range (18-hour forecast) when called with no arguments.
#
# Usage (PLACEHOLDER):
#   bash Scripts/run_qkrig_hourly.sh                         # yesterday, all 24 h
#   bash Scripts/run_qkrig_hourly.sh --date 2024-09-26       # specific date, all 24 h
#   bash Scripts/run_qkrig_hourly.sh --date 2024-09-26 --hour 04          # single hour
#   bash Scripts/run_qkrig_hourly.sh --date 2024-09-26 --start-hour 00 --end-hour 11  # hour range
#   bash Scripts/run_qkrig_hourly.sh --start-date 2024-09-25 --end-date 2024-09-28    # date range, all 24 h each
#
# Docker usage (env-var driven) (PLACEHOLDER):
#   docker run -e DATE=2024-09-26 -e HOUR=04 ...
#   docker run -e DATE=2024-09-26 -e START_HOUR=00 -e END_HOUR=11 ...
#   docker run -e START_DATE=2024-09-25 -e END_DATE=2024-09-28 ...
# =============================================================================

# Arguments we need to take:
# start time YYYYmmddHHMM
# forecast type
# VPU
# TODO: write an argument parser

# Some function to fetch and reformat NWM forecast data
# python fetch_nwm_data.py --start_date YYYYmmddHHMM --runinput 1
# wget -P /path/to/channel_forcing -i filenamelist.txt
# some scripting to rename the files
# TODO: write the rename file scripting

# Some function to fetch and reformat NWM analysis_assim data into restarts
# python fetch_nwm_data.py --start_date YYYYmmddHHMM --runinput 5
# wget -i filenamelist.txt
# python restart.py --nwm_file_path /path/to/analysis/assim/file
#    --routelink_file_path /path/to/RouteLink_CONUS.nc
#    --map_file_path /path/to/nwm_to_ngen_map.json
#   --output_directory /path/to/restart/dir

# Some function to edit troute.yaml and run t-route
# Do some regex magic to change start_datetime and nts, and mask file
# TODO: figure out regex
# python3 -m nwm_routing -f -V4 troute.yaml

# Some function to convert NWM t-route outputs into NextGen catchment resolution
# use code from visualizing_outputs.ipynb
# TODO: rewrite visualizing_outputs.ipynb into a visualizing_outputs.ipynb