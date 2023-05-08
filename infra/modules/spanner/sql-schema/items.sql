CREATE TABLE items (
  id STRING(36) NOT NULL,
  image_url STRING(255),
  name STRING(255),
  price FLOAT64,
  quantity NUMERIC,
  type STRING(255),
  version NUMERIC,
) PRIMARY KEY (id)