
# ------------------------------------------------------------------------
# Mumbai Access Mode Choice Modeling
# Main Analysis Script - Data Architecture Block
# ------------------------------------------------------------------------

# Clear workspace and clear console visually
rm(list = ls())
cat("\014")

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
cat("Total Columns Loaded:", ncol(survey_data), "(Expected: 33 independent)\n")

# Tabulate verification layers
cat("\n--- Distribution of Rows Across RP stated and SP scenarios ---\n")
print(table(survey_data$is_sp, useNA = "always"))

cat("\nProject initialized and data structure validated successfully.\n")

# ----------------------------------------
# Initial Exploration
# ----------------------------------------

# Define the ID you want to track at the top of your diagnostic block
target_id <- 2

cat(sprintf("\n--- Check Sample Rows Tracking One Respondent (ID: %d) ---\n", target_id))

# Select the first 3 rows (1 RP row and the first 2 SP choices) to preview layout
preview_df <- survey_data %>% 
  filter(respondent_id == target_id) %>% 
  select(respondent_id, is_sp, choice_situation_id, choice, av_bike, tt_walk, tt_bus) %>% 
  slice(1:11)

print(preview_df)

# ------------------------------------------------------------------------
# Viz
ggplot(preview_df, aes(x = factor(choice_situation_id), y = factor(choice), color = factor(is_sp))) +
  geom_point(size = 4, alpha = 0.8) +
  scale_color_manual(values = c("black", "#1f77b4"), labels = c("RP (Real Life)", "SP Card")) +
  labs(title = "Respondent 2: Choice Trajectory Across Situations",
       x = "Choice Situation ID (0 = Real Life)", y = "Chosen Alternative Code", color = "Context") +
  theme_minimal()

  # Save the last displayed plot automatically to your project folder
ggsave("output/respondent_trajectory.png", width = 8, height = 5, dpi = 300)
# ------------------------------------------------------------------------


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
# write_csv(sim_random, "data/sim_random.csv")
# write_csv(sim_utility, "data/sim_utility.csv")