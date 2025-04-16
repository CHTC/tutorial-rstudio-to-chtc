#!/usr/bin/env Rscript

library(glue)
library(tidyverse)

extract_temps_data <- function(ghcn_df, convert_to_fahrenheit=TRUE) {
  #' Returns a dataframe of only the temperature data
  
  temps_df <- ghcn_df %>%
    # Pivot to move values of ELEMENT to columns
    pivot_wider(
      id_cols = DATE, 
      names_from = ELEMENT, 
      values_from = DATA_VALUE
      ) %>% 
    # Only keep the date and temperature columns
    subset(
      select = c("DATE", "TMIN", "TMAX")
      ) %>%
    # Clean data types, units
    mutate(
      # Convert to proper date type
      DATE = as.Date(as.character(DATE), format = "%Y%m%d")
    )

  if (convert_to_fahrenheit) {
    # Convert temps from tenth-degrees-C to degrees-Fahrenheit
    temps_df <- temps_df %>% mutate(
      TMIN = ((TMIN / 10) * 9 / 5) + 32,
      TMAX = ((TMAX / 10) * 9 / 5) + 32
      )
  } else {
    # Convert temps from tenth-degrees-C to degrees-Celsius
    temps_df <- temps_df %>% mutate(
      TMIN = (TMIN / 10),
      TMAX = (TMAX / 10)
      )
  }
  
  return(temps_df)
}

identify_seasons <- function(input_df, southern_hemisphere=FALSE){
  #' Adds a SEASON column corresponding to the meteorological season the

  # DATE falls under
  if (southern_hemisphere) {
    # Index corresponds to month's number
    seasons_mapping <- c('SUMMER', 'SUMMER', 
                         'FALL', 'FALL', 'FALL', 
                         'WINTER', 'WINTER', 'WINTER',
                         'SPRING', 'SPRING', 'SPRING',
                         'SUMMER')    
  } else {
    # Index corresponds to month's number
    seasons_mapping <- c('WINTER', 'WINTER', 
                         'SPRING', 'SPRING', 'SPRING', 
                         'SUMMER', 'SUMMER', 'SUMMER',
                         'FALL', 'FALL', 'FALL',
                         'WINTER')
  }
  
  season_df <- input_df %>% 
    mutate(
      SEASON = seasons_mapping[month(DATE)]
    )
  
  return(season_df)
}

create_histogram <- function(
    temps_df, 
    station_id, 
    filename=glue('{station_id}.png'),
    use_celsius=FALSE
    ) {
  #' Saves a histogram of the daily temperatures sorted by meteorological season.
  
  # Print out simple metrics about observations
  n_days <- length(temps_df$DATE)
  start_date <- min(temps_df$DATE)
  end_date <- max(temps_df$DATE)
  n_years <- round(n_days / 365.25, digits = 1)
  
  print(glue(
    'Plotting histograms of observations for {format(n_days, big.mark = ",")} days,
    spanning {n_years} years from {start_date} to {end_date},
    and saving to "{filename}".'
  ))
  
  # Set histogram parameters
  if (use_celsius) {
    min_temp <- -40 # Celsius
    max_temp <- 41 # Celsius
    x_label <- expression("Temperature (" * degree * "C)")
  } else {
    min_temp <- -40 # Fahrenheit
    max_temp <- 110 # Fahrenheit
    x_label <- expression("Temperature (" * degree * "F)")
  }
  
  seasons_histograms <- ggplot() +
    geom_histogram(data=temps_df, bins=30, aes(x=TMAX, y=after_stat(density)), color='darkred', fill='darkred') +
    geom_histogram(data=temps_df, bins=30, aes(x=TMIN, y=-after_stat(density)), color='darkblue', fill='darkblue') +
    xlim(min_temp, max_temp) + 
    facet_grid(rows=vars(SEASON)) + 
    labs(title='Distribution of Min, Max Temperatures across the Seasons',
         subtitle=glue('from {start_date} to {end_date} for Station at {station_id}'), 
         x=x_label)
  
  ggsave(filename, plot=seasons_histograms)
}
