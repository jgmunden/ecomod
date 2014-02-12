
  # --------------------------
  # 0. Initialise work space 

  loadlibraries( "mgcv", "chron", "lattice"  ) 
	loadfunctions( "snowcrab", functionname="initialise.local.environment.r") 



  # --------------------------
  # 1. Define some additional starting parameters for debugging
  #    choose various over-rides: these are initially defined in parameters.r
  
  p$regions = c("cfa4x", "cfanorth","cfasouth" )
  
  p$vars.to.model = c("R0.mass",  "R1.no")
  p$vars.to.model = c("R0.mass", "R0.no", "R1.no", "totno.female.primiparous","totno.female.multiparous", "totno.female.berried", "fecundity","totno.female.imm", "totno.male.imm" )  
  p$vars.to.model = c("R0.no", "R1.no", "totno.female.primiparous","totno.female.multiparous", "totno.female.berried", "fecundity","totno.female.imm", "totno.male.imm" )  
  

  
  debug = F
  if (debug) {
    # identify areas to interpolate
      p$regions = c("cfanorth")
      p$regions = c("cfa4x", "cfanorth","cfasouth" )
      p$regions = c("cfa4x", "cfanorth","cfasouth", "cfaall" )
    
    # identify variables to interpolate and create abundance estimates
      
      p$vars.to.model = c("R0.no", "R1.no")
      p$vars.to.model = c("R0.mass",  "R1.no")
      p$vars.to.model = c("R1.no")
      p$vars.to.model = c("R0.mass")

      p$vars.to.model = c("male.large.mass", "male.small.mass", "female.large.mass", "female.small.mass" )
      
      p$vars.to.model = c("R0.mass", "R0.no", "R1.no", "totno.female.primiparous","totno.female.multiparous", "totno.female.berried", "fecundity","totno.female.imm", "totno.male.imm" ) 
      
      p$vars.to.model = c("R0.mass", "R0.no", "R1.no", "R2.no", "R3.no", "R4.no", "R5p.no", 
        "totno.female.berried", "totno.female.imm", "totno.female.mat", "totno.female.primiparous","totno.female.multiparous",
        "fecundity", "totno.male.com", "totno.male.mat", "totno.male.imm","dwarf.no", "totno.male.skip.moulter", "totno.male.com.CC5"   )

    # modify cluster requirements
      p$do.parallel =F
      p$clusters = rep("localhost",8)
      # p$clusters = rep("tethys", 7 )
      # p$clusters = rep("kaos",23 )
      # p$clusters = rep("nyx",24 )
      # p$clusters = rep("tartarus",24 )
  }


  # -----------------
  # 2. Abundance estimation via GAM   

    # create some intermediary files to speed up analysis

    habitat.model.db( DS="large.male.auxillary.data.redo", p=p )


    if (abundance.estimation.via.GAM) {
      
      # Define controlling parameters 
        
      p$model.type = "gam.full" # choose method for habitat model :
      p$habitat.threshold.quantile = 0.05 # quantile at which to consider zero-valued abundance
      p$optimizers = c( "nls", "perf", "bam", "bfgs", "newton", "Nelder-Mead" )  # used by GAM
			p$prediction.weekno = 39 # predict for ~ Sept 1 
      p$threshold.distance = 15  # limit to extrapolation/interpolation in km
     
      p$use.annual.models = TRUE  ## <<<<< new addition


      # ---------------------
      # model habitat and intermediate predictions
      # ~ 1 MB / process  .. use all 24 CPUs
      # Parameterize habitat space models for various classes, 
      # see: habitat.model.db( DS="habitat.redo" ... )
      
      p$clusters = rep( "localhost", 2)  # only need 2 if 2 vars are being modelled
      p$clusters = rep( "localhost", 8)  
      p$clusters = rep( "localhost", 24)  
      # p$clusters = c( rep( "nyx.beowulf", 24), rep("tartarus.beowulf", 24), rep("kaos", 24 ) )
      
      if ( p$use.annual.models ) {
         p = make.list( list(v=p$vars.to.model, years=p$years.to.model ), Y=p )
         habitat.model.db( DS="habitat_annual.redo", p=p )   
         # parallel.run( clusters=p$clusters, n=p$nruns, habitat.model.db, DS="habitat_annual.redo", p=p ) 
       } else { # annual representation of habitat response surfaces
         p = make.list( list(v=p$vars.to.model ), Y=p )
         habitat.model.db( DS="habitat.redo", p=p )   
         # parallel.run( clusters=p$clusters, n=p$nruns, habitat.model.db, DS="habitat.redo", p=p ) 
      }


      # ---------------------
      testing.environmentals.only = FALSE
      if ( testing.environmentals.only ) {
        # habitat surface area estimation for R0.mass from 1970 to present --- for timeseries and direct prediction maps
        p$clusters = c( rep( "localhost", 20) )
        # p$clusters = rep( "localhost", 2)  
        p = make.list( list(v=c("R0.mass.environmentals.only", "R0.mass") ), Y=p )
          habitat.model.db (DS="habitat.redo", p=p ) 
        p = make.list( list(y=1970:p$current.assessment.year, v=c("R0.mass.environmentals.only", "R0.mass") ), Y=p )
          parallel.run( clusters=p$clusters, n=length(p$yearswithTdata), snowcrab.habitat.db, p=p ) 
        # or
        # snowcrab.habitat.db (p=p) -- working?    
      }      


      # ---------------------
      # model abundance and intermediate predictions 
      if ( p$use.annual.models ) {
        p = make.list( list(v=p$vars.to.model, years=p$years.to.model ), Y=p )
        habitat.model.db( DS="abundance_annual.redo", p=p ) 
        # parallel.run( clusters=p$clusters, n=p$nruns, habitat.model.db, DS="abundance_annual.redo", p=p)
      } else {    
        p = make.list( list(v=p$vars.to.model ), Y=p )
        habitat.model.db( DS="abundance.redo", p=p) 
        # parallel.run( clusters=p$clusters, n=p$nruns, habitat.model.db, DS="abundance.redo", p=p )
      } 
      
      
      # ---------------------
      # compute posterior simulated estimates using habitat and abundance predictions 
      # and then map, stored in R/gam/maps/

      p$vars.to.model= "R0.mass"
      p$nsims = 2000 # n=1000 ~ 1 , 3 GB/run for sims; estim ~ 8 GB (upto 10)  
      # p$nsims = 1000 # n=1000 ~ 1 , 3 GB/run for sims; estim ~ 8 GB (upto 10)   --< FOR R0.mass ...
      p$ItemsToMap = c( "map.habitat", "map.abundance", "map.abundance.estimation" )

      p$clusters = c( rep( "nyx.beowulf",2), rep("tartarus.beowulf",2), rep("kaos", 2 ) )
      p = make.list( list(y=p$years.to.model, v=p$vars.to.model ), Y=p )
      
			# interpolation.db ( DS="interpolation.redo", p=p )
      # or:
      parallel.run( clusters=p$clusters, n=p$nruns, interpolation.db, DS="interpolation.redo", p=p )

      # collect all results into a single file and return: 
      K = interpolation.db( DS="interpolation.simulation", p=p  ) 
      table.view( K )      
 
      abund.v = c("yr", "total", "lbound", "ubound" )

      Pmeta = K[ which( K$region=="cfanorth") ,]
      Pmeta = K[ which( K$region=="cfasouth") ,]
      Pmeta = K[ which( K$region=="cfa4x") ,]
      Pmeta = K[ which( K$region=="cfaall") ,]
     
      outdir = file.path( project.directory("snowcrab"), "R", "gam", "timeseries")
      rr = "cfanorth"
      rr = "cfasouth"
      rr = "cfa4x"
      rr = "cfaall"

      vv = "R0.mass"
      Pmeta = K[ which( as.character(K$vars)==vv & as.character(K$region)==rr ) ,abund.v ]
      figure.timeseries.errorbars( Pmeta, outdir=outdir, fname=paste(vv, rr, sep=".") )
      
      # TODO :: MUST determine potential habitat stats in historical data ( 1950 to present ) for timeseries plots
      # use "prediction.surface( p, DS="annual.redo", vclass=vclass )" as an example

      ### --------- prediction success:
      
      set = snowcrab.db( DS="set.logbook" )
      set = set[ set$yr %in% p$years.to.model ,]
      set$total.landings.scaled = scale( set$total.landings, center=T, scale=T )
      set = presence.absence( set, "R0.mass", p$habitat.threshold.quantile )  # determine presence absence(Y) and weighting(wt)
      set$weekno = floor(set$julian / 365 * 52) + 1
      set$dt.seasonal = set$tmean -  set$t 
      set$dt.annual = set$tmean - set$tmean.cl
      

      if ( p$use.annual.models ) {
        for ( yr in sort(unique( set$yr) ) ) {
          o = which( set$yr==yr)
          if (length(o) < 5 ) next()
          set$predicted.pa = NA
          set$predicted.abund = NA
          H = habitat.model.db( DS="habitat", p=p, yr=yr, v="R0.mass" )
          set$predicted.pa[o] = predict( H, set[o,], type="response" )
          A = habitat.model.db( DS="abundance", p=p, yr=yr, v="R0.mass" )
          set$predicted.abund[o] = predict( A, set[o,], type="response" )
        }

      } else {
          H = habitat.model.db( DS="habitat", p=p, v="R0.mass" )
          set$predicted.pa = predict( H, set, type="response" )
          A = habitat.model.db( DS="abundance", p=p, v="R0.mass" )
          set$predicted.abund = predict( A, set, type="response" )
      }


      set$predicted.R0.mass = set$predicted.abund
      set$predicted.R0.mass[ which( set$predicted.pa < 0.5) ] = 0

      amin = min( set$predicted.R0.mass[ which( set$predicted.R0.mass >0 )])
      bmin = min( set$R0.mass[ which( set$R0.mass >0 )])

      plot( set$predicted.R0.mass , set$R0.mass )
      
      cor( set$predicted.R0.mass , set$R0.mass )^2  # 0.7870114 !!
      
      save ( set, file="/home/jae/tmp/set.test.rdata")
      
    }



    ---


    y = 2012
    v = "R0.mass"

        PS = habitat.db ( DS="complete", year=y, p=p )
				PS$weekno = p$prediction.weekno  # must be same as above
				PS$t = NA
      
        PST = temperature.interpolations( p=p, DS="spatial.interpolation", yr=y  )
				if (is.null(PST)) next ()
				
        PS$t = PST[, p$prediction.weekno ]
        PS$t[ which(PS$t < -2) ] = -2
			  PS$t[ which(PS$t > 30) ] = 30 

        iitna = which( ! is.finite( PS$t ) ) 
        if (length(iitna)>0) PS$t[iitna] = PS$tmean[iitna]

        PS$z = log(PS$z)
        PS$dt.seasonal = PS$tmean - PS$t 
        PS$dt.annual = PS$tmean - PS$tmean.cl
        PS$sa = 1

				# posterior simulations
				Hmodel = habitat.model.db( DS="habitat", v= v )
      
        PS$predicted.pa = predict( Hmodel, PS, type="response" )
      	
        levelplot( predicted.pa ~ plon + plat, data=PS, aspect="iso", title=paste("Habitat", y) )
       

        Amodel = habitat.model.db( DS="abundance", v= v )
      
        PS$abundance = predict( Amodel, PS, type="response" )
      	
        levelplot( log10(abundance) ~ plon + plat, data=PS, aspect="iso", title=paste("Abundance", y)  )
       

        present = which(PS$predicted.pa > p$habitat.threshold.quantile )
        PS$pa = 0
        PS$pa[present] = 1
        
        PS$combined = PS$abundance * PS$pa
        levelplot( log10(combined) ~ plon + plat, data=PS, aspect="iso", title=paste("Abundance", y)  )
  


