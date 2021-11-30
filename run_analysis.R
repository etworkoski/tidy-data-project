### Program Title: run_analysis.R
### Description: Create two tidy data frames from smartphone accelerometer and gyroscope
###  data. Read in and combine test and training datasets, append additional descriptive 
###  information, and produce additional summary dataset.

# Load packages
library(dplyr)
library(tibble)

## Read in reference data tables for activity and feature numbers/descriptions
activity_list <- read.table(file = "./data/activity_labels.txt") # table mapping numeric activity labels to descriptive names
activity_list <- activity_list %>% rename(activity_num = V1, activity_name = V2) #rename vars in activity list
feature_list <- read.table(file = "./data/features.txt") # table mapping numeric feature labels to descriptive names

## Read in TEST data, labels, and subject numbers
## Note that we are not reading in the raw time-series inertial data, but instead
## a 561-feature vector with time and frequency domain variables created from processing the raw data
test_data <- read.table(file = "./data/test/X_test.txt")  # feature vector data
test_label <- read.table(file = "./data/test/y_test.txt") # numeric activity labels
test_subject <- read.table(file = "./data/test/subject_test.txt") # subject labels

# Append subject and activity number columns to test data
test_df <- test_data %>% add_column(subject_num = test_subject$V1, activity_num = test_label$V1, .before = "V1")

## Read in TRAINING data, labels, and subject numbers
train_data <- read.table(file = "./data/train/X_train.txt")  # feature vector data
train_label <- read.table(file = "./data/train/y_train.txt") # numeric activity labels
train_subject <- read.table(file = "./data/train/subject_train.txt") # subject labels

# Append subject and activity number columns to training data
train_df <- train_data %>% add_column(subject_num = train_subject$V1, activity_num = train_label$V1, .before = "V1")

## Create a single tidy data frame that combines test and training data,
## and subset to features related to mean and std.
all_df <- rbind(train_df, test_df) #combine test and train data
mean_std_features <- subset(feature_list, grepl("[Mm]ean()|[Ss]td()", feature_list$V2)) #identify the numbers of features corresponding to mean or std
mean_std_features$V1 <- paste0("V",mean_std_features$V1) #modify the selected numbers so that they match the colnames in the all_df dataframe and can be used to subset that df
all_df_sub <- subset(all_df, select = c("subject_num", "activity_num", mean_std_features$V1)) #select the subset of columns in the all_df that have the subject/activity number or a mean or std feature

# Add descriptive column names to all identified features
old_colnames <- colnames(all_df_sub[,-1:-2]) #extract colnames for the selected feature columns- all cols except subject and activity num
new_colnames <- mean_std_features$V2 #extract new column names from the feature list
all_df_sub <- all_df_sub %>% rename_with(~new_colnames[which(old_colnames == .x)], .cols=old_colnames) #rename old feature colnames (V1, V2, etc.) with new descriptive feature colnames

## GENERATE FINAL TIDY DATASET #1
# Add descriptive names for activity numbers
tidy_dataset_1 <- left_join(all_df_sub, activity_list, by = "activity_num") #Add on an activity name column - note that a left join is used to preserve all data in case of missing activity numbers although initial investigations did not find evidence of this issue
tidy_dataset_1 <- tidy_dataset_1[,c(1,2,89,3:88)] #reorders columns so that activity number and name are next to each other
write.table(tidy_dataset_1, "tidy_dataset_1.txt", row.names=FALSE)

## GENERATE FINAL TIDY DATASET #2
tidy_dataset_2 <- aggregate(tidy_dataset_1[,4:89], list(subject_num=tidy_dataset_1$subject_num, activity_num=tidy_dataset_1$activity_num, activity_name=tidy_dataset_1$activity_name), mean) #calculate mean of all feature columns, grouped by subject number, activity number, and activity name
write.table(tidy_dataset_2, "tidy_dataset_2.txt", row.names = FALSE)