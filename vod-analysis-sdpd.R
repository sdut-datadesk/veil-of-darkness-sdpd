# Libraries
library(readr)
library(dplyr)
library(stringr)
library(stringi)

# Set working directory
setwd("~/Desktop/veil-of-darkness-sdpd")

###################################################################
######################## IMPORT STOPS #############################
###################################################################

# Import stop data
library(readr)
stops <- read_csv("ripa_stops_datasd.csv", 
                  col_types = cols(highway_exit = col_character(), 
                                   stop_id = col_character(),
                                   time_stop = col_character(),
                                   land_mark = col_character(), officer_assignment_key = col_character(), 
                                   school_name = col_character()))
## Row count == 427,365

# Create column for eventual merge
stops$id <- paste0(stops$stop_id, "_", stops$pid)

# Rearrange
library(dplyr)
stops <- stops %>%
  select(stop_id, pid, id, everything())

# How many unique stop_individuals are there?
n_distinct(stops$id)
# 427,350
## df contains duplicate rows

# Find duplicates
dups <- table(stops$id) %>% as.data.frame()
dups <- dups %>% filter(Freq >1)
# There are 15 stops_people (30 rows) that appear to have all of the same info, except for age.
## Most were entered by officers with 1 year of experience.

# Remove duplicates from df, as they represent < .01 percent of whole
## New row count == 427335
stops = subset(stops, !(id %in% dups$Var1))

# Check unique stop_individuals again
n_distinct(stops$id)
# == 427,335 -- matches row count

# Simplify column names
names(stops)
names(stops) <- c("stop_id", "pid", "id", "ori", "agency", "exp_years", 
                  "date", "time", "dur", "is_serv", "assign_key", 
                  "assign_words", "inters", "block", "ldmk", 
                  "street", "hw_exit", "is_school", "school_name", 
                  "city", "beat", "beat_name", "is_student", "lim_eng", 
                  "age", "gender_words", "is_gendnc", "gender_code", 
                  "gendnc_code", "lgbt")

# Remove dups
remove(dups)

###################################################################
######################## IMPORT RACE ##############################
###################################################################

# Import ethnicity data
race <- read_csv("ripa_race_datasd.csv", 
                 col_types = cols(stop_id = col_character()))
## Row count == 431,635

# Create column for merge
race$id <- paste0(race$stop_id, "_", race$pid)

# Rearrange
race <- race %>%
  select(id, everything())

# Remove original stop_id and pid columns to avoid duplicate columns in merge
race <- race %>% 
  select(-stop_id, -pid)

# Check for duplicates
n_distinct(race$id)
# 427,350
## df contains duplicate rows

# Multiple races can be assigned to one person. They're all in multiple rows
## Aggregate rows based on the id and collapse races into one cell
race = aggregate(race~id, data = race, paste, collapse="|")
## New row count == 427,350

###################################################################
###################### IMPORT DISABILITY ##########################
###################################################################

# Import disability data
dis <- read_csv("ripa_disability_datasd.csv", 
                col_types = cols(stop_id = col_character()))
## Row count == 429,121

# Create column for merge
dis$id <- paste0(dis$stop_id, "_", dis$pid)

# Rearrange
dis <- dis %>%
  select(id, everything())

# Remove original stop_id and pid columns to avoid dups in merge
dis <- dis %>% 
  select(-stop_id, -pid)

# Check for duplicates
n_distinct(dis$id)
# 427,350
## df contains duplicate rows

# There can be multiple disabilities listed for each person
## Aggregate rows based on the id and collapse disabilities into one cell
dis <- aggregate(disability~id, data = dis, paste, collapse="|")
## Row count == 427,350

###################################################################
######################## IMPORT REASON ############################
###################################################################

# Import stop reasons data
reason <- read_csv("ripa_stop_reason_datasd.csv", 
                   col_types = cols(reason_for_stopcode = col_character(), 
                                    stop_id = col_character()))
## Row count == 440,333

# Create column for merge
reason$id <- paste0(reason$stop_id, "_", reason$pid)

# Rearrange
reason <- reason %>%
  select(id, everything())

# Remove original stop_id and pid columns to avoid dups in merge
reason <- reason %>% 
  select(-stop_id, -pid)

# Check for duplicates
n_distinct(reason$id)
# 427,350
## df contains duplicate rows

# There are duplicates due to multiple reason_for_stop_detail entries
## Aggregate rows based on the id and collapse reason_for_stop_detail into one cell
reason2 <- reason %>% 
  group_by(id) %>%
  summarise(reason_for_stop_detail = paste(reason_for_stop_detail, collapse = "|"))

# Manual inspection found no other columns with multiple (different) entries
## Keep only distinct rows for each id in reason to merge with reason2
reason3 <- reason[!duplicated(reason$id),]

# Remove reason_for_stop_detail from reason3 to avoid duplicate columns in merge
reason3 <- reason3 %>% 
  select(-reason_for_stop_detail)

# Left_join reason2 and reason3
reason_final <- left_join(reason2, reason3, by = "id")

# Rearrange
reason_final <- reason_final %>%
  select(id, reason_for_stop, reason_for_stopcode, 
         reason_for_stop_code_text, reason_for_stop_detail, 
         reason_for_stop_explanation)

remove(reason, reason2, reason3)

# Simplify column names
names(reason_final)
names(reason_final) <- c("id", "reason_words", "reasonid", "reason_text", 
                         "reason_detail", "reason_exp")

###################################################################
###################### IMPORT SEARCH BASIS ########################
###################################################################

# Import search basis
search_basis <- read_csv("ripa_search_basis_datasd.csv", 
                         col_types = cols(stop_id = col_character()))
## Row count == 439,708

# Create column for merge
search_basis$id <- paste0(search_basis$stop_id, "_", search_basis$pid)

# Rearrange
search_basis <- search_basis %>%
  select(id, everything())

# Remove original stop_id and pid columns to avoid dups in merge
search_basis <- search_basis %>% 
  select(-stop_id, -pid)

# Check for duplicates
n_distinct(search_basis$id)
# 427,350
## df contains duplicate rows

# There can be multiple search bases listed for each person
## Aggregate rows based on the id and collapse bases into one cell
search_basis2 <- search_basis %>% 
  group_by(id) %>%
  summarise(basis_for_search = paste(basis_for_search, collapse = "|"))

# Manual inspection found no other columns with multiple (different) entries
## Keep only distinct rows for each id to merge with search_basis2
search_basis3 <- search_basis[!duplicated(search_basis$id),]

# Remove orig basis_for_search column
search_basis3 <- search_basis3 %>% 
  select(-basis_for_search)

# Left_join
search_basis_final <- left_join(search_basis2, search_basis3, by = "id")

remove(search_basis, search_basis2, search_basis3)

# Simplify column names
names(search_basis_final)
names(search_basis_final) <- c("id", "search_basis", "search_basis_exp")

###################################################################
###################### IMPORT SEIZE BASIS #########################
###################################################################

# Import seize basis
seize_basis <- read_csv("ripa_prop_seize_basis_datasd.csv", 
                        col_types = cols(stop_id = col_character()))
## Row count == 430,187

# Create column for merge
seize_basis$id <- paste0(seize_basis$stop_id, "_", seize_basis$pid)

# Rearrange
seize_basis <- seize_basis %>%
  select(id, everything())

# Remove original stop_id and pid columns to avoid dups in merge
seize_basis <- seize_basis %>% 
  select(-stop_id, -pid)

# Check for duplicates
n_distinct(seize_basis$id)
# 427,350
## df contains duplicate rows

# There can be multiple seize bases listed for each person
## Aggregate rows based on the id and collapse bases into one cell
seize_basis <- seize_basis %>% 
  group_by(id) %>%
  summarise(basisforpropertyseizure = paste(basisforpropertyseizure, collapse = "|"))

# Simplify column names
names(seize_basis) <- c("id", "seiz_basis")

###################################################################
####################### IMPORT PROP TYPE ##########################
###################################################################

# Import property seized type
prop_type <- read_csv("ripa_prop_seize_type_datasd.csv", 
                      col_types = cols(stop_id = col_character()))
## Row count == 432,206

# Create column for merge
prop_type$id <- paste0(prop_type$stop_id, "_", prop_type$pid)

# Rearrange
prop_type <- prop_type %>%
  select(id, everything())

# Remove original stop_id and pid columns to avoid dups in merge
prop_type <- prop_type %>% 
  select(-stop_id, -pid)

# Check for duplicates
n_distinct(prop_type$id)
# 427,350
## df contains duplicate rows

# There can be multiple property types listed for each person
## Aggregate rows based on the id and collapse types into one cell
prop_type <- prop_type %>% 
  group_by(id) %>%
  summarise(type_of_property_seized = paste(type_of_property_seized, collapse = "|"))

# Simplify column names
names(prop_type) <- c("id", "prop_type")

###################################################################
####################### IMPORT CONTRABAND #########################
###################################################################

# Import contraband / evidence
cont <- read_csv("ripa_contraband_evid_datasd.csv", 
                 col_types = cols(stop_id = col_character()))
## Row count == 438,460

# Create column for merge
cont$id <- paste0(cont$stop_id, "_", cont$pid)

# Rearrange
cont <- cont %>%
  select(id, everything())

# Remove original stop_id and pid columns to avoid dups in merge
cont <- cont %>% 
  select(-stop_id, -pid)

# Check for duplicates
n_distinct(cont$id)
# 427,350
## df contains duplicate rows

# There can be multiple contrabands listed for each person
## Aggregate rows based on the id and collapse contrabands into one cell
cont <- cont %>% 
  group_by(id) %>%
  summarise(contraband = paste(contraband, collapse = "|"))

# Simplify column names
names(cont) <- c("id", "cont")

###################################################################
######################### IMPORT ACTIONS ##########################
###################################################################

# Import actions taken
actions <- read_csv("ripa_actions_taken_datasd.csv", 
                    col_types = cols(consented = col_character(), 
                                     stop_id = col_character()))
## Row count == 661,011

# Create column for merge
actions$id <- paste0(actions$stop_id, "_", actions$pid)

# Rearrange
actions <- actions %>%
  select(id, everything())

# Remove original stop_id and pid columns to avoid dups in merge
actions <- actions %>% 
  select(-stop_id, -pid)

# Check for duplicates
n_distinct(actions$id)
# 427,350
## df contains duplicate rows

# There can be multiple actions taken for each person
## Aggregate rows based on the id and collapse actions into one cell
actions2 <- actions %>% 
  group_by(id) %>%
  summarise(actions = paste(action, collapse = "|"))

# There's Y or N for consent of each action 
## Aggregate rows based on the id and collapse consents into one cell
actions3 <- actions %>%
  group_by(id) %>%
  summarise(consented = paste(consented, collapse = "|"))

# Left_join actions2 and actions3
actions_final <- left_join(actions2, actions3, by = "id")

remove(actions, actions2, actions3)

# Simplify column names
names(actions_final) <- c("id", "actions", "act_consent")

###################################################################
########################### MERGE #################################
###################################################################

# Merge dfs
## Skip actions, not necessary for VOD test
library(plyr)
master <- join_all(list(stops, race, dis, reason_final, search_basis_final, 
                        seize_basis, prop_type, cont), 
                   by = "id", 
                   type = "left")
## Row count should == 427,335 (stops row count)
## 42 columns total

# Unload plyr, to avoid masking with dplyr
detach("package:plyr", unload=TRUE)

# Remove originals to clean environment (optional)
remove(actions_final, cont, dis, prop_type, race, reason_final, search_basis_final, seize_basis, stops)

###################################################################
########################### CLEAN #################################
###################################################################

# Remove leading and trailing whitespace
library(stringr)
master <- master %>% 
  mutate_if(is.character, str_trim)

# Remove all types of whitespace inside strings
master <- master %>% 
  mutate_if(is.character, str_squish)

# Remove floating commas
master$reason_exp <- gsub(" , ", ", ", master$reason_exp)
master$search_basis_exp <- gsub(" , ", ", ", master$search_basis_exp)

## Count number of characters in time string
library(stringi)
master$count <- nchar(stri_escape_unicode(master$time))

table(master$count)
#      8     19 
#   427312   23 

# 23 times have incorrect dates attached
## Remove date strings from time
master$time <- gsub("1900-01-01 ", "", master$time)
master$time <- gsub("1899-12-30 ", "", master$time)

# Create second time column that's in time format
library(chron)
master$time2 <- times(master$time)

# Unload chron, to avoid masking with lubridate
detach("package:chron", unload=TRUE)

# Remove count column
master <- master %>% 
  select(-count)

# Filter to traffic violations
final <- master %>% 
  filter(reason_words == "Traffic Violation")
## Row count == 180,918

###################################################################
#################### GET LAT AND LONGS ############################
###################################################################

# Import city lat and long coordinates data
cities <- read_delim("cities500.txt", 
                     "\t", escape_double = FALSE,
                     col_types = cols(X14 = col_character(),
                                      X13 = col_character()),
                     col_names = FALSE, 
                     trim_ws = TRUE)

# Name columns
names(cities) <- c("geonameid", "name", "asciiname", "alternatenames", 
                   "lat", "long", "feature_class", "feature_code", 
                   "country_code", "cc2", "fips", "county", "code1",
                   "code2", "pop", "elev", "dem",
                   "time_zone", "mod_date")

# Filter to US / CA / SD County
cities <- cities %>% 
  filter(country_code == "US" &
           fips == "CA" &
           county == "073")

# Select columns we need
cities <- cities %>% 
  select(geonameid, name, lat, long)

# Import list of smaller cities, collected manually
extra_cities <- read_csv("extra-cities-lat-long.csv")

# Bind two city dfs
cities_final <- rbind(cities, extra_cities)
remove(cities, extra_cities)

# Make city names uppercase for merge
cities_final$name <- toupper(cities_final$name)

# Rename column for merge
cities_final <- rename(cities_final, city = name)

# Remove leading and trailing whitespace
cities_final <- cities_final %>% 
  mutate_if(is.character, str_trim)

# Remove all types of whitespace inside strings
cities_final <- cities_final %>% 
  mutate_if(is.character, str_squish)

# Join final and cities_final
final <- left_join(final, cities_final, by = "city")

# Remove cities_final (optional)
remove(cities_final)

###################################################################
####################### CLEAN RACE ################################
###################################################################

# Create simplified column for race, written out
final <- final %>% 
  mutate(race_simp = str_replace_all(race, "White", "white") %>% 
           str_replace_all("Pacific Islander", "pi") %>% 
           str_replace_all("Native American", "nam") %>% 
           str_replace_all("Middle Eastern or South Asian", "me_sa") %>% 
           str_replace_all("Hispanic/Latino/a", "hisp") %>% 
           str_replace_all("Black/African American", "black") %>% 
           str_replace_all("Asian", "asian"))

# Create new race category for vod test
## Hispanic + other race == "hisp"
## More than one race (but not hisp) == "mixed"
final <- final %>% 
  mutate(race_condensed = case_when(str_detect(race_simp, "hisp") ~ "hisp", # if contains "hisp", add to Hispanic category
                                    str_detect(race_simp, "\\|") ~ "mixed", # if contains "|", create mixed category
                                    TRUE ~ race_simp)) # if neither above is true, paste original from race_words

###################################################################
######################### VOD 2019 PREP ###########################
###################################################################

# Time frame of data
min(final$date)
# 2018-07-01
max(final$date)
# 2020-12-31

# Filter to stops in 2019
### New row count == 75,320
library(lubridate)
final19 <- final %>% 
  filter(year(date) == 2019)

# Set lubridate time zone
tz <- "America/Los_Angeles"

# Create tables of SD County center_lat and center_long
center_lat <- 33.02573574851674
center_lng <- -116.74773330323929

# Time helper function
time_to_minute <- function(time) {
  hour(hms(time)) * 60 + minute(hms(time))
}

library(suncalc)
# Compute sunset time for each date in final19 dataset
sunset_times19 <- 
  final19 %>%
  mutate(
    lat = center_lat,
    lon = center_lng
  ) %>% 
  select(date, lat, lon) %>%
  distinct() %>%
  getSunlightTimes(
    data = ., 
    keep = c("sunset", "dusk"), 
    tz = tz
  ) %>% 
  mutate_at(vars("sunset", "dusk"), ~format(., "%H:%M:%S")) %>% 
  mutate(
    sunset_minute = time_to_minute(sunset),
    dusk_minute = time_to_minute(dusk),
    date = ymd(str_sub(date, 1, 10))) %>% 
  select(date, sunset, dusk, ends_with("minute"))

# Determine inter-twilight period
sunset_times19 %>% 
  filter(dusk == min(dusk) | dusk == max(dusk))
#     date    sunset     dusk     sunset_minute dusk_minute
# 2019-06-28 20:00:53 20:29:35          1200        1229
# 2019-06-29 20:00:55 20:29:35          1200        1229
# 2019-12-03 16:41:28 17:08:31          1001        1028
# 2019-12-04 16:41:26 17:08:31          1001        1028

###################################################################
######################## VOD ANALYSIS #############################
###################################################################

# Merge sunset_times19 with final19
## Create TRUE/FLASE columns for race (to be used in glm tests)
all19 <- 
  final19 %>% 
  left_join(
    sunset_times19,
    by = "date"
  ) %>% 
  mutate(
    minute = time_to_minute(time),
    minutes_after_dark = minute - dusk_minute,
    is_dark = minute > dusk_minute,
    min_dusk_minute = min(dusk_minute),
    max_dusk_minute = max(dusk_minute),
    is_white = race_condensed == "white",
    is_hisp = race_condensed == "hisp",
    is_black = race_condensed == "black",
    is_asian = race_condensed == "asian",
    is_me_sa = race_condensed == "me_sa",
    is_pi = race_condensed == "pi",
    is_nam = race_condensed == "nam",
    is_mixed = race_condensed == "mixed",
  )

# Filter to the inter-twilight period;
## Remove ambiguous pre-dusk period;
### Row count == 10,396
it19 <- all19 %>% 
  filter(
    # Filter to get only the inter-twilight period
    minute >= min_dusk_minute,
    minute <= max_dusk_minute,
    # Remove ambiguous period between sunset and dusk
    !(minute > sunset_minute & minute < dusk_minute)
  )

# Compute proportion of stops by race when it was dark vs proportion when it was light
it19 %>% 
  group_by(is_dark) %>% 
  summarise(prop_white = mean(is_white)*100,
            prop_hisp = mean(is_hisp)*100,
            prop_black = mean(is_black)*100,
            prop_asian = mean(is_asian)*100,
            prop_me_sa = mean(is_me_sa)*100,
            prop_pi = mean(is_pi)*100,
            prop_nam = mean(is_nam)*100,
            prop_mixed = mean(is_mixed)*100)

# is_dark prop_white prop_hisp prop_black prop_asian prop_me_sa prop_pi prop_nam prop_mixed
# FALSE         34.2      36.0       17.2       7.74       3.52   0.888    0.117      0.369
# TRUE          31.9      37.7       17.3       8.02       3.84   0.903    0.158      0.181

###################################################################
######################## VOD 2019 LOG REG #########################
###################################################################

# Hispanic glm test
mixed_test <- glm(
  is_mixed ~ is_dark + splines::ns(minute, df = 6),
  family = binomial,
  data = it19
)

summary(mixed_test)$coefficients["is_darkTRUE", c("Estimate", "Std. Error")]
# Estimate   Std. Error 
# -1.0924696  0.5142196

summary(mixed_test)
# p value = 0.0336
## Not significant

###################################################################
################## FURTHER ANALYSIS OF STOPS ######################
###################################################################

# Calculate percent of race in all stops (July 2018 through June 2020)
final %>% 
  group_by(race_condensed) %>% 
  summarise(total = n()) %>% 
  mutate(per_total = round((total / sum(total))*100,1)) %>% 
  arrange(desc(per_total))

# race_condensed total per_total
# white          66946      37  
# hisp           61929      34.2
# black          28702      15.9
# asian          13232       7.3
# me_sa           7623       4.2
# pi              1577       0.9
# mixed            724       0.4
# nam              185       0.1

# Calculate percent of race of 2019 stops
final19 %>% 
  group_by(race_condensed) %>% 
  summarise(total = n()) %>% 
  mutate(per_total = round((total / sum(total))*100,1)) %>% 
  arrange(desc(per_total))

# race_condensed total per_total
# white          27693      36.8
# hisp           25918      34.4
# black          11763      15.6
# asian           5742       7.6
# me_sa           3228       4.3
# pi               633       0.8
# mixed            265       0.4
# nam               78       0.1

######################################################################
# Percent of stops by day and by night in 2019
all19 %>% 
  group_by(is_dark) %>% 
  summarise(total = n()) %>% 
  mutate(per_total = round((total / sum(total))*100,1))

# is_dark  total per_total
# FALSE   57554      76.4
# TRUE    17766      23.6

# Percent of stops by day and night in 2019
## During inter-twilight period
it19 %>% 
  group_by(is_dark) %>% 
  summarise(total = n()) %>% 
  mutate(per_total = round((total / sum(total))*100,1))

# is_dark total per_total
# FALSE    5967      57.4
# TRUE     4429      42.6

######################################################################
# Percent of stops for each race that occurred during day and night
## 2019 stops
race_dn <- all19 %>% 
  group_by(race_condensed, is_dark) %>% 
  summarise(total = n())

# Spread
library(tidyr)
race_dn <- race_dn %>%
  spread(key = is_dark, value = total, fill = 0)

# Rename columns
names(race_dn) <- c("race_condensed", "day", "night")

# Add percentages
race_dn %>%
  mutate(day_per = round((day / (day + night))*100,1),
         night_per = round((night / (day + night))*100,1)) %>% 
  arrange(desc(day_per))

# race_condensed   day night day_per night_per
# mixed            217    48    81.9      18.1
# white          21935  5758    79.2      20.8
# pi               494   139    78        22  
# nam               59    19    75.6      24.4
# hisp           19536  6382    75.4      24.6
# me_sa           2423   805    75.1      24.9
# black           8701  3062    74        26  
# asian           4189  1553    73        27

# Percent of stops for each race that occurred during day and night
## 2019 stops
## Inter-twilight period
race_dn_it <- it19 %>% 
  group_by(race_condensed, is_dark) %>% 
  summarise(total = n())

# Spread
race_dn_it <- race_dn_it %>%
  spread(key = is_dark, value = total, fill = 0)

# Rename columns
names(race_dn_it) <- c("race_condensed", "day", "night")

# Add percentages
race_dn_it %>%
  mutate(day_per = round((day / (day + night))*100,1),
         night_per = round((night / (day + night))*100,1))

# race_condensed   day night day_per night_per
# asian            462   355    56.5      43.5
# black           1029   766    57.3      42.7
# hisp            2146  1669    56.3      43.7
# me_sa            210   170    55.3      44.7
# mixed             22     8    73.3      26.7
# nam                7     7    50        50  
# pi                53    40    57        43  
# white           2038  1414    59        41

######################################################################
# Total number of "stops" vs individuals (based on stop ID) in 2019
stops19 <- final19 %>% 
  group_by(stop_id) %>%
  summarise(total = n())
## Stops == 70,805
## vs Individuals == 75,320
