-- list user defined functions
SELECT proname AS function_name, 
pg_get_function_identity_arguments(oid) AS arguments_accepted
FROM pg_proc
WHERE pronamespace = 'public'::regnamespace;
