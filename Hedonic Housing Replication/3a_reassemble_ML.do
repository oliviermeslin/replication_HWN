* ============================================================================ *
* HOUSEKEEPING
* ============================================================================ *
clear
capture log close
set more off

*globals
global save_temp "/ssb/stamme01/wealth5/wk48/temp/rek/housing"
global save_prepared "/ssb/stamme01/wealth5/wk48/prepared/rek/housing"
global log_files "/ssb/stamme01/wealth5/dok/rek/housing/log"
global figurer "/ssb/stamme01/wealth5/dok/rek/housing/figurer"
global load_raw "/ssb/stamme01/wealth5/wk48/raw/gab1"
global load_raw2 "/ssb/stamme01/wealth5/wk48/raw"
global prog_files "/ssb/stamme01/wealth5/prog/knt/prepare/housing"
global w5_clean /ssb/stamme01/wealth5/wk48/rek/prepare/housing
global w5_data /ssb/stamme01/wealth5/wk48/rek/FHJN_demographics
global w5_prog /ssb/stamme01/wealth5/prog/rek/prepare/housing
global w5_raw /ssb/stamme01/wealth5/wk48/raw
global w5_prep /ssb/stamme01/wealth5/wk48/rek/prepare/housing
global w5_temp /ssb/stamme01/wealth5/wk48/rek/temp

local ngr = 44 // Set the number of 'ml_result_*.dta' files

// Load the first dataset and add the gr_bel variable
use $w5_prep/ml/ml_result_1.dta, clear
gen gr_bel = 1
save $w5_prep/ML_rawappended.dta, replace

// Append the remaining datasets
forvalues j = 2/`ngr' {
    use $w5_prep/ml/ml_result_`j'.dta, clear
    gen gr_bel = `j'
    append using $w5_prep/ML_rawappended.dta
    save $w5_prep/ML_rawappended.dta, replace
}

//
gen se = (ensemble_prediction-l_km2pris)^2 if holdout == 0
bys gr_bel: egen mse = mean(se)
gen rmse = sqrt(mse)
drop mse se

save $w5_prep/ML_appended.dta, replace

keep if holdout == 1

* create the volume-weighted in-sample rmse for the cabins and everything else
su rmse if gr_bel <= 41
su rmse if gr_bel > 41

bys gr_bel id: keep if _n == 1

merge 1:1 gr_bel id using $w5_prep/estimation_data.dta, keep(match) nogen

*Correct for log skewness
g predicted_kjopesum=exp(ensemble_prediction)*exp(rmse^2/2)*size

* Remove some duplicates
duplicates drop kommunenr gaardsnr bruksnr festenr seksjonsnr gatenr husnr bokstavnr etasje_type etasjenr leilighetsnr undernr year, force

save $w5_prep/ML_merged.dta, replace

* Create new variable for unique panel identifier
egen panel_id = group(kommunenr gaardsnr bruksnr festenr seksjonsnr gatenr husnr bokstavnr etasje_type etasjenr leilighetsnr undernr), missing

* Define panel structure using xtset
xtset panel_id year

* Create lagged variable
by panel_id: gen predicted_kjopesum_lag = l.predicted_kjopesum

* Compute hp_growth_ml
gen hp_growth_ml = (predicted_kjopesum / predicted_kjopesum_lag - 1) * 100

* Create lead variable
by panel_id: gen predicted_kjopesum_lead = f.predicted_kjopesum

* Compute hp_growth_ahead_ml
gen hp_growth_ahead_ml = (predicted_kjopesum_lead / predicted_kjopesum - 1) * 100

drop antall_bad antall_wc ant_bygg byggeaar bygg* kjokkenkode density garage areal size ensemble_prediction ols_prediction l_* aar* tomt* sone belig*
drop id
compress
save $w5_clean/housing_predicted_machine.dta, replace

keep if predicted_kjopesum != .
bys kommunenr gaardsnr bruksnr festenr seksjonsnr gatenr husnr bokstavnr etasje_type etasjenr leilighetsnr undernr year (predicted_kjopesum): keep if _n == _N
cap drop eierbrok

compress
save $w5_clean/housing_predicted_machine_small.dta, replace

clear
