with resolved_tickets as (
    select
        category,
        priority,
        resolution_time_hrs
    from {{ ref('stg_tickets') }}
    where 
        status = 'Resolved'
        and resolution_time_hrs is not null
)

select
    category,
    priority,
    avg(resolution_time_hrs) as avg_resolution_time_hrs,
    count(*) as ticket_count
from resolved_tickets
group by 1, 2
order by category, priority