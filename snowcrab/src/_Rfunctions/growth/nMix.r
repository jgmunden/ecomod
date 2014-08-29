nMixNormal <- function(x,seqK=1:8,...,aic.threshold=2,plot=T,mode.threshold=5) {
		#seqK is the sequence of components
		require(mixtools)
		loglikes <- vector(length=length(seqK))
		aic <- vector(length=length(seqK))
		x <- na.omit(x)
		n <- length(x)
		
		# k=1 needs special handling
		for(k in seqK) {
			if(k==1) {
				mu<-mean(x) # MLE of mean
				sigma <- sd(x)*sqrt((n-1)/n) # MLE of standard deviation
				loglikes[1] <- sum(dnorm(x,mu,sigma,log=TRUE))
				aic[k] <- aicc(lL=loglikes[k],k=k*3-1,n=n)
				} else {
			mixture <- normalmixEM(x,k=k,maxit=1000,epsilon=1e-2,arbvar=T)
			loglikes[k] <- loglikeMix(x,mixture=mixture)
			aic[k] <- aicc(lL=loglikes[k],k=k*3-1,n=n)
			}
			}
	if(plot) {
		par(mar=c(5,6,1,6))
		plot(seqK,loglikes,type='b')
		par(new=T)
		plot(seqK,aic,type='b',yaxt='n',ylab='')
		axis(side=4,round(seq(min(aic),max(aic),length.out=4),0))
	}
	nk <- findMinAIC(x=aic,thresh=aic.threshold)	
	if(nk>1) {
	mixture <- normalmixEM(x,k=nk,maxit=1000,epsilon=1e-2,arbvar=T)
	o <- sort(mixture$mu)
	if(any(o[2:nk]-o[1:nk-1]<mode.threshold)) {
	nMix(x=x,seqK=seqK,aic.threshold=aic.threshold,plot=plot,mode.threshold=mode.threshold)
	}
	} else {
	
	mixture=c(mu=mean(x),sigma = sd(x)*sqrt((n-1)/n),lambda=1)
	}

	return(mixture)
}