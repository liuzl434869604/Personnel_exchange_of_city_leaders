

****************************************Basic setting**************************************************
set rmsg on
cap log close
clear
clear matrix 
clear  mata
set matsize 11000
set maxvar  32767



global Path ""

cd $Path\Data


/*
Here, the term "rotation" refers to inter-city personnel exchanges of city leaders.
*/




*****************************************Modelling****************************************************



***************Baselin regressions*********************

global controls "ln_gdppc ln_popden ln_expenditure_pc ln_leader_age ln_leader_tenure  ln_output ln_age  ln_labor  "
global  fe "firm  code_province#year  leader_id"


reghdfe   ln_cod_emis  Rotation_dummy   $controls  if  cod_emission >0 & year>=2006 , a( $fe  ) vce(cluster firm)
est  sto  baseline_cod_all

reghdfe   ln_nh3_emis  Rotation_dummy   $controls  if  nh3_emission >0 & year>=2006 , a( $fe  ) vce(cluster firm)
est  sto  baseline_nh3_all

reghdfe   ln_wastewater_emis  Rotation_dummy   $controls  if  wastewater_emission >0 & year>=2006 , a( $fe  ) vce(cluster firm)
est  sto  baseline_ww_all


		 



//Figure output//

global color_type1  ""060 079 162"%70"
global  color_type2  ""242 147 057"%70"
global  color_type3  ""155 030 033"%70"

global  msymbol_type1  "circle"
global  msymbol_type2  "circle"
global  msymbol_type3  "circle"

global  msize  "medlarge "
global  recast "rcap"
global  ci_width "medthick "

cd $Path\Figure\Figure2\
coefplot  (baseline_cod_all , keep(Rotation_dummy) rename(Rotation_dummy = "1.1"  ) color($color_type1)  ciopts(lcolor($color_type1) lpattern(solid)  lwidth($ci_width)  recast($rcap))   msymbol($msymbol_type1)   aseq(1)     ) ///
								  (baseline_nh3_all , keep(Rotation_dummy ) rename(  Rotation_dummy = "2.1" )  color($color_type2)    ciopts(lcolor($color_type2)  lpattern(solid)  lwidth($ci_width)   recast($rcap))     msymbol($msymbol_type2)   aseq(2)     ) ///
								   (baseline_ww_all , keep(Rotation_dummy ) rename(Rotation_dummy  = "3.1")  color($color_type3)   ciopts(  lcolor($color_type3)  lpattern(solid)  lwidth($ci_width)   recast($rcap))  msymbol($msymbol_type3)   aseq(3)     ) ///
					,  vertical eqstrict eqlabels("COD" "Ammonia nitrogen" "Wastewater" ) ///
					  legend(off)    ///
					  levels(95)   msize($msize)  mlwidth(medthick)   ///
					 ytitle("Effects of personnel exchange on firm water pollution") ///
					title("(a)", pos(12) size(medthick)  yoffset(2) )  ylabel(,tlc(black)) xlabel(,tlc(black)) ///
					plotregion(lcolor(black)  lwidth(medium))  ylabel(,labsize(*1))      xlabel(, labsize(*1)  axis(2))  xlabel(,nolabels axis(1))   yscale(titlegap( 1)  lcolor(black) ) xscale(lcolor(black)) nooffsets   aspectratio(1) ///
					 saving(baseline.gph,replace)   





***************Robustness*********************

//Quasi-randomness of leader exchanges
//Here we include factors in both move-out and move-in cities, and the distance between two cities

preserve
	duplicates  drop  year  Moveout_city  name_prefecture  mayor  ,force
	keep if year>=2006 & year<=2013
	
	gen ln_distance=ln(distance+1)
	
	reghdfe  rotation_predict  move*_ln_gdppc  move*_gdp_growth  move*_ln_popden   move*_fdi_gdp   move*_ln_expenditure_pc     move*_employ_secondary   move*_employ_tertiary    move*_emission_intensity      ln_distance, a(moveout_code_province#year  movein_code_province#year   leader_id) vce(cluster code_moveout_city  code_movein_prefecture) 
	est  sto  ro_randomness
	
restore



//Event study

gen post_temp=(year-start_year)*Rotation_dummy
tab  post_temp,g(post_)

gen pre_temp=(year-end_year)*RotationNext_dummy
tab  pre_temp,g(pre_)

gen   pre_4years_before=0
replace pre_4years_before=1  if  pre_7==1 |  pre_6==1 |  pre_5==1 |  pre_4==1 |  pre_3==1 |  pre_2==1 |  pre_1==1

gen   post_5years_above=0
replace   post_5years_above=1  if  post_6==1 | post_7==1 | post_8==1 | post_9==1 | post_10==1

gen   post_4years_above=0
replace   post_4years_above=1  if post_5==1 | post_6==1 | post_7==1 | post_8==1 | post_9==1 | post_10==1



reghdfe   ln_cod_emission pre_4years_before pre_8 pre_9 pre_10   post_2 post_3 post_4  post_4years_above $controls  if  cod_emission >0 & year>=2006 , a( $fe ) vce(cluster code_prefecture)
est sto ro_event_study_cod 

reghdfe   ln_nh3_emission pre_4years_before pre_8 pre_9 pre_10   post_2 post_3 post_4 post_4years_above $controls  if  nh3_emission >0 & year>=2006 , a( $fe ) vce(cluster code_prefecture)
est sto ro_event_study_nh3

reghdfe   ln_wastewater_emission pre_4years_before pre_8 pre_9 pre_10   post_2 post_3 post_4 post_4years_above $controls  if wastewater_emission >0 & year>=2006 , a( $fe ) vce(cluster code_prefecture)
est sto ro_event_study_ww

coefplot    ro_event_study_cod ,  ///
			keep( pre_4years_before pre_8 pre_9 pre_10   post_2 post_3 post_4  post_4years_above) ///
			coeflabels( pre_4years_before= "≤-4"    pre_8 = "-3"   pre_9  =  "-2"  pre_10  =  "-1"  post_2 =  "1"   post_3 =  "2"   post_4= "3"   post_4years_above = "≥4" )    ///
			omitted  vertical recast(connect)   lcolor(black*0.8)  lpattern(-)  xline(4.5,lp(dash) lwidth(medium))    ylabel(-0.20(0.04)0.12)   ///
			title("(a) COD")  ytitle(Effects of personnel exchange) xtitle(Years with respect to exchange) yscale(lcolor(black) ) yline(0)   xscale(lcolor(black))   ///
			ciopts( lpattern(solid) lcolor(black)  recast(rcap) msize(medium) )   

coefplot    ro_event_study_nh3 ,  ///
			keep( pre_4years_before pre_8 pre_9 pre_10   post_2 post_3 post_4 post_4years_above) ///
			coeflabels( pre_4years_before= "≤-4"    pre_8 = "-3"   pre_9  =  "-2"  pre_10  =  "-1"  post_2 =  "1"   post_3 =  "2"   post_4= "3"   post_4years_above = "≥4" )    ///
			omitted  vertical recast(connect)   lcolor(black*0.8)  lpattern(-)  xline(4.5,lp(dash) lwidth(medium))    ylabel(-0.24(0.04)0.20)   ///
			title("(b) ammonia nitrogen")   ytitle(Effects of personnel exchange) xtitle(Years with respect to exchange) yscale(lcolor(black) ) yline(0)   xscale(lcolor(black))   ///
			ciopts( lpattern(solid) lcolor(black)  recast(rcap) msize(medium) )   
	
	
coefplot    ro_event_study_ww ,  ///
			keep( pre_4years_before pre_8 pre_9 pre_10   post_2 post_3 post_4 post_4years_above) ///
			coeflabels( pre_4years_before= "≤-4"    pre_8 = "-3"   pre_9  =  "-2"  pre_10  =  "-1"  post_2 =  "1"   post_3 =  "2"   post_4= "3"   post_4years_above = "≥4" )    ///
			omitted  vertical recast(connect)   lcolor(black*0.8)  lpattern(-)  xline(4.5,lp(dash) lwidth(medium))    ylabel(-0.14(0.04)0.14)   ///
			title("(c) wastewater")  ytitle(Effects of personnel exchange) xtitle(Years with respect to exchange)  yscale(lcolor(black) ) yline(0)   xscale(lcolor(black))   ///
			ciopts( lpattern(solid) lcolor(black)  recast(rcap) msize(medium) )   


			

//Additional FEs
reghdfe   ln_cod_emis  Rotation_dummy  $controls   if  cod_emission >0 & year>=2006 , a( $fe  code_industry#year code_province#code_industry) vce(cluster firm) 
est  sto   ro_more_fe_cod

reghdfe   ln_cod_emis  Rotation_dummy  $controls   if  nh3_emission >0 & year>=2006 , a( $fe  code_industry#year code_province#code_industry) vce(cluster firm) 
est  sto   ro_more_fe_nh3

reghdfe   ln_wastewater_emis  Rotation_dummy  $controls   if  wastewater_emission >0 & year>=2006 , a( $fe  code_industry#year code_province#code_industry) vce(cluster firm) 
est  sto   ro_more_fe_ww


//Alternative DID estimators
egen composition = nvals(Rotation_dummy) , by(code_prefecture mayor) 
gen never_treated = (composition==1 & Rotation_dummy==0) 
gen always_treated =  (composition==1 & Rotation_dummy==1) 


*1***Never-treated group + from "0" to "1" group*****

cap drop  Rotation_new_did_1
gen Rotation_new_did_1 = Rotation_dummy  if never_treated==1  |  ///
					(Rotation_before==0 & Rotation_dummy==1  ) | (Rotation_next>0 & Rotation_dummy==0)

				
reghdfe   ln_cod_emis  Rotation_new_did_1   $controls  if  cod_emission >0 & year>=2006  , a( $fe  ) vce(cluster firm)    
est sto  did_new_cod_1

reghdfe   ln_nh3_emis  Rotation_new_did_1   $controls  if  nh3_emission >0 & year>=2006  , a( $fe  ) vce(cluster firm) 
est sto  did_new_nh3_1

reghdfe   ln_wastewater_emis  Rotation_new_did_1   $controls  if  wastewater_emission >0 & year>=2006  , a( $fe  ) vce(cluster firm)   
est sto  did_new_ww_1



*2***Exclude samples with multiple treatment status****

cap drop    Rotation_term_temp_?
gen  Rotation_term_temp_1 = (Rotation_before == 0 & Rotation_dummy == 1 & Rotation_next ==0 ) 
gen  Rotation_term_temp_2 = (Rotation_before >= 1 & Rotation_dummy == 0 & Rotation_next >=1 ) 


cap drop  Rotation_new_did_2
cap  gen  Rotation_new_did_2 = Rotation_dummy  if   Rotation_term_temp_1 ==0  &  Rotation_term_temp_2 ==0

reghdfe   ln_cod_emis  Rotation_new_did_2  $controls  if  cod_emission >0 & year>=2006  , a( $fe  ) vce(cluster firm)   
est sto  did_new_cod_2

reghdfe   ln_nh3_emis   Rotation_new_did_2   $controls  if  nh3_emission >0 & year>=2006  , a( $fe  ) vce(cluster firm) 
est sto  did_new_nh3_2

reghdfe   ln_wastewater_emis   Rotation_new_did_2  $controls  if  wastewater_emission >0 & year>=2006  , a( $fe  ) vce(cluster firm)  
est sto  did_new_ww_2





*3***Exclude always-treated group***


reghdfe   ln_cod_emis  Rotation_dummy   $controls  if  cod_emission >0 & year>=2006 & always_treated==0  , a( $fe  ) vce(cluster firm)
est sto  did_new_cod_3

*
reghdfe   ln_nh3_emis   Rotation_dummy    $controls  if  nh3_emission >0 & year>=2006   & always_treated==0 , a( $fe  ) vce(cluster firm)
est sto  did_new_nh3_3

reghdfe   ln_wastewater_emis  Rotation_dummy  $controls  if  wastewater_emission >0 & year>=2006  & always_treated==0  , a( $fe  ) vce(cluster firm)
est sto  did_new_ww_3






***4***DID_M estimator (instant effect)*****


gen Rotation_start_year=Rotation*start_year

did_imputation  ln_cod_emis  firm  year  Rotation_start_year if  cod_emission >0 & year>=2006 ,fe($fe) controls($controls )  autosample
est sto  did_new_cod_4

did_imputation  ln_nh3_emis  firm  year  Rotation_start_year if  nh3_emission >0 & year>=2006 ,fe($fe) controls($controls )  autosample
est sto  did_new_nh3_4

did_imputation  ln_wastewater_emis  firm  year  Rotation_start_year if  wastewater_emission >0 & year>=2006 ,fe($fe) controls($controls )  autosample
est sto  did_new_ww_4








//Placebo tests
cd  $Path\Result
				permute   Rotation_dummy  beta = _b[Rotation_dummy],   reps(500) left seed(10101)  saving("simulation_500_cod.dta", every(1) replace) :  ///
				reghdfe   ln_cod_emis  Rotation_dummy $controls  if  cod_emission >0 & year>=2006 , a(firm  code_province#year  ) vce(cluster firm)

				permute   Rotation_dummy  beta = _b[Rotation_dummy],   reps(500) left seed(10101)  saving("simulation_500_nh3.dta", every(1) replace) :  ///
				reghdfe   ln_nh3_emis  Rotation_dummy $controls  if  nh3_emission >0 & year>=2006 , a(firm  code_province#year  ) vce(cluster firm)

				permute   Rotation_dummy  beta = _b[Rotation_dummy],   reps(500) left seed(10101)  saving("simulation_500_ww.dta", every(1) replace) :  ///
				reghdfe   ln_wastewater_emis  Rotation_dummy $controls  if  wastewater_emission >0 & year>=2006 , a(firm  code_province#year  ) vce(cluster firm)

cd  $Path\Data




//Reclsutering at the city level
reghdfe   ln_cod_emis  Rotation_dummy $controls   if  cod_emission >0 & year>=2006 , a($fe  ) vce(cluster code_prefecture) 
est  sto  ro_city_clu_cod

reghdfe   ln_nh3_emis  Rotation_dummy $controls   if  nh3_emission >0 & year>=2006 , a($fe  ) vce(cluster code_prefecture) 
est  sto  ro_city_clu_nh3

reghdfe   ln_wastewater_emis  Rotation_dummy $controls   if  wastewater_emission >0 & year>=2006 , a($fe  ) vce(cluster code_prefecture) 
est  sto  ro_city_clu_ww




//Alternative measurement of  Y
reghdfe   ln_cod_intensity  Rotation_dummy $controls  if  cod_emission >0 & year>=2006 , a($fe ) vce(cluster firm)
est  sto   ro_rede_y_cod

reghdfe   ln_nh3_intensity  Rotation_dummy $controls  if   nh3_emission >0 & year>=2006 , a($fe ) vce(cluster firm)
est  sto   ro_rede_y_nh3

reghdfe   ln_wastewater_intensity  Rotation_dummy $controls  if  wastewater_emission >0 & year>=2006 , a($fe ) vce(cluster firm)
est  sto   ro_rede_y_ww




//Redefinition of Rotation
reghdfe   ln_cod_emis  Rotation_dummy_2 $controls   if  cod_emission >0 & year>=2006 , a($fe  ) vce(cluster firm) 
est  sto   ro_rede_x_cod

reghdfe   ln_nh3_emis  Rotation_dummy_2 $controls   if  nh3_emission >0 & year>=2006 , a($fe  ) vce(cluster firm) 
est  sto   ro_rede_x_nh3

reghdfe   ln_cod_emis  Rotation_dummy_2 $controls   if  cod_emission >0 & year>=2006 , a($fe  ) vce(cluster firm) 
est  sto   ro_rede_x_ww




//Excluding special political timepoint
reghdfe   ln_cod_emis  Rotation_dummy $controls   if  cod_emission >0 & year>=2006 &year!=2007 & year!=2008 & year!=2012 & year !=2013 , a($fe  ) vce(cluster firm) 
est  sto  ro_exc_po_cod

reghdfe   ln_nh3_emis  Rotation_dummy $controls   if  nh3_emission >0 & year>=2006 &year!=2007 & year!=2008 & year!=2012 & year !=2013 , a($fe  ) vce(cluster firm) 
est  sto  ro_exc_po_nh3

reghdfe   ln_wastewater_emis  Rotation_dummy $controls   if  wastewater_emission >0 & year>=2006 &year!=2007 & year!=2008 & year!=2012 & year !=2013 , a($fe  ) vce(cluster firm) 
est  sto  ro_exc_po_ww


//Excluding 2008 crisis
reghdfe   ln_cod_emis  Rotation_dummy $controls   if  cod_emission >0 & year>=2006 & year!=2008 & year!=2009 & year!=2010 , a($fe  ) vce(cluster firm) 
est  sto  ro_exc_cri_cod
		
reghdfe   ln_nh3_emis  Rotation_dummy $controls   if  nh3_emission >0 & year>=2006 & year!=2008 & year!=2009 & year!=2010 , a($fe  ) vce(cluster firm) 
est  sto  ro_exc_cri_nh3
		
reghdfe   ln_wastewater_emis  Rotation_dummy $controls   if  wastewater_emission >0 & year>=2006 & year!=2008 & year!=2009 & year!=2010 , a($fe  ) vce(cluster firm) 
est  sto  ro_exc_cri_ww
		
		
//Excluding higher-level city
			
reghdfe   ln_cod_emission  Rotation_dummy $controls  if  cod_emission >0 & year>=2006 & provincial_capital==0, a( $fe ) vce(cluster firm) 
est  sto  ro_exc_cap_cod

reghdfe   ln_nh3_emission  Rotation_dummy $controls  if  nh3_emission >0 & year>=2006 & provincial_capital==0, a( $fe ) vce(cluster firm) 
est  sto  ro_exc_cap_nh3

reghdfe   ln_wastewater_emission  Rotation_dummy $controls  if  wastewater_emission >0 & year>=2006 & provincial_capital==0, a( $fe ) vce(cluster firm) 
est  sto  ro_exc_cap_ww





//Potential pollution subsitution
//so2
reghdfe   ln_so2_emission Rotation_dummy  $controls  if  so2_emission >0 & year>=2006 , a( $fe ) vce(cluster firm)
est sto baseline_so2_all

//nox
reghdfe   ln_nox_emission Rotation_dummy  $controls  if  nox_emission >0 & year>=2006 , a( $fe ) vce(cluster firm)
est sto baseline_nox_all

//dust
reghdfe   ln_dust_emission Rotation_dummy  $controls  if  dust_emission >0 & year>=2006 , a( $fe ) vce(cluster firm)
est sto baseline_dust_all







***********************Hetergenous analysis***********************


//Inter-provincial versus intra-provincial rotations
reghdfe   ln_cod_emis  i.Rotation   $controls  if  cod_emission  >0 & year>=2006 , a( $fe  ) vce(cluster firm)
est  sto  baseline_rtype_cod

reghdfe   ln_nh3_emis  i.Rotation   $controls  if  nh3_emission  >0 & year>=2006 , a( $fe  ) vce(cluster firm)
est  sto  baseline_rtype_nh3

reghdfe   ln_wastewater_emis  i.Rotation   $controls  if  wastewater_emission  >0 & year>=2006 , a( $fe  ) vce(cluster firm)
est  sto  baseline_rtype_ww	

cap drop _merge
merge m:1  name_prefecture  using  city_location.dta, keepusing(lat lon)
drop if  _merge==2
drop _merge
rename  (lat    lon)   (lat_movein lon_movein)

rename name_prefecture  name_prefecture_temp
rename  Moveout_city  name_prefecture 
merge m:1  name_prefecture  using  city_location.dta, keepusing(lat lon)
drop if  _merge==2
drop _merge
rename  (lat    lon)   (lat_moveout lon_moveout)
rename   name_prefecture  Moveout_city 
rename   name_prefecture_temp  name_prefecture

geodist  lat_movein lon_movein lat_moveout lon_moveout if  Moveout_city != "", gen(dist_moveout_movein)
gen ln_dist_moveout_movein = ln(dist_moveout_movein)
replace ln_dist_moveout_movein=0 if Rotation_dummy==0 //Rotation*ln_Dist
	
	
	
reghdfe   ln_cod_emis  Rotation_dummy Rotation_interprovincial ln_dist_moveout_movein $controls  if  cod_emission  >0 & year>=2006 , a( $fe  ) vce(cluster firm)
est  sto  cod_cross_boarder
reghdfe   ln_nh3_emis  Rotation_dummy Rotation_interprovincial ln_dist_moveout_movein $controls  if  nh3_emission  >0 & year>=2006 , a( $fe  ) vce(cluster firm)
est  sto   nh3_cross_boarder
reghdfe   ln_wastewater_emis  Rotation_dummy Rotation_interprovincial ln_dist_moveout_movein $controls  if  wastewater_emission  >0 & year>=2006 , a( $fe  ) vce(cluster firm)	
est sto   ww_cross_boarder



//Exchange frequencies					
reghdfe   ln_cod_emis  Rotation_dummy   Rotation_frequency_more_than_2   $controls  if  cod_emission >0 & year>=2006 , a( $fe  ) vce(cluster firm)
est sto freq_cod

reghdfe   ln_nh3_emis   Rotation_dummy   Rotation_frequency_more_than_2   $controls  if  nh3_emission >0 & year>=2006 , a( $fe  ) vce(cluster firm)
est sto freq_nh3

reghdfe   ln_wastewater_emis   Rotation_dummy Rotation_frequency_more_than_2  $controls  if  wastewater_emission >0 & year>=2006 , a( $fe  ) vce(cluster firm)
est sto freq_ww




//Hometown
cap drop Rotation_*hometown*
gen Rotation_hometown_city=Rotation_dummy*current_hometown_city


reghdfe   ln_cod_emis  Rotation_dummy Rotation_hometown_city   $controls  if  cod_emission >0 & year>=2006 , a( $fe  ) vce(cluster firm)
est sto  hometown_cod

reghdfe   ln_nh3_emis  Rotation_dummy Rotation_hometown_city   $controls  if  nh3_emission >0 & year>=2006 , a( $fe  ) vce(cluster firm)
est sto   hometown_nh3

reghdfe   ln_wastewater_emis  Rotation_dummy Rotation_hometown_city     $controls  if  wastewater_emission >0 & year>=2006 , a( $fe  ) vce(cluster firm)
est sto   hometown_ww
	

	

	






******************************Inter-city personnel exchanges of city leaders versus policy tranplantations********************************


merge m:1 name_prefecture_br year using  cosfinal.dta,keepusing(cosin_city_year_max)
drop  if  _merge==2
drop _merge

****
cap drop Rotation_transplantation Transplantation_only Rotation_only
*global  similarity "0.7246"
*global  similarity ".5680567  "
*global  similarity ".8660349 "
global similarity ".7035226"

gen Rotation_transplantation=(Rotation_dummy==1 &  cosin_city_year_max!=.  &  cosin_city_year_max>= $similarity)  
gen Transplantation_only=(Rotation_dummy==0 &  cosin_city_year_max!=.  &  cosin_city_year_max>= $similarity)  
gen Rotation_only=(Rotation_dummy==1   &  (cosin_city_year_max< $similarity | cosin_city_year_max==.))  



*******
reghdfe   ln_cod_emission   Rotation_transplantation Rotation_only   Transplantation_only    $controls  if  cod_emission >0 & year>=2006 , a( $fe  ) vce(cluster firm )
est sto  rota_tran_cod_mean

reghdfe   ln_nh3_emission   Rotation_transplantation Rotation_only   Transplantation_only    $controls  if  nh3_emission >0 & year>=2006 , a( $fe  ) vce(cluster firm )
est sto  rota_tran_nh3_mean

reghdfe   ln_wastewater_emission   Rotation_transplantation Rotation_only   Transplantation_only    $controls  if  wastewater_emission >0 & year>=2006 , a( $fe  ) vce(cluster firm )
est sto  rota_tran_wastewater_mean


******
//Figure output//

global color_type1  " "060 079 162"%70  "
global  color_type2  " "242 147 057"%70 "
global  color_type3  " "155 030 033"%70 "

global  msymbol_type1  "circle"
global  msymbol_type2  "circle"
global  msymbol_type3  "circle"

global  msize  "small"
global  recast "rspike"

cd $Path\Figure\
//cod
coefplot  (rota_tran_cod , keep(Rotation_transplantation) rename(Rotation_transplantation = "1.1"  ) color($color_type1)  ciopts(lcolor($color_type1) lpattern(solid)    recast($recast))   msymbol($msymbol_type1)   aseq(1)     ) ///
								  (rota_tran_cod , keep(Rotation_only  ) rename(  Rotation_only = "2.1" )  color($color_type2)    ciopts(lcolor($color_type2)  lpattern(solid)    recast($recast))     msymbol($msymbol_type2)   aseq(2)     ) ///
								   (rota_tran_cod , keep(Transplantation_only ) rename(Transplantation_only  = "3.1")  color($color_type3)   ciopts(  lcolor($color_type3)  lpattern(solid)    recast($recast))  msymbol($msymbol_type3)   aseq(3)     ) ///
					,  vertical eqstrict eqlabels(`" "Exchange*" "policy transplantation""'             `""Exchange" "only""'            `""Policy transplantation" "only""'     ) ///
					  yline(0, lwidth(medium) lpattern(shortdash) lcolor( gs12 )   )    grid(none) ///
					 msize($msize) levels(95) mfcolor(white)   ///
					 legend(off) ///
					 ytitle("Effects on firm water pollution" ,height(-2)) ///
					plotregion(lcolor(black))  ylabel(#5,labsize(*1.25) tlc(black))      xlabel(, labsize(*1.25)  axis(2) tlc(black))  xlabel(,nolabels axis(1) tlc(black))   yscale(lcolor(black) ) xscale(lcolor(black)) nooffsets   ///
					 saving(text_analysis_cod.gph,replace)   aspectratio(1)  
 //nh3
coefplot  (rota_tran_nh3 , keep(Rotation_transplantation) rename(Rotation_transplantation = "1.1"  ) color($color_type1)  ciopts(lcolor($color_type1) lpattern(solid)    recast($recast))   msymbol($msymbol_type1)   aseq(1)     ) ///
								  (rota_tran_nh3 , keep(Rotation_only  ) rename(  Rotation_only = "2.1" )  color($color_type2)    ciopts(lcolor($color_type2)  lpattern(solid)    recast($recast))     msymbol($msymbol_type2)   aseq(2)     ) ///
								   (rota_tran_nh3 , keep(Transplantation_only ) rename(Transplantation_only  = "3.1")  color($color_type3)   ciopts(  lcolor($color_type3)  lpattern(solid)    recast($recast))  msymbol($msymbol_type3)   aseq(3)     ) ///
					,  vertical eqstrict eqlabels(`" "Exchange*" "policy transplantation""'             `""Exchange" "only""'            `""Policy transplantation" "only""'     ) ///
					  yline(0, lwidth(medium) lpattern(shortdash) lcolor( gs12 )   )    grid(none) ///
					 msize($msize) levels(95) mfcolor(white)   ///
					 legend(off) ///
					 ytitle("Effects on firm water pollution" ,height(-2)) ///
					plotregion(lcolor(black))  ylabel(#5,labsize(*1.25) tlc(black))      xlabel(, labsize(*1.25)  axis(2) tlc(black))  xlabel(,nolabels axis(1) tlc(black))   yscale(lcolor(black) ) xscale(lcolor(black)) nooffsets   ///
					 saving(text_analysis_nh3.gph,replace)   aspectratio(1)  

 //wastewater
coefplot  (rota_tran_wastewater , keep(Rotation_transplantation) rename(Rotation_transplantation = "1.1"  ) color($color_type1)  ciopts(lcolor($color_type1) lpattern(solid)    recast($recast))   msymbol($msymbol_type1)   aseq(1)     ) ///
								  (rota_tran_wastewater , keep(Rotation_only  ) rename(  Rotation_only = "2.1" )  color($color_type2)    ciopts(lcolor($color_type2)  lpattern(solid)    recast($recast))     msymbol($msymbol_type2)   aseq(2)     ) ///
								   (rota_tran_wastewater , keep(Transplantation_only ) rename(Transplantation_only  = "3.1")  color($color_type3)   ciopts(  lcolor($color_type3)  lpattern(solid)    recast($recast))  msymbol($msymbol_type3)   aseq(3)     ) ///
					,  vertical eqstrict eqlabels(`" "Exchange*" "policy transplantation""'             `""Exchange" "only""'            `""Policy transplantation" "only""'     ) ///
					  yline(0, lwidth(medium) lpattern(shortdash) lcolor( gs12 )   )    grid(none) ///
					 msize($msize) levels(95) mfcolor(white)   ///
					 legend(off) ///
					 ytitle("Effects on firm water pollution" ,height(-2)) ///
					plotregion(lcolor(black))  ylabel(#8,labsize(*1.25) tlc(black))      xlabel(, labsize(*1.25)  axis(2) tlc(black))  xlabel(,nolabels axis(1) tlc(black))   yscale(lcolor(black) ) xscale(lcolor(black)) nooffsets   ///
					 saving(text_analysis_wastewater.gph,replace)   aspectratio(1)  

					 
cd $Path\Data\		




			
			
	
			
**********************************************

global  key_x "Rotation_transplantation Rotation_only Transplantation_only"

//production stage//
reghdfe   ln_water_consumption  $key_x    $controls  if year>=2006 & (cod_emission>0 | nh3_emission>0 | wastewater_emission>0), a( $fe  ) vce(cluster firm)
est  sto  as_p_water_consumption_mean

reghdfe   ln_fresh_water  $key_x    $controls  if year>=2006 & (cod_emission>0 | nh3_emission>0 | wastewater_emission>0), a( $fe  ) vce(cluster firm)
est  sto  as_p_fresh_water_mean

reghdfe   water_reused_rate   $key_x   $controls  if  year>=2006 & (cod_emission>0 | nh3_emission>0 | wastewater_emission>0), a( $fe  ) vce(cluster firm)
est  sto  as_p_water_reuse_rate_mean

reghdfe   ln_wastewater_generation  $key_x     $controls  if  wastewater_emission>0 & year>=2006 , a( $fe ) vce(cluster firm)
est  sto  as_p_ww_gen_mean


//end-of-pipe stage

cap gen wastewater_removal_rate=wastewater_removal / wastewater_generation

reghdfe   wastewater_removal_rate  $key_x  $controls  if    year>=2006 & wastewater_emission>0 , a( $fe  ) vce(cluster firm)
est  sto  as_e_ww_remo_rate_mean

reghdfe    ln_facility   $key_x      $controls  if   year>=2006 & (cod_emission>0 | nh3_emission>0 | wastewater_emission>0) , a($fe  ) vce(cluster firm)
est  sto  as_e_facility_n_mean

reghdfe    ln_facility_capability  $key_x   $controls  if  year>=2006 & (cod_emission>0 | nh3_emission>0 | wastewater_emission>0) , a($fe  ) vce(cluster firm)
est  sto  as_e_facility_capacity_mean




//Figure output//

global color_type1  ""060 079 162"%70"
global  color_type2  ""242 147 057"%70"
global  color_type3  ""155 030 033"%70"

global  msymbol_type1  "circle"
global  msymbol_type2  "circle"
global  msymbol_type3  "circle"

global  msize  "2pt"
global  recast "rcap"

cd $Path\Figure\
coefplot  (as_p_water_consumption , keep(Rotation_transplantation) rename(Rotation_transplantation = "1.1"  ) color($color_type1)  ciopts(lcolor($color_type1) lpattern(solid)    recast($rcap))   msymbol($msymbol_type1)   aseq(1)     ) ///
								  (as_p_water_consumption , keep(Rotation_only = "2.1" ) rename(  Rotation_only = "2.1" )  color($color_type2)    ciopts(lcolor($color_type2)  lpattern(solid)    recast($rcap))     msymbol($msymbol_type2)   aseq(1)     ) ///
								   (as_p_water_consumption , keep(Transplantation_only) rename(Transplantation_only = "3.1")  color($color_type3)   ciopts(  lcolor($color_type3)  lpattern(solid)    recast($rcap))  msymbol($msymbol_type3)   aseq(1)     ) ///
				   ( as_p_fresh_water , keep(Rotation_transplantation)  rename(Rotation_transplantation = "1.2"  )  ciopts(lcolor($color_type1)  lpattern(solid)    recast($rcap) )  color($color_type1)     msymbol($msymbol_type1)   aseq(2)) ///
								   ( as_p_fresh_water , keep(Rotation_only)  rename( Rotation_only = "2.2" )   color($color_type2)  ciopts(lcolor($color_type2)  lpattern(solid)    recast($rcap))   msymbol($msymbol_type2)   aseq(2)) ///
								   ( as_p_fresh_water , keep(Transplantation_only)  rename( Transplantation_only = "3.2")   color($color_type3)   ciopts(  lcolor($color_type3) lpattern(solid)    recast($rcap) )  msymbol($msymbol_type3)   aseq(2)) ///
				   ( as_p_water_reuse_rate , keep(Rotation_transplantation ) rename(Rotation_transplantation = "1.3" )  ciopts(lcolor($color_type1)  lpattern(solid)    recast($rcap))   color($color_type1)   msymbol($msymbol_type1)    aseq(3)) ///
								   ( as_p_water_reuse_rate , keep(Rotation_only) rename( Rotation_only = "2.3" )  color($color_type2)  ciopts(lcolor($color_type2)  lpattern(solid)    recast($rcap))   msymbol($msymbol_type2)    aseq(3)) ///
								   ( as_p_water_reuse_rate , keep(Transplantation_only) rename(Transplantation_only = "3.3")    color($color_type3)   ciopts(  lcolor($color_type3)  lpattern(solid)    recast($rcap))   msymbol($msymbol_type3)    aseq(3)) ///
				   ( as_p_ww_gen , keep(Rotation_transplantation)  rename(Rotation_transplantation = "1.4"  )  ciopts(lcolor($color_type1)  lpattern(solid)    recast($rcap))  color($color_type1)     msymbol($msymbol_type1)    aseq(4)) ///
								   ( as_p_ww_gen , keep(Rotation_only)  rename(Rotation_only = "2.4" ) color($color_type2)   ciopts(lcolor($color_type2)  lpattern(solid)    recast($rcap))   msymbol($msymbol_type2)   aseq(4)) ///
								   ( as_p_ww_gen , keep(Transplantation_only)  rename(Transplantation_only = "3.4")   color($color_type3)   ciopts(  lcolor($color_type3)  lpattern(solid)    recast($rcap))   msymbol($msymbol_type3)   aseq(4)) ///
					(as_e_ww_remo_rate , keep(Rotation_transplantation) rename(Rotation_transplantation = "1.5"  )    ciopts(lcolor($color_type1)  lpattern(solid)    recast($rcap))  color($color_type1)    msymbol($msymbol_type1)    aseq(5)) ///
									(as_e_ww_remo_rate , keep(Rotation_only) rename( Rotation_only = "2.5")  color($color_type2)    ciopts(lcolor($color_type2)  lpattern(solid)    recast($rcap))    msymbol($msymbol_type2)     aseq(5)) ///
									(as_e_ww_remo_rate , keep(Transplantation_only) rename( Transplantation_only = "3.5")     color($color_type3)   ciopts(  lcolor($color_type3)  lpattern(solid)    recast($rcap))    msymbol($msymbol_type3)   aseq(5)) ///
					(as_e_facility_n , keep(Rotation_transplantation)   rename(Rotation_transplantation = "1.6"  )  ciopts(lcolor($color_type1)  lpattern(solid)    recast($rcap))  color($color_type1)    msymbol($msymbol_type1)     aseq(6) ) ///
									(as_e_facility_n , keep(Rotation_only)   rename( Rotation_only = "2.6" )  color($color_type2)    ciopts(lcolor($color_type2)  lpattern(solid)    recast($rcap))   msymbol($msymbol_type2)   aseq(6) ) ///
									(as_e_facility_n , keep(Transplantation_only)   rename(Transplantation_only = "3.6")  color($color_type3)   ciopts(  lcolor($color_type3)  lpattern(solid)    recast($rcap))   msymbol($msymbol_type3)   aseq(6) ) ///
					(as_e_facility_capacity , keep(Rotation_transplantation)  rename(Rotation_transplantation = "1.7"  )  ciopts(lcolor($color_type1)  lpattern(solid)    recast($rcap))   color($color_type1)   msymbol($msymbol_type1)      aseq(7)) ///
									(as_e_facility_capacity , keep(Rotation_only)  rename( Rotation_only = "2.7" )  color($color_type2)     ciopts(lcolor($color_type2)  lpattern(solid)    recast($rcap))    msymbol($msymbol_type2)    aseq(7))  ///
									(as_e_facility_capacity , keep(Transplantation_only)  rename( Transplantation_only = "3.7")    color($color_type3)   ciopts(  lcolor($color_type3)  lpattern(solid)    recast($rcap) )  msymbol($msymbol_type3)    aseq(7)),  ///
					groups( 1.3   = "{bf:Production stage transition}"  2.6 = "{bf:End-of-pipe readjustment}"  )  yscale(alt axis(2) ) ///
					 eqstrict eqlabels("Industrial water consumption" "Fresh water consumption"  "Water reused rate"  "Wastewater generation" "Wastewater removal rate"  "No. of wastewater treatement facility" "Wastewater treatment capacity") ///
					xline(0, lwidth(medium) lpattern(shortdash) lcolor( gs12 )   )   yline(17, lwidth(medium) lpattern(shortdash) lcolor( gs12 )   )  legend(off)     grid(none) ///
					 msize($msize) levels(95) mfcolor(white)   ///
					xtitle(Effects of leader rotations and policy transplantations, height(5))  plotregion(lcolor(black))  xlabel(-0.1(0.025)0.05  ,labsize(*0.8))    ylabel(,labsize(*0.9) axis(3)  )  ylabel(,angle(270) labsize(*0.9)  axis(2))  ylabel(,nolabels noticks axis(1))   yscale(lcolor(black) ) xscale(lcolor(black)) nooffsets   ///
					 saving(coporate_responses.gph,replace)   aspectratio(2)  ///
					 legend(off)

					 cd $Path\Data\			



			
			
		





**************Advanced governanace experiences********************************************


//environement-related departments
cap drop  career_environ*

gen career_environment_temp_1=regexm(last_position, "环境" ) //environemnt protecteion in Chinese
gen career_environment_temp_2=regexm(last_position,  "水利" ) //water resources
gen career_environment_temp_3=regexm(last_position,  "资源" )  //(natural) resources

gen career_environment_temp=(career_environment_temp_1 ==1 | career_environment_temp_2==1  | career_environment_temp_3==1    )


bys code_prefecture mayor  name : egen career_environment = max(career_environment_temp)

cap drop  Rotation_environment_career  Rotation_non_environment 
gen Rotation_environment_career = (Rotation_dummy==1 & career_environment ==1)
gen Rotation_non_environment =(Rotation_dummy==1 & career_environment ==0)


**regressions**
reghdfe   ln_cod_emission   Rotation_environment_career  Rotation_non_environment  c.career_environment  $controls if  cod_emission >0 & year>=2006 , a(code_province#year firm) vce(cluster firm)
est  sto  career_env_cod_1


reghdfe   ln_nh3_emission   Rotation_environment_career  Rotation_non_environment  c.career_environment  $controls if  nh3_emission >0 & year>=2006 , a(code_province#year firm) vce(cluster firm)
est  sto  career_env_nh3_1

reghdfe   ln_wastewater_emission   Rotation_environment_career  Rotation_non_environment  c.career_environment  $controls if  wastewater_emission >0 & year>=2006 , a(code_province#year firm) vce(cluster firm)
est  sto  career_env_ww_1




reghdfe   ln_cod_emission  c.Rotation_dummy##c.career_environment  $controls if  cod_emission >0 & year>=2006 , a(code_province#year firm) vce(cluster firm)
est  sto  career_env_cod_2

reghdfe   ln_nh3_emission  c.Rotation_dummy##c.career_environment  $controls if  nh3_emission >0 & year>=2006 , a(code_province#year firm) vce(cluster firm)
est  sto  career_env_nh3_2

reghdfe   ln_wastewater_emission  c.Rotation_dummy##c.career_environment  $controls if  wastewater_emission >0 & year>=2006 , a(code_province#year firm) vce(cluster firm)
est  sto  career_env_ww_2



//Figure output//

global color_type1  ""060 079 162"%70"
global  color_type2  ""242 147 057"%70"
global  color_type3  ""155 030 033"%70"

global  msymbol_type1  "circle"
global  msymbol_type2  "circle"
global  msymbol_type3  "circle"

global  msize  "medlarge "
global  recast "rcap"
global  ci_width "medthick "

cd $Path\Figure\
//cod
coefplot  ( career_env_cod_1 , keep(Rotation_environment_career ) rename(Rotation_environment_career  = "1.1"  ) color($color_type1)  ciopts(lcolor($color_type1) lpattern(solid)  lwidth($ci_width)  recast($rcap))   msymbol($msymbol_type1)   aseq(1)     ) ///
								  ( career_env_cod_1, keep(Rotation_non_environment ) rename( Rotation_non_environment  = "2.1" )  color($color_type2)    ciopts(lcolor($color_type2)  lpattern(solid)  lwidth($ci_width)   recast($rcap))     msymbol($msymbol_type2)   aseq(2)     ) ///
					,  vertical ///
					  legend( position(6) r(1) order(2  "With experiences in environment-related departments" 4 "Without experiences" ) bmargin(tiny)   symysize(0)  )    ///
					  levels(95)   msize($msize)  mlwidth(medthick)   ///
					 ytitle("Effects of personnel exchange on firm water pollution") ///
					title("(a)  COD", pos(12) size(medthick)  yoffset(2) )  ylabel(,tlc(black)) xlabel(,tlc(black)) ///
					plotregion(lcolor(black)  lwidth(medium))  ylabel(#5,labsize(*1)  )       xlabel(,nolabels axis(1))   yscale(titlegap( 1)  lcolor(black) ) xscale(lcolor(black)) nooffsets ///
					 saving(career_env_cod.gph,replace)   aspectratio(1.25) 	
					 
//nh3
coefplot  ( career_env_nh3_1 , keep(Rotation_environment_career) rename(Rotation_environment_career = "1.1"  ) color($color_type1)  ciopts(lcolor($color_type1) lpattern(solid)  lwidth($ci_width)  recast($rcap))   msymbol($msymbol_type1)   aseq(1)     ) ///
								  (career_env_nh3_1, keep(Rotation_non_environment ) rename( Rotation_non_environment  = "2.1" )  color($color_type2)    ciopts(lcolor($color_type2)  lpattern(solid)  lwidth($ci_width)   recast($rcap))     msymbol($msymbol_type2)   aseq(2)     ) ///
					,  vertical ///
					  legend( position(6) r(1) order(2  "With experiences in environment-related departments" 4 "Without experiences" ) bmargin(tiny)   symysize(0)  )    ///
					  levels(95)   msize($msize)  mlwidth(medthick)   ///
					 ytitle("Effects of personnel exchange on firm water pollution") ///
					title("(b)  Ammonia nitrogen", pos(12) size(medthick)  yoffset(2) )  ylabel(,tlc(black)) xlabel(,tlc(black)) ///
					plotregion(lcolor(black)  lwidth(medium))  ylabel(-0.5(0.1)0,labsize(*1))       xlabel(,nolabels axis(1))   yscale(titlegap( 1)  lcolor(black) ) xscale(lcolor(black)) nooffsets 	  ///
					 saving(career_env_nh3.gph,replace)  		aspectratio(1.25)  
					 
//wastewater
coefplot  (career_env_ww_1 , keep(Rotation_environment_career) rename(Rotation_environment_career = "1.1"  ) color($color_type1)  ciopts(lcolor($color_type1) lpattern(solid)  lwidth($ci_width)  recast($rcap))   msymbol($msymbol_type1)   aseq(1)     ) ///
								  (career_env_ww_1 , keep(Rotation_non_environment  ) rename(Rotation_non_environment = "2.1" )  color($color_type2)    ciopts(lcolor($color_type2)  lpattern(solid)  lwidth($ci_width)   recast($rcap))     msymbol($msymbol_type2)   aseq(2)     ) ///
					,  vertical ///
					  legend( position(6) r(1) order(2  "With experiences in environment-related departments" 4 "Without experiences" ) bmargin(tiny)   symysize(0)  )    ///
					  levels(95)   msize($msize)  mlwidth(medthick)   ///
					 ytitle("Effects of personnel exchange on firm water pollution" ) ///
					title("(c)  Wastewater", pos(12) size(medthick)  yoffset(2)  )  ylabel(,tlc(black)) xlabel(,tlc(black)) ///
					plotregion(lcolor(black)  lwidth(medium))  ylabel(-0.1(0.02)0,labsize(*1))     xlabel(,nolabels axis(1))   yscale(titlegap( 1)  lcolor(black) ) xscale(lcolor(black)) nooffsets  	  ///
					 saving(career_env_wastewater.gph,replace)  aspectratio(1.25) 	


grc1leg  career_env_cod.gph    career_env_nh3.gph     career_env_wastewater.gph,  ///
		col(4) row(1) imargin(3 3 3)  graphregion(margin(tiny) fcolor(white) lcolor(white))  ///
		legendfrom(career_env_wastewater.gph) position(6) span  xsize(25) ysize(10) 
graph save career_env, replace 
		






*****from  first-mover to late-comer areas*******

**

foreach y in cod nh3 wastewater {
		gen green_pollutive_`y'=(moveout_`y'_initial_int==3 & movein_`y'_initial_int==1 ) 
		gen pollutive_pollutive_`y'=(moveout_`y'_initial_int==1 & movein_`y'_initial_int==1   &  moveout_`y'_initial_int!=. & movein_`y'_initial_int!=.  ) 
		gen green_green_`y'=(moveout_`y'_initial_int==3  & movein_`y'_initial_int==3  &  moveout_`y'_initial_int!=. & movein_`y'_initial_int!=.  ) 
		gen pollutive_green_`y'=(moveout_`y'_initial_int==1  & movein_`y'_initial_int==3   &  moveout_`y'_initial_int!=. & movein_`y'_initial_int!=.  ) 

		
		gen Rotation_g_p_`y'=(Rotation_dummy==1  &  green_pollutive_`y'==1) 	
		gen Rotation_o_`y'=(Rotation_dummy==1  &  green_pollutive_`y'==0)
}

**






*regressions*


//cod
reghdfe   ln_cod_emission  Rotation_g_p_cod Rotation_o_cod   moveout_cod_int_city_year  movein_cod_int_city_year  ///
					$controls if  cod_emission >0 & year>=2006 & _est_baseline_cod_all==1, a($fe ) vce(cluster firm)
est sto advanced_cod_1

//nh3
reghdfe   ln_nh3_emission Rotation_g_p_nh3 Rotation_o_nh3    moveout_nh3_int_city_year   movein_nh3_int_city_year  ///
					$controls if  nh3_emission >0 & year>=2006 & _est_baseline_nh3_all==1 , a($fe ) vce(cluster firm)
est sto advanced_nh3_1
	
//wastewater
reghdfe   ln_wastewater_emission Rotation_g_p_wastewater Rotation_o_wastewater   moveout_wastewater_int_city_year    movein_wastewater_int_city_year  ///
					$controls if  wastewater_emission >0  & year>=2006 & _est_baseline_ww_all==1 , a($fe ) vce(cluster firm)
est sto advanced_ww_1




//cod
reghdfe   ln_cod_emission  Rotation_dummy  Rotation_g_p_cod   moveout_cod_int_city_year  movein_cod_int_city_year  ///
					$controls if  cod_emission >0 & year>=2006 & _est_baseline_cod_all==1, a($fe ) vce(cluster firm)
est sto advanced_cod_2

//nh3
reghdfe   ln_nh3_emission Rotation_g_p_nh3  Rotation_dummy    moveout_nh3_int_city_year   movein_nh3_int_city_year  ///
					$controls if  nh3_emission >0 & year>=2006 & _est_baseline_nh3_all==1 , a($fe ) vce(cluster firm)
est sto advanced_nh3_2
	
//wastewater
reghdfe   ln_wastewater_emission Rotation_g_p_wastewater  Rotation_dummy  moveout_wastewater_int_city_year    movein_wastewater_int_city_year  ///
					$controls if  wastewater_emission >0  & year>=2006 & _est_baseline_ww_all==1 , a($fe ) vce(cluster firm)
est sto advanced_ww_2






//Figure output//			
global color_type1  ""060 079 162"%70"
global  color_type2  ""242 147 057"%70"
global  color_type3  ""155 030 033"%70"

global  msymbol_type1  "circle"
global  msymbol_type2  "circle"
global  msymbol_type3  "circle"

global  msize  "medlarge "
global  recast "rcap"
global  ci_width "medthick "

cd $Path\Figure\
//cod
coefplot  (advanced_cod_1 , keep(Rotation_g_p_cod ) rename(Rotation_g_p_cod  = "1.1"  ) color($color_type1)  ciopts(lcolor($color_type1) lpattern(solid)  lwidth($ci_width)  recast($rcap))   msymbol($msymbol_type1)   aseq(1)     ) ///
								  (advanced_cod_1 , keep(Rotation_o_cod  ) rename( Rotation_o_cod  = "2.1" )  color($color_type2)    ciopts(lcolor($color_type2)  lpattern(solid)  lwidth($ci_width)   recast($rcap))     msymbol($msymbol_type2)   aseq(2)     ) ///
					,  vertical ///
					 yline(0, lwidth(medthick) lpattern(shortdash) lcolor( black )   )    grid(none) ///
					  legend( position(6) r(1) order(2  "Exchanged from first-movers to late-comers" 4 "Other exchanges" ) bmargin(tiny)   symysize(0)  )    ///
					  levels(95)   msize($msize)  mlwidth(medthick)   ///
					 ytitle("Effects of personnel exchange on firm water pollution",height(-2.5)) ///
					title("(a)  COD", pos(12) size(medthick)  yoffset(2) )  ylabel(,tlc(black)) xlabel(,tlc(black)) ///
					plotregion(lcolor(black)  lwidth(medium))  ylabel(-0.20(0.05)0.025,labsize(*1))       xlabel(,nolabels axis(1))   yscale(titlegap( 1)  lcolor(black) ) xscale(lcolor(black)) nooffsets   ///
					 saving(advanced_goverance_cod.gph,replace)   aspectratio(1.25) 
					 
//nh3
coefplot  (advanced_nh3_1 , keep(Rotation_g_p_nh3 ) rename(Rotation_g_p_nh3  = "1.1"  ) color($color_type1)  ciopts(lcolor($color_type1) lpattern(solid)  lwidth($ci_width)  recast($rcap))   msymbol($msymbol_type1)   aseq(1)     ) ///
								  (advanced_nh3_1 , keep(Rotation_o_nh3  ) rename( Rotation_o_nh3  = "2.1" )  color($color_type2)    ciopts(lcolor($color_type2)  lpattern(solid)  lwidth($ci_width)   recast($rcap))     msymbol($msymbol_type2)   aseq(2)     ) ///
					,  vertical ///
					 yline(0, lwidth(medthick) lpattern(shortdash) lcolor( black )   )    grid(none) ///
					  legend( position(6) r(1) order(2  "Exchanged from first-movers to late-comers" 4 "Other exchanges" ) bmargin(tiny)   symysize(0)  )    ///
					  levels(95)   msize($msize)  mlwidth(medthick)   ///
					 ytitle("Effects of personnel exchange on firm water pollution",height(-2.5)) ///
					title("(b)  Ammonia nitrogen", pos(12) size(medthick)  yoffset(2) )  ylabel(,tlc(black)) xlabel(,tlc(black)) ///
					plotregion(lcolor(black)  lwidth(medium))  ylabel(-0.28(0.07)0.025,labsize(*1))       xlabel(,nolabels axis(1))   yscale(titlegap( 1)  lcolor(black) ) xscale(lcolor(black)) nooffsets   ///
					 saving(advanced_goverance_nh3.gph,replace)   aspectratio(1.25) 
					 
//wastewater
coefplot  (advanced_wastewater_1 , keep(Rotation_g_p_wastewater ) rename(Rotation_g_p_wastewater  = "1.1"  ) color($color_type1)  ciopts(lcolor($color_type1) lpattern(solid)  lwidth($ci_width)  recast($rcap))   msymbol($msymbol_type1)   aseq(1)     ) ///
								  (advanced_wastewater_1 , keep(Rotation_o_wastewater  ) rename( Rotation_o_wastewater  = "2.1" )  color($color_type2)    ciopts(lcolor($color_type2)  lpattern(solid)  lwidth($ci_width)   recast($rcap))     msymbol($msymbol_type2)   aseq(2)     ) ///
					,  vertical ///
					 yline(0, lwidth(medthick) lpattern(shortdash) lcolor( black )   )    grid(none) ///
					  legend( position(6) r(1) order(2  "Exchanged from first-movers to late-comers" 4 "Other exchanges" ) bmargin(tiny)   symysize(0)  )    ///
					  levels(95)   msize($msize)  mlwidth(medthick)   ///
					 ytitle("Effects of personnel exchange on firm water pollution",height(-2.5)) ///
					title("(c)  Wastewater", pos(12) size(medthick)  yoffset(2) )  ylabel(,tlc(black)) xlabel(,tlc(black)) ///
					plotregion(lcolor(black)  lwidth(medium))  ylabel(-0.18(0.06)0.025,labsize(*1))       xlabel(,nolabels axis(1))   yscale(titlegap( 1)  lcolor(black) ) xscale(lcolor(black)) nooffsets   ///
					 saving(advanced_goverance_wastewater.gph,replace)   aspectratio(1.25) 	
					 
grc1leg  advanced_goverance_cod.gph  advanced_goverance_nh3.gph     advanced_goverance_wastewater.gph,  ///
		col(3) row(1) imargin(3 3 3) xsize(10) ysize(5) graphregion(margin(tiny) fcolor(white) lcolor(white))  ///
		legendfrom(advanced_goverance_cod.gph)  span
		
		
graph combine advanced_goverance_cod.gph  advanced_goverance_nh3.gph     advanced_goverance_wastewater.gph,  ///
		col(3) row(1) imargin(3 3 3) xsize(20) ysize(10) graphregion(margin(tiny) fcolor(white) lcolor(white))  
graph save advanced_goverance, replace 
graph export "advanced_goverance.eps", replace
graph export "advanced_goverance.png", replace width(3000)
		
	
	
	
*Matching DD*

global psm_other_controls "ln_gdppc ln_popden  ln_expenditure_pc "


cap  drop psm* pscore* pcommon* 
cap drop pweight*

foreach y in cod  nh3 {


preserve

gen pweight_`y'=.
gen psm_`y'=.
gen pscore_`y'=.
gen pcommon_`y'=.

drop if name_prefecture=="" | mayor==.  |_est_baseline_`y'_all==0 

duplicates drop year name_prefecture mayor,force



forvalues t=2006(1)2013 {
	
	forvalues m=0(1)1 {
		psmatch2 Rotation_dummy  if year==`t' & mayor==`m' , out(ln_`y'_emission) mahal(  movein_`y'_initial_int $psm_other_controls ) n(1)
		
		replace  psm_`y'=_treated if year==`t' & mayor==`m' 
		replace  pcommon_`y'=_sup if year==`t' & mayor==`m' 
		replace  pweight_`y' = _weight if year==`t' & mayor==`m' 

	}	
}

cap drop _support  _weight  _treated
gen _support= pcommon_`y'
gen _weight= pweight_`y'
gen _treated= psm_`y'


	
keep p* code_province  name_prefecture code_prefecture  mayor  year  Rotation_dummy


save  psm_`y', replace

restore

}
*


preserve
rename movein_wastewater_initial_int  movein_ww_initial_int
gen psm_wastewater=.
gen pscore_wastewater=.
gen pcommon_wastewater=.
gen pweight_wastewater=.

drop if name_prefecture=="" | mayor==.  |_est_baseline_ww_all==0 

duplicates drop year name_prefecture mayor,force


forvalues t=2006(1)2013 {
	
	forvalues m=0(1)1 {
		
		
		psmatch2 Rotation_dummy  if year==`t' & mayor==`m' , out(ln_wastewater_emission) mahal(movein_ww_initial_int $psm_other_controls) n(1)
		
		
		replace  psm_wastewater=_treated if year==`t' & mayor==`m' 
		replace  pcommon_wastewater=_sup if year==`t' & mayor==`m' 
		replace   pweight_wastewater = _weight if year==`t' & mayor==`m' 
	
	}	
}

cap drop _support  _weight  _treated
gen _support= pcommon_wastewater
gen _weight= pweight_wastewater
gen _treated= psm_wastewater


keep p* code_province  name_prefecture code_prefecture  mayor  year  Rotation_dummy


save  psm_wastewater, replace

restore




foreach y in cod nh3 wastewater {
	
merge m:1 name_prefecture year mayor using psm_`y',keepusing(p*)

cap drop if _merge==2
cap drop _merge

}

foreach y in wastewater {
	cap drop _support _weight  _treated
	
	gen _support= pcommon_`y'
	gen _weight= pweight_`y'
	gen _treated= psm_`y'

	pstest  movein_`y'_initial_int $psm_other_controls,both graph

}


//regressions
//cod
reghdfe   ln_cod_emission Rotation_g_p_cod Rotation_o_cod     movein_cod_int_city_year $controls if pweight_cod!=. & cod_emission >0 & year>=2006 , a($fe ) vce(cluster firm)
est sto advanced_cod_3

//nh3
reghdfe   ln_nh3_emission Rotation_g_p_nh3 Rotation_o_nh3     movein_nh3_int_city_year ///
					$controls if pweight_nh3!=. &  nh3_emission >0 & year>=2006 , a($fe ) vce(cluster firm)					
est sto advanced_nh3_3

//wastewater
reghdfe   ln_wastewater_emission Rotation_g_p_wastewater Rotation_o_wastewater   movein_wastewater_int_city_year ///
					$controls if  pweight_wastewater !=. &  wastewater_emission >0  & year>=2006 , a($fe ) vce(cluster firm)
est sto advanced_ww_3



//cod
reghdfe   ln_cod_emission Rotation_dummy  Rotation_g_p_cod    movein_cod_int_city_year $controls if pweight_cod!=. & cod_emission >0 & year>=2006 , a($fe ) vce(cluster firm)
est sto advanced_cod_4

//nh3
reghdfe   ln_nh3_emission Rotation_dummy    Rotation_g_p_nh3     movein_nh3_int_city_year ///
					$controls if pweight_nh3!=. &  nh3_emission >0 & year>=2006 , a($fe ) vce(cluster firm)					
est sto advanced_nh3_4

//wastewater
reghdfe   ln_wastewater_emission Rotation_dummy     Rotation_g_p_wastewater   movein_wastewater_int_city_year ///
					$controls if  pweight_wastewater !=. &  wastewater_emission >0  & year>=2006 , a($fe ) vce(cluster firm)
est sto advanced_ww_4









	  

	  
	
	
***************chanelling resources to specific industries (green industries)**************************

//tax

gen green_industry=(emission_intensity_3digit_nq4<=2 & emission_intensity_3digit_nq4!=.)

gen Rotation_green_industry=(Rotation_dummy==1 & emission_intensity_3digit_nq4<=2)
gen Rotation_dirty_industry=(Rotation_dummy==1 & emission_intensity_3digit_nq4>2  & emission_intensity_3digit_nq4<=4 )



reghdfe   ln_tax  Rotation_dummy $controls  if  cod_emission >0 & year>=2006 , a( $fe  ) vce(cluster firm )
est sto tax_green_1

reghdfe   ln_tax  Rotation_?????_industry   c.green_industry   $controls  if  cod_emission >0 & year>=2006 , a( $fe  ) vce(cluster firm )
est sto tax_green_2

reghdfe   ln_tax  Rotation_dummy##c.green_industry   $controls  if  cod_emission >0 & year>=2006 , a( $fe  ) vce(cluster firm )
est sto tax_green_3




//Figure output//		
cd $Path\Figure

global color_type1  ""060 079 162"%70"
global  color_type2  ""242 147 057"%70"
global  color_type3  " "155 030 033"%70 "

global  msymbol_type1  "circle"
global  msymbol_type2  "circle"
global  msymbol_type3  "circle"

global  msize  "medlarge "
global  recast "rcap"
global  ci_width "medthick "

cd $Path\Figure\




coefplot  (tax_green_1 , keep( Rotation_dummy) rename(1.Rotation_dummy = "1.1"  ) color($color_type1)  ciopts(lcolor($color_type1) lpattern(solid)  lwidth($ci_width)  recast($rcap))   msymbol($msymbol_type1)   aseq(1)     ) ///
								  (tax_green_2 , keep(Rotation_green_industry   ) rename( Rotation_green_industry  = "2.1" )  color($color_type2)    ciopts(lcolor($color_type2)  lpattern(solid)  lwidth($ci_width)   recast($rcap))    msymbol($msymbol_type2)   aseq(2)     ) ///
									  (tax_green_2 , keep(Rotation_dirty_industry  ) rename(  Rotation_dirty_industry = "3.1" )  color($color_type3)    ciopts(lcolor($color_type3)  lpattern(solid)  lwidth($ci_width)   recast($rcap))      msymbol($msymbol_type3)   aseq(3)     ) ///
				,  vertical eqstrict eqlabels(`" "Overall" "effect""'    `" "Effect on" "green industries""'   `" "Effect on" "other industries""'        ) ///
					  yline(0, lwidth(medium) lpattern(shortdash) lcolor( black )   )    grid(none) ///
					  legend(off )    ///
					  levels(95)   msize($msize)  mlwidth(medthick)    ///
					 ytitle("Effects of personnel exchanges" "on corporate taxes"   ) ///
					plotregion(lcolor(black)  lwidth(medium))   ylabel(-0.08(0.02)0,labsize(*1.25) tlc(black))      xlabel(, labsize(*1.25)  axis(2) tlc(black))  xlabel(,nolabels axis(1) tlc(black))    yscale(lcolor(black) ) xscale(lcolor(black)) nooffsets   ///
					 saving(tax_cut_1028.gph,replace)   aspectratio(1.25)  
					graph export "tax_cut_1028.png", replace width(3000)




	  
	  
	  
	  
	  
	  
	  
	  
************************************Motivations***************************************


cd $Path\Data




***************Age of city leaders***************************************************

preserve
	keep if year>=2006  & year<=2013
	duplicates drop code_prefecture mayor  start_year position, force

	gen start_age=start_year-birth_year
	
	bys year code_province:egen age_median=median(leader_age)
	gen start_age_below_median=(start_age<=age_median	)
	gen start_age_vs_median=start_age-age_median	

	
	gen Rotation_dummy_forfigure=1-Rotation_dummy
	cdfplot start_age  if  start_age!=., by(Rotation_dummy_forfigure)  ///
				    plotregion(lcolor(black)  lwidth(medium)) ylabel(,labsize(*1) tlc(black))      xlabel(, labsize(*1) tlc(black))     yscale(lcolor(black) ) xscale(lcolor(black)) ///
					legend( position(6) r(1) order(1  "Exchanged city leader" 2 "Local city leader"   ) )    aspectratio(1)  ///
					xtitle("Age in the first year of a term")  saving(cdf_incentive_national.gph,replace)  
					
	cdfplot start_age_vs_median  if  start_age_vs_median!=., by(Rotation_dummy_forfigure) 		///
					   plotregion(lcolor(black)  lwidth(medium))  ylabel(,labsize(*1) tlc(black))      xlabel(, labsize(*1) tlc(black))     yscale(lcolor(black) ) xscale(lcolor(black)) ///
					legend( position(6) r(1) order(1  "Exchanged city leader" 2 "Local city leader" ) )    aspectratio(1)  ///
					xtitle("Age in the first year of a term")  saving(cdf_incentive_provincial.gph,replace)  
			

//regression
reghdfe  start_age   Rotation_dummy, noabsorb  vce(r) 
est sto start_age_m1
reghdfe  start_age   Rotation_dummy, a(year)   vce(r)
est sto start_age_m2
reghdfe  start_age   Rotation_dummy, a(code_prefecture year)  vce(r) keepsingletons
est sto start_age_m3


//figure output
global color_type1  " "060 079 162"%70  "
global  color_type2  " "242 147 057"%70 "
global  color_type3  " "155 030 033"%70 "

global  msymbol_type1  "circle"
global  msymbol_type2  "circle"
global  msymbol_type3  "circle"

global  msize  "medlarge"
global  recast "rspike"

cd $Path\Figure\
coefplot  (start_age_m1 , keep(Rotation_dummy ) rename(Rotation_dummy  = "1.1"  ) color($color_type1)  ciopts(lcolor($color_type1) lpattern(solid)    recast($recast))   msymbol($msymbol_type1)   aseq(1)     ) ///
								  (start_age_m2 , keep(Rotation_dummy   ) rename( Rotation_dummy  = "2.1" )  color($color_type2)    ciopts(lcolor($color_type2)  lpattern(solid)    recast($recast))     msymbol($msymbol_type2)   aseq(1)     ) ///
								  (start_age_m3 , keep(Rotation_dummy   ) rename(  Rotation_dummy  = "3.1" )  color($color_type3)    ciopts(lcolor($color_type3)  lpattern(solid)    recast($recast))     msymbol($msymbol_type3)   aseq(1)     ) ///
					,  vertical eqstrict eqlabels("Initial age"  ) ///
					  yline(0, lwidth(medthick) lpattern(shortdash) lcolor( black )    )    grid(none) ///
					 msize($msize) levels(95)   ///
					 legend( position(6) r(1) order(2  "Model 1" 4 "Model 2"  6 "Model 3" ) )   ///
					ytitle("Between-group differences in leaders' ages" ,height(-5)) ///
					plotregion(lcolor(black)   lwidth(medium) )  ylabel(-1(0.2)0.05,labsize(*1) tlc(black))      xlabel(, labsize(*1)  axis(2) tlc(black))  xlabel(,nolabels axis(1) tlc(black))   yscale(lcolor(black) ) xscale(lcolor(black)) nooffsets   ///
					 saving(incentive_regression_1028.gph,replace)   aspectratio(1)  
					 


					 
restore

			





**************redcution targets set by the central government*********
gen fyp=.
replace fyp=11  if   year>=2006 & year<=2010
replace fyp=12  if  year>=2011 & year<=2015

cap drop _merge
merge  m:1   name_province   fyp   using    target_cod  


/*
merge  m:1   name_province   fyp   using    target_cod

replace   target=16 if  name_prefecture == "大连市"
replace   target = 14.9  if  name_prefecture  == "宁波市"
replace   target  =  11.2     if  name_prefecture  == "厦门市"
replace   target  =  18     if  name_prefecture  == "青岛市"
*/


gen Rotation_high_target=(Rotation_dummy==1 & target_nq3==3 )
gen Rotation_medium_target=(Rotation_dummy==1 & target_nq3==2)
gen Rotation_low_target=(Rotation_dummy==1 & target_nq3==1)

gen fyp_2=fyp
replace fyp_2=2006 if fyp==11
replace fyp_2=2011 if fyp==12

gen fyp_lag= year- fyp_2+1



//Five special cities: Ningbo, Dalian, Qingdao, Xiamen and Shenzhen
gen  specific_city = (name_prefecture  == "宁波市" | name_prefecture == "大连市" | name_prefecture  == "青岛市" |  name_prefecture  == "厦门市" |  name_prefecture  == "深圳市") 





**
reghdfe   ln_cod_emission Rotation_high_target Rotation_medium_target Rotation_low_target  $controls  if  cod_emission >0 & year>=2006 , a( $fe ) vce(cluster firm)
est sto cc_central_target_cod_1
reghdfe   ln_nh3_emission  Rotation_high_target Rotation_medium_target Rotation_low_target    $controls  if  nh3_emission >0 & year>=2011 , a( $fe ) vce(cluster firm)
est sto cc_central_target_nh3_1


**
reghdfe   ln_cod_emission  Rotation_dummy  Rotation_medium_target Rotation_low_target  $controls  if  cod_emission >0 & year>=2006 , a( $fe ) vce(cluster firm)
est sto cc_central_target_cod_2
reghdfe   ln_nh3_emission  Rotation_dummy  Rotation_medium_target Rotation_low_target   $controls  if  nh3_emission >0 & year>=2011 , a( $fe ) vce(cluster firm)
est sto cc_central_target_nh3_2


**
reghdfe   ln_cod_emission Rotation_high_target Rotation_medium_target Rotation_low_target  $controls  if  cod_emission >0 & year>=2006 & _est_baseline_cod_all==1 & specific_city ==0, a( $fe ) vce(cluster firm)
est sto cc_central_target_cod_3



//Figure output//
global color_type1  " "060 079 162"%70  "
global  color_type2  " "242 147 057"%70 "
global  color_type3  ""155 030 033"%70"

global  msymbol_type1  "circle"
global  msymbol_type2  "circle"
global  msymbol_type3  "circle"

global  msize  "medlarge"
global  recast "rspike"
global  ci_width "medthick "

cd $Path\Figure\
coefplot  (cc_central_target_cod_1 , keep(Rotation_high_target) rename(Rotation_high_target = "1.1"  ) color($color_type1)  ciopts(lcolor($color_type1) lpattern(solid)   lwidth($ci_width)    recast($recast))   msymbol($msymbol_type1)   aseq(1)     ) ///
								  (cc_central_target_cod_1 , keep(Rotation_medium_target  ) rename(  Rotation_medium_target = "2.1" )  color($color_type2)    ciopts(lcolor($color_type2)  lpattern(solid)  lwidth($ci_width)     recast($recast))     msymbol($msymbol_type2)   aseq(1)     ) ///
								  (cc_central_target_cod_1 , keep(Rotation_low_target  ) rename(  Rotation_low_target = "3.1" )  color($color_type3)    ciopts(lcolor($color_type3)  lpattern(solid)  lwidth($ci_width)     recast($recast))     msymbol($msymbol_type3)   aseq(1)     ) ///
				(cc_central_target_nh3_1 , keep(Rotation_high_target) rename(Rotation_high_target = "1.2"  ) color($color_type1)  ciopts(lcolor($color_type1) lpattern(solid)   lwidth($ci_width)    recast($recast))   msymbol($msymbol_type1)   aseq(2)     ) ///
								  (cc_central_target_nh3_1, keep(Rotation_medium_target  ) rename(  Rotation_medium_target = "2.2" )  color($color_type2)    ciopts(lcolor($color_type2)  lpattern(solid)   lwidth($ci_width)    recast($recast))     msymbol($msymbol_type2)   aseq(2)     ) ///
								  (cc_central_target_nh3_1 , keep(Rotation_low_target  ) rename(  Rotation_low_target = "3.2" )  color($color_type3)    ciopts(lcolor($color_type3)  lpattern(solid)   lwidth($ci_width)    recast($recast))     msymbol($msymbol_type3)   aseq(2)     ) ///
					,  vertical eqstrict eqlabels("COD"          "Ammonia nitrogen"   ) ///
					  yline(0, lwidth(medthick) lpattern(shortdash) lcolor( black )   )    grid(none) ///
					 msize($msize) levels(95)    mlwidth(medthick)     ///
					 legend( position(6) r(1) order(2  "High target" 4  "Medium target"  6 "Low target" ) )   ///
					ytitle("Effects of personnel exchanges on firm water pollution" ,height(-5)) ///
					plotregion(lcolor(black) lwidth(medium) )   ylabel(-0.16(0.04)0.01,labsize(*1) tlc(black))      xlabel(, labsize(*1)  axis(2) tlc(black))  xlabel(,nolabels axis(1) tlc(black))   yscale(lcolor(black) ) xscale(lcolor(black)) nooffsets   ///
					 saving(assigned_targets.gph,replace)   aspectratio(1)  


		





