# Load Packages and get the Data
packages <- c("data.table", "reshape2")
sapply(packages, require, character.only=TRUE, quietly=TRUE)
path <- getwd()
url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
download.file(url, file.path(path, "dataFiles.zip"))
unzip(zipfile = "dataFiles.zip")

# Load activity labels and features
activity_labels <- fread(file.path(path, "UCI HAR Dataset/activity_labels.txt")
                        , col.names = c("class_labels", "activity_names"))
features <- fread(file.path(path, "UCI HAR Dataset/features.txt")
                  , col.names = c("index", "feature_names"))
features_desired <- grep("(mean|std)\\(\\)", features[, feature_names])
measurements <- features[features_desired, feature_names]
measurements <- gsub('[()]', '', measurements)

# Load train datasets
train <- fread(file.path(path, "UCI HAR Dataset/train/X_train.txt"))[, features_desired, with = FALSE]
data.table::setnames(train, colnames(train), measurements)
train_activities <- fread(file.path(path, "UCI HAR Dataset/train/Y_train.txt")
                         , col.names = c("Activity"))
train_subjects <- fread(file.path(path, "UCI HAR Dataset/train/subject_train.txt")
                       , col.names = c("SubjectNumber"))
train <- cbind(train_subjects, train_activities, train)

# Load test datasets
test <- fread(file.path(path, "UCI HAR Dataset/test/X_test.txt"))[, features_desired, with = FALSE]
data.table::setnames(test, colnames(test), measurements)
test_activities <- fread(file.path(path, "UCI HAR Dataset/test/Y_test.txt")
                        , col.names = c("Activity"))
test_subjects <- fread(file.path(path, "UCI HAR Dataset/test/subject_test.txt")
                      , col.names = c("SubjectNumber"))
test <- cbind(test_subjects, test_activities, test)

# merge datasets and add labels
combined <- rbind(train, test)

# Convert class_labels to activity_name basically.
combined[["Activity"]] <- factor(combined[, Activity]
                                 , levels = activity_labels[["class_labels"]]
                                 , labels = activity_labels[["activity_names"]])
combined[["SubjectNumber"]] <- as.factor(combined[, SubjectNumber])
combined <- reshape2::melt(data = combined, id = c("SubjectNumber", "Activity"))
combined <- reshape2::dcast(data = combined, SubjectNumber + Activity ~ variable, fun.aggregate = mean)
data.table::fwrite(x = combined, file = "data_output.csv", quote = FALSE)