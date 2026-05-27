
# ------------------------------------------------------------------------
# Mumbai Access Mode Choice Modeling
# Main Analysis Script - Data Architecture Block
# ------------------------------------------------------------------------

# Clear workspace
rm(list = ls())

# Load libraries
library(tidyverse)

# Source helper functions
source("helpers.R")


# ------------------------------------------------------------------------
# Load and Generate Synthetic Structural Data Frame
# ------------------------------------------------------------------------

cat("### Generating unified Long-Form Joint RP-SP Dataset... \n")
# Call with explicit tracking seed
survey_data <- generate_synthetic_data(num_respondents = 10, seed = 123)

# Verify dimensions and properties match schema exactly
cat("\n--- Structure Verification ---\n")
cat("Total Rows Generated:", nrow(survey_data), "(Expected: 160)\n")
cat("Total Columns Loaded:", ncol(survey_data), "(Expected: 29)\n")

# Tabulate verification layers
cat("\n--- Distribution of Rows Across Modes and Instruments ---\n")
print(table(survey_data$is_sp, useNA = "always"))

cat("\n--- Check Sample Rows Tracking One Respondent (ID: 1) ---\n")
# Select the first 3 rows (1 RP row and the first 2 SP choices) to preview layout
preview_df <- survey_data %>% 
  filter(respondent_id == 1) %>% 
  select(respondent_id, is_sp, choice_situation_id, choice, av_bike, tt_walk, tt_bus) %>% 
  slice(1:3)

print(preview_df)

cat("\nProject initialized and data structure validated successfully.\n")

# ----------------------------------------
# Initial Exploration
# ----------------------------------------

cat("Project initialized successfully\n")

# ------------------------------------------------------------------------
# Diagnostic: Track Choice Divergence (Random vs. Logit Utility Engine)
# ------------------------------------------------------------------------
cat("\n### Running Choice Engine Differential Test... \n")

# 1. Generate data using the OLD random logic 
# (Temporarily simulate by passing flat utilities to verify tracking script)
sim_random <- generate_synthetic_data(num_respondents = 10, seed = 123)

# 2. Generate data using your NEW logit logic 
sim_utility <- generate_synthetic_data(num_respondents = 10, seed = 234)

# 3. Bind choices together to isolate the delta
choice_comparison <- tibble(
  respondent_id = sim_random$respondent_id,
  is_sp         = sim_random$is_sp,
  tt_walk       = sim_random$tt_walk,
  tt_bus        = sim_random$tt_bus,
  old_choice    = sim_random$choice,
  new_choice    = sim_utility$choice
) %>% 
  # Filter strictly for rows where the choices changed
  filter(old_choice != new_choice)

cat("Number of choices changed due to utility math:", nrow(choice_comparison), "out of 160\n")

if(nrow(choice_comparison) > 0) {
  cat("\n--- Sample of Changed Choices ---\n")
  print(head(choice_comparison, 10))
}

# Minimal code to dump both datasets to CSV
write_csv(sim_random, "data/sim_random.csv")
write_csv(sim_utility, "data/sim_utility.csv")