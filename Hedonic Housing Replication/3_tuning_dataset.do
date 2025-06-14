u $w5_prep/estimation_data_eval.dta, replace
sum gr_bel
global ngr=`r(max)'
di $ngr

set matsize 11000

forv j=1(1)$ngr {

u $w5_prep/estimation_data_eval.dta if gr_bel == `j', replace

drop boligverdi dokumentdato bruksareal byggeaar 

replace borett = 0 if borett == .
replace bydel = 99 if bydel == . | bydel == 16 | kommunenr != 301
replace tag_fritt_salg = 0 if tag_fritt_salg == .

gen etasje_type2 = 1 if etasje_type == "H"
replace etasje_type2 = 2 if etasje_type == "U"
replace etasje_type2 = 3 if etasje_type == "K"
replace etasje_type2 = 4 if etasje_type == "L"
replace etasje_type2 = 5 if etasje_type == ""
drop etasje_type

gen fylke = floor(kommunenr/100)
gen kommune = kommunenr-fylke*100
bys kommune: drop if _N < 25

drop if year == 2016 | year == . 
gen quarter = quarter(dofq(date_quarter))
drop date_quarter gr_bel beliggenhet1 boligty

* Replace missing numbers with a specific number not using for anything else to avoid issues later.
replace etasjenr = 9999 if etasjenr == .
replace leilighetsnr = 9999 if leilighetsnr == .
replace kjokkenkode = 9999 if kjokkenkode == .

drop l_kjopesum km2pris date_pred sone aargammel size areal ant_bygg antall_bad antall_wc antall_rom undernr bokstavnr husnr gatenr kjopesum seksjonsnr festenr bruksnr gaardsnr kommunenr


outsheet * using tuning_sample_`j'.csv, comma replace
}
