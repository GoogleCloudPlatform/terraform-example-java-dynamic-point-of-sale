CREATE TABLE payment_units (
  id STRING(36) NOT NULL,
  item_id STRING(36),
  name STRING(255),
  quantity FLOAT64,
  total_cost FLOAT64,
  version NUMERIC,
) PRIMARY KEY (id)