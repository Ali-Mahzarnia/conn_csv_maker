
library(readxl)
library(dplyr)
library(RQuantLib)

path_data='Full_Cardiac_Metrics_01082024_Exercise.csv'
data=read.csv(path_data )
data = as.data.frame(data)
data = as.data.frame(t(na.omit(t(data))))

# length(unique(data$ID))
matcher_path = 'CardiacIDVsBadeaID_Zay_Edited.xls'
matcher = read_xls(matcher_path)

# sum(data$ID %in% matcher$`BadeID`) # 54 
# sum(data$ID %in% matcher$ID) # 124
# data$BadeaID = data$ID
# for (i in 1:dim(data)[1]) {
#   index = which( data$ID[i] == matcher$ID )
#   if (length(index)>0){
#   data$BadeaID[i] = matcher$`BadeID`[index]
#   }
#   else {data$BadeID[i] = NA}
# }

# write.csv(file= "zay.csv",data)
# sum(!is.na( data$BadeID))

master_path = 'MasterSheet_Experiments2021.xlsx'
master = read_xlsx(master_path, sheet = "18ABB11_readable02.22.22_BJ_Cor")

# data$Arunno =data$BadeaID 
# for (i in 1:dim(data)[1]) {
#   index = which( gsub("-","_",data$BadeaID[i]) == master$BadeaID )
#   if (length(index)>0){
#     data$Arunno[i] = master$ARunno[index]
#   }
#   else {data$Arunno[i] = NA}
# }





datatemp = master

####plains
path_connec="/Users/ali/Desktop/Mar24/fmri_all_to_batch5_conn/output_errts/"
file_list=list.files(path_connec)
plain_index = grep("errts.nii.gz", file_list)
file_list = file_list[plain_index]


results = data[0,]
colnames = colnames(results)

notfound=0
sum = 0 

for (i in 1:length(file_list)) {
  res = matrix(NA, 1, length(colnames))
  colnames(res) = colnames
  temp_index=which(datatemp$ARunno==(substr(file_list[i],1,9)))
  
  
  if (length(temp_index)>0) { 

    
    if(gsub("_","-", datatemp$CIVMID[temp_index])  %in% gsub("\\:.*","",matcher$BadeID) ) 
    {
      # {cat("here", i); sum = sum+1}
      index_matcher = which( gsub("_","-", datatemp$CIVMID[temp_index])  == matcher$BadeID)
      index_alex_al = which (matcher$ID[index_matcher] == data$ID )
      res = data[index_alex_al,]
      res$ID = datatemp$ARunno[temp_index]
      results =  rbind(results,res)
    }
      
    
    
    
    
    # 
    # genotype=datatemp$Genotype[temp_index]
    # if (grepl( "HN" , genotype )) { res$HN = 1  } else { res$`non-HN`  = 1  }
    # geno = gsub("HN", "", genotype )
    # if (geno == "APOE22" ) { res$E2 = 1 }
    # if (geno == "APOE33" ) { res$E3 = 1 }
    # if (geno == "APOE44" ) { res$E4 = 1 }
    # sex = datatemp$Sex[temp_index]
    # if (grepl( "female" , sex )   ) {res$female = 1   } else {res$male = 1 }
    # 
    # diet= datatemp$Diet[temp_index]
    # if (grepl( "HFD" , diet )   ) {res$HFD = 1   } 
    # if(grepl( "Control" , diet )   ) {res$CTRL = 1   } 
    # 
    # 
    # 
    # age= datatemp$Age_Months[temp_index]
    # 
    # # yearFraction(as.Date(datatemp$Perfusion[temp_index] ), as.Date(datatemp$DOB[temp_index] ) , dayCounters = 1)
    # res$Age = age
    # 
    # res$ All_subjects = 1
    # 
    # results = rbind(results,res)
    
  }
  
  
  # else
    # notfound=c(notfound, datatemp$ARunno[i])
  
}

# 
# notfound=notfound[2:length(notfound)]
# not_found_index=which( datatemp$ID  %in%  notfound )
# 
# datatemp=datatemp[-not_found_index,]
# 

results = as.data.frame(results)
cardiac = as.data.frame( matrix(NA,0,14 + 13 ) )
colnames(cardiac) = c("ID", "E2", "E3" , "E4", "HN", "non-HN", "KO", "male" , "female", "HFD", "CTRL", "Age", c(colnames)[10:23] ,"All_subjects")

for (i in 1:dim(results)[1]) {
  res = as.data.frame( matrix(0,1,14 +13) )
  colnames(res) = c("ID", "E2", "E3" , "E4", "HN", "non-HN", "KO", "male" , "female", "HFD", "CTRL", "Age", c(colnames)[10:23] ,"All_subjects")
  
  res$ID = results$ID[i]
  genotype=results$Genotype [i]
  if (grepl( "HN" , genotype )) { res$HN = 1  } else { res$`non-HN`  = 1  }
  geno = gsub("HN", "", genotype )
  if (geno == "E22" ) { res$E2 = 1 }
  if (geno == "E33" ) { res$E3 = 1 }
  if (geno == "E44" ) { res$E4 = 1 }
  
  sex = results$Sex [i]
  if (grepl( "Female" , sex )   ) {res$female = 1   } else {res$male = 1 }
  
  
  diet= results$Diet[i]
  if (grepl( "HFD" , diet )   ) {res$HFD = 1   }
  if(grepl( "Control" , diet )   ) {res$CTRL = 1   }
  
  
  res$Age = results$Age[i]
  
  res[13:27] = results[i,10:23]
  
  res$ All_subjects = 1
  
  cardiac = rbind(cardiac,res)
  
}


write.csv(cardiac, paste0("con_for_cardiac_",dim(cardiac)[1] ,".csv"), row.names=FALSE)
