

    ### ---- this is broken right now as 
    ### RE has been altered to work more autonomously ... 
    ### not fixed right now as bigmatrix does not seem to provide any speed benefits
    ### if fixing, make a local copy of relevant state space and then send to RE
    ### ... it used to be this:
       
        # propensity  (reaction rate) calculating function .. returns as a vector of reaction process rates ...
#        RE = function( p, x, ix ) {
#          with( p, { 
#            XX = x[ix]
#            bb = b[ix]
#            dd = d[ix]
#            KK = K[ix]
#            c( bb*XX ,
#              (dd+(bb-dd)*XX/KK)*XX 
#            )
#          })
#        }



 ssa.engine.parallel.bigmemory = function( p ) { 

  p <- within (p, { 
               
    simtime = tio = tout = nevaluations = 0
                  
    cl = makeCluster( spec=cluster, type=cluster.message.system )
    ssplt = lapply( clusterSplit( cl, 1:nsimultaneous.picks ), function(i){i} )

    while( simtime <= t.end ) {
     
      prop = .Internal( pmax( na.rm=FALSE, 0, P[]/P.total))
      J = random_deviate_uniform_weighted_rcpp( nsimultaneous.picks, prop )
      time.increment = random_deviate_exponential_rcpp( nsimultaneous.picks, P.total)

      psums = clusterApplyLB( cl=cl, x=ssplt, J=J, p=p, 
        
        fun = function( ip=NULL, J, p ) { 
        
          require(bigmemory)

          p <- within( p, {  # watch out ... a nested p ... only changing p$ppp

            X <- attach.big.matrix( bm.X )
            P <- attach.big.matrix( bm.P )

            if (is.null(ip)) ip =1:length(J)

            # ip = as.numeric(ip) 
            ppp = list()

            for ( iip in ip ) { 
              j = J[iip]
             
              # remap random index to correct location and process
              jn  = floor( (j-1)/nrc ) + 1  # which reaction process
              jj = j - (jn-1)*nrc  # which cell 
              cc = floor( (jj-1)/nr ) + 1
              cr = jj - (cc-1) * nr 
              
              # determine the appropriate operations for the reaction
              o = NU[[jn]] 
              no = dim(o)[1]
               
              # id coord(s) of reaction process(es) and ensure boundary conditions are sane
              ro = cr + o[,1] 
              co = cc + o[,2]
              ro[ro < 1] = 2
              ro[ro > nr] = nr_1
              co[co < 1] = 2
              co[co > nc] = nc_1 

              # update state (X) 
              Pchange = 0
              for ( l in 1:no ) {
                rr = ro[l]
                cc = co[l]
                
                Xcx = X[ rr, cc] + o[l,3]    ## bigmatrix uses a different refercing system than matrix
                Xcx[ Xcx<0 ] = 0
                X[rr,cc] = Xcx
              
                # update propensity in focal and neigbouring cells 
                jcP = cc + c(0: (np-1))*nc  # increment col indices depending upon reaction process
                dP = RE( p, X, cox )
                Pchange = Pchange + sum( dP - P[ rr, jcP ] )
                P[rr,jcP ] = dP
              }

              ppp[[iip]] = Pchange
            }

        })
        
        return(p$ppp) 

      }) # end clusterapply

      P.total = P.total + sum( .Internal(unlist( psums, TRUE, FALSE )) )
      nevaluations = nevaluations + nsimultaneous.picks
      simtime = simtime + sum(time.increment)   
        
      if (simtime > tout ) {
            
        X <- attach.big.matrix( bm.X, path=outdir)   ### might need to remove the path=outdir if using RAM-backed bigmemory object
        P <- attach.big.matrix( bm.P, path=outdir)

        tout = tout + t.censusinterval 
        tio = tio + 1  # time as index
        ssa.db( p=p, DS="save", out=as.matrix(X[]), tio=tio )  
        # print( P.total - sum(P[]) )
        P.total = sum(P[]) # reset P.total to prevent divergence due to floating point errors
        if (monitor) {
          P = array( RE( p, X, 1:nrc), dim=c( nr, nc, np ) )
          cat( paste( tio, round(P.total), round(sum(X[])), nevaluations, Sys.time(), sep="\t\t" ), "\n" )
          image( X[], col=heat.colors(100)  )
        }
      }

    } # end repeat
    
    stopCluster( cl )

  })

  return (p )

 }


