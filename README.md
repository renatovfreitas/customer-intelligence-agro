# Customer Intelligence for Agricultural Machinery Retail

## Overview

Agricultural machinery retailers often accumulate years of transactional sales data without transforming it into strategic business knowledge.

This project aims to build a Customer Intelligence solution capable of transforming raw sales data into actionable insights that support customer segmentation, customer retention, commercial planning, profitability analysis, and business decision-making.

The project is based on real sales data from an agricultural machinery retailer in Brazil.

---

## Business Problem

The company has a large customer base and thousands of historical sales records. However, it lacks a structured process to answer questions such as:

* Who are the company's most valuable customers?
* Which customers are becoming inactive?
* Which customers should receive commercial attention?
* Which product groups generate the highest profitability?
* How can sales opportunities be identified using historical data?

This project aims to answer these questions through Business Intelligence techniques.

---

## Project Objectives

* Identify the company's most valuable customers.
* Segment customers based on purchasing behavior.
* Analyze customer profitability.
* Detect inactive and high-potential customers.
* Analyze product categories and customer buying behavior.
* Generate business recommendations supported by data.
* Build an interactive Business Intelligence dashboard.

---

## Technologies

* MySQL
* SQL
* Git
* GitHub
* Power BI *(coming soon)*
* Python *(coming soon)*

---

## Dataset

The project uses approximately **24,000 sales item records**.

Each row represents a single product sold within a sales transaction.

Current columns include:

* Sale Item ID
* Sale Control Number
* Sale Date
* Customer Name
* CPF/CNPJ
* Product ID
* Product Name
* Product Subgroup
* Product Group
* Unit Sale Price
* Quantity
* Unit Cost

---

## Current Scope

This first version focuses exclusively on **product sales**.

Service operations such as mechanics, welding and lathe services are intentionally excluded from the scope to maintain project focus.

---

## Business Process

Business Understanding

↓

Data Extraction

↓

Data Cleaning

↓

Feature Engineering

↓

Customer Master Table

↓

Exploratory Data Analysis

↓

Customer Segmentation

↓

Business Insights

↓

Interactive Dashboard

↓

Business Recommendations

---

## Current Findings

* Duplicate customer registrations significantly changed customer rankings.
* Customer consolidation using **Customer Name + CPF/CNPJ** produced more reliable business results.
* Some customers with good historical performance have been inactive for more than 300 days.
* Customer frequency alone is not sufficient to determine customer value.
* Product categories were reorganized into macro groups to improve business analysis.

---

## Repository Structure

```text
customer-intelligence-agro/

docs/
sql/
data/
README.md
```

---

## Future Improvements

* Customer Segmentation Model
* RFM Analysis
* Customer Lifetime Value (CLV)
* Cross-selling Analysis
* Market Basket Analysis
* Predictive Models
* Interactive Power BI Dashboard

---

## Author

Developed by Renato Viveiros as part of a Business Intelligence portfolio focused on solving real business problems using data.


## Data Quality Notes

The customer names are standardized.

Some products may have different Product IDs while representing the same commercial item. This issue will be investigated during the data cleaning stage.
