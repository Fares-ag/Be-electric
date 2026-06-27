-- Recent work orders (requestor app)
SELECT
  id,
  ticketNumber,
  status,
  priority,
  requestorId,
  companyId,
  assetId,
  location,
  createdAt,
  updatedAt
FROM work_orders
ORDER BY createdAt DESC
LIMIT 50;
