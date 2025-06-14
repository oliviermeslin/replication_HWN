## Tune and fit models for JEP paper
# Jann Spiess, March/April 2017
# Modified by Martin Blomhoff Holm, April 2018


# Load environment

thisname <- "house_tune_40_1"

# Load base data

rawdata <- list("id",df=ahs,vars=vars,getformula=getformula)
localahs <- rawdata$df
ahsvars <- rawdata$vars
getformula <- rawdata$getformula

#rawdata <- readRDS(file=rname)
#instruction <- list(df=rawdata$df,settings=list(LHS="l_km2pris",RHS=rawdata$vars))


# Load prediction algorithms
#source("/ssb/stamme01/wealth5/prog/rek/prepare/housing/ml/predictiontools/algo_boosting.R")  # Boosted tree
source("/ssb/stamme01/wealth5/prog/rek/prepare/housing/ml/predictiontools/algo_linear.R")  # OLS et al.
source("/ssb/stamme01/wealth5/prog/rek/prepare/housing/ml/predictiontools/algo_penalizedlinear.R")  # Elastic net (incl. LASSO)
source("/ssb/stamme01/wealth5/prog/rek/prepare/housing/ml/predictiontools/algo_randomforest.R")  # Random forest
source("/ssb/stamme01/wealth5/prog/rek/prepare/housing/ml/predictiontools/algo_tree.R")  # Regression tree

# Load tools
source("/ssb/stamme01/wealth5/prog/rek/prepare/housing/ml/predictiontools/tool_analysis.R")  # Prediction output analysis
source("/ssb/stamme01/wealth5/prog/rek/prepare/housing/ml/predictiontools/tool_dataprep.R")  # Data preparation
source("/ssb/stamme01/wealth5/prog/rek/prepare/housing/ml/predictiontools/tool_prediction.R")  # Main prediction analysis routine
source("/ssb/stamme01/wealth5/prog/rek/prepare/housing/ml/predictiontools/tool_predictionhelpers.R")  # Tuning and ensemble tools

# Load interface
source("/ssb/stamme01/wealth5/prog/rek/prepare/housing/ml/predictiontools/interface_predictiveanalysis.R")  # Main interface for local analysis of ensembles
source("/ssb/stamme01/wealth5/prog/rek/prepare/housing/ml/predictiontools/interface_serverparallel.R")  # Additional tools for manual parallelization


# Random forest -- tune on server

# Prepare data locally
for (j in 1:4){
  parallelprep(df=localahs, LHS="l_km2pris", RHS=ahsvars,
               holdoutvar="holdout",
               predictor=rf(nodesizes=c(3),ntrees=c(20,50,75,100),pmtrys=c(0.4), numericfactors=T,bootstrap=T),
               nfold = 8,
               savename=paste0(thisname,j,"-rfin"))
# Example execution of a single node
parallelsinglepredict(savename=paste0(thisname,j,"-rfin"),iteration=j)
  # For full tuning, run through as many iterations
 # as there are combinations of tuning parameters
  # Analysis after all nodes have run
tunedrf <- parallelanalysis(savename=paste0(thisname,j,"-rfin"),fitit=T)
saveRDS(tunedrf,file=paste0(thisname,j,"-rfout"))
}

#treedepth <-predictiveanalysis(df=localahs,LHS="l_km2pris",RHS=ahsvars,
#                               holdoutvar="holdout",
#                               predictor=list(tree=regtree(minbuckets=c(1),maxdepths=c(20,22,24,26),numericfactors=F)), nfold=8)

#lassoplain <-  predictiveanalysis(df=localahs,LHS="l_km2pris",RHS=ahsvars,
#                                  holdoutvar="holdout",
#                                  predictor=list(elnet=elnet(lambdas=exp(-seq(3,8,by=.5)),alpha=c(0,.2,.4,.6,.8,1), interactions="")),nfold=8)

 



