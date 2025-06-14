# Jann Spiess, March 2017
# Modified by Martin Blomhoff Holm, April 2018

# structure of the data: 

# Read in data
newhouse <- read.csv(file=dbase, quote="\"'")

# Make some factors factors, numeric numeric
newhouse$etasje_type2 <- as.factor(newhouse$etasje_type2)
#newhouse$kommune <- as.factor(newhouse$kommune)
newhouse$fylke <- as.factor(newhouse$fylke)
newhouse$tomtsize <- as.factor(newhouse$tomtsize)
newhouse$aargammel_truc <- as.factor(newhouse$aargammel_truc)
newhouse$antall_rom_trunc <- as.factor(newhouse$antall_rom_trunc)
newhouse$year <- as.factor(newhouse$year)
newhouse$etasjenr <- as.factor(newhouse$etasjenr)
newhouse$leilighetsnr <- as.factor(newhouse$leilighetsnr)
newhouse$tag_fritt_salg <- as.factor(newhouse$tag_fritt_salg)
newhouse$bygg_bygningstype <- as.factor(newhouse$bygg_bygningstype)
#newhouse$kjokkenkode <- as.factor(newhouse$kjokkenkode)
newhouse$bydel <- as.factor(newhouse$bydel)
newhouse$density <- as.factor(newhouse$density)
newhouse$garage <- as.factor(newhouse$garage)
newhouse$borett <- as.factor(newhouse$borett)
newhouse$quarter<-as.factor(newhouse$quarter)
newhouse$holdout<-as.logical(newhouse$holdout)
newhouse$id <- as.integer(newhouse$id)

newhouse$l_km2_bolig <- as.numeric(as.character(newhouse$l_km2_bolig))
newhouse$l_km2_bolig2 <- as.numeric(as.character(newhouse$l_km2_bolig2))
newhouse$l_km2_bolig3 <- as.numeric(as.character(newhouse$l_km2_bolig3))
newhouse$l_km2pris <- as.numeric(as.character(newhouse$l_km2pris))

# Choose variables of interest

allvars <- names(newhouse)
charvar <- intersect(allvars,c("aargammel_truc","antall_rom_trunc","tomtsize","bygg_bygningstype","density","borett","l_km2_bolig","l_km2_bolig2","l_km2_bolig3"))
datevar <- intersect(allvars,c("year", "quarter"))
geovar <- intersect(allvars,c("bydel","etasje_type2","kommune","fylke"))
#("kommunenr","gaardsnr","bruksnr","seksjonsnr","festenr","gatenr","bokstavnr","undernr","husnr","etasjenr","bydel","etasje_type2","leilighetsnr","sone","gr_bel","beliggenhet1"))
keepvars <- unique(c("l_km2pris","holdout",geovar,charvar,datevar))

# Limit to owner-occupied units with non-missing value
ahs <- newhouse[,keepvars]

# Take samples
set.seed(20170313)
#ahs$holdout <- as.logical(ahs$tag_fritt_salg!=1& ahs$tag_estimation !=1&ahs$l_km2pris==1)


# Create folds for lasso barcode plot
ahs$lassofolds <- as.factor(ceiling(10 * sample(nrow(ahs)) / nrow(ahs)))

# Introduce missingness dummies
withmiss <- c()
for(contvar in names(ahs)[(!sapply(ahs, is.factor)) & sapply(ahs, is.numeric)]) {
  if(sum(ahs[, contvar] < 0) > 0) {
    ahs[, paste0(contvar, "MISS")] <- as.factor(pmin(ahs[, contvar], 0))
    ahs[ahs[, contvar] < 0, contvar] <- mean(ahs[!ahs$holdout & ahs[, contvar] > 0, contvar], na.rm=T)
    withmiss <- c(withmiss, contvar)
  }
}

# Collapse missingness that does not have enough variation
for(varname in names(ahs)[sapply(ahs, is.factor)]) {
  thiscol <- as.numeric(as.character(ahs[,varname]))
  if(min(table(thiscol[thiscol < 0])) < 30) {
    ahs[,varname] <- as.numeric(as.character(ahs[,varname]))
    ahs[thiscol < 0,varname] <- -1
    ahs[,varname] <- as.factor(ahs[,varname])
  }
}

# Delete variables that are constant on full training set
for(varname in setdiff(names(ahs), "holdout")) {
  if(length(unique(ahs[!ahs$holdout, varname])) == 1) {
    ahs <- ahs[, !(names(ahs) %in% paste0(varname, c("", "IMPUTED")))]
    print(paste0("Deleted ",varname))
}}

# Delete variables that have new levels on holdout
for(varname in names(ahs)[sapply(ahs, is.factor)]) {
  if((! varname %in% c("holdout","lassofolds")) & length(setdiff(unique(ahs[ahs$holdout, varname]),
                                                                 unique(ahs[!ahs$holdout, varname]))) > 0) {
    print(paste0(varname," misses ",setdiff(unique(ahs[ahs$holdout, varname]),
                                            unique(ahs[!ahs$holdout, varname]))))
    ahs <- ahs[, !(names(ahs) == varname)]
  }
}

# Flatten factors
ahs <- droplevels(ahs)

# Choose variables of interest
downtoearth <- function(RHS,survivors) {
  keepthem <- intersect(RHS,survivors)
  return(keepthem)
}
vars <- downtoearth(c(charvar,datevar,geovar),names(ahs))

getformula <- function(varlist,LHS="l_km2pris") {
  return(paste(LHS, paste(varlist,collapse=" + "), sep = " ~ "))
}





#saveRDS(list("id",df=ahs,vars=vars,getformula=getformula),file=rname)
