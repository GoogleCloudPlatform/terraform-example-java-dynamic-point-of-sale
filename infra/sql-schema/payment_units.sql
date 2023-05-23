CREATE TABLE payment_units (
  payment_id STRING(36) NOT NULL,
  payment_unit_id STRING(36) NOT NULL,
  item_id STRING(36) NOT NULL,
  name STRING(1024),
  quantity NUMERIC,
  totalcost NUMERIC,
  version INT64,
) PRIMARY KEY(payment_id, payment_unit_id),
INTERLEAVE IN PARENT payments ON DELETE NO ACTION
