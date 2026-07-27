#!/usr/bin/env bash
# =============================================================================
# preprocess_data.sh
#
# Fetch NWM channel routing forecast output files from Google Cloud Storage,
# rename the files so they work with t-route, and place in the channel_forcing
# directory.
#
# Next, fetch NWM analysis_assim channel routing output files from Google Cloud
# Storage, reformat the files using restart.ipynb code to generate a working
# restart file, and place the restart file in the restart folder.
#
# Finally, edit the t-route config file to have the appropriate start_datetime
# and nts.
#
# Usage:
#   bash preprocess_data.sh --START_TIME 202607231200 --FORECAST_TYPE 1
#   --VPU 03W --N_CPUS 4
#   docker run --rm -v
#       "/path/to/dir:/routing-comparison-nwm-nextgen-troute/t-route"
#       --env START_TIME=202607231200 --env FORECAST_TYPE=1 --env VPU="03W"
#       --env --N_CPUS=4
#       preprocessor-image
# =============================================================================

# Argument parser
# Default values
START_TIME=""
FORECAST_TYPE=""
VPU=""
N_CPUS=""

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
        --N_CPUS)
            N_CPUS="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 --START_TIME <YYYYMMDDHHmm> --FORECAST_TYPE <1|2|3|4|11> --VPU <VPU_code> --N_CPUS <num of cpus>"
            echo ""
            echo "Arguments:"
            echo "  --START_TIME      Start time in YYYYMMDDHHmm format (required)"
            echo "  --FORECAST_TYPE   Forecast type: 1, 2, 3, 4, or 11 (required)"
            echo "  --VPU             VPU code: 01, 02, 03N, 03S, 03W, etc. (required)"
            echo "  --N_CPUS          Number of CPUs to use in t-route"
            echo ""
            echo "Example: $0 --START_TIME 202607031100 --FORECAST_TYPE 1 --VPU 03W -N_CPUS 4"
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
if [[ -z "$START_TIME" || -z "$FORECAST_TYPE" ]]; then
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
echo "N_CPUS: $N_CPUS"

# Prep volume
rm -rf ./t-route/*

# Fetch and rename NWM forecasted channel routing data
python scripts/python/fetch_nwm_data.py --start_date "${START_TIME}" --runinput "${FORECAST_TYPE}"
mkdir ./t-route/channel_forcing
wget -P ./t-route/channel_forcing -i filenamelist.txt
python scripts/python/rename_troute_inputs.py --start_date "${START_TIME}" --directory \
    ./t-route/channel_forcing

# Fetch and reformat NWM analysis_assim data into restarts
python scripts/python/fetch_nwm_data.py --start_date "${START_TIME}" --runinput 5
mkdir ./t-route/restart
wget -P ./t-route/restart -i filenamelist.txt
mv ./t-route/restart/nwm*.nc ./t-route/restart/analysis_assim.nc

RESTART_FILE=$(python scripts/python/restart.py \
    --nwm_file_path ./t-route/restart/analysis_assim.nc \
    --routelink_file_path data/RouteLink_CONUS.nc \
    --map_file_path data/nwm_to_ngen_map.json \
    --output_directory ./t-route/restart)

# Set up directories
mkdir ./t-route/output
mkdir ./t-route/domain
mv data/RouteLink_CONUS.nc ./t-route/domain

# Fill in fields in troute.yaml
MASK_FILE_ORIGINAL="data/vpu${VPU,,}_ids.txt"
mv "$MASK_FILE_ORIGINAL" ./t-route/domain
MASK_FILE_PATH="vpu${VPU,,}_ids.txt"
export MASK_FILE_PATH
export N_CPUS

year=${START_TIME:0:4}
month=${START_TIME:4:2}
day=${START_TIME:6:2}
hour=${START_TIME:8:2}
minute=${START_TIME:10:2}
START_DATETIME="${year}-${month}-${day}_${hour}:${minute}"
export START_DATETIME

export RESTART_FILE

case $FORECAST_TYPE in
    1|11)
        N_HOURS=18
        ;;
    2|3)
        N_HOURS=240
        ;;
    4)
        N_HOURS=720
        ;;
    *)
        echo "Invalid forecast type: $FORECAST_TYPE"
        exit 1
        ;;
esac

NTS=$((N_HOURS*12))
export NTS
export MAX_LOOP_SIZE=$NTS

envsubst < data/troute_template.yaml > ./t-route/troute.yaml