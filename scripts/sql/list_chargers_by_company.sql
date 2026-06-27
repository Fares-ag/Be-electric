-- Chargers for a company (edit company id filter)
-- Usage: ./scripts/db.sh run scripts/sql/list_chargers_by_company.sql
-- Or in shell: set company id in WHERE clause

SELECT
  id,
  name,
  manufacturer,
  companyId,
  location,
  status,
  category,
  itemType
FROM assets
WHERE companyId IS NOT NULL
  AND (
    manufacturer ILIKE '%siemens%'
    OR manufacturer ILIKE '%kostad%'
    OR name ILIKE '%charger%'
    OR category ILIKE '%charger%'
  )
ORDER BY companyId, manufacturer, name
LIMIT 100;
