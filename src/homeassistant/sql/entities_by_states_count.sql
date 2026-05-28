-- List entities by states count
SELECT 
  states.metadata_id AS id, 
  states_meta.entity_id AS entity_id,
--  date_trunc('day', to_timestamp(last_updated_ts)),
  count(*) AS count
FROM states
JOIN states_meta ON states.metadata_id=states_meta.metadata_id
-- where (states_meta.entity_id like '%2pm\_%_voltage%'
--   or states_meta.entity_id like '%2pm\_%\_power%'
--   or states_meta.entity_id like '%futes%'
-- )
GROUP BY states.metadata_id, states_meta.entity_id
ORDER BY count DESC;
