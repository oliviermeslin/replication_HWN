rm(list=ls())

dbase<-paste("/ssb/stamme01/wealth5/wk48/rek/prepare/housing/ml/ml_sample_",j,".csv" ,sep="")
dtaname<-paste("/ssb/stamme01/wealth5/wk48/rek/prepare/housing/ml/ml_result_",j,".dta" ,sep="")

source("/home/onyxia/work/replication_HWN/Hedonic Housing Replication/ML/1_dataprep.R")
source("/home/onyxia/work/replication_HWN/Hedonic Housing Replication/ML/2_fitmodel.R")

