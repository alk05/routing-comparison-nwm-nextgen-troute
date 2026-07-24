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
# Usage:
#   bash preprocess_data.sh --START_TIME 202607231200 --FORECAST_TYPE 1
#   docker run --rm -v
#       "/path/to/dir:/routing-comparison-nwm-nextgen-troute/t-route"
#       --env START_TIME=202607231200 --env FORECAST_TYPE=1
#       preprocessor-image
# =============================================================================

# Argument parser
# Default values
START_TIME=""
FORECAST_TYPE=""

# Valid options
VALID_FORECAST_TYPES="1 2 3 4 11"

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
        --help)
            echo "Usage: $0 --START_TIME <YYYYMMDDHHmm> --FORECAST_TYPE <1|2|3|4|11>"
            echo ""
            echo "Arguments:"
            echo "  --START_TIME      Start time in YYYYMMDDHHmm format (required)"
            echo "  --FORECAST_TYPE   Forecast type: 1, 2, 3, 4, or 11 (required)"
            echo ""
            echo "Example: $0 --START_TIME 202607031100 --FORECAST_TYPE 1"
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

# If we get here, all arguments are valid
echo "START_TIME: $START_TIME"
echo "FORECAST_TYPE: $FORECAST_TYPE"

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
mv ./t-route/restart/*.nc ./t-route/restart/analysis_assim.nc