{\rtf1\ansi\ansicpg1252\cocoartf2870
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\paperw11900\paperh16840\margl1440\margr1440\vieww29200\viewh18460\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 # E-commerce Sales Analytics\
\
An end-to-end e-commerce sales analytics project using Python, PostgreSQL, SQL, and Tableau. The project analyzes transaction-level sales data to identify revenue trends, product performance, customer behavior, geographic performance, and cancellation patterns.\
\
## Business Scenario\
\
An online retailer wants to understand its sales performance and customer behavior. The objective is to transform raw transaction data into actionable business insights through data cleaning, SQL analysis, and an interactive Tableau dashboard.\
\
## Dataset\
\
The project uses the UCI Online Retail dataset.\
\
- Source: UCI Machine Learning Repository\
- Dataset: Online Retail\
- Period: December 2010 \'96 December 2011\
- Original records: 541,909\
- Countries: 38\
- Data includes invoices, products, quantities, prices, customers, dates, and countries.\
\
Source:\
https://archive.ics.uci.edu/dataset/352/online%2Bretail\
\
## Tools & Technologies\
\
- Python\
- Pandas\
- PostgreSQL\
- SQL\
- DBeaver\
- Tableau Public\
- Excel\
\
## Project Workflow\
\
Raw Data\
\uc0\u8595 \
Python Data Audit & Cleaning\
\uc0\u8595 \
PostgreSQL\
\uc0\u8595 \
SQL Analysis\
\uc0\u8595 \
CSV Exports\
\uc0\u8595 \
Tableau Dashboard\
\uc0\u8595 \
Business Insights\
\
## Data Cleaning & Preparation\
\
The original dataset contained 541,909 records.\
\
The following data-quality checks and transformations were performed:\
\
- Identified missing values\
- Identified exact duplicate records\
- Removed 5,268 exact duplicate rows\
- Classified transactions into sales, cancellations, and adjustments\
- Validated cancellation indicators against invoice numbers\
- Checked negative quantities and prices\
- Identified accounting and operational adjustments\
- Created transaction-level revenue using:\
\
  `Revenue = Quantity \'d7 UnitPrice`\
\
After deduplication, the dataset contained 536,641 records.\
\
For sales analysis, only valid sales transactions were included. Customer-level analysis excluded transactions without a CustomerID.\
\
Unusual high-volume transactions were retained but treated as potential anomalies rather than automatically removing them.\
\
## Key Performance Metrics\
\
| Metric | Value |\
|---|---:|\
| Sales Revenue | \'a310.63M |\
| Orders | 19,959 |\
| Units Sold | 5.57M |\
| Identified Customers | 4,338 |\
| Products | 3,921 |\
| Average Order Value | \'a3532.64 |\
\
## Key Analysis\
\
### 1. Monthly Sales Performance\
\
Monthly revenue was analyzed to identify changes in sales activity throughout the dataset period.\
\
November 2011 recorded the highest monthly revenue:\
\
\'a31.50M\
\
February 2011 recorded the lowest full-month revenue:\
\
\'a3522.55K\
\
December 2011 contains only partial-month data through December 9 and therefore should not be compared directly with complete months.\
\
### 2. Product Performance\
\
Products were analyzed using:\
\
- Revenue\
- Units sold\
- Number of orders\
- Revenue per order\
- Revenue per unit\
\
The highest-revenue merchandise product was:\
\
REGENCY CAKESTAND 3 TIER \'97 \'a3174,156.54\
\
Some products generated high revenue because of unusually large individual transactions. For example, PAPER CRAFT, LITTLE BIRDIE generated \'a3168,469.60 from a single order containing 80,995 units.\
\
These transactions were retained in the analysis and flagged as potential anomalies rather than removed.\
\
### 3. Customer Analysis\
\
Customer revenue and purchasing behavior were analyzed using:\
\
- Total revenue\
- Number of orders\
- Units purchased\
- Number of products purchased\
- Average order value\
- Revenue concentration\
- Repeat vs one-time purchasing\
\
Among customers with identified CustomerIDs:\
\
- 2,845 were repeat customers\
- 1,493 were one-time customers\
- Repeat customers generated 93.09% of identified-customer revenue\
\
Customer revenue was also segmented to understand the contribution of high-value customers.\
\
Customers generating \'a310,000 or more represented approximately 2.4% of identified customers but accounted for 41.07% of identified-customer revenue.\
\
### 4. Geographic Analysis\
\
Sales performance was analyzed across 38 countries.\
\
The United Kingdom generated:\
\
- \'a38.99M revenue\
- 18,018 orders\
- 84.57% of total sales revenue\
\
Other significant markets included the Netherlands, EIRE, Germany, France, and Australia.\
\
Country-level Average Order Value was also calculated, but interpreted alongside order volume because markets with a small number of orders can produce unusually high AOV values.\
\
### 5. Cancellation Analysis\
\
Cancellation activity was analyzed using:\
\
- Number of cancelled transactions\
- Cancelled units\
- Cancellation rate\
- Monthly cancellation trends\
\
There were 9,251 cancelled transactions.\
\
The transaction cancellation rate was approximately:\
\
1.76%\
\
Cancelled units represented approximately:\
\
4.95%\
\
of units sold.\
\
The absolute transaction value associated with cancellations was compared with sales revenue separately; it was not treated as directly equivalent to lost revenue.\
\
## Tableau Dashboard\
\
The Tableau dashboard provides an interactive overview of the analysis.\
\
Dashboard components include:\
\
- Revenue KPI\
- Orders KPI\
- Units Sold KPI\
- Customer KPI\
- Average Order Value KPI\
- Monthly Revenue Trend\
- Top 10 Products by Revenue\
- Top 10 Countries by Revenue\
- Repeat vs One-time Customers\
- Monthly Cancellation Rate\
\
## Dashboard Preview\
\
The completed dashboard is designed to provide a management-level overview of sales performance while allowing users to identify product, customer, geographic, and cancellation trends.\
\
## SQL Analysis\
\
The PostgreSQL analysis includes queries for:\
\
- Overall sales performance\
- Monthly revenue\
- Month-over-month growth\
- Product performance\
- Customer revenue\
- Customer revenue concentration\
- Repeat vs one-time customers\
- Country performance\
- Product order frequency\
- Average order value\
- Cancellation analysis\
- Cancellation trends\
- Customer revenue segmentation\
\
The SQL queries are available in:\
\
`sql/ecommerce_analysis.sql`\
\
## Project Structure\
\
```text\
Ecommerce-Sales-Analytics/\
\uc0\u9474 \
\uc0\u9500 \u9472 \u9472  data/\
\uc0\u9474    \u9492 \u9472 \u9472  Online Retail.xlsx\
\uc0\u9474 \
\uc0\u9500 \u9472 \u9472  dashboard/\
\uc0\u9474    \u9492 \u9472 \u9472  Ecommerce_Sales_Analytics.twbx\
\uc0\u9474 \
\uc0\u9500 \u9472 \u9472  notebooks/\
\uc0\u9474 \
\uc0\u9500 \u9472 \u9472  reports/\
\uc0\u9474 \
\uc0\u9500 \u9472 \u9472  sql/\
\uc0\u9474    \u9492 \u9472 \u9472  ecommerce_analysis.sql\
\uc0\u9474 \
\uc0\u9492 \u9472 \u9472  README.md}