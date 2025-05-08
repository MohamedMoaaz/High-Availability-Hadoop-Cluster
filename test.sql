CREATE EXTERNAL TABLE test (
    passenger_id STRING,
    national_id STRING,
    first_name STRING,
    last_name STRING,
    date_of_birth DATE,
    nationality STRING,
    email STRING,
    phone_number STRING,
    gender STRING,
    status STRING,
    frequent_flyer_number STRING,
    frequent_flyer_tier STRING,
    effective_date DATE,
    expiry_date DATE,
    is_current BOOLEAN,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/hive/warehouse/staging/source/passengers'
TBLPROPERTIES ("skip.header.line.count"="1");