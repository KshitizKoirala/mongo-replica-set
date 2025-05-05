# 🧩 MongoDB Replica Set with Keyfile Authentication

This project sets up a **MongoDB replica set** with authentication using a shared keyfile. It includes support for Windows host systems, high availability features, and guidance for secure and consistent reads/writes.

---

## 🔐 Keyfile Generation

Create a base64-encoded keyfile to enable internal authentication between replica set members:

```bash
openssl rand -base64 756 > ./envs/mongo-keyfile
truncate -s -1 ./envs/mongo-keyfile  # Remove trailing newline (important on Windows)
chmod 400 ./envs/mongo-keyfile       # Restrict access to owner only
```

This creates the keyfile inside **./envs/mongo-keyfile**, removes any trailing newline (which Windows may add), and sets the file permissions so only the owner can read it.

## 📦 Volumes and Cross-Platform Compatibility

To support MongoDB replica set authentication in a cross-platform environment, especially on Windows (which doesn't support UNIX-style file permissions in bind mounts), we use the following strategy:

1. Bind-mount the keyfile into the container at a neutral path:
2. Copy the keyfile inside the container to a native Linux path (/data/mongo-keyfile) during startup
3. Run MongoDB with the replica set and keyfile authentication enabled:

### Explained

1. Bind-mount the keyfile into the container at a neutral path:

```yml
- ./envs/mongo-keyfile:/etc/mongo-keyfile:ro
```

2. Copy the keyfile inside the container to a native Linux path (/data/mongo-keyfile) during startup

```bash
    cp /etc/mongo-keyfile /data/mongo-keyfile &&
    chmod 400 /data/mongo-keyfile &&
    chown 999:999 /data/mongo-keyfile
```

3. Run MongoDB with the replica set and keyfile authentication enabled:

```bash
    docker-entrypoint.sh --replSet rs0 --bind_ip_all --keyFile /data/mongo-keyfile
```

This ensures MongoDB runs securely and correctly even when started from a Windows host.

## ✅ Verifying Replica Set Status

To check if the keyfile-based replica set is running properly:

> docker exec -it mongo1 mongosh -u root -p example --authenticationDatabase admin

Then run:

> rs.status()

## ⚙️ Key Configuration for High Availability

### 🗳️ Election Priorities

```bash
{
\_id: 0, host: "mongo1:27017", priority: 2, // Preferred primary
\_id: 1, host: "mongo2:27017", priority: 1, // Secondary
\_id: 2, host: "mongo3:27017", priority: 1 // Secondary
}
```

    Here mongo1 is more likely to become primary due to a higher election priority.
    In case of failure, mongo2 or mongo3 can automatically take over.

### 🔁 Automatic Failover

MongoDB replica sets handle failovers automatically. When the primary node goes down, a new primary is elected without manual intervention.

### ✍️ Write Concern & 🔍 Read Concern

You can improve consistency and durability by configuring write and read concerns.

#### ✅ Example: Write Concern

```js
db.collection.insertOne(
  { item: "abc", qty: 100 },
  { writeConcern: { w: "majority", wtimeout: 5000 } }
);
```

Ensures write is acknowledged by a majority of replica members.

#### 🔎 Example: Read Concern

```js
db.collection.find({ item: "abc" }).readConcern("majority");
```

Ensures read reflects data committed by a majority of the replica set.

### 🧑‍⚖️ Optional: Adding an Arbiter for Quorum

To prevent a tie in elections (when using an even number of nodes), you can add an arbiter. Arbiters do not store data but help maintain quorum.
Example with Arbiter:

```bash
rs.initiate({
\_id: "rs0",
members: [
{ _id: 0, host: "mongo1:27017", priority: 2 },
{ _id: 1, host: "mongo2:27017", priority: 1 },
{ _id: 2, host: "mongo3:27017", priority: 1 },
{ _id: 3, host: "mongo4:27017", arbiterOnly: true }
]
});
```

## 📌 Additional Considerations

    Network Partitioning: MongoDB will automatically elect a new primary, but ensure your application is resilient to failovers (e.g., retry logic, connection handling).

    Maintenance Mode: Use rs.stepDown() to manually trigger an election when performing maintenance on the primary.
