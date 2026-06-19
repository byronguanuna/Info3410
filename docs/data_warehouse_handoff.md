# Data Warehouse Scope Note

The current reduced class-project version implements a small data warehouse
star schema.

Earlier planning discussed a larger analytical design. The current version
keeps that scope small enough for the assignment by using one inventory
movement fact table, four dimensions, one aggregate table, and snapshot
procedures to load warehouse data from the transactional database.

The current database includes transactional tables for locations, products,
inventory, employees, requests, and shipments, plus three simple views. The
warehouse tables and support scripts sit beside that transactional model and
are used for assignment reporting requirements.

