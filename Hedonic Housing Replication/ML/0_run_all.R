rm(list=ls())

for (j in 1:44){
      dbase<-paste("/ssb/stamme01/wealth5/wk48/rek/prepare/housing/ml/ml_sample_",j,".csv" ,sep="")
      dtaname<-paste("/ssb/stamme01/wealth5/wk48/rek/prepare/housing/ml/ml_result_",j,".dta" ,sep="")
      if (j >= 42){
              source("/ssb/stamme01/wealth5/prog/rek/prepare/housing/ml/1_dataprep_cabin.R")} 
      else {
      source("/ssb/stamme01/wealth5/prog/rek/prepare/housing/ml/1_dataprep.R")} 
      source("/ssb/stamme01/wealth5/prog/rek/prepare/housing/ml/2_fitmodel.R")
      rm(list=ls())
}

