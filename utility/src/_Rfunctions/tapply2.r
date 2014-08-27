

  tapply2 = function (x, indices, func, var, newvars, ...) {
    # fast
    x = convert2factor(x, indices)
    y = as.data.frame.table( tapply( x[,var], x[,indices], FUN=func, simplify=T, ... ) )
    names(y) = c(indices, newvars)
    y = factor2character (y, indices)
    return (y)
  }


