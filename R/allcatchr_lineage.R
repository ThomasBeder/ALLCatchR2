globalVariables(c("test_data","models_TALL_BC"))

#' @title Classifiction
#'
#' @description Prediction of B-ALL leukemia subtypes based on expression data
#' @export
#'
#' @param Lineage B-ALL or T-ALL
#' @param Counts.file count data
#' @param ID_class gene ids
#' @param sep file seperator
#' @param out.file output file name
#' @return data.frame containing class predictions
#' @examples
#' allcatchr_lineage()
#'

allcatchr_lineage <- function(Counts.file=NULL, ID_class="symbol", sep="\t", out.file=paste0(getwd(),"/predictions.tsv")) {
  # Namespace from packages needed for prediction function using pre-trainted models
  loadNamespace("kknn")
  loadNamespace("ranger")
  loadNamespace("randomForest")
  loadNamespace("LiblineaR")
  loadNamespace("glmnet")
  loadNamespace("elasticnet")  
  
    
  ##############################################################################################
  # inculde T-ALL subtype classifier and ssGSEA to healhty T cell development ##################
  ##############################################################################################
   #loadNamespace("caret")
    # 1. preprocessing ############################################################
    # load count data, where the first column should be gene identifiers
   if(is.null(Counts.file)){
    Counts <- test_data
    cat("test counts loaded...\n")
   } else if (is.data.frame(Counts.file)) {
    Counts <- Counts.file
    cat("counts loaded...\n")
    }else{
    Counts <- utils::read.csv(Counts.file, sep = sep, stringsAsFactors = F, row.names = 1)
    cat("counts loaded...\n")
  }
    
    if (length(rownames(Counts)) == length(which(rownames(Counts) == as.character(1:nrow(Counts))))) {
      stop("Error: symbol, ensemble or entrez are not provided in the first column")
    }
    ID_conv <- ID_conversion_TALL_subtype
    # select the genes used for classifier trainig
    ma <- match(ID_conv[,match(ID_class, colnames(ID_conv))], rownames(Counts))
    Counts <- Counts[ma[!is.na(ma)],,drop = F]
    
    # convert to symbol (classifier was trained on symbols)
    ma <- match(rownames(Counts), ID_conv[,match(ID_class, colnames(ID_conv))])
    Counts <- Counts[!is.na(ma),,drop = F]
    ma <- match(rownames(Counts), ID_conv[,match(ID_class, colnames(ID_conv))])
    rownames(Counts) <- ID_conv$symbol[ma]
    
    # normalize data and scale between 0 and 1
    Counts.norm <- Counts+1
    Counts.norm <- apply(Counts.norm, 2, log10)
    Counts.norm <- apply(Counts.norm, 2, scale)
  
    # transpose data
    Counts.norm <- as.data.frame(t(Counts.norm))
    colnames(Counts.norm) <- rownames(Counts)
    colnames(Counts.norm) <- colnames(Counts.norm)
    
    # find genes not provided by user
    ma <- match(ID_conv$symbol, rownames(Counts))
    GenesNoFound <- ID_conv$symbol[is.na(ma)]
    
    # Print number of missing genes
    cat(paste0(length(GenesNoFound)), " of ", nrow(ID_conv), " genes not found\n")
    if ((length(GenesNoFound)) > 0) {
      cat("impute missing genes...\n")
    }
    
    # impute missing genes
    GenesNoFound_df <- matrix(ID_conv$norm_exp[match(GenesNoFound, ID_conv$symbol)], nrow = nrow(Counts.norm), ncol = length(GenesNoFound))
    colnames(GenesNoFound_df) <- GenesNoFound
    Counts.norm <- cbind(Counts.norm, GenesNoFound_df)
    
    ################### predict all samples ########################################
    output <- "test"
                                                                           
    ################################################################################
    ###### finalize output table ###################################################
    ################################################################################
                                                                           
    output <- as.data.frame(cbind(output))
    
    cat("predictions saved in:", getwd(),"\n")
    # save predictions
    cat("Writing output file:",paste0(out.file),"...\n")
    utils::write.table(output,out.file, sep = sep, row.names = F)
    return(output)

}

