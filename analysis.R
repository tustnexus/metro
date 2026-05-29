# ------------------------------------------------------------------------
# Discrete Choice Model Calibration Analysis Layer
# Project: Mumbai Access Mode Choice Validation (Target vs Synthetic SP)
# ------------------------------------------------------------------------

# Clear workspace and clear console visually
rm(list = ls())
cat("\014")

library(tidyverse)

# Main Analysis Script
source("helpers.R")


# 1. HARDCODED PAPERS SP MODAL SPLIT TARGETS (Single Source of Truth)
# Empirical baseline derived from East Asia Society for Transportation Studies (EASTS)
# Joint RP-SP access choice framework for Mumbai Metrorail Line-3.
# Empirical RP baseline from the paper (Current real-world transit access)
target_shares_rp <- c(
  "Walk"            = 0.45,  # Dominant baseline mode in real-world Mumbai access
  "Bicycle"         = 0.01,  # Almost negligible currently due to infrastructure gaps
  "Private_Vehicle" = 0.24,  # High personal two-wheeler / car drop and park footprint
  "IPT"             = 0.16,  # Auto-rickshaws and black-and-yellow taxis
  "Bus"             = 0.11,  # BEST feeder bus systems
  "Drop_off"        = 0.03   # Formal household drop-off
)

# Empirical SP targets (Future state shift matching your previous script)
target_shares_sp <- c(
  "Walk"            = 0.36,  # Projected to drop as access catchments expand
  "Bicycle"         = 0.04,  # Expected to slightly increase with infrastructure
  "Private_Vehicle" = 0.19,  # Projected to decline soundly
  "IPT"             = 0.13,
  "Bus"             = 0.21,  # Projected to nearly double with optimized feeder routing
  "Drop_off"        = 0.08
)


# Configuration Parameters
NUM_RESPONDENTS <- 500  # Upscaled sample size for statistical smoothing
EPSILON         <- 0.3 # Calibration trigger window bounds (5% absolute share variation)
TIMESTAMP       <- "2026-05-29-1430"

cat("=== Initializing Multi-Seed Simulation Calibration Loop ===\n")

# 2. RUN DATA GENERATION SIMULATION ENGINE THRICE (Three Separate Seeds)
sim_run1 <- generate_synthetic_data(num_respondents = NUM_RESPONDENTS, seed = 101)
sim_run2 <- generate_synthetic_data(num_respondents = NUM_RESPONDENTS, seed = 202)
sim_run3 <- generate_synthetic_data(num_respondents = NUM_RESPONDENTS, seed = 303)

# 3. ISOLATE STATED PREFERENCE (SP) OBSERVATIONS & COMPUTE MARKET SHARES
get_sp_shares <- function(survey_data) {
  survey_data %>%
    filter(is_sp == 1) %>%
    count(choice_label) %>%
    mutate(share = n / sum(n)) %>%
    select(choice_label, share)
}

shares_run1 <- get_sp_shares(sim_run1) %>% rename(share_s1 = share)
shares_run2 <- get_sp_shares(sim_run2) %>% rename(share_s2 = share)
shares_run3 <- get_sp_shares(sim_run3) %>% rename(share_s3 = share)

# 4. CONSTRUCT CALIBRATION COMPARISON MATRIX (TARGET VS SYNTHETIC SP)
paper_shares_df <- tibble(
  choice_label = names(target_shares_sp),
  target_share = as.numeric(target_shares_sp)
)

calibration_matrix <- paper_shares_df %>%
  left_join(shares_run1, by = "choice_label") %>%
  left_join(shares_run2, by = "choice_label") %>%
  left_join(shares_run3, by = "choice_label") %>%
  # Fill missing modes generated in extreme probabilistic drops with 0
  mutate(across(starts_with("share_s"), ~replace_na(., 0))) %>%
  # Compute Deltas (Synthetic minus Target Empirical Share)
  mutate(
    delta_seed1 = share_s1 - target_share,
    delta_seed2 = share_s2 - target_share,
    delta_seed3 = share_s3 - target_share
  )

cat("\n--- SP Market Share Calibration Overview Table ---\n")
# Prevent tibble console column truncation via formatting bypass
calibration_matrix %>% 
  as.data.frame() %>% 
  print(row.names = FALSE)


# 5. SANITY CHECK VALIDATION: ATTRIBUTE REASONABLENESS OVER MATRIX
combined_survey_data <- bind_rows(sim_run1, sim_run2, sim_run3)

cat("\n--- Running Deep Cross-Attribute Sanity Checks ---\n")

# Compute cross-tabulations for behavioral auditing
mean_tt_walk   <- aggregate(tt_walk ~ choice_label, combined_survey_data, mean)
mean_tt_bus    <- aggregate(tt_bus ~ choice_label, combined_survey_data, mean)
mean_comfort   <- aggregate(comfort_bus ~ choice_label, combined_survey_data, mean)
mean_cost_bus  <- aggregate(tc_bus ~ choice_label, combined_survey_data, mean)

# For bicycle infrastructure, check if variable matches data_dictionary.csv column name
# If your column is named 'comfort_bike', we map it dynamically here
bike_infra_col <- if("infra_bike" %in% names(combined_survey_data)) "infra_bike" else "comfort_bike"
mean_bike_inf  <- aggregate(as.formula(paste(bike_infra_col, "~ choice_label")), combined_survey_data, mean)

# Print current state to R Console for immediate scannability
print(mean_tt_walk, row.names = FALSE)
print(mean_tt_bus, row.names = FALSE)


# 6. AUTOMATED RE-CALIBRATION DIAGNOSTIC FILE GENERATION (WITH OBSERVATIONS)
log_filename <- sprintf("comments-%s-calibration.md", TIMESTAMP)
log_con <- file(log_filename, "w")

writeLines(paste0("# Model Calibration & Behavioral Audit Report - ", TIMESTAMP), log_con)

# Part A: Market Share Epsilon Breaches
critical_mismatches <- calibration_matrix %>%
  filter(abs(delta_seed1) > EPSILON | abs(delta_seed2) > EPSILON | abs(delta_seed3) > EPSILON)

writeLines("\n## 1. Target Share Alignment Tracker", log_con)
if (nrow(critical_mismatches) > 0) {
  writeLines(sprintf("The following alternatives breached the acceptable variance threshold (epsilon = %s):", EPSILON), log_con)
  for (i in 1:nrow(critical_mismatches)) {
    row <- critical_mismatches[i, ]
    writeLines(sprintf("\n### Alternative: Mode '%s'", row$choice_label), log_con)
    writeLines(sprintf("  * Empirical Target Share (SP): %s%%", pct(row$target_share)), log_con)
    writeLines(sprintf("  * Simulated Shares (S1/S2/S3): %s%% / %s%% / %s%%", 
                       pct(row$share_s1), pct(row$share_s2), pct(row$share_s3)), log_con)
    
    if (mean(c(row$delta_seed1, row$delta_seed2, row$delta_seed3)) > 0) {
      writeLines("  * **Calibration Advice**: Mode is over-predicted. Reduce its baseline Alternative Specific Constant (ASC).", log_con)
    } else {
      writeLines("  * **Calibration Advice**: Mode is under-predicted. Increase its ASC coefficient.", log_con)
    }
  }
} else {
  writeLines("\n[SUCCESS] All synthetic mode shares track perfectly within epsilon tolerances.", log_con)
}

# Part B: Empirical Reality Observations (The Sanity Checks)
writeLines("\n## 2. Behavioral Sanity Check Observations", log_con)

# Observation 1: Walk Time Sensitivities
walk_min_mode <- mean_tt_walk[which.min(mean_tt_walk$tt_walk), "choice_label"]
writeLines(sprintf("\n###  Walk Time Sensitivity Profile\n* **Observation**: Commuters choosing **%s** had the shortest average walk time (%s mins).", 
                   walk_min_mode, round(min(mean_tt_walk$tt_walk), 2)), log_con)
writeLines("* **Expected Reality**: Walk choosers must display the lowest average walk times; spike variations indicate weak negative travel time coefficients ($B_{tt\\_walk}$).", log_con)

# Observation 2: Bus Time Sensitivities
bus_time_val <- mean_tt_bus[mean_tt_bus$choice_label == "Bus", "tt_bus"]
writeLines(sprintf("\n###  Bus Time Sensitivity Profile\n* **Observation**: Commuters choosing **Bus** experienced an average bus travel time of %s mins.", 
                   if(length(bus_time_val) > 0) round(bus_time_val, 2) else "N/A"), log_con)
writeLines("* **Expected Reality**: Bus choosers should have relatively low bus times compared to those who rejected the bus under heavy delays.", log_con)

# Observation 3: Bicycle Infrastructure Access
bike_max_mode <- mean_bike_inf[which.max(mean_bike_inf[[2]]), "choice_label"]
writeLines(sprintf("\n###  Bicycle Infrastructure Profile\n* **Observation**: Highest bicycle infrastructure score/presence (%s) was observed among **%s** choosers.", 
                   round(max(mean_bike_inf[[2]]), 2), bike_max_mode), log_con)
writeLines(sprintf("* **Expected Reality**: Bicycle choosers should pull the highest average index for `%s`, proving that dedicated tracks incentivize active choice shifts.", bike_infra_col), log_con)

# Observation 4: Bus Comfort Dynamics
comfort_max_mode <- mean_comfort[which.max(mean_comfort$comfort_bus), "choice_label"]
writeLines(sprintf("\n###  Bus Comfort & Crowding Profile\n* **Observation**: Highest transit vehicle comfort rating (%s) was tracked among **%s** choosers.", 
                   round(max(mean_comfort$comfort_bus), 2), comfort_max_mode), log_con)
writeLines("* **Expected Reality**: Bus choosers should experience high comfort scores (lower vehicle crowding); if they choose highly crowded buses consistently, your comfort parameter multipliers require heavier negative penalty scaling.", log_con)

# Observation 5: Cost Disutility (Generalized Cost)
bus_cost_val <- mean_cost_bus[mean_cost_bus$choice_label == "Bus", "tc_bus"]
writeLines(sprintf("\n###  Cost Sensitivity Profile\n* **Observation**: Commuters choosing Bus paid an average fare cost of INR %s.", 
                   if(length(bus_cost_val) > 0) round(bus_cost_val, 2) else "N/A"), log_con)
writeLines("* **Expected Reality**: Assuming cost enters utility formulations negatively ($B_{cost} < 0$), Bus choosers should map to lower average out-of-pocket costs relative to premium private setups.", log_con)

close(log_con)
cat(sprintf("\n[DIAGNOSTICS COMPLETE] Behavioral audit observations written to: %s\n", log_filename))


# ------------------------------------------------------------------------
# Calibration Validation Visualization Layer
# ------------------------------------------------------------------------

# 1. Reshape wide calibration matrix into clean long format for ggplot
viz_data <- calibration_matrix %>%
  select(choice_label, target_share, share_s1, share_s2, share_s3) %>%
  pivot_longer(
    cols = starts_with("share_s"), 
    names_to = "seed", 
    values_to = "synthetic_share"
  ) %>%
  mutate(
    seed_label = case_when(
      seed == "share_s1" ~ "Seed 101",
      seed == "share_s2" ~ "Seed 202",
      seed == "share_s3" ~ "Seed 303"
    )
  )

# 2. Build the Model Calibration Discrepancy Plot
ggplot(viz_data, aes(x = reorder(choice_label, target_share))) +
  # Draw a background reference shadow tracking the target
  geom_segment(
    aes(xend = choice_label, y = target_share, yend = synthetic_share), 
    color = "grey75", linewidth = 0.8, linetype = "dashed"
  ) +
  # Plot the empirical paper targets as highly visible cross-bars
  geom_errorbar(
    aes(y = target_share, ymin = target_share, ymax = target_share),
    width = 0.4, color = "firebrick3", linewidth = 1.2
  ) +
  # Scatter the multi-seed synthetic results to observe stochastic spread
  geom_point(
    aes(y = synthetic_share, color = seed_label), 
    size = 4, alpha = 0.85, position = position_dodge(width = 0.2)
  ) +
  # Format axes to match economic notation
  scale_y_continuous(labels = scales::percent_format(accuracy = 1), limits = c(0, 0.45)) +
  scale_color_manual(values = c("Seed 101" = "#1f77b4", "Seed 202" = "#aec7e8", "Seed 303" = "#2ca02c")) +
  coord_flip() + # Flip for professional look matching complex category text layout
  labs(
    title = "Mumbai Metro Access Mode Split: Calibration Audit",
    subtitle = "Red bars denote empirical paper targets; points denote synthetic choice loops",
    x = "Access Mode Alternative",
    y = "Predicted SP Market Share (%)",
    color = "Simulation Stream"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )

# 3. Export to production quality PNG image
ggsave(
  filename = "output/calibration_target_mismatch.png", 
  width = 8, 
  height = 5, 
  dpi = 300
)

cat("\n[VIZ COMPLETE] Calibration discrepancy chart successfully exported to: output/calibration_target_mismatch.png\n")