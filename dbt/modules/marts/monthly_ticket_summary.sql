with monthly_tickets as (
    select
        format_date('%Y-%m', created_date) as year_month,
        count(*) as ticket_count,
        avg(case when status = 'Resolved' then resolution_time_hrs else null end) as avg_resolution_time_hrs,
        sum(case when status = 'Resolved' then 1 else 0 end) as resolved_count
    from {{ ref('stg_tickets') }}
    where created_date is not null
    group by 1
)

select
    year_month,
    ticket_count,
    round(avg_resolution_time_hrs, 2) as avg_resolution_time_hrs,
    round(resolved_count * 100.0 / ticket_count, 2) as closure_rate
from monthly_tickets
order by year_month