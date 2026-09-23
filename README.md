# Customer Retention and Repeat Purchase Analysis for E-Commerce

## Executive Summary

This project analyzes customer retention and repeat purchasing behavior using the Brazilian Olist e-commerce dataset. SQL Server was used for data preparation, quality assessment, transformation, and hypothesis-driven analysis, followed by Power BI for interactive visualization.

The analysis focuses on customers with delivered orders and examines repeat purchasing in relation to second-order timing, first-order value, product category, delivery performance, review scores, and freight burden.

Approximately 3% of customers with delivered orders are classified as repeat customers.

## Business Problem

Despite approximately 96K customers and R$13.2M in delivered revenue, only around 3% of customers with delivered orders are classified as repeat customers.

Repeat purchasing is an important component of e-commerce customer retention. This analysis investigates which customer, order, delivery, and customer-experience factors are associated with repeat purchasing.

## Business Questions

### Overall Business Performance

1. What is the overall business performance in terms of delivered orders and delivered revenue?
2. Which top 10 product categories generate the most revenue?

### Customer Retention

1. How many customers are one-time versus repeat customers?
2. How long does it take customers to place their second order?
3. How does retention change across customer cohorts over time?
4. Is repeat purchasing associated with first-order value?
5. Does first-order product category show differences in repeat rates?

### Delivery and Customer Experience

1. What proportion of delivered orders arrive early, on time, or late?
2. What is the average delivery time and delivery variance?
3. Is delivery performance associated with repeat purchasing?
4. Does review score vary with repeat purchasing?
5. Is freight burden associated with differences in repeat rates?

## Methodology

Overall methodology:

<img width="1024" height="559" alt="image" src="https://github.com/user-attachments/assets/f4b63833-8b09-42bf-b5f8-31bb13efd452" />

**Bronze:** Raw Olist data was ingested into SQL Server.

**Silver:** Data quality checks were performed for missing values, timestamp consistency, and referential integrity, followed by validation and standardization. Timestamp inconsistencies were flagged rather than discarded.

**Gold:** Business-ready fact and dimension structures were created.

**SQL Analysis:** Analytical views were developed to investigate repeat purchasing and retention.

**Power BI:** The analytical outputs were visualized through a three-page interactive dashboard.

## Skills

**SQL:** CTEs, Views, Joins, CASE, Aggregate Functions, Window Functions

**Power BI:** DAX, Power Query, Conditional Columns, Measures, Data Visualization

## Dashboard

### Executive Overview

<img width="968" height="739" alt="image" src="https://github.com/user-attachments/assets/5b6a8e2a-d6f7-4c20-ad4c-cc40ba99f7fe" />

Provides an overview of customers, delivered orders, repeat customer rate, revenue, average order value, revenue trends, order status, and customer mix.

**Repeat Customer Rate:** Percentage of customers with delivered orders who placed more than one delivered order during the analysis period.

### Customer Retention

<img width="945" height="742" alt="image" src="https://github.com/user-attachments/assets/6e0c5037-99ff-4c24-b409-b0801565ce2c" />


Analyzes customer cohorts, retention patterns, and repeat purchasing behavior.

### Delivery Performance and Customer Experience

<img width="940" height="740" alt="image" src="https://github.com/user-attachments/assets/a1953f2d-535e-44b3-b8a8-d814b0881c0d" />

Examines delivery performance and customer experience indicators and their association with repeat purchasing.

## Key Findings

- **50.5% of repeat customers with a measured second order place their second order within 30 days.**
- **Cohort analysis shows that customer retention declines as the number of months since the first purchase increases.**
- **Repeat rates differ across delivery-performance categories, with the highest observed repeat rate among customers whose orders were delivered early.**
- **Repeat rates vary across review-score groups, but the relationship is not strictly monotonic.**
- **Repeat rates vary across freight-burden bands, with the highest observed repeat rate in the 50%+ freight-to-order-value band.**

## Business Recommendations

- **Prioritize the early retention window:** Since 50.5% of repeat customers with a measured second order make their second purchase within 30 days, the marketing team could investigate retention initiatives during the early post-purchase period.
- **Investigate freight burden:** The observed differences in repeat rates across freight-burden bands should be examined further while controlling for order value, category, geography, and customer characteristics.
- **Use customer segmentation:** RFM and cohort-based segmentation could provide a more detailed view of customer retention behavior.

## Limitations

- The analysis is based on historical Olist transactional data and may not represent current e-commerce customer behavior.
- The analysis focuses on delivered orders and defines a repeat customer as a customer with more than one delivered order.
- The analysis identifies associations rather than causal relationships.
- Geography, payment details, and other customer-level factors were not included in the current analysis.
