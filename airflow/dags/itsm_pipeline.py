from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
import pandas as pd
import os

# Define default arguments for the DAG
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

# Define the DAG
dag = DAG(
    'itsm_pipeline',
    default_args=default_args,
    description='ITSM data pipeline for ticket analytics',
    schedule_interval=timedelta(days=1),
    start_date=datetime(2023, 1, 1),
    catchup=False,
    tags=['itsm', 'analytics'],
)

# Function to load CSV data into PostgreSQL
def load_csv_to_postgres():
    # Path to the CSV file
    csv_file_path = 'data/Sample Data file for Analysis_Jan\'25.csv'
    
    # Read the CSV file
    df = pd.read_csv(csv_file_path)
    
    # Rename columns to match expected schema
    column_mapping = {
        'inc_number': 'Ticket_ID',
        'inc_category': 'Category',
        'inc_business_service': 'Sub_Category',
        'inc_priority': 'Priority',
        'inc_sys_created_on': 'Created_Date',
        'inc_resolved_at': 'Resolved_Date',
        'inc_state': 'Status',
        'inc_assignment_group': 'Assigned_Group',
        'inc_assigned_to': 'Technician',
        # No direct mapping for Resolution_Time_Hrs, will calculate
        'inc_caller_id': 'Customer_Impact'
    }
    
    # Rename columns
    df = df.rename(columns=column_mapping)
    
    # Calculate resolution time in hours
    df['Created_Date'] = pd.to_datetime(df['Created_Date'], format='%m/%d/%Y %H:%M', errors='coerce')
    df['Resolved_Date'] = pd.to_datetime(df['Resolved_Date'], format='%m/%d/%Y %H:%M', errors='coerce')
    
    # Calculate resolution time in hours
    df['Resolution_Time_Hrs'] = (df['Resolved_Date'] - df['Created_Date']).dt.total_seconds() / 3600
    
    # Connect to PostgreSQL
    pg_hook = PostgresHook(postgres_conn_id='postgres_default')
    engine = pg_hook.get_sqlalchemy_engine()
    
    # Load the data into PostgreSQL
    df.to_sql(
        'raw_tickets',
        engine,
        schema='itsm',
        if_exists='replace',
        index=False
    )
    
    print(f"Loaded {len(df)} rows into PostgreSQL")

# Function to validate DBT models
def validate_dbt_models():
    # Connect to PostgreSQL
    pg_hook = PostgresHook(postgres_conn_id='postgres_default')
    
    # List of tables to validate
    tables_to_validate = [
        'stg_tickets',
        'avg_resolution_time',
        'closure_rate',
        'monthly_ticket_summary',
        'ticket_backlog'
    ]
    
    # Validate each table
    for table in tables_to_validate:
        result = pg_hook.get_records(f"SELECT COUNT(*) FROM {table}")
        count = result[0][0]
        print(f"Table {table} has {count} rows")
        
        if count == 0:
            raise ValueError(f"Table {table} is empty")
    
    print("All DBT models validated successfully")

# Task 1: Load CSV data into PostgreSQL
load_csv_task = PythonOperator(
    task_id='load_csv_to_postgres',
    python_callable=load_csv_to_postgres,
    dag=dag,
)

# Task 2: Run DBT models
run_dbt_task = BashOperator(
    task_id='run_dbt_models',
    bash_command='cd ../dbt && dbt run',
    dag=dag,
)

# Task 3: Validate DBT models
validate_dbt_task = PythonOperator(
    task_id='validate_dbt_models',
    python_callable=validate_dbt_models,
    dag=dag,
)

# Define task dependencies
load_csv_task >> run_dbt_task >> validate_dbt_task
