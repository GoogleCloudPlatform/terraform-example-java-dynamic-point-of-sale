CREATE TABLE labels (
    item_id STRING(36) NOT NULL,
    labels STRING(255),
    CONSTRAINT FK_items_labels FOREIGN KEY (item_id) REFERENCES items (id)
) PRIMARY KEY (item_id)