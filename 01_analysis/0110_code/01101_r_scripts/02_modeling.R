library(sf)
library(raster)
library(randomForest)

training_data = st_read(
  "00_basedata/001_data/training_data/training_data.shp"
  , quiet = TRUE
)[1:2, ]


### . true-color images ----

## list files
rgbs = list.files(
  "01_analysis/0101_data/sentinel-2/RGB432B"
  , pattern = "Hesselbach.*.tif$"
  , full.names = TRUE
)

## order by date
dates = sapply(
  strsplit(
    basename(rgbs)
    , "_"
  )
  , "[["
  , 2
)

rgbs = rgbs[order(dates)]
dates = dates[order(dates)]

## rasterize
rasters = lapply(
  rgbs
  , brick
)

plotRGB(rasters[[73]])
plot(st_transform(training_data, crs = 32632), add = TRUE, border = "white", col = "transparent")


### . modeling ----

## bottom-of-atmosphere reflectances
boa = list.files(
  "01_analysis/0101_data/sentinel-2/BOA"
  , pattern = paste(dates[73], "Hesselbach", ".tif$", sep = ".*")
  , full.names = TRUE
)

boa = brick(boa)

## ndvi
ndvi = list.files(
  "01_analysis/0101_data/sentinel-2/NDVI"
  , pattern = paste(dates[73], "Hesselbach", ".tif$", sep = ".*")
  , full.names = TRUE
)

ndvi = raster(ndvi)

# spplot(
#   ndvi
#   , col.regions = colorRampPalette(RColorBrewer::brewer.pal(9, "BrBG"))(100)
#   , at = seq(5500, 9500, 100)
# ) + latticeExtra::layer(
#   sp.polygons(as(st_transform(training_data, crs = 32632), "Spatial"))
# )

## extract training data
dat = extract(
  stack(boa, ndvi)
  , training_data
  , df = TRUE
  , cellnumbers = TRUE
)

set.seed(1899)
ids = sample(
  which(dat$ID == 2)
  , sum(dat$ID == 1)
)

trn = dat[c(1:9, ids), -2]

## fit model
mod = randomForest(
  as.factor(ID) ~ .
  , data = trn
)

prd = predict(mod, newdata = dat)

##
out = ndvi
out[] = NA
out[dat$cell] = prd

spplot(
  out
  , scales = list(draw = TRUE)
  , col.regions = RColorBrewer::brewer.pal(3, "BrBG")
  , at = seq(.5, 2.5, 1)
) + latticeExtra::layer(
    sp.polygons(as(st_transform(training_data, crs = 32632), "Spatial"))
  )
