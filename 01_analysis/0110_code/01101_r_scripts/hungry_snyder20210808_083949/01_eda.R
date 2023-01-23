library(sf)
library(mapview)

idr = "00_basedata/001_data/hungry_snyder20210808_083949"

shp = file.path(
  idr
  , "hungry_snyder20210808_083949.shp"
) |> 
  st_read(
    quiet = TRUE
  ) |> 
  subset(
    REV %in% 1:5
  )

qnt = shp[[14]] |> 
  quantile(
    probs = seq(0, 1, 0.1)
  )

mapview(
  shp[14]
  , col.regions = viridis::inferno(
    length(qnt)
  )
  , at = qnt
)
