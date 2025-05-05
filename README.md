docker exec -it mongo1 mongosh -u root -p example --authenticationDatabase admin

rs.status()

Key Changes for High Availability:

    Election Priorities:

        priority: 2 is assigned to mongo1, making it the preferred primary node. In case of a failover, mongo1 will have a higher chance of becoming primary.

        priority: 1 is assigned to mongo2 and mongo3, which will act as secondary nodes unless mongo1 becomes unavailable.

    Automatic Failover:

        If mongo1 goes down, either mongo2 or mongo3 can automatically take over as the new primary. The election happens automatically without manual intervention, thanks to the default MongoDB replica set behavior.

    Write Concern:

        You can ensure that writes are acknowledged by at least two nodes (including the primary) before being considered successful by setting a write concern of w:2. This ensures that your data is written to at least two nodes, improving fault tolerance.

    Read Concern:

        You can configure read concern to ensure consistency when reading from the replica set. For example, using majority read concern will ensure that you only read data that has been committed by a majority of the replica set members.

Example for Write Concern and Read Concern:

You can configure these in your application to ensure strong consistency and availability:

db.collection.insertOne(
{ item: "abc", qty: 100 },
{ writeConcern: { w: "majority", wtimeout: 5000 } } // Wait for majority acknowledgment
);

db.collection.find({ item: "abc" }).readConcern("majority"); // Read only from the majority

Optional: Adding an Arbiter for Quorum

In some cases, if you want to avoid having an even number of replica set members (which could result in a tie in elections), you can add an arbiter. The arbiter doesn’t store data but helps with elections.

To add an arbiter, you can modify the rs.initiate call like so:

rs.initiate({
\_id: "rs0",
members: [
{ _id: 0, host: "mongo1:27017", priority: 2 },
{ _id: 1, host: "mongo2:27017", priority: 1 },
{ _id: 2, host: "mongo3:27017", priority: 1 },
{ _id: 3, host: "mongo4:27017", arbiterOnly: true }
]
});

In this case, mongo4 is an arbiter.

Considerations:

    Network Partitioning: MongoDB automatically elects a new primary in the event of network partitioning. However, it's critical to configure your applications for handling failovers, especially with regard to client connections and retries.

    Maintenance Mode: If you’re doing maintenance on the primary node, you can use rs.stepDown() to manually trigger a primary election.
