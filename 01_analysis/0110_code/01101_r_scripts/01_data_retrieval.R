library(sf)
library(mapview)
library(sen2r)

## import training data
# training_data = st_read(
#   "00_basedata/001_data/training_data/Forst.kml"
#   , quiet = TRUE
# )
# 
# training_data$Name = gsub("ä", "ae", training_data$Name)
# 
# st_write(
#   st_zm(training_data) # drop z-dimension
#   , dsn = "00_basedata/001_data/training_data"
#   , layer = "training_data"
#   , driver = "ESRI Shapefile"
# )

training_data = st_read(
  "00_basedata/001_data/training_data/training_data.shp"
  , quiet = TRUE
)

m = mapview(
  training_data
  , color = "lightgrey"
  , alpha.regions = 0
  , map.types = mapviewGetOption("basemaps")[c(4, 1:3, 5)]
  , legend = FALSE
)
m

## check scihub connection
if (check_scihub_connection()) {
  credentials = read_scihub_login()
  if (credentials[1] != "user") {
    write_scihub_login(
      username = "user"
      , password = "user"
    ) # FALSE if not correct
  }
}

#' As indicated on ESA's science toolbox exploitation platform 
#' ([STEP](http://step.esa.int/main/third-party-plugins-2/sen2cor/)), 
#' > "Sen2Cor is a processor for Sentinel-2 Level 2A product generation and 
#' > formatting; it performs the atmospheric, terrain and cirrus correction of 
#' > Top-Of-Atmosphere Level 1C input data. Sen2Cor creates Bottom-Of-Atmosphere, 
#' > optionally terrain and cirrus corrected reflectance images; additional, 
#' > Aerosol Optical Thickness, Water Vapor, Scene Classification Maps and 
#' > Quality Indicators for cloud and snow probabilities.

## list sentinel-2 products available for research area
s2_list(
  spatial_extent = training_data
)

## run .json template with modified settings
sen2r(
  param_list = "01_analysis/0140_misc/s2proc_template.json"
  , timewindow = c(as.Date("2020-06-01"), Sys.Date())
  , mask_type = "cloud_and_shadow"
  # , max_mask = 10
  , list_rgb = "RGB432B"
)

## list and reorder ndvi layers
ndvi = list.files(
  "01_analysis/0101_data/sentinel-2"
  , pattern = "NDVI_\\d{2}.tif$"
  , full.names = TRUE
  , recursive = TRUE
)

dates = regmatches(
  ndvi
  , regexpr(
    "\\d{8}"
    , ndvi
  )
)

ndvi = ndvi[order(dates)]

## import and plot ndvi layers
ndvi = stack(ndvi)

mapview(
  ndvi[[3]]
  , legend = FALSE
  , map.types = mapviewGetOption("basemaps")[c(4, 1:3, 5)]
) + m
