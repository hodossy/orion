/**
 * This script downsamples my status data to a reasonable level,
 * as aggregating helpers are updated at each component update,
 * effectively doubling the number of rows inserted.
**/
DO $$ BEGIN RAISE NOTICE '[%] Preparing metadata...', NOW(); END$$;

------------------------------------------------------------
------------ CREATE TIME RANGE DEFINITION TABLE ------------
------------------------------------------------------------

DROP TABLE IF EXISTS _timeref;
CREATE TEMPORARY TABLE IF NOT EXISTS _timeref as (
  SELECT
    EXTRACT (EPOCH FROM to_timestamp('2025-10-19', 'YYYY-MM-DD')) as _start
);

DROP TABLE IF EXISTS _timerange;
CREATE TEMPORARY TABLE IF NOT EXISTS _timerange as (
  SELECT
    _timeref._start as _start,
    _timeref._start + 3600 * 24 as _end,
	_timeref._start - 900 as _test_start,
    _timeref._start + 3600 as _test_end
  FROM _timeref
);

DO $$ BEGIN RAISE NOTICE '[%] Selected timerange: % - %', NOW(), (SELECT to_timestamp(_start) FROM _timerange), (SELECT to_timestamp(_end) FROM _timerange); END$$;

------------------------------------------------------------
--------- SELECT ENTITIES WITH TOO FREQUENT STATES ---------
------------------------------------------------------------

DROP TABLE IF EXISTS _states_meta;
CREATE TEMPORARY TABLE IF NOT EXISTS _states_meta  AS (
  SELECT
    states_meta.*
  from states_meta
  where (
       states_meta.entity_id like '%2pm\_%\_voltage%'
    or states_meta.entity_id like '%2pm\_%\_power%'
    or states_meta.entity_id like '%2pm\_%\_total\_daily\_energy%'
    or states_meta.entity_id like '%futes%'
  )
);

DO $$ BEGIN RAISE NOTICE '[%] Selected entities: %', NOW(), (SELECT string_agg(entity_id, ', ') FROM _states_meta); END$$;

DO $$ BEGIN RAISE NOTICE '[%] Done.', NOW(); END$$;

DO $$ BEGIN RAISE NOTICE '[%] Selecting data to prune...', NOW(); END$$;

------------------------------------------------------------
-- CREATE TIME BUCKETS FOR SELECTED ENTITIES AND INTERVAL --
------------------------------------------------------------

DROP TABLE IF EXISTS _states;
CREATE TEMPORARY TABLE IF NOT EXISTS _states AS (
  SELECT 
    states.state_id,
	states.old_state_id,
    states.metadata_id,
    states.last_updated_ts,
    date_bin('1 minute', to_timestamp(states.last_updated_ts), TIMESTAMP '2001-01-01') as last_updated_ts_bucket,
    _states_meta.entity_id as meta_entity_id
  from states
  INNER JOIN _states_meta ON states.metadata_id = _states_meta.metadata_id
  where (
        states.last_updated_ts >= (SELECT _start FROM _timerange)
	AND states.last_updated_ts < (SELECT _end FROM _timerange)
  )
);

DO $$ BEGIN RAISE NOTICE '[%] Done. Selected % entries', NOW(), (SELECT count(*) FROM _states); END$$;

DO $$ BEGIN RAISE NOTICE '[%] Selecting rows to keep...', NOW(); END$$;

------------------------------------------------------------
-------- KEEP LAST VALUE FOR EACH ENTITY AND BUCKET --------
------------------------------------------------------------

DROP TABLE IF EXISTS _kept_states;
CREATE TEMPORARY TABLE IF NOT EXISTS _kept_states AS (
  SELECT DISTINCT ON (last_updated_ts_bucket, metadata_id)
    _states.*
  from _states 
  ORDER BY metadata_id, last_updated_ts_bucket asc, last_updated_ts desc
);

------------------------------------------------------------
---------------- COLLECT FIRST DELETED ROWS ----------------
------------------------------------------------------------

DROP TABLE IF EXISTS _first_dropped_rows;
CREATE TEMPORARY TABLE IF NOT EXISTS _first_dropped_rows AS (
  SELECT DISTINCT ON (metadata_id)
    _states.*
  from _states 
  ORDER BY metadata_id, last_updated_ts
);

------------------------------------------------------------
--------------- COLLECT UPDATED OLD STATE IDS --------------
------------------------------------------------------------

WITH _kept_states_lag_cte (state_id, prev_state_id) AS (
  SELECT 
    state_id,
    LAG(state_id, 1) OVER (PARTITION BY metadata_id ORDER BY last_updated_ts_bucket) prev_state_id
  FROM _kept_states
)
UPDATE _kept_states 
SET old_state_id = _kept_states_lag_cte.prev_state_id
FROM _kept_states_lag_cte
WHERE _kept_states.state_id = _kept_states_lag_cte.state_id;

UPDATE _kept_states 
SET old_state_id = _first_dropped_rows.old_state_id
FROM _first_dropped_rows
WHERE 
      _kept_states.old_state_id IS NULL 
  AND _kept_states.metadata_id = _first_dropped_rows.metadata_id;

DO $$ BEGIN RAISE NOTICE '[%] Done. Selected % rows', NOW(), (SELECT count(*) FROM _kept_states); END$$;

/*
------------------------------------------------------------
------- CREATE A TEST DATABASE FOR CHECKING RESULTS --------
------------------------------------------------------------

DO $$ BEGIN RAISE NOTICE '[%] Setting up test database', NOW(); END$$;

DROP TABLE IF EXISTS _states_test;
CREATE TEMPORARY TABLE IF NOT EXISTS _states_test AS (
  SELECT 
    *
  FROM states
  where (
        states.last_updated_ts >= (SELECT _test_start FROM _timerange)
	AND states.last_updated_ts < (SELECT _test_end FROM _timerange)
  )
);

UPDATE _states_test
SET old_state_id = NULL
WHERE _states_test.old_state_id NOT IN (SELECT state_id FROM _states_test);

ALTER TABLE _states_test ADD
  CONSTRAINT _states_test_pkey PRIMARY KEY (state_id);
ALTER TABLE _states_test ADD
  CONSTRAINT _states_test_old_state_id_fkey FOREIGN KEY (old_state_id)
    REFERENCES _states_test (state_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;
CREATE INDEX IF NOT EXISTS ix_states_test_old_state_id
    ON _states_test USING btree
    (old_state_id ASC NULLS LAST);

DO $$ BEGIN RAISE NOTICE '[%] Done. Test DB size: %', NOW(), (SELECT count(*) FROM _states_test); END$$;

DO $$ BEGIN RAISE NOTICE '[%] Updating old_state_ids of test data...', NOW(); END$$;

UPDATE _states_test
SET old_state_id = _kept_states.old_state_id
FROM _kept_states
WHERE _states_test.state_id = _kept_states.state_id;

DO $$ BEGIN RAISE NOTICE '[%] Done.', NOW(); END$$;

DO $$ BEGIN RAISE NOTICE '[%] Deleting unnecessary data...', NOW(); END$$;

DELETE 
FROM _states_test
WHERE (
      _states_test.last_updated_ts >= (SELECT _start FROM _timerange)
  AND _states_test.last_updated_ts < (SELECT _end FROM _timerange)
  AND _states_test.metadata_id IN (SELECT metadata_id FROM _states_meta)
  AND _states_test.state_id NOT IN (SELECT state_id FROM _kept_states)
);

DO $$ BEGIN RAISE NOTICE '[%] Done.', NOW(); END$$;

SELECT * FROM _states_test ORDER BY metadata_id, last_updated_ts;
*/

------------------------------------------------------------
-------- UPDATE KEPT ROWS WITH PROPER OLD STATE ID ---------
------------------------------------------------------------

DO $$ BEGIN RAISE NOTICE '[%] Updating old_state_ids of test data...', NOW(); END$$;

UPDATE states
SET old_state_id = _kept_states.old_state_id
FROM _kept_states
WHERE states.state_id = _kept_states.state_id;

DO $$ BEGIN RAISE NOTICE '[%] Done.', NOW(); END$$;

------------------------------------------------------------
-------- DELETE ALL OTHER STATES IN GIVEN INTERVAL ---------
------------------------------------------------------------

DO $$ BEGIN RAISE NOTICE '[%] Deleting unnecessary data...', NOW(); END$$;

DELETE 
FROM states
WHERE (
      states.last_updated_ts >= (SELECT _start FROM _timerange)
  AND states.last_updated_ts < (SELECT _end FROM _timerange)
  AND states.metadata_id IN (SELECT metadata_id FROM _states_meta)
  AND states.state_id NOT IN (SELECT state_id FROM _kept_states)
);

