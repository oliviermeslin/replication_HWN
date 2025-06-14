* adjust the rental rate by business cycle variation

global w5prep /ssb/stamme01/wealth5/wk48/rek/prepare/housing

u $w5prep/estimated_housing_wealth_1993_2019_ml_may2023.dta, replace

collapse (sum) housing_wealth, by(year)

* Estimated rental value from owner-occupied housing in national accounts (current prices)
gen totRent = .
replace totRent = 54656 if year == 1993
replace totRent = 55133 if year == 1994
replace totRent = 57217 if year == 1995
replace totRent = 58771 if year == 1996
replace totRent = 60755 if year == 1997
replace totRent = 62855 if year == 1998
replace totRent = 65973 if year == 1999
replace totRent = 72150 if year == 2000
replace totRent = 75059 if year == 2001
replace totRent = 79474 if year == 2002
replace totRent = 86445 if year == 2003
replace totRent = 90886 if year == 2004
replace totRent = 96175 if year == 2005
replace totRent = 101976 if year == 2006
replace totRent = 107119 if year == 2007
replace totRent = 112825 if year == 2008
replace totRent = 116000 if year == 2009
replace totRent = 121500 if year == 2010
replace totRent = 125500 if year == 2011
replace totRent = 129801 if year == 2012
replace totRent = 141288 if year == 2013
replace totRent = 150320 if year == 2014
replace totRent = 161159 if year == 2015
replace totRent = 166778 if year == 2016
replace totRent = 172468 if year == 2017
replace totRent = 178102 if year == 2018
replace totRent = 185755 if year == 2019
replace totRent = 192799 if year == 2020
replace totRent = totRent * 1000000
gen adjFacRent = totRent/(housing_wealth)
keep year adjFacRent
save $w5prep/rental_adjustment, replace
