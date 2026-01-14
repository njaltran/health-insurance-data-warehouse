# 📊 Data Marts Dashboard - Marimo App

Interactive visualization dashboard for your Health Insurance Data Warehouse data marts using marimo and BigQuery MCP connection.

## 🚀 Quick Start

### Prerequisites

1. Ensure you have authenticated with Google Cloud:
```bash
gcloud auth application-default login
```

2. Verify your BigQuery project is accessible:
```bash
gcloud config set project dw-health-insurance-bipm
```

### Installation

All dependencies are already installed in your virtual environment:
- marimo
- plotly
- google-cloud-bigquery
- pandas

### Running the Dashboard

From the project root directory:

```bash
# Activate virtual environment
source venv/bin/activate

# Run the marimo app
marimo edit data_marts_dashboard.py
```

This will:
1. Launch the marimo notebook in edit mode
2. Open your browser at `http://localhost:2718`
3. Connect to BigQuery using the MCP connection
4. Load and visualize your data marts

## 📈 Features

### 5 Data Marts Visualizations

#### 1. **Customer 360° View** (`dm_customer_360`)
- Customer segmentation sunburst chart
- Health risk score distribution
- Lifetime value analysis (premiums vs claims)
- Health metrics by customer segment

#### 2. **Health by Demographics** (`dm_health_by_demographics`)
- Health metrics by age group
- Sleep quality vs hours analysis
- Blood pressure by age and gender
- Health risk indicators

#### 3. **Insurance Profitability** (`dm_insurance_profitability`)
- Profit treemap by occupation and wealth
- Loss ratio analysis
- Financial overview by occupation
- Risk profile scatter plots

#### 4. **Sleep Health Analysis** (`dm_sleep_health_analysis`)
- Sleep metrics by disorder type
- Activity and sleep relationship
- Stress level impact on sleep
- Health correlations

#### 5. **Data Quality Dashboard** (`dm_data_quality_dashboard`)
- Data completeness by source
- Data validity metrics
- Quality metrics by dimension
- Issues summary

### Interactive Features

- **Dropdown selector**: Switch between different data marts
- **Data preview table**: View first 10 rows of selected data mart
- **Multiple visualizations**: 4 charts per data mart
- **Summary statistics**: Descriptive statistics for all columns
- **Custom SQL query builder**: Execute your own queries
- **Real-time updates**: All visualizations update when you change the selection

## 🔧 Configuration

### BigQuery Connection

The app connects to:
- **Project**: `dw-health-insurance-bipm`
- **Dataset**: `raw_dataset_data_marts`
- **Tables**:
  - `dm_customer_360`
  - `dm_health_by_demographics`
  - `dm_insurance_profitability`
  - `dm_sleep_health_analysis`
  - `dm_data_quality_dashboard`

### Customization

To modify the connection, edit the following in `data_marts_dashboard.py`:

```python
# Initialize BigQuery client
client = bigquery.Client(project='your-project-id')

# Define dataset
project_id = 'your-project-id'
dataset_id = 'your_dataset_id'
```

## 💡 Usage Examples

### 1. Viewing Customer Segmentation

1. Select "Customer 360° View" from the dropdown
2. Explore the sunburst chart showing profit contribution by segment
3. Analyze the health risk score distribution

### 2. Analyzing Insurance Profitability

1. Select "Insurance Profitability" from the dropdown
2. View the treemap showing profit by occupation and wealth bracket
3. Examine the loss ratio scatter plot

### 3. Custom Queries

1. Scroll down to the "Custom Query Builder" section
2. Enter your SQL query (example provided)
3. Click "Execute Query" to run
4. View results in the interactive table

Example custom query:
```sql
SELECT
    customer_segment,
    health_status,
    COUNT(*) as customers,
    AVG(health_risk_score) as avg_risk,
    AVG(lifetime_profit_contribution) as avg_profit
FROM `dw-health-insurance-bipm.raw_dataset_data_marts.dm_customer_360`
GROUP BY customer_segment, health_status
ORDER BY avg_profit DESC
```

## 🎨 Visualization Types

The dashboard uses various Plotly chart types:

- **Sunburst charts**: Hierarchical data visualization
- **Histograms**: Distribution analysis
- **Scatter plots**: Correlation and relationship analysis
- **Box plots**: Statistical distribution and outliers
- **Bar charts**: Comparative analysis
- **Treemaps**: Hierarchical and proportional visualization

## 🔍 Data Exploration Tips

1. **Hover over charts**: See detailed information for each data point
2. **Click legend items**: Toggle visibility of specific categories
3. **Zoom and pan**: Use Plotly's interactive features
4. **Download charts**: Export as PNG using the camera icon
5. **Table filtering**: Use the interactive table to explore raw data

## 📊 Data Refresh

To refresh the data:

1. Run your dbt pipeline to update BigQuery tables:
```bash
cd dbt_health_insurance
dbt run --select data_marts
```

2. Reload the marimo app (it queries BigQuery directly)

## 🐛 Troubleshooting

### Connection Issues

If you see authentication errors:
```bash
# Re-authenticate with Google Cloud
gcloud auth application-default login

# Verify your credentials
gcloud auth list
```

### Missing Dependencies

If you see import errors:
```bash
# Reinstall dependencies
source venv/bin/activate
pip install marimo plotly google-cloud-bigquery pandas
```

### Query Errors

If custom queries fail:
- Check the project and dataset IDs are correct
- Ensure the table name is valid
- Verify you have permissions to query BigQuery

### Port Already in Use

If port 2718 is already in use:
```bash
# Use a different port
marimo edit data_marts_dashboard.py --port 8080
```

## 🔗 Related Documentation

- [dbt Project Documentation](dbt_health_insurance/README.md)
- [Data Marts Guide](dbt_health_insurance/models/data_marts/DATA_MARTS_README.md)
- [Star Schema Documentation](dbt_health_insurance/models/star_schema/STAR_SCHEMA_README.md)
- [Main Project README](README.md)

## 🎯 Next Steps

1. **Customize visualizations**: Edit `data_marts_dashboard.py` to add your own charts
2. **Add filters**: Implement date range or category filters
3. **Create dashboards**: Combine multiple visualizations for specific use cases
4. **Export reports**: Use marimo's export features to share insights

## 📝 Technical Details

### marimo Features Used

- **Reactive UI**: Automatic updates when inputs change
- **Interactive widgets**: Dropdowns, buttons, text areas
- **Plotly integration**: Interactive charts with zoom and hover
- **Table display**: Sortable and searchable data tables
- **Markdown support**: Rich text formatting

### Performance Considerations

- Queries run directly against BigQuery (no local caching)
- Use `LIMIT` clauses for large datasets
- Pre-aggregated data marts ensure fast query performance
- Consider materializing complex queries as new views

## 🙏 Acknowledgments

Built with:
- [marimo](https://marimo.io/) - Reactive Python notebook
- [Plotly](https://plotly.com/) - Interactive visualizations
- [BigQuery](https://cloud.google.com/bigquery) - Data warehouse
- [dbt](https://www.getdbt.com/) - Data transformation

---

**Questions?** Check the main [README](README.md) or [Documentation Index](DOCUMENTATION_INDEX.md)
