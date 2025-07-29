-- Q1: Evaluating Financial Risk by Encounter Outcome

with EncounterWithDemographics as (
    select 
        e.Id,
        e.PATIENT,
        e.REASONCODE,
		e.REASONDESCRIPTION,
        e.TOTAL_CLAIM_COST,
        e.PAYER_COVERAGE,
        (e.TOTAL_CLAIM_COST - e.PAYER_COVERAGE) as Uncovered_cost,
        p.GENDER,
        datediff(year, p.BIRTHDATE, getdate()) as age
    from encounters e
    inner join patients p on e.PATIENT = p.Id
),

-- Aggregate uncovered cost by reason_code
ReasonCodeStats as (
    select 
        REASONCODE,
		REASONDESCRIPTION,
		avg(age) as Average_Age,
        count(*) as total_encounters,
        round(sum(uncovered_cost),0) as total_uncovered_cost,
        round(avg(uncovered_cost),0) as avg_uncovered_cost,
        round(max(uncovered_cost),0) as max_uncovered_cost
    from EncounterWithDemographics
    group by REASONCODE,REASONDESCRIPTION
),

-- Identifying most common gender for reasoncode
MostCommonGender as (
    select 
        REASONCODE,
        GENDER as most_common_gender
    from (
        select 
            REASONCODE,
            GENDER,
            count(*) as gender_count,
            ROW_NUMBER() OVER (partition by REASONCODE order by count(*) desc) as rn
        from EncounterWithDemographics
        group by REASONCODE, GENDER) as ranked
    where rn = 1
)


select 
    r.REASONCODE,
	r.REASONDESCRIPTION,
	r.Average_Age,
	m.most_common_gender,
    r.total_encounters,
    r.total_uncovered_cost,
    r.avg_uncovered_cost,
    r.max_uncovered_cost
    
from ReasonCodeStats r
left join MostCommonGender m on r.REASONCODE = m.REASONCODE
order by r.total_uncovered_cost desc,r.avg_uncovered_cost desc;




--- Q2:Identifying Patients with Frequent High-Cost Encounters
with HighCostEncounters as (
    select 
        e.patient,
        year(e.stop) as encounter_year, 
        e.TOTAL_CLAIM_COST
    from encounters e
    where e.TOTAL_CLAIM_COST > 10000
),

PatientEncounterStats as (
    select 
        h.PATIENT,
        h.encounter_year,
        count(*) as encounter_count,
        sum(h.TOTAL_CLAIM_COST) as total_claim_cost
    from HighCostEncounters h
    group by h.PATIENT, h.encounter_year
    having count(*) > 3
)

select 
	p.Id,
    p.FIRST,
	p.LAST,
	p.MARITAL,
	p.RACE,
	p.ETHNICITY,
    p.GENDER,
    p.BIRTHDATE,
    s.encounter_year,
    s.encounter_count,
    round(s.total_claim_cost, 0) as total_claim_cost
from PatientEncounterStats s
join patients p on s.PATIENT = p.Id
order by s.total_claim_cost desc;



--- Q3.: Identifying Risk Factors Based on Demographics and Encounter Reasons

-- Creating a threshold of > 10000 for High cost encounter
with HighCostEncounters as (
    select 
        e.Id,
        e.PATIENT,
        e.REASONCODE,
		e.REASONDESCRIPTION,
        e.TOTAL_CLAIM_COST,
        e.START
    from encounters e
    where e.TOTAL_CLAIM_COST > 10000
),

-- Get top 3 most frequent ReasonCodes among high-cost encounters
TopReasonCodes as (
    select 
        REASONCODE,
		REASONDESCRIPTION,
        count(*) as encounter_count
    from HighCostEncounters
    group by REASONCODE,REASONDESCRIPTION
    order by encounter_count desc
    offset 0 rows fetch next 3 rows only
),

-- join with patients and calculate age
PatientwithDemographics as (
    select 
        p.Id,
        p.GENDER,
        datediff(year, p.BIRTHDATE, getdate()) as age
    from patients p
),

-- Combine everything
joinedData as (
    select 
        h.REASONCODE,
		h.REASONDESCRIPTION,
        d.GENDER,
        case 
            when d.age < 18 then '0-17'
            when d.age between 18 and 35 then '18-35'
            when d.age between 36 and 60 then '36-60'
            else '60+' 
        end as age_group,
        h.TOTAL_CLAIM_COST
    from HighCostEncounters h
    join TopReasonCodes t on h.REASONCODE = t.REASONCODE
    join PatientwithDemographics d on h.PATIENT = d.Id
)

-- Aggregate by ReasonCode + Gender + Age Group
select 
    REASONCODE,
	REASONDESCRIPTION,
    GENDER,
    age_group,
    count(*) as encounter_count,
    round(sum(TOTAL_CLAIM_COST), 0) as total_cost
from joinedData
group by REASONCODE,REASONDESCRIPTION, GENDER, age_group
order by REASONCODE, total_cost desc;



--- Q4: assessing Payer Contributions for Different Procedure Types
with EncounterDetails as (
    select 
        e.Id,
        e.PAYER,
        e.TOTAL_CLAIM_COST,
		pr.BASE_COST,
        e.PAYER_COVERAGE,
        (e.TOTAL_CLAIM_COST - e.PAYER_COVERAGE) as uncovered_cost
    from encounters e join procedures pr on e.id = pr.encounter
    where e.TOTAL_CLAIM_COST is not null and e.PAYER_COVERAGE is not null
)

select 
    p.NAME,
    count(e.Id) as total_encounters,
    round(sum(e.TOTAL_CLAIM_COST), 0) as TOTAL_CLAIM_COST,
	round(sum(e.BASE_COST),0) as BASE_COST,
    round(sum(e.PAYER_COVERAGE), 0) as total_payer_coverage,
    round(sum(e.uncovered_cost), 0) as total_uncovered_cost,
    round(
        case 
            when sum(e.TOTAL_CLAIM_COST) = 0 then 0
            else 100.0 * sum(e.PAYER_COVERAGE) / sum(e.TOTAL_CLAIM_COST)
        end, 2
    ) as coverage_percent_against_total_claim_cost,
	case 
        when round(sum(e.PAYER_COVERAGE), 0) = 0 then 'No coverage'
        when round(sum(e.PAYER_COVERAGE), 0) < round(sum(e.BASE_COST),0) then 'Partial coverage'
        when round(sum(e.PAYER_COVERAGE), 0) >= round(sum(e.BASE_COST),0)  then 'Full coverage'
    end as payer_contribution_to_base_cost
from EncounterDetails e
join payers p on e.PAYER = p.Id
group by p.NAME
order by coverage_percent_against_total_claim_cost desc;




--- Q5: Identifying Patients with Multiple Procedures Across Encounters
select     
    pr.REASONCODE,
	pr.PATIENT,
	p.FIRST,
	p.LAST,
    count(distinct pr.ENCOUNTER) as encounter_count,
    count(*) as procedure_count
from procedures pr join patients p on p.id = pr.PATIENT
where pr.REASONCODE is not null
group by pr.REASONCODE,pr.PATIENT,p.FIRST,p.LAST
having count(distinct pr.ENCOUNTER) > 1 and count(*) > count(distinct pr.ENCOUNTER)
order by procedure_count desc



--- Q6: Analyzing Patient Encounter Duration for Different Classes
select 
    Id as Encounter_ID,
    PATIENT,
    ORGANIZATION,
    ENCOUNTERCLASS,
    START,
    STOP,
    datediff(hour, START, STOP) as duration_hours
from 
    encounters
where 
    datediff(hour, START, STOP) > 24;

-- Average Encounter duration for different classes and counting encounters where duration exceeded 24 hours
with EncounterDurations as (
    select         
        ENCOUNTERCLASS,
        Id as ENCOUNTER_ID,
        PATIENT,
        START,
        STOP,
        datediff(hour, START, STOP) as duration_hours
    from encounters
	)

select    
    ENCOUNTERCLASS,
    avg(duration_hours * 1.0) as avg_duration_hours,
    count(case when duration_hours > 24 then 1 END) as encounters_over_24hrs
from EncounterDurations
group by ENCOUNTERCLASS;
