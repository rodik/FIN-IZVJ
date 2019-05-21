

source('R/Prepare_data.R', encoding = 'UTF-8')

dip_data <- Get_Data_From_DIP()
clean_data <- Obradi_Podatke(dip_data)
Deploy_To_PowerBI_Dataset(clean_data)


############### PowerBI import script
# Convert_All_Strings_UTF8 <- function(df){
#     
#     for(i in which(sapply(df, class) == "character")) 
#         df[[i]] = stringi::stri_encode(df[[i]], "", "UTF-8")
#     return(df)
# }
# 
# tst <- readRDS('C:/Users/filip/Documents/R projects/FIN-IZVJ/Export/financijski_izvjestaji.RDS')
# 
# dim_obveznici <- Convert_All_Strings_UTF8(tst$obveznici)
# dp_izvjestaji <- Convert_All_Strings_UTF8(tst$dp_izvjestaji)
# dp_donacije <- Convert_All_Strings_UTF8(tst$dp_donacije)
# tp_izvjestaji <- Convert_All_Strings_UTF8(tst$tp_izvjestaji)
# tp_troskovi <- Convert_All_Strings_UTF8(tst$tp_troskovi)
# mo_izvjestaji <- Convert_All_Strings_UTF8(tst$mo_izvjestaji)
# mo_oglasavanja <- Convert_All_Strings_UTF8(tst$mo_oglasavanja)


############### Export
# spremiCSV(clean_data$obveznici, fileName = 'Export/dim_obveznici.CSV')
# spremiCSV(clean_data$dp_izvjestaji, fileName = 'Export/dp_izvjestaji.CSV')
# spremiCSV(clean_data$dp_donacije, fileName = 'Export/dp_donacije.CSV')
# spremiCSV(clean_data$tp_izvjestaji, fileName = 'Export/tp_izvjestaji.CSV')
# spremiCSV(clean_data$tp_troskovi, fileName = 'Export/tp_troskovi.CSV')
# spremiCSV(clean_data$mo_izvjestaji, fileName = 'Export/mo_izvjestaji.CSV')
# spremiCSV(clean_data$mo_oglasavanja, fileName = 'Export/mo_oglasavanja.CSV')
