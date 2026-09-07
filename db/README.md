# Database dump

MySQL 8 dump of `microcrm`: schema, indexes, Alembic version `002_scale_indexes`, seed data, and cached AI insights.

## Restore

With the Compose MySQL already up (`docker compose up -d` from the repo root):

```bash
docker exec -i microcrm-mysql mysql -uroot -ppassword < db/microcrm.sql
```

Or from the host (port **3307**):

```bash
mysql -h 127.0.0.1 -P 3307 -uroot -ppassword < db/microcrm.sql
```

That creates `microcrm` if needed and loads all tables. You can skip `alembic upgrade` / `python -m app.seed.seed_data` after a restore.

## Refresh this file

```bash
docker exec microcrm-mysql mysqldump -uroot -ppassword \
  --single-transaction --complete-insert --set-gtid-purged=OFF --no-tablespaces \
  microcrm customers contacts interactions ai_insights alembic_version \
  > db/microcrm.sql
```

Then keep the `CREATE DATABASE` / `USE microcrm` header at the top of the file.
