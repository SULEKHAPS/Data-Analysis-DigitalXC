with ticket_counts as (
    select
        assigned_group,
        count(*) as total_tickets,
        sum(case when status = 'Resolved' then 1 else 0 end) as closed_tickets
    from {{ ref('stg_tickets') }}
    where assigned_group is not null
    group by 1
)

select
    assigned_group,
    total_tickets,
    closed_tickets,
    round(closed_tickets * 100.0 / total_tickets, 2) as closure_rate
from ticket_counts
order by closure_rate desc