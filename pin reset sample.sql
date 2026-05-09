--Filtering all pin reset data for failed login attempts:

CREATE TABLE minio.default.pin_reset_sample_2026 AS
SELECT
    mm_event_type,
    mm_start_time,
    mm_initiating_device_type,
    mm_initiating_device_value,
    mm_error_msg,
    mm_error_code,
    mm_partition_timestamp
FROM minio.default.u_al_identity
WHERE mm_error_code = 'TP40087'
  AND mm_event_type = 'CHANGE_CUSTOMER_PIN'
  AND mm_initiating_device_value IS NOT NULL
  -- Restrict to March 21 – April 20
  AND DATE(mm_partition_timestamp) BETWEEN DATE('2026-03-21') AND DATE('2026-04-20');
