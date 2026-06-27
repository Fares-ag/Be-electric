-- Public tables and approximate row counts
SELECT
  schemaname,
  relname AS table_name,
  n_live_tup AS estimated_rows
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY relname;
