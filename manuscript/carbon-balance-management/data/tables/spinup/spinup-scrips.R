

library(raster)
library(tidyverse)
library(rsyncrosim)
library(stringi)

# Create a simple ST-Sim library which will calculate spatial initial conditions maps from non-spatial input
SyncroSimDir <- "C:/Program Files/SyncroSim/"
mySession <- session(SyncroSimDir)

ssimDir = "F:/national-assessment/models/"

myLibrary = ssimLibrary(name = paste0(ssimDir,"Spin-up Model Conus.ssim"), session = mySession)
#myLibrary = ssimLibrary(name = paste0(ssimDir,"Initial Stocks Model.ssim"), session = mySession)
myProject = project(myLibrary, project="Definitions")



stocks_spinup = datasheet(myProject, scenario = 137, "stsimsf_OutputStock", fastQuery = T) %>% as_tibble()
stocks_spinup_reformat = stocks_spinup %>%
  mutate_if(is.factor, as.character) %>%
  filter(str_detect(StockGroupID, "Type")) %>%
  mutate(StockGroupID = stri_replace_all_fixed(StockGroupID, " [Type]", "")) %>%
  mutate(TertiaryStratumID = stri_replace_all_fixed(TertiaryStratumID, "Last Disturbance: ", "")) %>%
  select(Timestep, TertiaryStratumID, StateClassID, StockGroupID, Amount) %>%
  filter(!StockGroupID %in% c("Atmosphere", "Atmosphere: CO2", "Atmosphere: CH4", "Atmosphere: CO", "Peat", "Black Carbon", "Forestry Sector", "DOM: Black Carbon")) %>%
  arrange(Timestep) %>%
  write_csv("F:/national-assessment/output/spin-up/stocks-spin-up.csv")
unique(stocks_spinup_reformat$StockGroupID)

stocks_spinup_select = stocks_spinup_reformat %>%
  filter(StateClassID == "Forest: Douglas-fir Group") %>%
  write_csv("F:/national-assessment/output/spin-up/stocks-spin-up-douglas-fir.csv")

ggplot(stocks_spinup_select, aes(x=Timestep, y=Amount, color=TertiaryStratumID)) +
  geom_line() +
  facet_grid(StockGroupID~TertiaryStratumID)
unique(stocks_spinup_select$StockGroupID)


