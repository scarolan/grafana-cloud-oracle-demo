# Dashboards

This directory contains exported Grafana dashboard JSON files. Other SEs can import these directly into their Grafana Cloud instances.

## Creating Dashboards

1. Open your Grafana Cloud instance
2. Use **Grafana Assistant** to build dashboards for your demo scenario
3. Iterate with the assistant until the dashboard tells your demo story

## Exporting Dashboards

1. Open the dashboard in Grafana
2. Click **Share** (top-right)
3. Select **Export**
4. Click **Save to file**
5. Save the JSON file to this directory with a descriptive name:
   ```
   dashboards/oracle-overview.json
   dashboards/wait-time-analysis.json
   ```

## Importing Dashboards

To import a dashboard from this repo into your Grafana Cloud instance:

1. Open Grafana Cloud
2. Go to **Dashboards** > **New** > **Import**
3. Click **Upload dashboard JSON file**
4. Select the `.json` file from this directory
5. Choose your Prometheus and Loki data sources when prompted
6. Click **Import**

## Dashboard Inventory

<!-- Update this table as you add dashboards -->
| File | Description |
|------|-------------|
| `oracle-overview.json` | Oracle Database overview: status, sessions, processes, activity metrics, tablespace usage, wait time analysis, blocking sessions, slow queries, error logs, dual collection method comparison |
