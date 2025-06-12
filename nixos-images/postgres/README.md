# Databases

## Mongodb

create user

```bash
use brokerme
db.createUser({
  user: "brokerme",
  pwd: "brokerme1234",
  roles: [
    { role: "readWrite", db: "brokerme" }
  ]
})

```
