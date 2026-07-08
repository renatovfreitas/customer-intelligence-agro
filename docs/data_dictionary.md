# Data Dictionary

| Column | Description | Notes |
|---|---|---|
| sale_item_id | Unique identifier of each sold item | Primary key of the sales table |
| sale_control | Sale transaction number | Groups multiple items into a single sale |
| sale_date | Date of the sale | Date format |
| customer_name | Customer name | Already standardized |
| product_id | Unique identifier of the product | Foreign key to the product catalog |
| product_name | Product description | Some identical products may have different Product IDs |
| product_group | Product subgroup | Reliable, but may be too granular |
| unit_sale_price | Unit selling price | Used to calculate revenue |
| quantity | Quantity sold | Used to calculate revenue and cost |
| unit_cost | Unit cost | Confirmed as unit cost |
