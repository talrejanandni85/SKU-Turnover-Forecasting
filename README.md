# 🧦 Amazon SKU Turnover & Sales Forecasting — Pierre Henry Socks

**Author:** Nandni Talreja  
**Role:** Marketing & Data Analytics Intern  
**Period:** September 2024 – December 2024  
**Tools:** R (tidyverse, lubridate, forecast, ggplot2) · Quarto · Excel (PivotTables, XLOOKUP) · Amazon Seller Central  

---

## 🔍 Project Overview

Pierre Henry Socks sells across multiple Amazon SKUs spanning different sock styles and sizes. With no systematic way to track which SKUs were performing, which were sitting idle, and what inventory levels to maintain, the company was making restocking decisions based on intuition rather than data.

I was brought in as a data analytics intern to build a repeatable analysis pipeline that could answer three core business questions:

1. **Which SKUs have low turnover and should be reduced or discontinued?**
2. **Which SKUs are high performers and need prioritized restocking?**
3. **Can we predict future sales to improve restocking timing?**

The result was a 12% improvement in inventory forecasting accuracy and a reduction in underperforming SKU stock by 18%.

---

## ❓ The Business Problem

- Amazon sales data existed across multiple spreadsheets by month, with no unified view of SKU performance
- Inventory snapshots were taken at 3 points (January, June, September) but never connected to sales velocity
- No model existed to predict future demand — restocking was reactive, not proactive
- Stakeholders needed a clear, actionable output they could use without running code themselves

---

## 🛠️ What I Built

### File 1: `SKU_Turnover_Rate.qmd` — Core Turnover Analysis (2023 Data)
- Loaded and merged Amazon order data with inventory snapshots from January, June, and September
- Parsed purchase dates using `lubridate`, extracted month/year, and aggregated to monthly sales by SKU
- Calculated **Cost of Goods Sold (COGS)** per SKU per month using unit cost of $2.30
- Computed **SKU Turnover Rate** across three windows:
  - January → June
  - January → September  
  - June → September
- Formula: `Turnover Rate = Total Units Sold / Average Inventory`
- Identified **68 low-turnover SKUs** (rate < 3), of which **35 had zero sales** despite holding inventory — direct cost to the business

### File 2: `SKU_Turnover_Rate_Results.qmd` — Correlation & Business Insights
- Split SKUs into **high-performing** (11 SKUs) and **low-performing** (31 SKUs) groups
- Ran correlation analysis between:
  - **Turnover rate vs. total sales** by period and SKU tier
  - **Turnover rate vs. item price** by period and SKU tier
- Key findings guided recommendations on which SKUs to discontinue, reprice, or restock

### File 3: `SKU_2024.qmd` — 2024 Update + Predictive Modeling
- Rebuilt the full turnover pipeline for January–September 2024 data
- Added **net proceeds data** to connect inventory performance to actual revenue impact
- Built a **linear regression model** for daily sales forecasting:
  - Features: 1-day lag, 7-day lag (captures weekly seasonality), day of week
  - 80/20 train/test split
  - Evaluated using MAE and RMSE
- Built an **ARIMA model** using `auto.arima()` for time-series forecasting
- Visualized actual vs. predicted sales for Aug–Oct 2024 holdout period

---

## 📊 Key Findings

**SKU Performance:**
- Most SKU turnover rates clustered between 0 and 10 — a cutoff of < 3 was used to flag underperformers
- 35 SKUs had zero COGS (no sales at all) yet maintained inventory — these were flagged for immediate review
- High-performing SKUs showed a **moderate negative correlation between price and turnover** (higher prices = slightly slower turnover), suggesting price sensitivity exists even for top SKUs
- Low-performing SKUs showed a **strong positive correlation between total sales and turnover** — when sales picked up for these SKUs, inventory cycled faster, suggesting seasonal opportunity

**Sales Forecasting:**
- The linear regression model using lagged sales and day-of-week captured weekly demand patterns effectively
- ARIMA was fitted to the daily sales time series to capture longer-range trend and seasonality
- Combined, the models supported a **12% improvement in inventory forecasting accuracy** vs. prior intuition-based restocking

**Business Outcome:**
- Recommendations led to a **18% reduction in underperforming SKU stock**
- Turnover analysis outputs were delivered as Excel files for use by 4 non-technical stakeholders

---

## 📁 Repository Structure

```
├── analysis/
│   ├── SKU_Turnover_Rate.qmd          # Core turnover pipeline (2023 data)
│   ├── SKU_Turnover_Rate_Results.qmd  # Correlation analysis & SKU segmentation
│   └── SKU_2024.qmd                   # 2024 update + regression & ARIMA forecasting
├── data/
│   └── amazon_jan_to_sept_2024.xlsx   # Anonymized sample of Amazon order data
└── README.md
```

---

## ⚙️ How to Run

1. Clone this repository
2. Open any `.qmd` file in RStudio
3. Install required packages:
```r
install.packages(c("readxl", "tidyverse", "lubridate", "ggplot2", 
                   "kableExtra", "writexl", "forecast", "psych"))
```
4. Update file paths in the data loading section to point to your local data files
5. Render to HTML for the full report

> ⚠️ **Note:** Proprietary Amazon Seller Central data is not included in this repository. The `.qmd` files and sample data structure are provided for portfolio and reproducibility purposes. Column names and data structure are preserved; actual sales figures and SKU identifiers have been anonymized.

---

## 💡 Skills Demonstrated

- **Financial analysis:** COGS calculation, turnover rate modeling, net proceeds analysis
- **Inventory analytics:** Multi-period SKU performance segmentation, restocking recommendations
- **Predictive modeling:** Linear regression with lag features, ARIMA time-series forecasting
- **Data wrangling:** Multi-sheet Excel ingestion, monthly aggregation, multi-dataset joins in R
- **Stakeholder delivery:** Excel output files designed for non-technical users

---

## 📬 Contact

**Nandni Talreja**  
📧 talrejanandni.da@gmail.com  
🔗 [LinkedIn](https://linkedin.com/in/nandni-talreja)  
💼 [Upwork](https://www.upwork.com/freelancers/~01883ca0f5638a8066)
