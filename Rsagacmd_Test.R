# Author: Andrew Paolucci
# Title: Investigate SAGA tools in R studio and get 5 derivatives from DEM 

# List derivatives of interest 
# Flow Direction
# Flow Accumulation
# Stream Power Index
# Slope
# LS Factor 

# set up environmental variables to include QGIS folder C:\Program Files\QGIS 3.26.1\bin\

# load libraries 
library(Rsagacmd)
library(terra)


# setwd
setwd('C:/geodata/projectdata/')
#### get and investigate saga tools ####
# Specify file path where saga_cmd.exe resides 

file.path <- "C:/Program Files/QGIS 3.26.1/apps/saga/saga_cmd.exe"

# get saga .Can also specify cores, all_outputs, and grid caching 
saga <-saga_gis(file.path, raster_backend = "terra")

# list available saga commands 
search_tools(saga, "sinks")
print(tidy(saga$ta_morphometry), n=50)

# look up documentation for tool
saga_docs(saga$ta_hydrology$flow_accumulation_top_down)

#### Get DEM Data ####
# Generate random terrain and save to temp file
dem <- saga$grid_calculus$random_terrain(target_out_grid = tempfile(fileext = ".sgrd"))

#### Flow Direction #### 
  # only need to specify dem. Optional minimum Slope input. set to the min to 0 then water will pond. default is 0.1
  fill.sinks <- saga$ta_preprocessor$fill_sinks_wang_liu(dem)
  # subset flow raster 
  flow.direction <-fill.sinks$fdir
  saga_remove_tmpfiles(h = 0)
  
#### Flow Accumulation ####
  # one step method
  flow.acc.os <- saga$terrain_analysis$flow_accumulation_one_step(dem)
  # subset total catchment area
  tca <- flow.acc.os$tca
  # subset specific catchment area 
  sca <- flow.acc.os$sca
  saga_remove_tmpfiles(h=0)
  # top down method. Needs other specifications "Accumulation Target"
  #flow.acc.td <- saga$ta_hydrology$flow_accumulation_top_down(ELEVATION=dem, ACCU_TARGET='?')
  
#### Stream Power Index ####
  # need to specify slope and total catchment area (tca). Assumed degrees for slope 
    # run slope, aspect, curvature. Default slope method is: 9 parameter 2nd order polynom (Zevenbergen & Thorne 1987). Slope has         options for other units
      print(saga$ta_morphometry$slope_aspect_curvature)
      slope.aspect.curvature <- saga$ta_morphometry$slope_aspect_curvature(dem)
      # subset slope raster 
      slope.deg <- slope.aspect.curvature$slope
      saga_remove_tmpfiles(h=0)
  # calculate index 
  stream.power.idx <- saga$ta_hydrology$stream_power_index(slope=slope.deg, area=tca)


#### LS-Slope Length ####
  # ls factor one step method
  #ls.factor.os <-saga$terrain_analysis$ls_factor_one_step(dem)
  # ls factor 
  ls.factor <- saga$ta_hydrology$ls_factor(slope=slope.deg, area=sca)

# stack rasters  
final.output <- rast(list(dem, flow.direction, tca, slope.deg, stream.power.idx, ls.factor))

# change names 
names(final.output) <- c("elevation","flow.direction","flow.accumulation","slope.degrees","stream.power.index","ls.factor")
plot(final.output)

# remove temp files 
saga_remove_tmpfiles(h = 0)

#writeRaster. Specify file path 
terra::writeRaster(final.output, "./test3.tif")

#
# TO DO: How to nest tools using pips. Careful of output dependecies 
#master.raster <- dem %>% 
    # Flow Direction: input DEM output flow direction %>%
    # Flow Accumulation: input DEm output sca and tca %>%
    # Slope: input dem: output slope, aspect, curvature %>%
    # Stream power: input slope and tca output stream power index %>%
    # ls factor: input dem and sca output output ls factor


