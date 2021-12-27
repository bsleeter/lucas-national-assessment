


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


# Get results from single cell model run
stocks_singlecell = datasheet(myProject, scenario = 52, "stsimsf_OutputStock") %>% as_tibble()
stocks_singlecell_reformat = stocks_singlecell %>%
  mutate_if(is.factor, as.character) %>%
  arrange(Timestep, StockGroupID, StateClassID) %>%
  rename("AgeMin" = "Timestep") %>%
  select(StateClassID, StockGroupID, AgeMin, Amount) %>%
  filter(str_detect(StockGroupID, "Type")) %>%
  mutate(StockGroupID = stri_replace_all_fixed(StockGroupID, " [Type]", "")) %>%
  #mutate(StockGroupID = stri_replace_all_fixed(StockGroupID, "DOM: ", "")) %>%
  #mutate(StockGroupID = stri_replace_all_fixed(StockGroupID, "Biomass: ", "")) %>%
  filter(!StockGroupID %in% c("Atmosphere", "Atmosphere: CO2", "Atmosphere: CH4", "Atmosphere: CO", "Peat", "Black Carbon", "Forestry Sector", "DOM: Black Carbon")) %>%
  rename("LUCAS_Value" = "Amount")
unique(stocks_singlecell_reformat$StockGroupID)
stocks_singlecell_reformat 

# Read in the CBM State Attribute File
stocks_stateAttributes = read_csv("data/state-attributes/state-attribute-values-fire.csv") %>%
  select(-StratumID, -SecondaryStratumID, -AgeMax) %>%
  rename("StockGroupID" = "StateAttributeTypeID") %>%
  arrange(AgeMin, StockGroupID, StateClassID) %>%
  mutate(StockGroupID = str_remove(StockGroupID, pattern = "Carbon Initial Conditions: ")) %>%
  mutate(StockGroupID = if_else(StockGroupID=="Aboveground Fast", "DOM: Aboveground Fast",
                                if_else(StockGroupID=="Aboveground Very Fast", "DOM: Aboveground Very Fast", 
                                        if_else(StockGroupID=="Aboveground Medium", "DOM: Aboveground Medium",
                                                if_else(StockGroupID=="Aboveground Slow", "DOM: Aboveground Slow",
                                                        if_else(StockGroupID=="Belowground Very Fast", "DOM: Belowground Very Fast",
                                                                if_else(StockGroupID=="Belowground Fast", "DOM: Belowground Fast",
                                                                        if_else(StockGroupID=="Belowground Slow", "DOM: Belowground Slow", StockGroupID)))))))) %>%
  mutate(StockGroupID = if_else(StockGroupID=="Coarse Roots", "Biomass: Coarse Root",
                                if_else(StockGroupID=="Fine Roots", "Biomass: Fine Root",
                                        if_else(StockGroupID=="Foliage", "Biomass: Foliage",
                                                if_else(StockGroupID=="Merchantable", "Biomass: Merchantable",
                                                        if_else(StockGroupID=="Other Wood", "Biomass: Other Wood",
                                                                if_else(StockGroupID=="Snag Stem", "DOM: Snag Stem",
                                                                        if_else(StockGroupID=="Snag Branch", "DOM: Snag Branch", StockGroupID)))))))) %>%
  filter(StockGroupID != "Net Growth") %>%
  rename("CBM_Value" = "Value")
unique(stocks_stateAttributes$StockGroupID)


stocks_comparison_all = stocks_singlecell_reformat %>%
  left_join(stocks_stateAttributes) %>%
  write_csv("output/validation/lucas-cbm-stock-comparison_all.csv")


stocks_comparison = stocks_singlecell_reformat %>%
  left_join(stocks_stateAttributes) %>%
  filter(StateClassID == "Forest: Douglas-fir Group") %>%
  write_csv("output/validation/lucas-cbm-stock-comparison.csv")


ggplot(stocks_comparison, aes(x=CBM_Value, y=LUCAS_Value)) +
  geom_point() +
  facet_wrap(~StockGroupID, scales = "free")

ggplot(stocks_comparison, aes(x=AgeMin, y=LUCAS_Value)) +
  geom_line(aes(x=AgeMin, y=CBM_Value), color="black", size=2) +
  geom_line(aes(x=AgeMin, y=LUCAS_Value), color="red") +
  facet_wrap(~StockGroupID, scales = "free")
