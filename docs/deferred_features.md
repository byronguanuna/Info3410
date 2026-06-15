# Deferred Features

The first transactional foundation intentionally leaves the following
features for later team review or implementation:

- Lot numbers and expiration dates
- Inventory balances by lot
- Product recall tracking
- External suppliers and distributors
- External purchase orders and procurement workflows
- Emergency or virtual warehouse location types
- Automated parent location-type validation
- Automated inventory balance updates
- Automated request status and fulfillment maintenance
- Route planning
- Recurring shipping schedules
- Point-of-sale sales records
- Menu recipes and recipe depletion
- Customer receipts and payment processing
- Full authentication and login management
- Large sample-data generation
- Data warehouse facts, dimensions, aggregates, loading, and snapshots

## Future Lot Tracking Direction

Complete lot tracking must preserve the remaining quantity of each lot at each
location and follow that lot through every movement. A future design could use:

- `InventoryLot` for the lot identifier, product, expiration date, and initial
  receipt details
- `LocationInventoryLot` for current lot quantities by location
- `InventoryLotMovement` for auditable movement of lot quantities

External receipts into main warehouses are the natural point to first record
the lot ID and expiration date. No partial lot fields are included in the
current schema because they would suggest traceability that the system cannot
yet provide.

