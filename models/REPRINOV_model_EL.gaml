/***
* Name: REPRINOV
* Author: laclefel
* Description: Version 1 (V1)

***/
model REPRINOV

//----------------------------------------------------------------------------
// GLOBAL ATTRIBUTS AND PARAMETERS
//----------------------------------------------------------------------------
global {
	string scenario <- "scenar1";
	bool transition <- false;
	bool end_simulation <- false;
	///////////////////////////////////////////	
	///////////////TRANSITION/////////////////	
	reflex scenario_transition {
		if (scenario = "scenar0") {
			AI <- true;
			AI_youngs <- true;
			hormon_shot <- true;
			hormon_shot_youngs <- true;
		}

		if (production_season_number = 2 and current_date = first(farmer).ram_introduction add_months 11 and scenario = "scenar1") {
			transition <- true;
			//write current_date + scenario color: #purple;
			AI <- true;
			AI_youngs <- false;
			hormon_shot <- false;
			hormon_shot_youngs <- false;
			male_female_ratio <- 1 / 30;
		}

		if (production_season_number = 2 and current_date = first(farmer).ram_introduction add_months 11 and scenario = "scenar2") {
			transition <- true;
			// write current_date + scenario color: #purple;
			AI <- false;
			AI_youngs <- false;
			hormon_shot <- false;
			hormon_shot_youngs <- false;
			male_female_ratio <- 1 / 30;
		}

	}
	////////////////////////////////////	

	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////		
	//////Loading all external source files///////
	csv_file data2 <- csv_file("../includes/ROQ/Management_dates.csv", ";", true);
	csv_file data3 <- csv_file("../includes/ROQ/All_parametersvalues.csv", ";", true);
	file data_grazing_periods <- csv_file("../includes/ROQ/Grazing_periods.csv", ";", true);
	file data_diet <- csv_file("../includes/ROQ/Diets.csv", ";", true);
	file data_feed <- csv_file("../includes/ROQ/Feed.csv", ";", true);
	file data_surfaces <- csv_file("../includes/ROQ/Yields.csv", ";", true); // surface file
	file data_eco_loads <- csv_file("../includes/ROQ/Eco_Loads.csv", ";", true); //loads
	file data_eco_products <- csv_file("../includes/ROQ/Eco_Products.csv", ";", true); //products
	file data_eco_subsidies <- csv_file("../includes/ROQ/Eco_Subsidies.csv", ";", true); //subsidies
	file data_parameters_GHG <- csv_file("../includes/ROQ/Enviro_parametres.csv", ";", true);
	file data_type_surfaces <- csv_file("../includes/ROQ/Surfaces_used.csv", ";", true);
	//loading the diets file for the concerned farm
	file data_nutrition_periods <- csv_file("../includes/ROQ/Feeding_periods.csv", ";", true);

	////// declaration of maps which will be used to stock parameters values:
	map<string, float> map_param_eco_products <- map<string, float>(data_eco_products);
	map<string, float> map_param_eco_loads <- map<string, float>(data_eco_loads);
	map<string, float> map_param_eco_subsidies <- map<string, float>(data_eco_subsidies);
	map<string, float> map_param_GHG <- map<string, float>(data_parameters_GHG);
	map<date, float> daily_consumed_grass; // map of monthly grazed consumed per day in kg MS
	// Creation of associated matrices
	matrix dates <- matrix(data2);
	matrix all_parameters <- matrix(data3);
	matrix mat_periodes <- matrix(data_nutrition_periods);
	matrix mat_grazing_periods <- matrix(data_grazing_periods);
	matrix mat_surfaces <- matrix(data_type_surfaces);
	list<float> grass_resources_evolution;
	matrix mat_alim <- matrix(data_feed);
	matrix mat_diet <- matrix(data_diet);
	matrix mat_coupes <- matrix(data_surfaces);
	matrix mat_eco_products <- matrix(data_eco_products);
	matrix mat_eco_loads <- matrix(data_eco_loads);
	matrix mat_eco_subsidies <- matrix(data_eco_subsidies);

	//INITIALIZATION AND VISUALIZATION OF AGENTS//
	float marge <- 1.0 parameter: "margin between icons" category: "visualization";
	float ewes_space_width <- 60.0 parameter: "width of the ewe space" category: "visualization";
	float icon_size_max <- 2.0 parameter: "max icon size" category: "visualization";
	float icon_size;
	map<string, rgb> ewes_state_color <- ["in anoestrus"::#blue, "in heat"::#red, "gestating"::#orange, "lactating"::#purple];
	map<string, rgb> rams_state_color <- ["resting"::#yellow, "active"::#violet];
	geometry background_ewes;
	geometry background_rams;
	geometry background_breeder;

	//General characteristics of the system to be filled in//
	date starting_date <- date(2016, 6, 9);
	float step <- 12 #hours;
	bool AI <- true parameter: "AI" category: "Reproduction management";
	bool AI_youngs <- true parameter: "AI_young" category: "Reproduction management";
	bool hormon_shot <- true parameter: "Hormonal treatment" category: "Reproduction management";
	bool hormon_shot_youngs <- true parameter: "Hormonal treatment young" category: "Reproduction management";
	bool ram_autorenewal <- false; ///  self-renewal for the rams of the flock
	bool ewe_autorenewal <- true; ///  self-renewal for the ewe-lambs of the flock
	float male_female_ratio <- 1 / 70;

	init {
		EMP <- 370; ///initial average number of ewes present in the flock
		///Initialization of cutting date for forage surfaces of the farm
		cut_dates[1] <- date(2016, 5, 1);
		cut_dates[2] <- date(2016, 6, 1);
		cut_dates[3] <- date(2016, 8, 1);
		////////////////////////////////////////////////////*Agents creation and attributs initialization*///////////////////////////////////////////////////////////////////////////	
		create farmer number: 1 {
			create surface from: data_surfaces with:
			[id::int(get("id_parc")), type:: int(get("id_type_parc")), mod_exp_s::string(get("id_mod_expl_comp")), mod_exp::string(get("id_mod_exp")), size::float(get("size")), rotation_duration::float(get("ratation_duration")), amendment::int(get("amend_CaO")), ferti_N::int(get("ferti_N")), ferti_P::int(get("ferti_P")), ferti_K::int(get("ferti_K")), yield_cut1::float(get("yield mowing1")), yield_cut2::float(get("yield mowing2")), yield_cut3::float(get("rdt mowing3")), yield_cut4::float(get("yield mowing4")), straw_yield::float(get("yield straw")), cereal_yield::float(get("yield_cereal")), $fertilizer::float(get("$_fertilizer_per_ha")), $seed::float(get("$_seed_per_ha")), $treatment::float(get("$_treatment_per_ha")), $amendment::float(get("$_amendment_per_ha")), $other_cost::float(get("$_other_cost_per_ha")), ferti_implantation_cost::float(get("ferti_impl_cost")), seed_implantation_cost::float(get("seed_impl_cost")), treatment_implantation_cost::float(get("treat_impl_cost"))]
			{
				myself.my_surfaces << self;
				my_farmer <- myself;
			}

			create ewe number: adult_batch_size {
				myself.my_ewes << self;
				my_farmer <- myself;
				BCS <- min(5.0, max(1.0, gauss(2.5, 0.3)));
				age <- min(7, max(1, poisson(2)));
				ewe_initial_milk_prod <- min(5.0, max(1.0, gauss(ewe_initial_milk_prod_mean, 0.5)));
				ewelamb_initial_milk_prod <- min(5.0, max(1.0, gauss(ewelamb_initial_milk_prod_mean, 0.5)));
				lact_num <- age + 1;
				days_since_lambing <- int(gauss(200, 30));
				estimated_total_milk_production <- gauss(350.0, 50.0);
				Ctl[4] <- min(2500.0, max(200.0, gauss(1300.0, 300.0))); ///last milk monitoring value
				newborn <- false;
				renew <- false;
				father_index <- rnd(80, 120);
				nutrition_state <- "maintenance";
				weight <- 75.0;
				milk_prod[lact_num] <- [];
				MFC_init_value <- 60.7;
				MPC_init_value <- 45.9;
			}

			create ewe number: young_batch_size {
				myself.my_ewes << self;
				my_farmer <- myself;
				BCS <- min(5.0, max(1.0, gauss(2.5, 0.3)));
				ewe_initial_milk_prod <- min(5.0, max(1.0, gauss(ewe_initial_milk_prod_mean, 0.5)));
				ewelamb_initial_milk_prod <- min(5.0, max(1.0, gauss(ewelamb_initial_milk_prod_mean, 0.5)));
				age <- 0;
				lact_num <- 0;
				days_since_lambing <- 0;
				estimated_total_milk_production <- 0.0;
				newborn <- false;
				renew <- true;
				father_index <- rnd(80, 120);
				nutrition_state <- "maintenance";
				weight <- 50.0;
				Ctl[4] <- 0.0;
				milk_prod[lact_num] <- [0];
				MFC_init_value <- 60.7;
				MPC_init_value <- 45.9;
			}

			flock_size <- length(my_ewes);
			write "flock_size: " + flock_size;
			flock_size_current_production_season[production_season_number] <- flock_size;
			flock_MFC <- mean(ewe collect (each.MFC_init_value));
			flock_MPC <- mean(ewe collect (each.MPC_init_value));
			create ram number: round(length(ewe) * male_female_ratio) {
				myself.my_rams << self;
				newborn <- false;
				my_farmer <- myself;
				age <- rnd(2, 4); ///random distribution of the age of the rams in the flock
				father_index <- rnd(80, 120);
				state <- "male";
				renew <- false;
			}

			nb_renew_ram <- int(1 / 3 * length(ram));
			create feed from: data_diet with:
			[diet_group::int(get("id_batch")), diet_period::int(get("id_period")), feed_type::int(get("id_feed")), feed_qty::float(get("qty_or_h_pasture")), batch_name::string(get("id_batch_name"))]
			{
				myself.my_diets << self;
				my_farmer <- myself;
			}

		}

		do compute_visualisation; ///Command to view the agents in image (see action entitled compte_visualisation)
		//////////////////////////////////////////////////////////////////////////*End of agents creation and attributs initialization*///////////////////////////////////////////////////////////////////////////	

	}
	///Command to view the agents in image
	action compute_visualisation {
		ask farmer {
			location <- {10, 8};
		}

		float y_size <- 80.0;
		icon_size <- icon_size_max;
		int ewes_nb <- length(ewe);
		int rams_nb <- length(ram);
		int max_cpt_x <- int((ewes_space_width - 4) / (icon_size + marge));
		int max_cpt_y <- int(y_size / (icon_size + marge));
		int nb_places <- max_cpt_x * max_cpt_y;
		loop while: ewes_nb > nb_places {
			icon_size <- icon_size * 0.9;
			max_cpt_x <- int((ewes_space_width - 4) / (icon_size + marge));
			max_cpt_y <- int(y_size / (icon_size + marge));
			nb_places <- max_cpt_x * max_cpt_y;
		}

		int cpt_x;
		int cpt_y;
		ask ewe {
			location <- {5 + icon_size + cpt_x * (icon_size + marge), 14 + icon_size + cpt_y * (icon_size + marge)};
			cpt_x <- cpt_x + 1;
			if (cpt_x > max_cpt_x) {
				cpt_x <- 0;
				cpt_y <- cpt_y + 1;
			}

		}

		float yy <- int((world.shape.width - ewes_space_width - (icon_size * 2))) - 3 * marge - 2 * icon_size;
		max_cpt_x <- int((yy - 5) / (icon_size + marge));
		cpt_x <- 0;
		cpt_y <- 0;
		ask ram {
			location <- {5 + ewes_space_width + icon_size * 2 + cpt_x * (icon_size + marge), 14 + icon_size + cpt_y * (icon_size + marge)};
			cpt_x <- cpt_x + 1;
			if (cpt_x > max_cpt_x) {
				cpt_x <- 0;
				cpt_y <- cpt_y + 1;
			}

		}

		background_breeder <- rectangle(90, 10) at_location {50, 8};
		background_ewes <- rectangle(ewes_space_width, y_size) at_location {ewes_space_width / 2 + 5, y_size / 2 + 14};
		background_rams <- rectangle(yy, y_size) at_location {ewes_space_width + 2 * marge + 2 * icon_size_max + yy / 2, y_size / 2 + 14};
	}

	reflex update_visualisation {
		do compute_visualisation;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	///////////INPUT DATA FROM INPUT FOLDERS//////////////
	///PARAMETERS RELATIVE TO EWE REPRODUCTION ///////////
	int flock_size;
	int adult_batch_size <- int(all_parameters[2, 29]);
	int young_batch_size <- int(all_parameters[2, 30]);
	int nb_ewe_to_be_insem1;
	int nb_ewelamb_to_be_insem1;
	int nb_ewe_to_be_insem2;
	int nb_of_insemination;
	float repro_age_of_ewe_lambs;
	float ewe_renewal_rate_from_AI; //% of renewal coming from AI
	float ram_renewal_rate_from_AI;
	float youngs_from_AI_rate;
	int AI_index <- rnd(100, 120); // supposedly the breeder chooses semens with an average to very good index
	float easy_lambing <- float(all_parameters[2, 0]); /*probability of giving birth without problems */
	float proba_abortion <- float(all_parameters[2, 1]);
	float synchronization_rate <- float(all_parameters[2, 3]);
	float to_portee_2 <- float(all_parameters[2, 4]); //  proba rate for litter size = 2
	float to_portee_3 <- float(all_parameters[2, 16]); //  proba rate for litter size = 3
	float mortality_rate <- float(all_parameters[2, 14]);
	float to_ingested_hour_grazed <- float(all_parameters[2, 28]);

	reflex change_AI_semen when: every(#year) {
		AI_index <- rnd(100, 120);
	}

	///PARAMETERS RELATIVE TO EWE LACTATION ////////////
	int suckling_duration <- int(all_parameters[2, 2]); //4 weeks suckling in the Roquefort area
	float prod_min <- float(all_parameters[2, 5]);
	float ewelamb_initial_milk_prod_mean <- float(all_parameters[2, 6]);
	float ewe_initial_milk_prod_mean <- float(all_parameters[2, 7]);
	float proba_hp <- float(all_parameters[2, 8]);
	int EMP;

	///PARAMETERS RELATIVE TO HUMAN MANAGEMENT /////////
	date start_grazing_date <- date(string(dates[2, 12]) split_with ","); // date of the beginning of the grazed period 
	date end_grazing_date <- date(string(dates[2, 13]) split_with ","); // date of the end of the grazed period
	date cereal_cut_date <- date(2016, 7, 1); ///next harvet date for cereals
	int nb_graz_day <- int(end_grazing_date - start_grazing_date); //number of days the sheep are on pasture
	int nb_confinement_day <- 365 - nb_graz_day; //number of days the sheep are in confinement	
	int flock_milking_days;
	int production_season_number <- 0;
	int number_of_milk_monitoring <- int(all_parameters[2, 21]);
	int culling_age <- int(all_parameters[2, 9]);
	int ewesonly_free_mating_duration <- int(all_parameters[2, 12]); //fixed giving the reference case values
	int male_effect_duration <- int(all_parameters[2, 15]); //Male effect duration
	int working_time_per_ewe_during_lambing <- int(all_parameters[2, 31]); //in hours
	int fixed_time_work_during_milking <- int(all_parameters[2, 33]); // in minutes
	float proba_AI_sucess <- float(all_parameters[2, 10]);
	float young_proba_AI_sucess <- float(all_parameters[2, 20]);
	float turnover_rate <- float(all_parameters[2, 11]);
	float genetic_gain_for_milk_prod <- float(all_parameters[2, 13]);
	float genetic_gain_for_MFC <- float(all_parameters[2, 26]);
	float genetic_gain_for_MPC <- float(all_parameters[2, 27]);
	float AI_rate <- float(all_parameters[2, 17]); //Percentage of AI in the adult batch 
	float youngs_AI_rate <- float(all_parameters[2, 18]); //Percentage of AI in the youngs batch 
	float youngs_synchronization_rate <- float(all_parameters[2, 19]);
	float EffPDI <- float(all_parameters[2, 23]); //PDI efficiency (g/g) for a good quality alfalfa hay distributed at libitum
	float detection_rate <- float(all_parameters[2, 22]);
	float working_time_per_milking_round <- float(all_parameters[2, 32]); // in minutes
	map<int, date> cut_dates;

	///PARAMETERS RELATIVE FARM SURFACES/////////
	///////// production per season for grazing on grazed surfaces
	date beg_graz_period_begSpring <- date(string(mat_grazing_periods[4, 0]) split_with ",");
	date end_graz_period_begSpring <- date(string(mat_grazing_periods[5, 0]) split_with ",");
	date beg_graz_period_Spring <- date(string(mat_grazing_periods[4, 1]) split_with ",");
	date end_graz_period_Spring <- date(string(mat_grazing_periods[5, 1]) split_with ",");
	date beg_graz_period_Summer <- date(string(mat_grazing_periods[4, 2]) split_with ",");
	date end_graz_period_Summer <- date(string(mat_grazing_periods[5, 2]) split_with ",");
	date beg_graz_period_Autumn <- date(string(mat_grazing_periods[4, 3]) split_with ",");
	date end_graz_period_Autumn <- date(string(mat_grazing_periods[5, 3]) split_with ",");
	date beg_graz_period_Winter <- date(string(mat_grazing_periods[4, 4]) split_with ",");
	date end_graz_period_Winter <- date(string(mat_grazing_periods[5, 4]) split_with ",");

	///PARAMETERS RELATIVE TO FARM ECONOMY AND ENVIRONNEMENTAL IMPACT ///////////
	// input parameters for production variables
	float milk_reference_price <- map_param_eco_products['eco_milk']; //price for an average fat content of 70 g/l and an average protein content of 50 g/l
	map<int, date> deb_period_milk_price;
	map<int, date> end_period_milk_price;
	// inputs parameters for environemental indicators calculation :
	float fe_manure_bat <- map_param_GHG['CH4_mbat_fe']; // manure emission factor in bat
	float fe_manure_past <- map_param_GHG['CH4_mpat_fe']; // emission factor of dejections at the pat
	float to_CH4_C <- map_param_GHG['to_CH4_C'];
	float to_CO2_C <- map_param_GHG['to_CO2_C'];
	float fe_elec <- map_param_GHG['fe_elec']; //emission factor (in kg CO2 eq/per kwh consumed)
	float fe_input <- map_param_GHG['fe_input']; // emission factor (in kg CO2 eq/per Kg of feed input bought)
	float fe_forage_input <- map_param_GHG['fe_forage_bought'];
	float Ym <- map_param_GHG['ym']; //methane conversion facteur for feed gross energy
	float awms_bat <- map_param_GHG['AWMS_bat'];
	float awms_pat <- map_param_GHG['AWMS_pat'];
	float GE_intake_adult <- map_param_GHG['GE_adult']; ///gross energy intake in MJ/animal/day
	float GE_intake_young <- map_param_GHG['GE_young'];
	float GE_intake_rams <- map_param_GHG['GE_rams'];
	float mean_nrj_consum_per_l <- map_param_GHG['mean_nrj_consum_per_l']; /// reference value in kwh/l of milk 
	float daily_milking_water_consum <- map_param_GHG['daily_water_consum']; //water consumption during the milking period
	float fixed_nrj_conso_during_milking <- 0.0136; //kwh/l of milk
	float nrj_conso_per_milking_round <- 2.06; ///kwh/day for a basis of 48 ewes 

	/////////////////*OUTPUTS DEFINITION*/////////////////////
	// declaration of output variables:
	int number_of_ewes_starting_heating;
	int number_of_ewelamb_starting_heating;
	int number_of_ewes_coming_back_into_heat;
	int number_of_gestating_females;
	int number_of_ewes_lambing;
	int number_of_ewes_entering_milking;
	int young_ewes_sales;
	int young_ram_sales;
	int nb_ram_bought;
	int nb_ewes_bought;
	int number_of_AI_lambings;
	int number_of_youngs_from_AI;
	int total_lambing_count;
	int lambing_count_day <- 0;
	int daily_AI_lambings <- 0;
	int newborn_count_day <- 0;
	int nb_culled_fem; // nb of culled females
	int nb_culled_mal; // nb of culled females
	int nb_culled_ad_tot; // nb of culled females+males
	int nb_of_fem_born;
	int nb_of_male_born;
	int nb_of_newborn;
	int young_mortality;
	float total_work_during_milking; //in hours
	int total_lambing_work_time; //in hours
	float htmp_day <- 0.0 with_precision 2;
	float sales_youngs;
	float forage_sold;
	float forage_bought;
	float grain_sold;
	float grain_bought;
	float straw_sold;
	float straw_bought;
	float $_milk_without_pp;
	float $_milk;
	float ref_MFC <- 70.0 with_precision 2; // reference fat content in g/l
	float ref_MPC <- 50.0 with_precision 2; // reference protein content in g/l
	float flock_MFC;
	float flock_MPC;
	float stock_forage_tot <- 0.0 with_precision 2; // quantity of forage produced
	float stock_grain <- 0.0 with_precision 2; // quantity of grain produced
	float stock_straw <- 0.0 with_precision 2; // quantity of straw produced
	float grazed_qty_to_subtract;
	float total_grazing;
	float total_grazed_qty_available_over_year;
	//float nrj_cons;///energy consomation (energy relative to electricity uses only) for the giving farm (in kwh/year)
	float nrj_conso;
	float ch4_ent; //  CH4 from enteric fermentation
	float ch4_manure;
	float ch4_manure_bat;
	float ch4_manure_past;
	list<ewe> ewes_per_lambing_dates;
	list<float> htmp_days;
	list<ewe> ewe_that_produced;
	map<string, float> coeff_ch4_ent; //sheep enteric CH4 emission coefficient
	map<string, float> manure_volatil_solid;
	map<int, float> fertility_rate;
	map<int, float> flock_size_current_production_season;
	map<string, float> grazed_day; // map of monthly grazed days per surface
	map<string, float> grazed_day_ugb; // map of monthly grazed days per ugb
	map<string, float> feed_distributed; /*to store the amount of feed distributed*/
	map<date, float> flock_bes_UFL;
	map<date, float> flock_bes_PDI;
	map<string, float> total_energy_intake;
	map<string, float> total_protein_intake;
	map<date, int> nb_dry_or_maintening_ewes;
	map<date, int> nb_dry_or_maintening_ewelambs;
	map<date, int> nb_gestating_ewes;
	map<date, int> nb_gestating_ewelambs;
	map<date, int> nb_lactating_ewes;
	map<date, int> nb_lactating_ewelambs;
	map<date, int> nb_suckling_ewes;
	map<date, int> nb_suckling_ewelambs;
	map<int, float> htmp; /*total milk prod of the flock*/
	map<int, float> $_milk2;
	map<date, int> lambing_count_days2;
	map<date, int> AI_lambing_count_day;
	map<date, float> htmp_days2;
	map<date, int> newborn_count_days2;
	map<int, float> htmp_month;
	map<date, int> size_grazing_batch;
	map<date, int> milking_work_time; /*working time during milking*/
	map<date, int> lambing_work_time; /*working time during lambing*/
	float total_water_consum;

	reflex lambing_count when: every(#day) {
		lambing_count_days2[current_date] <- lambing_count_day;
		AI_lambing_count_day[current_date] <- daily_AI_lambings;
		if (lambing_count_day >= 8) {
			lambing_work_time[current_date] <- 24;
		}

		if (lambing_count_day < 8) {
			lambing_work_time[current_date] <- working_time_per_ewe_during_lambing * lambing_count_day;
		}

		total_lambing_work_time <- total_lambing_work_time + last(lambing_work_time);
		lambing_count_day <- 0;
		daily_AI_lambings <- 0;
	}

	reflex newborn_counting when: every(#day) {
		newborn_count_days2[current_date] <- newborn_count_day;
		newborn_count_day <- 0;
	}

	reflex htmp_calcul when: every(#day) {
		htmp_days <+ htmp_day;
		htmp_days2[current_date] <- htmp_day;
		htmp_day <- 0.0;
	}

	reflex milk_price_calculation when: current_date.day = 1 and current_date.hour = 0 {
		float price_milk_month; //milk price + premiums linked to the milk fat and protein content
		/*Calcul of price of milk for the month according to milk quality */
		price_milk_month <- (1 / 2 * milk_reference_price) * (flock_MFC / ref_MFC + flock_MPC / ref_MPC);
		htmp_month[current_date.month] <- htmp_days sum_of each;
		$_milk <- $_milk + (htmp_month[current_date.month] / 1000 * price_milk_month);
		htmp_days <- [];
	}

	reflex reset_donnees when: every(1 #day) {
		number_of_ewes_starting_heating <- 0;
		number_of_ewelamb_starting_heating <- 0;
		number_of_ewes_coming_back_into_heat <- 0;
		number_of_gestating_females <- 0;
		number_of_ewes_lambing <- 0;
		number_of_ewes_entering_milking <- 0;
	}

	reflex sauvegarde1 when: cycle != 0 and every(#year) {
		save
		[current_date.year, self.scenario, self.name, self.production_season_number, last(self.flock_size_current_production_season), last(self.fertility_rate), self.nb_of_insemination / last(self.flock_size_current_production_season), self.number_of_AI_lambings / self.total_lambing_count, self.youngs_from_AI_rate, self.ewe_renewal_rate_from_AI, self.ram_renewal_rate_from_AI]
		to: "Results_ROQ/Results_repro_results_percentage.csv" type: csv rewrite: false header: false;
		save
		[current_date.year, self.scenario, self.name, self.production_season_number, last(self.flock_size_current_production_season), self.total_lambing_count, self.total_lambing_work_time, self.total_lambing_work_time / self.total_lambing_count, self.nb_of_insemination, self.number_of_AI_lambings, self.nb_of_newborn, number_of_youngs_from_AI, young_mortality, sales_youngs, self.repro_age_of_ewe_lambs]
		to: "Results_ROQ/Results_repro_results_numbers.csv" type: csv rewrite: false header: false;
		total_lambing_count <- 0;
		total_lambing_work_time <- 0;
		number_of_AI_lambings <- 0;
		number_of_youngs_from_AI <- 0;
		nb_of_insemination <- 0;
		nb_of_fem_born <- 0;
		nb_of_male_born <- 0;
		nb_of_newborn <- 0;
		young_mortality <- 0;
	}

	reflex sauvegarde2 when: current_date > end_grazing_date {
	//save matrix([self.name],["total_grass_conso"],[sum(daily_consumed_grass) / 1000] )to: "Results_ROQ1/total_grass_consomation"+current_date.year+".txt" type: "text" rewrite: true header: false //divisé par 1000 pour avoir la valeur en T de MS
		loop e over: daily_consumed_grass.keys {
			save [self.scenario, self.name, e, production_season_number, self.daily_consumed_grass[e]] to: "Results_ROQ/daily_grazing.csv" rewrite: false type: csv;
		}

		loop e over: size_grazing_batch.keys {
			save [self.scenario, self.name, e, production_season_number, self.size_grazing_batch[e]] to: "Results_ROQ/grazing_batch.csv" rewrite: false type: csv;
		}

	}

	reflex sauvegarde3 when: current_date = first(farmer).end_delivery_date add_hours 12 {
		save
		[current_date.year, self.scenario, self.name, self.production_season_number, length(self.ewe_that_produced), last(self.htmp), last(self.htmp) / length(self.ewe_that_produced), self.total_work_during_milking, self.total_work_during_milking / last(self.htmp), self.total_work_during_milking / length(self.ewe_that_produced)]
		to: "Results_ROQ/Results_htmp_and_milking_work.csv" rewrite: false header: true type: csv;
		total_work_during_milking <- 0.0;
	}

	float agric_use_area;
	float crop_use_area;
	float rangelands_use_area;
	float forage_use_area;
	float forage_distributed;
	float forage_balance;
	float grain_distributed;
	float grain_balance;
	float straw_for_beding;
	float straw_distributed;
	float straw_balance;
	float concentrates_distributed;
	float $_young_sales;
	float buy_repro_female;
	float buy_repro_male;
	float $_culled_male;
	float $_culled_female;
	float $wool;
	float $_supp_forage;
	float $_grain;
	float $_straw;
	float $_feed_loads;
	float $hormonal_treatment;
	float $AI;
	float $_diverses_loads;
	float $_op_loads_milkprod_workshop;
	float $_surf_vege_loads;
	float $_gp_milkprod_workshop;
	float $_surf_vege_product;
	float $_gp_without_subsidies;
	float $_operating_loads;
	float $gross_marging_whithout_subsidies;
	float $_gp_milkprod_workshop_per_l_of_milk;
	float $_surf_vege_product_per_l_of_milk;
	float $_gp_without_subsidies_per_l_of_milk;
	float $_op_loads_milkprod_workshop_per_l_of_milk;
	float $_surf_vege_loads_per_l_of_milk;
	float $_operating_loads_per_l_of_milk;
	float $gross_marging_whithout_subsidies_per_l_of_milk;
	float ch4_ent_per_l_of_milk;
	float VS_rate <- 8.2; //Reference value from IPCC2019 for sheep
	float ch4_manure_per_l_of_milk;
	float CH4_emission_tot;
	float CH4_emission_per_l_of_milk;
	float CO2_emissions_elec;
	float CO2_emissions_elec_per_l_of_milk;
	float CO2_emissions_feed_input;
	float CO2_emissions_feed_input_per_l_of_milk;
	float water_consumption; ///en litres
	float water_consumption_per_l_of_milk;
	float forage_perl;
	float concentrates_perl;
	list<surface> Surfaces_tot;
	list<surface> crop_area;
	list<surface> rangelands_area;
	list<surface> forage_area;
	////////////Calculation of economic and environmental indicators (set to occur before the begining of the expected suckling period por the first ewes producing during the year)/////// 
	reflex maj_indicateurs when: (current_date.month = 11 and current_date.day = 16 and current_date.hour = 0) {
		Surfaces_tot <- list(surface);
		agric_use_area <- Surfaces_tot sum_of (each.size);
		//write sample(agric_use_area);
		crop_area <- Surfaces_tot where (each.cereal_yield > 0.0);
		crop_use_area <- crop_area sum_of (each.size);
		//write sample(crop_use_area);
		rangelands_area <- Surfaces_tot where (each.mod_exp = "PARCOURS");
		rangelands_use_area <- rangelands_area sum_of (each.size);
		forage_area <- Surfaces_tot where ((each.mod_exp = "SFP"));
		forage_use_area <- forage_area sum_of (each.size);
		//write sample(forage_use_area);
		cereal_cut_date <- cereal_cut_date add_years 1;

		////forage balance
		forage_distributed <-
		feed_distributed['foin1C_lzdvent'] + feed_distributed['foin2C_lzdvent'] + feed_distributed['foin3C_lzdvent'] + feed_distributed['foin1C_rg_apres_deprimage'] + feed_distributed['foin_PT'] + feed_distributed['enrubannage'] + feed_distributed['ensilage'];
		forage_balance <- stock_forage_tot - forage_distributed;
		if (forage_balance > 0) {
			forage_sold <- forage_balance;
			forage_bought <- 0.0;
		} else {
			forage_bought <- (-forage_balance);
			forage_sold <- 0.0;
		}
		///grain balance
		grain_distributed <- feed_distributed["orge"];
		grain_balance <- stock_grain - grain_distributed;
		if (grain_balance > 0) {
			grain_sold <- grain_balance;
			grain_bought <- 0.0;
		} else {
			grain_bought <- (-grain_balance);
			grain_sold <- 0.0;
		}
		//straw balance
		straw_for_beding <- 0.17 * EMP; // according to standard cases of the Roquefort are 0,17 Tons of straw/ewe are needed
		straw_distributed <- feed_distributed["paille"] + straw_for_beding;
		straw_balance <- stock_straw - straw_distributed;
		if (straw_balance > 0) {
			straw_sold <- straw_balance;
			straw_bought <- 0.0;
		} else {
			straw_bought <- (-straw_balance);
			straw_sold <- 0.0;
		}
		///Concentrates distributed=concentrates bought
		concentrates_distributed <- feed_distributed["alim_complet_agnelles"] + feed_distributed["complementaire_tourteau"] + feed_distributed["premier_age"];

		// ---------------------------------------------------------------
		// Economic indicators calculation :
		// ---------------------------------------------------------------
		// animal gross product :
		$_young_sales <- sales_youngs * map_param_eco_products['eco_y'];
		buy_repro_female <- nb_ewes_bought * map_param_eco_products['eco_female'];
		buy_repro_male <- nb_ram_bought * map_param_eco_products['eco_male'];
		$_culled_male <- nb_culled_mal * map_param_eco_products['eco_culM'];
		$_culled_female <- nb_culled_fem * map_param_eco_products['eco_culF'];
		$wool <- flock_size * map_param_eco_products['eco_wool'];

		// ---------------------------------------------------------------
		// vegetal gross product :
		$_supp_forage <- forage_sold * map_param_eco_products['eco_forage']; // forage sale
		$_grain <- grain_sold * map_param_eco_products['eco_grain']; // cereals sale
		$_straw <- straw_sold * map_param_eco_products['eco_straw']; // straw sale
		// ---------------------------------------------------------------
		// animal operating loads :	
		$_feed_loads <-
		grain_bought * map_param_eco_products['eco_grain'] + feed_distributed["alim_complet_agnelles"] * map_param_eco_products['eco_alim_agn'] + feed_distributed["complementaire_tourteau"] * map_param_eco_products['eco_compl_tourt'] + feed_distributed["premier_age"] * map_param_eco_products['eco_1rst_age'] + (straw_bought * map_param_eco_products['eco_straw']) + (forage_bought * map_param_eco_products['eco_forage']);
		if (hormon_shot) {
			$hormonal_treatment <-
			(adult_batch_size * synchronization_rate + young_batch_size * youngs_synchronization_rate) * (map_param_eco_loads['cost_horm_sponge'] + map_param_eco_loads['cost_pmsg']);
		} else {
			$hormonal_treatment <- 0.0;
		}

		if (AI) {
			$AI <- nb_of_insemination * map_param_eco_loads['cost_AI'];
		} else {
			$AI <- 0.0;
		}

		$_diverses_loads <-
		$hormonal_treatment + $AI + map_param_eco_loads['cost_other_repro'] + EMP * (map_param_eco_loads['cost_vet'] + map_param_eco_loads['cost_casual_labour'] + map_param_eco_loads['cost_CMV'] + map_param_eco_loads['cost_milk_monitoring']);
		$_op_loads_milkprod_workshop <- $_feed_loads + $_diverses_loads + map_param_eco_loads['cost_fees'];

		// ---------------------------------------------------------------
		// vegetal operating loads :
		$_surf_vege_loads <- Surfaces_tot sum_of (each.$surface_care_cost);

		// ---------------------------------------------------------------
		// Gross product :
		$_gp_milkprod_workshop <- last($_milk2) + $_young_sales - buy_repro_female - buy_repro_male + $_culled_male + $_culled_female + $wool;
		$_surf_vege_product <- $_supp_forage + $_grain + $_straw;
		$_gp_without_subsidies <- $_gp_milkprod_workshop + $_surf_vege_product;

		// ---------------------------------------------------------------
		// Loads:
		$_operating_loads <- $_op_loads_milkprod_workshop + $_surf_vege_loads;
		$gross_marging_whithout_subsidies <- $_gp_without_subsidies - $_operating_loads;

		///////////////* GHG Emissions*/////////////////////////////////////////////////////
		// CH4 emissions +  CO2 emissions
		coeff_ch4_ent["adult_ewes"] <- (GE_intake_adult * Ym) / 55.65;
		coeff_ch4_ent["adult_rams"] <- (GE_intake_rams * Ym) / 55.65;
		coeff_ch4_ent["youngs"] <- (GE_intake_young * Ym) / 55.65;
		ch4_ent <- (coeff_ch4_ent["adult_ewes"] * adult_batch_size + coeff_ch4_ent["adult_rams"] * length(ram where
		(each.age >= 1)) + coeff_ch4_ent["youngs"] * young_batch_size) * to_CH4_C;

		//-------- CH4 manure management :
		manure_volatil_solid["adult_ewes"] <- (VS_rate * 75 / 1000) * 365; ///average weight of this category =75kg
		manure_volatil_solid["youngs"] <- (VS_rate * 47 / 1000) * 365; ///average weight of this category =47kg
		manure_volatil_solid["adult_rams"] <- (VS_rate * 75 / 1000) * 365;
		ch4_manure_bat <- (manure_volatil_solid["adult_ewes"] * adult_batch_size * awms_bat * fe_manure_bat) / 1000 + (manure_volatil_solid["adult_rams"] * length(ram where
		(each.age >= 0)) * awms_bat * fe_manure_bat) / 1000 + (manure_volatil_solid["youngs"] * young_batch_size * awms_bat * fe_manure_bat) / 1000;
		ch4_manure_past <- (manure_volatil_solid["adult_ewes"] * adult_batch_size * awms_pat * fe_manure_past) / 1000 + (manure_volatil_solid["adult_rams"] * length(ram where
		(each.age >= 0)) * awms_pat * fe_manure_past) / 1000 + (manure_volatil_solid["youngs"] * young_batch_size * awms_pat * fe_manure_past) / 1000;
		ch4_manure <- (ch4_manure_bat + ch4_manure_past) * to_CH4_C; ///*  to_CH4_C to get the value in kg eq CO2
		CH4_emission_tot <- (ch4_ent + ch4_manure);

		///////////////--------------CO2
		// nergy consumption of the dairy sheep workshop
		CO2_emissions_elec <- nrj_conso * fe_elec;
		CO2_emissions_feed_input <- ((concentrates_distributed+grain_bought) * fe_input + forage_bought * fe_forage_input) * 10 ^ 3;
		//calculation of C02 emissions from the purchase of concentrates;10^3 to pass qty of concentrates and forage purchased in kg 

		///////////////----------WATER
		water_consumption <- (daily_milking_water_consum * flock_milking_days + total_water_consum); ///en litres
		if (production_season_number > 0) {
			ch4_ent_per_l_of_milk <- ch4_ent / last(htmp);
			ch4_manure_per_l_of_milk <- ch4_manure / last(htmp);
			CH4_emission_per_l_of_milk <- CH4_emission_tot / last(htmp);
			CO2_emissions_elec_per_l_of_milk <- CO2_emissions_elec / last(htmp);
			CO2_emissions_feed_input_per_l_of_milk <- CO2_emissions_feed_input / last(htmp);
			water_consumption_per_l_of_milk <- water_consumption / last(htmp);
			$_gp_milkprod_workshop_per_l_of_milk <- $_gp_milkprod_workshop / last(htmp);
			$_surf_vege_product_per_l_of_milk <- $_surf_vege_product / last(htmp);
			$_gp_without_subsidies_per_l_of_milk <- $_gp_without_subsidies / last(htmp);
			$_op_loads_milkprod_workshop_per_l_of_milk <- $_op_loads_milkprod_workshop / last(htmp);
			$_surf_vege_loads_per_l_of_milk <- $_surf_vege_loads / last(htmp);
			$_operating_loads_per_l_of_milk <- $_operating_loads / last(htmp);
			$gross_marging_whithout_subsidies_per_l_of_milk <- $gross_marging_whithout_subsidies / last(htmp);
			forage_perl <- forage_distributed / last(htmp);
			concentrates_perl <- (concentrates_distributed + grain_distributed) / last(htmp);
		}

		//--------------------------------------------------
		// End of GHG indicators calculation 
		//--------------------------------------------------
		//Saving results on csv files
		string lala <- "";
		lala <- lala + current_date.year + "," + self.scenario + "," + self.name;
		loop v over: feed_distributed.values {
			lala <- lala + "," + v;
		}

		save lala to: "Results_ROQ/distributed_feed.csv" type: csv rewrite: false;
		save [current_date.year, self.scenario, self.name, self.sales_youngs, self.nb_culled_fem, self.nb_culled_mal] to: "Results_ROQ/prod_other_indicators.csv" type: csv rewrite:
		false header: false;
		save
		[current_date.year, self.scenario, self.name, self.forage_distributed, (self.concentrates_distributed + self.grain_distributed), self.straw_distributed, self.stock_forage_tot, self.stock_grain, self.stock_straw, self.forage_perl, self.concentrates_perl]
		to: "Results_ROQ/vegetal_prod_indicators.csv" type: csv rewrite: false header: false;
		save
		[current_date.year, self.scenario, self.name, $_gp_milkprod_workshop, $_surf_vege_product, $_gp_without_subsidies, $_op_loads_milkprod_workshop, $_surf_vege_loads, $_operating_loads, $gross_marging_whithout_subsidies]
		to: "Results_ROQ/economic_indicators.csv" type: csv rewrite: false header: false;
		save
		[current_date.year, self.scenario, self.name, $_gp_milkprod_workshop_per_l_of_milk, $_surf_vege_product_per_l_of_milk, $_gp_without_subsidies_per_l_of_milk, $_op_loads_milkprod_workshop_per_l_of_milk, $_surf_vege_loads_per_l_of_milk, $_operating_loads_per_l_of_milk, $gross_marging_whithout_subsidies_per_l_of_milk]
		to: "Results_ROQ/economic_indicators_per_litre.csv" type: csv rewrite: false header: false;
		save
		[current_date.year, self.scenario, self.name, ch4_ent, ch4_ent_per_l_of_milk, ch4_manure, ch4_manure_per_l_of_milk, CH4_emission_tot, CH4_emission_per_l_of_milk, nrj_conso, CO2_emissions_elec, CO2_emissions_elec_per_l_of_milk, CO2_emissions_feed_input, CO2_emissions_feed_input_per_l_of_milk, water_consumption, water_consumption_per_l_of_milk]
		to: "Results_ROQ/environnemental_indicators.csv" type: csv rewrite: false header: false;
	}

	reflex maj_year2 when: current_date.month = 11 and current_date.day = 17 and current_date.hour = 0 {
		stock_forage_tot <- 0.0;
		stock_grain <- 0.0;
		stock_straw <- 0.0;
		feed_distributed[] <- 0;
		grazed_day_ugb[] <- 0.0;
		young_ewes_sales <- 0;
		young_ram_sales <- 0;
		nb_ram_bought <- 0;
		nb_ewes_bought <- 0;
		sales_youngs <- 0.0;
		nb_culled_fem <- 0;
		nb_culled_mal <- 0;
		nb_culled_ad_tot <- 0;
		total_water_consum <- 0.0;
		nrj_conso <- 0.0;
	}

	// ---------------------------------------------------------------
	// GHG indicators calculation :
	// ---------------------------------------------------------------
	reflex sauvegarde4 when: production_season_number = 12 {
		loop d over: lambing_count_days2.keys {
			save [self.scenario, self.name, d, production_season_number, self.lambing_count_days2[d], self.AI_lambing_count_day[d], self.newborn_count_days2[d], self.lambing_work_time[d]]
			to: "Results_ROQ/Results_LCW_per_day.csv" rewrite: false type: csv;
		}

		loop p over: htmp_days2.keys {
			save [self.scenario, self.name, p, production_season_number, self.htmp_days2[p], self.milking_work_time[p]] to: "Results_ROQ/Results_HTMP_per_day.csv" rewrite: false type: csv;
		}

		loop e over: nb_dry_or_maintening_ewes.keys {
			save [self.scenario, self.name, e, self.flock_bes_PDI[e], self.flock_bes_UFL[e]] to: "Results_ROQ/Results_nutri_requirements_flock.csv" rewrite: false type: csv;
		}

		loop e over: nb_dry_or_maintening_ewes.keys {
			save [self.scenario, self.name, e, nb_dry_or_maintening_ewes[e], nb_gestating_ewes[e], nb_suckling_ewes[e], nb_lactating_ewes[e]] to:
			"Results_ROQ/Results_ewes_physio_stage.csv" rewrite: false type: csv;
		}

	}

	reflex ending_simulation when: production_season_number = 12 {
	//do pause;
		end_simulation <- true;
	}

}

////////////End of global part//////////////////////

//----------------------------------------------------------------------------
// AGENTS SHEEP :
//----------------------------------------------------------------------------
species sheep {
	date birth_date; /*sheep birth date*/
	int age;
	float weight; //live weight for Lacaune ewes
	float dwc; //daily water consumption for sheep watering
	bool newborn <- true;
	bool weaned <- false;
	bool culling_for_age <- false; /*Assigned to ewes or rams selected for culling because of their age*/
	bool renew <- false;
	bool lamb_from_AI <- false; //young from AI
	svg_file icon;
	farmer my_farmer;
	string father_name;
	string nutrition_state;

	reflex aging when: cycle != 0 and ((current_date = my_farmer.ram_introduction) or (current_date = my_farmer.sponge)) {
		age <- age + 1;
		newborn <- false;
		ask (ewe where (each.nutrition_state = "growing")) {
			nutrition_state <- "maintenance";
		}

	}

	reflex young_mortality_calculation when: newborn and not weaned and current_date = birth_date add_days suckling_duration {
		if (flip(mortality_rate)) {
			young_mortality <- young_mortality + 1;
			ask (ewe) {
				my_farmer.my_ewes >> self;
			}

			ask (ram) {
				my_farmer.my_rams >> self;
			}

			do die;
		} else {
			weaned <- true;
		} }

	rgb couleur {
		return #white;
	}

	aspect default {
	/*graphic representation */
		draw icon size: icon_size / 2 + (icon_size / 2 * age / 10) color: couleur() rotate: 180;
	}

}

//----------------------------------------------------------------------------
// AGENTS RAM :
//----------------------------------------------------------------------------
species ram parent: sheep {
	svg_file icon <- svg_file("../includes/ram.svg");
	rgb couleur <- #yellow;
	bool active <- false;
	bool active_for_ewelambs <- false;
	float proba_mating_success <- 0.5;
	string state <- "resting";
	int father_index; //genetic index of the fathers
	rgb couleur {
		return rams_state_color[state];
	}

	init {
		nutrition_state <- "male";
	}

	reflex udpdate_nutri_state when: nutrition_state = "growing_male" and age = 0 {
		nutrition_state <- "male";
	}
	
	reflex auto_renewal_ram when:ram_autorenewal and weaned and (length(ram where (each.newborn and each.weaned and each.renew)) < my_farmer.nb_renew_ram){
		renew <- true;
	}

	reflex water_consumption_of_males when: every(#day) {
		if (age < 0) {
			dwc <- 1.5;
		}

		if (age >= 0 and age < 1) {
			dwc <- 2.5;
		}

		if (age >= 1 and current_date.month between (6, 10)) {
			dwc <- 2.43;
		} else {
			dwc <- 4.06;
		}

	}

	reflex mating when: every(#day) and active {
		list<ewe> empty_ewe <- ewe where (each.age >= 1 and each.in_heat and not each.gestating);
		/*write name + brebis_vides + "brebis_vides" + current_date;*/
		if not empty(empty_ewe) {
			ask (empty_ewe where (each.father_name = nil or each.father_name != father_name)) {
				gestating <- flip(myself.proba_mating_success);
				if (gestating) {
				//write name + " -> a ete luttee" + current_date;
					gestating <- true;
					index_of_mate <- myself.father_index;
					father_name <- myself.name;
					state <- "gestating";
					if (not lactating) {
						nutrition_state <- "maintenance";
					}

					couleur <- #orange;
					start_gestation <- current_date;
					number_of_gestating_females <- number_of_gestating_females + 1;
					in_heat <- false;
					first_heat <- false;
				}

			}

		}

	}

	reflex mating_ewelambs when: every(#day) and active_for_ewelambs {
		list<ewe> empty_ewelambs <- ewe where (each.renew and each.in_heat and not each.gestating);
		/*write name + brebis_vides + "brebis_vides" + current_date;*/
		if not empty(empty_ewelambs) {
			ask (empty_ewelambs where (each.father_name = nil or each.father_name != father_name)) {
				gestating <- flip(myself.proba_mating_success);
				if (gestating) {
				//write name + " -> a ete luttee" + current_date;
					gestating <- true;
					index_of_mate <- myself.father_index;
					father_name <- myself.name;
					state <- "gestating";
					if (not lactating) {
						nutrition_state <- "maintenance";
					}

					couleur <- #orange;
					start_gestation <- current_date;
					number_of_gestating_females <- number_of_gestating_females + 1;
					in_heat <- false;
					first_heat <- false;
				}

			}

		}

	}

}

//----------------------------------------------------------------------------
// AGENTS EWE :
//----------------------------------------------------------------------------
species ewe parent: sheep {
	svg_file icon <- svg_file("../includes/ewe.svg");
	rgb couleur <- #blue;
	bool in_anoestrus <- true;
	bool in_heat <- false;
	bool first_heat <- false;
	bool gestating <- false;
	bool gave_birth <- false;
	bool suckling <- false;
	bool lactating <- false;
	bool cyclic <- false;
	bool MER <- false;
	bool abortion <- false;
	bool culling <- false; /*reform */
	bool latecomer <- false;
	bool health_problem <- false;
	bool to_be_inseminate <- false;
	bool culling_for_perf <- false;
	bool AI_lambs <- false; //ewe pregenat following AI
	bool to_portee <- false; // proba to have a litter size =2
	bool to_portee3 <- false; //proba to have a litter size =3
	bool producing_ewe <- false;
	float age_at_repro;
	float BCS;
	float MFC;
	float MPC;
	float MFC_init_value;
	float MPC_init_value;
	float ewe_initial_milk_prod;
	float ewelamb_initial_milk_prod;
	float estimated_total_milk_production;
	float proba_cyclic;
	float proba_MER;
	float besUFL_gest;
	float besUFL_suck;
	float besPDI_suck;
	float besUFL_maint;
	float besPDI_maint;
	float besUFL_MY;
	float besUFL_gain;
	float besPDI_MY;
	float besPDI_gest;
	float bes_UFL_tot;
	float bes_PDI_tot;
	float weight_gain_of_youngs_during_suck <- 350.0 with_precision 2; //weight gain of the litter during the first 3 weeks of lactation (in g/d)
	int lit_size <- 1; // initial litter size=1 by default and then changes during gestation with the proba of having on other litter size
	int foetusweigth <- 7; //Average litter weight for a 70kg Lacaune ewe with 2 lambs (INRAtion)
	int number_of_milking_days;
	int gestating_week;
	int week_before_lambing;
	int lact_num;
	int day_of_first_heat;
	int day_of_first_heat_ewelamb <- rnd(0, 17);
	int day_of_first_heat_with_AI <- 2;
	int gestation_duration <- int(min(157.0, max(145.0, gauss(147.0, 5.0)))); /* gestation duration is between 147 and 157 j */
	int day_of_abortion <- rnd(5, 140);
	int days_since_lambing;
	int index_of_mate; //genetic index of the ram with which it mates
	int father_index; ///genetic index of the father
	map<int, date> lambing_date;
	map<int, float> Ctl;
	map<int, float> Constante;
	map<int, date> start_milking;
	map<int, list<float>> milk_prod; /*mapping of the milk production to keep the daily production value and calculate the total production */
	map<int, date> end_of_milking_date;
	date start_gestation;
	date abortion_date;
	date start_heating;
	string state <- "in anoestrus";
	rgb couleur {
		return ewes_state_color[state];
	}

	reflex BCS_evolution_with_age when: cycle != 0 and every(#year) {
		if (lact_num > 1) {
		//BCS at mating evolution of the adult multiparous  
			BCS <- BCS - 0.1;
		}

		if (age = 1 and lact_num = 1) {
		//BCS at mating evolution of the primiparous 
			BCS <- BCS + 0.2;
		}

	}
	reflex auto_renewal_ewe when:ewe_autorenewal and weaned and (length(ewe where (each.newborn and each.weaned and each.renew)) < my_farmer.nb_renew_ewe){
		renew <- true;
	}

	///////////////////////////////water consum////////////////////////
	reflex calcul_water_consum when: every(#day) {
		if (not renew and not lactating) {
			if (current_date.month between (6, 10)) {
				dwc <- 2.96;
			} else {
				dwc <- 4.06;
			}

		}

		if (renew and age < 0) {
			dwc <- 1.5;
		}

		if (renew and age >= 0) {
			dwc <- 2.5;
		}

	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	reflex calcul_estimated_milkprod when: current_date = my_farmer.ram_introduction and gave_birth {
		estimated_total_milk_production <- Constante[0] * (Ctl[0] * 0.001);
		loop i from: 1 to: number_of_milk_monitoring {
			estimated_total_milk_production <- estimated_total_milk_production + (Constante[i] * (Ctl[i - 1] + Ctl[i]) * (0.001 / 2));
		}

	}

	reflex calcul_mean_age_renewal_lambs when: renew and current_date.year!=starting_date.year and ((hormon_shot_youngs and current_date =my_farmer.ewelamb_AI_date_with_hormone) or (not hormon_shot_youngs and current_date = my_farmer.ewe_lamb_start_mating_date)) {
		age_at_repro<-(current_date-birth_date)/#month;
		//write current_date + name +sample(age_at_repro);
		
	}  

	reflex ewelamb_entering_in_heat when: (((not hormon_shot_youngs and renew) or (latecomer)) and (not first_heat and in_anoestrus and not gestating)) and
	((current_date = my_farmer.ewe_lamb_start_mating_date add_days day_of_first_heat_ewelamb)) {
		if (current_date.month between (2, 7)) {
			first_heat <- flip(0.2);
		}
		/*It seems that ewe lambs come into heat less in the spring than in the summer, but this value must be adjusted according to field observations */
		if (current_date.month between (6, 9)) {
			first_heat <- flip(0.8);
		}

		if (current_date.month = 9 or current_date.month = 10 or current_date.month = 11 or current_date.month = 12) {
			first_heat <- flip(0.95);
		}

		if (first_heat) {
			start_heating <- current_date;
			in_heat <- true;
			in_anoestrus <- false;
			state <- "in heat";
			latecomer <- false;
			number_of_ewelamb_starting_heating <- number_of_ewelamb_starting_heating + 1;
		}

		if (nutrition_state = "growing") {
			nutrition_state <- "maintenance";
		}

	}

	reflex ewelamb_entering_in_heat_with_hormones when: renew and hormon_shot_youngs and in_anoestrus and not first_heat and not gestating and
	(current_date = my_farmer.sponge_removal_ewelamb add_days day_of_first_heat_with_AI) {
		first_heat <- flip(youngs_synchronization_rate);
		if (first_heat) {
			start_heating <- current_date;
			in_heat <- true;
			in_anoestrus <- false;
			state <- "in heat";
			number_of_ewelamb_starting_heating <- number_of_ewelamb_starting_heating + 1;
		}

		if (nutrition_state = "growing") {
			nutrition_state <- "maintenance";
		}

	}

	reflex being_cyclic_before_male_effect when: not hormon_shot and age >= 1 and not culling_for_age and not culling_for_perf and (current_date = my_farmer.ram_introduction) and
	in_anoestrus {
		if (my_farmer.mating_period = "early" and (BCS <= 2.0)) {
			proba_cyclic <-
			exp(0.007 * estimated_total_milk_production + 0.102 * age + 0.008 * days_since_lambing - 0.001 * last(Ctl) - 2.723) / (1 + exp(0.007 * estimated_total_milk_production + 0.102 * age + 0.008 * days_since_lambing - 0.001 * last(Ctl) - 2.723));
		}

		if (my_farmer.mating_period = "early" and BCS > 3.0) {
			proba_cyclic <-
			exp(1.204 + 0.007 * estimated_total_milk_production + 0.102 * age + 0.008 * days_since_lambing - 0.001 * last(Ctl) - 2.723) / (1 + exp(1.204 + 0.007 * estimated_total_milk_production + 0.102 * age + 0.008 * days_since_lambing - 0.001 * last(Ctl) - 2.723));
		}

		if (my_farmer.mating_period = "early" and BCS between (2.0, 3.1)) {
			proba_cyclic <-
			exp(0.585 + 0.007 * estimated_total_milk_production + 0.102 * age + 0.008 * days_since_lambing - 0.001 * last(Ctl) - 2.723) / (1 + exp(0.585 + 0.007 * estimated_total_milk_production + 0.102 * age + 0.008 * days_since_lambing - 0.001 * last(Ctl) - 2.723));
		}

		if (my_farmer.mating_period = "late") {
			if (current_date.month between (5, 9)) {
				proba_cyclic <- 0.8;
			}

			if (current_date.month between (8, 12)) {
				proba_cyclic <- 1.0;
			}

		}

		cyclic <- flip(proba_cyclic);
		if (cyclic) {
			day_of_first_heat <- rnd(0, 17);
		}

	}

	reflex responding_to_male_effect when: not hormon_shot and age >= 1 and not culling_for_age and not culling_for_perf and (current_date = my_farmer.ram_introduction add_days 10)
	and not cyclic {
		if (BCS <= 2.0) {
			proba_MER <-
			exp(0.011 * estimated_total_milk_production + 0.275 * age - 0.002 * last(Ctl) - 1.952) / (1 + exp(0.011 * estimated_total_milk_production + 0.275 * age - 0.002 * last(Ctl) - 1.952));
		}

		if (BCS > 3.0) {
			proba_MER <-
			exp(2.859 + 0.011 * estimated_total_milk_production + 0.275 * age - 0.002 * last(Ctl) - 1.952) / (1 + exp(2.859 + 0.011 * estimated_total_milk_production + 0.275 * age - 0.002 * last(Ctl) - 1.952));
		} else {
			proba_MER <-
			exp(1.741 + 0.011 * estimated_total_milk_production + 0.275 * age - 0.002 * last(Ctl) - 1.952) / (1 + exp(1.741 + 0.011 * estimated_total_milk_production + 0.275 * age - 0.002 * last(Ctl) - 1.952));
		}

		MER <- flip(proba_MER);
		if (MER) {
			if (flip(0.5)) {
				day_of_first_heat <- int(min(22, max(14, gauss(18, 3))));
			} else {
				day_of_first_heat <- int(min(28, max(20, gauss(24, 3))));
			}

		}

	}

	reflex starts_heating when: every(#day) and age >= 1 and not culling_for_age and not culling_for_perf and not first_heat and in_anoestrus and not gestating {
		if (not hormon_shot and cyclic) and (current_date = my_farmer.ram_introduction add_days day_of_first_heat) {
			first_heat <- true;
		}

		if (not hormon_shot and MER) and (current_date = my_farmer.ram_introduction add_days day_of_first_heat) {
			first_heat <- true;
		}

		if (hormon_shot and (current_date = my_farmer.sponge_removal add_days day_of_first_heat_with_AI)) {
			first_heat <- flip(synchronization_rate);
		}

		if (not hormon_shot and not cyclic and not MER) or (hormon_shot and current_date between (my_farmer.sponge_removal add_days 3, my_farmer.final_withdraw_date)) {
			latecomer <- true;
			state <- "in anoestrus";
		}

		if (first_heat) {
			in_heat <- true;
			in_anoestrus <- false;
			latecomer <- false;
			state <- "in heat";
			start_heating <- current_date;
			number_of_ewes_starting_heating <- number_of_ewes_starting_heating + 1;
		}

	}

	reflex end_of_heat_period when: in_heat and ((((current_date - start_heating) / #hour) mod 36) = 0) and (current_date > start_heating) {
	/*heats last 36 hours, hence the modulo 36 */
		in_heat <- false;
	}

	reflex next_heats when: first_heat and not gestating and not in_heat and ((((current_date - start_heating)) mod (17 #day)) = 0) and (current_date > start_heating) {
	/* cycle every 17 days */
		in_heat <- true;
		state <- "in heat";
		start_heating <- current_date;
		number_of_ewes_coming_back_into_heat <- number_of_ewes_coming_back_into_heat + 1;
	}

	reflex return_in_anoestrus when: current_date.month = 1 and current_date.day = 1 and current_date.hour = 0 {
	/*On January 1st of each year, all ewes return to anoestrus*/
		in_anoestrus <- true;
		in_heat <- false;
		first_heat <- false;
		cyclic <- false;
		MER <- false;
		latecomer <- false;
		state <- "in anoestrus";
	}

	reflex abortion_date_calcul when: gestating and current_date = start_gestation add_days 1 {
		abortion <- flip(proba_abortion);
		if (abortion) {
			abortion_date <- start_gestation add_days day_of_abortion;
		}

	}

	reflex abort when: gestating and abortion and current_date = abortion_date {
		if ((abortion_date - start_gestation) < 45 / #days) {
			gestating <- false;
		}

		if (abortion_date between (start_gestation add_days 45, start_gestation add_days (gestation_duration - 5))) {
			gestating <- false;
			first_heat <- false;
			in_heat <- false;
			in_anoestrus <- true;
			state <- "in anoestrus";
			nutrition_state <- "maintenance";
		}

		AI_lambs <- false;
	}

	reflex return_in_heat_after_abortion when: first_heat and not gestating and not in_heat and abortion and abortion_date != nil and ((current_date - abortion_date) = 15 / #days) {
		in_heat <- true;
		state <- "in heat";
		start_heating <- current_date;
		number_of_ewes_coming_back_into_heat <- number_of_ewes_coming_back_into_heat + 1;
	}

	reflex calcul_besUFL_gest when: not abortion and gestating and every(#day) {
		gestating_week <- int(((current_date - start_gestation) / #day) / 7);
		week_before_lambing <- (21 - gestating_week);
		if (week_before_lambing between (-1, 7)) {
		//calculation of the number of weeks before lambing considering that mb after 21 weeks (147 days on average)			
			nutrition_state <- "gestating";
		}

	}

	reflex lambing when: (gestating and (current_date = (start_gestation add_days gestation_duration))) { /*add_days permet d'ajouter des jours,5mois=150j environ */
		gave_birth <- flip(easy_lambing);
		if (gave_birth) {
			lambing_count_day <- lambing_count_day + 1;
			gestating <- false;
			lambing_date[current_date.year] <- current_date;
			in_heat <- false;
			first_heat <- false;
			suckling <- true;
			state <- "lactating";
			nutrition_state <- "suckling";
			start_milking[lact_num + 1] <- current_date add_days suckling_duration;
			if ((start_milking[lact_num + 1]) < my_farmer.flock_milking_start) {
				start_milking[lact_num + 1] <- my_farmer.flock_milking_start;
			}

			number_of_ewes_lambing <- number_of_ewes_lambing + 1;
			total_lambing_count <- total_lambing_count + 1;
			if (AI_lambs) {
				daily_AI_lambings <- daily_AI_lambings + 1;
				number_of_AI_lambings <- number_of_AI_lambings + 1;
			}

			to_portee <- flip(to_portee_2);
			// size of litter
			if (to_portee) {
				lit_size <- 2;
			} else {
				to_portee3 <- flip(to_portee_3);
				if (to_portee3) {
					lit_size <- 3;
				}

			}

			newborn_count_day <- newborn_count_day + lit_size; //Count the number of newborn per day
			if (flip(0.5)) {
				create ewe number: lit_size with: [age::-1] {
					my_farmer <- myself.my_farmer;
					my_farmer.my_ewes << self;
					ewe_initial_milk_prod <- myself.ewe_initial_milk_prod;
					ewelamb_initial_milk_prod <- myself.ewelamb_initial_milk_prod;
					MFC_init_value <- myself.MFC_init_value;
					MPC_init_value <- myself.MPC_init_value;
					if (myself.AI_lambs) {
						number_of_youngs_from_AI <- number_of_youngs_from_AI + 1;
						lamb_from_AI <- true;
						ewe_initial_milk_prod <- myself.ewe_initial_milk_prod + genetic_gain_for_milk_prod; //Evolution of the milk prod over the AIs
						ewelamb_initial_milk_prod <- myself.ewelamb_initial_milk_prod + genetic_gain_for_milk_prod; //Evolution of the milk prod over the AIs
						MFC_init_value <- myself.MFC_init_value + genetic_gain_for_MFC;
						MPC_init_value <- myself.MPC_init_value + genetic_gain_for_MPC;
					}

					birth_date <- current_date;
					BCS <- min(5.0, max(1.0, gauss(2.5, 0.3)));
					days_since_lambing <- 0;
					newborn <- true;
					state <- "in anoestrus";
					nutrition_state <- "growing";
					father_index <- myself.index_of_mate;
					father_name <- myself.father_name;
					weight <- 47.0;
					nb_of_fem_born <- nb_of_fem_born + 1;
					nb_of_newborn <- nb_of_newborn + 1;
				}

			} else {
				create ram number: lit_size with: [age::-1] {
					my_farmer <- myself.my_farmer;
					my_farmer.my_rams << self;
					birth_date <- current_date;
					newborn <- true;
					father_index <- myself.index_of_mate;
					father_name <- myself.father_name;
					state <- "in anoestrus";
					nutrition_state <- "growing_male";
					if (myself.AI_lambs) {
						number_of_youngs_from_AI <- number_of_youngs_from_AI + 1;
						lamb_from_AI <- true;
					}

					nb_of_male_born <- nb_of_male_born + 1;
					nb_of_newborn <- nb_of_newborn + 1;
				}

			}

			AI_lambs <- false;
		} else {
			AI_lambs <- false;
			culling <- true;
			gestating <- false;
			in_anoestrus <- true;
			state <- "in anoestrus";
			nutrition_state <- "maintenance";
			lit_size <- 1;
		}

	}

	reflex start_of_lactation when: nutrition_state = "suckling" and current_date = last(start_milking) {
		suckling <- false;
		health_problem <- flip(proba_hp);
		if (not health_problem) {
			lactating <- true;
			lact_num <- lact_num + 1;
			state <- "lactating";
			nutrition_state <- "lactating";
			milk_prod[lact_num] <- [0];
			number_of_ewes_entering_milking <- number_of_ewes_entering_milking + 1;
		} else {
			lactating <- false;
			in_anoestrus <- true;
			state <- "in anoestrus";
			nutrition_state <- "maintenance";
		}

	}

	reflex milk_production when: lactating and nutrition_state = "lactating" and every(#day) {
		producing_ewe <- true;
		lit_size <- 1;
		number_of_milking_days <- length(last(milk_prod.values)) + 1;
		if (lact_num > 1) {
			milk_prod[lact_num] <+ (ewe_initial_milk_prod * exp(-(0.0028 + 0.0049 * ln(ewe_initial_milk_prod)) * (number_of_milking_days)));
		} else {
			milk_prod[lact_num] <+ (ewelamb_initial_milk_prod * exp(-(0.0021 + 0.0052 * ln(ewelamb_initial_milk_prod)) * (number_of_milking_days)));
		}

		htmp_day <- htmp_day + last(milk_prod[lact_num]);
		number_of_milking_days <- length(last(milk_prod.values)) + 1;
		MFC <- flock_MFC;
		MPC <- flock_MPC;

		///////////daily_water_consum/////////////////////////////////////////////////////////////////
		////If summer
		//Using reference water consumption values from Russel et al 2012
		if (current_date.month between (6, 10)) {
			if (last(milk_prod[lact_num]) between (0.44, 1.5)) {
				dwc <- 3.01;
			}

			if (last(milk_prod[lact_num]) between (1.4, 2.0)) {
				dwc <- 5.27;
			}

			if (last(milk_prod[lact_num]) between (1.9, 3.2)) {
				dwc <- 4.5;
			}

		} else { /////If not summer
			if (last(milk_prod[lact_num]) between (0.44, 1.5)) {
				dwc <- 6.28;
			}

			if (last(milk_prod[lact_num]) between (1.4, 2.0)) {
				dwc <- 7.05;
			}

			if (last(milk_prod[lact_num]) between (1.9, 3.2)) {
				dwc <- 9.59;
			}

		}

	}

	reflex end_of_milking when: number_of_milking_days > 0 and lactating and nutrition_state = "lactating" and ((last(milk_prod[lact_num]) < prod_min) or
	(current_date = my_farmer.end_delivery_date)) {
		end_of_milking_date[lact_num] <- current_date;
		lactating <- false;
		number_of_milking_days <- 0;
		milk_prod[lact_num] <+ 0.0;
		state <- " in anoestrus";
		nutrition_state <- "maintenance";
		if (gestating) {
			state <- "gestating";
		}

	}

	reflex calcul_ctl {
		if (lactating and last(lambing_date) != nil and current_date = my_farmer.ctl_date[0]) {
			Ctl[0] <- ((last(milk_prod[lact_num])) * 1000); ///par 2 si demi traite
			Constante[0] <- ((my_farmer.ctl_date[0] - last(lambing_date)) / #day);
		}

		loop i from: 1 to: 4 {
			if (lactating and current_date = my_farmer.ctl_date[i]) {
				Ctl[i] <- ((last(milk_prod[lact_num])) * 1000);
				//*1000 because the milk production is in liter and the Ctl in ml
				Constante[i] <- ((my_farmer.ctl_date[i] - my_farmer.ctl_date[i - 1]) / #day);
				//Calculation of the milk monitoring value and the Constant i which intervenes in the estimation of the milk production
			}

		}

	}

	reflex reset_bool when: (current_date = my_farmer.ram_introduction) or (current_date = my_farmer.sponge) {
	/*Return to the initial state for the boolean abortion and gave_birth*/
		abortion <- false;
		gave_birth <- false;
	}

}

//////////////////////FARMER AGENT/////////////////////
species farmer {
	rgb couleur <- #saddlebrown update: #saddlebrown;
	date ram_introduction;
	date final_withdraw_date;
	date old_ewes_departure_date;
	int nb_renew_ram;
	int nb_renew_ewe;
	date ewe_lamb_start_mating_date;
	date second_ram_intro_date;
	date sponge;
	date sponge_ewelamb;
	date sponge_removal;
	date sponge_removal_ewelamb;
	date ewe_AI_date_with_hormone;
	date ewelamb_AI_date_with_hormone;
	date first_lambing_date;
	date last_lambing_date;
	date rst_month_of_lambing;
	date deb_management_period;
	date flock_milking_start;
	date end_delivery_date;
	list<list<date>> AI_dates;
	list<date> free_mating_dates;
	list<ram> my_rams;
	list<ewe> my_ewes;
	list<sheep> my_youngs;
	list<surface> my_surfaces;
	list<feed> my_diets;
	int number_of_culled_ewes;
	int nbre_days_since_milking_start <- 0;
	float total_renewal_rate_from_AI;
	float mean_gen_index;
	float bes_UFL_ewe;
	float bes_UFL_ewelamb;
	float nrj_requirement_covering;
	float bes_PDI_ewe;
	float bes_PDI_ewelamb;
	float flock_MFC_initial;
	float flock_MPC_initial;
	map<int, date> ctl_date;
	map<string, float> total_PDIE_intake;
	map<string, float> total_PDIN_intake;
	map<int, float> grpt_1_month;
	map<int, int> EP_month;
	svg_file icon <- svg_file("../includes/farmer.svg");
	string mating_period;

	init {
		ram_introduction <- date(string(dates[2, 0]) split_with ",");
		sponge <- date(string(dates[2, 2]) split_with ",");
		if ((ram_introduction.month between (1, 6)) or sponge.month between (1, 6)) {
			mating_period <- "early";
		} else {
			mating_period <- "late";
		}

		write sample(mating_period);
		ewe_lamb_start_mating_date <- date(string(dates[2, 1]) split_with ",");
		second_ram_intro_date <- date(string(dates[2, 9]) split_with ",");
		sponge_ewelamb <- date(string(dates[2, 11]) split_with ",");
		sponge_removal <- sponge add_days 14;
		sponge_removal_ewelamb <- sponge_ewelamb add_days 14;
		ewe_AI_date_with_hormone <- sponge_removal add_days 3;
		ewelamb_AI_date_with_hormone <- sponge_removal_ewelamb add_days 3;
		AI_dates <- calcul_insemination_dates();
		free_mating_dates <- adult_freemating_dates_calcul();
		final_withdraw_date <- date(string(dates[2, 10]) split_with ",");
		flock_milking_start <- date(string(dates[2, 14]) split_with ",");
		end_delivery_date <- date(string(dates[2, 3]) split_with ",");
		flock_milking_days <- int((end_delivery_date - flock_milking_start) / #days);
		old_ewes_departure_date <- end_delivery_date add_days 1;
		loop i from: 0 to: number_of_milk_monitoring {
			ctl_date[i] <- date(string(dates[2, i + 4]) split_with ",");
		}

	}

	reflex management_dates_update when: (current_date = ram_introduction add_days 360) or (current_date = sponge add_days 360) {
		ram_introduction <- ram_introduction add_years 1;
		sponge <- sponge add_years 1;
		ask (ewe where (not empty(each.lambing_date))) {
			days_since_lambing <- int((my_farmer.ram_introduction - last(lambing_date)) / #day);
			if (days_since_lambing < 0) {
				days_since_lambing <- 0;
			}

			days_since_lambing <- int((my_farmer.ram_introduction - last(lambing_date)) / #day);
		}

		ewe_lamb_start_mating_date <- ewe_lamb_start_mating_date add_years 1;
		second_ram_intro_date <- second_ram_intro_date add_years 1;
		sponge_ewelamb <- sponge_ewelamb add_years 1;
		sponge_removal <- sponge add_days 14;
		sponge_removal_ewelamb <- sponge_ewelamb add_days 14;
		ewe_AI_date_with_hormone <- sponge_removal add_days 3;
		ewelamb_AI_date_with_hormone <- sponge_removal_ewelamb add_days 3;
		AI_dates <- calcul_insemination_dates();
		free_mating_dates <- adult_freemating_dates_calcul();
		final_withdraw_date <- final_withdraw_date add_years 1;
	}

	reflex update_nb_milking_days_TB_TP when: every(#day) {
		if (current_date between (flock_milking_start, end_delivery_date)) {
			nbre_days_since_milking_start <- int((current_date - flock_milking_start) / #day);
			flock_MFC <- flock_MFC_initial + 0.122 * nbre_days_since_milking_start;
			flock_MPC <- flock_MPC_initial + 0.072 * nbre_days_since_milking_start;
		} else {
			nbre_days_since_milking_start <- 0;
			flock_MFC <- flock_MFC_initial;
			flock_MPC <- flock_MPC_initial;
		}

		total_water_consum <- total_water_consum + sum(ewe collect (each.dwc)) + sum(ram collect (each.dwc));
	}

	reflex other_dates_and_indicators_update when: current_date = ram_introduction or current_date = sponge {
		if (not hormon_shot) {
			second_ram_intro_date <- last(free_mating_dates);
			write current_date + sample(production_season_number) + sample(hormon_shot) + sample(second_ram_intro_date) color: #purple;
		}

		write current_date + "Flock size: " + flock_size color: #red;
		number_of_culled_ewes <- int(flock_size * turnover_rate);
		nb_renew_ewe <- number_of_culled_ewes;
		write current_date + "Nb to cull:" + number_of_culled_ewes;
		mean_gen_index <- mean(ewe collect (each.father_index));
		loop i from: 0 to: number_of_milk_monitoring {
			ctl_date[i] <- ctl_date[i] add_years 1;
		}

		if (cycle != 0) {
			write EP_month;
			EMP <- int(mean((EP_month)));
			write sample(EMP);
		}

		if (transition and production_season_number = 2) {
			write current_date + sample(transition) color: #pink;
			ewe_lamb_start_mating_date<-ewelamb_AI_date_with_hormone;
			create ram number: 8 {
				my_farmer <- myself;
				my_farmer.my_rams << self;
				newborn <- false;
				age <- rnd(2, 4);
				father_index <- rnd(80, 120);
				state <- "male";
				renew <- false;
			}

			nb_renew_ram <- int(1 / 3 * length(ram));
			
			create ram number: 3 {
				my_farmer <- myself;
				my_farmer.my_rams << self;
				newborn <- false;
				age <- 0;
				father_index <- rnd(80, 120);
				state <- "male";
				renew <- true;
				weaned<-true;
			}
			
			write sample(nb_renew_ram) color: #red;
		}

	}
	
	reflex other_dates_and_indicators_update2 when: current_date = ewe_lamb_start_mating_date {
		repro_age_of_ewe_lambs <- mean(((ewe where (each.renew)) collect (each.age_at_repro)));
		write sample(repro_age_of_ewe_lambs) color: #red;
	}

	reflex calcul_EMP when: current_date.day = 20 and current_date.hour = 0 {
		EP_month[current_date.month] <- length(ewe where (not each.renew and not each.newborn)) + length(ewe where (each.renew and each.age <= 0)); // sheep actually present even those that should be culling
	}

	list<list<date>> calcul_insemination_dates {
		if (mating_period = "early") {
			return [[ram_introduction add_days 17, ram_introduction add_days 21], [ram_introduction add_days 23, ram_introduction add_days 27]];
		}

		if (mating_period = "late") {
			return [[ram_introduction add_days 16, ram_introduction add_days 20], [ram_introduction add_days 19, ram_introduction add_days 23]];
		}

	}

	list<date> adult_freemating_dates_calcul {
		if (not hormon_shot and AI) {
			return [last(last(AI_dates)) add_days 2, last(last(AI_dates)) add_days (2 + ewesonly_free_mating_duration)];
		}

		if (not hormon_shot and not AI) {
			return [ram_introduction add_days male_effect_duration, (ram_introduction add_days male_effect_duration) add_days ewesonly_free_mating_duration];
		}

		if (hormon_shot and AI) {
			return [ewe_AI_date_with_hormone add_days 14, ewe_AI_date_with_hormone add_days (14 + ewesonly_free_mating_duration)];
		} /* to check these dates because they condition a lot the number of pregnant females */
	}

	aspect default {
		draw icon size: {0.75, 2} color: couleur rotate: 180;
		draw ("Date: " + current_date.day + "/" + current_date.month + "/" + current_date.year) font: font("SansSerif", 24, #bold) at: location + {10, 0} color: #white;
	}

	/*reflex to choose the ewes to be inseminated in the case of an AI with hormones (considering that all the ewes of 
	renewal ewes are inseminated). In case of AI without hormones, all ewes in heat are detected and inseminated*/
	reflex choose_ewe_to_inseminate when: AI and ((current_date = sponge) or (current_date = ram_introduction)) {
		if (hormon_shot) {
			write "Possible to inseminate:" + (flock_size - length(ewe where each.culling_for_age) - length(ewe where each.culling_for_perf));
			list<ewe> ewes_to_be_insem <- ewe where (each.age >= 1 and not each.culling_for_age and not each.culling_for_perf);
			nb_ewe_to_be_insem1 <- int(AI_rate * length(ewes_to_be_insem));
			ask (nb_ewe_to_be_insem1 among ewes_to_be_insem) {
			/*Here we choose to select the ewes to be inseminated at random in the flock but can be that selection 
				on criterion (age, genet, success last campaign...) */
				to_be_inseminate <- true;
			}

		}

		if (hormon_shot_youngs) {
			list<ewe> ewe_lambs <- ewe where (each.age < 1);
			nb_ewelamb_to_be_insem1 <- int(youngs_AI_rate * length(ewe_lambs));
			ask (nb_ewelamb_to_be_insem1 among ewe_lambs) {
				to_be_inseminate <- true;
			}

		} else {
			ask (ewe) {
				to_be_inseminate <- true;
			}

		}

	}

	reflex inseminates_without_hormones when: AI and not hormon_shot and not empty(AI_dates where (current_date between (each[0], each[1]))) {
		list<ewe> brebis_pouvant_etre_gestantes <- ewe where (each.to_be_inseminate and each.in_heat);
		/*This reflex must occur after the first AI */
		
		nb_ewe_to_be_insem2 <- int(detection_rate * length(brebis_pouvant_etre_gestantes));
		ask (nb_ewe_to_be_insem2 among brebis_pouvant_etre_gestantes) {
			gestating <- flip(proba_AI_sucess);
			to_be_inseminate <- false;
			if (to_be_inseminate = false) {
				nb_of_insemination <- nb_of_insemination + 1;
			}

			if (gestating) {
				gestating <- true;
				AI_lambs <- true;
				index_of_mate <- AI_index;
				in_heat <- false;
				state <- "gestating";
				if (not lactating) {
					nutrition_state <- "maintenance";
				}

				couleur <- #orange;
				start_gestation <- current_date;
				number_of_gestating_females <- number_of_gestating_females + 1;
			}

		}

	}

	reflex inseminates_ewes_with_hormone when: AI and hormon_shot and (current_date = ewe_AI_date_with_hormone) {
		list<ewe> ewes_candidates_to_gestation <- ewe where (each.age >= 1 and (each.to_be_inseminate) and (each.in_heat));
		/* must occur after the first AI */
		nb_of_insemination<-length(ewes_candidates_to_gestation);
		ask (ewes_candidates_to_gestation) {
			gestating <- flip(proba_AI_sucess);
			to_be_inseminate <- false;
			if (gestating) {
				gestating <- true;
				AI_lambs <- true;
				index_of_mate <- AI_index;
				in_heat <- false;
				state <- "gestating";
				if (not lactating) {
					nutrition_state <- "maintenance";
				}

				couleur <- #orange;
				start_gestation <- current_date;
				number_of_gestating_females <- number_of_gestating_females + 1;
			}

		}

	}

	reflex inseminates_youngs_with_hormone when: AI_youngs and hormon_shot_youngs and (current_date = ewelamb_AI_date_with_hormone) {
		list<ewe> ewelambs_candidates_to_gestation <- ewe where (each.renew and each.to_be_inseminate and each.in_heat); /*Cette étape 
		 * doit avoir lieu après la 1ère IA */
		 nb_of_insemination<-nb_of_insemination+length(ewelambs_candidates_to_gestation);
		ask (ewelambs_candidates_to_gestation) {
			gestating <- flip(young_proba_AI_sucess);
			to_be_inseminate <- false;
			if (gestating) {
				gestating <- true;
				AI_lambs <- true;
				index_of_mate <- AI_index;
				in_heat <- false;
				state <- "gestating";
				if (not lactating) {
					nutrition_state <- "maintenance";
				}

				couleur <- #orange;
				start_gestation <- current_date;
				number_of_gestating_females <- number_of_gestating_females + 1;
			}

		}

	}

	reflex rst_introduction_of_freemating_ram when: current_date between (first(free_mating_dates), last(free_mating_dates)) {
		ask (ram where (each.age >= 1)) {
			active <- true;
			state <- "active";
		}

	}

	reflex rst_withdrawal_of_freemating_ram when: (current_date = last(free_mating_dates)) {
		ask (ram where (each.age >= 1)) {
			active <- false;
			state <- "resting";
		}

	}

	reflex rst_introduction_of_freemating_ram_for_ewelambs when: current_date between (ewe_lamb_start_mating_date, final_withdraw_date) {
		ask (ram where (each.age >= 1)) {
			active_for_ewelambs <- true;
			state <- "active";
		}

	}

	reflex second_introduction_of_freemating_ram when: current_date between (second_ram_intro_date, final_withdraw_date) {
		ask (ram where (each.age >= 1)) {
			active <- true;
			state <- "active";
		}

	}

	reflex final_withdrawal_of_freemating_ram when: (current_date = final_withdraw_date) {
		ask (ram where (each.age >= 1)) {
			active <- false;
			active_for_ewelambs <- false;
			state <- "resting";
		}

	}

	reflex TB_TP_init_milkprod_monitoring_and_renewupdate when: current_date = flock_milking_start {
		flock_MFC_initial <- mean((ewe where not each.newborn) collect (each.MFC_init_value));
		flock_MPC_initial <- mean((ewe where not each.newborn) collect (each.MPC_init_value));
		write "Initial milk fat content:" + flock_MFC_initial;
		write "Initial milk protein content:" + flock_MPC_initial;
		write " IDMY young mean: " + mean(ewe where (not each.newborn and each.renew) collect (each.ewelamb_initial_milk_prod));
		write " IDMY adult mean: " + mean(ewe where (not each.renew and each.age >= 0) collect (each.ewe_initial_milk_prod));
	}

	reflex milking_work_assesment when: every(#day) and current_date between (flock_milking_start minus_days 1, end_delivery_date add_days 1) {
		if ((int(length(ewe where (each.lactating)) / 48) mod 48) = 0) {
			milking_work_time[current_date] <- fixed_time_work_during_milking + int(working_time_per_milking_round * (int(length(ewe where (each.lactating)) / 48))); ////calculate working time per day in minutes
			nrj_conso <- nrj_conso + fixed_nrj_conso_during_milking * htmp_day + int(nrj_conso_per_milking_round * (int(length(ewe where (each.lactating)) / 48)));
		} else {
			milking_work_time[current_date] <- fixed_time_work_during_milking + int(working_time_per_milking_round * (int(length(ewe where (each.lactating)) / 48) + 1)); ////calculate working time per day in minutes
			nrj_conso <- nrj_conso + fixed_nrj_conso_during_milking * htmp_day + int(nrj_conso_per_milking_round * (int(length(ewe where (each.lactating)) / 48) + 1));
		}

		total_work_during_milking <- total_work_during_milking + (milking_work_time[current_date]) / 60; // to put in hours

	}

	reflex reset_renew when: current_date = flock_milking_start {
		ask (ewe where (each.renew and not each.newborn)) {
			renew <- false;
			weaned <- false;
		}

		ask (ram where (each.renew and not each.newborn)) {
			renew <- false;
			weaned <- false;
		}

	}

	reflex bought_renew when: current_date = flock_milking_start {
		if (not ewe_autorenewal) {
			create ewe number: nb_renew_ewe with: [age::-1] {
				my_farmer <- myself;
				my_farmer.my_ewes << self;
				ewe_initial_milk_prod <- mean((ewe where not (each.renew)) collect (each.ewe_initial_milk_prod));
				ewelamb_initial_milk_prod <- mean((ewe where (each.renew)) collect (each.ewelamb_initial_milk_prod));
				MFC_init_value <- mean((ewe where not (each.renew)) collect (each.MFC_init_value));
				MPC_init_value <- mean((ewe where (each.renew)) collect (each.MPC_init_value));
				birth_date <- current_date minus_months 1;
				BCS <- min(5.0, max(1.0, gauss(2.5, 0.3)));
				newborn <- true;
				renew <- true;
				weaned <- true;
				father_index <- rnd(80, 120);
				state <- "in anoestrus";
				nutrition_state <- "growing";
				weight <- 47.0;
			}

		}

		if (not ram_autorenewal) {
			create ram number: nb_renew_ram with: [age::-1] {
				my_farmer <- myself;
				my_farmer.my_rams << self;
				birth_date <- current_date minus_months 1;
				newborn <- true;
				renew <- true;
				weaned <- true;
				father_index <- rnd(80, 120);
				state <- "in anoestrus";
				nutrition_state <- "growing_male";
			}
			

		}

	}

	reflex young_ewes_sales when: int(length(ewe where (each.newborn and each.weaned and each.renew))) = nb_renew_ewe {
		if (ewe_autorenewal) {
			ask (ewe where (each.newborn and each.weaned and not each.renew)) {
				young_ewes_sales <- young_ewes_sales + 1;
				sales_youngs <- sales_youngs + 1;
				my_farmer.my_ewes >> self;
				do die;
			}

		} else {
			ask (ewe where (each.newborn and not each.renew)) {
				young_ewes_sales <- young_ewes_sales + 1;
				sales_youngs <- sales_youngs + 1;
				my_farmer.my_ewes >> self;
				do die;
			}

		}

	}

	reflex young_ram_sales when: int(length(ram where (each.newborn and each.weaned and each.renew))) = nb_renew_ram {
		if (ram_autorenewal) {
			ask (ram where (each.newborn and each.weaned and not each.renew)) {
				young_ram_sales <- young_ram_sales + 1;
				sales_youngs <- sales_youngs + 1;
				my_farmer.my_rams >> self;
				do die;
			}

		} else {
			ask (ram where (each.newborn and not each.renew)) {
				young_ram_sales <- young_ram_sales + 1;
				sales_youngs <- sales_youngs + 1;
				my_farmer.my_rams >> self;
				do die;
			}

		}

	}

	reflex involuntary_culling when: (current_date = ram_introduction add_months 10) or (current_date = sponge add_months 10) {
		list<ewe> ewes_to_be_culled_accidentally <- (ewe where (each.culling));
		write "involontary culling:" + length(ewe where (each.culling));
		number_of_culled_ewes <- number_of_culled_ewes - length(ewe where (each.culling)); //adjustment of the total number of ewes to be culled due to accidental deaths
		write sample(number_of_culled_ewes) color: #green;
		ask (ewes_to_be_culled_accidentally) {
			my_farmer.my_ewes >> self;
			do die;
		}

	}

	reflex choice_of_ewes_to_cull_for_performances when: (not hormon_shot and current_date = ram_introduction add_months 10) or (hormon_shot and current_date = sponge add_months 10)
	{
		list<ewe> ewes_to_be_culled_for_perf <- ewe where (each.lact_num > 1 and each.producing_ewe) sort_by (sum(each.milk_prod[each.lact_num]));
		ask (number_of_culled_ewes first (ewes_to_be_culled_for_perf)) {
			culling_for_perf <- true;
		}

		write "culls for perf:" + length((ewe where (each.culling_for_perf))) color: #green;
	}

	reflex choice_of_old_ewes_for_culling when: (not hormon_shot and current_date = ram_introduction add_months 10) or (hormon_shot and current_date = sponge add_months 10) {
		list<ewe> old_ewes_to_be_culled <- (ewe where (each.age >= culling_age)) sort_by (-1 * each.age); //creation of a list of ewes to cull that we classify from the youngest to the oldest age with sort_by
		ask ((number_of_culled_ewes - length(ewe where each.culling_for_perf)) first (old_ewes_to_be_culled)) { //request the (number*new) first sheep on the list to die//
			culling_for_age <- true;
		}

	}

	reflex choice_of_old_rams_for_culling when: (not hormon_shot and current_date = ram_introduction add_months 10) or (hormon_shot and current_date = sponge add_months 10) {
		list<ram> old_rams_to_be_culled <- (ram where (each.age >= 2)) sort_by (-1 * each.age);
		ask (nb_renew_ram first old_rams_to_be_culled) {
			culling_for_age <- true; // ask all the old rams to die/

		}

	}

	reflex sorties_pour_bilan_eco when: ((current_date = ram_introduction add_months 10) or (current_date = sponge add_months 10)) {
		write "nb young born: " + nb_of_newborn;
		write "nb ewes born " + nb_of_fem_born;
		write "nb ram born" + nb_of_male_born;
		youngs_from_AI_rate <- number_of_youngs_from_AI / nb_of_newborn;
		write "nb death before weaning:" + young_mortality;
		write "nb young sold: " + sales_youngs;
		if (AI and ewe_autorenewal) {
			ewe_renewal_rate_from_AI <- length(ewe where (each.renew and each.lamb_from_AI)) / length(ewe where each.renew); ///females renewal

		} else {
			ewe_renewal_rate_from_AI <- 0.0;
		}

		if (AI and ram_autorenewal) {
			ram_renewal_rate_from_AI <- length(ram where (each.renew and each.lamb_from_AI)) / length(ram where (each.renew)); ///males renewal

		} else {
			ram_renewal_rate_from_AI <- 0.0;
		}

	}

	reflex calcul_lambing_period_and_fertility_rate when: (current_date = ram_introduction add_months 10) or (current_date = sponge add_months 10) {
		flock_size <- length(ewe where each.renew) + length(ewe where (not each.renew and each.age >= 0)) - length(ewe where each.culling_for_age) - length(ewe where
		each.culling_for_perf); //remove the reforms that are not yet gone but will not be reproduced
		write "flock size two months from repro:" + flock_size color: #red;
		write sample(length(ewe where (not each.renew))) color: #orange;
		adult_batch_size <- length(ewe where (not each.renew and each.age >= 0)) - length(ewe where each.culling_for_age) - length(ewe where each.culling_for_perf);
		write sample(adult_batch_size) color: #orange;
		young_batch_size <- length(ewe where each.renew);
		write sample(young_batch_size) color: #orange;
		ewes_per_lambing_dates <- (ewe where (each.gave_birth)) sort_by ((last(each.lambing_date)));
		ask first(ewes_per_lambing_dates) {
			myself.first_lambing_date <- last(self.lambing_date);
			myself.rst_month_of_lambing <- myself.first_lambing_date add_months 1;
			write sample(myself.rst_month_of_lambing);
		}

		ask last(ewes_per_lambing_dates) {
			myself.last_lambing_date <- last(self.lambing_date);
		}

		fertility_rate[production_season_number] <- length(ewes_per_lambing_dates) / last(flock_size_current_production_season[production_season_number]);
		write "Fertility rate:" + fertility_rate[production_season_number];
		write "First lambing of the flock:" + (first(ewes_per_lambing_dates)) + ":" + first_lambing_date;
		write "Last lambing of the flock:" + (last(ewes_per_lambing_dates)) + ":" + last_lambing_date;
		write "Lambing period (days):" + ((last_lambing_date - first_lambing_date) / #days);
		list<ewe> ewes_that_lambed_in_1_month <- ewes_per_lambing_dates where (last(each.lambing_date) <= rst_month_of_lambing);
		grpt_1_month[production_season_number] <- length(ewes_that_lambed_in_1_month) / length(ewe where each.gave_birth);
		write sample(grpt_1_month[production_season_number]);
	}

	reflex calcul_TMP_of_the_herd when: current_date = end_delivery_date {
		ewe_that_produced <- ewe where (each.producing_ewe);
		write " number of ewes that produced:" + length(ewe_that_produced) + " flock size:" + (flock_size_current_production_season[production_season_number]) color: #purple;
		htmp[production_season_number] <- (ewe_that_produced sum_of (sum(each.milk_prod[each.lact_num])));
		write current_date + scenario + "production season: " + production_season_number + "Total_prod of flock (L):" + htmp[production_season_number] color: #green;
		write "TMP mean (L/ewe):" + (ewe_that_produced mean_of (sum(each.milk_prod[each.lact_num])));
		ask (ewe where (each.producing_ewe)) {
			producing_ewe <- false;
		}

	}

	reflex update_milking_and_old_ewes_departure_date when: current_date > end_delivery_date {
		production_season_number <- production_season_number + 1;
		flock_size_current_production_season[production_season_number] <- flock_size;
		write "check size of the flock for the production season:" + last(flock_size_current_production_season[production_season_number]);
		old_ewes_departure_date <- end_delivery_date add_days 1; //important that this update is done before the update of the "end_delivery_date"
		flock_milking_start <- flock_milking_start add_years 1;
		end_delivery_date <- end_delivery_date add_years 1;
		flock_milking_days <- int((end_delivery_date - flock_milking_start) / #days);
	}

	reflex culling_of_ewes_and_rams when: current_date = old_ewes_departure_date {
		$_milk2[production_season_number - 1] <- $_milk;
		write sample($_milk2) color: #green;
		$_milk_without_pp <- 0.0;
		write current_date + "nb culling for age:" + length((ewe where (each.culling_for_age)));
		write current_date + "nb culling for perf:" + length((ewe where (each.culling_for_perf)));
		write current_date + "nb ram culled:" + length((ram where (each.culling_for_age)));
		ask (ewe where each.culling_for_age) {
			nb_culled_fem <- nb_culled_fem + 1;
			nb_culled_ad_tot <- nb_culled_ad_tot + 1;
			my_farmer.my_ewes >> self;
			do die;
		}

		ask (ewe where each.culling_for_perf) {
			nb_culled_fem <- nb_culled_fem + 1;
			my_farmer.my_ewes >> self;
			do die;
		}

		write sample(ram count each.culling_for_age);
		ask (ram where each.culling_for_age) {
			nb_culled_mal <- nb_culled_mal + 1;
			nb_culled_ad_tot <- nb_culled_ad_tot + 1;
			my_farmer.my_rams >> self;
			do die;
		}

	}

}

//----------------------------------------------------------------------------
// AGENT DIET :
//----------------------------------------------------------------------------
species feed {
	farmer my_farmer;
	string batch_name;
	string feed_category;
	int diet_period;
	int diet_group;
	int feed_type;
	float feed_qty;
	string feed_name;
	date deb_period;
	date end_period;
	int size_batch_1;
	int size_batch_2;
	int size_batch_3;
	int size_batch_4;
	int size_batch_5;
	int size_batch_6;
	int size_batch_7;
	int size_batch_8;
	int size_batch_9;
	float refus;
	float daily_PDIN_intake;
	float daily_PDIE_intake;
	float daily_energy_intake;
	map<string, int> size_batch;
	map<string, int> size_batch_adult;
	map<string, int> size_batch_young;
	float max_feed_herbe <- 1.1 with_precision 2;

	init {
	//find the feed name corresponding to the feed type
		feed_name <- string(mat_alim[1, (feed_type) - 1]);
		feed_category <- string(mat_alim[10, (feed_type) - 1]);
		// find the beginning and the end of period of the diet 
		deb_period <- date(string(mat_periodes[1, diet_period - 1]) split_with ",");
		end_period <- date(string(mat_periodes[2, diet_period - 1]) split_with ",");
		//write "nom alim:" + feed_name + " deb_period:" + deb_period + " End_period" + end_period;
	

	}

	reflex update_feed when: every(#day) {
		if (current_date between (deb_period minus_days 1, end_period add_days 1)) {

		///////calculation of the quantity of food distributed
			if (batch_name = "growing") {
				size_batch_1 <- length(ewe where (each.nutrition_state = "growing"));
				//write current_date + "growing: " + size_batch_1;
				if size_batch_1 > 0 {
					if (feed_name != 'herbe') {
						feed_distributed[feed_name] <- feed_distributed[feed_name] + ((feed_qty * (1 + refus)) / 1000) * size_batch_1; // Aliment distribué en tonnes
					} else {
						feed_distributed[feed_name] <- feed_distributed[feed_name] + min([max_feed_herbe, (feed_qty * to_ingested_hour_grazed)]) / 1000 * size_batch_1; // Aliment distribué en tonnes
						daily_consumed_grass[current_date] <- (daily_consumed_grass[current_date]) + min([max_feed_herbe, (feed_qty * to_ingested_hour_grazed)]) * size_batch_1; //en kg/MS/JOUR
						size_grazing_batch[current_date] <- size_grazing_batch[current_date] + size_batch_1;
					}

				}

			}

			if ((diet_group != 4) and (batch_name = "gestating")) {
				size_batch_2 <- length(ewe where ((not each.renew) and each.nutrition_state = batch_name));
				if size_batch_2 > 0 {
					if (feed_name != 'herbe') {
						feed_distributed[feed_name] <- feed_distributed[feed_name] + ((feed_qty * (1 + refus)) / 1000) * size_batch_2; // Aliment distribué en tonnes

					} else {
						feed_distributed[feed_name] <- feed_distributed[feed_name] + min([max_feed_herbe, (feed_qty * to_ingested_hour_grazed)]) / 1000 * size_batch_2; // Aliment distribué en tonnes
						daily_consumed_grass[current_date] <- (daily_consumed_grass[current_date]) + min([max_feed_herbe, (feed_qty * to_ingested_hour_grazed)]) * size_batch_2; //en kg/MS/JOUR
						size_grazing_batch[current_date] <- size_grazing_batch[current_date] + size_batch_2;
					}

				}

			}

			if ((diet_group = 4) and (batch_name = "gestating")) {
				size_batch_3 <- length(ewe where (each.renew and each.nutrition_state = batch_name));
				if size_batch_3 > 0 {
					if (feed_name != 'herbe') {
						feed_distributed[feed_name] <- feed_distributed[feed_name] + ((feed_qty * (1 + refus)) / 1000) * size_batch_3; // Aliment distribué en tonnes
					} else {
						feed_distributed[feed_name] <- feed_distributed[feed_name] + min([max_feed_herbe, (feed_qty * to_ingested_hour_grazed)]) / 1000 * size_batch_3; // Aliment distribué en tonnes
						daily_consumed_grass[current_date] <- (daily_consumed_grass[current_date]) + min([max_feed_herbe, (feed_qty * to_ingested_hour_grazed)]) * size_batch_3; //en kg/MS/JOUR
						size_grazing_batch[current_date] <- size_grazing_batch[current_date] + size_batch_3;
					}

				}

			}

			if ((diet_group != 4) and (batch_name = "maintenance")) {
				size_batch_8 <- length(ewe where ((not each.renew) and each.nutrition_state = batch_name));
				if size_batch_8 > 0 {
					if (feed_name != 'herbe') {
						feed_distributed[feed_name] <- feed_distributed[feed_name] + ((feed_qty * (1 + refus)) / 1000) * size_batch_8; // Aliment distribué en tonnes

					} else {
						feed_distributed[feed_name] <- feed_distributed[feed_name] + min([max_feed_herbe, (feed_qty * to_ingested_hour_grazed)]) / 1000 * size_batch_8; // Aliment distribué en tonnes
						daily_consumed_grass[current_date] <- (daily_consumed_grass[current_date]) + min([max_feed_herbe, (feed_qty * to_ingested_hour_grazed)]) * size_batch_8; //en kg/MS/JOUR
						size_grazing_batch[current_date] <- size_grazing_batch[current_date] + size_batch_8;
					}

				}

			}

			if ((diet_group = 4) and (batch_name = "maintenance")) {
				size_batch_9 <- length(ewe where (each.renew and each.nutrition_state = batch_name));
				if size_batch_9 > 0 {
					if (feed_name != 'herbe') {
						feed_distributed[feed_name] <- feed_distributed[feed_name] + ((feed_qty * (1 + refus)) / 1000) * size_batch_9; // Aliment distribué en tonnes
					} else {
						feed_distributed[feed_name] <- feed_distributed[feed_name] + min([max_feed_herbe, (feed_qty * to_ingested_hour_grazed)]) / 1000 * size_batch_9; // Aliment distribué en tonnes
						daily_consumed_grass[current_date] <- (daily_consumed_grass[current_date]) + min([max_feed_herbe, (feed_qty * to_ingested_hour_grazed)]) * size_batch_9; //en kg/MS/JOUR
						size_grazing_batch[current_date] <- size_grazing_batch[current_date] + size_batch_9;
					}

				}

			}

			if (batch_name = "suckling") {
				size_batch_4 <- length(ewe where (each.nutrition_state = batch_name));
				if size_batch_4 > 0 {
					if (feed_name != 'herbe') {
						feed_distributed[feed_name] <- feed_distributed[feed_name] + ((feed_qty * (1 + refus)) / 1000) * size_batch_4; // Aliment distribué en tonnes

					} else {
						feed_distributed[feed_name] <- feed_distributed[feed_name] + min([max_feed_herbe, (feed_qty * to_ingested_hour_grazed)]) / 1000 * size_batch_4; // Aliment distribué en tonnes
						daily_consumed_grass[current_date] <- (daily_consumed_grass[current_date]) + min([max_feed_herbe, (feed_qty * to_ingested_hour_grazed)]) * size_batch_4; //en kg/MS/JOUR
						size_grazing_batch[current_date] <- size_grazing_batch[current_date] + size_batch_4;
					}

				}

			}

			if (batch_name = "lactating") {
				size_batch_5 <- length(ewe where (each.nutrition_state = batch_name));
				if size_batch_5 > 0 {
					if (feed_name != 'herbe') {
						feed_distributed[feed_name] <- feed_distributed[feed_name] + ((feed_qty * (1 + refus)) / 1000) * size_batch_5; // Aliment distribué en tonnes

					} else {
						feed_distributed[feed_name] <- feed_distributed[feed_name] + min([max_feed_herbe, (feed_qty * to_ingested_hour_grazed)]) / 1000 * size_batch_5; // Aliment distribué en tonnes
						daily_consumed_grass[current_date] <- (daily_consumed_grass[current_date]) + min([max_feed_herbe, (feed_qty * to_ingested_hour_grazed)]) * size_batch_5; //en kg/MS/JOUR
						size_grazing_batch[current_date] <- size_grazing_batch[current_date] + size_batch_5;
					}

				}

			}

			if (batch_name = "male") {
				size_batch_6 <- length(ram where (each.nutrition_state = "male"));
				if size_batch_6 > 0 {
					if (feed_name != 'herbe') {
						feed_distributed[feed_name] <- feed_distributed[feed_name] + ((feed_qty * (1 + refus)) / 1000) * size_batch_6;
					} else {
						feed_distributed[feed_name] <- feed_distributed[feed_name] + min([max_feed_herbe, (feed_qty * to_ingested_hour_grazed)]) / 1000 * size_batch_6; //// Aliment distribué en tonnes
						daily_consumed_grass[current_date] <- (daily_consumed_grass[current_date]) + min([max_feed_herbe, (feed_qty * to_ingested_hour_grazed)]) * size_batch_6; //en kg/MS/JOUR
						size_grazing_batch[current_date] <- size_grazing_batch[current_date] + size_batch_6;
					}

				}

			}

			if (batch_name = "growing_male") {
				size_batch_7 <- length(ram where (each.nutrition_state = "growing_male"));
				if size_batch_7 > 0 {
					if (feed_name != 'herbe') {
						feed_distributed[feed_name] <- feed_distributed[feed_name] + ((feed_qty * (1 + refus)) / 1000) * size_batch_7;
					} else {
						feed_distributed[feed_name] <- feed_distributed[feed_name] + min([max_feed_herbe, (feed_qty * to_ingested_hour_grazed)]) * size_batch_7 / 1000;
						daily_consumed_grass[current_date] <- (daily_consumed_grass[current_date]) + min([max_feed_herbe, (feed_qty * to_ingested_hour_grazed)]) * size_batch_7; //en kg/MS/JOUR
						size_grazing_batch[current_date] <- size_grazing_batch[current_date] + size_batch_7;
					}

				}

			}

			//total quantity of grass used by animals during the year :
			total_grazing <- daily_consumed_grass[current_date];
			grazed_qty_to_subtract <- total_grazing;
		}

	}

	reflex update_period_dates when: current_date = end_period {

	// find the period
		deb_period <- deb_period add_years 1;
		end_period <- end_period add_years 1;
		//feed_qty_tot <- 0.0;
		// write('deb ' + deb_period+ 'end '+ end_period );

	}

}

//----------------------------------------------------------------------------
// AGENT SURFACES :
//----------------------------------------------------------------------------
species surface {
// surfaces attributes
	farmer my_farmer;
	map<int, date> forage_cut_date;
	int id;
	string mod_exp;
	int type;
	int ferti_nb;
	int cut_nb;
	int cut_i <- 0;
	int amendment;
	string mod_exp_s;
	string type_name;
	string ferti_type;
	float ferti_qty;
	float ferti_N;
	float ferti_P;
	float ferti_K;
	float qty_ferti_N;
	float qty_ferti_P;
	float qty_ferti_K;
	float yield_cut1;
	float yield_cut2;
	float yield_cut3;
	float yield_cut4;
	float yield_graz_begSpring;
	float yield_graz_Spring;
	float yield_graz_Summer;
	float yield_graz_Autumn;
	float yield_graz_Winter;
	float yield_grazing_prod_period;
	float yield;
	float cereal_yield;
	float straw_yield;
	float size;
	float rotation_duration;
	float prod_forage;
	float prod_grain;
	float prod_straw;
	float grass_qty;
	float ferti_implantation_cost;
	float seed_implantation_cost;
	float treatment_implantation_cost;
	float $fertilizer;
	float $seed;
	float $other_cost;
	float $amendment;
	float $treatment;
	float $surface_care_cost;
	bool cutting <- false;
	bool grazing <- false;
	map<int, float> yield_cut; // yield per cut
	init {
		yield <- 0.0;
		cut_nb <- 0;
		prod_forage <- 0.0;
		yield_grazing_prod_period <- 0.0;
		grazed_qty_to_subtract <- 0.0;
		if (rotation_duration = 0) {
			$surface_care_cost <- size * ($fertilizer + $seed + $amendment + $treatment + $other_cost);
		} else {
			$surface_care_cost <-
			size * (((ferti_implantation_cost + seed_implantation_cost + treatment_implantation_cost) / rotation_duration) + $fertilizer + $seed + $amendment + $treatment + $other_cost);
		}

		// find the row with the corresponding id in the mat_rendement matrix:
		point n_row <- mat_coupes index_of (string(id));
		// find if the surface is grazed	
		if (mod_exp_s contains 'prairie' or mod_exp_s contains 'parcours') {
		// to check if the surface could be grazed:
			grazing <- true;
			yield_graz_begSpring <- float(mat_surfaces[5, (type) - 1]);
			yield_graz_Spring <- float(mat_surfaces[6, (type) - 1]);
			yield_graz_Summer <- float(mat_surfaces[7, (type) - 1]);
			yield_graz_Autumn <- float(mat_surfaces[8, (type) - 1]);
			yield_graz_Winter <- float(mat_surfaces[9, (type) - 1]);
		}
		// find if the surface is cut:
		if (mod_exp_s contains 'fauches') {
			cutting <- true;

			// calculation of the number of cuts for forage surfaces:
			loop s from: 10 to: (10 + 3) {
				if (float(mat_coupes[s, int(n_row.y)]) > 0.0) {
					cut_nb <- cut_nb + 1;
					yield_cut[cut_nb] <- float(mat_coupes[s, int(n_row.y)]);
					forage_cut_date[cut_nb] <- cut_dates[cut_nb];
				}

			}

			loop j from: 1 to: 3 {
				if (forage_cut_date[j] != nil and (forage_cut_date[j] between (beg_graz_period_begSpring minus_days 1, end_graz_period_begSpring))) {
					yield_graz_begSpring <- 0.0;
				}

				if (forage_cut_date[j] != nil and (forage_cut_date[j] between (beg_graz_period_Spring minus_days 1, end_graz_period_Spring))) {
				// Spring period
					yield_graz_Spring <- 0.0;
				}

				if (forage_cut_date[j] != nil and (forage_cut_date[j] between (beg_graz_period_Summer minus_days 1, end_graz_period_Summer))) {
				//Summer period
					yield_graz_Summer <- 0.0;
				}

				if (forage_cut_date[j] != nil and (forage_cut_date[j] between (beg_graz_period_Autumn minus_days 1, end_graz_period_Autumn))) {
				// Autumn period
					yield_graz_Autumn <- 0.0;
				}

				if (forage_cut_date[j] != nil and (forage_cut_date[j] between (beg_graz_period_Winter minus_days 1, end_graz_period_Winter))) {
				// Winter period
					yield_graz_Winter <- 0.0;
				}

			}

		}

	}

	reflex update_cut_date when: current_date.month = 1 and current_date.day = 1 {
		cut_i <- 0;
		if (forage_cut_date[1] != nil) and (current_date > forage_cut_date[1] add_days 60) {
			forage_cut_date[1] <- forage_cut_date[1] add_years 1;
		}

		if (forage_cut_date[2] != nil) and (current_date > forage_cut_date[2] add_days 60) {
			forage_cut_date[2] <- forage_cut_date[2] add_years 1;
		}

		if (forage_cut_date[3] != nil) and (current_date > forage_cut_date[3] add_days 60) {
			forage_cut_date[3] <- forage_cut_date[3] add_years 1;
		}

	}

	// update of biomass production for animal grazing		
	// update cut and update of forages produced
	reflex cut when: (mod_exp_s contains 'fauches') {
		if ((forage_cut_date[1] != nil) and (current_date = forage_cut_date[1])) {
			yield <- yield_cut[cut_i + 1];
			prod_forage <- yield * size;
			cut_i <- cut_i + 1;
			stock_forage_tot <- stock_forage_tot + prod_forage;
		}

		if ((forage_cut_date[2] != nil) and (current_date = forage_cut_date[2])) {
			yield <- yield_cut[cut_i + 1];
			// forage produced for the number of cuts
			prod_forage <- yield * size;
			cut_i <- cut_i + 1;
			stock_forage_tot <- stock_forage_tot + prod_forage;
		}

		if ((forage_cut_date[3] != nil) and (current_date = forage_cut_date[3])) {
			yield <- yield_cut[cut_i + 1];
			// forage produced for the number of cuts
			prod_forage <- yield * size;
			cut_i <- cut_i + 1;
			stock_forage_tot <- stock_forage_tot + prod_forage;
		}

	}

	// grain harvest :
	reflex grain_harvest when: cereal_yield > 0.0 and (current_date = cereal_cut_date) {
	// update stocks:
		prod_grain <- cereal_yield * size;
		prod_straw <- straw_yield * size;
		stock_grain <- stock_grain + prod_grain;
		stock_straw <- stock_straw + prod_straw;
	}

	// update only grazing: from May to October

	// UPDATE GRAZING ACCORDING YIELD VARYING WITH SEASON & NB OF ANIMALS WHICH ARE GRAZING:
	// update with grazing and cutting : from July to October
	reflex animal_grazing when: grazing = true {
	// find the production period for grazed surfaces

	// beg Spring period
		if current_date = beg_graz_period_begSpring minus_days 1 {
			yield_grazing_prod_period <- yield_graz_begSpring;
			grass_qty <- yield_grazing_prod_period * size;
		}

		// Spring period
		if current_date = beg_graz_period_Spring minus_days 1 {
			yield_grazing_prod_period <- yield_graz_Spring;
			grass_qty <- yield_grazing_prod_period * size;
		}

		//Summer period
		if current_date = beg_graz_period_Summer minus_days 1 {
			yield_grazing_prod_period <- yield_graz_Summer;
			grass_qty <- yield_grazing_prod_period * size;
		}

		// Autumn period
		if current_date = beg_graz_period_Autumn minus_days 1 {
			yield_grazing_prod_period <- yield_graz_Autumn;
			grass_qty <- yield_grazing_prod_period * size;
		}

		// if the surface is cut, the surface is not available for grazing
		if current_date = beg_graz_period_Winter minus_days 1 {
		// Winter period
			yield_grazing_prod_period <- yield_graz_Winter;
			grass_qty <- yield_grazing_prod_period * size;
		}

	}

	// update the diet period for the following year :
	reflex update_period_dates when: current_date > end_grazing_date {
	// find the period
	// update the grazing yields:

	// update of the grazing periods dates (next year):
		beg_graz_period_begSpring <- beg_graz_period_begSpring add_years 1;
		end_graz_period_begSpring <- end_graz_period_begSpring add_years 1;
		beg_graz_period_Spring <- end_graz_period_begSpring add_years 1;
		end_graz_period_Spring <- end_graz_period_begSpring add_years 1;
		beg_graz_period_Summer <- beg_graz_period_Summer add_years 1;
		end_graz_period_Summer <- end_graz_period_Summer add_years 1;
		beg_graz_period_Autumn <- beg_graz_period_Autumn add_years 1;
		end_graz_period_Autumn <- end_graz_period_Autumn add_years 1;
		beg_graz_period_Winter <- beg_graz_period_Winter add_years 1;
		end_graz_period_Winter <- end_graz_period_Winter add_years 1;
		start_grazing_date <- start_grazing_date add_years 1;
		end_grazing_date <- end_grazing_date add_years 1;
		total_grazing <- 0.0;
		daily_consumed_grass <- [];
		size_grazing_batch <- [];
	}

}

//----------------------------------------------------------------------------
// END AGENT SURFACES 
//----------------------------------------------------------------------------
experiment experiment1 type: gui {
//float minimum_cycle_duration <- 0.03;
/** Insert here the definition of the input and output of the model */
	output {
		display Farm {
			overlay position: {5, 5} size: {180 #px, 240 #px} background: #black transparency: 0.5 border: #black rounded: true {
			//for each possible type, we draw a square with the corresponding color and we write the name of the type
				float y <- 30 #px;
				draw "Ewes" at: {40 #px, y + 4 #px} color: #white font: font("SansSerif", 18, #bold);
				y <- y + 30 #px;
				loop type over: ewes_state_color.keys {
					draw square(10 #px) at: {20 #px, y} color: ewes_state_color[type] border: #white;
					draw type at: {40 #px, y + 4 #px} color: #white font: font("SansSerif", 18, #bold);
					y <- y + 25 #px;
				}

				draw line([{10 #px, y}, {170 #px, y}]) color: #white;
				y <- y + 20 #px;
				draw "Rams" at: {40 #px, y + 4 #px} color: #white font: font("SansSerif", 18, #bold);
				y <- y + 30 #px;
				loop type over: rams_state_color.keys {
					draw square(10 #px) at: {20 #px, y} color: rams_state_color[type] border: #white;
					draw type at: {40 #px, y + 4 #px} color: #white font: font("SansSerif", 18, #bold);
					y <- y + 25 #px;
				}

			}

			graphics "background" {
				draw background_breeder color: #lightgray border: #black;
				draw background_ewes color: #lightgreen border: #black;
				draw background_rams color: #lightblue border: #black;
			}

			species ewe;
			species ram;
			species farmer;
			species feed;
			species surface;
		}

		display Flock_size refresh: every(1 #day) {
			chart "Evolution of herd size" size: {1.0, 0.5} x_label: 'Time (day)' y_label: 'Herd size' {
				data "number of ewes" value: length(ewe) color: #red;
				data "number of rams" value: length(ram) color: #blue;
			}

			chart "Age repartition in the herd" size: {1.0, 0.5} position: {0.0, 0.5} type: histogram y_label: 'Herd size' {
				data "[0,1[" value: (ewe count (each.age < 1)) color: #red;
				data "[1,2[" value: (ewe count ((each.age >= 1) and (each.age < 2))) color: #red;
				data "[2,3[" value: (ewe count ((each.age >= 2) and (each.age < 3))) color: rgb(255, 0, 0);
				data "[3,4[" value: (ewe count ((each.age >= 3) and (each.age < 4))) color: #red;
				data "[4,5[" value: (ewe count ((each.age >= 4) and (each.age < 5))) color: #red;
				data "[5,6[" value: (ewe count ((each.age >= 5) and (each.age < 6))) color: #red;
				data "[6,7[" value: (ewe count ((each.age >= 6) and (each.age < 7))) color: #red;
				data "[7,8[" value: (ewe count ((each.age >= 7) and (each.age < 8))) color: #red;
				data "[8,9[" value: (ewe count ((each.age >= 8) and (each.age < 9))) color: #red;
				data "[9, inf[" value: (ewe count ((each.age >= 9))) color: #red;
			}

		}

		display Daily_ewes_physiological_stages refresh: every(1 #days) {
			chart "Evolution of states in the flock" size: {1.0, 0.5} x_label: 'Time (day)' y_label: 'Number of ewes' {
				data "number of ewes starting heating" value: number_of_ewes_starting_heating color: #green;
				data "number of ewes-lamb starting heating" value: number_of_ewelamb_starting_heating color: #darkblue;
				data "total heats" value: ewe count (each.in_heat) color: #pink;
				data "number of ewes coming back into heat" value: number_of_ewes_coming_back_into_heat color: #lime;
				data "number of gestating ewes" value: number_of_gestating_females color: #mediumvioletred;
				data "number of ewes lambing" value: number_of_ewes_lambing color: #gamaorange;
				data "number of ewes entering milking" value: number_of_ewes_entering_milking color: #blue;
			}

			chart "Zoom" size: {1.0, 0.5} position: {0.0, 0.5} x_range: 100 x_label: 'Time (day)' {
				data "number of ewes starting heating" value: number_of_ewes_starting_heating style: bar color: #green;
				data "number of ewes-lamb starting heating" value: number_of_ewelamb_starting_heating style: bar color: #darkblue;
				data "total heats" value: ewe count (each.in_heat) style: bar color: #pink;
				data "number of ewes coming back into heat" value: number_of_ewes_coming_back_into_heat style: bar color: #lime;
				data "number of gestating ewes" value: number_of_gestating_females style: bar color: #mediumvioletred;
				data "number of ewes lambing" value: number_of_ewes_lambing style: bar color: #gamaorange;
				data "number of ewes entering milking" value: number_of_ewes_entering_milking style: bar color: #blue;
			}

		}

		display Daily_milk_production_of_the_flock refresh: every(1 #day) {
			chart "Total milk production of the flock/day" size: {1.0, 0.5} x_label: 'Time (day)' y_label: 'Cumulative milk production (L)' {
				data "Total milk production of the flock/day" value: sum((ewe where each.lactating) collect (last(each.milk_prod[each.lact_num]))) color: #blue;
			}

			chart "Average milk production per milking ewe per day" size: {1.0, 0.5} position: {0.0, 0.5} x_label: 'Time (day)' y_label: 'Average milk production (L)' {
				data "Average milk production/milking ewe/day" value: mean((ewe where each.lactating) collect (last(each.milk_prod[each.lact_num]))) style: line color: #green;
			}

		}

		display Flock_physiological_stages_per_fortnight refresh: every(15 #day) {
			chart "Evolution of physiological states every 15 days " size: {1.0, 0.5} x_label: 'Time (day)' y_label: 'Flock size' {
				data "nb ewes gestating" value: ewe count (each.gestating) color: #pink;
				data "nb ewes cyclic" value: ewe count (each.cyclic) color: #green;
				data "nb ewes responding to ME" value: ewe count (each.MER) color: #mediumslateblue;
				data "Number of lambing" value: ewe count (each.gave_birth) color: #gamaorange;
			}

			chart "Feeding category " size: {1.0, 0.5} position: {0.0, 0.5} type: histogram y_label: 'Batch size' {
				data "in maintenance" value: (ewe count (each.nutrition_state = "maintenance")) color: #red;
				data "gestating" value: (ewe count (each.nutrition_state = "gestating")) color: #orange;
				data "suckling" value: (ewe count (each.nutrition_state = "suckling")) color: #yellow;
				data "lactating" value: (ewe count (each.nutrition_state = "lactating")) color: #lightgreen;
				data "growing" value: (ewe count (each.nutrition_state = "growing")) color: #blue;
				data "growing_male" value: (ram count (each.nutrition_state = "growing_male")) color: #lightblue;
				data "male" value: (ram count (each.nutrition_state = "male")) color: #violet;
			}

		}

		display Genetic refresh: every(1 #year) {
			chart "Mean genetic index" size: {1.0, 0.5} x_label: 'Time (1/2 day)' y_label: 'Mean genetic index' {
				data "Mean index in ewe batch" value: mean(ewe collect (each.father_index)) color: #red;
			}

		}

		display Grass_consumed_during_grazing refresh: every(1 #day) {
			chart "Evolution of grazing" type: xy x_label: 'Time (day)' y_label: 'Quantity of grass consumed (kg of DMI)' {
				data " qty grazed per day  " value: total_grazing color: #darkgreen;
			}

		}

	}

}

experiment Explorationscenarios_batch repeat: 75 type: batch until: end_simulation {
	parameter scenario var: scenario among: ["scenar0", "scenar1", "scenar2"];

	action init {
		gama.pref_parallel_simulations <- true;
		gama.pref_parallel_threads <- 25;
		save "Scenario,Sim_name,date,campaign, ewes_lambing_per_day,AI_lambing_count, lambs_born_per_day,lambing work" to: "Results_ROQ/Results_LCW_per_day.csv" rewrite: true type:
		text;
		save "Year,Scenario,Sim_name,campaign,flock_size,fertility_rate,AI%_in_the_flock,%_of_ewes_lambing_from_AI,% of youngs born from AI,%_ewes_renewal_from_AI,%rams_renewal_from_AI"
		to: "Results_ROQ/Results_repro_results_percentage.csv" rewrite: true header: false type: text;
		save
		"Year,Scenario,Sim_name,campaign,flock_size ,tlc,work_time,work_time_per_ewe,Nb ewes inseminated,Nb_of_ewes_lambing_from_AI,Nb_young_born,Nb_young_born_from_AI,Nb_of_young_dead,Nb_young_sold,mean_age_at_repro"
		to: "Results_ROQ/Results_repro_results_numbers.csv" type: text rewrite: true header: false;
		save "Scenario,Sim_name,date, campaign, daily_grazing" to: "Results_ROQ/daily_grazing.csv" rewrite: true type: text;
		save "Year,Scenario,Sim_name,campaign,ewe_that_produced,htmp,htmp_per_ewe,work_time,work_time_per_l,work_time_per_ewe" type: text to:
		"Results_ROQ/Results_htmp_and_milking_work.csv" rewrite: true;
		save "Scenario,Sim_name, Date,campaign, htmp_per_day, work_per_day" to: "Results_ROQ/Results_HTMP_per_day.csv" rewrite: true type: text;
		string
		lili <- "Year,Scenario,Sim_name,foin1C_rg_apres_deprimage,orge,complementaire_tourteau,herbe,foin1C_lzdvent,foin_PT,foin2C_lzdvent,premier_age,foin3C_lzdvent,paille,alim_complet_agnelles,ensilage,enrubannage";
		save lili to: "Results_ROQ/distributed_feed.csv" type: text rewrite: true header: false;
		save "Year,Scenario,Sim_name,sales_young,culled_fem,culled_male" to: "Results_ROQ/prod_other_indicators.csv" type: text rewrite: true header: false;
		save "Year,Scenario,Sim_name,conso_forage,conso_concentrates,conso_straw,stock_forage_tot,stock_grain,stock_straw,forage_perl,concentrates_perl" to: "Results_ROQ1/vegetal_prod_indicators.csv" type: text
		rewrite: true;
		save
		"Year,Scenario,Sim_name,$_gross_product_milkprod_workshop,$_surf_vege_product,$_gross_product_without_subsidies,$_op_loads_milkprod_workshop,$_surf_vege_loads,$_operating_loads,$gross_marging_whithout_subsidies"
		to: "Results_ROQ/economic_indicators.csv" type: text rewrite: true;
		save
		"Year,Scenario,Sim_name,$_gross_product_milkprod_workshop,$_surf_vege_product,$_gross_product_without_subsidies,$_op_loads_milkprod_workshop,$_surf_vege_loads,$_operating_loads,$gross_marging_whithout_subsidies"
		to: "Results_ROQ/economic_indicators_per_litre.csv" type: text rewrite: true;
		save
		"Year,Scenario,Sim_name,CH4_ent,CH4_ent/l,CH4_manure,CH4_manure/l,CH4_tot, CH4_tot/l,nrj_conso,CO2_elec,CO2_elec/l,CO2_feed_input,CO2_feed_input/l,water_conso,water conso/l" to:
		"Results_ROQ/environnemental_indicators.csv" rewrite: true type: text;
		save "Scenario,Sim_name,date, PDI_requirement, UFL_requirement" to: "Results_ROQ/Results_nutri_requirements_flock.csv" rewrite: true type: text;
		save "Scenario,Sim_name,date,nb_maintening, nb_gestating,nb_suckling,nb_lactating" to: "Results_ROQ/Results_ewes_physio_stage.csv" rewrite: true type: text;
		save "Scenario,Sim_name,date,campaign, nb_of_sheep_grazing" to: "Results_ROQ/grazing_batch.csv" rewrite: true type: text;
	}

}
		





