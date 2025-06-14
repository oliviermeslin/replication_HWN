
## Fit tuned models for JEP paper
# Jann Spiess, March/April 2017

# Based on tuning results (see separate file)


# Load data

rawdata <- list("id",df=ahs,vars=vars,getformula=getformula)
#rawdata <- readRDS(file=rname)
instruction <- list(df=rawdata$df,settings=list(LHS="l_km2pris",RHS=rawdata$vars))

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


# Fit models
#thisname <-paste("predict")

olsbaseline <- predictiveanalysis(df=instruction$df, LHS=instruction$settings$LHS, RHS=instruction$settings$RHS,
                          holdoutvar="holdout", holdout=T,
                          predictors=list(ols=ols()),
                          nfold = 8)


# Ensemble based on individual tuning results (calculates weights)
ensemblefit <- predictiveanalysis(df=instruction$df, LHS=instruction$settings$LHS, RHS=instruction$settings$RHS,
                                  holdoutvar="holdout", holdout=T,
                                  predictors=list(rf=rf(nodesize=4,ntree=100,pmtry=0.4,numericfactors=F,bootstrap=T),
                                                  lasso=elnet(lambdas=0, alpha=c(1), interactions=""),
                                                  tree=regtree(minbuckets=c(1),maxdepths=c(15),numericfactors=F)
                                  ),
                                  nfold = 8)


fulldata <- olsbaseline$returndf[,c("l_km2pris","holdout")]
fulldata$ensemble_prediction <- ensemblefit$returndf$prediction
fulldata$ols_prediction<-olsbaseline$returndf$prediction
fulldata$id<-newhouse$id
#saveRDS(fulldata,file=rname)

library(foreign)
write.dta(fulldata,file=dtaname)
