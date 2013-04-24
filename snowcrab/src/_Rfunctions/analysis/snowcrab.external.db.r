
  snowcrab.external.db = function( p=NULL, DS="", vname="" ) {
  
    if ( DS=="det.snowcrab.in.groundfish.survey" ) {
      loadfunctions( "groundfish", functionname="current.year.r" )
      loadfunctions( "groundfish", functionname="load.groundfish.environment.r" )


      ct = groundfish.db( "det" )
      ct = filter.taxa( x=ct, method="snowcrab")
     
      imale = which( ct$sex==1 )
      ifemale = which( ct$sex==2 )
      
      ct$sex = NA 
      ct$sex[ imale ] = male 
      ct$sex[ female ] = female 

      ct$cw = ct$len
      
      ct$mat = NULL  # cannot be determined 
      ct$len =NULL
      ct$spec= NULL
      ct$age =NULL
      ct$fshno = NULL
          
      # only a few types of translations are possible, based upon size classes
      # as there is no chela or abdomen or maturit y information
      # f7, f8, f9, f10, m7, to m13
      vt = vname 
      vt = gsub( "^totno.", "", vt )
      vt = gsub( "^totmass.", "", vt )
      vt = gsub( ".no$", "", vt )
      vt = gsub( ".mass$", "", vt )
      
      if ( vt %in% c("R0", "m.com"  ) ) {
        vi = which( ct$sex==male & ct$cw>=95 & ct$cw<200  ) 
      } else {
        vi = filter.class( ct, vt ) 
      }

      ct = ct[ vi, ]

      return(ct)
    }
  
    if ( DS %in% c("set.snowcrab.in.groundfish.survey", "set.snowcrab.in.groundfish.survey.redo"  ) ) {

      fn = file.path( project.directory("snowcrab"), "R", paste("set.groundfish", vname, "rdata", sep=".") )

      set = NULL
      if ( DS=="set.snowcrab.in.groundfish.survey" ) {
        if ( file.exists( fn) )  load( fn )
        return (set)
      }

      loadfunctions( "groundfish", functionname="current.year.r" )
      loadfunctions( "groundfish", functionname="load.groundfish.environment.r" )

      ct = snowcrab.external.db( DS="det.snowcrab.in.groundfish.survey", vname=vname )
      if (nrow(ct)==0) return()

      uu = sum.data( ct, factors="id", variable="number" )
      names(uu) =c( "id", "n" )

      set = groundfish.db( "set.base" )
      set = lonlat2planar( set, proj.type=p$internal.projection )  # utm20, WGS84 (snowcrab geoid) 
      set$plon = grid.internal( set$plon, p$plons )
      set$plat = grid.internal( set$plat, p$plats )

      set = set[ which( is.finite( set$plon + set$plat) ) , ]
      if (nrow(set)==0) return()

      set = merge (set, uu, by = "id", sort=F, all.x=T, all.y=F )
      oo = as.data.frame( matrix( unlist( strsplit( set$id, ".", fixed=T )), ncol=2, byrow=T ))
      names(oo) = c("trip", "set" )
      oo$trip = as.character( oo$trip)
      oo$set = as.numeric( as.character( oo$set ))
      set = cbind( set, oo)
      set$survey = "groundfish"
      set$metric = "number"
      set$z = set$sdepth
      set$t = set$temp
      set$sa = set$sakm2
      set$n [ which( !is.finite( set$n)) ] = 0 # assume to be real zeros as dervied from trawls
      set$temp = NULL
      set$sdepth = NULL
      set$cftow = NULL
      
      set$yr = convert.datecodes(set$chron, "year")
      set$julian = convert.datecodes(set$chron, "julian")
      set$weekno = floor(set$julian/365*52) + 1 
      
      #----------------------------
      # look up missing environmental data
      sp.br=c(1, 5, 10) # distances to interpolate ... short-scale only (km) if no exact match
       
		# bring in time invariant features:: depth
			print ("Bring in depth")
      todrop = which(set$z < 20 | set$z > 500 )
      if (length( todrop) > 0 ) set$z [todrop ] = NA
      set$z = habitat.lookup.simple( set,  p=p, vnames="z", lookuptype="depth" )
      set$z = log( set$z )
			
		  # bring in time varing features:: temperature
			print ("Bring in temperature")
      set$t = habitat.lookup.simple( set,  p=p, vnames="t", lookuptype="temperature.weekly" )

			# bring in all other habitat variables, use "z" as a proxy of data availability
			# and then rename a few vars to prevent name conflicts
			print ("Bring in all other habitat variables")
      sH = habitat.lookup.grouped( set,  p=p, lookuptype="all.data", sp.br=sp.br )
      sH$z = NULL 
			sH$yr = NULL
			sH$weekno = NULL
      sH
      vars = names (sH )

      set = cbind( set, sH )
		
      # return planar coords to correct resolution
      set = lonlat2planar( set, proj.type=p$internal.projection )
     
      set = set[ which( is.finite( set$z + set$t + set$substrate.mean ) ), ]
      gc()

      # convert non-zero values quantiles, 
      oo = which( !is.finite( set$sa )  )
      if (length(oo)>0 ) set$sa[oo ] = median( set$sa, na.rm=TRUE )

	    regs = c("cfanorth", "cfasouth", "cfa4x" )
      set$cfa = NA
      for (r in regs) {
        jj = filter.region.polygon( set[, c("plon", "plat") ], region=r, planar=T, proj.type=p$internal.projection ) 
        set$cfa[jj] = r
      }


      # ---------------------------------
      # bring in fisheries stats
      set = logbook.fisheries.stats.merge( set )
      
      save ( set, file=fn, compress=T )
      
      return ( fn )

    }

  }

  

