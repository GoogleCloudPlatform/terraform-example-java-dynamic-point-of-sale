-- Copyright 2023 Google LLC
--
--  Licensed under the Apache License, Version 2.0 (the "License");
--  you may not use this file except in compliance with the License.
--  You may obtain a copy of the License at
--
--      http://www.apache.org/licenses/LICENSE-2.0
--
--  Unless required by applicable law or agreed to in writing, software
--  distributed under the License is distributed on an "AS IS" BASIS,
--  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--  See the License for the specific language governing permissions and
--  limitations under the License.

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
