# ------------------------------------------------------------------------
# Helper Functions & Operational Data Engine
# Mumbai Access Mode Choice Modeling
# ------------------------------------------------------------------------

pct <- function(x) round(x * 100, 2)
quick_summary <- function(df) summary(df)
missing_report <- function(df) sapply(df, function(x) sum(is.na(x)))

# ------------------------------------------------------------------------
# Synthetic Joint RP-SP Data Generator Engine (Dictionary-Driven)
# ------------------------------------------------------------------------
generate_synthetic_data <- function(num_respondents = 10, seed = NULL) {
  
  # 1. Read Data Dictionary to extract expected variables list (Single Source of Truth)
  dict_path <- "data/data_dictionary.csv"
  if (!file.exists(dict_path)) {
    stop(paste("CRITICAL ERROR: Data Dictionary missing at:", dict_path))
  }
  
  # Pull variables directly from the dictionary schema
  expected_vars <- read_csv(dict_path, show_col_types = FALSE) %>% pull(Variable)
  
  # Protect the global random seed state if a local seed is provided
  if (!is.null(seed)) {
    old_seed <- if (exists(".Random.seed", envir = .GlobalEnv)) get(".Random.seed", envir = .GlobalEnv) else NULL
    set.seed(seed)
    if (!is.null(old_seed)) {
      on.exit(assign(".Random.seed", old_seed, envir = .GlobalEnv))
    }
  } 

  master_data <- tibble()
  global_row_counter <- 1
  
  for (i in 1:num_respondents) {
    # Generate Static Respondent-Level Characteristics
    v_age  <- sample(c(1, 2, 3), 1, prob = c(0.45, 0.45, 0.10))
    v_inc  <- sample(c(1, 2, 3), 1, prob = c(0.30, 0.50, 0.20))
    v_land <- sample(c(1, 2, 3, 4), 1, prob = c(0.20, 0.40, 0.30, 0.10))
    
    owns_bike <- sample(c(0, 1), 1, prob = c(0.70, 0.30))
    owns_pvt  <- sample(c(0, 1), 1, prob = c(0.40, 0.60))
    has_drop  <- ifelse(owns_pvt == 1, sample(c(0, 1), 1, prob = c(0.30, 0.70)), 0)
    
    # --------------------------------------------------------------------
    # A. REVEALED PREFERENCE (RP) ROW - Actual Behavior
    # --------------------------------------------------------------------
    rp_row <- tibble(
      respondent_id       = i,
      row_id              = global_row_counter,
      is_sp               = 0,
      choice_situation_id = 0,
      
      av_walk = 1, av_bike = owns_bike, av_pvt = owns_pvt, 
      av_ipt = 1,  av_bus = 1,         av_drop = has_drop,
      
      tt_walk = runif(1, 5, 25),    tt_bike = runif(1, 4, 15),
      tt_pvt  = runif(1, 5, 20),    tt_ipt  = runif(1, 6, 22),
      tt_bus  = runif(1, 10, 35),   tt_drop = runif(1, 5, 20),
      
      tc_bike = runif(1, 0, 2),     tc_pvt  = runif(1, 15, 60),
      tc_ipt  = runif(1, 30, 120),  tc_bus  = runif(1, 5, 20),
      tc_drop = runif(1, 10, 40),
      
      # Baseline qualitative attributes (RP baseline)
      comfort_walk  = sample(c(1, 2), 1, prob = c(0.60, 0.40)),
      comfort_bike  = 0, # Low infrastructure baseline in current state
      comfort_pvt   = sample(c(1, 2), 1, prob = c(0.70, 0.30)),
      comfort_ipt   = sample(c(1, 2), 1, prob = c(0.50, 0.50)),
      comfort_bus   = sample(c(1, 2), 1, prob = c(0.70, 0.30)),
      comfort_drop  = 0,
      
      safety_street = sample(c(0, 1), 1, prob = c(0.50, 0.50)),
      weather       = sample(c(1, 2, 3), 1, prob = c(0.40, 0.40, 0.20)),
      land_use      = v_land,
      age_cohort    = v_age,
      inc_level     = v_inc
    )
    
    # Mathematical Choice Utilities using ALL comfort dimensions (RP parameters)
    v_walk_rp = -0.12 * rp_row$tt_walk + 0.30 * rp_row$comfort_walk + 0.25 * rp_row$safety_street
    v_bike_rp = -0.22 * rp_row$tt_bike - 0.05 * rp_row$tc_bike      + 0.40 * rp_row$comfort_bike
    v_pvt_rp  = -0.05 * rp_row$tt_pvt  - 0.02 * rp_row$tc_pvt       + 0.20 * rp_row$comfort_pvt
    v_ipt_rp  = -0.08 * rp_row$tt_ipt  - 0.01 * rp_row$tc_ipt       + 0.25 * rp_row$comfort_ipt
    v_bus_rp  = -0.07 * rp_row$tt_bus  - 0.03 * rp_row$tc_bus       + 0.35 * rp_row$comfort_bus
    v_drop_rp = -0.09 * rp_row$tt_drop - 0.02 * rp_row$tc_drop      + 0.30 * rp_row$comfort_drop

    # Structural Masking Layer
    u_walk_rp = ifelse(rp_row$av_walk == 1, v_walk_rp, -999)
    u_bike_rp = ifelse(rp_row$av_bike == 1, v_bike_rp, -999)
    u_pvt_rp  = ifelse(rp_row$av_pvt  == 1, v_pvt_rp,  -999)
    u_ipt_rp  = ifelse(rp_row$av_ipt  == 1, v_ipt_rp,  -999)
    u_bus_rp  = ifelse(rp_row$av_bus  == 1, v_bus_rp,  -999)
    u_drop_rp = ifelse(rp_row$av_drop == 1, v_drop_rp, -999)

    probs_rp <- exp(c(u_walk_rp, u_bike_rp, u_pvt_rp, u_ipt_rp, u_bus_rp, u_drop_rp)) / 
                sum(exp(c(u_walk_rp, u_bike_rp, u_pvt_rp, u_ipt_rp, u_bus_rp, u_drop_rp)))

    rp_row$choice <- sample(1:6, 1, prob = probs_rp)
    
    # Enforce strict ordering to match dictionary columns
    rp_row <- rp_row %>% select(all_of(expected_vars))
    master_data <- bind_rows(master_data, rp_row)
    global_row_counter <- global_row_counter + 1
    
    # --------------------------------------------------------------------
    # B. STATED PREFERENCE (SP) ROWS - Stated Choice Cards
    # --------------------------------------------------------------------
    for (card in 1:15) {
      sp_row <- tibble(
        respondent_id       = i,
        row_id              = global_row_counter,
        is_sp               = 1,
        choice_situation_id = card,
        
        av_walk = 1, av_bike = owns_bike, av_pvt = owns_pvt, 
        av_ipt = 1,  av_bus = 1,         av_drop = has_drop,
        
        tt_walk = runif(1, 5, 25),    tt_bike = runif(1, 3, 12),
        tt_pvt  = runif(1, 4, 18),    tt_ipt  = runif(1, 5, 20),
        tt_bus  = runif(1, 8, 25),    tt_drop = runif(1, 4, 18),
        
        tc_bike = runif(1, 0, 5),     tc_pvt  = runif(1, 20, 80),
        tc_ipt  = runif(1, 40, 150),  tc_bus  = runif(1, 10, 30),
        tc_drop = runif(1, 15, 50),
        
        # Experimental SP conditions randomized across levels 1-3 or 0-1
        comfort_walk  = sample(c(1, 2, 3), 1, prob = c(0.33, 0.33, 0.34)),
        comfort_bike  = sample(c(0, 1), 1, prob = c(0.50, 0.50)),
        comfort_pvt   = sample(c(1, 2, 3), 1, prob = c(0.33, 0.33, 0.34)),
        comfort_ipt   = sample(c(1, 2, 3), 1, prob = c(0.33, 0.33, 0.34)),
        comfort_bus   = sample(c(1, 2, 3), 1, prob = c(0.33, 0.33, 0.34)),
        comfort_drop  = sample(c(0, 1), 1, prob = c(0.50, 0.50)),
        
        safety_street = sample(c(0, 1), 1, prob = c(0.50, 0.50)),
        weather       = sample(c(1, 2, 3), 1, prob = c(0.33, 0.33, 0.34)),
        land_use      = v_land,
        age_cohort    = v_age,
        inc_level     = v_inc
      )
      
      # Comprehensive SP Utilities scaled by structural factor (0.74)
      v_walk_sp = 0.74 * (-0.12 * sp_row$tt_walk + 0.30 * sp_row$comfort_walk + 0.25 * sp_row$safety_street)
      v_bike_sp = 0.74 * (-0.22 * sp_row$tt_bike - 0.05 * sp_row$tc_bike      + 0.40 * sp_row$comfort_bike)
      v_pvt_sp  = 0.74 * (-0.05 * sp_row$tt_pvt  - 0.02 * sp_row$tc_pvt       + 0.20 * sp_row$comfort_pvt)
      v_ipt_sp  = 0.74 * (-0.08 * sp_row$tt_ipt  - 0.01 * sp_row$tc_ipt       + 0.25 * sp_row$comfort_ipt)
      v_bus_sp  = 0.74 * (-0.07 * sp_row$tt_bus  - 0.03 * sp_row$tc_bus       + 0.35 * sp_row$comfort_bus)
      v_drop_sp = 0.74 * (-0.09 * sp_row$tt_drop - 0.02 * sp_row$tc_drop      + 0.30 * sp_row$comfort_drop)

      u_walk_sp = ifelse(sp_row$av_walk == 1, v_walk_sp, -999)
      u_bike_sp = ifelse(sp_row$av_bike == 1, v_bike_sp, -999)
      u_pvt_sp  = ifelse(sp_row$av_pvt  == 1, v_pvt_sp,  -999)
      u_ipt_sp  = ifelse(sp_row$av_ipt  == 1, v_ipt_sp,  -999)
      u_bus_sp  = ifelse(sp_row$av_bus  == 1, v_bus_sp,  -999)
      u_drop_sp = ifelse(sp_row$av_drop == 1, v_drop_sp, -999)

      probs_sp <- exp(c(u_walk_sp, u_bike_sp, u_pvt_sp, u_ipt_sp, u_bus_sp, u_drop_sp)) / 
                  sum(exp(c(u_walk_sp, u_bike_sp, u_pvt_sp, u_ipt_sp, u_bus_sp, u_drop_sp)))

      sp_row$choice <- sample(1:6, 1, prob = probs_sp)
      
      # Enforce strict ordering to match dictionary columns
      sp_row <- sp_row %>% select(all_of(expected_vars))
      master_data <- bind_rows(master_data, sp_row)
      global_row_counter <- global_row_counter + 1
    }
  }
  
# Final Structural Assert Check: Column layout must exactly match data dictionary + choice
  if (ncol(master_data) != length(expected_vars)) {
    stop(paste0(
      "CRITICAL SCHEMA MISMATCH: The generated dataset columns do not align with the Data Dictionary.\n",
      " -> Expected columns (As in Dictionary): ", length(expected_vars), "\n",
      " -> Actual columns generated: ", ncol(master_data), "\n",
      "Please verify your 'select(all_of(expected_vars), choice)' mapping layer inside the loops."
    ))
  }
  
  return(master_data)
}