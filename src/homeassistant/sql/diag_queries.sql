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
-- WHERE states.last_updated_ts>1760745600
GROUP BY states.metadata_id, states_meta.entity_id
ORDER BY count DESC;

-- min and max human readable timestamps
SELECT to_timestamp(min(last_updated_ts)), to_timestamp(max(last_updated_ts)) FROM states;

-- get timestamp as double from the day string at the start of day (00:00:00)
SELECT EXTRACT (EPOCH FROM to_timestamp('2025-10-19', 'YYYY-MM-DD')) as _start

-- List number of states entries by day
SELECT
  date_trunc('day', to_timestamp(last_updated_ts)),
  count(*)
FROM states
GROUP BY 1
ORDER BY 1 DESC;

-- List tables by their total size
SELECT
  table_name,
  pg_size_pretty(pg_total_relation_size(quote_ident(table_name))),
  pg_total_relation_size(quote_ident(table_name))
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY 3 desc;

-- find what eats the space of a table: replace public.tbl with the table name
-- https://stackoverflow.com/questions/62642234/index-size-after-autovacuum
SELECT l.metric, l.nr AS bytes
     , CASE WHEN is_size THEN pg_size_pretty(nr) END AS bytes_pretty
     , CASE WHEN is_size THEN nr / NULLIF(x.ct, 0) END AS bytes_per_row
FROM  (
   SELECT min(tableoid)        AS tbl      -- = 'public.tbl'::regclass::oid
        , count(*)             AS ct
        , sum(length(t::text)) AS txt_len  -- length in characters
   FROM   public.tbl t                     -- provide table name *once*
   ) x
CROSS  JOIN LATERAL (
   VALUES
     (true , 'core_relation_size'               , pg_relation_size(tbl))
   , (true , 'visibility_map'                   , pg_relation_size(tbl, 'vm'))
   , (true , 'free_space_map'                   , pg_relation_size(tbl, 'fsm'))
   , (true , 'table_size_incl_toast'            , pg_table_size(tbl))
   , (true , 'indexes_size'                     , pg_indexes_size(tbl))
   , (true , 'total_size_incl_toast_and_indexes', pg_total_relation_size(tbl))
   , (true , 'live_rows_in_text_representation' , txt_len)
   , (false, '------------------------------'   , NULL)
   , (false, 'row_count'                        , ct)
   , (false, 'live_tuples'                      , pg_stat_get_live_tuples(tbl))
   , (false, 'dead_tuples'                      , pg_stat_get_dead_tuples(tbl))
   ) l(is_size, metric, nr);
