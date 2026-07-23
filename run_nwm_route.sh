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
# Usage:
#   bash run_nwm_route.sh --START_TIME 202607231200 --FORECAST_TYPE 1 --VPU 03W
# =============================================================================

# Argument parser
# Default values
START_TIME=""
FORECAST_TYPE=""
VPU=""

# Valid options
VALID_FORECAST_TYPES="1 2 3 4 11"
VALID_VPUS="01 02 03N 03S 03W 04 05 06 07 08 09 10L 10U 11 12 13 14 15 16 17 18"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --START_TIME)
            START_TIME="$2"
            shift 2
            ;;
        --FORECAST_TYPE)
            FORECAST_TYPE="$2"
            shift 2
            ;;
        --VPU)
            VPU="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 --START_TIME <YYYYMMDDHHmm> --FORECAST_TYPE <1|2|3|4|11> --VPU <VPU_code>"
            echo ""
            echo "Arguments:"
            echo "  --START_TIME      Start time in YYYYMMDDHHmm format (required)"
            echo "  --FORECAST_TYPE   Forecast type: 1, 2, 3, 4, or 11 (required)"
            echo "  --VPU             VPU code: 01, 02, 03N, 03S, 03W, etc. (required)"
            echo ""
            echo "Example: $0 --START_TIME 202607031100 --FORECAST_TYPE 1 --VPU 03W"
            exit 0
            ;;
        *)
            echo "Error: Unknown option '$1'"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate required arguments
if [[ -z "$START_TIME" || -z "$FORECAST_TYPE" || -z "$VPU" ]]; then
    echo "Error: Missing required arguments"
    echo "Use --help for usage information"
    exit 1
fi

# Validate START_TIME format (YYYYMMDDHHmm = 12 digits)
if ! [[ "$START_TIME" =~ ^[0-9]{12}$ ]]; then
    echo "Error: START_TIME must be in YYYYMMDDHHmm format (12 digits)"
    exit 1
fi

# Validate FORECAST_TYPE
if ! [[ "$VALID_FORECAST_TYPES" =~ $FORECAST_TYPE ]]; then
    echo "Error: FORECAST_TYPE must be one of: $VALID_FORECAST_TYPES"
    exit 1
fi

# Validate VPU
if ! [[ "$VALID_VPUS" =~ $VPU ]]; then
    echo "Error: VPU must be one of: $VALID_VPUS"
    exit 1
fi

# If we get here, all arguments are valid
echo "START_TIME: $START_TIME"
echo "FORECAST_TYPE: $FORECAST_TYPE"
echo "VPU: $VPU"

# Fetch and rename NWM forecasted channel routing data
python fetch_nwm_data.py --start_date "${START_TIME}" --runinput "${FORECAST_TYPE}"
mkdir ./channel_forcing
wget -P ./channel_forcing -i filenamelist.txt
python rename_troute_inputs.py --start_date "${START_TIME}" --directory ./channel_forcing

# Fetch and reformat NWM analysis_assim data into restarts
python fetch_nwm_data.py --start_date "${START_TIME}" --runinput 5
mkdir ./restart
wget -P ./restart -i filenamelist.txt -O analysis_assim.nc
RESTART_FILE=$(python restart.py \
    --nwm_file_path ./restart/analysis_assim.nc \
    --routelink_file_path RouteLink_CONUS.nc \
    --map_file_path nwm_to_ngen_map.json \
    --output_directory ./restart)

# Some function to edit troute.yaml and run t-route
# Do some regex magic to change start_datetime and nts, and mask file
mkdir ./outputs
# TODO: figure out regex
# python3 -m nwm_routing -f -V4 troute.yaml

# Some function to convert NWM t-route outputs into NextGen catchment resolution
python nwm_to_ngen.py \
    --nwm_to_ngen_map nwm_to_ngen_map.json \
    --troute_outputs ./outputs