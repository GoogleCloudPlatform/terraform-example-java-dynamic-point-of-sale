CREATE TABLE payments (
  payment_id STRING(36) NOT NULL,
  unitList STRING(1024),
  type STRING(1024),
  paidAmount NUMERIC,
  version INT64,
) PRIMARY KEY(payment_id)
