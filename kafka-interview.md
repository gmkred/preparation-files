# Kafka Interview Preparation — Java Developer (5+ Years)

> **Goal:** Make you interview-ready on every Kafka topic that gets asked at senior Java developer interviews. Every concept is explained with real scenarios, Java code, CLI commands, and edge cases. Architecture first — everything else follows from it.

---

## TABLE OF CONTENTS

1. [Kafka Architecture — The Complete Picture](#1-kafka-architecture--the-complete-picture)
   - Broker, Cluster, Controller, ZooKeeper vs KRaft
   - Topic, Partition, Offset, Replication
   - ISR, Leader, Follower
2. [Producers — Sending Messages](#2-producers--sending-messages)
   - Acks, Retries, Idempotent Producer
   - Batching, Linger.ms, Compression
   - Sending to a specific partition (with Java code)
   - What if the message is never acknowledged?
3. [Consumers — Receiving Messages](#3-consumers--receiving-messages)
   - Consumer Groups, Partition Assignment
   - Auto vs Manual Offset Commit
   - What if offset is not committed after consuming?
   - Consuming from a specific partition (with Java code)
4. [How to Detect a Slow or Stuck Consumer](#4-how-to-detect-a-slow-or-stuck-consumer)
   - Consumer LAG — what it is and how to measure it
   - CLI commands to identify which consumer is behind
   - CloudWatch / Prometheus alerting on LAG
5. [Java Spring Boot — Full Producer & Consumer Code](#5-java-spring-boot--full-producer--consumer-code)
   - KafkaTemplate — produce with acks, retries, callbacks
   - @KafkaListener — manual offset, error handling
   - Multiple producer instances
   - Multiple consumer instances with same group
6. [Dead Letter Queue (DLQ) — Full Pattern](#6-dead-letter-queue-dlq--full-pattern)
   - Why DLQ exists and when to use it
   - Spring Boot DLQ configuration
   - Processing DLQ messages (retry or discard)
7. [Saga Pattern with Kafka in Spring Boot Microservices](#7-saga-pattern-with-kafka-in-spring-boot-microservices)
   - Choreography Saga (event-driven, no orchestrator)
   - Orchestration Saga (central coordinator)
   - Compensating transactions on failure
   - Java code for a complete order saga
8. [Partition Deep Dive](#8-partition-deep-dive)
   - Why partitions exist
   - How Kafka assigns messages to partitions (murmur2)
   - Sending to a specific partition — Java code
   - Consuming from a specific partition — Java code
   - What happens when you increase partitions?
9. [Replication, Fault Tolerance and Data Loss Prevention](#9-replication-fault-tolerance-and-data-loss-prevention)
   - Replication factor, ISR, min.insync.replicas
   - What happens when a broker goes down
   - Topic/partition corruption — how to detect and recover
   - Precautions to prevent data loss
10. [Exactly-Once Semantics — At Most Once, At Least Once, Exactly Once](#10-exactly-once-semantics)
11. [Advanced Topics — Compaction, Headers, Schema Registry](#11-advanced-topics)
12. [Essential CLI Commands — Where to Run and Why](#12-essential-cli-commands)
13. [Monitoring — Metrics Every Developer Must Know](#13-monitoring--metrics-every-developer-must-know)
14. [Top Interview Questions with Full Answers](#14-top-interview-questions-with-full-answers)

---

## 1. KAFKA ARCHITECTURE — THE COMPLETE PICTURE

> Before anything else, you need a strong mental model of how Kafka works. Every interview question ties back to this.

---

### 1.1 The Big Picture

```
PRODUCERS                    KAFKA CLUSTER                    CONSUMERS
(Spring Boot                 ┌─────────────────────────┐      (Spring Boot
 order-service)              │  Broker 1 (Leader P0)   │       inventory-service)
      │                      │  Broker 2 (Leader P1)   │             │
      │  produce message      │  Broker 3 (Follower)    │   poll messages
      └──────────────────────▶│                         │─────────────┘
                              │  Topic: order-events    │
                              │    Partition 0  [0,1,2] │
                              │    Partition 1  [0,1,2] │
                              │                         │
                              │  Controller manages     │
                              │  cluster metadata,      │
                              │  leader election        │
                              └─────────────────────────┘
```

---

### 1.2 Core Concepts — Every Term Explained

**Broker**
A single Kafka server. Receives messages from producers, stores them to disk, and serves them to consumers. A cluster has multiple brokers. Each broker has an ID (1, 2, 3...).

**Cluster**
Multiple brokers working together. They know about each other. If one broker goes down, others continue serving. Kafka is designed so no single broker failure can stop the system.

**Controller**
One broker is elected as Controller — it manages cluster metadata: which broker leads which partition, handles broker failures, and reassigns partitions. If the controller broker goes down, another broker is automatically elected.

**ZooKeeper vs KRaft**
```
Old Kafka (< 2.8):  ZooKeeper is a separate process that manages the cluster.
                    Problems: extra process to maintain, slower operations, separate config.

New Kafka (KRaft):  Kafka manages itself. One broker acts as the controller.
                    ZooKeeper is completely removed.
                    Simpler, faster, more scalable.
                    Interview: "We use KRaft-based Kafka in production — no ZooKeeper dependency."
```

**Topic**
A category/feed name to which messages are published. Like a table in a database. You can have thousands of topics. Examples: `order-events`, `payment-events`, `user-clicks`.

**Partition**
A topic is divided into one or more partitions. Each partition is an ordered, immutable sequence of messages stored on disk. Partitions enable parallelism.

```
Topic: order-events (3 partitions)

Partition 0: [msg0] [msg1] [msg4] [msg7]   ← messages with key "account-100"
Partition 1: [msg0] [msg2] [msg5] [msg8]   ← messages with key "account-200"
Partition 2: [msg0] [msg3] [msg6] [msg9]   ← messages with key "account-300"

offset        0      1      2      3        ← offset is per-partition, starts at 0
```

**Offset**
A sequential number given to each message within a partition. Offsets are per-partition — not per-topic. Consumer tracks which offset it has consumed up to.

```
Key Interview Fact:
  Offset 5 in Partition 0  ≠  Offset 5 in Partition 1
  They are completely different messages.
```

**Replication**
Each partition has one leader and N-1 followers (replicas). All reads and writes go to the leader. Followers copy data from the leader. If the leader's broker crashes, a follower becomes the new leader.

```
Topic: order-events, Partition 0, Replication Factor 3

Broker 1: Partition 0 LEADER      ← producer writes here, consumer reads here
Broker 2: Partition 0 Follower    ← copies from leader
Broker 3: Partition 0 Follower    ← copies from leader

If Broker 1 crashes:
  Controller elects Broker 2 or 3 as new Leader → no data loss, no downtime
```

**ISR — In-Sync Replicas**
The set of replicas that are currently fully caught up with the leader. If a follower falls behind (slow network, disk issue), it's removed from the ISR. This matters for acks.

```
ISR = [1, 2, 3]   ← all 3 brokers in sync (healthy)
ISR = [1, 2]      ← broker 3 fell behind (still receiving data, just not in ISR)
ISR = [1]         ← only leader — danger zone if leader dies now, data can be lost
```

**Consumer Group**
A logical group of consumer instances that collectively consume a topic. Each partition is assigned to exactly ONE consumer in the group. This provides parallel consumption without duplicate processing.

```
Topic: order-events (3 partitions)
Consumer Group: inventory-service

  inventory-service instance 1  → reads Partition 0
  inventory-service instance 2  → reads Partition 1
  inventory-service instance 3  → reads Partition 2

  Each message is processed by exactly ONE instance.

  If a 4th instance joins → it sits idle (max consumers = number of partitions).
  If an instance leaves → its partition is reassigned to remaining consumers (rebalance).
```

**Bootstrap Server**
The initial Kafka broker address your client connects to. The client uses it to discover ALL other brokers in the cluster. You only need to specify one (but specify 2-3 for resilience in case one is down at startup time).

---

## 2. PRODUCERS — SENDING MESSAGES

### 2.1 How the Producer Works Internally

```
Your code calls: kafkaTemplate.send("order-events", key, value)

Internally the Kafka client library:
1. Serializes key and value to bytes
2. Determines target partition:
   - Key present: murmur2(key) % numPartitions → deterministic partition
   - Key null:    round-robin across partitions (sticky batching in new versions)
3. Adds message to an internal in-memory buffer (RecordAccumulator)
4. When buffer is full OR linger.ms has passed → sends batch to broker
5. Waits for acknowledgement (ack) from broker
6. On success: calls the callback with RecordMetadata (partition, offset)
7. On failure: retries (configurable) → after max retries, throws exception
```

---

### 2.2 Producer Acknowledgements (acks) — The Most Important Config

```
acks=0  (Fire and Forget)
  Producer does NOT wait for any ack from broker.
  Fastest. Highest throughput. Maximum data loss risk.
  Use: metrics, logs where losing a few messages is acceptable.

acks=1  (Leader Ack)
  Producer waits for ack from the LEADER broker only.
  Message is safe once written to the leader.
  Risk: if leader crashes BEFORE followers replicate → message is lost.
  Use: moderate reliability, good performance.

acks=-1 or acks=all  (All In-Sync Replicas — DEFAULT in new versions)
  Producer waits for ack from ALL in-sync replicas.
  Message is safe as long as at least one ISR replica survives.
  Slowest. Zero data loss (combined with min.insync.replicas).
  Use: financial transactions, order events, payment events.

Combined with min.insync.replicas:
  If replication.factor=3 and min.insync.replicas=2 and acks=all:
    → Producer gets ack only after 2 brokers confirm the write
    → Even if one broker dies, data is on at least one other broker
    → If only 1 broker is in ISR → producer gets NotEnoughReplicasException
       → This is intentional — it's better to fail than to lose data silently
```

---

### 2.3 What If the Message Is Never Acknowledged?

**Scenario: Producer sends a message, broker writes it, sends ack, but the ack is LOST in the network. Producer never receives the ack.**

```
Without idempotence:
  Producer retries → sends the SAME message again → broker writes it AGAIN
  → DUPLICATE message in the topic
  → Consumer processes the same order TWICE — critical bug!

With idempotence (enable.idempotence=true — default in Kafka 3.x):
  Kafka client assigns each message a Producer ID (PID) and Sequence Number.
  On retry, the same message carries the same PID + Sequence Number.
  Broker checks: "Have I already written this PID+Sequence?"
  → YES: drops the duplicate, sends ack back
  → NO: writes it normally

This guarantees: exactly-once delivery from producer to broker.

What does NOT protect against:
  Your OWN APPLICATION generates the same message twice (business logic bug).
  These get different sequence numbers → both written → duplicates.
  Fix: use business-level idempotency keys (UUID in the message payload).
```

**Producer retry configuration:**
```java
props.put(ProducerConfig.ACKS_CONFIG, "all");
props.put(ProducerConfig.RETRIES_CONFIG, Integer.MAX_VALUE);     // retry forever
props.put(ProducerConfig.RETRY_BACKOFF_MS_CONFIG, 100);          // 100ms between retries
props.put(ProducerConfig.DELIVERY_TIMEOUT_MS_CONFIG, 120000);    // give up after 2 min total
props.put(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, true);       // no duplicates on retry
props.put(ProducerConfig.MAX_IN_FLIGHT_REQUESTS_PER_CONNECTION, 5); // must be ≤5 with idempotence
```

---

### 2.4 Sending to a Specific Partition

**Why would you want this?**
- Guarantee that ALL messages for a particular entity go to one partition
- Manual load balancing across partitions
- Testing a specific consumer that owns that partition

```java
// Method 1: Use a Message Key (recommended — Kafka handles the partition assignment)
// Same key ALWAYS goes to the same partition (murmur2 hash algorithm)
ProducerRecord<String, String> record = new ProducerRecord<>(
    "order-events",         // topic
    "account-123",          // key → always → same partition
    orderJson               // value
);

// Method 2: Specify partition explicitly (override Kafka's decision)
ProducerRecord<String, String> record = new ProducerRecord<>(
    "order-events",   // topic
    0,                // partition number (0-indexed) — EXPLICIT
    "account-123",    // key
    orderJson         // value
);
kafkaTemplate.send(record);
```

**When to use explicit partition vs key:**
```
Use KEY (recommended):
  You want messages for the same entity (same account, same order ID) together.
  You don't care WHICH specific partition, just that they're consistent.
  Kafka handles rebalancing correctly.

Use EXPLICIT PARTITION (avoid unless needed):
  You have specific routing logic not expressible by key.
  You're implementing a custom partitioner.
  Risk: if you remove that partition later, your code breaks.
```

**Custom Partitioner (if key-based logic is not enough):**
```java
public class RegionPartitioner implements Partitioner {

    @Override
    public int partition(String topic, Object key, byte[] keyBytes,
                         Object value, byte[] valueBytes, Cluster cluster) {
        int numPartitions = cluster.partitionCountForTopic(topic);
        String orderKey = (String) key;
        
        // Route "US-*" orders to partition 0, "EU-*" to partition 1, others round-robin
        if (orderKey.startsWith("US-")) return 0;
        if (orderKey.startsWith("EU-")) return 1;
        return Math.abs(orderKey.hashCode()) % numPartitions;
    }

    @Override
    public void configure(Map<String, ?> configs) {}

    @Override
    public void close() {}
}

// Register in producer config:
props.put(ProducerConfig.PARTITIONER_CLASS_CONFIG, RegionPartitioner.class.getName());
```

---

### 2.5 Batching and Throughput Tuning

```java
// Producer sends in BATCHES for efficiency — not one message at a time
props.put(ProducerConfig.BATCH_SIZE_CONFIG, 32 * 1024);        // 32KB batch size
props.put(ProducerConfig.LINGER_MS_CONFIG, 10);                 // wait up to 10ms for batch to fill
props.put(ProducerConfig.COMPRESSION_TYPE_CONFIG, "snappy");    // compress batches
props.put(ProducerConfig.BUFFER_MEMORY_CONFIG, 32 * 1024 * 1024); // 32MB in-memory buffer

// linger.ms=0: send immediately when ready (low latency, smaller batches)
// linger.ms=10: wait 10ms before sending (higher latency, larger batches → more throughput)
// For microservices: linger.ms=5-20 is a good balance
```

---

## 3. CONSUMERS — RECEIVING MESSAGES

### 3.1 How the Consumer Works Internally

```
Consumer is a PULL model (not push):
  Consumer asks Kafka: "Give me messages from order-events partition 0 starting at offset 42"
  Kafka sends up to max.poll.records (default 500) messages
  Consumer processes them
  Consumer commits offset 42+N → tells Kafka "I've processed up to here"
  Consumer polls again

Important: Kafka does NOT push messages to consumers.
           Consumer calls poll() in a loop.
           This gives consumers full control over processing rate.
```

**Consumer poll loop (what Spring Boot's @KafkaListener does internally):**
```
while (true) {
    records = consumer.poll(Duration.ofMillis(100))   // poll for up to 100ms
    for each record in records:
        process(record)
    consumer.commitSync()   // commit offsets after processing
}
```

---

### 3.2 Offset Commit — Auto vs Manual (Critical Interview Topic)

**Auto Commit (enable.auto.commit=true — default):**
```
Every auto.commit.interval.ms (default 5000ms = 5 seconds):
  Consumer automatically commits the last polled offset to Kafka.

Problem scenario:
  1. Consumer polls messages [offset 10, 11, 12]
  2. Auto-commit fires → commits offset 12
  3. Consumer crashes BEFORE processing offset 11
  4. When consumer restarts → starts from offset 13 (next after 12)
  5. Offsets 11 and 12 are LOST — never processed
  → "at-most-once" delivery — you can LOSE messages

Another problem:
  1. Consumer polls messages [offset 10, 11, 12]
  2. Consumer processes offset 10 partially (sends email to user)
  3. Auto-commit fires → commits offset 12
  4. Processing crashes at offset 11
  5. When consumer restarts → starts at offset 13
  6. Offset 11's email was not sent — LOST
```

**Manual Commit (enable.auto.commit=false — recommended for production):**
```java
// Commit AFTER processing → "at-least-once" delivery
// If crash happens before commit → messages re-delivered → process again
// Make your consumer IDEMPOTENT so re-processing is safe

// Option 1: commitSync() — blocks until broker confirms the commit
consumer.commitSync();   // after processing each batch

// Option 2: commitAsync() — does not block (higher throughput)
consumer.commitAsync((offsets, exception) -> {
    if (exception != null) {
        log.error("Commit failed for offsets {}", offsets, exception);
    }
});

// Option 3: commit specific offset (fine-grained control)
Map<TopicPartition, OffsetAndMetadata> offsets = new HashMap<>();
offsets.put(
    new TopicPartition("order-events", record.partition()),
    new OffsetAndMetadata(record.offset() + 1)  // +1 = next message to consume
);
consumer.commitSync(offsets);
```

---

### 3.3 What If a Consumer Consumes But Doesn't Commit the Offset?

**Scenario: Consumer reads message, sends email, then crashes before committing offset.**

```
State after crash:
  Broker thinks consumer is at offset 9 (last committed)
  Consumer actually processed up to offset 12

When consumer restarts:
  Reads from offset 9 (last committed)
  Re-processes offsets 9, 10, 11, 12
  User receives DUPLICATE emails!

This is "at-least-once" delivery — you WILL reprocess on failure.

Solution — Idempotent Consumer:
  Before processing, check: "Have I already processed this message?"
  Store processed message IDs in a DB table:

  CREATE TABLE processed_messages (
    message_id VARCHAR(255) PRIMARY KEY,  -- or topic+partition+offset
    processed_at TIMESTAMP
  );

  @KafkaListener
  void handleOrder(ConsumerRecord<String, OrderEvent> record) {
    String msgId = record.topic() + "-" + record.partition() + "-" + record.offset();
    
    if (processedMessageRepo.existsById(msgId)) {
        log.info("Duplicate message, skipping: {}", msgId);
        return;  // already processed, skip
    }
    
    // Process the message
    orderService.processOrder(record.value());
    
    // Mark as processed (in the SAME DB transaction as business logic)
    processedMessageRepo.save(new ProcessedMessage(msgId, Instant.now()));
  }
```

**The safest pattern — process and mark in same transaction:**
```java
@Transactional
void handleOrder(ConsumerRecord<String, OrderEvent> record) {
    String msgId = buildMessageId(record);
    
    // Idempotency check
    if (processedMessageRepo.existsById(msgId)) return;
    
    // Business logic — in same transaction
    Order order = orderService.createOrder(record.value());
    
    // Mark processed — in same transaction
    // If DB transaction fails → both rollback → safe to retry
    processedMessageRepo.save(new ProcessedMessage(msgId));
    
    // Offset committed AFTER this method returns (by Spring's AckMode)
}
```

---

### 3.4 Consuming From a Specific Partition

```java
// Assign specific partitions to a consumer (bypasses consumer group coordination)
// WARNING: when you manually assign partitions, you OPT OUT of rebalancing
//          and consumer group management. Use only when you explicitly need this.

@Configuration
public class ManualPartitionConsumer {

    @Bean
    public void consumeFromPartition0() {
        Map<String, Object> props = consumerProps();
        props.put(ConsumerConfig.GROUP_ID_CONFIG, "order-service-manual");

        KafkaConsumer<String, String> consumer = new KafkaConsumer<>(props);

        // Manually assign partition 0 of order-events
        TopicPartition partition0 = new TopicPartition("order-events", 0);
        consumer.assign(Collections.singletonList(partition0));

        // Optionally seek to a specific offset:
        consumer.seekToBeginning(Collections.singletonList(partition0)); // from start
        consumer.seekToEnd(Collections.singletonList(partition0));        // latest only
        consumer.seek(partition0, 42L);                                   // from offset 42

        while (true) {
            ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(100));
            for (ConsumerRecord<String, String> record : records) {
                System.out.printf("partition=%d offset=%d key=%s value=%s%n",
                    record.partition(), record.offset(), record.key(), record.value());
            }
            consumer.commitSync();
        }
    }
}
```

**In Spring Boot with @KafkaListener and topicPartitions:**
```java
// Consume only from partition 0 and partition 1, starting from the latest offset
@KafkaListener(
    groupId = "order-service-group",
    topicPartitions = {
        @TopicPartition(
            topic = "order-events",
            partitionOffsets = {
                @PartitionOffset(partition = "0", initialOffset = "0"),
                @PartitionOffset(partition = "1", initialOffset = "0")
            }
        )
    }
)
public void listenToSpecificPartitions(ConsumerRecord<String, OrderEvent> record) {
    log.info("Partition: {}, Offset: {}, Key: {}", 
             record.partition(), record.offset(), record.key());
    processOrder(record.value());
}
```

---

## 4. HOW TO DETECT A SLOW OR STUCK CONSUMER

> This was your exact interview question: "If one consumer is not consuming messages, how do you identify which one?"

---

### 4.1 Consumer LAG — The Key Concept

**LAG = messages available in partition - messages consumed by consumer group**

```
Partition 0: latest offset = 1000  (1001 messages total: 0-1000)
Consumer for Partition 0: committed offset = 950

LAG for this consumer on Partition 0 = 1000 - 950 = 50

LAG = 0:   Consumer is fully caught up. Healthy.
LAG > 0:   Consumer is behind. Might be slow, might be stuck.
LAG = N and not changing:   Consumer is STUCK (not moving at all).
LAG = N and growing:   Consumer is too slow (can't keep up with producer).
```

---

### 4.2 CLI Commands to Identify Which Consumer Is Lagging

**These commands are run inside the Kafka container or from any machine with Kafka CLI tools.**

```bash
# Step 1: List all consumer groups
kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --list

# Output:
# inventory-service-group
# payment-service-group
# notification-service-group

# Step 2: Describe a specific consumer group — THIS IS THE ANSWER TO THE INTERVIEW QUESTION
kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --group inventory-service-group \
  --describe

# Output:
# GROUP                   TOPIC         PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG    CONSUMER-ID                         HOST
# inventory-service-group order-events  0          1050            1050            0      consumer-1-abc123@server-1          /10.0.1.1
# inventory-service-group order-events  1          800             1200            400    consumer-2-def456@server-2          /10.0.1.2  ← HIGH LAG!
# inventory-service-group order-events  2          1050            1050            0      consumer-3-ghi789@server-3          /10.0.1.3

# Reading this output:
# PARTITION 0: consumer-1, LAG=0 → healthy, fully caught up
# PARTITION 1: consumer-2, LAG=400 → 400 messages behind! This is the stuck consumer
#              HOST=/10.0.1.2 → this is the specific pod/machine that's behind
# PARTITION 2: consumer-3, LAG=0 → healthy

# CONSUMER-ID shows you:
#   consumer-2-def456@server-2 → consumer instance ID + hostname
#   → Go to that pod/machine and check its logs

# Step 3: Watch LAG in real time (run every 5 seconds)
watch -n 5 "kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --group inventory-service-group \
  --describe"

# If the LAG for partition 1 is:
#   Increasing → consumer is stuck / crashed but still connected
#   Constant → consumer is processing but too slowly
#   Decreasing → consumer is recovering (catching up)

# Step 4: Check if ANY consumer is assigned to the stuck partition
# CONSUMER-ID shows "consumer-2-def456" → means a consumer IS assigned
# If CONSUMER-ID is empty → NO consumer is assigned to that partition!
#   → That consumer instance died and rebalance hasn't happened yet
#   → Or consumer group has fewer instances than partitions

# Step 5: Describe ALL consumer groups at once
kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --all-groups \
  --describe
```

**Full diagnostic sequence when you get a "consumer not consuming" alert:**

```bash
# 1. Find which group has lag
kafka-consumer-groups.sh --bootstrap-server localhost:9092 --all-groups --describe \
  | awk '$6 > 0'   # show only rows with LAG > 0

# 2. See the lag trend (run twice, 30 seconds apart)
kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
  --group inventory-service-group --describe

# sleep 30s, run again → if LAG grew → consumer is NOT processing

# 3. Find the pod that owns the lagging partition
# From the output: HOST=/10.0.1.2 → go to that pod
kubectl get pods -o wide -n production | grep 10.0.1.2
# → inventory-service-68f9b-xyz99

# 4. Check that pod's logs
kubectl logs inventory-service-68f9b-xyz99 -n production | grep -i "error\|exception\|warn"

# 5. Check if pod is alive
kubectl exec -it inventory-service-68f9b-xyz99 -n production -- \
  wget -qO- http://localhost:8080/actuator/health

# 6. Check consumer thread count (if using JMX/actuator/metrics):
kubectl exec -it inventory-service-68f9b-xyz99 -n production -- \
  wget -qO- http://localhost:8080/actuator/metrics/kafka.consumer.fetch.manager.records.lag
```

---

### 4.3 What Causes a Consumer to Get Stuck — Root Causes

```
Cause 1: Consumer is processing too slowly
  → Each message takes 2s to process (DB write + external API call)
  → Producer sends 100 msg/sec → consumer can only do 0.5 msg/sec
  → LAG grows at 99.5 msg/sec
  Fix: Add more consumer instances (up to partition count), optimize processing,
       increase max.poll.records, async processing

Cause 2: Consumer is stuck in an infinite retry loop on one bad message
  → Message #500 is malformed → consumer throws exception → retries → exception → loop
  → LAG stays constant at (total - 500) → nothing moves
  Fix: DLQ (Dead Letter Queue) — after N retries, send to DLQ and move on

Cause 3: Consumer thread is deadlocked
  → Consumer holds a lock and waits for another resource that's also locked
  → poll() is never called → Kafka thinks consumer is dead after max.poll.interval.ms
  Fix: Thread dump, fix deadlock. Meanwhile Kafka rebalances partition to another consumer.

Cause 4: max.poll.interval.ms exceeded
  → Consumer polled records, started processing, but took too long
  → After max.poll.interval.ms (default 5 min) Kafka considers consumer dead
  → Triggers rebalance → partition reassigned
  → Consumer gets kicked out of group
  Fix: Increase max.poll.interval.ms, reduce max.poll.records, speed up processing

Cause 5: Consumer is up but network is partitioned
  → Consumer can't reach Kafka broker
  → session.timeout.ms exceeded → Kafka considers consumer dead → rebalance
  Fix: Fix network, check security groups / VPC routing

Cause 6: Not enough consumer instances
  → 3 partitions, 2 consumers → one consumer has 2 partitions, one has 1
  → The consumer with 2 partitions is slower (double workload)
  Fix: Scale to 3 consumer instances (one per partition)
```

---

### 4.4 Monitoring LAG with Alerts (Production Setup)

**In Spring Boot with Micrometer + Prometheus:**
```yaml
# application.yml — expose Kafka consumer metrics
management:
  metrics:
    kafka:
      consumer:
        enabled: true
```

```
Prometheus metric: kafka_consumer_fetch_manager_records_lag{topic="order-events"}
Grafana alert:     IF lag > 1000 for 5 minutes → alert team on Slack/PagerDuty
```

**CloudWatch (AWS MSK):**
```
MSK → Monitoring → Consumer Group Lag
  → Select consumer group: inventory-service-group
  → Select topic: order-events
  → Create CloudWatch Alarm: if MaxOffsetLag > 500 → SNS alert
```

**Important consumer configs related to lag:**
```java
// How often consumer sends heartbeat to Kafka (proves it's alive)
props.put(ConsumerConfig.HEARTBEAT_INTERVAL_MS_CONFIG, 3000);   // 3s heartbeat

// How long without heartbeat before Kafka considers consumer dead
props.put(ConsumerConfig.SESSION_TIMEOUT_MS_CONFIG, 30000);     // 30s timeout

// Max time between consecutive poll() calls (if exceeded → consumer kicked out)
props.put(ConsumerConfig.MAX_POLL_INTERVAL_MS_CONFIG, 300000);  // 5 minutes

// How many records per poll — reduce if each record takes long to process
props.put(ConsumerConfig.MAX_POLL_RECORDS_CONFIG, 100);         // default 500

// Key rule: HEARTBEAT_INTERVAL < SESSION_TIMEOUT < MAX_POLL_INTERVAL
```

---

## 5. JAVA SPRING BOOT — FULL PRODUCER & CONSUMER CODE

### 5.1 Dependencies

```xml
<dependency>
    <groupId>org.springframework.kafka</groupId>
    <artifactId>spring-kafka</artifactId>
</dependency>
<dependency>
    <groupId>com.fasterxml.jackson.core</groupId>
    <artifactId>jackson-databind</artifactId>
</dependency>
```

---

### 5.2 Configuration

```yaml
# application.yml
spring:
  kafka:
    bootstrap-servers: kafka1:9092,kafka2:9092,kafka3:9092  # specify 2-3 for resilience

    producer:
      acks: all                          # wait for all ISR to confirm
      retries: 2147483647                # retry forever (until delivery.timeout.ms)
      properties:
        enable.idempotence: true         # no duplicate on retry
        max.in.flight.requests.per.connection: 5
        delivery.timeout.ms: 120000      # give up after 2 min total
        linger.ms: 5                     # wait 5ms to batch messages
        batch-size: 32768                # 32KB batch
      key-serializer: org.apache.kafka.common.serialization.StringSerializer
      value-serializer: org.springframework.kafka.support.serializer.JsonSerializer

    consumer:
      group-id: inventory-service-group
      auto-offset-reset: earliest        # on first start, read from beginning
      enable-auto-commit: false          # MANUAL offset commit
      max-poll-records: 100
      properties:
        max.poll.interval.ms: 300000
        session.timeout.ms: 30000
        heartbeat.interval.ms: 3000
      key-deserializer: org.apache.kafka.common.serialization.StringDeserializer
      value-deserializer: org.springframework.kafka.support.serializer.JsonDeserializer
      properties:
        spring.json.trusted.packages: "com.myapp.events"
```

---

### 5.3 Event Classes

```java
// Shared events (in a common module or published to Maven repo)
package com.myapp.events;

public record OrderCreatedEvent(
    String orderId,
    String customerId,
    String productId,
    int quantity,
    BigDecimal totalAmount,
    String messageId,     // UUID for idempotency check
    Instant timestamp
) {}

public record OrderCancelledEvent(
    String orderId,
    String reason,
    String messageId,
    Instant timestamp
) {}

public record PaymentProcessedEvent(
    String orderId,
    String paymentId,
    BigDecimal amount,
    String status,   // SUCCESS, FAILED
    String messageId,
    Instant timestamp
) {}
```

---

### 5.4 Producer — Multiple Instances with Full Error Handling

```java
package com.myapp.orderservice.kafka;

@Service
@Slf4j
public class OrderEventProducer {

    private final KafkaTemplate<String, Object> kafkaTemplate;
    private static final String TOPIC = "order-events";

    public OrderEventProducer(KafkaTemplate<String, Object> kafkaTemplate) {
        this.kafkaTemplate = kafkaTemplate;
    }

    // Basic send — fire and check callback
    public void sendOrderCreated(OrderCreatedEvent event) {
        var record = new ProducerRecord<String, Object>(
            TOPIC,
            event.orderId(),  // key → same orderId → same partition → ordering guaranteed
            event
        );

        kafkaTemplate.send(record).whenComplete((result, ex) -> {
            if (ex != null) {
                // Message failed after all retries — alert, store in outbox, etc.
                log.error("Failed to send OrderCreatedEvent orderId={} after retries: {}",
                    event.orderId(), ex.getMessage());
                // DO NOT silently ignore — you will lose the event!
                handleSendFailure(event, ex);
            } else {
                log.info("Sent OrderCreatedEvent orderId={} → partition={} offset={}",
                    event.orderId(),
                    result.getRecordMetadata().partition(),
                    result.getRecordMetadata().offset());
            }
        });
    }

    // Send to explicit partition (use only when you have a specific reason)
    public void sendToPartition(OrderCreatedEvent event, int partitionNumber) {
        var record = new ProducerRecord<>(
            TOPIC,
            partitionNumber,    // explicit partition
            event.orderId(),
            event
        );
        kafkaTemplate.send(record);
    }

    // Synchronous send — blocks until ack received (useful for critical paths)
    public RecordMetadata sendSync(OrderCreatedEvent event) throws Exception {
        var record = new ProducerRecord<String, Object>(TOPIC, event.orderId(), event);
        var future = kafkaTemplate.send(record);
        
        try {
            SendResult<String, Object> result = future.get(10, TimeUnit.SECONDS);
            return result.getRecordMetadata();
        } catch (TimeoutException e) {
            log.error("Kafka send timed out for orderId={}", event.orderId());
            throw e;
        } catch (ExecutionException e) {
            log.error("Kafka send failed for orderId={}", event.orderId(), e.getCause());
            throw new KafkaSendException("Failed to send order event", e.getCause());
        }
    }

    private void handleSendFailure(OrderCreatedEvent event, Throwable ex) {
        // Strategy 1: Save to outbox table — a background job will retry
        // Strategy 2: Write to a fallback topic (DLQ for producer failures)
        // Strategy 3: Alert monitoring, stop accepting new orders
        outboxRepository.save(new OutboxEvent(event.orderId(), event, ex.getMessage()));
    }
}
```

---

### 5.5 Transactional Outbox Pattern (Most Reliable Producer)

The biggest risk with Kafka producers: your DB write succeeds but Kafka send fails. Data is inconsistent.

```java
// Problem:
@Transactional
void placeOrder(PlaceOrderRequest request) {
    Order order = orderRepository.save(new Order(request));  // DB write: SUCCESS
    kafkaTemplate.send("order-events", order.getId(), new OrderCreatedEvent(order));
    // ^ What if THIS fails? Order is in DB but no Kafka event → inventory never notified
}

// Solution: Transactional Outbox Pattern
@Transactional
void placeOrder(PlaceOrderRequest request) {
    // 1. Save order to DB
    Order order = orderRepository.save(new Order(request));
    
    // 2. Save event to outbox table IN THE SAME TRANSACTION
    // If either fails, BOTH rollback → consistent state
    outboxRepository.save(new OutboxEvent(
        UUID.randomUUID().toString(),  // unique ID
        "order-events",                // target topic
        order.getId(),                 // kafka key
        toJson(new OrderCreatedEvent(order)),  // payload
        "PENDING"
    ));
    // At this point: order is saved AND outbox event is saved → atomically consistent
}

// Separate background job (runs every second):
@Scheduled(fixedDelay = 1000)
void publishOutboxEvents() {
    List<OutboxEvent> pending = outboxRepository.findByStatus("PENDING");
    for (OutboxEvent event : pending) {
        try {
            kafkaTemplate.send(event.topic(), event.key(), event.payload())
                .get(5, TimeUnit.SECONDS);  // sync wait
            event.setStatus("PUBLISHED");
            outboxRepository.save(event);
        } catch (Exception e) {
            event.incrementRetryCount();
            if (event.getRetryCount() > 5) {
                event.setStatus("FAILED");
                // Alert team
            }
            outboxRepository.save(event);
        }
    }
}
```

---

### 5.6 Consumer — Multiple Instances, Manual Offset, Error Handling

```java
package com.myapp.inventoryservice.kafka;

@Service
@Slf4j
public class OrderEventConsumer {

    private final InventoryService inventoryService;
    private final ProcessedMessageRepository processedRepo;

    // Multiple instances of THIS class can run across multiple pods.
    // Kafka ensures each partition goes to exactly ONE instance.
    // With 3 partitions, 3 instances → each handles 1 partition.

    @KafkaListener(
        topics = "order-events",
        groupId = "inventory-service-group",
        concurrency = "3",   // 3 consumer threads within this pod (parallel)
        containerFactory = "kafkaListenerContainerFactory"
    )
    public void handleOrderCreated(
            ConsumerRecord<String, OrderCreatedEvent> record,
            Acknowledgment ack) {   // manual ack — enable.auto.commit=false required

        String msgId = record.topic() + "-" + record.partition() + "-" + record.offset();
        log.info("Received: topic={} partition={} offset={} key={} msgId={}",
            record.topic(), record.partition(), record.offset(), record.key(), msgId);

        // Idempotency check — guard against redelivery
        if (processedRepo.existsById(msgId)) {
            log.warn("Duplicate message detected, skipping: {}", msgId);
            ack.acknowledge();   // must ack even duplicates, otherwise offset never moves
            return;
        }

        try {
            // Business logic
            inventoryService.reserveStock(record.value());

            // Mark as processed (idempotency record)
            processedRepo.save(new ProcessedMessage(msgId, Instant.now()));

            // Commit offset ONLY after successful processing
            ack.acknowledge();

        } catch (InventoryNotFoundException e) {
            // Permanent failure — don't retry, send to DLQ
            log.error("Permanent error for order {}: {}", record.key(), e.getMessage());
            // Spring's DefaultErrorHandler will send to DLQ after exhausting retries
            throw e;   // let Spring's error handler deal with it

        } catch (TransientException e) {
            // Transient failure — safe to retry
            log.warn("Transient error for order {}, will retry: {}", record.key(), e.getMessage());
            throw e;   // don't ack → Spring will retry based on backoff policy
        }
    }
}
```

---

### 5.7 Kafka Listener Container Factory — Full Configuration

```java
@Configuration
public class KafkaConsumerConfig {

    @Bean
    public ConsumerFactory<String, OrderCreatedEvent> consumerFactory() {
        Map<String, Object> props = new HashMap<>();
        props.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, "kafka1:9092,kafka2:9092");
        props.put(ConsumerConfig.GROUP_ID_CONFIG, "inventory-service-group");
        props.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");
        props.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, false);      // manual commit
        props.put(ConsumerConfig.MAX_POLL_RECORDS_CONFIG, 100);
        props.put(ConsumerConfig.MAX_POLL_INTERVAL_MS_CONFIG, 300000);
        props.put(ConsumerConfig.SESSION_TIMEOUT_MS_CONFIG, 30000);
        props.put(ConsumerConfig.HEARTBEAT_INTERVAL_MS_CONFIG, 3000);
        props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
        props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, JsonDeserializer.class);
        props.put(JsonDeserializer.TRUSTED_PACKAGES, "com.myapp.events");

        return new DefaultKafkaConsumerFactory<>(props);
    }

    @Bean
    public ConcurrentKafkaListenerContainerFactory<String, OrderCreatedEvent>
            kafkaListenerContainerFactory() {

        var factory = new ConcurrentKafkaListenerContainerFactory<String, OrderCreatedEvent>();
        factory.setConsumerFactory(consumerFactory());

        // MANUAL_IMMEDIATE: ack() is called by your code, commits immediately
        // MANUAL: ack() is called by your code, batches commits
        // RECORD: auto-commit after each record
        // BATCH: auto-commit after each batch
        factory.getContainerProperties().setAckMode(ContainerProperties.AckMode.MANUAL_IMMEDIATE);

        // Retry policy: retry 3 times with exponential backoff, then send to DLQ
        factory.setCommonErrorHandler(errorHandler());

        return factory;
    }

    @Bean
    public DefaultErrorHandler errorHandler() {
        // Exponential backoff: 1s → 2s → 4s → 8s (3 retries, then DLQ)
        ExponentialBackOffWithMaxRetries backoff = new ExponentialBackOffWithMaxRetries(3);
        backoff.setInitialInterval(1000L);     // 1 second
        backoff.setMultiplier(2.0);            // doubles each time
        backoff.setMaxInterval(10000L);        // max 10 seconds between retries

        DefaultErrorHandler errorHandler = new DefaultErrorHandler(
            new DeadLetterPublishingRecoverer(kafkaTemplate(),
                (record, ex) -> new TopicPartition(
                    record.topic() + ".DLQ",   // DLQ topic = original-topic.DLQ
                    record.partition()          // same partition in DLQ
                )
            ),
            backoff
        );

        // Don't retry these exceptions — send to DLQ immediately
        errorHandler.addNotRetryableExceptions(
            JsonProcessingException.class,      // bad JSON — retrying won't help
            DataIntegrityViolationException.class  // DB constraint — retrying won't help
        );

        return errorHandler;
    }
}
```

---

## 6. DEAD LETTER QUEUE (DLQ) — FULL PATTERN

### 6.1 Why DLQ Exists

```
Problem without DLQ:
  Message #500 is malformed → consumer throws exception → retried 3 times → fails again
  → Consumer is STUCK at offset 500 → can never move to offset 501
  → LAG keeps growing → the entire partition is blocked by ONE bad message
  → This is called "poison pill" — one bad message blocks all subsequent messages

DLQ Solution:
  After N retries → move message to a separate "dead letter" topic
  → Continue processing offset 501, 502, 503 → normal processing resumes
  → DLQ topic holds all failed messages for investigation and manual retry
```

---

### 6.2 DLQ Architecture

```
Normal flow:
  order-events → inventory-service → processes → ack

Failed message flow:
  order-events (offset 500) → inventory-service
    → Exception → retry 1 (after 1s)
    → Exception → retry 2 (after 2s)
    → Exception → retry 3 (after 4s)
    → All retries exhausted
    → Send to order-events.DLQ
    → ack offset 500 → move to 501 (normal processing resumes)

DLQ topic: order-events.DLQ
  → Contains only failed messages
  → Separate consumer (DLQ processor) reads these:
      → Inspect the failure
      → Fix the data and re-publish to order-events (manual retry)
      → Or: store in DB for human review
      → Or: discard if truly unprocessable
```

---

### 6.3 DLQ Configuration in Spring Boot

```java
// Producer Config — needed for DLQ publisher
@Bean
public KafkaTemplate<Object, Object> kafkaTemplate() {
    return new KafkaTemplate<>(producerFactory());
}

// The DeadLetterPublishingRecoverer sends to DLQ topic
// It adds headers to the DLQ message:
//   kafka_dlt-original-topic: order-events
//   kafka_dlt-original-partition: 0
//   kafka_dlt-original-offset: 500
//   kafka_dlt-exception-message: "NullPointerException: orderId is null"
//   kafka_dlt-exception-stacktrace: full stack trace
```

**DLQ consumer — process failed messages:**
```java
@Service
@Slf4j
public class DlqProcessor {

    @KafkaListener(
        topics = "order-events.DLQ",
        groupId = "inventory-service-dlq-group"
    )
    public void processDlqMessage(
            ConsumerRecord<String, OrderCreatedEvent> record,
            @Header(KafkaDltHeaders.DLT_EXCEPTION_MESSAGE) String exceptionMessage,
            @Header(KafkaDltHeaders.DLT_ORIGINAL_TOPIC) String originalTopic,
            @Header(KafkaDltHeaders.DLT_ORIGINAL_OFFSET) long originalOffset) {

        log.error("DLQ message received: originalTopic={} originalOffset={} error={}",
            originalTopic, originalOffset, exceptionMessage);

        OrderCreatedEvent event = record.value();

        // Strategy 1: Auto-fix and republish
        if (isFixable(event, exceptionMessage)) {
            OrderCreatedEvent fixed = fixEvent(event);
            kafkaTemplate.send(originalTopic, record.key(), fixed);
            log.info("DLQ message fixed and republished: orderId={}", event.orderId());
            return;
        }

        // Strategy 2: Store in DB for manual review
        dlqRepository.save(new DlqRecord(
            record.key(),
            toJson(event),
            exceptionMessage,
            originalTopic,
            originalOffset,
            Instant.now()
        ));
        log.warn("DLQ message stored for manual review: orderId={}", event.orderId());

        // Strategy 3: Alert (Slack/PagerDuty) if DLQ is filling up
        if (dlqRepository.countByStatus("PENDING") > 100) {
            alertService.sendAlert("DLQ has >100 pending messages!");
        }
    }

    @Scheduled(cron = "0 0 * * * *")  // every hour
    void retryDlqMessages() {
        // Retry messages that failed > 2 hours ago (maybe transient issue is resolved)
        List<DlqRecord> toRetry = dlqRepository.findOlderThan(Duration.ofHours(2));
        for (DlqRecord record : toRetry) {
            kafkaTemplate.send(record.getOriginalTopic(), record.getKey(), record.getPayload());
            record.setStatus("RETRIED");
            dlqRepository.save(record);
        }
    }
}
```

---

## 7. SAGA PATTERN WITH KAFKA IN SPRING BOOT MICROSERVICES

> The Saga pattern manages distributed transactions across multiple microservices. Instead of a 2-phase commit (which Kafka doesn't support), each service does its work and publishes an event. If something fails, compensating events undo the previous steps.

---

### 7.1 The Business Scenario

```
Place Order flow (distributed across 4 services):
  1. order-service:      Create order (status=PENDING)
  2. inventory-service:  Reserve stock
  3. payment-service:    Charge customer
  4. shipping-service:   Schedule shipment

If payment fails: undo stock reservation + cancel order
If shipping fails: refund payment + release stock + cancel order
```

---

### 7.2 Choreography Saga (No Central Coordinator)

```
Services react to events — no central brain. Each service does its part and emits the next event.

ORDER FLOW:
  order-service     → publishes  → order-events/OrderCreated
  inventory-service ← consumes   ← OrderCreated
  inventory-service → publishes  → inventory-events/StockReserved  (or StockReservationFailed)
  payment-service   ← consumes   ← StockReserved
  payment-service   → publishes  → payment-events/PaymentProcessed  (or PaymentFailed)
  shipping-service  ← consumes   ← PaymentProcessed
  shipping-service  → publishes  → shipping-events/ShipmentScheduled

COMPENSATION FLOW (if PaymentFailed):
  payment-service   → publishes  → payment-events/PaymentFailed
  inventory-service ← consumes   ← PaymentFailed
  inventory-service → publishes  → inventory-events/StockReleased   (compensate)
  order-service     ← consumes   ← PaymentFailed
  order-service     → publishes  → order-events/OrderCancelled       (compensate)
```

**Topics:**
```
order-events        → OrderCreated, OrderApproved, OrderCancelled, OrderCompleted
inventory-events    → StockReserved, StockReservationFailed, StockReleased
payment-events      → PaymentProcessed, PaymentFailed, PaymentRefunded
shipping-events     → ShipmentScheduled, ShipmentFailed
```

---

### 7.3 Java Code — Choreography Saga

**order-service:**
```java
@Service
@Slf4j
public class OrderService {

    private final OrderRepository orderRepo;
    private final OrderEventProducer producer;

    @Transactional
    public Order placeOrder(PlaceOrderRequest req) {
        Order order = orderRepo.save(Order.builder()
            .customerId(req.customerId())
            .productId(req.productId())
            .quantity(req.quantity())
            .status(OrderStatus.PENDING)
            .build());

        // Outbox pattern: event saved in same transaction
        producer.sendOrderCreated(new OrderCreatedEvent(
            order.getId(), order.getCustomerId(), order.getProductId(),
            order.getQuantity(), order.getTotalAmount(),
            UUID.randomUUID().toString(), Instant.now()
        ));

        log.info("Order placed: {}", order.getId());
        return order;
    }

    // Saga compensation: handle payment failure
    @KafkaListener(topics = "payment-events", groupId = "order-service-group")
    @Transactional
    public void handlePaymentFailed(ConsumerRecord<String, PaymentFailedEvent> record) {
        PaymentFailedEvent event = record.value();
        Order order = orderRepo.findById(event.orderId()).orElseThrow();
        
        order.setStatus(OrderStatus.CANCELLED);
        order.setCancellationReason("Payment failed: " + event.reason());
        orderRepo.save(order);

        producer.sendOrderCancelled(new OrderCancelledEvent(
            order.getId(), "Payment failed: " + event.reason(),
            UUID.randomUUID().toString(), Instant.now()
        ));

        log.info("Order {} cancelled due to payment failure", order.getId());
    }

    // Saga completion: shipping scheduled → order is done
    @KafkaListener(topics = "shipping-events", groupId = "order-service-group")
    @Transactional
    public void handleShipmentScheduled(ConsumerRecord<String, ShipmentScheduledEvent> record) {
        ShipmentScheduledEvent event = record.value();
        Order order = orderRepo.findById(event.orderId()).orElseThrow();
        order.setStatus(OrderStatus.CONFIRMED);
        order.setTrackingNumber(event.trackingNumber());
        orderRepo.save(order);
        log.info("Order {} confirmed, tracking: {}", order.getId(), event.trackingNumber());
    }
}
```

**inventory-service:**
```java
@Service
@Slf4j
public class InventoryService {

    private final InventoryRepository inventoryRepo;
    private final InventoryEventProducer producer;

    @KafkaListener(topics = "order-events", groupId = "inventory-service-group")
    @Transactional
    public void handleOrderCreated(
            ConsumerRecord<String, OrderCreatedEvent> record, Acknowledgment ack) {
        
        OrderCreatedEvent event = record.value();
        log.info("Reserving stock for order: {}", event.orderId());

        Optional<Inventory> inventory = inventoryRepo.findByProductId(event.productId());

        if (inventory.isEmpty() || inventory.get().getAvailableQuantity() < event.quantity()) {
            // Not enough stock → saga compensation: cancel the order
            log.warn("Insufficient stock for order: {}", event.orderId());
            producer.sendStockReservationFailed(new StockReservationFailedEvent(
                event.orderId(), event.productId(),
                "Insufficient stock: available=" + 
                    inventory.map(Inventory::getAvailableQuantity).orElse(0),
                UUID.randomUUID().toString(), Instant.now()
            ));
            ack.acknowledge();
            return;
        }

        // Reserve stock
        Inventory inv = inventory.get();
        inv.setAvailableQuantity(inv.getAvailableQuantity() - event.quantity());
        inv.setReservedQuantity(inv.getReservedQuantity() + event.quantity());
        inventoryRepo.save(inv);

        // Proceed to next saga step
        producer.sendStockReserved(new StockReservedEvent(
            event.orderId(), event.productId(), event.quantity(),
            UUID.randomUUID().toString(), Instant.now()
        ));

        ack.acknowledge();
        log.info("Stock reserved for order: {}", event.orderId());
    }

    // Compensating transaction: payment failed → release the reserved stock
    @KafkaListener(topics = "payment-events", groupId = "inventory-service-group")
    @Transactional
    public void handlePaymentFailed(
            ConsumerRecord<String, PaymentFailedEvent> record, Acknowledgment ack) {

        PaymentFailedEvent event = record.value();
        log.info("Releasing stock for cancelled order: {}", event.orderId());

        // Find the reservation and release it
        inventoryRepo.findReservationByOrderId(event.orderId()).ifPresent(inv -> {
            inv.setAvailableQuantity(inv.getAvailableQuantity() + event.quantity());
            inv.setReservedQuantity(inv.getReservedQuantity() - event.quantity());
            inventoryRepo.save(inv);
        });

        ack.acknowledge();
        log.info("Stock released for order: {}", event.orderId());
    }
}
```

---

### 7.4 Orchestration Saga (Central Saga Orchestrator)

```
One "Saga Orchestrator" service manages the entire workflow.
It knows all steps and sends commands to each service.

ORDER SAGA ORCHESTRATOR:
  1. Receive PlaceOrderRequest
  2. Send ReserveStockCommand → inventory-service
  3. Wait for StockReservedEvent OR StockFailedEvent
  4. If StockReserved: Send ProcessPaymentCommand → payment-service
  5. If StockFailed: Send CancelOrderCommand → order-service (compensation)
  6. If PaymentProcessed: Send ScheduleShipmentCommand → shipping-service
  7. If PaymentFailed: Send ReleaseStockCommand → inventory-service (compensation)
                       Send CancelOrderCommand → order-service (compensation)
  8. If ShipmentScheduled: Complete saga → mark order CONFIRMED

Advantages over choreography:
  ✅ Single place to see the whole flow
  ✅ Easier to add/remove steps
  ✅ Better error handling and compensation logic

Disadvantages:
  ❌ Orchestrator is a single point of failure (mitigate: make it stateless, use DB state)
  ❌ Tight coupling to orchestrator
```

**Orchestrator implementation:**
```java
@Service
@Slf4j
public class PlaceOrderSagaOrchestrator {

    private final SagaStateRepository sagaRepo;
    private final KafkaTemplate<String, Object> kafka;

    // Step 1: Start the saga
    @Transactional
    public void startSaga(String orderId, PlaceOrderRequest req) {
        SagaState state = new SagaState(orderId, SagaStep.RESERVING_STOCK);
        sagaRepo.save(state);

        kafka.send("inventory-commands", orderId,
            new ReserveStockCommand(orderId, req.productId(), req.quantity()));
        log.info("Saga started for orderId={}", orderId);
    }

    // Step 2: Stock reserved → go to payment
    @KafkaListener(topics = "inventory-events", groupId = "saga-orchestrator-group")
    @Transactional
    public void onStockReserved(ConsumerRecord<String, StockReservedEvent> record, Acknowledgment ack) {
        StockReservedEvent event = record.value();
        SagaState state = sagaRepo.findByOrderId(event.orderId()).orElseThrow();
        
        if (state.getCurrentStep() != SagaStep.RESERVING_STOCK) {
            ack.acknowledge(); // duplicate or out-of-order — ignore
            return;
        }

        state.setCurrentStep(SagaStep.PROCESSING_PAYMENT);
        sagaRepo.save(state);

        kafka.send("payment-commands", event.orderId(),
            new ProcessPaymentCommand(event.orderId(), state.getCustomerId(), state.getAmount()));
        ack.acknowledge();
    }

    // Compensation: stock reservation failed → cancel order
    @KafkaListener(topics = "inventory-events", groupId = "saga-orchestrator-group")
    @Transactional
    public void onStockFailed(ConsumerRecord<String, StockReservationFailedEvent> record, Acknowledgment ack) {
        StockReservationFailedEvent event = record.value();
        SagaState state = sagaRepo.findByOrderId(event.orderId()).orElseThrow();

        state.setCurrentStep(SagaStep.FAILED);
        state.setFailureReason(event.reason());
        sagaRepo.save(state);

        kafka.send("order-commands", event.orderId(),
            new CancelOrderCommand(event.orderId(), "Stock not available: " + event.reason()));
        ack.acknowledge();
        log.warn("Saga failed at stock step for orderId={}", event.orderId());
    }
}
```

---

### 7.5 Saga Edge Cases — Interview Questions

**Q: What if the same saga step executes twice (duplicate event)?**
```
Use saga state machine: check current step before processing.
If currentStep != expected step → ignore the event (already processed or wrong order).
Store processed event IDs with the saga state.
```

**Q: What if the orchestrator crashes in the middle of a saga?**
```
Saga state is persisted in DB (SagaState table).
When orchestrator restarts, it reads pending sagas from DB.
A scheduled job scans for sagas that are STUCK (no update in >5 minutes).
It re-sends the appropriate command based on current saga step.
→ Exactly why idempotent consumers are critical — re-sent commands must be safe to re-execute.
```

**Q: What if compensation (rollback) also fails?**
```
This is "saga failure mode" — a stuck compensation.
Solutions:
  1. Retry compensation with exponential backoff (DLQ for compensation failures)
  2. Human intervention queue — alert operations team
  3. Compensating compensation — even more steps to undo the undo
  4. Eventual consistency — accept inconsistency, fix it manually or via background job
```

---

## 8. PARTITION DEEP DIVE

### 8.1 Why Partitions Exist

```
Without partitions (1 partition):
  - Only ONE consumer can read from the topic at a time
  - Producer throughput is limited by ONE broker's disk write speed
  - No parallelism at all

With 10 partitions:
  - 10 consumer instances can read in parallel (10x throughput)
  - Messages are distributed across multiple brokers (distributed storage)
  - Each partition is an independent ordered log
  - ORDER is guaranteed WITHIN a partition (not across partitions)
```

**Choosing partition count:**
```
Too few partitions: Can't scale consumers beyond partition count
Too many partitions: 
  → More memory/file handles on brokers
  → Rebalancing takes longer (more partitions to reassign)
  → More ZooKeeper/KRaft metadata overhead
  → Longer leader election time when a broker fails

Rule of thumb:
  Target throughput / per-consumer throughput = number of partitions
  
  If you expect 1 GB/s total throughput and each consumer handles 50 MB/s:
  1000 MB/s ÷ 50 MB/s = 20 partitions

  Start with: max(3, number of consumers you'll ever need)
  Common choices: 6, 12, 24 (multiples of 2 and 3 → flexible assignment)
```

---

### 8.2 How Kafka Assigns Messages to Partitions

```
Step 1: Does the message have a key?

  Key = NULL:
    Old Kafka: Round-robin across partitions
    New Kafka (2.4+): Sticky partitioner
      → Fills up one partition's batch before moving to next
      → Better batching efficiency, still approximately round-robin

  Key = "account-123":
    partition = murmur2(key.getBytes()) % numPartitions
    → Always the same partition for the same key
    → ORDER guaranteed for all messages with the same key

Example:
  murmur2("account-100") % 3 = 0   → always Partition 0
  murmur2("account-200") % 3 = 1   → always Partition 1
  murmur2("account-300") % 3 = 2   → always Partition 2
  murmur2("account-400") % 3 = 0   → also Partition 0 (hash collision is fine)
```

**WARNING — Changing partition count breaks key-based ordering:**
```
Before (3 partitions):
  "account-100" → murmur2("account-100") % 3 = 0 → Partition 0

After (add 4th partition):
  "account-100" → murmur2("account-100") % 4 = 3 → Partition 3

New messages go to Partition 3.
Old messages for "account-100" are still in Partition 0.
Two consumers process them in parallel → ordering is broken.

How to handle it:
  Option 1: Stop producer → drain all existing messages → then increase partitions
  Option 2: Create new topic with new partition count → migrate to new topic
  Option 3: Accept brief ordering issue (only for low-stakes data)
  NOTE: You can only INCREASE partitions, never decrease.
```

---

### 8.3 Why to Send a Message to a Specific Partition — Use Cases

```
Use case 1: Ensure all events for one entity are processed in order by the same consumer
  → Use key (orderId, accountId) — Kafka routes to same partition automatically
  → Don't need explicit partition — keys handle this

Use case 2: A specific consumer has special processing capability (more RAM, GPU)
  → Route GPU-intensive tasks to Partition 2 which is owned by the GPU pod
  → Use explicit partition assignment
  
Use case 3: Time-based routing (old data vs new data on different partitions)
  → Explicit partition based on date
  
Use case 4: A/B testing — route 10% of traffic to a new consumer on a specific partition
  → Custom partitioner that routes 10% to Partition 0, 90% to others

Use case 5: Debugging — reproduce an issue by replaying a specific partition
  → Seek to a specific offset on Partition 1 to replay
```

---

## 9. REPLICATION, FAULT TOLERANCE AND DATA LOSS PREVENTION

### 9.1 Replication Factor and ISR

```
Replication Factor = how many copies of each partition exist

replication.factor=1: Only 1 copy (no redundancy) — if broker dies, data LOST
replication.factor=2: 1 leader + 1 follower — 1 broker failure tolerated
replication.factor=3: 1 leader + 2 followers — 2 broker failures tolerated (recommended for prod)

The formula: can tolerate (replication.factor - 1) broker failures

Production setup:
  replication.factor=3
  min.insync.replicas=2   ← minimum brokers that must be in sync to accept writes
  acks=all                ← wait for all ISR brokers to confirm

This means:
  - 3 brokers total, all must be running for clean operation
  - 1 broker can fail → 2 remaining → still ≥ min.insync.replicas (2) → writes succeed
  - 2 brokers fail → 1 remaining → ISR=1 < min.insync.replicas=2 → 
    producer gets NotEnoughReplicasException → producer retries or fails
    → Better to REJECT writes than to accept data that might be lost
```

---

### 9.2 What Happens When a Broker Goes Down

```
Scenario: Broker 2 (leader for Partition 1) crashes

Step 1 (0-30 seconds):
  Controller detects Broker 2 is gone (heartbeat timeout)
  Controller selects new leader from ISR: picks Broker 3 (was a follower)
  Controller updates cluster metadata (broadcasts to all brokers)
  All producers/consumers automatically reconnect to new leader (Broker 3)

Step 2:
  Broker 3 is now both:
    Leader of Partition 1 (was Broker 2's)
    Follower of Partition 0 (was always this)
  
  Writes resume normally — zero data loss (data was already in Broker 3 as a follower)

Step 3 (when Broker 2 comes back):
  Broker 2 rejoins as a follower for Partition 1
  Syncs up with Broker 3 (replicates missing messages)
  Once caught up, added back to ISR
  Eventually may be re-elected as leader for Partition 1

From the producer/consumer perspective:
  Brief reconnect (~1-5 seconds for leader election + reconnect)
  No data loss
  No manual intervention needed
```

---

### 9.3 Topic or Partition Corruption — How to Detect and Recover

**Detection:**
```bash
# Check partition health — look for "under-replicated" partitions
kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --describe \
  --under-replicated-partitions
# Shows partitions where ISR < replication.factor
# These partitions are at risk — if leader dies, data may be lost

# Check for offline partitions (no leader)
kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --describe \
  --unavailable-partitions
# These partitions have NO leader → producers/consumers can't access them → immediate alert!

# Check broker status
kafka-broker-api-versions.sh \
  --bootstrap-server localhost:9092
# Lists all reachable brokers — if some are missing → investigate
```

**What "partition corruption" looks like:**
```
Symptoms:
  → kafka.log.CorruptRecordException in broker logs
  → Consumers stuck at a specific offset (can't parse the record)
  → Broker crashes on startup trying to load a corrupted segment

Recovery steps:

Step 1: Identify the corrupted segment
  kafka-dump-log.sh --files /var/kafka/logs/order-events-0/*.log --print-data-log
  → Read error at a specific offset? That's the corrupt point.

Step 2: Try log recovery tool
  bin/kafka-server-start.sh --config server.properties
  # Kafka will automatically run log recovery on startup
  # It truncates the log to the last valid offset

Step 3: If partition is available on another replica (replicas are clean):
  On the corrupted broker:
  # Delete the local corrupted log files for that partition
  rm -rf /var/kafka/logs/order-events-0/
  # Restart the broker
  # Broker will re-sync from the leader → gets clean data from another replica

Step 4: If ALL replicas are corrupted (data is permanently lost):
  # This should NEVER happen with replication.factor=3 unless 3 brokers simultaneously fail
  # Last resort: restore from backup (S3 backup of broker log files)
  # Or: accept data loss for the corrupted segment, reset consumer offset past it:
  kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
    --group my-group --topic order-events \
    --reset-offsets --to-offset 1500 --execute  # skip past the corrupted offset

Step 5: Alert and post-mortem
  → How did all replicas get corrupted simultaneously?
  → Was it a disk failure (RAID issue)?
  → Was it a Kafka version bug?
  → Add monitoring for disk health
```

---

### 9.4 Precautions to Prevent Data Loss

**At the Kafka cluster level:**
```
✅ replication.factor=3 (MINIMUM for production)
✅ min.insync.replicas=2 (reject writes if only 1 replica available)
✅ unclean.leader.election.enable=false
   → Do NOT allow out-of-sync replicas to become leader
   → If true: faster recovery but RISKS data loss (out-of-sync replica may be missing messages)
   → If false: wait for an in-sync replica to be available (safe)
✅ log.retention.hours=168 (7 days) — adjust based on your needs
✅ Monitor disk space — full disk = broker stops accepting writes
✅ Distribute brokers across AZs (availability zones) — rack.id configuration
✅ Keep Kafka version up to date — many data integrity fixes in newer versions
```

**At the producer level:**
```
✅ acks=all
✅ enable.idempotence=true
✅ retries=Integer.MAX_VALUE (with delivery.timeout.ms as the time limit)
✅ Use the Transactional Outbox pattern — never lose events between DB and Kafka
✅ Monitor producer error callback — log and alert on send failures
```

**At the consumer level:**
```
✅ enable.auto.commit=false (manual commit)
✅ Commit AFTER processing (at-least-once — make consumer idempotent)
✅ DLQ for poison pill messages — never let one bad message block a partition
✅ Monitor consumer lag — alert if lag grows
✅ Set appropriate session.timeout.ms and max.poll.interval.ms
```

**Backup strategy:**
```
Use Kafka's MirrorMaker 2 to replicate topics to a DR (disaster recovery) cluster:
  Cluster 1 (us-east-1): order-events [prod]
  MirrorMaker 2 replicates to:
  Cluster 2 (us-west-2): order-events [DR]
  → If us-east-1 region goes down → switch consumers to us-west-2
  → Data lag: typically <1 second (near real-time replication)
```

---

## 10. EXACTLY-ONCE SEMANTICS

### 10.1 Delivery Guarantees — The Three Levels

```
AT MOST ONCE (acks=0, no retry):
  Producer: fire and forget
  Consumer: commit before processing
  
  Behavior:
  → Message may be LOST (producer crash, ack not received)
  → Message is NEVER duplicated
  Use when: log events, analytics where loss is acceptable

AT LEAST ONCE (acks=all, enable.idempotence=true, manual commit after processing):
  Producer: retry on failure, idempotence for broker-level dedup
  Consumer: commit after processing
  
  Behavior:
  → Message is NEVER lost
  → Message MAY be duplicated (consumer reprocesses on restart)
  → Must make consumer idempotent
  Use when: most business events — orders, payments, notifications
  This is the most common in practice.

EXACTLY ONCE (Kafka Transactions):
  Producer + Consumer in same Kafka transaction
  Consume → process → produce → all atomic
  
  Behavior:
  → Message is NEVER lost
  → Message is NEVER duplicated
  → Highest overhead (2x latency, lower throughput)
  Use when: financial ledger, audit log where duplicates would cause real problems
```

---

### 10.2 Kafka Transactions (Exactly-Once)

```java
// Producer side — mark as transactional
props.put(ProducerConfig.TRANSACTIONAL_ID_CONFIG, "order-producer-1");
// Each producer instance needs a unique transactional ID
// For multiple instances: "order-producer-" + instanceId

KafkaProducer<String, Object> producer = new KafkaProducer<>(props);
producer.initTransactions();

try {
    producer.beginTransaction();
    
    // All sends in this transaction are atomic
    producer.send(new ProducerRecord<>("order-events", orderId, orderCreatedEvent));
    producer.send(new ProducerRecord<>("audit-log", orderId, auditEvent));
    
    producer.commitTransaction();   // both messages committed atomically
} catch (ProducerFencedException e) {
    // Another producer with same transactional ID took over → close this one
    producer.close();
} catch (KafkaException e) {
    producer.abortTransaction();    // rollback both messages
    // retry or handle failure
}
```

**Read-process-write (consume → transform → produce — all atomic):**
```java
// In Spring Boot with KafkaTransactionManager:
@Transactional("kafkaTransactionManager")
@KafkaListener(topics = "raw-orders")
public void processAndForward(ConsumerRecord<String, RawOrder> record) {
    // This entire method is wrapped in a Kafka transaction:
    // 1. Consuming from raw-orders
    // 2. Sending to processed-orders
    // If any step fails, the Kafka transaction rolls back
    // → Consumer offset is NOT committed
    // → Produced message is NOT committed
    // → On retry: both re-happen atomically

    ProcessedOrder processed = orderTransformer.transform(record.value());
    kafkaTemplate.send("processed-orders", record.key(), processed);
    // offset for raw-orders is committed as part of the SAME transaction
}
```

---

## 11. ADVANCED TOPICS

### 11.1 Log Compaction

```
Normal topic: retains messages for N hours (log.retention.hours=168)
  All messages for all versions of a key are kept.
  After 7 days, messages are deleted regardless of key.

Compacted topic: retains ONLY the latest value for each key FOREVER
  log.cleanup.policy=compact
  
  Use case: "current state" topics
    → "What is the current stock level for product-X?"
    → Don't need history, just latest value
    → topic: product-stock
        Key: "product-123" → latest value: {"stock": 45}
        Key: "product-456" → latest value: {"stock": 0}
    
  Tombstone: send a message with key="product-123" value=NULL
    → Kafka removes this key from the compacted log
    → Signals "this entity was deleted"
  
  Real-world use:
    - User profile topic (latest profile state for each userId)
    - Configuration topic (latest config for each service)
    - Cache warming (consumers read the topic to rebuild in-memory state)
```

### 11.2 Message Headers

```java
// Add headers to a Kafka message (useful for distributed tracing)
ProducerRecord<String, OrderCreatedEvent> record = new ProducerRecord<>(
    "order-events", "account-123", orderEvent
);
record.headers().add("X-Correlation-Id", correlationId.getBytes());
record.headers().add("X-Source-Service", "order-service".getBytes());
record.headers().add("X-Timestamp", Instant.now().toString().getBytes());

// Consumer reads headers:
@KafkaListener(topics = "order-events")
public void consume(ConsumerRecord<String, OrderCreatedEvent> record) {
    String correlationId = new String(record.headers().lastHeader("X-Correlation-Id").value());
    MDC.put("correlationId", correlationId);  // add to logs for tracing
    // process...
}
```

### 11.3 Schema Registry (Avro/Protobuf)

```
Problem: Producer sends JSON, consumer expects different JSON structure → crash.
         No contract between producer and consumer.

Solution: Schema Registry (Confluent Schema Registry or AWS Glue Schema Registry)
  - Producer registers schema version when sending
  - Consumer validates schema version before deserializing
  - Schema evolution with compatibility rules:
      BACKWARD: new schema can read old messages (add optional fields)
      FORWARD:  old schema can read new messages (delete fields)
      FULL:     both directions compatible

Spring Boot with Avro + Schema Registry:
  Producer serializer: KafkaAvroSerializer
  Consumer deserializer: KafkaAvroDeserializer
  → Automatically validates against registry on every message
```

---

## 12. ESSENTIAL CLI COMMANDS — WHERE TO RUN AND WHY

> Run these inside the Kafka container (`docker exec -it kafka bash`) or from any machine with Kafka binaries and access to the bootstrap server.

---

### Topic Management

```bash
# Create topic (always specify partitions and replication for production)
kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --topic order-events \
  --create \
  --partitions 3 \
  --replication-factor 3 \
  --config min.insync.replicas=2 \
  --config retention.ms=604800000    # 7 days

# List all topics
kafka-topics.sh --bootstrap-server localhost:9092 --list

# Describe a topic (shows partitions, leaders, ISR, replicas)
kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --topic order-events \
  --describe
# Output shows:
# Topic: order-events  Partition: 0  Leader: 1  Replicas: 1,2,3  Isr: 1,2,3
# Topic: order-events  Partition: 1  Leader: 2  Replicas: 2,3,1  Isr: 2,3,1
# Topic: order-events  Partition: 2  Leader: 3  Replicas: 3,1,2  Isr: 3,1,2

# Find UNDER-REPLICATED partitions (ISR < replication factor = problem!)
kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --describe \
  --under-replicated-partitions

# Find OFFLINE partitions (no leader = total outage for that partition!)
kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --describe \
  --unavailable-partitions

# Increase partition count (CANNOT decrease!)
kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --topic order-events \
  --alter \
  --partitions 6

# Delete a topic
kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --topic order-events \
  --delete
```

---

### Consumer Group Management

```bash
# List all consumer groups
kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --list

# Describe a group — SEE LAG, PARTITION ASSIGNMENT, HOST
kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --group inventory-service-group \
  --describe
# Key columns: PARTITION, CURRENT-OFFSET, LOG-END-OFFSET, LAG, CONSUMER-ID, HOST
# LAG > 0 = consumer is behind
# CONSUMER-ID empty = no consumer assigned to that partition (problem!)
# HOST = which machine the consumer is on (helps you find the specific pod)

# Monitor lag in real-time (runs every 5 seconds)
watch -n 5 "kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --group inventory-service-group \
  --describe"

# Describe all groups at once
kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --all-groups \
  --describe

# Reset consumer group offset (STOP consumers first!)
# To beginning:
kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --group inventory-service-group \
  --topic order-events \
  --reset-offsets \
  --to-earliest \
  --execute

# To end (skip all existing messages):
kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --group inventory-service-group \
  --topic order-events \
  --reset-offsets \
  --to-latest \
  --execute

# Shift by N (e.g., go back 100 messages):
kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --group inventory-service-group \
  --topic order-events \
  --reset-offsets \
  --shift-by -100 \
  --execute

# To a specific offset:
kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --group inventory-service-group \
  --topic order-events \
  --reset-offsets \
  --to-offset 500 \
  --execute

# To a specific datetime (replay events from a point in time):
kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --group inventory-service-group \
  --topic order-events \
  --reset-offsets \
  --to-datetime 2024-01-15T10:00:00.000 \
  --execute

# Dry run first (see what WOULD happen without changing anything):
kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --group inventory-service-group \
  --topic order-events \
  --reset-offsets \
  --to-earliest \
  --dry-run    # no --execute → preview only

# Delete a consumer group (removes all offset tracking for this group)
kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --group old-service-group \
  --delete
```

---

### Production and Consumption (CLI Testing)

```bash
# Produce messages (with key — useful for testing partition assignment)
kafka-console-producer.sh \
  --bootstrap-server localhost:9092 \
  --topic order-events \
  --property key.separator=: \
  --property parse.key=true
# Type: account-100:{"orderId":"1","amount":100}
# Type: account-200:{"orderId":"2","amount":200}

# Consume all messages from beginning, show offset and key
kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic order-events \
  --from-beginning \
  --property print.key=true \
  --property print.offset=true \
  --property print.timestamp=true \
  --property print.partition=true

# Consume from a specific partition only
kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic order-events \
  --partition 0 \
  --from-beginning

# Consume from specific offset on specific partition
kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic order-events \
  --partition 0 \
  --offset 42          # start from offset 42

# Read DLQ messages
kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic order-events.DLQ \
  --from-beginning \
  --property print.headers=true \
  --property print.offset=true

# Count messages in a topic/partition
kafka-run-class.sh kafka.tools.GetOffsetShell \
  --broker-list localhost:9092 \
  --topic order-events \
  --time -1   # latest offset (= total messages since beginning)
```

---

### Cluster Management

```bash
# List all brokers in the cluster
kafka-broker-api-versions.sh --bootstrap-server localhost:9092
# Or check controller:
kafka-metadata-shell.sh --snapshot /tmp/kafka-logs/__cluster_metadata-0/00000000000000000000.log
# (KRaft mode only)

# Check topic partition leader balance
kafka-topics.sh --bootstrap-server localhost:9092 --describe
# Check if all partitions have leaders from different brokers (well-balanced)

# Trigger preferred leader election (rebalance leaders to original/preferred brokers)
kafka-leader-election.sh \
  --bootstrap-server localhost:9092\
  --election-type preferred \
  --all-topic-partitions

# Read a log file directly (for debugging corruption)
kafka-dump-log.sh \
  --files /var/kafka/logs/order-events-0/00000000000000000000.log \
  --print-data-log | head -50
```

---

## 13. MONITORING — METRICS EVERY DEVELOPER MUST KNOW

### 13.1 Producer Metrics

| Metric | What It Means | Alert If |
|--------|--------------|----------|
| `record-send-rate` | Messages/sec sent | Drops suddenly |
| `record-error-rate` | Messages/sec failed | > 0 (should always be 0) |
| `record-retry-rate` | Messages/sec retried | > 0 (indicates broker issues) |
| `request-latency-avg` | Avg time to get ack | > 100ms |
| `outgoing-byte-rate` | Bytes/sec to broker | Drops (producer slowing down) |
| `batch-size-avg` | Avg batch size | Too small = too many requests |

### 13.2 Consumer Metrics

| Metric | What It Means | Alert If |
|--------|--------------|----------|
| `records-consumed-rate` | Messages/sec consumed | Drops → consumer slowing |
| `records-lag` | LAG per partition | > threshold (e.g. > 1000) |
| `records-lag-max` | Maximum LAG across partitions | > threshold |
| `fetch-latency-avg` | Time to get records from broker | > 500ms |
| `commit-rate` | Offset commits/sec | Drops → commits failing |
| `join-total` | Consumer group rebalances | > 0 frequently → instability |

### 13.3 Broker Metrics (JMX)

| Metric | What It Means | Alert If |
|--------|--------------|----------|
| `UnderReplicatedPartitions` | Partitions not fully replicated | > 0 |
| `OfflinePartitionsCount` | Partitions with no leader | > 0 (immediate alert!) |
| `ActiveControllerCount` | Active controllers in cluster | != 1 |
| `BytesInPerSec` | Data rate to broker | Near disk/network limit |
| `RequestsPerSec` | Requests/sec per broker | Near broker capacity |

```java
// In Spring Boot — expose consumer lag metric
@Component
public class KafkaLagMetrics {

    @Autowired
    private KafkaListenerEndpointRegistry registry;

    @Scheduled(fixedDelay = 30000)
    public void reportLag() {
        registry.getListenerContainers().forEach(container -> {
            container.metrics().forEach((id, metrics) -> {
                metrics.entrySet().stream()
                    .filter(e -> e.getKey().name().contains("lag"))
                    .forEach(e -> log.info("Consumer lag metric: {} = {}", 
                        e.getKey().name(), e.getValue().metricValue()));
            });
        });
    }
}
```

---

## 14. TOP INTERVIEW QUESTIONS WITH FULL ANSWERS

---

**Q1: A consumer is not consuming messages. How do you find which consumer is stuck and why?**

> "First I run `kafka-consumer-groups.sh --describe` for the consumer group. The output shows CURRENT-OFFSET, LOG-END-OFFSET, and LAG per partition, plus CONSUMER-ID and HOST for each partition.
> A partition with LAG > 0 and the LAG not changing over time = stuck consumer. The HOST column shows which machine (pod) that consumer is on. I then go to that pod and check its logs for exceptions.
> Common causes: poison pill message causing infinite retry (fix: DLQ), consumer thread deadlock (fix: thread dump), max.poll.interval.ms exceeded because processing takes too long (fix: increase the config or reduce max.poll.records), or a network partition to the broker."

---

**Q2: What is the difference between acks=1, acks=0, acks=all?**

> "acks=0: producer doesn't wait for any acknowledgement. Fastest, but data can be lost if the broker crashes right after receiving the message.
> acks=1: producer waits for the leader to write the message. If the leader crashes before followers replicate, data is lost.
> acks=all (or -1): producer waits for all in-sync replicas to confirm. Combined with min.insync.replicas=2 and replication.factor=3, this gives the strongest durability guarantee. In production I always use acks=all."

---

**Q3: What happens if the Kafka broker sends the ack, but the producer never receives it due to a network issue?**

> "The producer assumes failure and retries. Without idempotence, this causes a duplicate — the broker gets the same message twice and writes it twice. The consumer then processes it twice.
> With enable.idempotence=true (the default in Kafka 3.x), the producer assigns a unique sequence number to each message. On retry, it sends the same sequence number. The broker detects 'I already wrote this sequence number' and drops the duplicate, then sends the ack. The consumer never sees the duplicate. This is producer-level idempotence — it doesn't protect against your own application logic generating the same event twice."

---

**Q4: What if a consumer processes a message but crashes before committing the offset?**

> "The consumer restarts from the last committed offset and reprocesses the message. This is at-least-once delivery — you will reprocess. The solution is an idempotent consumer: before processing, check if you've already handled this message (by topic+partition+offset or by a business-level UUID in the message). Store the processed message ID in your DB in the same transaction as your business logic. If you've already processed it, skip it and just commit the offset. This way, reprocessing is safe."

---

**Q5: Why do we use partitions? How do you send a message to a specific partition?**

> "Partitions enable parallel consumption and horizontal scaling. One consumer per partition allows N consumers to process concurrently. Order is guaranteed within a partition, not across partitions.
> For specific partition: use a message key — Kafka's murmur2 algorithm routes the same key to the same partition consistently. For explicit routing, use `new ProducerRecord<>(topic, partitionNumber, key, value)` or implement a custom Partitioner. I prefer keys over explicit partitions because they're resilient to broker changes."

---

**Q6: What is the Saga pattern? How does it handle failures?**

> "Saga is how you manage distributed transactions across microservices without 2-phase commit. Each service does its step and publishes an event. If a step fails, compensating events undo previous steps.
> For example, in an order flow: order-service creates the order → inventory-service reserves stock → payment-service charges the customer. If payment fails, payment-service publishes PaymentFailed. Inventory-service consumes PaymentFailed and releases the reserved stock. Order-service consumes PaymentFailed and marks the order as cancelled.
> There are two styles: choreography (services react to each other's events — simpler but harder to track) and orchestration (a central saga coordinator sends commands and tracks state — more visible, easier to debug)."

---

**Q7: What is DLQ and when do you use it?**

> "Dead Letter Queue is where messages go after failing all retry attempts. Without it, one bad message (poison pill) blocks the entire partition — no subsequent messages are processed. With DLQ: after N retries with exponential backoff, the framework moves the message to a `.DLQ` topic and commits the offset, so processing continues.
> The DLQ has a separate consumer that inspects failed messages, either auto-fixes and republishes them, stores them for human review, or discards them. I configure this with Spring's DefaultErrorHandler and DeadLetterPublishingRecoverer. Not-retryable exceptions (like JSON parse errors) go straight to DLQ without retrying."

---

**Q8: What is consumer group rebalancing? When does it happen and what is its impact?**

> "Rebalancing is when Kafka redistributes partition assignments among consumers in a group. It happens when: a new consumer joins, a consumer leaves/crashes (session.timeout.ms exceeded), or partitions are added to the topic.
> During rebalancing, ALL consumers in the group STOP consuming (stop-the-world rebalance by default). This causes a brief lag spike. The impact is proportional to the number of partitions — reassigning 100 partitions takes longer than 3.
> In production, minimize rebalancing by: stable consumer instance IDs (group.instance.id for static membership), not killing/starting consumers frequently, and using incremental cooperative rebalancing (rebalance.protocol=cooperative-sticky in Kafka 2.4+) which only moves partitions that need to move, not all of them."

---

**Q9: How do you guarantee message ordering?**

> "Ordering is guaranteed WITHIN a partition. All messages with the same key go to the same partition (murmur2 hash), and they're consumed in order by the same consumer.
> For example, all events for order-123 use key='order-123' → always go to the same partition → consumed in order by one consumer instance.
> Ordering is NOT guaranteed across partitions. If you need global ordering across all events, you must use 1 partition — but that means 1 consumer, no scaling.
> Also: at the producer level, set max.in.flight.requests.per.connection=1 if you need ordering with retries and idempotence is disabled. With idempotence enabled, up to 5 in-flight requests are safe."

---

**Q10: What happens when you change the number of partitions?**

> "You can only increase partitions, never decrease. When you increase, the murmur2 algorithm uses the new partition count, so the same key may now hash to a different partition. This breaks ordering: old messages for a key are in Partition 0, new messages go to Partition 3. Two consumers process them in parallel → ordering is broken.
> How to handle it: design the partition count upfront based on your scaling needs. If you must increase, either: stop the producer and drain all existing messages first, or create a new topic with the new count and migrate, or accept brief ordering issues for the transition period."

---

**Q11: How do you handle a corrupted or lost topic?**

> "First, never get here — use replication.factor=3 and min.insync.replicas=2. If it happens anyway:
> 1. Check if other replicas are clean — corrupt only the leader's log. Delete the local log directory for that partition on the corrupted broker, restart it, it resyncs from a healthy replica.
> 2. If all replicas are corrupted (very rare with proper replication), restore from backup (S3 snapshots of broker log directories) or reset consumer offsets past the corrupted range.
> Prevention: monitor disk health, UnderReplicatedPartitions metric, don't use unclean.leader.election.enable=true."

---

**Q12: What is the difference between at-least-once, at-most-once, and exactly-once delivery?**

> "At-most-once: messages can be lost but never duplicated. Consumer commits offset before processing — if it crashes, that message is skipped.
> At-least-once: messages are never lost but may be duplicated. Consumer commits after processing — if it crashes before commit, it reprocesses. This is what most production systems use. Make the consumer idempotent to handle duplicates.
> Exactly-once: messages are never lost and never duplicated. Achieved with Kafka Transactions — the consume-process-produce cycle is atomic. Highest overhead, used for financial or audit use cases."

---

**Q13: Multiple instances of the same consumer service are running. How does Kafka distribute messages?**

> "Each instance is part of the same consumer group. Kafka assigns partitions to instances — each partition goes to exactly one instance. With 3 partitions and 3 instances: instance 1 → partition 0, instance 2 → partition 1, instance 3 → partition 2.
> If a 4th instance starts, it sits idle (can't have more active consumers than partitions). If an instance crashes, its partition is reassigned to a surviving instance during rebalance (LAG spikes temporarily).
> For multiple services (e.g., inventory AND payment both want order events): each service has its own consumer group. Kafka delivers each message to ONE consumer per group, but to ALL groups. So inventory-service-group gets every order event, AND payment-service-group also gets every order event — independently."

---

**Q14: What is the difference between a consumer group with the same group ID vs different group IDs consuming from the same topic?**

> "Same group ID (e.g., inventory-service-group with 3 instances): partition-based load balancing. Each message goes to only ONE of the 3 instances. This is for scaling — parallel processing without duplicate work.
> Different group IDs (inventory-service-group vs payment-service-group, both reading order-events): each group independently consumes ALL messages. Inventory gets every order event AND payment also gets every order event. This is for fan-out — multiple services reacting to the same events independently, each at their own pace, with their own offsets."

---

**Q15: What is ISR and why does it matter?**

> "ISR (In-Sync Replicas) is the set of partition replicas that are currently fully caught up with the leader. A follower is removed from ISR if it falls more than replica.lag.time.max.ms (default 30s) behind.
> It matters for acks=all: the producer waits for confirmation from ALL brokers in the ISR. If ISR shrinks to 1 (just the leader) and min.insync.replicas=2, the producer gets NotEnoughReplicasException. This is intentional — it's the Kafka way of saying 'I can't guarantee your data is safe enough right now, please retry later.' This is far better than silently accepting writes that might be lost."

---

*This guide covers every Kafka topic asked in senior Java developer interviews. The most commonly tested areas are: consumer lag diagnosis, acks and idempotence, consumer offset management and DLQ, partition assignment and why keys matter, saga pattern, and how Kafka achieves fault tolerance. Practice explaining each concept with a concrete example — interviewers want to see that you've debugged real Kafka problems, not just read the docs.*