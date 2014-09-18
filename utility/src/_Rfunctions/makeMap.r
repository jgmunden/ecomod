#----------------------------------------------------
# generate map using PBSmapping plotting functions
#----------------------------------------------------
wd = file.path(project.directory('polygons'),'data')
makeMap= function(x,xlim=c(-67,-57), ylim=c(42,47.5), addCrabLabels=T, title="", area='ALL',addEmera=F,addStAnns=F,addGully=F, 
addSurvey=F,addFisheryFootprint=F,main=""){
  require(PBSmapping)
  require("raster")
	require("geosphere")

wd <- file.path(project.directory('polygons'),'data')
##from Ben June 14, 2013 08:15:00 PM 
##couple of mods by Adam June 14, 2013 01:21:02 PM 
## area one of c('NENS','SENS','4X','23','24')
  
# read in shapefiles
#--------------------------------------
  basemap= importShapefile(file.path(wd,"map_base_region"))
  dm200= importShapefile(file.path(wd,"dm200_region"))
  dm100= importShapefile(file.path(wd,"dm100_region"))
  zones= importShapefile(file.path(wd,"sczones2010_polyline"))
  land= importShapefile(file.path(wd,"landmass_region"))
  coast=importShapefile(file.path(wd,"coastline_polyline"))
  axis=importShapefile(file.path(wd,"axis_polyline"))

# Provide projection information
#---------------------------------
  proj.abbr=attr(basemap, "projection") # abbreviated projection info
  proj.full=attr(basemap, "prj") # full projection info

  if(area=='NENS') 			{ xlim=c(-61,-58.2); ylim=c(45.9,47.5) }
  if(area=='SENS') 			{ xlim=c(-63.5,-57); ylim=c(42.5,46.1)   }
  if(area=='4X')   			{ xlim=c(-67,-63.1); ylim=c(42.5,45)     }
  if(area=='23')   			{ xlim=c(-60.5,-57); ylim=c(43,46.2)   }
  if(area=='24')   			{ xlim=c(-63.5,-59); ylim=c(42.5,45.5)   }
  if(area=='not4X')   		{ xlim=c(-63.5,-57); ylim=c(42.5,47.5)   }
  
   
  
   plotPolys(basemap, projection=proj.abbr, col="royalblue2", border="black",
   font.lab=1,  xlab="Longitude", ylab="Latitude", axes=T, tck=-.01,
   tckLab=TRUE, ylim=ylim, xlim=xlim,main=main)
     
  title(main=title, line=1, cex.main = .7)
  addPolys(dm200, col="steelblue2", border="steelblue2")
  addPolys(dm100, col="lightblue1", border="lightblue1")

  

  
#Overlay land and coastline such that any bad data (on land) is hidden
  addPolys(land, col="khaki", border="khaki")
  addLines(coast, col="black")
  box()

#function to add area labels
#--------------------------------------------
  if (addCrabLabels) {
    text("CFA 23", x=-58.05, y=44.55, font=2, cex=1.0)
    text("CFA 24", x=-60.9, y=43.75, font=2, cex=1.0)
    text("CFA 4X", x=-64.2, y=43.25, font=2, cex=1.0)
    text("N-ENS", x= -59.15, y=46.65, font=2, cex=1.0)
      addLines(zones, col="darkgoldenrod1", lwd=2)
  }
#add in shrimp

  

if(addStAnns) {
	sta <- read.csv(file.path(wd,'StAnnsMPA.csv'))
	 rc = col2rgb("red")
	addPolys(sta[sta$PID==1,],col=	rgb(rc[1]/255, rc[2]/255, rc[3]/255, .3) , border = "black")
} 

if(addSurvey) { 
	surveydata <- read.csv(file.path(wd,'surveypoints.csv'))
  surveydata = surveydata[-which(is.na(surveydata$Station)),]
  names(surveydata) = c("PID", "Y", "X", "Y2", "X2", "ID", "col" )
  surveydata$col[which(surveydata$col == 1)] = "green"
  surveydata$col[which(surveydata$col == 2)] = "yellow"
  surveydata$col[which(surveydata$col == 3)] = "red"
  
  surveydata$X = surveydata$X*-1
  surveydata$X2 = surveydata$X2*-1
  
  ind = which(surveydata$X < min(xlim) )

  if(length(ind)>0) surveydata = surveydata[-ind,]
  
  ind = which(surveydata$X > max(xlim)) 

  if(length(ind)>0) surveydata = surveydata[-ind,]
  
  ind = which(surveydata$Y > max(ylim))

  if(length(ind)>0) surveydata = surveydata[-ind,]
  
  ind = which(surveydata$Y < min(ylim) )

  if(length(ind)>0) surveydata = surveydata[-ind,]
  sd = as.PolyData(data.frame(surveydata), projection = "LL")
  addPoints(sd,col=sd$col,pch=16,cex=0.8)
	} 

if(addGully) {
  x = NULL
  # <name>GULLY</name>
  x$X = c(-59.1, -58.5833333, -58.5833333, -59.1333333, -59.1333333, -59.3333333)
  x$Y = c(44.2166667, 43.7833333, 43.5833333, 43.5833333, 43.9166667, 44.1)
  x$PID = c(1, 1,1,1,1,1)
  x$POS = c(1, 2,3,4,5,6)
  x = as.PolySet(data.frame(x), projection = "LL")
  rc = col2rgb("red")
  addPolys(x, col = rgb(rc[1]/255, rc[2]/255, rc[3]/255, .3) , border = "black")
  }

if(addFisheryFootprint){

n=7
	ff=importShapefile(file.path(wd,"fisheryfootprint","crq0610_weight_2minGrid.shp"))
	cols 			<- colorRampPalette(c("darkblue","cyan","green", "yellow", "orange","darkred", "black"), space = "Lab")
	fp <- attr(ff,'PolyData')[,c('PID','ZDENSITY','CLASS','GMEAN')]
	fp$Z <- log(fp$ZDENSITY+1)
	trim <- quantile(fp$Z,c(0.005,0.995)) 
	fp <- fp[fp$Z>trim[1] & fp$Z<trim[2],]
	br <- seq(min(fp$Z),max(fp$Z),length.out=n)
	a <- col2rgb(cols(n))/255
	coll <- apply(a,2,function(x) rgb(blue=x[3],green=x[2],red=x[1],0.9))
	fp <- makeProps(fp,breaks=br,propName='col',propVals=coll)
	addPolys(ff,polyProps=fp)
	}
	 if(addEmera) {
	emera=importShapefile(file.path(wd,"Emera Line","ENL_SubseaCable_2km_StudyArea.shp"))
	addPolys(emera,col='red',lwd=2)
}

addPolys(land,col='khaki',border='khaki')
addLines(coast,col='black')
box()
}

addVMSTrack <- function(dat) {
 	#dat from getVMS.R
 	#AMCook June 14, 2013 01:59:26 PM 
 	names(dat)[3:4] <-  c('X','Y')
 	tr <- unique(dat$trip_id) 
 	vr <- data.frame(vrn=unique(dat$vrn),col=1:length(unique(dat$vrn)))
 	  for(i in 1:length(tr)) {
  		db <- dat[dat$trip_id==tr[i],]
  		db$PID <- i
  		db$POS <- 1:nrow(db)
  		attr(db,'projection') <- "LL"
  		addLines(db,col=vr[vr$vrn==unique(db$vrn),2])
          }
       }

       
  
