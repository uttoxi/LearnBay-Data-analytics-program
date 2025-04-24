/* Que-1 : classifies deals into high, mid, and low-value segments and identifies which sales agents close the most high-value deals. */

with Ranked_deals as (
	select 
		sp.opportunity_id as opportunity_id,
		sp.sales_agent as sales_agent,
		st.regional_office as regional_office,
		sp.close_value as close_value,
		percent_rank() over (order by sp.close_value) as revenue_percentile
	from sales_pipeline sp inner join sales_teams st on sp.sales_agent = st.sales_agent
	where sp.close_value is not null
),
classified_deals as (
	select
		opportunity_id,
		sales_agent,
		regional_office,
		close_value,
		revenue_percentile,
    case
      when revenue_percentile >= 0.75 then 'High'
      when revenue_percentile >= 0.25 then 'Mid'
      else 'Low'
    end as value_segment
  from ranked_deals
)

select 
	sales_agent, regional_office, count(opportunity_id) as High_Value_Deals
from classified_deals
where value_segment='High'
group by sales_agent,regional_office
order by High_Value_Deals desc;

/* Que-2 : identify which accounts are moving faster or slower through different deal stages and can highlight bottlenecks. 

win rate = num of 'won' deals / total deals
sales pipeline velocity = (number of opportunities * average deal size * win rate)/ average duration taken for sale */

with measures as (
	select 
		account,
		count(opportunity_id) as number_of_opportunities,
		avg(cast(close_value as float)) as avg_deal_size,                  --- close value is nvarchar(50) data type not suitable for calculating average
		sum(case when deal_stage = 'won' then 1 else 0 end)*1.0/count(*) as win_rate,    
		avg(datediff(day,engage_date, close_date)) as avg_duration_days
	from sales_pipeline
	where engage_date is not null and close_date is not null
	group by account
)
select 
	account,
	number_of_opportunities,
	avg_deal_size,
	win_rate,
	avg_duration_days,
	round((number_of_opportunities * avg_deal_size * win_rate)/avg_duration_days,2) as pipeline_velocity
from measures


/* Que-3: Calculating the average number of days taken to close a deal for each industry. */

select 
	a.sector,
	avg(datediff(day, sp.engage_date, sp.close_date)) as avg_days_to_close
from sales_pipeline sp
inner join accounts a
on a.account = sp.account
where engage_date is not null and close_date is not null 
group by a.sector
order by avg_days_to_close desc


/* Que-4: This query identifies accounts with a high risk of churn by calculating the lost deal percentage and the time gap since their last won deal. */

with deal_metrics as (
    select
        account,
        count(*) as total_deals,
        sum(case when deal_stage = 'Lost' then 1 else 0 end) as lost_deals,
        max(case when deal_stage = 'Won' then cast(close_date as date) end) as last_won_date
    from sales_pipeline
	where account is not null
    group by account
),
churn_analysis as (
    select
        account,
        total_deals,
        lost_deals,
        last_won_date,
        datediff(day,last_won_date,'2017/12/31') as days_since_last_win,
		round((cast(lost_deals as float) * 100.0 / total_deals),2) as lost_deal_percentage
    from deal_metrics
)
select *
from churn_analysis
where days_since_last_win >= 10 and lost_deal_percentage >= 35.0    --- Adjust limit as needed
order by lost_deal_percentage desc



/* Que-5: To identify seasonal trends in sales performance by analyzing revenue fluctuations across months and years.  */
with monthly_revenue as (
	select 
		year(close_date) as year,
		month(close_date) as month,
		datename(month,close_date) as Month_name,
		sum(cast(close_value as float)) as monthly_revenue
	from sales_pipeline
	where deal_stage = 'Won'
	group by year(close_date),month(close_date),datename(month,close_date) 
),
seasonal_trend as (
	select 
		year,
		month,
		Month_name,
		monthly_revenue,
		lag(monthly_revenue) over (order by year,month) as previous_revenue,
		case 
			when lag(monthly_revenue) over(order by year,month) is null  then 0
			when lag(monthly_revenue) over(order by year,month) = 0  then 0
			else (monthly_revenue - lag(monthly_revenue) over (order by year,month))*100/lag(monthly_revenue) over (order by year,month) end percentage_change
			from monthly_revenue
		)
select 
	year,
	Month_name,
	monthly_revenue,
	previous_revenue,
	CAST(round(percentage_change,2) AS VARCHAR) + '%' AS percentage_change

from seasonal_trend


		




