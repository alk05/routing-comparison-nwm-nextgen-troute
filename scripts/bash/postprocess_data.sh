#!/usr/bin/env bash
# =============================================================================
# postprocess_data.sh
#
# Recast NWM t-route outputs to NextGen catchment resolution.
#
# Usage:
#   bash postprocess_data.sh
# =============================================================================

# Convert NWM t-route outputs into NextGen catchment resolution

NC_NAME=$(ls ./t-route/outputs/troute)
TROUTE_OUTPUT="./t-route/outputs/troute/${NC_NAME}"
python scripts/python/nwm_to_ngen.py \
    --nwm_to_ngen_map data/nwm_to_ngen_map.json \
    --troute_outputs "$TROUTE_OUTPUT"