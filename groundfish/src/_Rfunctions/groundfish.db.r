
  groundfish.db = function(  DS="complete", p=NULL, taxa="all", r2crit=0.75, threshold=0, type="number", season="summer", datayrs=NULL  ) {
  
    loc = file.path( project.directory("groundfish"), "data" )
    DataDumpFromWindows = F
    if ( DataDumpFromWindows ) {
      project.directory("taxonomy") = loc = file.path("C:", "datadump")
    }
    dir.create( path=loc, recursive=T, showWarnings=F )
    
    if (DS %in% c("odbc.redo") ) {
      
      # ODBC data dump of groundfish tables
      groundfish.db( DS="gscat.odbc.redo", datayrs=datayrs )
      groundfish.db( DS="gsdet.odbc.redo", datayrs=datayrs )
      groundfish.db( DS="gsinf.odbc.redo", datayrs=datayrs )
      groundfish.db( DS="gshyd.profiles.odbc.redo", datayrs=datayrs )

      groundfish.db( DS="gsmissions.odbc.redo" ) #  not working?
      
      update.infrequently = F
      if (update.infrequently) {
        # the following do not need to be updated annually
        groundfish.db( DS="gscoords.odbc.redo" )
        groundfish.db( DS="spcodes.odbc.redo" )
        groundfish.db( DS="gslist.odbc.redo" )
        groundfish.db( DS="gsstratum.odbc.redo" )
      }
    
    }

 # ----------------------

    if (DS %in% c("spcodes", "spcodes.odbc", "spcodes.redo", "spcodes.odbc.redo", "gstaxa", "gstaxa.redo"  ) ) {
      
      fnspc = file.path( loc, "spcodes.rdata" )
         
      if ( DS %in% c( "spcodes", "spcodes.odbc", "gstaxa" ) ) {
        load( fnspc )
        return( spcodes )
      }

      if ( DS %in% c( "spcodes.odbc.redo", "spcodes.redo", "gstaxa.redo" ) ) {
        require(RODBC)
        connect=odbcConnect( oracle.groundfish.server, uid=oracle.personal.user,
            pwd=oracle.personal.password, believeNRows=F)
        spcodes =  sqlQuery(connect, "select * from groundfish.gsspecies", as.is=T) 
        odbcClose(connect)
        names(spcodes) =  tolower( names(spcodes) )
        save(spcodes, file=fnspc, compress=T)
        print( fnspc )
        print("Should follow up with a refresh of the taxonomy.db " )
        return( fnspc )
      }
    }


    # --------------------



		if (DS %in% c( "gscat.odbc", "gscat.odbc.redo" ) ) {
      
      fn.root =  file.path( project.directory("groundfish"), "data", "trawl", "gscat" )
			dir.create( fn.root, recursive = TRUE, showWarnings = FALSE  )
       
			out = NULL
	    if ( is.null(DS) | DS=="gscat.odbc" ) {
        fl = list.files( path=fn.root, pattern="*.rdata", full.names=T ) 
 				for ( fny in fl ) {
					load (fny)
					out = rbind( out, gscat )
				}
				return (out)
      }

      require(RODBC)
      connect=odbcConnect( oracle.groundfish.server, uid=oracle.personal.user, pwd=oracle.personal.password, believeNRows=F)

			for ( YR in datayrs ) {
				fny = file.path( fn.root, paste( YR,"rdata", sep="."))
        gscat = sqlQuery( connect,  paste( 
               "select i.*, j.YEAR " , 
        "    from groundfish.gscat i, groundfish.gsmissions j " , 
        "    where i.MISSION(+)=j.MISSION " ,
        "    and YEAR=", YR, ";"
        ) )
     
        names(gscat) =  tolower( names(gscat) )
        print(fny)
        save(gscat, file=fny, compress=T)
				gc()  # garbage collection
				print(YR)
			}
   
      odbcClose(connect)             
      return (fn.root)

		}


    # --------------------


 
    if (DS %in% c("gscat", "gscat.redo"  ) ) {
       
      fn = file.path( loc,"gscat.rdata")
      
      if ( DS=="gscat" ) {
        load( fn )
        return (gscat)
      }

      gscat = groundfish.db( DS="gscat.odbc" )
      gscat$year = NULL

      # update taxa codes to a clean state:
      spec.pass1 = taxa.specid.correct( gscat$spec ) 
      oo = which( !is.finite(spec.pass1) ) 
 
      if (length(oo) > 0 ) {
        res = lookup.taxa2tsn2spec( taxa=gscat$remarks[oo] )
        gscat$spec[oo] = res$spec
        taxa.db( DS="gscat.update", res=res )  # this saves a local copy of the "res" file which can then be used to update the specieslist 
      }

      gscat$spec = taxa.specid.correct( gscat$spec ) 

      
      # remove data where species codes are ambiguous, or missing or non-living items
      xx = which( !is.finite( gscat$spec) ) 
      if (length(xx)>0) gscat = gscat[ -xx, ] 

      gscat = gscat[ filter.taxa( gscat$spec, method="living.only" ) , ]

      min.number.observations.required = 3
      species.counts = as.data.frame( table( gscat$spec) )
      species.to.remove = as.numeric( as.character( species.counts[ which( species.counts$Freq < min.number.observations.required) , 1 ] ))

      ii = which( gscat$spec %in% species.to.remove )
      gscat = gscat[ -ii , ]
      gscat$id = paste(gscat$mission, gscat$setno, sep=".")
      gscat$id2 = paste(gscat$mission, gscat$setno, gscat$spec, sep=".")
  

      # filter out strange data
			ii = which( gscat$totwgt >= 9999 )  # default code for NAs -- 
      if (length(ii)>0) gscat$totwgt[ii] = NA 
    
			ii = which( gscat$totwgt >= 5000 )  # upper limit of realistic kg/set
      if (length(ii)>0) gscat$totwgt[ii] = 5000
      
			jj = which( gscat$totwgt == 0 )
			if (length(jj)>0) gscat$totwgt[jj] = NA

			kk = which( gscat$totno == 0 ) 
      if (length(kk)>0) gscat$totno[kk] = NA
 		
      ll = which( is.na(gscat$totno) & is.na(gscat$totwgt) ) 
      if (length(ll) > 0) gscat$totno[ ll ] = 1
        
      # as species codes have been altered, look for duplicates and update totals	
      d = which(duplicated(gscat$id2))
      s = NULL
      for (i in d) {
        q = which(gscat$id2 == gscat$id2[i])
				gscat$totno[q[1]] = sum( gscat$totno[q], na.rm=T )
				gscat$totwgt[q[1]] = sum( gscat$totwgt[q], na.rm=T )
				gscat$sampwgt[q[1]] = sum( gscat$sampwgt[q], na.rm=T )
        s = c(s, q[2:length(q)])
      }
      if (length(s)>0) gscat = gscat[-s,]

      oo = which( duplicated( gscat$id2) )
      if ( length( oo )>0 ) {
        print( gscat[ oo , "id2"] )
        stop("Duplcated id2's in gscat"  )
      }

      mw = meansize.crude(Sp=gscat$spec, Tn=gscat$totno, Tw=gscat$totwgt )
      mw2 = meansize.direct() 
      mw = merge(mw, mw2, by="spec", all=T, sort=T, suffixes=c(".crude", ".direct") )
      # directly determined mean size has greater reliability --- replace
      mm = which( is.finite(mw$meanweight.direct))
      mw$meanweight = mw$meanweight.crude
      mw$meanweight[mm] = mw$meanweight.direct[mm]
      mw = mw[which(is.finite(mw$meanweight)) ,]


      ii = which( is.na(gscat$totno) & gscat$totwgt >  0 ) 
      
      print( "Estimating catches from mean weight information... slow ~ 5 minutes")

      if (length(ii)>0) {
        # replace each number estimate with a best guess based upon average body weight in the historical record
        uu = unique( gscat$spec[ii] )
        for (u in uu ) {
          os =  which( mw$spec==u ) 
          if (length( os)==0 ) next()
          toreplace = intersect( ii, which( gscat$spec==u) )
          gscat$totno[toreplace] = gscat$totwgt[toreplace] / mw$meanweight[os]
        }
      }

      jj = which( gscat$totno >  0 & is.na(gscat$totwgt) ) 
      if (length(jj)>0) {
        # replace each number estimate with a best guess based upon average body weight in the historical record
        uu = unique( gscat$spec[jj] )
        for (u in uu ) {
          os =  which( mw$spec==u ) 
          if (length( os)==0 ) next()
          toreplace = intersect( jj, which( gscat$spec==u) )
          gscat$totwgt[toreplace] = gscat$totno[toreplace] * mw$meanweight[os]
        }
      }

 
      gscat = gscat[, c("id", "id2", "spec", "totwgt", "totno", "sampwgt" )] # kg, no/set

      save(gscat, file=fn, compress=T)
      return( fn )
    }

  # ----------------------


		if (DS %in% c( "gsdet.odbc", "gsdet.odbc.redo" ) ) {
      
      fn.root =  file.path( project.directory("groundfish"), "data", "trawl", "gsdet" )
			dir.create( fn.root, recursive = TRUE, showWarnings = FALSE  )
       
			out = NULL
	    if ( is.null(DS) | DS=="gsdet.odbc" ) {
        fl = list.files( path=fn.root, pattern="*.rdata", full.names=T  ) 
 				for ( fny in fl ) {
					load (fny)
					out = rbind( out, gsdet )
				}
				return (out)
      }

      require(RODBC)
      connect=odbcConnect( oracle.groundfish.server, uid=oracle.personal.user, pwd=oracle.personal.password, believeNRows=F)

			for ( YR in datayrs ) {
				fny = file.path( fn.root, paste( YR,"rdata", sep="."))
        gsdet = sqlQuery( connect,  paste( 
        "select i.*, j.YEAR " , 
        "    from groundfish.gsdet i, groundfish.gsmissions j " , 
        "    where i.MISSION(+)=j.MISSION " ,
        "    and YEAR=", YR, ";"
        ) )
        names(gsdet) =  tolower( names(gsdet) )
        gsdet$mission = as.character( gsdet$mission )
        save(gsdet, file=fny, compress=T)
        print(fny)
				gc()  # garbage collection
				print(YR)
			}
      odbcClose(connect)
              
      return (fn.root)

		}
     
   
    # ----------------------


    if (DS %in% c("gsdet", "gsdet.redo") ) {
    
    # --------- codes ----------------
    # sex: 0=?, 1=male, 2=female,  3=?
    # mat: 0=observed but undetermined, 1=imm, 2=ripening(1), 3=ripening(2), 4=ripe(mature), 
    #      5=spawning(running), 6=spent, 7=recovering, 8=resting
    # settype: 1=stratified random, 2=regular survey, 3=unrepresentative(net damage), 
    #      4=representative sp recorded(but only part of total catch), 5=comparative fishing experiment, 
    #      6=tagging, 7=mesh/gear studies, 8=explorartory fishing, 9=hydrography
    # --------- codes ----------------


      fn = file.path( loc,"gsdet.rdata")
      
      if ( DS=="gsdet" ) {
        load( fn )
        return (gsdet)
      }

      gsdet = groundfish.db( DS="gsdet.odbc" )
      gsdet$year = NULL
             
      gsdet$spec = taxa.specid.correct( gsdet$spec ) 
      oo = which(!is.finite(gsdet$spec) )
      if (length(oo)>0) gsdet = gsdet[-oo,]
      
      # remove data where species codes are ambiguous, or missing or non-living items
      gsdet = gsdet[ filter.taxa( gsdet$spec, method="living.only" ) , ]


      gsdet$id = paste(gsdet$mission, gsdet$setno, sep=".")
      gsdet$id2 = paste(gsdet$mission, gsdet$setno, gsdet$spec, sep=".")
      gsdet = gsdet[, c("id", "id2", "spec", "fshno", "fsex", "fmat", "flen", "fwt", "age") ]  
      names(gsdet)[which(names(gsdet)=="fsex")] = "sex"
      names(gsdet)[which(names(gsdet)=="fmat")] = "mat"
      names(gsdet)[which(names(gsdet)=="flen")] = "len"  # cm
      names(gsdet)[which(names(gsdet)=="fwt")]  = "mass" # g
      save(gsdet, file=fn, compress=T)

      return( fn )
    }
  
    
    # ----------------------


		if (DS %in% c( "gsinf.odbc", "gsinf.odbc.redo" ) ) {
      
      fn.root =  file.path( project.directory("groundfish"), "data", "trawl", "gsinf" )
			dir.create( fn.root, recursive = TRUE, showWarnings = FALSE  )
       
			out = NULL
	    if ( is.null(DS) | DS=="gsinf.odbc" ) {
        fl = list.files( path=fn.root, pattern="*.rdata", full.names=T  ) 
 				for ( fny in fl ) {
					load (fny)
					out = rbind( out, gsinf )
				}
				return (out)
      }

      require(RODBC)
      connect=odbcConnect( oracle.groundfish.server, uid=oracle.personal.user, pwd=oracle.personal.password, believeNRows=F)

			for ( YR in datayrs ) {
				fny = file.path( fn.root, paste( YR,"rdata", sep="."))
        gsinf = sqlQuery( connect,  paste( 
        "select * from groundfish.gsinf where EXTRACT(YEAR from SDATE) = ", YR, ";"
        ) )
        names(gsinf) =  tolower( names(gsinf) )
        save(gsinf, file=fny, compress=T)
        print(fny)
				gc()  # garbage collection
				print(YR)
			}
	        
      odbcClose(connect)	              
      return (fn.root)

		}
     
    

  # ----------------------


    if (DS %in% c("gsinf", "gsinf.redo" ) ) {
      fn = file.path( loc,"gsinf.rdata")
      
      if ( DS=="gsinf" ) {
        load( fn )
        return (gsinf)
      }
 
      gsinf = groundfish.db( DS="gsinf.odbc" )
      names(gsinf)[which(names(gsinf)=="type")] = "settype"
      gsinf$mission = as.character( gsinf$mission )
      gsinf$strat = as.character(gsinf$strat)
      gsinf$strat[ which(gsinf$strat=="") ] = "NA"
      gsinf$id = paste(gsinf$mission, gsinf$setno, sep=".")
      d = which(duplicated(gsinf$id))
      if (!is.null(d)) write("error: duplicates found in gsinf")
      gsinf$lat = gsinf$slat/100
      gsinf$lon = gsinf$slong/100
      if (mean(gsinf$lon,na.rm=T) >0 ) gsinf$lon = - gsinf$lon  # make sure form is correct
      gsinf = convert.degmin2degdec(gsinf)
      gsinf$cftow = 1.75/gsinf$dist
      ft2m = 0.3048
      m2km = 1/1000
      nmi2mi = 1.1507794
      mi2ft = 5280
      gsinf$sakm2 = (41 * ft2m * m2km ) * ( gsinf$dist * nmi2mi * mi2ft * ft2m * m2km )  # surface area sampled in km^2
				oo = which( !is.finite(gsinf$sakm2 )) 
					gsinf$sakm2[oo] = median (gsinf$sakm2, na.rm=T)
				pp = which( gsinf$sakm2 > 0.09 )
					gsinf$sakm2[pp] = median (gsinf$sakm2, na.rm=T)


			gsinf = gsinf[, c("id", "sdate", "time", "strat","area", "dist", "cftow", "sakm2", "settype", "lon", "lat", "surface_temperature","bottom_temperature","bottom_salinity")]
      save(gsinf, file=fn, compress=T)
      return(fn)
    }

 # ----------------------


		if (DS %in% c( "gshyd.profiles.odbc" , "gshyd.profiles.odbc.redo" ) ) {
      
      fn.root =  file.path( project.directory("groundfish"), "data", "trawl", "gshyd" )
			dir.create( fn.root, recursive = TRUE, showWarnings = FALSE  )
       
			out = NULL
	    if ( is.null(DS) | DS=="gshyd.profiles.odbc" ) {
        fl = list.files( path=fn.root, pattern="*.rdata", full.names=T  ) 
 				for ( fny in fl ) {
					load (fny)
					out = rbind( out, gshyd )
				}
				return (out)
      }

      require(RODBC)
      connect=odbcConnect( oracle.groundfish.server, uid=oracle.personal.user, pwd=oracle.personal.password, believeNRows=F)

			for ( YR in datayrs ) {
				fny = file.path( fn.root, paste( YR,"rdata", sep="."))
        gshyd = sqlQuery( connect,  paste( 
        "select i.*, j.YEAR " , 
        "    from groundfish.gshyd i, groundfish.gsmissions j " , 
        "    where i.MISSION(+)=j.MISSION " ,
        "    and YEAR=", YR, ";"
        ) )
        names(gshyd) =  tolower( names(gshyd) )
        gshyd$mission = as.character( gshyd$mission )
        save(gshyd, file=fny, compress=T)
        print(fny)
				gc()  # garbage collection
				print(YR)
			}
			odbcClose(connect)
              
      return ( fn.root )

		}
     
 # ----------------------


   
    if (DS %in% c("gshyd.profiles", "gshyd.profiles.redo" ) ) {
      # full profiles
      fn = file.path( loc,"gshyd.profiles.rdata")
      if ( DS=="gshyd.profiles" ) {
        load( fn )
        return (gshyd)
      }
      
      gshyd = groundfish.db( DS="gshyd.profiles.odbc" )
      gshyd$id = paste(gshyd$mission, gshyd$setno, sep=".")
      gshyd = gshyd[, c("id", "sdepth", "temp", "sal", "oxyml" )]
      save(gshyd, file=fn, compress=T)
      return( fn )
    }
      
 # ----------------------



    if (DS %in% c("gshyd", "gshyd.redo") ) {
      # hydrographic info at deepest point
      fn = file.path( loc,"gshyd.rdata")
      if ( DS=="gshyd" ) {
        load( fn )
        return (gshyd)
      }
      gshyd = groundfish.db( DS="gshyd.profiles" )
      nr = nrow( gshyd)

      deepest = NULL
      t = which( is.finite(gshyd$sdepth) )
      id = unique(gshyd$id)
      for (i in id) {
        q = intersect( which( gshyd$id==i), t )
        r = which.max( gshyd$sdepth[q] )
        deepest = c(deepest, q[r])
      }
      gshyd = gshyd[deepest,]
      
      oo = which( duplicated( gshyd$id ) )
      if (length(oo) > 0) stop( "Duplicated data in GSHYD" )

      gsinf = groundfish.db( "gsinf" ) 
      gsinf = gsinf[, c("id", "bottom_temperature", "bottom_salinity" ) ] 
      gshyd = merge( gshyd, gsinf, by="id", all.x=T, all.y=F, sort=F )
      
      ii = which( is.na( gshyd$temp) )
      if (length(ii)>0) gshyd$temp[ii] =  gshyd$bottom_temperature[ii]

      jj = which( is.na( gshyd$sal) )
      if (length(jj)>0) gshyd$sal[jj] =  gshyd$bottom_salinity[jj]

      gshyd$bottom_temperature = NULL
      gshyd$bottom_salinity = NULL


      gshyd$sal[gshyd$sal<5 ] = NA
      
      save(gshyd, file=fn, compress=T)
      return( fn )
    }

 # ----------------------



    if (DS %in% c("gshyd.georef", "gshyd.georef.redo") ) {
      # hydrographic info georeferenced
      fn = file.path( loc,"gshyd.georef.rdata")
      if ( DS=="gshyd.georef" ) {
        load( fn )
        return (gshyd)
      }
      gsinf = groundfish.db( "gsinf" ) 
      gsinf$date = as.chron( gsinf$sdate )
      gsinf$yr = convert.datecodes( gsinf$date, "year" )
      gsinf$dayno = convert.datecodes( gsinf$date, "julian")
      gsinf$weekno = ceiling ( gsinf$dayno / 365 * 52 )
      gsinf$longitude = gsinf$lon
      gsinf$latitude = gsinf$lat
      gsinf = gsinf[ , c( "id", "lon", "lat", "yr", "weekno", "dayno", "date" ) ]
      gshyd = groundfish.db( "gshyd.profiles" )
      gshyd = merge( gshyd, gsinf, by="id", all.x=T, all.y=F, sort=F )
      gshyd$sal[gshyd$sal<5]=NA
      save(gshyd, file=fn, compress=T)
      return( fn )
    }


    # ----------------------


    if (DS %in% c("gsstratum", "gsstratum.obdc.redo") ) {
      fn = file.path( loc,"gsstratum.rdata")
      if ( DS=="gsstratum" ) {
        load( fn )
        return (gsstratum)
      }
      require(RODBC)
      connect=odbcConnect( oracle.groundfish.server, uid=oracle.personal.user, 
          pwd=oracle.personal.password, believeNRows=F)
      gsstratum =  sqlQuery(connect, "select * from groundfish.gsstratum", as.is=T) 
      odbcClose(connect)
      names(gsstratum) =  tolower( names(gsstratum) )
      save(gsstratum, file=fn, compress=T)
      print(fn)
      return( fn )
    }


    # ----------------------


    if (DS %in% c("gscoords", "gscoords.odbc.redo") ) {
      # detailed list of places, etc
      fn = file.path( loc,"gscoords.rdata")
      if ( DS=="gscoords" ) {
        load( fn )
        return (gscoords)
      }
      require(RODBC)
      connect=odbcConnect( oracle.groundfish.server, uid=oracle.personal.user, 
          pwd=oracle.personal.password, believeNRows=F)
      coords = sqlQuery(connect, "select * from mflib.mwacon_mapobjects", as.is=T) 
      odbcClose(connect)
      names(coords) =  tolower( names(coords) )
      save(coords, file=fn, compress=T)
      print(fn)
      return( fn )
    }
 
 # ----------------------

 
   if (DS %in% c("gslist", "gslist.odbc.redo") ) {
      fn = file.path( loc,"gslist.rdata")
      if ( DS=="gslist" ) {
        load( fn )
        return (gslist)
      }
      require(RODBC)
      connect=odbcConnect( oracle.groundfish.server, uid=oracle.personal.user, 
          pwd=oracle.personal.password, believeNRows=F)
      gslist = sqlQuery(connect, "select * from groundfish.gs_survey_list")
      odbcClose(connect)
      names(gslist) =  tolower( names(gslist) )
      save(gslist, file=fn, compress=T)
      print(fn)
      return( fn )
    }

 # ----------------------

    if (DS %in% c("gsmissions", "gsmissions.odbc.redo") ) {
      fnmiss = file.path( loc,"gsmissions.rdata")
      
      if ( DS=="gsmissions" ) {
        load( fnmiss )
        return (gsmissions)
      }
      
      require(RODBC)
      connect=odbcConnect( oracle.groundfish.server, uid=oracle.personal.user, 
          pwd=oracle.personal.password, believeNRows=F)
        gsmissions = sqlQuery(connect, "select MISSION, VESEL, CRUNO from groundfish.gsmissions")
        odbcClose(connect)
        names(gsmissions) =  tolower( names(gsmissions) )
        save(gsmissions, file=fnmiss, compress=T)
      print(fnmiss)
      return( fnmiss )
    }

 # ----------------------

    if (DS %in% c("cat.base", "cat.base.redo") ) {
      fn = file.path( project.directory("groundfish"), "data", "cat.base.rdata")
      if ( DS=="cat.base" ) {
        load( fn )
        return (cat)
      }
      
      require(chron)

      gscat = groundfish.db( "gscat" ) #kg/set, no/set 
      gsinf = groundfish.db( "gsinf" ) 
      cat = merge(x=gscat, y=gsinf, by=c("id"), all.x=T, all.y=F, sort=F) 
      rm (gscat, gsinf)     
   
      gshyd = groundfish.db( "gshyd" ) 
      cat = merge(x=cat, y=gshyd, by=c("id"), all.x=T, all.y=F, sort=F) 
      rm (gshyd)

      gstaxa = taxa.db( "life.history" ) 
      gstaxa = gstaxa[,c("spec", "name.common", "name.scientific", "itis.tsn" )]
      oo = which( duplicated( gstaxa$spec ) )
      if (length( oo) > 0 ) {
        gstaxa = gstaxa[ -oo , ]  # arbitrarily drop subsequent matches
        print( "NOTE -- Duplicated species codes in taxa.db(life.history) ... need to fix taxa.db, dropping for now " )
      }

      cat = merge(x=cat, y=gstaxa, by=c("spec"), all.x=T, all.y=F, sort=F) 
      rm (gstaxa)


      # initial merge without any real filtering
      # save(cat, file=file.path( project.directory("groundfish"), "data", "cat0.rdata"), compress=T)  

			oo = which( !is.finite( cat$sdate)) # NED1999842 has no accompanying gsinf data ... drop it
      if (length(oo)>0) cat = cat[ -oo  ,]  
      cat$chron = as.chron(cat$sdate)
      cat$sdate = NULL
      cat$yr = convert.datecodes(cat$chron, "year" )
      cat$julian = convert.datecodes(cat$chron, "julian")

      save(cat, file=fn, compress=T )

      return ( fn )
    }
    
     # ----------------------

    if (DS %in% c("det.base", "det.base.redo") ) {
      fn = file.path( project.directory("groundfish"), "data", "det.base.rdata")
      if ( DS=="det.base" ) {
        load( fn )
        return (det)
      }

      det = groundfish.db( "gsdet" )
      
      det = det[, c("id", "id2", "spec", "fshno", "sex", "mat", "len", "mass", "age") ]
      det$mass = det$mass / 1000 # convert from g to kg 
      #       
      #       det$mass = log10(det$mass) # log10(kg)
      #       det$len = log10(det$len)  # log10(cm)
      # 
      #qmass = quantile( det$mass, probs=c(0.005, 0.995), na.rm=T )
      # det$mass[ which( det$mass< qmass[1] | det$mass>qmass[2]) ] = NA

      #qlen = quantile( det$len, probs=c(0.005, 0.995), na.rm=T )
      # det$len[ which( det$len < qlen[1] | det$len>qlen[2]) ] = NA

#      k = which( is.finite(det$len) & is.finite(det$mass)  )
      
      #       R = lm.resid( det[k ,c("mass", "len", "sex", "spec")], threshold=r2crit )
      #       det$residual = NA
      #       det$residual[k] = R$residual
      #       
      #       det$predicted.mass = NA
      #       det$predicted.mass[k] = R$predicted.mass
      # 
      #       i = which( !is.finite( det$predicted.mass)  )
      #       det$predicted.mass[i] = lm.mass.predict ( x=det[i,c("spec","sex","len")], lm=R$lm.summ, threshold=r2crit )
      #    
      #       i = which( is.finite(det$residual)  )
      #       det$pvalue = NA
      #       det$pvalue[i] = lm.pvalue ( x=det[i,c("spec","sex", "residual")], lm=R$lm.summ, threshold=r2crit )
      #       
      #       det$mass = 10^(det$mass)  # re-convert to (kg) (from log10(kg))
      #       det$len = 10^(det$len)  # re-convert to (kg) (from log10(kg))
      #       det$predicted.mass = 10^(det$predicted.mass)
      #       
      #       oo = which( !is.finite(det$mass) & is.finite(det$predicted.mass) )
      #       det$mass[oo] = det$predicted.mass[oo]
      # 
      save( det, file=fn, compress=T )
      return( fn )
    }
 

 # ----------------------

    if (DS %in% c("cat", "cat.redo") ) {
      fn = file.path( project.directory("groundfish"), "data", "cat.rdata")
      if ( DS=="cat" ) {
        load( fn )
        return (cat)
      }
     
      cat = groundfish.db( DS="cat.base" )  # kg/set, no/set
     
      # combine correction factors or ignore trapability corrections .. 
      # plaice correction ignored as they are size-dependent
      cat = correct.vessel(cat)
     
      #dim(cat)
#[1] 184372     32


      # many cases have measurements but no subsampling info  ---- NOTE ::: sampwgt seems to be unreliable  -- recompute where necessary in "det"
      
        # weighting for totals 
      cat$cf = cat$cfvessel / cat$sakm2 

      # the following conversion are done here as sakm2 s not available in "gscat"
      # .. needs to be merged before use from gsinf
      # surface area of 1 standard set: sa =  41 (ft) * N  (nmi); N==1.75 for a standard trawl
      # the following express per km2 and so there is no need to "correct"  to std tow.
      
      cat$totwgt  = cat$totwgt  * cat$cf # convert kg/set to kg/km^2
      cat$totno   = cat$totno   * cat$cf # convert number/set to number/km^2
 
      # cat$sampwgt is unreliable for most data points nned to determine directly from "det"
      cat$sampwgt = NULL
      
      # cat$cfsampling = cat$totwgt / cat$sampwgt
      # cat$cfsampling[ which( !is.finite(cat$cfsampling)) ] = 1 # can only assume everything was measured (conservative estimate)

     
      # cat$sampwgt =  cat$sampwgt * cat$cf   # keep same scale as totwgt to permit computations later on 
      
      save(cat, file=fn, compress=T )

      return (fn)
    }
    


 # ----------------------



    if (DS %in% c("det", "det.redo") ) {
      fn = file.path( project.directory("groundfish"), "data", "det.rdata")
      if ( DS=="det" ) {
        load( fn )
        return (det)
      }
 
      # determine weighting factor for individual-level measurements (len, weight, condition, etc)
      # x$cf is the multiplier used to scale for trawl sa, species, but not subsampling of individual metrics 
      
      # at the set level, some species are not sampled even though sampwgt's are recorded
      # this makes the total biomass > than that estimated from "DET" 
      # a final correction factor is required to bring it back to the total biomass caught,
      # this must be aggregated across all species within each set :  

      # correction factors for sampling etc after determination of mass and len 
      # for missing data due to subsampling methodology
      # totals in the subsample that was taken should == sampwgt (in theory) but do not 
      # ... this is a rescaling of the sum to make it a 'proper' subsample
      
      det = groundfish.db( "det.base" )  # kg, cm
      
      massTotCat = applySum( det[ ,c("id2", "mass")], newnames=c("id2","massTotdet" ) )  
      noTotCat = applySum( det$id2, newnames=c("id2","noTotdet" ) )  

      cat = groundfish.db( "cat" ) # kg/km^2 and  no/km^2 
      cat = cat[, c("id2", "totno", "totwgt", "cf", "cfvessel", "cftow" )]
      cat = merge( cat, massTotCat, by="id2", all.x=T, all.y=F, sort=F )  # set-->kg/km^2, det-->km
      cat = merge( cat, noTotCat, by="id2", all.x=T, all.y=F, sort=F )    # set-->no/km^2, det-->no
 
      cat$cfdetcat =  cat$totwgt/ cat$massTotdet 
      oo = which ( !is.finite( cat$cfdetcat ) )
      if (length(oo)>0) cat$cfdetcat[oo] = 1  # assume no subsampling -- all weights determined from the subsample
      
      pp = which ( cat$cfdetcat==0)
      if (length(pp) > 0) cat$cfdetcat[pp ] = 1  # assume no subsampling -- all weights determined from the subsample

      cat$cfdet = cat$cfset * cat$cfdetcat  ## This brings together all weighting factors to make each individual reading equivalent to other individual readings

      det = merge( det, cat[, c("id2", "cfdet")], by="id2", all.x=T, all.y=F, sort=F)

      save( det, file=fn, compress=T )
      return( fn  )
    }
 


 # ----------------------

  
    if (DS %in% c("set.base", "set.base.redo") ) {
      fn = file.path( project.directory("groundfish"), "data", "set.base.rdata")
      if ( DS=="set.base" ) {
        load( fn )
        return ( set )
      }
 ~~~check     set = groundfish.db( "cat")  
      set = set[, c("id", "chron", "yr", "julian", "strat", "dist", 
                 "sakm2", "lon", "lat", "sdepth", "temp", "sal", "oxyml", "settype", "cf")]

      set = set[ !duplicated(set$id) ,] 
      set$oxysat = compute.oxygen.saturation( t.C=set$temp, sal.ppt=set$sal, oxy.ml.l=set$oxyml)
      save ( set, file=fn, compress=T)
      return( fn  )
    }
     
     # ----------------------

    
    if (DS %in% c("catchbyspecies", "catchbyspecies.redo") ) {
     fn = file.path( project.directory("groundfish"), "data", "set.catchbyspecies.rdata")
     if ( DS=="catchbyspecies" ) {
       load( fn )
       return ( set )
     }
 
      set = groundfish.db( "set.base" ) [, c("id", "yr")] # yr to maintain data structure

      # add dummy variables to force merge suffixes to register
      set$totno = NA
      set$totwgt = NA
      set$ntaxa = NA
      cat = groundfish.db( "cat" ) 
      cat = cat[ which(cat$settype %in% c(1,2,5)) , ]  # required only here
  
    # settype: 1=stratified random, 2=regular survey, 3=unrepresentative(net damage), 
    #  4=representative sp recorded(but only part of total catch), 5=comparative fishing experiment, 
    #  6=tagging, 7=mesh/gear studies, 8=explorartory fishing, 9=hydrography

      cat0 = cat[, c("id", "spec", "totno", "totwgt")]
      rm(cat); gc()
      for (tx in taxa) {
        print(tx)
        i = filter.taxa( x=cat0$spec, method=tx )
        cat = cat0[i,]
        index = list(id=cat$id)
        qtotno = tapply(X=cat$totno, INDEX=index, FUN=sum, na.rm=T)
        qtotno = data.frame(totno=as.vector(qtotno), id=I(names(qtotno)))
        qtotwgt = tapply(X=cat$totwgt, INDEX=index, FUN=sum, na.rm=T)
        qtotwgt = data.frame(totwgt=as.vector(qtotwgt), id=I(names(qtotwgt)))
        qntaxa = tapply(X=rep(1, nrow(cat)), INDEX=index, FUN=sum, na.rm=T)
        qntaxa = data.frame(ntaxa=as.vector(qntaxa), id=I(names(qntaxa)))
        qs = merge(qtotno, qtotwgt, by=c("id"), sort=F, all=T)
        qs = merge(qs, qntaxa, by=c("id"), sort=F, all=T)
        set = merge(set, qs, by=c("id"), sort=F, all.x=T, all.y=F, suffixes=c("", paste(".",tx,sep="")) )
      }
      set$totno = NULL
      set$totwgt = NULL
      set$ntaxa = NULL
      set$yr = NULL
      save ( set, file=fn, compress=T)
      return( fn  )
    }


    # ----------------------


    if (DS %in% c("set.det", "set.det.redo") ) {
      fn = file.path( project.directory("groundfish"), "data", "set_det.rdata")
      if ( DS=="set.det" ) {
        load( fn )
        return ( set )
      }
      
      require (Hmisc)
      set = groundfish.db( "set.base" ) [, c("id", "yr")] # yr to maintain data structure
      newvars = c("rmean", "pmean", "mmean", "lmean", "rsd", "psd", "msd", "lsd") 
      dummy = as.data.frame( array(data=NA, dim=c(nrow(set), length(newvars) )))
      names (dummy) = newvars
      set = cbind(set, dummy)
      
      det = groundfish.db( "det" )       
     
      #det = det[ which(det$settype %in% c(1, 2, 4, 5, 8) ) , ]
    # settype: 1=stratified random, 2=regular survey, 3=unrepresentative(net damage), 
    #  4=representative sp recorded(but only part of total catch), 5=comparative fishing experiment, 
    #  6=tagging, 7=mesh/gear studies, 8=explorartory fishing, 9=hydrography
      det$mass = log10( det$mass )
      det$len  = log10( det$len )

#       det0 = det[, c("id", "spec", "mass", "len", "age", "residual", "pvalue", "cf")]
       det0 = det[, c("id", "spec", "mass", "len", "age", "cfdet")]
      rm (det); gc()

      for (tx in taxa) {
        print(tx)
        if (tx %in% c("northernshrimp") ) next
        i = filter.taxa( x=det0$spec, method=tx  )
        det = det0[i,]
        index = list(id=det$id)
        
        # using by or aggregate is too slow: raw computation is fastest using the fast formula: sd = sqrt( sum(x^2)-sum(x)^2/(n-1) ) ... as mass, len and resid are log10 transf. .. they are geometric means

        mass1 = tapply(X=det$mass*det$cfdet, INDEX=index, FUN=sum, na.rm=T)
        mass1 = data.frame(mass1=as.vector(mass1), id=I(names(mass1)))
        
        mass2 = tapply(X=det$mass*det$mass*det$cfdet, INDEX=index, FUN=sum, na.rm=T)
        mass2 = data.frame(mass2=as.vector(mass2), id=I(names(mass2)))

        len1 = tapply(X=det$len*det$cfdet, INDEX=index, FUN=sum, na.rm=T)
        len1 = data.frame(len1=as.vector(len1), id=I(names(len1)))
        
        len2 = tapply(X=det$len*det$len*det$cfdet, INDEX=index, FUN=sum, na.rm=T)
        len2 = data.frame(len2=as.vector(len2), id=I(names(len2)))
#
#        res1 = tapply(X=det$residual*det$cfdet, INDEX=index, FUN=sum, na.rm=T)
#        res1 = data.frame(res1=as.vector(res1), id=I(names(res1)))
#        
#        res2 = tapply(X=det$residual*det$residual*det$cfdet, INDEX=index, FUN=sum, na.rm=T)
#        res2 = data.frame(res2=as.vector(res2), id=I(names(res2)))
#
#        pv1 = tapply(X=det$pvalue*det$cfdet, INDEX=index, FUN=sum, na.rm=T)
#        pv1 = data.frame(pv1=as.vector(pv1), id=I(names(pv1)))
#        
#        pv2 = tapply(X=det$pvalue*det$pvalue*det$cfdet, INDEX=index, FUN=sum, na.rm=T)
#        pv2 = data.frame(pv2=as.vector(pv2), id=I(names(pv2)))
#
        ntot = tapply(X=det$cfdet, INDEX=index, FUN=sum, na.rm=T)
        ntot = data.frame(ntot=as.vector(ntot), id=I(names(ntot)))

        qs = NULL
        qs = merge(mass1, mass2, by=c("id"), sort=F, all=T)
        qs = merge(qs, len1, by=c("id"), sort=F, all=T)
        qs = merge(qs, len2, by=c("id"), sort=F, all=T)
#        qs = merge(qs, res1, by=c("id"), sort=F, all=T)
#        qs = merge(qs, res2, by=c("id"), sort=F, all=T)
#        qs = merge(qs, pv1, by=c("id"), sort=F, all=T)
#        qs = merge(qs, pv2, by=c("id"), sort=F, all=T)
        qs = merge(qs, ntot, by=c("id"), sort=F, all=T)

#        qs$rmean = qs$res1/qs$ntot
#        qs$pmean = qs$pv1/qs$ntot
        qs$mmean = qs$mass1/qs$ntot
        qs$lmean = qs$len1/qs$ntot
        
        # these are not strictly standard deviations as the denominator is not n-1 
        # but the sums being fractional and large .. is a close approximation
        # the "try" is to keep the warnings quiet as NANs are produced.
#        qs$rsd = try( sqrt( qs$res2 - (qs$res1*qs$res1/qs$ntot) ), silent=T )
#        qs$psd = try( sqrt( qs$pv2 - (qs$pv1*qs$pv1/qs$ntot) ), silent=T  )
        qs$msd = try( sqrt( qs$mass2 - (qs$mass1*qs$mass1/qs$ntot) ), silent=T  )
        qs$lsd = try( sqrt( qs$len2 - (qs$len1*qs$len1/qs$ntot)  ), silent=T  )
        
#        qs = qs[, c("id","rmean", "pmean","mmean", "lmean", "rsd", "psd", "msd", "lsd")]
        qs = qs[, c("id","mmean", "lmean",  "msd", "lsd")]
        set = merge(set, qs, by=c("id"), sort=F, all.x=T, all.y=F, suffixes=c("", paste(".",tx,sep="")) )
      }
      for (i in newvars) set[,i]=NULL # these are temporary vars used to make merges retain correct suffixes

      set$yr = NULL  # dummy var

      save ( set, file=fn, compress=T)
      return( fn  )
    }
    
 # ----------------------

    if (DS %in% c("metabolic.rates","metabolic.rates.redo") ) {
      fn = file.path( project.directory("groundfish"), "data", "set_mrate.rdata" )
      if (DS=="metabolic.rates") {
        load( fn)
        return (set)
      }
      
      set = groundfish.db( "set.base" )      
      x = groundfish.db( "det" )
      x = x[ which(x$settype %in% c(1, 2, 4, 5, 8) ) , ]
    #  settype: 1=stratified random, 2=regular survey, 3=unrepresentative(net damage), 
    #  4=representative sp recorded(but only part of total catch), 5=comparative fishing experiment, 
    #  6=tagging, 7=mesh/gear studies, 8=explorartory fishing, 9=hydrography

      x = merge(x, set, by="id", all.x=T, all.y=F, suffixes=c("",".set"), sort=F)

          
      # from Robinson et al. (1983) 
      # specific standard MR = 0.067 M^(-0.24) * exp(0.051 * Temp) 
      # (Temp in deg Celcius; M in grams, MR in ml O2/g/hr)
      b0 = 0.067
      b1 = -0.24
      b2 = 0.051
      
      # 1 ml O2 = 4.8 cal (from paper)
      # 1 W = 7537.2 kcal/yr
      
      # 1 ml O2 / g / hr = 4.8 * 24 * 365 kcal / yr / kg
      #                  = 4.8 * 24 * 365 / (7537.2 W) / kg
      #                  = 5.57873 W / kg
      
      from.ml.O2.per.g.per.hr.to.W.per.kg = 1 / 5.57873
      

    ###################### <<<<<<<<<<<<<<<<< Should bring in habitat variables here to assist with temperature .. lots of missing values!

      x$smr  = b0 * (x$mass*1000)^b1 * exp( b2 * 20.0) * from.ml.O2.per.g.per.hr.to.W.per.kg
      x$smrT = b0 * (x$mass*1000)^b1 * exp( b2 * x$temp) * from.ml.O2.per.g.per.hr.to.W.per.kg

      x$mr  = x$smr  * x$mass
      x$mrT = x$smrT * x$mass

      # Arrhenius correction
      # k = 10^8 # the constant
      # Ea = 10 # energy of activation (kcal/mol) 10 ~ q10 of 2; 25 ~ q10 of 4
      # R = 1.9858775 # gas constant cal/(mole.K)
      # x$mrT = x$mr * k * exp( - Ea * 1000 / (R * (x$temp + 273.150) ))

      prec = 10^5 # just a constant to get xtabs to work with a non-integer
      
      e = x$mr * x$cf  # correction factors required to make areal estimates 
      d = which( is.finite(e) & e> 0 )
        id = as.factor(x$id[d])
        l0 = prec / min(e[d] , na.rm=T)
        data = as.numeric(as.integer(e[d] * l0))
        mr = as.data.frame(xtabs(data ~ id) / l0)
      
      e = x$mrT * x$cf 
      d = which( is.finite(e) & e> 0 )
        id = as.factor(x$id[d])
        l0 = prec / min(e[d], na.rm=T)
        data = as.numeric(as.integer(e[d] * l0))
        mrT = as.data.frame(xtabs(data ~ id) / l0)
       
      e = x$mass * x$cf
      d = which( is.finite(e) & e> 0 )
        id = as.factor(x$id[d])
        l0 = prec / min(e[d], na.rm=T)
        data = as.numeric(as.integer(e[d] * l0))
        massTot = as.data.frame(xtabs(data ~ id) / l0)

      names(mr) = c("id","mr")
      names(mrT) = c("id","mrT")
      names(massTot) = c("id","massTot")

      mr$id = as.character(mr$id)
      mrT$id = as.character(mrT$id)
      massTot$id = as.character(massTot$id)
      mr$mr = as.numeric(mr$mr)
      mrT$mrT = as.numeric(mrT$mrT)
      massTot$massTot = as.numeric(massTot$massTot)
      
      # merge data together
      mr = merge(x=mr, y=mrT, by="id", all.x=T, all.y=F)
      mr = merge(x=mr, y=massTot, by="id", all.x=T, all.y=F)

      # calculate mass-specific rates in the whole set
      mr$smr = mr$mr / mr$massTot
      mr$smrT = mr$mrT / mr$massTot

      mr$smr[ which(mr$massTot==0) ] = NA
      mr$smrT[ which(mr$massTot==0) ] = NA

      mr = mr[mr$mr > 0 ,]
      mr = mr[mr$mrT > 0 ,]
      mr = mr[mr$massTot > 0 ,]
      mr = mr[is.finite(mr$mrT), ]

      mr.lm = summary(lm(log(mr$mr) ~ log(mr$massTot)))
      mrT.lm = summary(lm(log(mr$mrT) ~ log(mr$massTot)))

      mr$mrPvalue =  pnorm(q=mr.lm$residuals, sd=mr.lm$sigma)
      mr$mrPvalueT = pnorm(q=mrT.lm$residuals, sd=mrT.lm$sigma)

      set = groundfish.db( "set.base" ) [, c("id", "temp")]
      set = merge( set, mr, by=c("id"), sort=F, all.x=T, all.y=F )
      set$temp = NULL
      save (set, file=fn, compress=T)
      return( fn  )
 
    }

 # ----------------------

    if (DS %in% c("speciescomposition", "ordination.speciescomposition", "scores.speciescomposition", "speciescomposition.redo") ) {
    
      fn = file.path( project.directory("groundfish"), "data", "ordination.rdata" )
      fn.ord = file.path( project.directory("groundfish"), "data", "ordination.all.rdata" )
      fn.scores = file.path( project.directory("groundfish"), "data", "ordination.scores.rdata" )

      if ( DS=="speciescomposition" ) {
        load( fn )
        return (set)
      } 
   
      if ( DS=="ordination.speciescomposition" ) {
        load( fn.ord )
        return (ord)
      } 
   
      if ( DS=="scores.speciescomposition" ) {
        load( fn.scores )
        return (scores)
      } 
   

    # rescale variables .. log transforms and express per km2 before ordinations
    # ...  large magnitude numbers are needed for ordinations

    # form datasets
    # numbers and weights have already been converted to per km2 and with vessel corrections
      k = 1e4         # a large constant number to make xtabs work
  
      x = groundfish.db( "cat" )
      
      x = filter.taxa( x, method=p$taxa )
      
      x = x[ filter.season( x$julian, period=season, index=T ) , ]

      if (type == "number") {
        o = which(is.finite(x$totno))
        m = xtabs( as.numeric(as.integer(totno*k)) ~ as.factor(id) + as.factor(spec), data=x[o,] ) / k
      }
      if (type == "biomass") {
        o = which(is.finite(x$totwgt))
        m = xtabs(as.numeric( as.integer(totwgt*k)) ~ as.factor(id) + as.factor(spec), data=x[o,] ) / k
      }

      finished.j = finished.i = F
      while( !(finished.j & finished.i) ) {
        nr = nrow(m)
        nc = ncol(m)
        rowset = rowSums(m)
        colset = colSums(m)
        i = unique( c( which( rowset/nr <= threshold ), which(rowset==0 ) ))
        j = unique( c( which( colset/nc <= threshold ), which(colset==0 ) ))
        if (length(i) > 0 ) {
          m = m[ -i , ]
        } else {
          finished.i = T 
        }
        if (length(j) > 0 ) {
          m = m[ , -j ]
        } else {
          finished.j = T
        }
      }
      
      minval = min(m[m>threshold], na.rm=T)
      m = log( m + minval )
  
      ord = cca( m )
      sp.sc = scores(ord)$species
      si.sc = scores(ord)$sites

      scores = data.frame( 
        id=rownames(si.sc), 
        ca1=as.numeric(si.sc[,1]), 
        ca2=as.numeric(si.sc[,2]) 
      )
      scores$id = as.character(scores$id)

      save (scores, file=fn.scores, compress=T)
      save (ord, file=fn.ord, compress=T)
     
      set = groundfish.db( "set.base" ) [, c("id", "yr")]
      set = merge(set, scores, by="id", all.x=T, all.y=F, sort=F)
      set$yr = NULL
      
      save (set, file=fn, compress=T)
   
      print( ord$CA$eig[1:10]/sum(ord$CA$eig)*100 )

      cluster.analysis = F
      if (cluster.analysis) {
        X = t(m)
        gstaxa = taxa.db( "life.history" ) 
        names = NULL
        names$spec = as.numeric(dimnames(X)[[1]])
        names = merge(y=names, x=gstaxa, by="spec", all.y=T, all.x=F, sort=F)

        if (chisquared) {
          X = X/sum(X)
          rsums = rowSums(X)
          csums = colSums(X)
          rc = outer(rsums, csums)
          out = (X-rc)/sqrt(rc)
          d = out[lower.tri(out)]

          # mimic a "dist" class
          attr(d, "Size") <- nrow(X <- as.matrix(X))
          attr(d, "Labels") <- names$common
          attr(d, "Diag") <- F
          attr(d, "Upper") <- F
          attr(d, "method") <- "chisquare"
          attr(d, "call") <- "NA"
          class(d) <- "dist"
        }

        if (braycurtis) {
          attr(X, "dimnames")[[1]] = names$common
          d = vegdist(X, method="bray")
        }

        plot(hclust(d, "average"), cex=1); printfigure()
        plot(hclust(d, "ward"), cex=0.5); printfigure()
        plot(hclust(d, "complete"), cex=0.5); printfigure()
        plot(hclust(d, "single"), cex=0.5); printfigure()
        plot(hclust(d, "centroid"), cex=0.5); printfigure()
      
      }
      return ( c(fn, fn.ord, fn.scores)  )
    }

    # ----------------------

    if (DS %in% c("shannon.information", "shannon.information.redo" ) ) {
    
      fn = file.path( project.directory("groundfish"), "data", "set_shannon_information.rdata" )

      if (DS=="shannon.information") {
        load( fn )
        return (set)
      } 
      x = groundfish.db( "cat" )
       
      # filter taxa
      x = filter.taxa( x, method=p$taxa )
      x = x[ filter.season( x$julian, period=season, index=T ) , ]

      qn = quantile( x$totno, probs=0.95, na.rm = T ) 
      x$totno [ which( x$totno > qn ) ] = qn

                    # numbers and weights have already been converted to per km2 and with vessel corrections
      k = 1e3         # a large constant number to make xtabs work
      o = which(is.finite(x$totno))
      x = x[o,]
      m = xtabs( as.numeric(as.integer(totno*k)) ~ as.factor(id) + as.factor(spec), data=x ) / k
      
      
      # remove low counts (absence) in the timeseries  .. species (cols) only
      cthreshold = 0.05 * k  # quantiles to be removed 

      finished = F
      while( !(finished) ) {
        i = unique( which(rowSums(m) == 0 ) )
        j = unique( which(colSums(m) <= cthreshold ) )
        if ( ( length(i) == 0 ) & (length(j) == 0 ) ) finished=T
        if (length(i) > 0 ) m = m[ -i , ]
        if (length(j) > 0 ) m = m[ , -j ]
      }

      si = shannon.diversity(m)
        
      set = groundfish.db( "set.base" ) [, c("id", "yr")]
      set = merge( set, si, by=c("id"), sort=F, all.x=T, all.y=F )
      set$yr = NULL

      save(set, file=fn, compress=T)
      return( fn )
    }

    # ----------------------
    


    if (DS %in% c("set.partial") ) {
      
      # this is everything in groundfish just prior to the merging in of habitat data
      # useful for indicators db as the habitat data are brough in separately (and the rest of 
      # set.complete has not been refactored to incorporate the habitat data

      set = groundfish.db( "set.base" )

      # 1 merge catch
      set = merge (set, groundfish.db( "catchbyspecies" ), by = "id", sort=F, all.x=T, all.y=F )

      # 2 merge condition and other determined characteristics
      set = merge (set, groundfish.db( "set.det" ), by = "id", sort=F, all.x=T, all.y=F )
  
      # strata information
      gst = groundfish.db( DS="gsstratum" )
      w = c( "strat", setdiff( names(gst), names(set)) )
      if ( length(w) > 1 ) set = merge (set, gst[,w], by="strat", all.x=T, all.y=F, sort=F)
      set$area = as.numeric(set$area)
      
      return( set)
    
    }

    # ----------------------
    


    if (DS %in% c("set.complete", "set.complete.redo") ) {
      fn = file.path( project.directory("groundfish"), "data", "set.rdata")
      if ( DS=="set.complete" ) {
        load( fn )
        return ( set )
      }
        
      set = groundfish.db( "set.partial" )
      set = lonlat2planar(set, proj.type=p$internal.projection ) # get planar projections of lon/lat in km
      
	    # bring in time invariant features:: depth
			print ("Bring in depth")
      set$sdepth = habitat.lookup.simple( set,  p=p, vnames="sdepth", lookuptype="depth" )
      set$z = set$sdepth  # dummy var for later merges
      # set$z = log( set$z )
			
		  
      # bring in time varing features:: temperature
			print ("Bring in temperature")
      set$temp = habitat.lookup.simple( set,  p=p, vnames="temp", lookuptype="temperature.weekly" )

			# bring in all other habitat variables, use "z" as a proxy of data availability
			# and then rename a few vars to prevent name conflicts
			print ("Bring in all other habitat variables")
      
      sH = habitat.lookup.grouped( set,  p=p, lookuptype="all.data", sp.br=seq(5, 25, 50) )
      sH$z = log(sH$z) 
      sH = rename.df( sH, "z", "z.H" )
			sH$yr = NULL
			vars = names (sH )

      set = cbind( set, sH )
		
      # return planar coords to correct resolution
      set = lonlat2planar( set, proj.type=p$internal.projection )

      
      # 3 merge nss 
      loadfunctions( "sizespectrum")
      
      nss = sizespectrum.db( DS="sizespectrum.stats.merged", 
          p=list( spatial.domain="SSE", taxa="maxresolved", season="allseasons" ) )
      nss$strat = NULL
      if ( length(w) > 1 ) w = c( "id", setdiff( names(nss), names( set) ) )
      set = merge( set, nss[,w], by="id", sort=FALSE )
      rm (nss)

      
      # 4 merge sar
      loadfunctions( "speciesarea")
      sar = speciesarea.db( DS="speciesarea.stats.merged", 
          p=list( spatial.domain="SSE", taxa="maxresolved", season="allseasons" ) )
      if ( length(w) > 1 ) w = c( "id", setdiff( names(sar), names(set)) )
      set = merge( set, sar[,w], by="id", sort=FALSE )
      rm (sar)


      # 5 merge metabolic rates
      loadfunctions( "metabolism")
      meta = metabolism.db( DS="metabolism.merged", 
          p=list( spatial.domain="SSE", taxa="alltaxa", season="allseasons" ) )
      if ( length(w) > 1 ) w = c( "id", setdiff( names(meta), names(set)) )
      set = merge( set, meta[,w], by="id", sort=FALSE )
      rm (meta)

      # 6 merge species composition
      loadfunctions( "speciescomposition")
      sc = speciescomposition.db( DS="speciescomposition.stats.merged", 
          p=list( spatial.domain="SSE", taxa="maxresolved", season="allseasons" ) )
      w = c( "id", setdiff( names(sc), names(set)) )
      if ( length(w) > 1 ) set = merge( set, sc[,w], by="id", sort=FALSE )
      rm (sc)


      # 7 merge species diversity 
      si = groundfish.db( "shannon.information" )
      w = c( "id", setdiff( names(si), names(set)) )
      if ( length(w) > 1 ) set = merge( set, si[,w], by="id", sort=F )
      
    
      save ( set, file=fn, compress=F )
      return( fn )
    }
    

  }


