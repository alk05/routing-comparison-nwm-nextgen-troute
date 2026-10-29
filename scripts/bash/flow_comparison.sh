set -eo pipefail

# Directory paths
REPO_DIR="/home/alk05/testing/routing-comparison-nwm-nextgen-troute"
HOST_DATA_DIR="/home/alk05/testing/t-route"
PYTHON_SCRIPT_DIR="${REPO_DIR}/scripts/python"

CONTAINER_REPO_DIR="/routing-comparison-nwm-nextgen-troute"
CONTAINER_DATA_DIR="/t-route"

echo "==> Running Flow Comparison..."
docker run --rm \
  -v "${HOST_DATA_DIR}:${CONTAINER_DATA_DIR}" \
  -v "${REPO_DIR}:${CONTAINER_REPO_DIR}" \
  -v "${PYTHON_SCRIPT_DIR}/flow_comparison.py:/app/flow_comparison.py" \
  -w /app \
  flow-comparison \
  /app/flow_comparison.py \
    --nwm-to-ngen-map "${CONTAINER_REPO_DIR}/data/gage_downstream_nwm_to_ngen_map.json" \
    --channel-forcing-dir "${CONTAINER_DATA_DIR}/channel_forcing" \
    --troute-output-dir "${CONTAINER_DATA_DIR}/outputs/troute" \
    --output-dir "${CONTAINER_DATA_DIR}/outputs/troute" \
    "$@"
