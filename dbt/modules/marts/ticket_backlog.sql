with open_tickets as (
    select
        priority,
        created_date,
        current_timestamp() as current_date,
        date_diff(current_timestamp(), created_date, day) as age_days
    from {{ ref('stg_tickets') }}
    where 
        status != 'Resolved'
        and created_date is not null
)

select
    priority,
    count(*) as open_ticket_count,
    min(created_date) as oldest_ticket_date,
    round(avg(age_days), 1) as avg_age_days
from open_tickets
group by 1
order by 
    case 
        when priority = 'Critical' then 1
        when priority = 'High' then 2
        when priority = 'Medium' then 3
        when priority = 'Low' then 4
        else 5
    end