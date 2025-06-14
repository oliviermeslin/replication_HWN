rm(list=ls())

###############################################
###############################################
###############################################
# Addition to the original script
###############################################
###############################################
###############################################

library(DBI)
library(duckdb)
library(dplyr)
library(glue)

###############################################
# Load French data on transactions
###############################################

# Instantiate duckdb connection
conn_ddb <- DBI::dbConnect(duckdb::duckdb())

# Prepare access to S3
dbExecute(conn_ddb, "LOAD postgres;")
dbExecute(conn_ddb, "LOAD httpfs;")
dbExecute(conn_ddb, "LOAD spatial;")

dbExecute(conn_ddb, "SET s3_url_style = 'path';")

# Load French transaction data
dbExecute(
  conn_ddb, 
  glue(
    "
    CREATE OR REPLACE VIEW transaction_data AS
    SELECT * from read_parquet('s3://oliviermeslin/tempFF/table_logements_vendus_final.parquet')
    "
  )
)
transaction_data <- tbl(conn_ddb, "transaction_data")

###############################################
# Define variables used in the models
###############################################

model_variables <- c(
  "anneemut",                          "moismut",                           "jannath",                          
  "x",                                 "y",                                 "dnbniv",                           
  "dnbbai",                            "dnbdou",                            "dnblav",                           
  "dnbwc",                             "dnbppr",                            "dnbsam",                           
  "dnbcha",                            "dnbcu8",                            "dnbcu9",                           
  "dnbsea",                            "dnbann",                            "dnbpdc",                           
  "dsupdc",                            "geaulc",                            "gelelc",                           
  "gesclc",                            "ggazlc",                            "gasclc",                           
  "gchclc",                            "gvorlc",                            "gteglc",                           
  "dniv",                              "nb_garages",                       
  "nb_piscines",                       "nb_terrasses",                      "nb_greniers",                      
  "nb_caves",                          "nb_autresdep",                      "holdout",
  "l_km2pris"
)

###############################################
# Define the dataset and build the holdout set
###############################################

# Load data on flats sold in Paris and define the target
transaction_data_flats_paris <- transaction_data |>
  filter(ccodep == "75" & dteloc == "2" & libnatmut == "Vente") |>
  # The target is the log of price per sqm. I use the name "l_km2pris" to minimize changes in other codes.
  mutate(l_km2pris = log(valeurfonc / dsupdc)) |>
  mutate(random_number = random()) |>
  compute("transaction_data_flats_paris", temporary = FALSE, overwrite = TRUE)

# The holdout set contains 20% of the data, randomly chosen
holdout_set <- transaction_data_flats_paris |>
  filter(random_number >= 0.8) |> 
  mutate(holdout = NA) |>
  select(all_of(model_variables)) |>
  collect()

###############################################
###############################################
###############################################
# Code from the original script
###############################################
###############################################
###############################################

# The training data (dbase) contains the other 80% of the data
dbase   <- transaction_data_flats_paris |>
  filter(random_number < 0.8) |> 
  mutate(holdout = (random_number > 0.6)) |>
  select(all_of(model_variables)) |>
  collect()
dtaname <- "flats_paris"

source("/home/onyxia/work/replication_HWN/Hedonic Housing Replication/ML/1_dataprep.R")
source("/home/onyxia/work/replication_HWN/Hedonic Housing Replication/ML/2_fitmodel.R")

