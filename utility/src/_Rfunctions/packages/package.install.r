 
	# To update/install useful packages
  #	loadfunctions( "utility")
  # package.install ()
  # if there are problems, use a direct download from R-forge:
  # install.packages("foo", repos="http://R-Forge.R-project.org")

	package.install = function( X="all", override=F ) {
		
		toinstall = package.list( X=X )
			ii = 1:nrow(toinstall)
			for (p in ii) try( install.packages ( toinstall$pkgs[p], repos=toinstall$repos[p], dependencies=T ) )

	}
  



