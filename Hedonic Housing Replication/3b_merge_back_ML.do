* ============================================================================ *
* HOUSEKEEPING
* ============================================================================ *
clear
capture log close
set more off

*declare globals
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


log using $log_files/K_merge_back.smcl, replace


* ============================================================================ *
* MERGE IN OWNER INFORMATION
* ============================================================================ *


u $w5_clean/housing_predicted_machine_small.dta if borett != 1, replace
replace etasjenr = . if etasjenr == 9999
replace leilighetsnr = . if leilighetsnr == 9999
replace gaardsnr = . if gaardsnr == 9999
replace bruksnr = . if bruksnr == 9999
replace festenr = . if festenr == 9999
replace seksjonsnr = . if seksjonsnr == 9999
replace gatenr = . if gatenr == 9999
replace husnr = . if husnr == 9999
replace bokstavnr = 0 if husnr == 9999
replace undernr = 0 if undernr == .
replace undernr = 0 if undernr == 9999


duplicates drop kommunenr gaardsnr bruksnr festenr seksjonsnr gatenr husnr bokstavnr etasje_type etasjenr leilighetsnr undernr year, force

merge 1:m kommunenr gaardsnr bruksnr festenr seksjonsnr gatenr husnr bokstavnr etasje_type etasjenr leilighetsnr undernr year using $w5_clean/housing_owner, keepusing(lnr eierbrok) keep(match) nogen

save $w5_data/temp_merge_eier_ml, replace
clear

u $w5_clean/housing_predicted_machine_small.dta if borett == 1, replace

merge 1:m kommunenr gaardsnr bruksnr festenr seksjonsnr gatenr husnr bokstavnr etasje_type etasjenr leilighetsnr undernr year using $w5_clean/borett_owner, keepusing(lnr eierbrok) keep(match) nogen

save $w5_data/temp_merge_coop_ml, replace
clear

********************************************************************************
* Append it all together
u $w5_data/temp_merge_eier_ml, replace
append using $w5_data/temp_merge_coop_ml
save $w5_data/temp_last_merge3, replace
 
********************************************************************************
* Clean files
u $w5_data/temp_last_merge3, replace
drop if lnr == .
drop if predicted_kjopesum == .
drop if eierbrok == .
drop gr_bel date_quarter* km2pris tag_estimation tag_fritt_salg 
bys kommunenr gaardsnr bruksnr festenr seksjonsnr gatenr husnr bokstavnr etasje_type etasjenr leilighetsnr undernr year: egen sumBrok = sum(eierbrok)



******************
** STEP 1: Construct the tax values

merge m:1 year using $load_raw2/cpi_1960_2020_USD, keep(master match) keepusing(pgrowth) nogen

* get address to pinpoint primary
merge m:1 lnr year using $load_raw2/adr/address_1992_2020, keep(master match) keepusing(municipality street_nr house_nr) nogen

gen primary = 1 if municipality == kommunenr & street_nr == gatenr & husnr == house_nr

bys lnr year: egen maxprim = max(primary)

cap drop NNN
bys lnr year: gen NNN = _N
replace primary = 1 if NNN == 1
count if  primary == 1 

bys lnr year: egen maxvalue = max(predicted_kjopesum)
replace primary = 1 if predicted_kjopesum == maxvalue & maxprim != 1
replace primary = 0 if predicted_kjopesum != maxvalue & primary != 1

* Cabins
replace primary = 0 if boligty == 4
count if primary == 1

drop gaardsnr gatenr husnr etasje_type etasjenr leilighetsnr festenr seksjonsnr bruksnr street_nr house_nr 

su eierbrok, det
replace eierbrok = . if eierbrok > 1
replace eierbrok = . if eierbrok < 0.2
gen housing_wealth = predicted_kjopesum*eierbrok
replace housing_wealth = 0 if housing_wealth == .

* adjust to the tax assessed values
gen taxvalue = housing_wealth*0.25

replace taxvalue = housing_wealth*1 if year == 2023 & primar == 0
replace taxvalue = housing_wealth*0.95 if year == 2022 & primar == 0
replace taxvalue = housing_wealth*0.90 if year == 2021 & primar == 0
replace taxvalue = housing_wealth*0.90 if year == 2020 & primar == 0
replace taxvalue = housing_wealth*0.9 if year == 2019 & primar == 0
replace taxvalue = housing_wealth*0.9 if year == 2018 & primar == 0
replace taxvalue = housing_wealth*0.9 if year == 2017 & primar == 0
replace taxvalue = housing_wealth*0.8 if year == 2016 & primar == 0
replace taxvalue = housing_wealth*0.7 if year == 2015 & primar == 0
replace taxvalue = housing_wealth*0.6 if year == 2014 & primar == 0
replace taxvalue = housing_wealth*0.5 if year == 2013 & primar == 0
replace taxvalue = housing_wealth*0.4 if year == 2012 & primar == 0
replace taxvalue = housing_wealth*0.4 if year == 2011 & primar == 0
replace taxvalue = housing_wealth*0.4 if year == 2010 & primar == 0

gen tag_cabin = boligty == 4
replace borett = 0 if borett == .


keep lnr year boligverdi kjopesum housing_wealth borett kommunenr taxvalue municipality pgrowth primar tag_cabin bruksareal hp_growth*


save $w5_data/temp_last_merge4, replace
u $w5_data/temp_last_merge4, replace


* Make a primary/secondary dataset


save $w5_data/temp_last_merge5, replace

****************************************
* STEP 3: Construct the ratios for later adjustments
u $w5_data/temp_last_merge5, replace

* make the growth ahead variables volume weighted
bys lnr year: egen sumW = sum(housing_wealth)
bys lnr year: egen hp_growth_ahead = sum(hp_growth_ahead_ml*housing_wealth/sumW)
bys lnr year: egen hp_growth = sum(hp_growth_ml*housing_wealth/sumW)
cap drop sumW

collapse (sum) housing_wealth taxvalue kjopesum boligverdi (max) hp_growth hp_growth_ahead borett kommunenr municipality tag_cabin, by(lnr year)


save $w5_data/temp_last_merge6, replace
u $w5_data/temp_last_merge6, replace


gen fylke_address = floor(municipality/100)
gen fylke_estimate = floor(kommunenr/100)

merge m:1 lnr year using $load_raw2/realkap9315_taxvalues_correct, keepusing(housing_coop housing_owned cabin other_real_estate) nogen
replace cabin = 0  if cabin == .
replace housing_coop = 0 if housing_coop == .
replace housing_owned = 0 if housing_owned == .
replace other_real_estate = 0 if other_real_estate == .

*Updated to 2016-2019 numbers
merge m:1 lnr year using $load_raw2/sbsareg/realkap_2010_2019, keepusing(housing_coop housing_owned cabin real_estate_other) nogen
replace cabin = 0  if cabin == .
replace housing_coop = 0 if housing_coop == .
replace housing_owned = 0 if housing_owned == .
replace other_real_estate = 0 if real_estate_other == .
egen realestateother = rowtotal(real_estate_other other_real_estate), missing
drop real_estate_other other_real_estate
rename realestateother other_real_estate

merge 1:1 lnr year using $load_raw2/marital_cohabit_91_20.dta, nogen
replace spousal_lnr = . if marital ==1 |  marital >2
replace spousal_lnr = . if spousal_lnr < 10000 //missing spousal_lnr's are sometimes coded as very low numbers, dropping these observations.


*Generate hhid based on the unique combination of two lnrs using "min" and "max", since both husband and wife have separate entries in data.  
gen double max = lnr if lnr > spousal_lnr
replace max = spousal_lnr  if spousal_lnr > lnr
gen double min = lnr if lnr < spousal_lnr
replace min = spousal_lnr if spousal_lnr < lnr
format min max %15.0g
replace max = 1 if max == . 
egen hhid = group(min max)

save $w5_data/temp_last_merge7, replace
u $w5_data/temp_last_merge7, replace

foreach var of varlist housing_wealth taxvalue housing_coop housing_owned cabin other_real_estate {
	qui replace `var' = 0 if `var' == .
	bys hhid year: egen `var'_h = sum(`var')
}

gen tag_drop = 0
forval year = 1993/2019 {
	qui su housing_wealth_h if housing_wealth_h != 0 & year == `year', det
	qui su housing_wealth_h if housing_wealth_h != 0 & year == `year' & housing_wealth_h > r(p99), det
	replace tag_drop = 1 if housing_wealth_h > r(p99) & housing_wealth_h != . & year == `year'
	qui su housing_coop_h if housing_coop_h > 0 & year == `year', det
	replace tag_drop = 1 if housing_coop_h < r(p1) & housing_coop_h > 0 & year == `year' 
	qui su housing_owned_h if housing_owned_h > 0 & year == `year', det
	replace tag_drop = 1 if housing_owned_h < r(p1) & housing_owned_h > 0 & year == `year' 
	qui su cabin if cabin_h > 0 & year == `year', det
	replace tag_drop = 1 if cabin_h < r(p1) & cabin_h > 0 & year == `year' 
}

gen ratio_coop = taxvalue_h/housing_coop_h if borett == 1 & tag_cabin != 1 & housing_owned_h == 0 
gen ratio_owner = taxvalue_h/housing_owned_h if borett != 1 & tag_cabin != 1 
gen ratio_cabin = taxvalue_h/cabin_h if borett != 1 & tag_cabin == 1 & housing_owned_h == 0

save $w5_data/temp_last_merge7b, replace


preserve
keep if ratio_owner > 0 & ratio_owner != . & tag_drop == 0
collapse (mean) ratio_owner_mean=ratio_owner (median) ratio_owner_median=ratio_owner (sd) ratio_owner_sd=ratio_owner, by(year)
rename * *_country
rename year year
save $w5_data/ratio_owner_ml, replace
restore

preserve
keep if ratio_coop > 0 & ratio_coop != . & tag_drop == 0
collapse (mean) ratio_coop_mean=ratio_coop (median) ratio_coop_median=ratio_coop (sd) ratio_coop_sd=ratio_coop, by(year)
rename * *_country
rename year year
save $w5_data/ratio_coop_ml, replace
restore


preserve
keep if ratio_cabin > 0 & ratio_cabin != . & tag_drop == 0
collapse (mean) ratio_cabin_mean=ratio_cabin (median) ratio_cabin_median=ratio_cabin (sd) ratio_cabin_sd=ratio_cabin, by(year)
rename * *_country
rename year year
save $w5_data/ratio_cabin_ml, replace
restore

preserve
keep if ratio_owner > 0 & ratio_owner != . & fylke_address == fylke_estimate & fylke_address != . & fylke_estimate != 20 & fylke_estimate != 19 & fylke_estimate != 18  & tag_drop == 0
collapse (mean) ratio_owner_mean=ratio_owner (median) ratio_owner_median=ratio_owner (sd) ratio_owner_sd=ratio_owner, by(year fylke_address)
rename * *_fylke
rename year year
rename fylke fylke_address
save $w5_data/ratio_owner_fylke_ml, replace
restore

preserve
keep if ratio_coop > 0 & ratio_coop != . & fylke_address == fylke_estimate & fylke_address != . & fylke_estimate != 20 & fylke_estimate != 19 & fylke_estimate != 18  & tag_drop == 0
collapse (mean) ratio_coop_mean=ratio_coop (median) ratio_coop_median=ratio_coop (sd) ratio_coop_sd=ratio_coop, by(year fylke_address)
rename * *_fylke
rename year year
rename fylke fylke_address
save $w5_data/ratio_coop_fylke_ml, replace
restore

cap drop _merge
merge m:1 year using $w5_data/ratio_owner_ml, keep(match master) nogen
merge m:1 year using $w5_data/ratio_coop_ml, keep(match master) nogen
merge m:1 year using $w5_data/ratio_cabin_ml, keep(match master) nogen
merge m:1 year fylke_address using $w5_data/ratio_owner_fylke_ml, keep(match master) nogen
merge m:1 year fylke_address using $w5_data/ratio_coop_fylke_ml, keep(match master) nogen

drop ratio_owner
rename ratio_owner_median_country ratio_owner
drop ratio_coop
rename ratio_coop_median_country ratio_coop
drop ratio_cabin
rename ratio_cabin_median_country ratio_cabin
drop if year == 2020


*************************************************
* STEP 4: Construct the adjusted tax values to use if we have no estimated observations

gen housing_coop_adjusted = 0
gen housing_owner_adjusted = 0
gen housing_cabin_adjusted = 0
gen housing_other_adjusted = 0


qui replace housing_cabin_adjusted = cabin*4*ratio_cabin if year < 2010 
qui replace housing_other_adjusted = other_real_estate*4*ratio_owner if year < 2010
qui replace housing_cabin_adjusted = cabin/0.4*ratio_cabin if year == 2010 
qui replace housing_other_adjusted = other_real_estate/0.4*ratio_owner if year == 2010
qui replace housing_cabin_adjusted = cabin/0.4*ratio_cabin if year == 2011
qui replace housing_other_adjusted = other_real_estate/0.4*ratio_owner if year == 2011
qui replace housing_cabin_adjusted = cabin/0.4*ratio_cabin if year == 2012
qui replace housing_other_adjusted = other_real_estate/0.4*ratio_owner if year == 2012
qui replace housing_cabin_adjusted = cabin/0.5*ratio_cabin if year == 2013
qui replace housing_other_adjusted = other_real_estate/0.5*ratio_owner if year == 2013
qui replace housing_cabin_adjusted = cabin/0.6*ratio_cabin if year == 2014
qui replace housing_other_adjusted = other_real_estate/0.6*ratio_owner if year == 2014
qui replace housing_cabin_adjusted = cabin/0.7*ratio_cabin if year == 2015
qui replace housing_other_adjusted = other_real_estate/0.7*ratio_owner if year == 2015
qui replace housing_cabin_adjusted = cabin/0.8*ratio_owner if year == 2016
qui replace housing_other_adjusted = other_real_estate/0.8*ratio_owner if year == 2016
qui replace housing_cabin_adjusted = cabin/0.8*ratio_owner if year == 2017
qui replace housing_other_adjusted = other_real_estate/0.9*ratio_owner if year == 2017
qui replace housing_cabin_adjusted = cabin/0.9*ratio_owner if year == 2018
qui replace housing_other_adjusted = other_real_estate/0.9*ratio_owner if year == 2018
qui replace housing_cabin_adjusted = cabin/0.9*ratio_owner if year == 2019
qui replace housing_other_adjusted = other_real_estate/0.9*ratio_owner if year == 2019
qui replace housing_cabin_adjusted = cabin/0.9*ratio_owner if year == 2020
qui replace housing_other_adjusted = other_real_estate/0.9*ratio_owner if year == 2020
qui replace housing_cabin_adjusted = cabin/0.9*ratio_owner if year == 2021
qui replace housing_other_adjusted = other_real_estate/0.9*ratio_owner if year == 2021
qui replace housing_cabin_adjusted = cabin/0.95*ratio_owner if year == 2022
qui replace housing_other_adjusted = other_real_estate/0.95*ratio_owner if year == 2022
qui replace housing_cabin_adjusted = cabin/1*ratio_owner if year == 2023
qui replace housing_other_adjusted = other_real_estate/1*ratio_owner if year == 2023

* multiply with the county-year-specific ratios
qui replace housing_coop_adjusted = housing_coop*4*ratio_coop_median_fylke if ratio_coop_median_fylke != .
qui replace housing_owner_adjusted = housing_owned*4*ratio_owner_median_fylke if ratio_owner_median_fylke != .

* multiply with year-specific ratios
qui replace housing_coop_adjusted = housing_coop*4*ratio_coop if housing_coop_adjusted == 0 
qui replace housing_owner_adjusted = housing_owned*4*ratio_owner if housing_owner_adjusted == 0

gen total_housing = housing_coop_adjusted + housing_owner_adjusted + housing_cabin_adjusted

save $w5_data/temp_last_merge8, replace
clear
u $w5_data/temp_last_merge8, replace

replace housing_wealth = 0 if housing_wealth == .
gen estimated_housing_wealth = housing_wealth
replace housing_wealth = total_housing if housing_wealth == 0
gen diff = (housing_wealth - total_housing)/housing_wealth
replace housing_wealth = total_housing if diff < -0.10
drop diff 
replace housing_cabin_adjusted = 0 if housing_cabin_adjusted == .
replace housing_other_adjusted = 0 if housing_other_adjusted == .

gen housing_wealth_excl_other = housing_wealth
replace housing_wealth = housing_wealth + housing_other_adjusted 
replace housing_wealth = housing_wealth + housing_cabin_adjusted if tag_cabin == 0
gen estimated = housing_wealth_excl_other == estimated_housing_wealth & estimated_housing_wealth != 0


save $w5_data/temp_last_merge9, replace
clear

**********************************************************************
* STEP 7: add the transcation/active saving information
u $w5_data/temp_last_merge9, replace

cap drop _merge
cap drop kjopesum
merge 1:m lnr year using $w5_clean/ambita_transact_simple, keep(master match) keepusing(kjoper kjopesum brok)
drop if _merge == 2
drop _merge
rename kjoper transact
replace kjopesum = kjopesum*brok
replace kjopesum = - kjopesum if transact == 0
rename kjopesum saving_housing
replace transact = transact + 1 if transact != .
collapse (sum) saving_housing transact (mean) housing_wealth estimated hp_growth hp_growth_ahead, by(lnr year)
replace transact = 1 if transact > 1 & transact != .

tsset lnr year
gen hp_growth_imp = (housing_wealth/l.housing_wealth-1)*100
gen hp_growth_ahead_imp = (f.housing_wealth/housing_wealth-1)*100

replace hp_growth_imp = . if hp_growth_imp == 100
replace hp_growth_ahead_imp = . if hp_growth_ahead_imp == 100

su hp_growth_imp, det
replace hp_growth = hp_growth_imp if hp_growth == . & hp_growth_imp > r(p5) & hp_growth_imp < r(p95) & transact != 1

su hp_growth_ahead_imp, det
replace hp_growth_ahead = hp_growth_ahead_imp if hp_growth_ahead == . & hp_growth_ahead_imp > r(p5) & hp_growth_ahead_imp < r(p95) & transact != 1

label variable saving_housing "Net saving in housing: bought - sold"
label variable housing_wealth "Housing wealth. Estimated = 1: hedonic; Estimated = 0: adjusted tax value"
label variable transact "0 if no transact, 1 if transact"
label variable estimated "Estimated = 1: ml; Estimated = 0: adjusted tax value"

drop if year < 1993
replace hp_growth_ahead = . if year == 2019
replace hp_growth = . if year == 1993

keep if housing_wealth > 0 & housing_wealth != . 

compress
save $w5_clean/estimated_housing_wealth_1993_2019_ml_may2023, replace
clear

