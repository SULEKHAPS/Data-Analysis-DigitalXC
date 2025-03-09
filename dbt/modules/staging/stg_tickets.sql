with source as (
    select * from {{ source('itsm', 'raw_tickets') }}
),

cleaned as (
    select
        -- Convert column names to lowercase and clean identifiers
        lower(trim(Ticket_ID)) as ticket_id,
        nullif(trim(Category), '') as category,
        nullif(trim(Sub_Category), '') as sub_category,
        -- Handle priority format from the new data file (e.g., "3 - Moderate")
        case
            when Priority like '%Critical%' then 'Critical'
            when Priority like '%High%' then 'High'
            when Priority like '%Moderate%' then 'Medium'
            when Priority like '%Low%' then 'Low'
            else nullif(trim(Priority), '')
        end as priority,
        -- Convert string dates to proper timestamp format
        try_cast(Created_Date as timestamp) as created_date,
        try_cast(Resolved_Date as timestamp) as resolved_date,
        -- Map status values from the new data format
        case
            when Status = 'Closed' then 'Resolved'
            else nullif(trim(Status), '')
        end as status,
        nullif(trim(Assigned_Group), '') as assigned_group,
        nullif(trim(Technician), '') as technician,
        -- Handle numeric values
        case 
            when Resolution_Time_Hrs is null or Resolution_Time_Hrs = '' then null
            else try_cast(Resolution_Time_Hrs as float)
        end as resolution_time_hrs,
        nullif(trim(Customer_Impact), '') as customer_impact
    from source
    -- Remove duplicates by taking the first occurrence of each ticket_id
    qualify row_number() over (partition by Ticket_ID order by Created_Date) = 1
)

select
    ticket_id,
    category,
    sub_category,
    priority,
    created_date,
    resolved_date,
    status,
    assigned_group,
    technician,
    resolution_time_hrs,
    customer_impact,
    -- Extract date components
    extract(year from created_date) as created_year,
    extract(month from created_date) as created_month,
    extract(day from created_date) as created_day
from cleaned
where ticket_id is not null -- Ensure we only include records with valid IDs