globalVariables(c("test_data","TALL_umap_model"))

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
#' allcatchr_projectTALL()
#'

allcatchr_projectTALL <- function(Counts.file=NULL, ID_class="symbol", 
                                  sep="\t", 
                                  out.file=paste0(getwd(),"/TALL_projection.tsv"), 
                                  plot.file = paste0(getwd(),"/TALL_projection.png"),
                                  plot.width = 8, 
                                  plot.height = 6,
                                 label.size = 3) {
  # Namespace from packages needed for prediction function using pre-trainted models
  loadNamespace("kknn")
  loadNamespace("ranger")
  loadNamespace("randomForest")
  loadNamespace("LiblineaR")
  loadNamespace("glmnet")
  loadNamespace("elasticnet") 
  loadNamespace("umap")  
  loadNamespace("ggplot2")  
  loadNamespace("ggrepel")  
  
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
    Counts <- utils::read.csv(Counts.file, sep = sep, stringsAsFactors = F, row.names = 1,check.names = F)
    cat("counts loaded...\n")
  }
  
  if (length(rownames(Counts)) == length(which(rownames(Counts) == as.character(1:nrow(Counts))))) {
    stop("Error: symbol, ensembl or entrez are not provided in the first column")
  }
  ID_conv <- ID_conversion_TALLumap
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
  
  umap_projection <- as.data.frame(predict(TALL_umap_model, Counts.norm[,lasso_genes_TALL]))
  umap_projection <- data.frame("X1" = umap_projection$V1,
                              "X2" = umap_projection$V2,
                              "pred_final" = "query",
                              "label" = rownames(umap_projection)
    )

    TALL_subtypes_umap_P <- as.data.frame(rbind(umap_projection, TALL_subtypes_umap_P))
    TALL_subtypes_umap_P$pred_final <- factor(TALL_subtypes_umap_P$pred_final, levels = names(TALL_subtype_colors))
    plot <- suppressWarnings({ggplot2::ggplot(TALL_subtypes_umap_P, ggplot2::aes(x=X1, y=X2, color = pred_final, label = label
    )) +
      ggplot2::geom_point(size = 0.75,alpha = 1) + 
      ggplot2::geom_point(data = TALL_subtypes_umap_P[which(TALL_subtypes_umap_P$pred_final == "query"),],
                          size = 0.75,alpha = 1, color = "black", shape = 21) + 
      ggplot2::xlab("UMAP 1") +
      ggplot2::ylab("UMAP 2") +
      ggplot2::theme_bw() +
      ggplot2::scale_color_manual(values = TALL_subtype_colors) +
      ggrepel::geom_text_repel(max.overlaps = 1000, size= label.size, min.segment.length = 0, color = "black") + 
      ggplot2::theme( text = ggplot2::element_text(size = 8), 
             #axis.title = element_blank(), 
             #legend.title = element_blank(),
             legend.box="vertical", 
             legend.key.size =ggplot2::unit(x = 1, "mm"),
             panel.grid = ggplot2::element_blank(),
             panel.border = ggplot2::element_blank(),
             axis.text = ggplot2::element_blank(),
             axis.ticks = ggplot2::element_blank(),
             axis.line = ggplot2::element_line(colour = "black"),
             legend.title = ggplot2::element_blank(),
             legend.text= ggplot2::element_text(size=6),
             plot.title = ggplot2::element_blank()
      ) +
      ggplot2::guides(color = ggplot2::guide_legend(override.aes = list(size = 1), ncol = 1),
             shape = ggplot2::guide_legend(override.aes = list(size = 1), ncol = 1))
   })
    suppressWarnings({ggplot2::ggsave(plot = plot,
       plot.file,
       device = "png", width = plot.width, height = plot.height, units = "in", dpi = 600)})

   cat("UMAP projection is saved in:", paste0(out.file),"\n")                                                                       
   cat("UMAP projection table is saved in:", paste0(plot.file),"\n")

  utils::write.table(umap_projection, out.file, sep = sep, row.names = F)
  output <- list(umap_projection = umap_projection,
                plot = plot)
  # return predictions
  return(output) 
}

