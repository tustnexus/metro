# Suggested progression:

## Stage 1 (Done)

✔ Dataset generation

## Stage 2 (Done)

✔ Reasonable mode shares

## Stage 3 (Next)

✔ Validate attribute sensitivity.

Examples:

aggregate(tt_walk ~ choice_label, survey_data, mean)

aggregate(tc_bus ~ choice_label, survey_data, mean)

You want to see things like:

Walk choosers
    lower walk times

Bus choosers
    lower bus generalized cost

Bicycle choosers
    better bicycle infrastructure

If those relationships appear, utilities are behaving correctly.

## Stage 4

✔ Scale up:

survey_data <- generate_synthetic_data(
    num_respondents = 1000,
    seed = 123
)

I have left the num_respondents = 500 in the current code

Then verify the mode shares stabilize.

## Stage 5

✔ Freeze the schema.

At this point I'd treat:

data_dictionary.csv

as a contract.

Future utility code should adapt to the schema rather than continually changing column names.

## Stage 6

Begin Apollo integration.

The paper estimated a Joint RP-SP MNL using Apollo with a scale parameter μ for SP observations.

Details in the paper linked in the README

Happy Coding