* ============================================================================ *
* HOUSEKEEPING
* ============================================================================ *
capture log close
clear
set more off


* ============================================================================ *
* LOAD DATA
* ============================================================================ *

u $w5_prep/housing_info_san, replace
cap drop borett
cap drop lnr_fob

* Merge info on housing cooperatives
append using $w5_prep/borett_info


rename antall_boliger ant_bygg

gen tag_estimation = 1 

replace ant_bygg=1 if ant_bygg==.
replace garage = 0 if garage == .
replace areal = 0 if areal == .
replace tett = 1 if borett == 1 & tett == .

replace tag_fritt_salg = . if kjopesum == 0
replace kjopesum = . if kjopesum == 0

* We do not include the transaction prices of cooperatives since these do not represent the market value (debt in the coope is not included so they should not be included in a hedonic system). 
replace kjopesum = . if borett == 1


replace antall_rom = round(antall_rom)
replace bruksareal = round(bruksareal)

* Assume housing cooperatives are apartment blocks if building type is missing.
replace bygningstype = 142 if borett == 1 & bygningstype == .


* Set a minimum purchasing price
merge m:1 year using $w5_raw/cpi_1960_2020_USD.dta, keep(match master) nogen keepusing(cpi_orig)
rename cpi_orig cpi
* Normalize to 2019-CPI
sum cpi if year==2019
replace cpi=cpi/`r(mean)'
g rkjopesum=kjopesum/cpi
* Remove purchasing prices that are too low (possibly non-market transaction)
replace kjopesum = . if rkjopesum <800000

drop rkjopesum cpi


* ============================================================================ *
* Housing type from theregister (1=block/apartment block, 2=detached house, 3=semi-detached, 4=holiday home)
*
* Omitting detached houses/farmhouses used as holiday homes (162&163)
* ============================================================================ *


rename bygningstype bygg_bygningstype
g boligty=1 if bygg_bygningstype==135 | bygg_bygningstype==141 | bygg_bygningstype==142 | ///
			   bygg_bygningstype==143 | bygg_bygningstype==144 | ///
			   bygg_bygningstype==145 | bygg_bygningstype==146 
			   
replace boligty=2 if bygg_bygningstype==111 | bygg_bygningstype==112 |  ///
		     bygg_bygningstype==113

replace boligty=3 if bygg_bygningstype==121 | bygg_bygningstype==122 | ///
			bygg_bygningstype==123 | bygg_bygningstype==124 | ///
			bygg_bygningstype==131 | bygg_bygningstype==133 | ///
		        bygg_bygningstype==136
			
replace boligty=4 if bygg_bygningstype == 161 | bygg_bygningstype == 162 | bygg_bygningstype == 163

count if boligty==.
tab bygg_bygningstype if boligty==. & ant_bygg>0 


drop if boligty==.

* ============================================================================ *
* HOUSING CHARACTERISTICS AND SAMPLE SELECTION
* ============================================================================ *

* log-size
g size=bruksareal
replace size = . if size == 0
replace size = . if size >= 1000
replace size = . if size <= 20

g temp=size==.
tab year temp, row nofreq
tab boligty temp
drop temp

replace size=abs(size)
g l_km2_bolig=log(size)
g l_km2_bolig2=l_km2_bolig^2
g l_km2_bolig3=l_km2_bolig^3
drop if size == .



* Number of rooms
replace antall_rom=abs(antall_rom)
replace antall_rom = round(antall_rom)

g antall_rom_trunc=antall_rom
replace antall_rom_trunc=0 if antall_rom_trunc==.
replace antall_rom_trunc=6 if antall_rom_trunc>6

* Year when building was first in use
g aargammel=year-byggeaar
drop if aargammel<0 & aargammel!=. 

g aargammel_truc=.
replace aargammel_truc=0 if aargammel<5
replace aargammel_truc=5 if aargammel<15 & aargammel>=5
replace aargammel_truc=15 if aargammel<25 & aargammel>=15
replace aargammel_truc=25 if aargammel<35 & aargammel>=25
replace aargammel_truc=35 if aargammel>=35
tab aargammel_truc


g tomtsize=0
replace tomtsize=round(areal,500)
replace tomtsize=2000 if tomtsize>2000
tab tomtsize

* Boroughs in larger cities
g sone=kommunenr
replace sone=bydel if kommunenr==301

* Boroughs in Bergen (1 = North, 2 = West, 3 = South, 4 = Downtown)
g bydel3 = .
replace bydel3 = 1 if (bydel == 1 | bydel == 8) & kommunenr == 4601
replace bydel3 = 2 if (bydel == 4 | bydel == 5) & kommunenr == 4601
replace bydel3 = 3 if (bydel == 3 | bydel == 6) & kommunenr == 4601
replace bydel3 = 4 if (bydel == 2 | bydel == 7) & kommunenr == 4601
replace sone = bydel3 if kommunenr == 4601

* Boroughs in Oslo  (1 = West, 2 = Downtown, 3 = Fancy East, 4 = East)
g bydel2 = .
replace bydel2 = 1 if (bydel >= 3 & bydel <= 8) & kommunenr == 301
replace bydel2 = 2 if (bydel == 1 | bydel == 2 | bydel == 9) & kommunenr == 301 
replace bydel2 = 3 if (bydel == 13 | bydel == 14) & kommunenr == 301 
replace bydel2 = 4 if (bydel == 10 | bydel == 11 | bydel == 12 | bydel == 15) & kommunenr == 301 
replace sone = bydel2 if kommunenr == 301 & boligty == 1

* log purchasing price
g l_kjopesum=log(kjopesum)
g km2pris=kjopesum/size
g l_km2pris=log(km2pris)

* Generate quarterly date
g date_quarter=qofd(dokumentdato)
format date_quarter %tq

tab date_quarter
gen date_pred = mdy(12,31,year)
replace date_pred = qofd(date_pred)
format date_pred %tq

save $w5_temp/_temp_estimation_data.dta, replace

* ============================================================================ *
* ============================================================================ *
* ============================================================================ *
* ============================================================================ *
* TEST 3: COUNTIES/CITIES & HOUSING TYPE
* ============================================================================ *
global name="fylke_storby_type"

u $w5_temp/_temp_estimation_data.dta, replace
rename tett density
replace density=1 if kommunenr==301 & density==.
replace density=0 if density==.
replace density = round(density)


* fylker
g beliggenhet1=floor(kommunenr/100)
drop if beliggenhet1 == 7 | beliggenhet1 == 17 | beliggenhet1 == 19

* make into wide area beliggenhet for cabins (østlandet, vestlandet, nordland)
replace beliggenhet1 = 100 if boligty == 4 & (beliggenhet1 == 3 | beliggenhet1 == 30 | beliggenhet1 == 34 | beliggenhet1 == 38 | beliggenhet1 == 42)
replace beliggenhet1 = 101 if boligty == 4 & (beliggenhet1 == 11 | beliggenhet1 == 15 | beliggenhet1 == 46)
replace beliggenhet1 = 102 if boligty == 4 & (beliggenhet1 == 18 | beliggenhet1 == 50 | beliggenhet1 == 54)


* move Bærum to Oslo (essentially same market)
replace beliggenhet1 = 3 if kommunenr == 3024 & boligty < 4


* Stavanger (only 1 and 3, keep apartments in Stavanger with the rest of the region)
replace beliggenhet1=kommunenr if kommunenr==1103 & (boligty == 1 | boligty == 3)

* Bergen
replace beliggenhet1=kommunenr if kommunenr==4601 & boligty < 4

* Trondheim
replace beliggenhet1=kommunenr if kommunenr==5001 & boligty < 4



* Drop Longyearbyen (Svalbard)
drop if kommunenr == 2111


// GROUP BELIGGENHET TYPE
egen gr_bel=group(boligty beliggenhet1)


sum gr_bel
global ngr=`r(max)'
di $ngr


* id is what we use to paste together after ml
bys gr_bel: g id = _n


drop if year == 2020 | year == .

save $w5_prep/estimation_data.dta, replace

keep if l_km2pris != . 

save $w5_prep/estimation_data_eval.dta, replace


