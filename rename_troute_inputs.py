"""
Renames downloaded operational NWM channel routing forecast data to a name compatible with
t-route
"""

import re
from pathlib import Path
from datetime import datetime, timedelta
import argparse
import sys

def _parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--start_date",
        type= lambda s: (
            datetime.strptime(s, "%Y%m%d%H%M")
        ),
        help="The start date and time of the data to be collected, in YYYYmmddHHMM"
    )
    parser.add_argument(
        "--directory",
        type=Path,
        help="Path to the directory that contains the files to be renamed"
    )
    args = parser.parse_args()
    return args

def main():
    """Finds downloaded NWM files and renames them to a format used by t-route"""
    args = _parse_arguments()

    start_dt = args.start_date

    # Find all matching NWM files
    channel_forcing_dir = args.directory
    pattern = "nwm.t*.short_range.channel_rt.f*.conus.nc"
    files = sorted(channel_forcing_dir.glob(pattern))

    if not files:
        print(f"No files matching pattern '{pattern}' found")
        sys.exit()

    for file in files:
        # Extract f-value using regex
        match = re.search(r"\.f(\d+)\.", file.name)
        if not match:
            print(f"Could not extract f-value from {file.name}, skipping")
            continue

        f_value = int(match.group(1))

        # Calculate hours ahead: f_value - 1
        # Technically, the f001 files correspond to an hour after the initial time, (for t0z, the
        # f001 refers to 01:00, not 00:00 like how it is renamed). However, NWM and t-route models
        # have differences in what an hour's output refers to. For one, it refers to the previous
        # hour, while the other is that of the upcoming hour. Following this naming convention
        # ensures that the models align.
        hours_ahead = f_value - 1

        # Add hours to start time
        new_dt = start_dt + timedelta(hours=hours_ahead)

        # Format new filename
        new_filename = f"{new_dt.strftime('%Y%m%d%H%M')}.CHRTOUT_DOMAIN1"
        new_path = file.parent / new_filename

        # Rename file
        file.rename(new_path)
        print(f"Renamed: {file.name} → {new_filename}")

    print("Done!")

if __name__ == "__main__":
    main()
