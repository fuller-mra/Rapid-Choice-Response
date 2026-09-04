#' Rapid Choice Response (RCR) Score Calculation by Group
#'
#' @description
#' Evaluates and rescales timed binary (YES/NO) association data using a 
#' commercially adapted Rapid Choice Response (RCR) framework. The function 
#' groups data (e.g., by country), removes reaction-time outliers item-by-item, 
#' and rescales velocities onto a continuous -1 to +1 association strength spectrum.
#' Trimming the top (highest scores)
#'
#' @param data A data frame containing the raw survey response and reaction time data.
#' @param time_cols A vector of column indices or names containing reaction times in milliseconds.
#' @param pick_cols A vector of column indices or names containing binary choice data (hits/misses).
#' @param group_col An optional string specifying the column name to group by (e.g., "DCOUNTRY"). 
#'   If \code{NULL}, the entire dataset is treated as a single group. Defaults to \code{NULL}.
#' @param negative The raw data value that represents a negative/reject response (e.g., 1 or -1).
#' @param positive The raw data value that represents a positive/accept response (e.g., 2 or 1).
#' @param trim A numeric value representing the proportion of extreme responses to trim from 
#'   both the top and bottom percentiles. Defaults to \code{0.05} (5%).
#'
#' @return A numeric matrix of rescaled RCR scores ranging from -1.00 (fast intuitive rejection) 
#'   to +1.00 (fast intuitive association), where values near 0 represent slow or uncertain responses. 
#'   Columns are named to match the original time columns prefixed with \code{"score_"}.
#'
#' @details 
#' Unlike traditional academic Implicit Association Tests (IAT) that calculate D-scores using 
#' compatible/incompatible blocking paradigms, this function uses a heuristic, single-trial 
#' approach tailored for swift market research diagnostics. 
#' 
#' Outlier trimming and normalization are executed independently for each item (column) within 
#' each group to prevent shorter stimuli from being systematically misidentified as speed outliers 
#' relative to longer stimuli.
#' 
#' If a pre/post setup structure is part of the sutdy then score them each separately. 
#' 
#' @export
#'
#' @examples
#' \code{
#' # Example Usage:
#' final_scores <- rcr_by_group(
#'   data       = survey_data,
#'   time_cols  = 13:22,
#'   pick_cols  = 3:12,
#'   group_col  = "DCOUNTRY",
#'   negative   = 1,
#'   positive   = 2,
#'   trim       = 0.05
#' )
#' }
rcr_by_group <- function(data, time_cols, pick_cols, group_col = NULL, 
                         negative = -1, positive = 1, trim = 0.05) {
  
  # Core worker function executing the item-by-item RCR mathematical framework
  rcr_numeric <- function(t_mat, p_mat, neg, pos, tr) {
    out_scores <- matrix(NA_real_, nrow = nrow(t_mat), ncol = ncol(t_mat))
    
    # Process column-by-column to preserve individual item latency baselines
    for (j in seq_len(ncol(t_mat))) {
      t_val <- t_mat[, j]
      p_val <- p_mat[, j]
      
      # Step 1: Calculate local item quantiles within this group segment
      q_low  <- quantile(t_val, tr, na.rm = TRUE)
      q_high <- quantile(t_val, 1 - tr, na.rm = TRUE)
      range_size <- q_high - q_low
      
      # Fallback if variation is non-existent
      if (is.na(range_size) || range_size == 0) range_size <- 1 
      
      # Step 2: Extract valid indices matching the quality control filter
      valid_idx <- which(!is.na(t_val) & t_val >= q_low & t_val <= q_high)
      if (length(valid_idx) == 0) next
      
      # Step 3: Compute raw relative speed (1 = fastest allowed, 0 = slowest allowed)
      speed_normalized <- 1 - ((t_val[valid_idx] - q_low) / range_size)
      
      # Step 4: Apply strict mathematical directionality matching documentation:
      # Fast YES -> stretches from 0 to +1
      # Fast NO  -> stretches from 0 to -1
      # Slow responses (speed near 0) always compress toward 0
      direction <- rep(0, length(valid_idx))
      direction[p_val[valid_idx] == pos] <- 1
      direction[p_val[valid_idx] == neg] <- -1
      
      out_scores[valid_idx, j] <- speed_normalized * direction
    }
    
    return(out_scores)
  }
  
  # Ensure input column selections are correctly recognized as vectors
  time_cols <- unlist(time_cols)
  pick_cols <- unlist(pick_cols)
  
  # Track original row ordering to ensure the final output mirrors the input data frame
  original_row_id <- seq_len(nrow(data))
  
  t_matrix <- as.matrix(data[, time_cols, drop = FALSE])
  p_matrix <- as.matrix(data[, pick_cols, drop = FALSE])
  
  if (is.null(group_col)) {
    # Path A: Process entire dataset globally if no grouping variable is passed
    final_scores <- rcr_numeric(t_matrix, p_matrix, negative, positive, trim)
    
  } else {
    # Path B: Segment, process, and reassemble matrices by unique group values
    group_vector <- data[[group_col]]
    unique_groups <- unique(group_vector)
    
    score_chunks <- list()
    id_chunks    <- list()
    
    for (g in unique_groups) {
      subset_idx <- which(group_vector == g)
      if (length(subset_idx) == 0) next
      
      g_scores <- rcr_numeric(t_matrix[subset_idx, , drop = FALSE], 
                              p_matrix[subset_idx, , drop = FALSE], 
                              negative, positive, trim)
      
      score_chunks[[length(score_chunks) + 1]] <- g_scores
      id_chunks[[length(id_chunks) + 1]]       <- original_row_id[subset_idx]
    }
    
    # Bind processed segments and re-sort them back into perfect baseline alignment
    combined_scores <- do.call(rbind, score_chunks)
    combined_ids    <- unlist(id_chunks)
    final_scores    <- combined_scores[order(combined_ids), , drop = FALSE]
  }
  
  # Format final column headers to reflect RCR score transformations
  colnames(final_scores) <- paste0("score_", colnames(data)[time_cols])
  return(final_scores)
}
