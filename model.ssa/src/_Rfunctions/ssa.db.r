

  ssa.db = function( p=NULL, ptype="debug", out=NULL, tio=NULL, rn=NULL, outdir=NULL ) {
    
    odir = file.path( outdir, "individual.runs", rn ) 
    fn = file.path( odir, paste( "out", tio, "rdata", sep="." )) 
    
    if ( ptype=="save" ) {
      if (! file.exists(odir) ) dir.create( odir, recursive=TRUE, showWarnings=FALSE  )
      save (out, file=fn, compress=TRUE )
      return (fn)
    }


    if ( ptype=="load" ) {
      out = NULL
      if (file.exists( fn) ) load (fn )
      return(out)
    }
      

    if ( ptype=="load.all" ) {
      out = array( NA, dim=c(p$nr, p$nc, p$n.times)  )  
      for ( i in 1:p$n.times ) {
        X = ssa.db( ptype="load", tio=i )
        if ( !is.null(X) ) out[,,i] = X 
      }
      return(out)
    }
     
    
    if ( ptype=="restart" ) {
      out = within(p, {
        # initiate state space with some random noise and a core area in the center of the system
        X = ssa.db( ptype="load", tio=tio )
        P = RE( p, X ) 
        P.total = sum( P[] )
        list( X=X, P=P, P.total=P.total)
      })
      return(out)
    }
     
    
    if ( ptype=="debug" ) {
      out = within( p, {
        # initiate state space with some random noise and a core area in the center of the system
        X = array( 0, dim=c( nr, nc ) ) 
        rwind = floor(nr/10*4.5):floor(nr/10*5.5)
        cwind = floor(nc/10*4.5):floor(nc/10*5.5)
        X[ rwind, cwind ] = round( K[rwind, cwind ] * 0.8 )
        P = array( RE( p, X ) ,  dim=c( nr, nc, np ) ) 
        P.total = sum( P[] )
        list( X=X, P=P, P.total=P.total)
      })
      return(out)
    }    
    
    
    if ( ptype=="debug.big.matrix.rambacked" ) {
      # as in the basic "debug" form but using a bigmemory RAM object 
      # .. make sure SHM (shared memory is used an d properly configured on the OS) in /etc/fstab
      require(bigmemory)

      out = within( p, {
        X = big.matrix( nrow=nr, ncol=nc, init=0 ) 
        rwind = floor(nr/10*4.5):floor(nr/10*5.5)
        cwind = floor(nc/10*4.5):floor(nc/10*5.5)
        X[ rwind, cwind ] = round( K[rwind, cwind ] * 0.8 )
        P = big.matrix( nrow=nr, ncol=nc*np, type='double', init=RE( p, X[] )  ) 
        P.total = sum( P[] )
        bm.P = describe( P )
        bm.X = describe( X )
        list( P.total=P.total, bm.P=bm.P, bm.X=bm.X )  
      })
      return(out)
    }
 
    
    if ( ptype=="debug.big.matrix.filebacked" ) {
      # as in the basic "debug" form but using a bigmemory RAM object 
      require(bigmemory)

      out = within( p, {
        X = big.matrix( nrow=nr, ncol=nc, type="double", init=0, 
          backingpath=outdir, backingfile="ssa.X.bm.tmp", descriptorfile="ssa.X.bm.desc" ) 
        rwind = floor(nr/10*4.5):floor(nr/10*5.5)
        cwind = floor(nc/10*4.5):floor(nc/10*5.5)
        X[ rwind, cwind ] = round( K[rwind, cwind ] * 0.8 )
        P = big.matrix( nrow=nr, ncol=nc*np, type='double', init=RE( p, X[] ),
          backingpath=outdir, backingfile="ssa.P.bm.tmp", descriptorfile="ssa.P.bm.desc" ) 
        P.total = sum( P[] )
        bm.P = describe( P )
        bm.X = describe( X )
        list( P.total=P.total, bm.P=bm.P, bm.X=bm.X )  
      }) 
      return(out)
    }

  }



