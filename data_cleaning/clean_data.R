#Setting arguments
args <- commandArgs(trailingOnly = TRUE)

#args[1] - filepath for partitioned data from sample_table.csv
#args[2] - filepath for "tel_aviv_neighborhood.csv"
#args[3] - filepath and name for partitioned clean_data

# Libraries
library(tidyverse)
library(sf)

#Read points data
car_share <- read.csv(args[1])

# Modify timestampt to string and round to nearest hour
car_share$timestamp <- round.POSIXt(car_share$timestamp, units = "hours")
car_share$timestamp <- as.character(car_share$timestamp)

# Read Neighborhood data
neighborhood <- read.csv(args[2])

#Create simple feature data for neighborhood
neighborhood_sf <-st_as_sf(neighborhood, wkt = "area_polygon", crs=4326)

#Create simple feature data for car_share points
car_share_sf <- st_as_sf(car_share, coords = c("longitude","latitude"), crs=4326)

# Verify which point are in which neighborhood
parked_cars <- st_join(car_share_sf, neighborhood_sf, join=st_within)

# Drop gerometry for car_share_sf and select the desired columns
parked_cars <- parked_cars %>% select(timestamp, total_cars, carsList, neighborhood_id, neighborhood_name, Shape_Area) %>% st_drop_geometry()

# removing NAs
parked_cars <- subset(parked_cars, !is.na(parked_cars$neighborhood_id))

# so we want to get the number of vehicles that where parked in a specific neighborhood within an hour. If we just group by and sum the total cars then we will be counting twice or more cars that just made within neighborhood trips. 
parked_cars <- parked_cars %>% group_by(timestamp,neighborhood_id,neighborhood_name) %>% mutate(carList_hour = paste0(carsList, collapse = ","))
parked_cars <- ungroup(parked_cars) %>% mutate(carList_hour = str_extract_all(carList_hour,"\\d+"))
unique_count <- function(x){
  n= length(unique(unlist(x)))
  return(n)
}
parked_cars$n_cars <- unlist(lapply(parked_cars$carList_hour, unique_count))
parked_cars <- parked_cars %>%  group_by(timestamp,neighborhood_id,neighborhood_name,Shape_Area) %>% summarise(cars = mean(n_cars))

#Write parked_cars as csv
write.csv(parked_cars,file = args[3])
