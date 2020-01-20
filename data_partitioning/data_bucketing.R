# args[1] - Filepath were the "sample_table.csv", "tel_aviv_neighborhood.csv" and "clean_data.R" are located
# args[2] - Filename "sample_table.csv"
# args[3] - Filename "tel_aviv_neighborhood.csv"
args <- commandArgs(trailingOnly = TRUE)

#Since the data is too big to work at once we will be splitting into 10 parts to clean and further join the data.
input_filepath = args[1]
input_filename = args[2]
neighborhood_filename = args[3]

full_data <- read.csv(paste0(input_filepath,input_filename))

n <- 10
nr <- nrow(full_data)
dfs<- split(full_data, rep(1:10, each=ceiling(nr/n), length.out=nr))

# Creating Directory for the partitioning of the sample_table data
sample_parts_filepath = paste0(input_filepath,"sample_parts/")
system(paste("mkdir",paste0('"',sample_parts_filepath,'"')))

# Creating directory for clean data for all of the paritioned data
clean_parts_filepath = paste0(input_filepath,"clean_parts/")
system(paste("mkdir",paste0('"',clean_parts_filepath,'"')))


# Splitting sample_table data and writing csv files in sample_parts_filepath directory
lapply(names(dfs),
       function(x){write.csv(dfs[[x]], paste0(sample_parts_filepath,x,".csv"),
                             row.names = FALSE)})

system_clean_data_cmd <- paste("Rscript.exe",paste0('"',input_filepath,"clean_data.R",'"'))
# Applying data cleaning and manipulation to each data part created
for (file in list.files(sample_parts_filepath)){
  clean_parts_filename = paste0("clean_part_",file)
  args1 <- paste0('"',sample_parts_filepath,file,'"')
  args2 <- paste0('"',input_filepath, neighborhood_filename,'"')
  args3 <- paste0('"',clean_parts_filepath,clean_parts_filename,'"')
  system(paste(system_clean_data_cmd, args1, args2, args3))
}