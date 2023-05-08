CREATE TABLE payments (
  id STRING(36) NOT NULL,
  paid_amount FLOAT64,
  type INT64,
  version NUMERIC,
) PRIMARY KEY (id)