CREATE TABLE payments_unit_list (
    payment_id STRING(36) NOT NULL,
    unit_list_id STRING(36) NOT NULL,
    CONSTRAINT FK_payments FOREIGN KEY (payment_id) REFERENCES payments (id),
    CONSTRAINT FK_payment_units FOREIGN KEY (unit_list_id) REFERENCES payment_units (id)
) PRIMARY KEY (payment_id)