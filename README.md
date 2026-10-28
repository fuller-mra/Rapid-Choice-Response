# rcr_by_group: Rapid Choice Response (RCR) Score Calculation

`rcr_by_group` is an R function designed for neuromarketing and commercial market research to calculate and rescale timed binary (YES/NO) association data. 

It implements a modern, single-trial **Rapid Choice Response (RCR)** framework that measures the speed and direction of consumer perceptions, accounting for outlier noise and grouping variables item-by-item.

## 🧠 Methodology Overview
Unlike a formal academic Implicit Association Test (IAT) that relies on block-sorting differences to yield psychometric D-scores, this RCR setup evaluates individual stimulus pairings on a simple, single-trial basis. It provides fast, directional insights into automatic, "gut-level" (Type-1) consumer perceptions.

### User Defined Trimming Rule
To safeguard data integrity, the user can specify a top/bottom percentile for use as symmetrical trimming applied to both tails of the reaction-time distribution within each item and group (e.g. country). This cleans out two distinct types of data noise:

* **Trimming the Slowest (Distraction Filter):** Captures and removes instances where respondents became severely distracted, paused mid-survey, or looked away from their screens. This prevents massive latencies (e.g., several seconds or minutes) from skewing the group averages.
* **Trimming the Fastest (Non-Cognitive Floor Filter):** The idea is to remove accidental double-taps, rapid button-mashing, and automated survey bots. 

---

## 🔢 Score Interpretation
The function scales individual response times onto a standardized continuous spectrum from **-1.00** to **+1.00**:

* **+0.50 to +1.00** — **Strong, fast, automatic association.** 
* **+0.20 to +0.49** — **Moderate association.** 
* **-0.19 to +0.19** — **Weak or uncertain/neutral association.** 
* **-0.20 to -0.49** — **Moderate rejection.** 
* **-0.50 to -1.00** — **Strong, fast, automatic rejection.** 

---

### ✨ Usage
```r
source("https://raw.githubusercontent.com/fuller-mra/Rapid-Choice-Response/main/rcr_by_group.R")

final_score_matrix <- rcr_by_group(
  data       = survey_data, 
  time_cols  = 13:22,      # Column indices/names containing reaction times in ms
  pick_cols  = 3:12,       # Column indices/names containing YES/NO data
  group_col  = "DCOUNTRY",  # Column to split/group calculation by
  negative   = 1,          # Value matching a "NO/Not Associated" response
  positive   = 2,          # Value matching a "YES/Associated" response
  trim       = 0.05        # Percentage to trim on both ends (5%)
)
```

## 🛠️ Key Arguments
* `data`: A data frame containing the raw survey response and reaction time data.
* `time_cols`: A vector of column indices or names containing reaction times in milliseconds.
* `pick_cols`: A vector of column indices or names containing binary choice data (hits/misses).
* `group_col`: An optional string specifying the column name to group by (e.g., `"DCOUNTRY"`). If `NULL`, the entire dataset is treated as a single group.
* `negative` / `positive`: The raw data values representing rejection and acceptance respectively.
* `trim`: The proportion of extreme responses to trim from both the top and bottom percentiles.
