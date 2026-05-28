-- List number of states entries by day
SELECT
  date_trunc('day', to_timestamp(last_updated_ts)),
  count(*)
FROM states
WHERE states.last_updated_ts>1760745600
GROUP BY 1
ORDER BY 1 DESC;
