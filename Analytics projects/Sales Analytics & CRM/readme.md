
# Optimizing Sales Performance & Customer Retention Through Data-Driven Insights

## **What it does:**

This solution analyzes sales performance, identifies deal success drivers, pinpoints reasons for lost deals, and predicts customer churn risks. It also uncovers seasonal trends to optimize pipeline efficiency and boost revenue.

## **Who it’s for:**

**Sales Teams** – To prioritize high-potential deals and improve win rates.

**Sales Managers** – To refine strategies based on data-driven insights.

**Business Leaders** – To forecast revenue risks and retention opportunities.

## Objective
* Analyze Sales Performance – Identify top-performing sales agents, best-selling products, and high-value deals.

* Understand Deal Success & Failure – Determine factors leading to lost deals and measure conversion rates.

* Predict Churn Risk – Identify at-risk accounts based on lost deals and engagement trends.

* Detect Seasonal Sales Trends – Analyze revenue fluctuations over time to optimize marketing and resource allocation.

* Enhance Decision-Making – Provide data-driven insights for sales strategy optimization using SQL and Power BI or Tableau.

## Dataset

### Table-1 : accounts

| Field   | Description |
|:------------------------------------:|:---------------------|
|account|	Company name|
|sector|	Industry
|	year_established|	Year Established|
|	revenue|	Annual revenue (in millions of USD)|
|	employees|	Number of employees|
|	office_location|	Headquarters|
|	subsidiary_of|	Parent company|


### Table-2 : products

| Field   | Description |
|:------------------------------------:|:---------------------|
|product|	Product name|
|series|	Product series|
|sales_price|	Suggested retail price|

### Table-3 : sales_teams
| Field   | Description |
|:------------------------------------:|:---------------------|
|sales_agent|	Sales agent|
|manager|	Respective sales manager|
|	regional_office|Regional office|


### Table-4 : sales_pipeline

| Field   | Description |
|:------------------------------------:|:---------------------|
|opportunity_id|	Unique identifier|
|sales_agent|	Sales agent |
|	product|	Product name|
|	account|	Company name|
|	deal_stage|	Sales pipeline stage (Prospecting > Engaging > Won / Lost)|
|	engage_date|	Date in which the "Engaging" deal stage was initiated|
|	close_date|	Date in which the deal was "Won" or "Lost"|
| close_value| Revenue from the deal|




## SQL Analysis
Predicting High-Value Deals Using Revenue Percentile Analysis 

    classifies deals into high, mid, and low-value segments and identifies which sales agents close the most high-value deals.

Sales Pipeline Velocity Analysis

    identify which accounts are moving faster or slower through different deal stages and can highlight bottlenecks.

Average Deal Closing Time by Industry

    Calculate the average number of days taken to close a deal for each industry.

Churn Risk Analysis Based on Deal Loss Patterns

    This query identifies accounts with a high risk of churn by calculating the lost deal percentage and the time gap since their last won deal.
Sales Seasonality & Revenue Impact Analysis

    This query identifies seasonal trends in sales performance by analyzing revenue fluctuations across months and years.

## Dashboard

1. Sales Performance 

         - KPIs: Total revenue, number of won deals, average deal size
         - Revenue breakdown by industry, company, and sales agent
2. Sales Funnel Analysis

         - Drop-off analysis at each stage (Prospecting → Engaging → Won/Lost)
         - Conversion rates at each stage

3. Monthly Revenue Trends

         - Line chart showing monthly revenue trends
         - Forecasting for future revenue growth
4. Sales Agent Performance

         - Ranking of agents based on closed deals & revenue
         - Win-rate comparison for different agents
5. Product Performance Analysis

         - Top-selling products by revenue and deal count
         - Comparison of sales across different product series
6. Industry & Regional Insights

         - Revenue contribution by sector
         - Performance by regional office
