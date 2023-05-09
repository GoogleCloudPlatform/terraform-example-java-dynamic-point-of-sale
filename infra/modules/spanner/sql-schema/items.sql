CREATE TABLE items (
  item_id STRING(36) NOT NULL,
  name STRING(1024),
  type STRING(1024),
  price NUMERIC,
  imageUrl STRING(1024),
  quantity INT64,
  labels ARRAY<STRING(1024)>,
  version INT64,
) PRIMARY KEY(item_id)
