# additional experiments here

# ----------------------------------------
# Helper Functions
# Mumbai Access Mode Choice Modeling
# ----------------------------------------

# Simple percentage formatter
pct <- function(x) {
  round(x * 100, 2)
}

# Safe summary function
quick_summary <- function(df) {
  summary(df)
}

# Check missing values
missing_report <- function(df) {
  sapply(df, function(x) sum(is.na(x)))
}

# ------------------------------------------------------------------------
# Synthetic Joint RP-SP Data Generator Engine for Mumbai Metro Access
generate_synthetic_data <- function(num_respondents = 10, seed = NULL) {
  
  # Protect the global random seed state if a local seed is provided
  if (!is.null(seed)) {
    # If a global seed exists, preserve it; otherwise, handle the null seed state gracefully
    old_seed <- if (exists(".Random.seed", envir = .GlobalEnv)) get(".Random.seed", envir = .GlobalEnv) else NULL
    
    set.seed(seed)
    
    # Restore the global random stream to exactly where it was before this function was invoked
    if (!is.null(old_seed)) {
      on.exit(assign(".Random.seed", old_seed, envir = .GlobalEnv))
    }
  } 

  master_data <- tibble()
  global_row_counter <- 1
  
  for (i in 1:num_respondents) {
    # 1. Generate Static Individual-Level Characteristics (Fixed across all choices)
    v_age  <- sample(c(1, 2, 3), 1, prob = c(0.45, 0.45, 0.10))
    v_inc  <- sample(c(1, 2, 3), 1, prob = c(0.30, 0.50, 0.20))
    v_land <- sample(c(1, 2, 3, 4), 1, prob = c(0.20, 0.40, 0.30, 0.10))
    
    # Household vehicle footprints determine systemic alternatives availability flags
    owns_bike <- sample(c(0, 1), 1, prob = c(0.70, 0.30))
    owns_pvt  <- sample(c(0, 1), 1, prob = c(0.40, 0.60))
    has_drop  <- ifelse(owns_pvt == 1, sample(c(0, 1), 1, prob = c(0.30, 0.70)), 0)
    
    # --------------------------------------------------------------------
    # A. REVEALED PREFERENCE (RP) ROW - Actual Current Behavior (1 Row)
    # --------------------------------------------------------------------
    rp_row <- tibble(
      respondent_id       = i,
      row_id              = global_row_counter,
      is_sp               = 0,
      choice_situation_id = 0,
      
      # Availability rules
      av_walk = 1, av_bike = owns_bike, av_pvt = owns_pvt, 
      av_ipt = 1,  av_bus = 1,         av_drop = has_drop,
      
      # Attributes (RP usually mirrors current historical values)
      tt_walk = runif(1, 5, 25),    tt_bike = runif(1, 4, 15),
      tt_pvt  = runif(1, 5, 20),    tt_ipt  = runif(1, 6, 22),
      tt_bus  = runif(1, 10, 35),   tt_drop = runif(1, 5, 20),
      
      tc_bike = runif(1, 0, 2),     tc_pvt  = runif(1, 15, 60),
      tc_ipt  = runif(1, 30, 120),  tc_bus  = runif(1, 5, 20),
      tc_drop = runif(1, 10, 40),
      
      # Base baseline qualitative layers (RP reflects baseline conditions)
      comfort_bus   = sample(c(1, 2), 1, prob = c(0.70, 0.30)),
      infra_bike    = 0,
      infra_bus     = sample(c(0, 1), 1, prob = c(0.80, 0.20)),
      safety_street = sample(c(0, 1), 1, prob = c(0.50, 0.50)),
      weather       = sample(c(1, 2, 3), 1, prob = c(0.40, 0.40, 0.20)),
      land_use      = v_land,
      age_cohort    = v_age,
      inc_level     = v_inc
    )
    
    # --- RP LOGIT CHOICE ENGINE OPTIMIZATION ---
    # 1. Define baseline alternative utilities based on specific coefficients
    v_walk_rp = -0.10 * rp_row$tt_walk
    v_bike_rp = -0.20 * rp_row$tt_bike
    v_pvt_rp  = -0.05 * rp_row$tt_pvt
    v_ipt_rp  = -0.08 * rp_row$tt_ipt
    v_bus_rp  = -0.06 * rp_row$tt_bus
    v_drop_rp = -0.07 * rp_row$tt_drop

    # 2. Apply the structural availability mask (If av == 0, utility becomes -999)
    u_walk_rp = ifelse(rp_row$av_walk == 1, v_walk_rp, -999)
    u_bike_rp = ifelse(rp_row$av_bike == 1, v_bike_rp, -999)
    u_pvt_rp  = ifelse(rp_row$av_pvt  == 1, v_pvt_rp,  -999)
    u_ipt_rp  = ifelse(rp_row$av_ipt  == 1, v_ipt_rp,  -999)
    u_bus_rp  = ifelse(rp_row$av_bus  == 1, v_bus_rp,  -999)
    u_drop_rp = ifelse(rp_row$av_drop == 1, v_drop_rp, -999)

    # 3. Combine masked utilities
    utilities_rp <- c(u_walk_rp, u_bike_rp, u_pvt_rp, u_ipt_rp, u_bus_rp, u_drop_rp)

    # 4. Compute strict logit probabilities
    probs_rp <- exp(utilities_rp) / sum(exp(utilities_rp))

    # 5. Draw the choice cleanly from all 6 universal alternatives
    rp_row$choice <- sample(1:6, 1, prob = probs_rp)
    
    master_data <- bind_rows(master_data, rp_row)
    global_row_counter <- global_row_counter + 1
    
    # --------------------------------------------------------------------
    # B. STATED PREFERENCE (SP) ROWS - Stated Experiment Cards (15 Rows)
    # --------------------------------------------------------------------
    for (card in 1:15) {
      sp_row <- tibble(
        respondent_id       = i,
        row_id              = global_row_counter,
        is_sp               = 1,
        choice_situation_id = card,
        
        # Availability fields remain consistent with structural assets
        av_walk = 1, av_bike = owns_bike, av_pvt = owns_pvt, 
        av_ipt = 1,  av_bus = 1,         av_drop = has_drop,
        
        # SP Design Attributes vary widely based on experimental levels
        tt_walk = runif(1, 5, 25),    tt_bike = runif(1, 3, 12),
        tt_pvt  = runif(1, 4, 18),    tt_ipt  = runif(1, 5, 20),
        tt_bus  = runif(1, 8, 25),    tt_drop = runif(1, 4, 18),
        
        tc_bike = runif(1, 0, 5),     tc_pvt  = runif(1, 20, 80),
        tc_ipt  = runif(1, 40, 150),  tc_bus  = runif(1, 10, 30),
        tc_drop = runif(1, 15, 50),
        
        # Qualitative levels randomized across choice task cells
        comfort_bus   = sample(c(1, 2, 3), 1, prob = c(0.33, 0.33, 0.34)),
        infra_bike    = sample(c(0, 1), 1, prob = c(0.50, 0.50)),
        infra_bus     = sample(c(0, 1), 1, prob = c(0.50, 0.50)),
        safety_street = sample(c(0, 1), 1, prob = c(0.50, 0.50)),
        weather       = sample(c(1, 2, 3), 1, prob = c(0.33, 0.33, 0.34)),
        land_use      = v_land,
        age_cohort    = v_age,
        inc_level     = v_inc
      )
      
      # --- SP LOGIT CHOICE ENGINE OPTIMIZATION ---
      # 1. Define baseline alternative utilities based on specific coefficients
      v_walk_sp = -0.10 * sp_row$tt_walk
      v_bike_sp = -0.20 * sp_row$tt_bike
      v_pvt_sp  = -0.05 * sp_row$tt_pvt
      v_ipt_sp  = -0.08 * sp_row$tt_ipt
      v_bus_sp  = -0.06 * sp_row$tt_bus
      v_drop_sp = -0.07 * sp_row$tt_drop

      # 2. Apply the structural availability mask (If av == 0, utility becomes -999)
      u_walk_sp = ifelse(sp_row$av_walk == 1, v_walk_sp, -999)
      u_bike_sp = ifelse(sp_row$av_bike == 1, v_bike_sp, -999)
      u_pvt_sp  = ifelse(sp_row$av_pvt  == 1, v_pvt_sp,  -999)
      u_ipt_sp  = ifelse(sp_row$av_ipt  == 1, v_ipt_sp,  -999)
      u_bus_sp  = ifelse(sp_row$av_bus  == 1, v_bus_sp,  -999)
      u_drop_sp = ifelse(sp_row$av_drop == 1, v_drop_sp, -999)

      # 3. Combine masked utilities
      utilities_sp <- c(u_walk_sp, u_bike_sp, u_pvt_sp, u_ipt_sp, u_bus_sp, u_drop_sp)

      # 4. Compute strict logit probabilities
      probs_sp <- exp(utilities_sp) / sum(exp(utilities_sp))

      # 5. Draw the choice cleanly from all 6 universal alternatives
      sp_row$choice <- sample(1:6, 1, prob = probs_sp)
      
      master_data <- bind_rows(master_data, sp_row)
      global_row_counter <- global_row_counter + 1
    }
  }
  return(master_data)
}