# Streamflow Routing Comparison: NWM, NextGen Routing-Only Datastream, and Locally-Executed T-Route
This repository documents the process to align standalone t-route simulations with the National Water Model. A comparison is made between the outputs from the NWM, NextGen Routing-Only Datastream, and a standalone local execution of T-Route forced with NWM. All outputs are validated against observed USGS gage data, with the goal is to exactly (or nearly exactly) match the NWM output. 

## Table of Contents
- [Installation](#install)
- [T-Route Outputs](#t-route-outputs)
  - [Mask File](#mask-file)
  - [RouteLink File](#routelink-file)
  - [Forcing Files](#forcing-files)
  - [Restart Files](#restart-files)
  - [Running T-Route](#running-t-route)
- [Gage Outputs](#usgs-gage-outputs)
- [NextGen Routing-Only Datastream Outputs](#nextgen-routing-only-datastream-outputs)
- [Visualizing the Outputs](#visualizing-the-outputs)

# T-Route Outputs 
This section walks through the steps of executing a standalone T-Route simulation, using the NWM framework. 

## Install
Follow [install instructions](https://github.com/CIROH-UA/t-route), and within a copy of the Lower Colorado example folder, make a copy of the test_Ana_V4_NHD.yaml file to edit.

## Mask File 
To create the mask file, run the following [notebook](https://github.com/jameshalgren/troute-network-analysis/blob/main/notebooks/Subnetwork_Extraction_andMask_Demo.ipynb) for each location of interest, to get a list of upstream reach IDs. Combine the outputs from each location into a single text file and move it to the “domain” folder. In the case of the mask file found in this repository, there are around 2,000 reachs IDs collectively corresponding to the Mulberry Creek, Walnut Creek, and Cahaba River locations.

Reference the file under `mask_file_path` in the .yaml file (Example: `mask_file_path: domain/specific_AL_sites.txt`).

## RouteLink File 
Download [NWM parameter files](https://water.noaa.gov/about/nwm), found in the webpage section "Parameter Files". Open file folder, and move RouteLink_CONUS.nc to the “domain” folder. 

Within the .yaml file, replace each instance of RouteLink.nc with the new route link file. 

## Forcing Files 
In the [NWM Google Bucket](https://console.cloud.google.com/storage/browser/national-water-model;tab=objects?hl=en&prefix=&forceOnObjectsSortingFiltering=false), select a day, short_range, and then download the 18 channel_rt files that correspond to the desired hour. The numbers following the "t" indicate the hour. (In the repository, Files/short_range contains files for June 19th, 2026 hour 04). 

For T-Route to successfully run, these files need to be renamed in the format "YYYYMMDDHHMM.CHRTOUT_DOMAIN1". For example:
New File Name | Original File Name
---|---
202604300000.CHRTOUT_DOMAIN1 | nwm.t00z.short_range.channel_rt.f001.conus.nc 
202604300100.CHRTOUT_DOMAIN1 | nwm.t00z.short_range.channel_rt.f002.conus.nc
202606190400.CHRTOUT_DOMAIN1 | nwm.t04z.short_range.channel_rt.f001.conus.nc 
202606190500.CHRTOUT_DOMAIN1 | nwm.t04z.short_range.channel_rt.f002.conus.nc

Technically, the f001 files correspond to an hour after the initial time, (for t0z, the f001 refers to 01:00, not 00:00 like how it is renamed). However, NWM and t-route models have differences in what an hour's output refers to. For one, it refers to the previous hour, while the other is that of the upcoming hour. Following the naming convention above ensures that the models align.

Move these files to the “channel_forcing” folder. 

## Restart files 
Return to the [Google Bucket](https://console.cloud.google.com/storage/browser/national-water-model;tab=objects?hl=en&prefix=&forceOnObjectsSortingFiltering=false), this time choosing analysis_assim. Download the channel_rt.tm00 for the chosen hour. 

This file doesn’t have the variables required for t-route (qlink, hlink, etc.). Use `restart.ipynb`, based on the following [code](https://github.com/CIROH-UA/forcingprocessor/blob/main/src/forcingprocessor/troute_restart_tools.py) to get a working restart file. Additional files required to run the code include the RouteLink file, and the nwm_to_nextgen_map.json file (NextGen AWS under [mappings](https://datastream.ciroh.org/index.html#mappings/)). 

Save the final restart file in the “restart” folder and reference it in the .yaml, making sure that the line isn't commented out (`wrf_hydro_channel_restart_file : restart/troute_restart.nc`) 

After that line, add the following: 

```yaml
wrf_hydro_channel_ID_crosswalk_file_field_name : link 

wrf_hydro_channel_restart_upstream_flow_field_name : qlink1 

wrf_hydro_channel_restart_downstream_flow_field_name : qlink2 

wrf_hydro_channel_restart_depth_flow_field_name : hlink
```

Additionally, in nhd_io.py, the function `get_channel_restart_from_wrf_hydro` originally required the restart file to have channel IDs in the same order as in the crosswalk_file, but was rewritten to remove that requirement. The code is found in the repository under 'get_channel)restart_from_wrf_hydro'.

## Running T-Route
Change the `start_datetime` to the desired time. 

Set `nts : 216`, to correspond with an 18 hour runtime. 

Call the program, `python3 -m nwm_routing -f -V4 <filename>.yaml`.

T-route outputs data for every five minutes of the 18 hours runtime, starting 5 minutes after the start_datetime. (Example output found in repository with file name "flowveldepth_2026-07-01T13:05:35.034852.parquet")

# USGS Gage Outputs 
To be able to evaluate models against real values, find the monitoring location page for the [gage(s)](https://waterdata.usgs.gov/explore/#dataCollections=continuous&mapCenter=33.25700003497726,-86.64346089407479&mapZoomLevel=7) of interest. Change time span, and data type to discharge, before downloading "continuous data" (Example files found in the repository). 

# NextGen Routing-Only Datastream Outputs 
Download the output files using one of the following methods:
* Via the [datastream viewer](https://communityhydrofabric.s3.us-east-1.amazonaws.com/datastream_viewer.html?bucket=ciroh-community-ngen-datastream&path=outputs%2Frouting_only%2Fv2.2_hydrofabric%2F)
  * Example path: `ciroh-community-ngen-datastream/outputs/routing_only/v2.2_hydrofabric/ngen.20260430/short_range/00/VPU_03W`
* Via the [CIROH AWS](https://datastream.ciroh.org/index.html#outputs/routing_only/v2.2_hydrofabric/)
  * Example path: `ciroh-community-ngen-datastream/outputs/routing_only/v2.2_hydrofabric/ngen.20260430/short_range/00/VPU_03W/ngen-run/outputs/troute`

# Visualizing the Outputs 
The `visualizing_outputs.ipynb` notebook compiles all the outputs from the different sources (NWM, t-route, next-gen routing-only, and gage data) and plots them for a given NextGen ID, as well as producing a table of values. The notebook requires the user to know the NextGen ID for the location of interest, which can be looked up [here](https://nrds.ciroh.org/).

To run the notebook, update the file paths for all the files that were downloaded. The NWM output files are the same files that are used as the channel forcing files, but the way the code is written uses the file names before they were changed to the *CHRTOUT_DOMAIN1 version.

For the gage data, two more changes are needed. Adjust the start and end dates at the bottom of the `get_comparison_data` function, and in the function `show_combined_info`, edit the NextGen IDs associated with each gage.

NextGen IDs correspond to multiple NWM streamreaches. Many of these NWM IDs are tributaries to the main branch of the creek or river, and they are unaffected by the precipitation that happened upstream from the main branch. As a result, they show essentially no response during a rainfall event; their flowrate is basically zero. The code has a `zero_tolerance` that can be set to filter out these IDs. The code also plots an average of the remaining NWM IDs. 
