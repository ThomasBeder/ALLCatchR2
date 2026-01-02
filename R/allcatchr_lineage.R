globalVariables(c("test_data","models_L_Lineage"))

#' @title Classifiction
#'
#' @description Prediction of B-ALL or T-ALL based on expression data
#' @export
#'
#' @param Counts.file count data
#' @param ID_class gene ids
#' @param sep file seperator
#' @param out.file output file name
#' @return data.frame containing class predictions
#' @examples
#' allcatchr_lineage()
#'

allcatchr_lineage <- function(Counts.file=NULL, ID_class="symbol", sep="\t", out.file=paste0(getwd(),"/Lineage_predictions.tsv")) {
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
    Counts <- utils::read.csv(Counts.file, sep = sep, stringsAsFactors = F, row.names = 1, check.names = F)
    cat("counts loaded...\n")
  }
  
  if (length(rownames(Counts)) == length(which(rownames(Counts) == as.character(1:nrow(Counts))))) {
    stop("Error: symbol, ensembl or entrez are not provided in the first column")
  }
  ID_conv <- ID_conversion_Lineage
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
  Counts.norm <- apply(Counts.norm, 2, log2)
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
  
  Lineage_preds <- list()
  
  for (y in 1:length(models_L_Lineage)) {
    model <- models_L_Lineage[[y]]
    
    modelType <- c("determenistic", "determenistic", "probalistic", 
                   "probalistic",  "probalistic"#, "probalistic"
    )
    pred_ind_model <- list()
    
    for (x in 1:length(model)) {
      model_type <- modelType[x]
      if (model_type == "determenistic") {
        preds <- list()
        for (j in 1:length(model[[x]])) {
          preds[[j]] <- as.character(predict(model[[x]][[j]], newdata = Counts.norm,type = "raw"))
        }
        preds <- as.data.frame(do.call("cbind", preds))
        head(preds)
        
        preds_prob <- data.frame(matrix(0, nrow = nrow( Counts.norm),
                                        ncol = length(c(model$model_svmLinear[[1]]$levels[1],
                                                        model$model_svmLinear[[1]]$levels[2]))
        ))
        colnames(preds_prob) <- c(model$model_svmLinear[[1]]$levels[1],
                                  model$model_svmLinear[[1]]$levels[2])               
        
        for (i in 1:nrow(preds)) {
          for (j in 1:ncol(preds_prob)) {
            preds_prob[i,j] <- length(which(preds[i,] == make.names(colnames(preds_prob)[j])))/length(model[[1]])
            
          }
        }
        
        
        
      }
      
      if (model_type == "probalistic") {
        preds_prob <- list()
        for (j in 1:length(model[[x]])) {
          preds_prob[[j]] <- predict(model[[x]][[j]], newdata =Counts.norm,type = "prob")
        }
        tail(preds_prob[[j]])
        
        Means <- list()
        
        for (j in 1:ncol(preds_prob[[1]])) {
          values <-list()
          for (i in 1:length(preds_prob)) {
            values[[i]] <- preds_prob[[i]][,j]
          }
          
          Means[[j]] <-  apply(do.call("cbind", values), 1, mean)
        }
        
        preds_prob <- as.data.frame(do.call("cbind", Means))
        head(preds_prob)
        tail(preds_prob)
        colnames(preds_prob) <- sort(make.names(c(model$model_svmLinear[[1]]$levels[1],
                                                  model$model_svmLinear[[1]]$levels[2])))
      } 
      pred_ind_model[[x]] <- preds_prob
      
    }
    
    Means <- list()
    
    for (j in 1:ncol(pred_ind_model[[1]])) {
      values <-list()
      for (i in 1:length(pred_ind_model)) {
        values[[i]] <- pred_ind_model[[i]][,j]
      }
      
      Means[[j]] <-  apply(do.call("cbind", values), 1, mean)
    }
    
    
    integrated_model <-  as.data.frame(do.call("cbind", Means))
    
    colnames(integrated_model) <- make.names(c(model$model_svmLinear[[1]]$levels[1],
                                               model$model_svmLinear[[1]]$levels[2]))
    integrated_model <- data.frame(sample = rownames(Counts.norm),
                                   integrated_model = integrated_model,
                                   max = apply(integrated_model, 1, max),
                                   pred = colnames(integrated_model)[apply(integrated_model, 1, which.max)]
    )
    
    Lineage_preds[[y]] <- integrated_model
  }  
  # combine predictions from the individual T-ALL subtype models
  Lineage_preds <- data.frame(sample = rownames(Counts.norm),
                              "B-ALL" = (Lineage_preds[[1]][,2] +
                                             Lineage_preds[[2]][,2])/2,
                              "T-ALL" = (Lineage_preds[[1]][,3] +
                                           Lineage_preds[[2]][,3])/2,
                              check.names = F
  )
  Lineage_preds$prediction <- "Unclassified"
  Lineage_preds$prediction[which(Lineage_preds$`B-ALL` > 0.7)] <- "B-ALL"
  Lineage_preds$prediction[which(Lineage_preds$`T-ALL` > 0.7)] <- "T-ALL"
  
  rownames(Lineage_preds) <- rownames(Counts.norm)
  
  ################################################################################
  ###### finalize output table ###################################################
  ################################################################################
  
  output <- as.data.frame(cbind(Lineage_preds))
  
  cat("Lienage predictions saved in:", getwd(),"\n")
  # save predictions
  cat("Writing output file:",paste0(out.file),"...\n")
  utils::write.table(output,out.file, sep = sep, row.names = F)
  return(output)
  
}
