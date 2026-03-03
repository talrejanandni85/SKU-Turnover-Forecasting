# Data Dictionary — Amazon SKU Analysis

## `amazon_jan_to_sept_2024.xlsx`

This file contains Amazon order-level data for January–September 2024, exported from Amazon Seller Central. Each row represents one line item in an order.

> ⚠️ **Note:** All order IDs, SKUs, ASINs, customer locations, and product names in this file have been anonymized from the original data. Real sales figures have been lightly perturbed (±5%) to prevent reverse-engineering of proprietary business data.

| Column | Type | Description |
|---|---|---|
| `amazon-order-id` | string | Anonymized unique order identifier |
| `purchase-date` | datetime | Date and time the order was placed |
| `last-updated-date` | datetime | Last status update timestamp |
| `order-status` | string | One of: Shipped, Cancelled, Complete, Shipping |
| `fulfillment-channel` | string | Amazon (FBA) or Merchant (FBM) |
| `sales-channel` | string | Sales channel (e.g., Amazon.com) |
| `ship-service-level` | string | Shipping tier (Standard, Expedited, etc.) |
| `product-name` | string | Anonymized product listing title |
| `sku` | string | Anonymized seller SKU identifier |
| `asin` | string | Anonymized Amazon Standard ID Number |
| `item-status` | string | Item fulfillment status |
| `quantity` | integer | Units ordered |
| `currency` | string | Currency code (USD) |
| `item-price` | float | Order line revenue (lightly perturbed) |
| `item-tax` | float | Tax collected |
| `shipping-price` | float | Shipping charge to buyer |
| `shipping-tax` | float | Tax on shipping |
| `gift-wrap-price` | float | Gift wrap charge |
| `gift-wrap-tax` | float | Tax on gift wrap |
| `item-promotion-discount` | float | Discount applied via promotion |
| `ship-promotion-discount` | float | Shipping discount via promotion |
| `ship-city` | string | Anonymized destination city |
| `ship-state` | string | Destination state/province |
| `ship-postal-code` | string | Anonymized postal code |
| `ship-country` | string | Destination country code |
| `is-business-order` | boolean | Whether this was a B2B order |
| `price-designation` | string | Price type (standard, business, etc.) |

---

## `inventory_jan.xlsx` / `inventory_june.csv` / `inventory_sept.csv`

Inventory snapshot files exported from Amazon Seller Central at three points in the year.

| Column | Type | Description |
|---|---|---|
| `sku` | string | Seller SKU (matches orders table) |
| `available` | integer | Units available in FBA warehouse at snapshot date |

---

## `net_proceeds.xlsx`

Net revenue per SKU after Amazon fees (referral fees, FBA fees, etc.).

| Column | Type | Description |
|---|---|---|
| `SKU` | string | Seller SKU |
| `net_proceeds` | float | Revenue after all Amazon fees |

---

## Derived Variables (created in analysis)

| Variable | Formula | Description |
|---|---|---|
| `cogs_[month]` | `quantity × $2.30` | Cost of goods sold per month (unit cost = $2.30) |
| `avg_inventory_[window]` | `(opening_inv + closing_inv) / 2` | Average inventory for a time window |
| `turnover_[window]` | `total_units_sold / avg_inventory` | SKU Turnover Rate for a given window |
| `sales_lag_1` | `lag(total_sales, 1)` | Yesterday's total daily sales |
| `sales_lag_7` | `lag(total_sales, 7)` | Same day last week's total daily sales |
