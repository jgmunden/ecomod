


# Solution via the simplest and most direct SSA -- Gillespie Alogrithm:  
# direct computation of everything -- no approximations



############## Model Parameters 
# Basic logistic with spatial processes  
# Using: logistic model as base
# dX/dt = rX(1-X/K)

  

  # set.seed(1)


  p = list()
 
  
  p$RE = function( X, b, d, K, dr, dc, np) {
    # propensity calculations .. returns as a vector of reaction process rates ...
    c(
      b[]*X[] ,
      (d[]+(b[]-d[])*X[]/K)[]*X[] ,
      dr[]*X[] ,
      dr[]*X[] ,
      dc[]*X[] ,
      dc[]*X[] 
    )
  }
  
  
  p$NU = list (
    # Changes associated with Reaction processes 
    # Lagrangian operator structure: 
    #   (row, column, operation) 
    # where row, column are relative to the focal cell 
    rbind( c(0,0,1) ),  # for the focal cell (0,0), the birth process: "bX"
    rbind( c(0,0,-1) ), # for the focal cell (0,0), the death process: "(d+(b-d)*X/K)*X""
    rbind( c(0,0,-1), c(-1,0,1) ), # "jump to adjacent row from the focal cell:: X[i] -> X[i+/-1] {dr0}
    rbind( c(0,0,-1), c(+1,0,1) ),
    rbind( c(0,0,-1), c(0,-1,1) ),  # same as above but now for column-wise jumps
    rbind( c(0,0,-1), c(0,+1,1) )
  )


  p$np = length(p$NU)  # no. of processes
     
  # pre-sorted data indices ... at most there will be 2 sets as all interactions are binary
  p$po = list(
    rep(1:6), # for 1 set
    c(t(matrix( rep(1:6,2), ncol=2)))  # for 2 sets 
  )
  

  p$nr = 100  
  p$nc = 100 
  p$nrc = p$nr*p$nc

  
  # pde related params
  p$eps  = 1e-6   # A in units of t/km^2 -- number below which abundance can be considered zero ~ 1 kg/ km^2 = 1g / m^2
  p$atol = 1e-9  # atol -- absolute error tolerance for lsoda
  p$rtol = 1e-9  # rtol -- relative error tolerance for lsoda
  

  # in the stochastic form:: using a birth-death Master Equation approach 
  # birth = b
  # death = d
  # carrying capacity = K
  # r = b-d >0 
 
   
  # model parameters
  p$b = 3 / 365 # birth rate
  p$d = 2 / 365 # death rate
  p$K = 1e6

  p$r = p$b - p$d  ## used by pde model
  

  # diffusion coef d=D/h^2 ; h = 1 km; per year (range from 1.8 to 43  ) ... using 10 here 
  # ... see b ulk estimation in model.lattice/src/_Rfunctions/estimate.bulk.diffusion.coefficient.r
  p$dr=10 
  p$dc=10 
  p$Da = matrix( ncol=p$nc, nrow=p$nr, data=10 ) 

  
  
  
  # model run dimensions and times
  p$n.times = 365  # number of censuses  
  p$t.end =   365   # in model time .. days
  p$t.censusinterval = p$t.end / p$n.times
  p$modeltimeoutput = seq( 0, p$t.end, length=p$n.times )  # times at which output is desired .. used by pde
 
  # calc here to avoid repeating calculations
  p$nr_1 = p$nr-1
  p$nc_1 = p$nc-1

  # rows are easting (x);  columns are northing (y) --- in R 
  # ... each cell has dimensions of 1 X 1 km ^2


  attach(p) 
    out = array( 0, dim=c( nr, nc, n.times ) )
    X = array( 0, dim=c(nr, nc ) ) 
   
    debug = TRUE
    if (debug) {
      rwind = floor(nr/10*4.5):floor(nr/10*5.5)
      cwind = floor(nc/10*4.5):floor(nc/10*5.5)
      X = array( 0, dim=c(nr, nc ) ) 
      X[ rwind, cwind ] = round( K * 0.8 )
    }
   
    # initiate P the propensities 
    P = array(  RE( X[], b, d, K, dr, dc, np ) , dim=c( nr, nc, np ) )
    p$nP = length(P)
    P.total = sum(P[])
  detach(p)
  
    
  
  
  ####################################################
  ################# simulation engine ################
  ####################################################



  simtime = tio = tout = nevaluations = 0
 

  attach(p)

    repeat {
      
      prop = .Internal(pmax(na.rm=FALSE, 0, P[]/P.total  ))   # using .Internal is not good syntax but this gives a major perfance boost > 40%
      j = .Internal(sample( nP, size=1, replace=FALSE, prob=prop ) )

      # remap random element to correct location and process
      jn  = floor( (j-1)/nrc ) + 1  # which reaction process
      jj = j - (jn-1)*nrc  # which cell 

      # focal cell coords
      cc = floor( (jj-1)/nr ) + 1
      cr = jj - (cc-1) * nr 

      # determine the appropriate operations for the reaction and their 'real' locations
      o = NU[[ jn ]]  
      no = dim(o)[1]
      
      ro = cr + o[,1] 
      co = cc + o[,2]
      
      # ensure boundary conditions are sane
      ro[ro < 1] = 2
      ro[ro > nr] = nr_1
      
      co[co < 1] = 2
      co[co > nc] = nc_1 
      
      # build correctly structured indices
      cox = cbind( ro, co)  ## in X
      cop = cbind( ro, co, po[[no]] )   # in P

      # update state (X) 
      Xcx = X[cox] + o[,3]   # Xcx is a temp copy to skip another lookup below
      Xcx[Xcx<0] = 0
      X[cox] = Xcx
  
      # update propensity in focal cells 
      dP = RE( Xcx, b, d, K, dr, dc, np )
      P.total = P.total + sum( dP - P[cop] )
      P[cop] = dP

      nevaluations = nevaluations + 1
      simtime = simtime - (1/P.total) * log( runif( 1))   # ... again to optimize for speed
      if (simtime > t.end ) break()
      if (simtime > tout) {
        tout = tout + t.censusinterval 
        tio = tio + 1  # time as index
        out[,,tio] = X[]
        P.total = sum(P[]) # reset P.total to prevent divergence due to floating point errors
        cat( paste( tio, round(P.total), round(sum(X)), nevaluations, Sys.time(), sep="\t\t" ), "\n" )
        image( X[], col=heat.colors(100)  )
      }
    } # end repeat
  
  detach(p)



  plot( seq(0, t.end, length.out=n.times), out[1,1,], pch=".", col="blue", type="b" ) 
  







  ### ---------------------------------------
  ### Compare with a PDE version of the model 

  p$init = loadfunctions( c( "model.pde" )  )
  p$libs = loadlibraries ( c( "deSolve", "lattice") )


  A = array( 0, dim=c(p$nr, p$nc ) ) 
  debug = TRUE
  if (debug) {
    rwind = floor(p$nr/10*4.5):floor(p$nr/10*5.5)
    cwind = floor(p$nc/10*4.5):floor(p$nc/10*5.5)
    A = array( 0, dim=c(p$nr, p$nc ) ) 
    A[ rwind, cwind ] = round( p$K * 0.8 )
    # X[,] = round( runif(nrc) * K )
  }
 
  
  p$parmeterizations = c( "reaction", "diffusion.second.order.central") 

  
  out <- ode.2D(  times=p$modeltimeoutput, y=as.vector(A), parms=p, dimens=c(p$nr, p$nc),
    func=single.species.2D.logistic, 
    method="lsodes", lrw=1e8,  
    atol=p$atol 
  )
 

  image.default( matrix(out[365,2:10001], nrow=100), col=heat.colors(100) )

  diagnostics(out)
  
  plot(p$modeltimeoutput, apply(out, 1, sum))
  
  image(out)
  hist( out[1,] )

  select <- c(1, 4, 10, 20, 50, 100, 200, 500 )
  image(out, xlab = "x", ylab = "y", mtext = "Test", subset = select, mfrow = c(2,4), legend =  TRUE)
 







