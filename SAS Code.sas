/* Step 1: Import data */
data OriginalSeoulBikeSharing;
   title 'Seoul Bike Sharing';
   infile 'SeoulBikeSharing.csv' delimiter=',' firstobs=2;
   input Date $ Rented_Bike_Count Hour Temperature_C Humidity_pct
         Wind_speed_m_s Visibility_10m Dew_point_temperature_C
         Solar_Radiation_MJ_m2 Rainfall_mm Snowfall_cm Seasons $
         Holiday $ Functioning_Day $;
run;


/* Step 2: Create dummy variables */
data SeoulBikeSharing;
    title 'Seoul Bike Sharing';
    infile 'SeoulBikeSharing.csv' delimiter=',' firstobs=2;
    input Date $ Rented_Bike_Count Hour Temperature_C Humidity_pct
          Wind_speed_m_s Visibility_10m Dew_point_temperature_C
          Solar_Radiation_MJ_m2 Rainfall_mm Snowfall_cm Seasons $
          Holiday $ Functioning_Day $;

    /* Converts values to uppercase and trims extra spaces */
    Seasons = upcase(trim(Seasons));
    Holiday = upcase(trim(Holiday));
    Functioning_Day = upcase(trim(Functioning_Day));

    dummy_holiday = (Holiday = "HOLIDAY");
    dummy_functioning_day = (Functioning_Day = "NO");

    dummy_winter = 0;
    dummy_spring = 0;
    dummy_summer = 0;
    dummy_autumn = 0;

    if Seasons = "WINTER" then dummy_winter = 1;
    else if Seasons = "SPRING" then dummy_spring = 1;
    else if Seasons = "SUMMER" then dummy_summer = 1;
    else if Seasons = "AUTUMN" then dummy_autumn = 1;

	    /* Getting day of week from Date and creating dummy_weekday variable */
    new_Date = input(Date, mmddyy10.);
    DayOfWeek = weekday(new_Date);
    dummy_weekday = (DayOfWeek >= 2 and DayOfWeek <= 6); /* weekdays = 1, weekends = 0 */


run;

proc sort data=SeoulBikeSharing;
   by Rented_Bike_Count;
run;

/* Step 3: plots & descriptives (histogram, scatterplots, boxplots) */
proc univariate normal;
var Rented_Bike_Count;
histogram / normal(mu=est sigma=est);
run;


proc sgplot data=SeoulBikeSharing;
   title "Rented_Bike_Count by Functioning Day";
   vbox Rented_Bike_Count / category=dummy_functioning_day;
run;

proc sgplot data=SeoulBikeSharing;
   title "Rented_Bike_Count by Holiday";
   vbox Rented_Bike_Count / category=dummy_holiday;
run;

proc sgplot data=SeoulBikeSharing;
   title "Rented_Bike_Count by Winter Season";
   vbox Rented_Bike_Count / category=dummy_winter;
run;

proc sgplot data=SeoulBikeSharing;
   title "Rented_Bike_Count by Spring Season";
   vbox Rented_Bike_Count / category=dummy_spring;
run;

proc sgplot data=SeoulBikeSharing;
   title "Rented_Bike_Count by Summer Season";
   vbox Rented_Bike_Count / category=dummy_summer;
run;

proc sgplot data=SeoulBikeSharing;
   title "Rented_Bike_Count by Autumn Season";
   vbox Rented_Bike_Count / category=dummy_autumn;
run;

proc sgplot data=SeoulBikeSharing;
   title "Rented_Bike_Count by Weekday";
   vbox Rented_Bike_Count / category=dummy_weekday;
run;



proc sgplot;
   scatter y=Rented_Bike_Count x=Hour;
   title "Rented_Bike_Count by Hour";
run;

proc sgplot;
   scatter y=Rented_Bike_Count x=Temperature_C;
   title "Rented_Bike_Count by Temperature_C";
run;

proc sgplot;
   scatter y=Rented_Bike_Count x=Humidity_pct;
   title "Rented_Bike_Count by Humidity_pct";
run;

proc sgplot;
   scatter y=Rented_Bike_Count x=Wind_speed_m_s;
   title "Rented_Bike_Count by Wind_speed_m_s";
run;

proc sgplot;
   scatter y=Rented_Bike_Count x=Visibility_10m;
   title "Rented_Bike_Count by Visibility_10m";
run;

proc sgplot;
   scatter y=Rented_Bike_Count x=Dew_point_temperature_C;
   title "Rented_Bike_Count by Dew_point_temperature_C";
run;

proc sgplot;
   scatter y=Rented_Bike_Count x=Solar_Radiation_MJ_m2;
   title "Rented_Bike_Count by Solar_Radiation_MJ_m2";
run;

proc sgplot;
   scatter y=Rented_Bike_Count x=Rainfall_mm;
   title "Rented_Bike_Count by Rainfall_mm";
run;

proc sgplot;
   scatter y=Rented_Bike_Count x=Snowfall_cm;
   title "Rented_Bike_Count by Snowfall_cm";
run;

proc corr;
var Rented_Bike_Count Hour Temperature_C Humidity_pct Wind_speed_m_s Visibility_10m
    Dew_point_temperature_C Solar_Radiation_MJ_m2 Rainfall_mm Snowfall_cm dummy_holiday
    dummy_functioning_day dummy_winter dummy_spring dummy_summer dummy_autumn dummy_weekday;
run;



/* Step 4: Run full model
	Check for multicollinearity, outliers, influential, model assumptions:
		homoscedasticity (constant variance), independence, linearity, normality
	Fix Issues -> Transformation*/

proc reg data=SeoulBikeSharing;
	   model Rented_Bike_Count = Hour Temperature_C Humidity_pct Wind_speed_m_s Visibility_10m
       Dew_point_temperature_C Solar_Radiation_MJ_m2 Rainfall_mm Snowfall_cm dummy_holiday
       dummy_functioning_day dummy_winter dummy_spring dummy_summer dummy_autumn dummy_weekday
       / rsquare stb corrb influence vif r;
	plot student.*predicted.; *No transformation needed, already normalized;
	plot student.*(Hour Temperature_C Humidity_pct Wind_speed_m_s Visibility_10m Dew_point_temperature_C Solar_Radiation_MJ_m2 Rainfall_mm Snowfall_cm dummy_holiday dummy_functioning_day dummy_winter dummy_spring dummy_summer dummy_autumn dummy_weekday);
	plot npp.*student.;
    title 'Linear regression model - Rented Bike Count prediction';
run; *dummy_autumn was set to 0 to avoid multicollinearity issues;

*Outliers & influential points removed from data set;
data SeoulBikeSharing2;
set SeoulBikeSharing;
if _n_ in (272 305 356 368 452 476 499 537 539 615 623 644 663 665 687 880 953 974 991 1251 1327 1350 1434 1537 1548 1574 1626 1725 1727 1879 1917 1996 1999 2075 2168 2212 2279 2424 2425 2539 2626 2742 2753 2765 2846 2903 2961 3046 3353 3513 3547 3778 4269 4482 4497 4506 4551 4605 4613 4625 4633 4674 4690 4702 4721 4773 4788 4808 4917 5116 5431 5644 6891 6924 7057 7105 7363 7632 7655 7665 7671 7709 7746 7749 7770 7793 7812 7817 7818 7824 7833 7864 7884 7889 7902 7904 7908 7917 7939 7980 8015 8018 8025 8037 8044 8045 8065 8073 8075 8097 8118 8124 8131 8142 8144 8147 8148 8159 8160 8162 8165 8169 8172 8173 8176 8187 8194 8197 8211 8215 8222 8240 8251 8256 8261 8266 8270 8272 8273 8277 8280 8284 8293 8302 8305 8310 8317 8321 8331 8336 8338 8346 8354 8355 8362 8380 8384 8385 8388 8405 8409 8410 841 8424 8426 8458 8465 8471 8478 8504 8505 8514 8519) then delete;
run;

proc reg data=SeoulBikeSharing2;
	   model Rented_Bike_Count = Hour Temperature_C Humidity_pct Wind_speed_m_s Visibility_10m
       Dew_point_temperature_C Solar_Radiation_MJ_m2 Rainfall_mm Snowfall_cm dummy_holiday
       dummy_functioning_day dummy_winter dummy_spring dummy_summer dummy_autumn dummy_weekday
       / rsquare stb corrb influence vif r;
	plot student.*predicted.; *No transformation needed, already normalized;
	plot student.*(Hour Temperature_C Humidity_pct Wind_speed_m_s Visibility_10m Dew_point_temperature_C Solar_Radiation_MJ_m2 Rainfall_mm Snowfall_cm dummy_holiday dummy_functioning_day dummy_winter dummy_spring dummy_summer dummy_autumn dummy_weekday);
	plot npp.*student.;
    title 'Linear regression model - Rented Bike Count prediction';
run;


/* Removing variables one-by-one that have a Variance Inflation Factor > 10 to avoid multicollinearity */
proc reg data=SeoulBikeSharing2;
	   model Rented_Bike_Count = Hour Temperature_C Humidity_pct Wind_speed_m_s Visibility_10m
       Solar_Radiation_MJ_m2 Rainfall_mm Snowfall_cm dummy_holiday dummy_functioning_day dummy_winter
       dummy_spring dummy_summer dummy_autumn dummy_weekday / vif;
	   title 'Removed Dew_point_temperature_C';
run;

/* Step 5: split data into train and test set */
proc surveyselect data=SeoulBikeSharing2 out=xv_all seed=495857
samprate=0.80 outall;
title 'Training and Testing Dataset'
run;
/*proc print; *selected = 1 is training, selected = 0 is testing;*/
/*run;*/


/* Step 6: Run model selection on Train set only
	Obtain final model, recheck assumptions (step 4), fix issues*/
data xv_all;
set xv_all;
if selected = 1 then new_y = Rented_Bike_count;
run;
proc print;


/*Stepwise selection, NOT Used - Inaccurate Output
proc reg data=training;
title 'Stepwise Model';
   model Rented_Bike_Count = Hour Temperature_C Humidity_pct Wind_speed_m_s Visibility_10m
       Solar_Radiation_MJ_m2 Rainfall_mm Snowfall_cm dummy_holiday dummy_functioning_day dummy_winter
       dummy_spring dummy_summer dummy_autumn dummy_weekday / selection = stepwise STB;
run;
*/

/*ADJRSQ selection, USED - Same Model as Backwards and Cp
proc reg data=training;
title 'ADJRSQ Model';
   model Rented_Bike_Count = Hour Temperature_C Humidity_pct Wind_speed_m_s Visibility_10m
       Solar_Radiation_MJ_m2 Rainfall_mm Snowfall_cm dummy_holiday dummy_functioning_day dummy_winter
       dummy_spring dummy_summer dummy_autumn dummy_weekday / selection = adjrsq STB;
run;
*/

/*Forwards Elim selection, NOT Used - Inaccurate Output
proc reg data=training;
title 'Forward Selection Model';
model Rented_Bike_Count = Hour / selection=forward STB; *Hour is most significant predictor so we start with that;
run;
*/

/* Mallows' Cp selection, USED - Same Modelas ADJRSQ and Backwards
proc reg data=training;
title 'Mallows Cp Selection Model';
model Rented_Bike_Count = Hour Temperature_C Humidity_pct Wind_speed_m_s Visibility_10m
    Solar_Radiation_MJ_m2 Rainfall_mm Snowfall_cm dummy_holiday dummy_functioning_day dummy_winter
    dummy_spring dummy_summer dummy_autumn dummy_weekday / selection=cp STB;
run;
*/

/*Backwards Elim selection, USED - Same Model as ADJRSQ and Cp*/
proc reg data=xv_all;
title 'Backward Elimination Model';
model new_y = Hour Temperature_C Humidity_pct Wind_speed_m_s Visibility_10m
    Solar_Radiation_MJ_m2 Rainfall_mm Snowfall_cm dummy_holiday dummy_functioning_day dummy_winter
    dummy_spring dummy_summer dummy_autumn dummy_weekday / selection=backward STB;
run;


/* Mallows'cp, backwards elim, and adjrq were the most accurate and were all the same
These models all Removed dummy_weekday, dummy_autumn, Visibility_10m*/
proc reg data=xv_all;
  model new_y = Hour Temperature_C Humidity_pct Wind_speed_m_s Solar_Radiation_MJ_m2
        Rainfall_mm Snowfall_cm dummy_holiday dummy_functioning_day dummy_winter dummy_spring
        dummy_summer / r STB VIF influence;
  plot student.*residual.; 
  plot npp.*student.;
  title 'Selected Model (training)';
run;

*Rechecking assumptions in plots and desciptive. Removing more outliers did NOT further improve model;
proc univariate normal;
  var new_y;
  histogram / normal(mu=est sigma=est);
run;

proc sgplot;
  title "new_y x Hour";
  scatter y=new_y x=Hour;
run;

proc sgplot;
  title "new_y x Temperature_C";
  scatter y=new_y x=Temperature_C;
run;

proc sgplot;
  title "new_y x Humidity_pct";
  scatter y=new_y x=Humidity_pct;
run;

proc sgplot;
  title "new_y x Wind_speed_m_s";
  scatter y=new_y x=Wind_speed_m_s;
run;

proc sgplot;
  title "new_y x Solar_Radiation_MJ_m2";
  scatter y=new_y x=Solar_Radiation_MJ_m2;
run;

proc sgplot;
  title "new_y x Rainfall_mm";
  scatter y=new_y x=Rainfall_mm;
run;

proc sgplot;
  title "new_y x Snowfall_cm";
  scatter y=new_y x=Snowfall_cm;
run;


proc sgplot;
  title "new_y by dummy_holiday";
  vbox new_y / category=dummy_holiday;
run;

proc sgplot;
  title "new_y by dummy_functioning_day";
  vbox new_y / category=dummy_functioning_day;
run;

proc sgplot;
  title "new_y by dummy_winter";
  vbox new_y / category=dummy_winter;
run;

proc sgplot;
  title "new_y by dummy_spring";
  vbox new_y / category=dummy_spring;
run;

proc sgplot;
  title "new_y by dummy_summer";
  vbox new_y / category=dummy_summer;
run;

proc sgplot;
  title "new_y by dummy_autumn";
  vbox new_y / category=dummy_autumn;
run;



/*Step 7 & 8: Compute test performance*/
/*	compute y_hat*/
/*	compute y - y_hat and |y - y_hat|, MAE and RMSE*/
/*	compute R^2 for test set*/
/*	cross validated R^2 between train and set */

proc reg data=xv_all;
 model new_y = Hour Temperature_C Humidity_pct Wind_speed_m_s Solar_Radiation_MJ_m2
                            Rainfall_mm Snowfall_cm dummy_holiday dummy_functioning_day dummy_winter
                            dummy_spring dummy_summer / r;
output  out=outml(where=(new_y=.)) p=yhat;
run;
data outml_sum;
set outml;
title 'Observed vs Predicted in the (20%) test set';
d= Rented_Bike_Count - yhat;
absd=abs(d); *Absolute Difference;
run;
proc summary data=outml_sum;
var d absd;
output out=outml_stats std(d)=rmse mean(absd)=mae;
run;
proc print data = outml_stats ;
title 'Model Validation';
run;
proc corr data=outml;
var Rented_Bike_Count yhat;
run;


/* Step 9: If only 1 model (YES) (train -> test), Compare models*/
proc glmselect data=SeoulBikeSharing2
plots=(asePlot Criteria);
model Rented_Bike_Count = Hour Temperature_C Humidity_pct Wind_speed_m_s Solar_Radiation_MJ_m2
        Rainfall_mm Snowfall_cm dummy_holiday dummy_functioning_day dummy_winter dummy_spring
        dummy_summer / selection=backward(stop=cv) cvMethod=split(5) cvDetails=all;
run;
proc glmselect data=SeoulBikeSharing2
	plots=(asePlot Criteria);
	partition fraction(test=0.20);
	model Rented_Bike_Count = Hour Temperature_C Humidity_pct Wind_speed_m_s Solar_Radiation_MJ_m2
        Rainfall_mm Snowfall_cm dummy_holiday dummy_functioning_day dummy_winter dummy_spring
        dummy_summer / selection=backward(stop=cv) cvMethod=split(5) cvDetails=all;
run;

/* Step 10: Compute predictions 
	Make up values to substitute*/

data new;
input Hour Temperature_C Humidity_pct Wind_speed_m_s Solar_Radiation_MJ_m2
      Rainfall_mm Snowfall_cm dummy_holiday dummy_functioning_day dummy_winter dummy_spring
      dummy_summer;
datalines;
6 0 35 1 0 0 0 0 1 0 0 1 
12 0 40 1 0 0 0 0 1 0 1 0 
18 0 45 1 0 0 0 0 1 1 0 0
;
run;
proc print;
run;
data predictions;
title 'prediction set';
set new xv_all;
run;
proc print;
run;
proc reg data = predictions;
title 'predictions';
model new_y =Hour Temperature_C Humidity_pct Wind_speed_m_s Solar_Radiation_MJ_m2
      Rainfall_mm Snowfall_cm dummy_holiday dummy_functioning_day dummy_winter dummy_spring
      dummy_summer /cli clm r p alpha = 0.05;
run;




