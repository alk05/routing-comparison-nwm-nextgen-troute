"""
Uses nwmurl to fetch operational forecast and analysis/assimilation data.

Usage: python fetch_nwm_data.py --start_date YYYYmmddHHMM --runinput [1,2,3,4,5,6,7,8,9,10,11]

These arguments are nwmurl arguments. The runinput is defined like this:
1: short-range forecast
2: medium-range forecast
3: medium-range forecast, no data assimilation
4: long-range forecast
5: analysis-assimilation
6: extended analysis-assimilation
7: extended analysis-assimilation, no data assimilation
8: long analysis-assimilation
9: long analysis-assimilation, no data assimilation
10: analysis-assimilation, no data assimilation
11: short-range forecast, no data assimilation
"""

import argparse
from datetime import datetime
import nwmurl

def _parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--start_date",
        type= lambda s: (
            datetime.strptime(s, "%Y%m%d%H%M")
        ),
        help="The start date and time of the data to be collected, in YYYYmmddHHMM"
    )

    # A quick design note: as of the writing of this module, we will only use runinputs 1 and 5.
    # But I have included functionality to support all of the other run configurations, in the
    # spirit of the NRDS. The other AA runs may not be necessary though.
    # TODO: confirm design choice

    parser.add_argument(
        "--runinput",
        type=int,
        help="Represents NWM run configuration. See github.com/CIROH-UA/nwmurl for more details",
        choices=[1,2,3,4,5,6,7,8,9,10,11]
    )

    args = parser.parse_args()
    return args

def main():
    """
    Given the arguments start_date and runinput, build a nwmurl configuration and call nwmurl.

    Hardcoded assumptions:
    Only fetches one NWM run.
    Only fetches channel routing data.
    Only fetches CONUS data.
    Fetches data from Google Cloud Storage.
    Only fetches ensemble member 0 (only relevant for medium-range forecasts)
    """
    args = _parse_arguments()

    start_date = args.start_date
    end_date = start_date # this only fetches one NWM run
    fcst_cycle = [0]

    runinput = args.runinput

    if runinput in {1, 11}: # short-range forecast
        dt = 1
        num_hrs = 18
    elif runinput in {2, 3}: # medium-range forecast
        dt = 1
        num_hrs = 240
    elif runinput in {4}: # long-range forecast
        dt = 1
        num_hrs = 720
    elif runinput in {5, 10}: # analysis-assimilation
        dt = 0
        num_hrs = 1 # A design choice: These runs are 3 hours long, but we only really use them for
        # generating restarts. So we could get it to default to num_hrs = 1?
    elif runinput in {6, 7}: # extended analysis-assimilation
        dt = 0
        num_hrs = 28
    elif runinput in {8, 9}: # long-range analysis-assimilation
        dt = 0
        num_hrs = 12

    lead_time = [x+dt for x in range(num_hrs)]

    varinput = 1 # channel routing
    geoinput = 1 # CONUS
    urlbaseinput = 3 # GCS
    meminput = 0 # ensemble member
    write_to_file = True

    nwmurl.generate_urls_operational(
        start_date,
        end_date,
        fcst_cycle,
        lead_time,
        varinput,
        geoinput,
        runinput,
        urlbaseinput,
        meminput,
        write_to_file
    )

if __name__ == "__main__":
    main()
