# ITSM Data Analytics Project

## Overview

This project implements a complete data pipeline for analyzing IT Service Management (ITSM) ticket data. It demonstrates the ability to process, transform, and visualize ServiceNow ticket data using a modern data stack consisting of PostgreSQL, DBT, Apache Airflow, and Apache Superset.

## Project Structure

```
├── airflow/
│   └── dags/
│       └── itsm_pipeline.py     # Airflow DAG for orchestrating the pipeline
├── data/
│   └── sample_tickets.csv       # Sample ServiceNow ticket data
├── dbt/
│   ├── models/
│   │   ├── staging/             # Initial data cleaning and preparation
│   │   └── marts/               # Transformed business-ready data models
│   ├── dbt_project.yml          # DBT project configuration
│   └── profiles.yml             # DBT connection profiles
├── superset/
│   └── dashboard_export.json    # Exported Superset dashboard
└── README.md                    # Project documentation
```

## Components

### 1. Data Ingestion and Transformation (DBT & PostgresDB)

- Raw ticket data is loaded into PostgreSQL
- DBT models perform data cleaning and transformations:
  - Removing duplicates and handling null values
  - Standardizing date formats
  - Extracting time dimensions (Year, Month, Day)
  - Calculating performance metrics (resolution time, closure rate)
  - Creating aggregated monthly summaries

### 2. Workflow Orchestration (Apache Airflow)

- Airflow DAG orchestrates the entire pipeline:
  - CSV ingestion into PostgreSQL
  - Triggering DBT transformations
  - Validation of completed models
  - Scheduled to run daily

### 3. Data Visualization (Apache Superset)

- Interactive dashboard with key metrics:
  - Ticket volume trends over time
  - Resolution time comparisons across categories
  - Closure rates by assigned group
  - Ticket backlog by priority
  - Filterable by week, category, and priority

## Setup Instructions

### Prerequisites

- Docker and Docker Compose
- Python 3.8+
- PostgreSQL 13+
- Apache Airflow 2.0+
- Apache Superset 1.0+
- DBT 1.0+

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/yourusername/itsm-analytics.git
   cd itsm-analytics
   ```

2. **Set up PostgreSQL**

   ```bash
   # Create a database for the project
   createdb itsm_analytics
   ```

3. **Set up DBT**

   ```bash
   # Install DBT with PostgreSQL adapter
   pip install dbt-postgres

   # Configure profiles.yml with your database credentials
   cd dbt
   dbt debug  # Verify connection
   ```

4. **Set up Airflow**

   ```bash
   # Install Airflow
   pip install apache-airflow

   # Initialize Airflow database
   airflow db init

   # Create Airflow user
   airflow users create \
     --username admin \
     --password admin \
     --firstname Admin \
     --lastname User \
     --role Admin \
     --email admin@example.com

   # Start Airflow webserver and scheduler
   airflow webserver -p 8080 &
   airflow scheduler &
   ```

5. **Set up Superset**

   ```bash
   # Install Superset
   pip install apache-superset

   # Initialize Superset database
   superset db upgrade

   # Create admin user
   superset fab create-admin \
     --username admin \
     --firstname Admin \
     --lastname User \
     --email admin@example.com \
     --password admin

   # Initialize Superset
   superset init

   # Start Superset
   superset run -p 8088 --with-threads --reload --debugger
   ```

### Running the Pipeline

1. **Load sample data**

   - Place your ServiceNow ticket CSV in the `data/` directory

2. **Run DBT models**

   ```bash
   cd dbt
   dbt run
   ```

3. **Trigger Airflow DAG**

   - Access Airflow UI at http://localhost:8080
   - Enable and trigger the `itsm_pipeline` DAG

4. **View dashboards in Superset**
   - Access Superset at http://localhost:8088
   - Import the dashboard from `superset/dashboard_export.json`

## Assumptions

- The ServiceNow ticket data follows the specified schema with fields: Ticket ID, Category, Sub-Category, Priority, Created Date, Resolved Date, Status, Assigned Group, Technician, Resolution Time (Hrs), and Customer Impact.
- Date formats in the source data are consistent or can be standardized.
- The pipeline is designed to run in a development environment but can be adapted for production use.

## Future Improvements

- Implement data quality tests in DBT
- Add error handling and notifications in Airflow
- Enhance dashboard with additional metrics and visualizations
- Containerize the entire solution with Docker Compose
#
