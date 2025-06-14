clear

u $w5_prep/estimation_data_eval.dta, replace
sum gr_bel
global ngr=`r(max)'
di $ngr
di "Number of groups: $ngr"

forv j=1(1)$ngr {

u $w5_prep/estimation_data.dta if gr_bel == `j', replace

qui sum year
forv i=`r(min)'(1)`r(max)' {
    di "Processing year `i'"
    qui sum l_km2pris if year==`i', det
    local p1 = `r(p1)'
    local p99 = `r(p99)'

    di "Percentiles for year `i': p1=`p1', p99=`p99'"
    replace l_km2pris=. if (l_km2pris>=`p99' | l_km2pris<=`p1') & year==`i'
}
    di "Price outliers removed"

    drop boligverdi dokumentdato bruksareal byggeaar
    di "Variables dropped"

    replace borett = 0 if borett == .
    replace bydel = 99 if bydel == . | bydel == 16 | kommunenr != 301
    replace tag_fritt_salg = 0 if tag_fritt_salg == .
    di "Missing values replaced"

    gen etasje_type2 = 1 if etasje_type == "H"
    replace etasje_type2 = 2 if etasje_type == "U"
    replace etasje_type2 = 3 if etasje_type == "K"
    replace etasje_type2 = 4 if etasje_type == "L"
    replace etasje_type2 = 5 if etasje_type == ""
    drop etasje_type
    di "Etasje_type recoded and dropped"

    gen fylke = floor(kommunenr/100)
    gen kommune = kommunenr-fylke*100
    di "Fylke and kommune generated"

    drop if year == 2020 | year == .
    di "Year 2020 and missing years dropped"

    gen quarter = quarter(dofq(date_quarter))
    di "Quarter variable generated"

    drop date_quarter gr_bel beliggenhet1 boligty
    di "Variables dropped"

    replace l_km2_bolig = -1 if l_km2_bolig == .
    replace l_km2_bolig2 = -1 if l_km2_bolig2 == .
    replace l_km2_bolig3 = -1 if l_km2_bolig3 == .
    di "Missing values replaced for l_km2_bolig variables"

    bys kommune: drop if _N < 1000
    di "Dropped observations with less than 1000 per kommune"

    g holdout = (l_km2pris == . | tag_fritt_salg != 1 | tag_estimation != 1)
    di "Holdout variable generated"

    preserve
    keep if holdout == 0
    save $w5_temp/_temp_ml, replace
    restore
    di "Holdout data saved and restored"

    replace holdout = 1
    replace quarter = quarter(dofq(date_pred))
    append using $w5_temp/_temp_ml
    di "Holdout data appended"

    replace quarter = quarter(dofq(date_pred))
    di "Quarter variable updated"

    replace l_km2pris = 1 if l_km2pris == .
    drop l_kjopesum km2pris date_pred sone aargammel size areal ant_bygg antall_bad antall_wc antall_rom undernr bokstavnr husnr gatenr kjopesum seksjonsnr festenr bruksnr gaardsnr kommunenr
    di "Dropped variables"

    cap drop noise
    gen noise = uniform()
    di "Generated noise variable"

    count
    di "Observations counted"

    replace etasjenr = 9999 if etasjenr == .
    replace leilighetsnr = 9999 if leilighetsnr == .
    replace kjokkenkode = 9999 if kjokkenkode == .
    di "Missing values replaced for etasjenr, leilighetsnr, and kjokkenkode"

    format id %12.0f
    di "Formatted id variable"

    outsheet * using $w5_prep/ml/ml_sample_`j'.csv, comma replace
    di "Data saved as .csv file"
}
di "End of loop"
