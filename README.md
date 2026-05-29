# Mumbai Metro Access Mode Choice Modeling

A transport econometrics and discrete choice modeling project implemented in R for analyzing first-mile and last-mile access behavior to future Mumbai Metro stations using a Joint Revealed Preference–Stated Preference (RP-SP) Multinomial Logit (MNL) framework.

## Project Overview

This repository contains an experimental implementation of a Joint RP-SP access mode choice model inspired by the research paper:

> *What are the likely access modes to future metro rail stations? A stated preference choice experiment of Mumbai commuters*

### Authors

* Manoj B. Sangameshwar
* Mandar Vaidya
* Arkopal K. Goswami

### Affiliations

* Ranbir and Chitra Gupta School of Infrastructure Design and Management, Indian Institute of Technology Kharagpur, India
* University of British Columbia, Okanagan Campus, Canada
* KPMG Mumbai, India

Published in:

> Proceedings of the Eastern Asia Society for Transportation Studies (EASTS), Vol. 15, 2025.

### Reference Paper

Sangameshwar, M. B., Vaidya, M., & Goswami, A. K. (2025).  
*What are the likely access modes to future metro rail stations? A stated preference choice experiment of Mumbai commuters.*

[Read the paper (PDF)](https://easts.info/on-line/proceedings/vol.15/pdf/C_PP4221.pdf)

---

## Research Objective

The study investigates how Mumbai commuters are likely to access future Metro Line-3 stations using different first-mile and last-mile transport modes.

The project models commuter choice behavior across multiple transport alternatives using a Joint RP-SP Multinomial Logit framework.

The alternatives include:

* Walking
* Bicycle
* Personal Vehicle
* IPT (Intermediate Public Transport)
* Bus
* Drop-off

The implementation focuses on:

* Synthetic RP-SP dataset generation
* Discrete choice data architecture
* Utility specification
* Access mode availability constraints
* Apollo-based econometric estimation
* Future scenario simulation

---

## Current Project Structure

```text
metro/
├── data/
│   └── data_dictionary.csv
├── output/
│   ├── Respondent_Scenario.png
│   ├── Same_Scenario_With_Labels.png
│   └── synthetic_data_compared_to_research_paper.png
├── analysis.R
├── helpers.R
├── metro.Rproj
├── README.md
└── state.md
```

### File Descriptions

#### `analysis.R`

Main execution script for the project.

Responsibilities include:

* generating synthetic RP-SP observations
* validating dataset structure
* performing calibration diagnostics
* producing visualizations
* preparing data for future Apollo estimation

#### `helpers.R`

Contains reusable functions for:

* synthetic respondent generation
* utility calculations
* mode choice simulation
* validation utilities
* reporting support

#### `data/data_dictionary.csv`

Defines the canonical schema used throughout the project, including variable names, coding conventions, and attribute descriptions.

#### `state.md`

Project notebook containing implementation status, design decisions, calibration findings, and upcoming work items.

#### `output/`

Stores generated figures and calibration diagnostics used during model development and validation.

---

## Modeling Framework

The project is based on Random Utility Theory and uses a Joint RP-SP MNL specification.

Conceptually:

```text
U_RP = V_RP + ε
U_SP = μ(V_SP + ε)
```

where:

* `V` is the deterministic utility component
* `ε` is the random error term
* `μ` is the RP-SP scale parameter

The implementation aims to reproduce and extend the methodology described in the original paper.

---

## R Packages

Primary packages used:

```r
library(tidyverse)
library(apollo)
```

### Install Dependencies

```r
install.packages("tidyverse")
install.packages("apollo")
```

---

## Current Development Status

Implemented:

* project architecture and repository structure
* synthetic RP-SP dataset generator
* mode availability constraints
* utility-based choice simulation
* multi-seed stability testing
* cross-attribute sensitivity validation
* calibration diagnostics against published SP mode shares
* visualization and reporting infrastructure

In Progress:

* calibration of alternative-specific constants (ASCs)
* utility specification refinement

Planned:

* Apollo integration
* joint RP-SP likelihood estimation
* scale parameter estimation
* model validation against published coefficients
* policy scenario analysis


---

## Notes on Synthetic Data

The current implementation uses synthetic commuter observations for architecture testing and model prototyping.

The synthetic data generator creates:

* 1 RP observation per respondent
* 15 SP choice situations per respondent

with mode availability conditioned on household vehicle ownership.

---

## Long-Term Goals

Potential future extensions include:

* Mixed Logit models
* Nested Logit models
* Mode-shift elasticity estimation
* Transit-oriented development (TOD) policy simulation
* Integration with GIS and land-use datasets
* Real Mumbai survey calibration

---


## Disclaimer

This repository is currently an experimental academic implementation intended for learning, modeling exploration, and future research development.

It is not yet a production-grade transport forecasting system.
