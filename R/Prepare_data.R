options(scipen = 999) # JSON numerics format
options(stringsAsFactors = FALSE)
library(tidyverse)
library(lubridate)
library(jsonlite)
library(openxlsx)

Get_Data_From_DIP <- function(dana = 7){
    popis_obveznika_json_url <- "https://www.izbori.hr/eup2019/financ/data/obveznik.json"
    # procitaj json
    sif_obveznici <- fromJSON(popis_obveznika_json_url) 
    # preimenuj
    sif_obveznici <- sif_obveznici %>% as_tibble() %>% rename(
        obveznik_id = value,
        naziv = label
    )
    
    dp_template_url <- paste0("https://www.izbori.hr/eup2019/financ/data/#obveznik_id#/IZ-DP_",dana,"_dana.json")
    tp_template_url <- paste0("https://www.izbori.hr/eup2019/financ/data/#obveznik_id#/IZ-TP_",dana,"_dana.json")
    mo_template_url <- paste0("https://www.izbori.hr/eup2019/financ/data/#obveznik_id#/IZ-MO_",dana,"_dana.json")
    
    dp_report_list <- list()
    tp_report_list <- list()
    mo_report_list <- list()
    
    for (i in 1:nrow(sif_obveznici)) {
        
        o <- sif_obveznici[i,]
        
        print(paste("čitam podatke za:", o$naziv))
        
        # build url
        dp_url <- str_replace(string = dp_template_url, pattern = '#obveznik_id#', o$obveznik_id)
        tp_url <- str_replace(string = tp_template_url, pattern = '#obveznik_id#', o$obveznik_id)
        mo_url <- str_replace(string = mo_template_url, pattern = '#obveznik_id#', o$obveznik_id)
        
        tryCatch({
            
            # get data
            dp_data <- fromJSON(dp_url)
            tp_data <- fromJSON(tp_url)
            mo_data <- fromJSON(mo_url)
            
            # add obveznik_id to list
            dp_data$obveznik_id <- o$obveznik_id
            tp_data$obveznik_id <- o$obveznik_id
            mo_data$obveznik_id <- o$obveznik_id
            
            # add to global list
            dp_report_list[[i]] <- dp_data
            tp_report_list[[i]] <- tp_data
            mo_report_list[[i]] <- mo_data
            
        }, warning = function(warning_condition) {
            print(warning_condition)
        }, error = function(error_condition) {
            print(error_condition)
        }, finally={
            # cleanup-code
        })
        
    }
    
    return(list(
        dp_reports = dp_report_list,
        tp_reports = tp_report_list,
        mo_reports = mo_report_list,
        sif_obveznici = sif_obveznici
    ))
}

Obradi_Podatke <- function(report_lists){
    
    # IZVJEŠĆE O PRIMLJENIM DONACIJAMA ZA FINANCIRANJE IZBORNE PROMIDŽBE -- dp
    dp_report_tbl <- tibble()
    dp_data_tbl <- tibble()
    
    for (i in 1:length(report_lists$dp_reports)) {
        
        r <- report_lists$dp_reports[[i]]
        
        # dodaj naziv stranke u tablicu za povezivanje s razinom reporta
        r_data <- r$data %>% as_tibble() %>% mutate(obveznik_id = r$obveznik_id)
        # ukloni tablicu i pretvori ostale atribute u data.frame razine reporta
        r$data <- NULL
        r_report <- r %>% as_tibble()
        
        dp_report_tbl <- rbind(dp_report_tbl, r_report)
        dp_data_tbl <- rbind(dp_data_tbl, r_data)
    }
    
    # IZVJEŠĆE O TROŠKOVIMA (RASHODIMA) IZBORNE PROMIDŽBE                -- tp
    tp_report_tbl <- tibble()
    tp_data_tbl <- tibble()
    
    for (i in 1:length(report_lists$tp_reports)) {
        
        r <- report_lists$tp_reports[[i]]
        
        # dodaj naziv stranke u tablicu za povezivanje s razinom reporta
        r_data <- r$data %>% as_tibble() %>% mutate(obveznik_id = r$obveznik_id)
        # ukloni tablicu i pretvori ostale atribute u data.frame razine reporta
        r$data <- NULL
        r_report <- r %>% as_tibble()
        
        tp_report_tbl <- rbind(tp_report_tbl, r_report)
        tp_data_tbl <- rbind(tp_data_tbl, r_data)
    }
    # IZVJEŠĆE O IZNOSU CIJENE I IZNOSU OSTVARENOG POPUSTA U CIJENI ZA MEDIJSKO OGLAŠAVANJE IZBORNE PROMIDŽBE -- mo
    mo_report_tbl <- tibble()
    mo_data_tbl <- tibble()
    
    for (i in 1:length(report_lists$mo_reports)) {
        
        r <- report_lists$mo_reports[[i]]
        
        # dodaj naziv stranke u tablicu za povezivanje s razinom reporta
        r_data <- r$data %>% as_tibble() %>% mutate(obveznik_id = r$obveznik_id)
        # ukloni tablicu i pretvori ostale atribute u data.frame razine reporta
        r$data <- NULL
        r_report <- r %>% as_tibble()
        
        mo_report_tbl <- rbind(mo_report_tbl, r_report)
        mo_data_tbl <- rbind(mo_data_tbl, r_data)
    }
    
    # definiraj kolone koje se ponavljaju u sva 3 izvjestaja
    fixed_cols <- c('obveznik_id', 'nazivStranke', 'adresaStranke', 'oibStranke', 'brojRacunaStranke')
    
    # kreiraj "dimenziju" obveznika
    dim_obveznici <- rbind(
        dp_report_tbl %>% select(fixed_cols),
        tp_report_tbl %>% select(fixed_cols),
        mo_report_tbl %>% select(fixed_cols)
    ) %>% unique() %>% inner_join(report_lists$sif_obveznici, by = 'obveznik_id') %>%
        select(-naziv)
    
    fixed_cols <- fixed_cols[-1]
    # vrati sve podatke
    return(list(
        dp_izvjestaji = dp_report_tbl %>% select(-fixed_cols),
        dp_donacije = dp_data_tbl,
        tp_izvjestaji = tp_report_tbl %>% select(-fixed_cols),
        tp_troskovi = tp_data_tbl,
        mo_izvjestaji = mo_report_tbl %>% select(-fixed_cols),
        mo_oglasavanja = mo_data_tbl,
        obveznici = dim_obveznici
    ))
}

Deploy_To_PowerBI_Dataset <- function(source_data, file_name = 'financijski_izvjestaji.RDS'){
    
    file_name = paste0('Export/', file_name)
    
    source_data %>% saveRDS(file_name)
    
    print(paste('Saved file:', file_name))
}

Convert_All_Strings_UTF8 <- function(df){
    
    for(i in which(sapply(df, class) == "character")) 
        df[[i]] = stringi::stri_encode(df[[i]], "", "UTF-8")
    return(df)
}

spremiCSV <- function(df, fileName, encoding="UTF-8", sep = ';', na ='', row.names = FALSE){
    con<-file(fileName, encoding=encoding)
    
    write.table(df, file=con, na=na, sep = sep, row.names = row.names, qmethod = "double" )
}

spremiXLSX <- function(data, fileName){
    if (is.data.frame(data)) {
        df <- data
        wb <- createWorkbook()
        addWorksheet(wb = wb, sheetName = "Sheet 1", gridLines = FALSE)
        writeDataTable(wb = wb, sheet = 1, x = df)
        saveWorkbook(wb, fileName, overwrite = TRUE)
    }
    else if (is.list(data)) {
        wb <- createWorkbook()
        for(i in 1:length(data)){
            df <- data[i]
            df_name <- names(df)
            addWorksheet(wb = wb, sheetName = df_name, gridLines = FALSE)
            writeDataTable(wb = wb, sheet = df_name, x = as_data_frame(df[[1]]))
        }
        saveWorkbook(wb, fileName, overwrite = TRUE)
    }
}
