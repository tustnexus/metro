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
├── analysis.R
├── helpers.R
└── metro.Rproj
```

### File Descriptions

#### `analysis.R`

Main orchestration script.

Responsibilities include:

* loading libraries
* sourcing helper functions
* generating or loading datasets
* validating schema structure
* defining model specifications
* running future estimations

#### `helpers.R`

Contains reusable helper functions including:

* synthetic RP-SP data generation
* utility helpers
* missing value diagnostics
* formatting functions
* future modeling utilities

#### `data/data_dictionary.csv`

Canonical schema reference for the RP-SP dataset.

Will eventually define:

* variable names
* variable descriptions
* data types
* coding conventions
* allowable categorical values

#### `output/`

Stores generated outputs including:

* model estimation results
* plots
* diagnostics
* exported tables

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

* project scaffolding
* synthetic RP-SP dataset generator
* availability constraints
* schema verification checks
* exploratory infrastructure

Planned:

* Apollo estimation integration
* utility specification
* likelihood functions
* RP-SP scale estimation
* validation diagnostics
* policy scenario simulation
* visualization layer

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
