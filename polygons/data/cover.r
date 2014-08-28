cover= function(x,area="all", wd="C:/Rsaves/maps"){
  require(PBSmapping)

  borders= read.csv(file=file.path(wd,"areaborders.csv"), head=T, sep=",")
  b=borders[which(borders$area==area),]

# read in shapefiles
#--------------------------------------
  land= importShapefile(file.path(wd,"landmass_region"))
  coast=importShapefile(file.path(wd,"coastline_polyline"))


#Overlay land and coastline such that any bad data (on land) is hidden
  addPolys(land, col="khaki", border="khaki")
  addLines(coast, col="black")
  abline(h=b$slat, lwd=3)
  abline(h=b$nlat, lwd=3)
  abline(v=-b$wlon, lwd=3)
  abline(v=-b$elon, lwd=3)

}
