CREATE TABLE minio.default.ato_pin_momo_features_2026 AS
WITH pin_reset AS (
    SELECT 
        mm_initiating_device_value AS msisdn,
        mm_start_time AS pin_reset_time
    FROM minio.default.pin_reset_sample_2026
),
momo_txn AS (
    SELECT DISTINCT
        ord_initiating_device_value AS msisdn,
        ord_begintime AS txn_time,
        ord_procstate,
        tx_actual_amount
    FROM minio.default.momo_txn_sample_2026
    WHERE ord_procstate IN ('Completed','Declined','Cancelled')
)
SELECT 
    pr.msisdn,
    pr.pin_reset_time,

    -- First transaction after PIN reset
    MIN(mt.txn_time) FILTER (WHERE mt.txn_time > pr.pin_reset_time) AS first_txn_time,
    FIRST_VALUE(mt.tx_actual_amount) OVER (
        PARTITION BY pr.msisdn 
        ORDER BY mt.txn_time
    ) AS first_tx_amt_aftr_pr,
    FIRST_VALUE(mt.ord_procstate) OVER (
        PARTITION BY pr.msisdn 
        ORDER BY mt.txn_time
    ) AS first_tx_status_aftr_pr,

    -- Counts within 6h, 24h, 48h
    COUNT(*) FILTER (WHERE mt.ord_procstate='Completed' AND mt.txn_time BETWEEN pr.pin_reset_time AND pr.pin_reset_time + INTERVAL '6' hour) AS comp_tx_count_6h_pr,
    COUNT(*) FILTER (WHERE mt.ord_procstate='Completed' AND mt.txn_time BETWEEN pr.pin_reset_time AND pr.pin_reset_time + INTERVAL '24' hour) AS comp_tx_count_24h_pr,
    COUNT(*) FILTER (WHERE mt.ord_procstate='Completed' AND mt.txn_time BETWEEN pr.pin_reset_time AND pr.pin_reset_time + INTERVAL '48' hour) AS comp_tx_count_48h_pr,

    COUNT(*) FILTER (WHERE mt.ord_procstate='Declined' AND mt.txn_time BETWEEN pr.pin_reset_time AND pr.pin_reset_time + INTERVAL '6' hour) AS decl_tx_count_6h_pr,
    COUNT(*) FILTER (WHERE mt.ord_procstate='Declined' AND mt.txn_time BETWEEN pr.pin_reset_time AND pr.pin_reset_time + INTERVAL '24' hour) AS decl_tx_count_24h_pr,
    COUNT(*) FILTER (WHERE mt.ord_procstate='Declined' AND mt.txn_time BETWEEN pr.pin_reset_time AND pr.pin_reset_time + INTERVAL '48' hour) AS decl_tx_count_48h_pr,

    COUNT(*) FILTER (WHERE mt.ord_procstate='Cancelled' AND mt.txn_time BETWEEN pr.pin_reset_time AND pr.pin_reset_time + INTERVAL '6' hour) AS cancel_tx_count_6h_pr,
    COUNT(*) FILTER (WHERE mt.ord_procstate='Cancelled' AND mt.txn_time BETWEEN pr.pin_reset_time AND pr.pin_reset_time + INTERVAL '24' hour) AS cancel_tx_count_24h_pr,
    COUNT(*) FILTER (WHERE mt.ord_procstate='Cancelled' AND mt.txn_time BETWEEN pr.pin_reset_time AND pr.pin_reset_time + INTERVAL '48' hour) AS cancel_tx_count_48h_pr,

    -- Amount totals
    SUM(mt.tx_actual_amount) FILTER (WHERE mt.ord_procstate='Completed' AND mt.txn_time BETWEEN pr.pin_reset_time AND pr.pin_reset_time + INTERVAL '24' hour) AS comp_tx_amt_24h_pr,
    SUM(mt.tx_actual_amount) FILTER (WHERE mt.ord_procstate='Declined' AND mt.txn_time BETWEEN pr.pin_reset_time AND pr.pin_reset_time + INTERVAL '6' hour) AS decl_tx_amt_6h_pr,
    SUM(mt.tx_actual_amount) FILTER (WHERE mt.ord_procstate='Declined' AND mt.txn_time BETWEEN pr.pin_reset_time AND pr.pin_reset_time + INTERVAL '24' hour) AS decl_tx_amt_24h_pr,

    -- History before reset
    COUNT(*) FILTER (WHERE mt.ord_procstate='Completed' AND mt.txn_time < pr.pin_reset_time) AS count_comp_tx_before_pr,
    COUNT(*) FILTER (WHERE mt.ord_procstate='Declined' AND mt.txn_time < pr.pin_reset_time) AS count_decl_tx_before_pr,
    COUNT(*) FILTER (WHERE mt.ord_procstate='Cancelled' AND mt.txn_time < pr.pin_reset_time) AS count_cancel_tx_before_pr

FROM pin_reset pr
LEFT JOIN momo_txn mt
    ON pr.msisdn = mt.msisdn
GROUP BY pr.msisdn, pr.pin_reset_time;


