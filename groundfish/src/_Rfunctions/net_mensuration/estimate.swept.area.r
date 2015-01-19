estimate.swept.area = function( gsi=NULL, x=NULL, getnames=FALSE  ){

  if (getnames) return( c("names, of variables") )
  
  n.req = 30

  gsi$sweptarea.mean = NA
  gsi$depth.mean = NA
  gsi$depth.sd = NA
  gsi$wingspread.mean = NA
  gsi$wingspread.sd = NA
  
if (FALSE){
 
u=which(modern.data$id== "NED2009027.108")
t0 = 500
t1 = 41500


}



  x = x[order( x$timestamp ) ,]
  
  ##--------------------------------
  # timestamps have frequencies higher than 1 sec .. duplciates are created and this can pose a problem
  x$ts = as.numeric(x$timestamp)  # in seconds 
  x$ts = x$ts - min(x$ts) 
  
  bc = which( x$timestamp >=gsi$bc0.datetime & x$timestamp <= gsi$bc1.datetime ) 
  i0 = min(bc)
  i1 = max(bc)
  
  if (debug) {
    plot (latitude~longitude, data=x, pch=20, cex=.1)
    points(latitude~longitude, data=x[bc,], pch=20, cex=.1, col="orange")
  }

  nupos = sqrt( length( unique( x$longitude)) ^2  + length(unique(x$latitude))^2)
  if (nupos < 30) { 
    method = "interpolated.using.velocity" # older data
  } else {
    method = "direct"  # higher resolution GPS data
  }
  
  if (method=="interpolated.using.velocity") {
    ## obtain ship velocity 
    # estim distance from vel * duration
    # incremental distance from incremental time
    # integrate
	loadfunctions( "groundfish")
	
	gsinf = groundfish.db( DS="gsinf.odbc" ) # loading raw data from Oracle data dump
	 # fix lon/lat
	  gsinf$lat = gsinf$slat/100
      gsinf$lon = gsinf$slong/100
      if (mean(gsinf$lon,na.rm=T) >0 ) gsinf$lon = - gsinf$lon  # make sure form is correct
      gsinf = convert.degmin2degdec(gsinf)
      
	  
	  gsinf$cftow = 1.75/gsinf$dist  # not used
      ft2m = 0.3048
      m2km = 1/1000
      nmi2mi = 1.1507794
      mi2ft = 5280
      gsinf$sakm2 = (41 * ft2m * m2km ) * ( gsinf$dist * nmi2mi * mi2ft * ft2m * m2km )  # surface area sampled in km^2
	
  }

  
  if (method=="direct") {
    # use direct GPS position to estimate diff in 
    # incremental distance from incremental time
    # integrate
    # but first filter data
  }


  dh =  rep(0, end-1)
  for( ii in 1:(end-1) ) dh[ii] = geodist( point=x[ii,pos], locations=x[ii+1,pos], method="vincenty" ) # km .. slower but high res
  hDist = c( 0, cumsum( dh ) ) 
  
  dv =  rep(0, end-1)
  dv = abs( diff( N$depth ) ) / 1000   # m to km
  vDist = c( 0, cumsum( dv) ) 

  


  ds = N$doorspread
  ii = which( is.finite( n$doorspread ) )
  if ( length(ii) < n.req ) {
    # estimate from doorspread
    # 
  }

  n$distances = # cumsum used to do piecewise integration of distance
      # model/smooth/interpolate the spreads
      n$doorspread.predicted = NA
      ii = which( is.finite( n$doorspread ) )
      if ( length(ii) > n.req ) {
           
      n$doorspread.predicted = approx( x=n$distances, y=n$doorspread, xout=n$distances, method="linear", rule=2 )$y
         
         
       #turned off gam model in December 20, 2013 giving unrealistic values for spread as the new esnoar files have 0 and NA whereas older netmind are filled with previous value 
			      	#gam.model = try( gam( doorspread ~ s(distances, k=5, bs="ts"), data=n[ii,], optimizer=c("outer", "nlm")), silent = T )
			        #if ( ! "try-error" %in% class( gam.model )) {
			        #  n$doorspread.predicted = predict( gam.model, newdata=n, newdata.guaranteed=T )
			        #} else {
			        #  n$doorspread.predicted = approx( x=n$distances, y=n$doorspread, xout=n$distances, method="linear", rule=2 )$y
			        #}
      }
      if ( length( which( is.finite( n$doorspread.predicted ) ) ) < 10 ) {
        n$doorspread.predicted = mean( n$doorspread , na.rm=T, trim=0.1 )
      }

      mean.doorspreads = ( n$doorspread.predicted[1:(end-1)] + n$doorspread.predicted[2:(end)] ) / 2 / 1000  # mean between two ends
      partial.area =  delta.distance * mean.doorspreads
      out$surfacearea = sum( partial.area )  # km^2
      out$surfacearea = abs(  out$surfacearea )

      out$spread = mean(n$doorspread.predicted, na.rm=T, trim=0.1)/1000  # in km
     spread_sd = sd(n$doorspread.predicted, na.rm=T )/1000
     if(!is.na(spread_sd) & spread_sd!=0) out$spread_sd = spread_sd #if just using the mean from above do not over write spread_sd
     out$distance=n$distances[end]


  plot ()

  gsi$sweptarea.mean = sweptarea.mean 
  gsi$depth.mean = depth.mean
  gsi$depth.sd = depth.sd
  gsi$wingspread.mean = wingspread.mean
  gsi$wingspread.sd = wingspread.sd
  
  return( gsi)

}


