oceans.activity.mapper<-function(
  #default values
  dsn         = oracle.dsn,
  user        = oracle.oceans.user,
  pw          = oracle.oceans.password,
  debug       = F, 
  last_n_days = 30,                          
  startdate   = NULL, 
  enddate     = NULL,
  vessel_list = c(),          
  datawindows = c("Lophelia CCA","Northeast Channel","Gully","VazellaEmerald","St Anns Bank Inventory Box","Musquash")
  ){

options(stringsAsFactors=F)
options(warn=-1)
workdir <- file.path(project.directory('vdc.push.reports.oceans'),"src" )
setwd(workdir)
#tmpdir      <- file.path( workdir,"tmp" )
savelocation<- file.path( workdir,"output")

map.vessels<-function(dsn, user, pw, datawindows, last_n_days, startDate, endDate, vessel_list,workdir,savelocation){
      if (exists("dfKeep")&&debug==T){
        cat("-------> Using existing data <--------\n")
        setwd(workdir)
        the.df<-dfKeep
        the.df<-c(the.df,workdir,savelocation )
        results1<-oceans.make.kml(the.df)
      }else{
        cat("Getting new data...\n")
        for (i in 1:length(datawindows)){
          cat(paste("Starting ", datawindows[i], "\n"))
          setwd(workdir)
          the.df<-oceans.get.data(dsn, user, pw, datawindows[i], last_n_days, startdate, enddate, vessel_list)
          the.df<-c(the.df,workdir,savelocation )
          results1<-oceans.make.kml(the.df)
          if (length(datawindows>1)){
            cat(paste("Finished ", datawindows[i],"\n"))
          }
          cat("Finished Request\n")
        }
      }
    }
map.vessels(dsn, user, pw, datawindows, last_n_days, startdate, enddate, vessel_list,workdir,savelocation)
}