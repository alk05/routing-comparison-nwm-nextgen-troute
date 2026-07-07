# README 
This repository is a documentation of _______ ... getting t-route outputs to match the National Water Model, while also comparing it to next-gen routing-only datastream and USGS gage outputs, in the hopes of eventually improving the routing-only outputs to be better than the NWM.

# T-route Outputs 
Running t-route on NWM framework, etc., to get outputs that match (or at least are very similar to) NWM outputs.

## Installation 
Follow [install instructions](https://github.com/CIROH-UA/t-route), and within a copy of the Lower Colorado example folder, make a copy of the test_Ana_V4_NHD.yaml file to edit.

## Mask File 
To create the mask file, run the following [notebook](https://github.com/jameshalgren/troute-network-analysis/blob/main/notebooks/Subnetwork_Extraction_andMask_Demo.ipynb) for each location of interest, to get a list of upstream reach IDs. Combine the outputs from each location into a single text file and move it to the “domain” folder. In the case of the mask file found in this repository, there are collectively around 2,000 reachs IDs corresponding to the Mulberry Creek, Walnut Creek, and Cahaba River locations.

Reference the file under `mask_file_path` in the .yaml file (Example: `mask_file_path: domain/specific_AL_sites.txt`).

## RouteLink File 
Download [NWM parameter files](https://water.noaa.gov/about/nwm) (Under the section “Parameters Files” near the bottom of the webpage). 

Open file folder, and get RouteLink_CONUS.nc and move it to the “domain” folder. 

Within the .yaml file replace each instance of RouteLink.nc with the new route link file. 

## Forcing Files 
In the [NWM Google Bucket](https://console.cloud.google.com/storage/browser/national-water-model;tab=objects?hl=en&prefix=&forceOnObjectsSortingFiltering=false), select day of interest, short_range, and then download the 18 channel_rt files that correspond to your chosen hour. The numbers following the "t" indicate the hour. (Files/short_range contains files for June 19th, 2026 hour 04). 

In order for T-Route to successful run, these files need to be renamed in the format "YYYYMMDDHHMM.CHRTOUT_DOMAIN1". For example:
New File Name | Original File Name
---|---
202604300000.CHRTOUT_DOMAIN | nwm.t00z.short_range.channel_rt.f001.conus.nc 
202604300100.CHRTOUT_DOMAIN | nwm.t00z.short_range.channel_rt.f002.conus.nc
202606190400.CHRTOUT_DOMAIN | nwm.t04z.short_range.channel_rt.f001.conus.nc 
202606190500.CHRTOUT_DOMAIN | nwm.t04z.short_range.channel_rt.f002.conus.nc

Technically, the f001 files correspond to an hour after the initial time, (1 am not, mightnight, or 5 am not 4am, like in the examples). However NWM and t-route have different 'definitions' of what an hour is, for one it means the outputs at the end of the hour, and the other outputs for the coming hour. This slightly ~wrong~ naming convention ensures that the two models align.

Move these files to the “channel_forcing” folder. 

## Restart files 
Returning to the [Google Bucket](https://console.cloud.google.com/storage/browser/national-water-model;tab=objects?hl=en&prefix=&forceOnObjectsSortingFiltering=false) but this time choosing analysis_assim 

Once again we want the channel_rt for chosen hour. However, there are three files to choose from: tm00, tm01, and tm02. Choose the tm00 

The file doesn’t have the variables that t-route wants (qlink, hlink, link). Use `restart.ipynb` to get a working restart file. (Based off of the following [code](https://github.com/CIROH-UA/forcingprocessor/blob/main/src/forcingprocessor/troute_restart_tools.py)).

Required files for that to run: 
* The analysis_assim file
* RouteLink file (previously downloaded) 
* nwm_to_nextgen_map.json file (NextGen AWS under [mappings](https://datastream.ciroh.org/index.html#mappings/)) 

Save the final restart file in the “restart” folder and reference it in the .yaml, making sure that the line isn't commented out (`wrf_hydro_channel_restart_file : restart/troute_restart.nc`) 

After that line, add the following: 

```
wrf_hydro_channel_ID_crosswalk_file_field_name : link 

wrf_hydro_channel_restart_upstream_flow_field_name : qlink1 

wrf_hydro_channel_restart_downstream_flow_field_name : qlink2 

wrf_hydro_channel_restart_depth_flow_field_name : hlink
```

Also of note, in nhd_io.py, the function `get_channel_restart_from_wrf_hydro` was rewritten to remove the dependency of the restart file containing channel IDs in the same order of the crosswalk_file.

## Running T-Route
Change the `start_datetime` to the desired time. 

Change `nts` to “216”, to correspond with an 18 hour runtime. 

In the terminal, within the virtual environment, to the folder that you made at the beginning (`~git/t-route/test/Alabamatest`), call the program, `python3 -m nwm_routing -f -V4 <filename>.yaml`.

T-route outputs data for every five minutes of the 18 hours runtime, starting 5 minutes after the start_datetime. (Example output found in repository with file name "flowveldepth_2026-07-01T13:05:35.034852.parquet")

# USGS Gage Outputs 
(So as to compare model outputs with actual values). 

Find the monitoring location page for the [gage(s)](https://waterdata.usgs.gov/explore/#dataCollections=continuous&mapCenter=33.25700003497726,-86.64346089407479&mapZoomLevel=7) of interest. Change time span, and data type to discharge, before downloading "continuous data" (Example files found in the repository). 

# NextGen Routing-Only Datastream Outputs 
Download output file via the [datastream viewer](https://communityhydrofabric.s3.us-east-1.amazonaws.com/datastream_viewer.html?bucket=ciroh-community-ngen-datastream&path=outputs%2Frouting_only%2Fv2.2_hydrofabric%2F) (Example path: `ciroh-community-ngen-datastream/outputs/routing_only/v2.2_hydrofabric/ngen.20260430/short_range/00/VPU_03W`) 

Alternatively, download via the [CIROH AWS](https://datastream.ciroh.org/index.html#outputs/routing_only/v2.2_hydrofabric/) (Example path: `ciroh-community-ngen-datastream/outputs/routing_only/v2.2_hydrofabric/ngen.20260430/short_range/00/VPU_03W/ngen-run/outputs/troute`)

# Visualizing the Outputs 
The `visualizing_outputs.ipynb` code compiles all the outputs from the different sources (NWM, t-route, next-gen routing-only, and gage data) and plots them for a given NextGen ID, as well as getting a table. Requires user to know the NextGen ID at locations of interest ([NextGen Map](https://nrds.ciroh.org/)).

NextGen IDs correspond to multiple NWM streamreaches. Many of these NWM IDs are tributaries to the main branch of the creek or river, and they are unaffected by the precipitation that happened upstream from the main branch. As a result, they show essentially no response during the event; their flowrate is basically zero. The code has a lower threshold can be set to filter out these negligible IDs. Additionally, the code also plots an average of the remaining NWM IDs to help ~see what’s actually going on. 

Update the filepathways for all the files that were downloaded.  

The NWM output files are the same files that are used as the channel forcing files, but the way the code is written reflects the files before the file names were changed to the *CHRTOUT_DOMAIN1 version.

For the gage data, two more changes are needed. Adjust the start and end dates at the bottom of the `get_comparison_data` function. Additionally, in the function `show_combined_info`, edit the NextGen IDs associated with each gage. 
