

select CP.Crop, count(CP.Crop)
from Crop_Prod_study CP
group by Crop

select distinct(CP.Crop) 
from Crop_Prod_study CP

-- Que-1: Calculate crop yield (production per unit area) to assess which crops are the most efficient in production. 
select Crop, sum(Production)/sum(Area) as 'Crop Yield'
from Crop_prod_study
group by Crop
order by 'Crop Yield' desc

-- Que-2 : calculates the year-over-year percentage growth in crop production for each state and crop.

with Yearly_Production as (
    select 
        State_Name,
		Crop_Year,
        Crop,
        sum(Production) as Production
    from crop_prod_study
    where Production is not null
    group by Crop_Year, State_Name, Crop
)

select 
    State_Name, 
    Crop, 
    Crop_Year,
    Production,
    lag(Production, 1, 0) over (partition by State_Name, Crop order by Crop_Year) as Prev_Year_Production,
    Case 
        when lag(Production, 1, 0) over (partition by State_Name, Crop order by Crop_Year) = 0 then NULL
        else ((Production - lag(Production, 1, 0) over (partition by State_Name, Crop order by Crop_Year)) * 100.0 
             / lag(Production, 1, 0) over (partition by State_Name, Crop order by Crop_Year))
    end as YoY_Growth
from Yearly_Production
where Production is not null
order by State_Name, Crop, Crop_Year




-- Que-3 : calculates each state's average yield (production per area) and identifies the top N states with the highest average yield over multiple years.

with Average_state_yield as (
	select 
		State_Name,
		avg(Production/nullif(Area,0)) as State_yield
	from Crop_prod_study
	where Area > 0 and Production is not null
	group by State_name
)

select top 5 State_name, State_yield
from Average_state_yield
order by State_yield desc


-- Que-4 : Calculates the variance in production across different crops and states. (tip: use VAR function).

select 
    State_Name,
    Crop,
    round(var(Production),2) as Production_Variance
from Crop_prod_study
group by State_Name, Crop
order by State_Name, Crop asc ,Production_Variance desc

-- Que-5 : Identifies states that have the largest increase in cultivated area for a specific crop between two years

 
drop procedure if exists Area_growth
create procedure Area_growth
    @Year1 int,
    @Year2 int,
	@Cropname varchar(20)
as
begin
    with Cultivated_area as (
        select 
            State_Name,
            Crop,
            Crop_Year,
            sum(Area) as Total_Cultivated_Area
        from crop_prod_study
        where Area is not null
        group by State_Name, Crop, Crop_Year
    )
    select 
        State_Name, 
        Crop,
        max(case when Crop_Year = @Year1 then Total_Cultivated_Area end) as Area_year1,
        max(case when Crop_Year = @Year2 then Total_Cultivated_Area end) as Area_year2,
        case 
            when max(case when Crop_Year = @Year1 then Total_Cultivated_Area end) = 0 then NULL
            else (
                max(case when Crop_Year = @Year2 then Total_Cultivated_Area end) - 
                max(case when Crop_Year = @Year1 then Total_Cultivated_Area end)
            ) * 100.0 / max(case when Crop_Year = @Year1 then Total_Cultivated_Area end)
        end as Percentage_Area_Change
    from Cultivated_area
	where Crop= @Cropname
    group by State_Name, Crop
    order by Percentage_Area_Change desc
end


exec Area_growth @Year1 = 2004, @Year2 = 2009, @Cropname = 'Coconut'

 


