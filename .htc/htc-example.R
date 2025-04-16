#!/usr/bin/env Rscript

library(glue)
library(tidyverse)

# Load useful functions from my_functions.R :
#   - extract_temps_data()
#   - identify_seasons()
#   - create_histogram
source('my_functions.R')

# Read in station list from the trailing arguments
station_list <- commandArgs(trailingOnly = TRUE)

for (station in station_list) {
  # Read data from file
  station_data_filename <- glue('{station}.csv')
  station_df <- read_csv(station_data_filename, col_names=TRUE)

  # Extract Min, Max Temperatures (in Fahrenheit); remove original dataframe from memory
  temps_df <- extract_temps_data(station_df)
  rm(station_df)

  # Print summary of dataframe
  summary(temps_df)

  # Add "SEASON" column to label the meteorological season each date occurred in
  temps_df <- temps_df %>% identify_seasons()

  # Create histogram of the distribution of temperatures by SEASON
  create_histogram(temps_df, station)
}
