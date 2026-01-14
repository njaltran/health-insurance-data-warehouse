# 🎯 Data Marts Dashboard - Quick Start

## ✅ Setup Complete!

Your marimo dashboard is ready to visualize your data marts!

## 🚀 Access the Dashboard

The dashboard is currently running at:

**URL**: http://localhost:2718?access_token=QEMCKxaScAB4mOoXQF_8Hg

Simply open this URL in your browser to start exploring your data!

## 📊 What You Can Do

### 1. Select a Data Mart
Use the dropdown menu to choose from 5 different data marts:
- **Customer 360° View** - Complete customer profiles with health metrics
- **Health by Demographics** - Population health analysis
- **Insurance Profitability** - Financial performance metrics
- **Sleep Health Analysis** - Sleep patterns and correlations
- **Data Quality Dashboard** - Data quality monitoring

### 2. Explore Interactive Visualizations
Each data mart includes 4 custom visualizations:
- Sunburst charts for hierarchical data
- Scatter plots for correlations
- Bar charts for comparisons
- Box plots for distributions

### 3. View Data Tables
- See preview of the first 10 rows
- View complete summary statistics
- All tables are interactive and sortable

### 4. Run Custom SQL Queries
Scroll to the "Custom Query Builder" section to:
- Write your own SQL queries
- Execute them against BigQuery
- View results in interactive tables

## 🔧 Example Queries

### Get Top 10 Profitable Customers
```sql
SELECT
    PersonID,
    customer_segment,
    lifetime_profit_contribution,
    health_risk_score,
    years_as_customer
FROM `dw-health-insurance-bipm.raw_dataset_data_marts.dm_customer_360`
ORDER BY lifetime_profit_contribution DESC
LIMIT 10
```

### Analyze Health Metrics by Age Group
```sql
SELECT
    age_group,
    gender,
    AVG(avg_heart_rate_bpm) as avg_heart_rate,
    AVG(avg_blood_oxygen_pct) as avg_blood_oxygen,
    AVG(avg_sleep_hours) as avg_sleep
FROM `dw-health-insurance-bipm.raw_dataset_data_marts.dm_health_by_demographics`
GROUP BY age_group, gender
ORDER BY age_group
```

### Find Most Profitable Insurance Segments
```sql
SELECT
    occupational_category,
    wealth_bracket,
    insurance_status,
    net_profit,
    loss_ratio_pct,
    unique_customers
FROM `dw-health-insurance-bipm.raw_dataset_data_marts.dm_insurance_profitability`
WHERE net_profit > 0
ORDER BY net_profit DESC
LIMIT 20
```

## 🎨 Dashboard Features

### Interactive Charts
- **Hover**: See detailed data points
- **Click**: Toggle legend items on/off
- **Zoom**: Use mouse wheel or click-drag
- **Pan**: Drag to move around zoomed charts
- **Download**: Click camera icon to export as PNG

### Reactive Updates
- Changes to dropdown automatically update all visualizations
- No need to refresh the page
- Real-time query execution

### Data Exploration
- Sort table columns by clicking headers
- View descriptive statistics
- Explore data distributions and patterns

## 📁 Files Created

1. **data_marts_dashboard.py** - Main marimo app
2. **MARIMO_DASHBOARD_README.md** - Complete documentation
3. **DASHBOARD_QUICK_START.md** - This file

## 🛑 Stopping the Dashboard

When you're done, stop the dashboard:

```bash
# Find the marimo process
ps aux | grep marimo

# Kill the process (use the PID from above)
kill <PID>
```

Or restart it anytime:

```bash
source venv/bin/activate
marimo edit data_marts_dashboard.py
```

## 🐛 Troubleshooting

### Can't Access the Dashboard?
- Make sure the URL includes the access token
- Check that port 2718 is not blocked by firewall
- Verify the marimo process is still running

### Authentication Errors?
```bash
gcloud auth application-default login
```

### Data Not Loading?
- Check your BigQuery project is set correctly
- Verify the dataset `raw_dataset_data_marts` exists
- Ensure you have permissions to query BigQuery

## 📚 Learn More

- **Full Documentation**: [MARIMO_DASHBOARD_README.md](MARIMO_DASHBOARD_README.md)
- **Data Marts Guide**: [dbt_health_insurance/models/data_marts/DATA_MARTS_README.md](dbt_health_insurance/models/data_marts/DATA_MARTS_README.md)
- **Main Project**: [README.md](README.md)

## 🎯 Next Steps

1. **Explore the visualizations** - Try each data mart
2. **Run custom queries** - Test the example queries above
3. **Customize the dashboard** - Edit `data_marts_dashboard.py` to add your own charts
4. **Share insights** - Export charts and share with your team

---

**Built with marimo + BigQuery MCP + dbt 5-Layer Data Warehouse**

Enjoy exploring your data! 🚀
