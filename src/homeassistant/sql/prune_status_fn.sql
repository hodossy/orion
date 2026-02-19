CREATE FUNCTION prune_status(start_date TEXT, days INT DEFAULT 1, entity_regex TEXT[] DEFAULT ARRAY['%2pm\_%\_voltage%','%2pm\_%\_current%','%2pm\_%\_power%','%2pm\_%\_total\_daily\_energy%','%futes%'], bin_size TEXT DEFAULT '1 minute') RETURNS INT AS $$
DECLARE
    rows_deleted INT;
BEGIN
  BEGIN
    RAISE NOTICE '[%] Preparing metadata...', NOW();
  END;

  ------------------------------------------------------------
  ------------ CREATE TIME RANGE DEFINITION TABLE ------------
  ------------------------------------------------------------

  CREATE TEMPORARY TABLE _timeref as (
    SELECT
      EXTRACT (EPOCH FROM to_timestamp(start_date, 'YYYY-MM-DD')) as _start
  );

  CREATE TEMPORARY TABLE _timerange as (
    SELECT
      _timeref._start as _start,
      _timeref._start + 3600 * 24 * days as _end
    FROM _timeref
  );

  BEGIN
    RAISE NOTICE '[%] Selected timerange: % - %', NOW(), (SELECT to_timestamp(_start) FROM _timerange), (SELECT to_timestamp(_end) FROM _timerange);
  END;

  ------------------------------------------------------------
  --------- SELECT ENTITIES WITH TOO FREQUENT STATES ---------
  ------------------------------------------------------------

  CREATE TEMPORARY TABLE _states_meta  AS (
    SELECT
      states_meta.*
    from states_meta
    where states_meta.entity_id like ANY (entity_regex)
  );

  BEGIN
    RAISE NOTICE '[%] Selected entities: %', NOW(), (SELECT string_agg(entity_id, ', ') FROM _states_meta);
    RAISE NOTICE '[%] Selecting data to prune...', NOW();
  END;

  ------------------------------------------------------------
  -- CREATE TIME BUCKETS FOR SELECTED ENTITIES AND INTERVAL --
  ------------------------------------------------------------

  CREATE TEMPORARY TABLE _states AS (
    SELECT
      states.state_id,
      states.old_state_id,
      states.metadata_id,
      states.last_updated_ts,
      date_bin(bin_size::interval, to_timestamp(states.last_updated_ts), TIMESTAMP '2001-01-01') as last_updated_ts_bucket,
      _states_meta.entity_id as meta_entity_id
    from states
    INNER JOIN _states_meta ON states.metadata_id = _states_meta.metadata_id
    where (
          states.last_updated_ts >= (SELECT _start FROM _timerange)
    AND states.last_updated_ts < (SELECT _end FROM _timerange)
    )
  );

  BEGIN
    RAISE NOTICE '[%] Done. Selected % entries', NOW(), (SELECT count(*) FROM _states);
    RAISE NOTICE '[%] Selecting rows to keep...', NOW();
  END;

  ------------------------------------------------------------
  -------- KEEP LAST VALUE FOR EACH ENTITY AND BUCKET --------
  ------------------------------------------------------------

  CREATE TEMPORARY TABLE _kept_states AS (
    SELECT DISTINCT ON (last_updated_ts_bucket, metadata_id)
      _states.*
    from _states
    ORDER BY metadata_id, last_updated_ts_bucket asc, last_updated_ts desc
  );

  ------------------------------------------------------------
  ---------------- COLLECT FIRST DELETED ROWS ----------------
  ------------------------------------------------------------

  CREATE TEMPORARY TABLE _first_dropped_rows AS (
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

  BEGIN
    RAISE NOTICE '[%] Done. Selected % rows', NOW(), (SELECT count(*) FROM _kept_states);
  END;

  ------------------------------------------------------------
  -------- UPDATE KEPT ROWS WITH PROPER OLD STATE ID ---------
  ------------------------------------------------------------

  BEGIN
    RAISE NOTICE '[%] Updating old_state_ids of test data...', NOW();
  END;

  UPDATE states
  SET old_state_id = _kept_states.old_state_id
  FROM _kept_states
  WHERE states.state_id = _kept_states.state_id;

  BEGIN
    RAISE NOTICE '[%] Done.', NOW();
  END;

  ------------------------------------------------------------
  -------- DELETE ALL OTHER STATES IN GIVEN INTERVAL ---------
  ------------------------------------------------------------

  BEGIN
    RAISE NOTICE '[%] Deleting unnecessary data...', NOW();
  END;

  DELETE
  FROM states
  WHERE (
        states.last_updated_ts >= (SELECT _start FROM _timerange)
    AND states.last_updated_ts < (SELECT _end FROM _timerange)
    AND states.metadata_id IN (SELECT metadata_id FROM _states_meta)
    AND states.state_id NOT IN (SELECT state_id FROM _kept_states)
  );
  GET DIAGNOSTICS rows_deleted = ROW_COUNT;

  BEGIN
    RAISE NOTICE '[%] Deleted % rows.', NOW(), rows_deleted;
  END;

  ------------------------------------------------------------
  ---------------- CLEAN UP TEMPORARY TABLES -----------------
  ------------------------------------------------------------

  DROP TABLE _timeref;
  DROP TABLE _timerange;
  DROP TABLE _states_meta;
  DROP TABLE _states;
  DROP TABLE _kept_states;
  DROP TABLE _first_dropped_rows;

  RETURN rows_deleted;
END;
$$ LANGUAGE plpgsql;
