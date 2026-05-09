CREATE TABLE minio.default.momo_txn_sample_2026 AS
SELECT DISTINCT
    REPLACE(ord_initiating_device_value, '+', '') AS msisdn,
    ord_begintime AS txn_time,   -- keep full timestamp
    ord_procstate,
    tx_actual_amount,
    ord_receiver_identifier_value AS receiver
FROM minio.default.u_mm_transaction
WHERE ord_initiating_device_value IS NOT NULL
    AND ord_procstate IN ('Completed','Declined','Cancelled')
  AND DATE(ord_begintime) BETWEEN DATE('2026-03-21') AND DATE('2026-04-20');
