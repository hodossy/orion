-- min and max human readable timestamps
SELECT to_timestamp(min(last_updated_ts)), to_timestamp(max(last_updated_ts)) FROM states;

-- get timestamp as double from the day string at the start of day (00:00:00)
SELECT EXTRACT (EPOCH FROM to_timestamp('2025-10-19', 'YYYY-MM-DD')) as _start
