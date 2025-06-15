SELECT states.metadata_id as id, states_meta.entity_id as entity_id, count(*) as count
from states
join states_meta on states.metadata_id=states_meta.metadata_id
-- where (states_meta.entity_id like '%2pm\_%_voltage%'
--   or states_meta.entity_id like '%2pm\_%\_power%'
--   or states_meta.entity_id like '%futes%'
-- )
group by states.metadata_id, states_meta.entity_id
order by count desc;


-- SELECT to_timestamp(min(last_updated_ts)), to_timestamp(max(last_updated_ts)) from states;

-- SELECT
--   states_meta.*
-- from states_meta
-- where (
--      states_meta.entity_id like '%2pm\_%\_voltage%'
--   or states_meta.entity_id like '%2pm\_%\_power%'
--   or states_meta.entity_id like '%futes%'
-- )

select
  table_name,
  pg_size_pretty(pg_total_relation_size(quote_ident(table_name))),
  pg_total_relation_size(quote_ident(table_name))
from information_schema.tables
where table_schema = 'public'
order by 3 desc;
