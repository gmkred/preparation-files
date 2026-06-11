# AWS File Processing Pipeline

## Overview

This document explains a production-grade file processing system using AWS services. A CSV file uploaded to S3 triggers a Lambda function that reads the file in batches, validates each row, and writes valid data to an RDS MSSQL database. Invalid rows go to SQS Dead Letter Queue (DLQ), and the DEV-TEAM gets email notifications at every stage.

---

## Architecture Diagram (Text)

```
User/System
    |
    | uploads CSV
    v
[S3 - Input Bucket]
    |
    | triggers (S3 Event Notification)
    v
[Lambda Function]
    |
    |--- reads file in batches
    |
    |--- validates each row
    |
    |--- valid rows ---------> [RDS MSSQL DB]
    |
    |--- invalid rows -------> [SQS - DLQ]
    |                               |
    |                               +----> [SES Email] --> DEV-TEAM
    |
    |--- invalid file format -> [S3 - Quarantine Bucket]
    |                               |
    |                               +----> [SES Email] --> DEV-TEAM
    |
    |--- success  -----------> [SES Email] --> DEV-TEAM
    |
    +------ all logs ---------> [CloudWatch Logs]
```

---

## AWS Services Used

| Service | Purpose |
|---|---|
| S3 (Input Bucket) | Stores uploaded CSV files |
| S3 (Quarantine Bucket) | Stores invalid/corrupt files |
| Lambda | Reads file, validates rows, writes to DB |
| RDS MSSQL | Final destination for valid data |
| SQS DLQ | Holds invalid rows for retry or review |
| SES | Sends emails to DEV-TEAM |
| CloudWatch Logs | Stores all Lambda execution logs |
| IAM | Permissions for Lambda to access other services |

---

## Step-by-Step Flow

### Step 1 — File Upload to S3

- A user or external system uploads a CSV file to the **Input S3 Bucket**.
- S3 is configured with an **Event Notification** that triggers Lambda automatically when a new `.csv` file arrives.
- Only the `ObjectCreated` event is used so Lambda is not triggered by deletions or updates.

**S3 Event Notification Config:**
```
Event Type  : s3:ObjectCreated:*
Prefix      : uploads/          (optional folder filter)
Suffix      : .csv              (only CSV files)
Destination : Lambda Function
```

---

### Step 2 — Lambda is Triggered

Lambda receives an event that contains:
- Bucket name
- File key (path to the uploaded file)

Lambda immediately logs the event to CloudWatch:
```
[INFO] New file received: uploads/data_2026-06-05.csv
[INFO] Bucket: my-input-bucket
[INFO] File size: 45.2 MB
```

---

### Step 3 — File Validation (Is the file itself valid?)

Before processing rows, Lambda checks:

| Check | What it looks for |
|---|---|
| File extension | Must be `.csv` |
| File size | Not empty (0 bytes) |
| Header row | Expected columns must exist |
| Encoding | UTF-8 or ASCII only |
| Delimiter | Comma-separated, not tab or pipe |

**If the file itself is invalid (any check above fails):**

1. Lambda copies the file to the **Quarantine S3 Bucket** with a timestamp prefix.
2. Lambda sends an email to DEV-TEAM via SES with file name, error reason, and a link to the quarantine bucket.
3. Lambda logs the failure to CloudWatch and exits.

```
[ERROR] File validation failed: missing required column 'customer_id'
[ERROR] File moved to quarantine: quarantine/2026-06-05T10:30:00_data_2026-06-05.csv
[INFO]  Email sent to dev-team@company.com
```

**SES Email — Invalid File:**
```
Subject : [ALERT] Invalid File Uploaded — data_2026-06-05.csv
Body    :
  File    : uploads/data_2026-06-05.csv
  Reason  : Missing required column 'customer_id'
  Moved to: s3://my-quarantine-bucket/quarantine/2026-06-05T10:30:00_data_2026-06-05.csv
  Time    : 2026-06-05 10:30:00 UTC
```

---

### Step 4 — Batch Reading the File (Large File Support)

Large files cannot be loaded into memory all at once. Lambda reads the file **in chunks (batches)** using streaming.

**How batching works:**
- Lambda opens a stream from S3 using `GetObject` with byte-range requests.
- Rows are collected into a batch of (example) **500 rows at a time**.
- Each batch is processed independently — validated and written to DB.
- If one batch fails, it does not stop the rest.

```
[INFO] Starting batch processing. Batch size: 500 rows
[INFO] Batch 1/120 — Rows 1-500 — Processing...
[INFO] Batch 1/120 — 498 valid, 2 invalid
[INFO] Batch 2/120 — Rows 501-1000 — Processing...
...
[INFO] Batch 120/120 — Complete
```

**Why batching matters in production:**
- Lambda has a 10 GB memory limit and 15 minute timeout.
- A 1 million row file cannot be held in memory.
- Batching prevents timeouts and memory crashes.
- Failed batches can be retried without reprocessing the whole file.

---

### Step 5 — Row-Level Validation

For each row in a batch, Lambda validates:

| Check | Example rule |
|---|---|
| Required fields | `customer_id`, `email`, `amount` must not be empty |
| Data types | `amount` must be a number, `date` must be a valid date |
| Length limits | `name` must be under 100 characters |
| Format rules | `email` must match email pattern |
| Business rules | `amount` must be greater than 0 |

**Valid row:** Written to RDS MSSQL database.

**Invalid row:**
1. The row is sent to **SQS DLQ** as a JSON message.
2. The message includes: row number, raw data, and reason for failure.
3. After each batch, if invalid rows exist, a **single SES email** is sent summarizing that batch's failures (not one email per row — that would flood the inbox).

**SQS DLQ Message format:**
```json
{
  "file_name": "uploads/data_2026-06-05.csv",
  "batch_number": 3,
  "row_number": 1347,
  "raw_data": "John,,abc@email,not-a-number,2026-13-45",
  "errors": [
    "email field is empty",
    "amount is not a number",
    "date '2026-13-45' is invalid"
  ],
  "timestamp": "2026-06-05T10:35:22Z"
}
```

**SES Email — Invalid Rows (per batch summary):**
```
Subject : [WARNING] Invalid Rows Found — Batch 3 — data_2026-06-05.csv
Body    :
  File         : uploads/data_2026-06-05.csv
  Batch        : 3 (rows 1001–1500)
  Invalid rows : 4 out of 500
  See SQS DLQ  : https://console.aws.amazon.com/sqs/...
  Details      :
    Row 1347 — email empty, amount not a number, invalid date
    Row 1389 — customer_id empty
    Row 1402 — amount is negative
    Row 1456 — name exceeds 100 characters
```

---

### Step 6 — Write Valid Rows to RDS MSSQL

Valid rows are inserted into the MSSQL database using a **bulk insert** approach (not row-by-row inserts, which are slow).

- Lambda uses a connection pool to RDS — it does not open a new connection per batch.
- RDS sits inside a **VPC** and Lambda is configured to run inside the same VPC.
- Transactions are used — if a batch insert fails halfway, it is rolled back and the batch goes to SQS DLQ.

```
[INFO] Batch 1 — Inserting 498 rows into RDS...
[INFO] Batch 1 — Insert successful in 320ms
[INFO] Batch 2 — Inserting 500 rows into RDS...
[ERROR] Batch 2 — DB connection timeout after 30s — rolling back
[ERROR] Batch 2 — 500 rows sent to SQS DLQ
```

**RDS Connection tips for Lambda:**
- Use **RDS Proxy** in front of RDS to manage connection pooling, because Lambda can spin up hundreds of instances and each would try to open a DB connection, which crashes MSSQL.
- Set connection timeout to 30 seconds.
- Always close the connection at the end of the Lambda function.

---

### Step 7 — Success Email

After all batches are processed, Lambda sends a success summary email.

**SES Email — Success:**
```
Subject : [SUCCESS] File Processed — data_2026-06-05.csv
Body    :
  File          : uploads/data_2026-06-05.csv
  Total rows    : 60,000
  Valid rows    : 59,987 (written to RDS MSSQL)
  Invalid rows  : 13 (sent to SQS DLQ)
  Processing time: 4 minutes 22 seconds
  Time completed: 2026-06-05 10:45:00 UTC

  Check invalid rows in SQS DLQ for review.
```

---

## CloudWatch Logging Strategy

Every action Lambda takes is logged to CloudWatch. Use **structured logging** (JSON format) so logs can be filtered and searched easily.

**Log Levels used:**

| Level | When to use |
|---|---|
| INFO | Normal steps (file received, batch started, rows inserted) |
| WARN | Recoverable issues (invalid rows found, retry attempt) |
| ERROR | Failures (file invalid, DB down, SQS send failed) |

**Example CloudWatch log stream:**
```json
{"level":"INFO",  "message":"File received",           "file":"uploads/data.csv", "size_mb":45.2}
{"level":"INFO",  "message":"File validation passed",   "file":"uploads/data.csv"}
{"level":"INFO",  "message":"Batch started",            "batch":1, "rows":"1-500"}
{"level":"WARN",  "message":"Invalid rows in batch",    "batch":1, "invalid_count":2}
{"level":"INFO",  "message":"Batch complete",           "batch":1, "inserted":498, "duration_ms":320}
{"level":"ERROR", "message":"DB insert failed",         "batch":7, "error":"Connection timeout"}
{"level":"INFO",  "message":"Processing complete",      "total_valid":59987, "total_invalid":13}
```

**CloudWatch Metric Filters (set these up):**

Create alarms based on these patterns:
```
Filter name         : ErrorCount
Pattern             : [ERROR]
Alarm threshold     : > 5 errors in 5 minutes
Action              : SNS → email to DEV-TEAM

Filter name         : InvalidFileAlert
Pattern             : "File validation failed"
Alarm threshold     : >= 1
Action              : SNS → email to DEV-TEAM immediately
```

---

## IAM Permissions for Lambda

Lambda needs these permissions (least privilege):

```json
{
  "Effect": "Allow",
  "Action": [
    "s3:GetObject",
    "s3:PutObject"
  ],
  "Resource": [
    "arn:aws:s3:::my-input-bucket/*",
    "arn:aws:s3:::my-quarantine-bucket/*"
  ]
},
{
  "Effect": "Allow",
  "Action": ["sqs:SendMessage"],
  "Resource": "arn:aws:sqs:us-east-1:123456789:file-processing-dlq"
},
{
  "Effect": "Allow",
  "Action": ["ses:SendEmail"],
  "Resource": "*"
},
{
  "Effect": "Allow",
  "Action": [
    "logs:CreateLogGroup",
    "logs:CreateLogStream",
    "logs:PutLogEvents"
  ],
  "Resource": "*"
},
{
  "Effect": "Allow",
  "Action": [
    "ec2:CreateNetworkInterface",
    "ec2:DescribeNetworkInterfaces",
    "ec2:DeleteNetworkInterface"
  ],
  "Resource": "*"
}
```

> The last EC2 permissions are required when Lambda runs inside a VPC to connect to RDS.

---

## Error Scenarios and How to Handle Them

### Scenario 1 — Lambda Times Out

**What happens:** File is too large and Lambda hits the 15 minute limit mid-way.

**How to handle:**
- Use a checkpoint system — store the last processed row number in DynamoDB or S3.
- On timeout, Lambda logs `[ERROR] Timeout at batch 45/120`.
- A CloudWatch alarm triggers an SNS alert to DEV-TEAM.
- DEV-TEAM can rerun the Lambda manually starting from the last checkpoint.

**Better long-term fix:** Move to Step Functions or use S3 multipart + SQS to fan out batches to separate Lambda invocations.

---

### Scenario 2 — RDS is Down

**What happens:** Lambda cannot connect to the database.

**How to handle:**
- Lambda retries the connection up to 3 times with a 5-second wait between tries.
- If all retries fail, the entire batch goes to SQS DLQ.
- Lambda logs `[ERROR] RDS unreachable after 3 retries`.
- CloudWatch alarm triggers email to DEV-TEAM.
- Once RDS is back, DEV-TEAM can replay the DLQ messages.

---

### Scenario 3 — SES Email Fails

**What happens:** Email sending fails (SES quota exceeded or wrong email address).

**How to handle:**
- Lambda logs `[WARN] SES email failed — continuing processing`.
- Email failure does NOT stop file processing — it is a notification service, not core logic.
- CloudWatch logs the failure so DEV-TEAM can see it later.

---

### Scenario 4 — S3 File Deleted Before Lambda Reads It

**What happens:** Someone deletes the file between the S3 event and Lambda reading it.

**How to handle:**
- Lambda receives a `NoSuchKey` error from S3.
- Logs `[ERROR] File not found: uploads/data.csv — may have been deleted`.
- Sends alert email to DEV-TEAM.
- Lambda exits cleanly.

---

### Scenario 5 — SQS DLQ is Full

**What happens:** SQS DLQ has reached max capacity (120,000 messages default).

**How to handle:**
- Set a CloudWatch alarm on the `NumberOfMessagesSent` metric for the DLQ.
- Alert DEV-TEAM when DLQ size exceeds 50,000 messages.
- DEV-TEAM should review, fix, and purge or replay messages regularly.

---

### Scenario 6 — Duplicate File Upload

**What happens:** Same file is uploaded twice (user mistake).

**How to handle:**
- Lambda checks RDS for a `file_name + upload_timestamp` record before processing.
- If the file was already processed, Lambda skips it and logs `[WARN] Duplicate file detected — skipping`.
- Optionally, send a warning email to DEV-TEAM.

---

## Debugging Guide

### Where to look when something goes wrong

| Problem | Where to look |
|---|---|
| Lambda not triggering | S3 Event Notification config, Lambda permissions, CloudWatch for invocation count |
| File went to quarantine | CloudWatch logs — search `"File validation failed"` |
| Rows missing from DB | SQS DLQ messages, CloudWatch logs for that batch number |
| No email received | SES sending stats, Lambda logs for `"SES"`, check SES sandbox mode |
| Lambda timeout | CloudWatch Duration metric, increase timeout or reduce batch size |
| DB insert slow | RDS Performance Insights, check for missing indexes on target table |
| High invalid row count | SQS DLQ — inspect messages, find common error pattern |
| Lambda crashing | CloudWatch for `[ERROR]` or `REPORT` lines with non-zero error codes |

### Useful CloudWatch Queries (CloudWatch Insights)

**Find all errors for a specific file:**
```
fields @timestamp, message, file
| filter level = "ERROR" and file = "uploads/data_2026-06-05.csv"
| sort @timestamp asc
```

**Count invalid rows per file:**
```
fields @timestamp, file, invalid_count
| filter message = "Invalid rows in batch"
| stats sum(invalid_count) as total_invalid by file
```

**Find slowest batches:**
```
fields @timestamp, batch, duration_ms
| filter message = "Batch complete"
| sort duration_ms desc
| limit 10
```

---

## Environment Variables for Lambda

Store these in Lambda environment variables (not hardcoded):

```
DB_HOST          = rds-proxy-endpoint.us-east-1.rds.amazonaws.com
DB_NAME          = myapp_db
DB_USER          = lambda_user
DB_PASSWORD      = (use AWS Secrets Manager — not plain text)
DB_PORT          = 1433
INPUT_BUCKET     = my-input-bucket
QUARANTINE_BUCKET= my-quarantine-bucket
SQS_DLQ_URL      = https://sqs.us-east-1.amazonaws.com/123456789/file-dlq
SES_FROM_EMAIL   = noreply@company.com
DEV_TEAM_EMAIL   = dev-team@company.com
BATCH_SIZE       = 500
MAX_DB_RETRIES   = 3
```

> Use **AWS Secrets Manager** for DB_PASSWORD. Never store passwords in environment variables in plain text.

---

## Quick Setup Checklist

- [ ] Create Input S3 Bucket
- [ ] Create Quarantine S3 Bucket
- [ ] Create SQS DLQ (set message retention to 14 days)
- [ ] Verify DEV-TEAM email in SES (if still in sandbox mode)
- [ ] Create RDS MSSQL instance inside VPC
- [ ] Set up RDS Proxy in front of RDS
- [ ] Create Lambda function, attach IAM role with above permissions
- [ ] Configure Lambda inside same VPC as RDS
- [ ] Add S3 Event Notification on Input Bucket → Lambda
- [ ] Set Lambda timeout to 15 minutes, memory to 1024 MB
- [ ] Set Lambda environment variables (DB creds from Secrets Manager)
- [ ] Create CloudWatch Log Group for Lambda
- [ ] Create CloudWatch Metric Filters and Alarms
- [ ] Test with a small valid CSV (happy path)
- [ ] Test with an invalid file (quarantine path)
- [ ] Test with a CSV containing some invalid rows (DLQ path)
- [ ] Test with a large file (batching + timeout path)

---

## Java Code Examples — Transient vs Non-Transient Exceptions

### The Core Rule

| Type | Meaning | Action |
|---|---|---|
| **Transient** | Temporary failure — infrastructure hiccup, will likely pass | Retry with backoff, then DLQ |
| **Non-Transient** | Permanent failure — bad data, code bug, constraint violation | DLQ immediately, never retry |

---

### Transient Exception Examples (retry these)

| Exception | Why it is transient |
|---|---|
| `SocketTimeoutException` | Network blip — next attempt usually works |
| `SQLTransientConnectionException` | DB connection pool temporarily full |
| `SQLTimeoutException` | Query took too long — DB was briefly busy |
| SQL deadlock (`SQLSTATE 40001`, MSSQL error 1205) | Two transactions clashed — retry resolves it |
| AWS SDK `429` (throttling) | Too many requests — back off and retry |
| AWS SDK `503` / `500` (server error) | AWS service temporarily unavailable |
| `ConnectException` (connection refused) | RDS Proxy briefly restarting |

### Non-Transient Exception Examples (DLQ immediately)

| Exception | Why it is non-transient |
|---|---|
| `SQLIntegrityConstraintViolationException` | Duplicate key, NOT NULL violated — data is wrong |
| `NumberFormatException` | `"abc"` will never become a number |
| `DateTimeParseException` | `"2026-13-45"` will never be a valid date |
| Validation failure (empty required field) | Missing data will not appear on retry |
| AWS SDK `400` (bad request) | Your request format is wrong — fix the code |
| `NullPointerException` | Code bug — retrying hits same bug |
| Column count mismatch in row | Row is malformed — data is wrong |

---

### 1 — Exception Classifier

```java
import software.amazon.awssdk.awscore.exception.AwsServiceException;
import java.net.ConnectException;
import java.net.SocketTimeoutException;
import java.sql.*;

public class ExceptionClassifier {

    public static boolean isTransient(Exception e) {
        // Network timeout — usually resolves on retry
        if (e instanceof SocketTimeoutException) return true;
        if (e instanceof ConnectException)       return true;

        // JDBC transient connection issues
        if (e instanceof SQLTransientConnectionException) return true;
        if (e instanceof SQLTimeoutException)             return true;

        // SQL deadlock — another transaction held the lock, retry wins
        if (e instanceof SQLException sqlEx) {
            String state = sqlEx.getSQLState();
            int    code  = sqlEx.getErrorCode();
            return "40001".equals(state)   // ANSI deadlock
                || "40P01".equals(state)   // Postgres deadlock
                || code == 1205;           // MSSQL deadlock victim
        }

        // AWS SDK: throttling (429) or server-side error (5xx) → transient
        if (e instanceof AwsServiceException awsEx) {
            int status = awsEx.statusCode();
            return status == 429 || status >= 500;
        }

        return false;
    }

    public static boolean isNonTransient(Exception e) {
        return !isTransient(e);
    }
}
```

---

### 2 — Retry Handler with Exponential Backoff

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class RetryHandler {

    private static final Logger log = LoggerFactory.getLogger(RetryHandler.class);

    private static final int  MAX_RETRIES   = 3;
    private static final long BASE_DELAY_MS = 1_000; // 1 second

    // Returns true if row was written to DB, false if it went to DLQ
    public boolean processWithRetry(Row row, DbWriter dbWriter, SqsDlqSender dlqSender) {
        Exception lastException = null;

        for (int attempt = 1; attempt <= MAX_RETRIES; attempt++) {
            try {
                dbWriter.insert(row);
                return true; // success — stop here

            } catch (Exception e) {

                if (ExceptionClassifier.isNonTransient(e)) {
                    // Retrying will never fix this — go to DLQ immediately
                    log.warn("Non-transient error on row {} — sending to DLQ immediately: {}",
                        row.getRowNumber(), e.getMessage());
                    dlqSender.send(row, "Non-transient error: " + e.getMessage());
                    return false;
                }

                // Transient — worth retrying
                lastException = e;
                long delayMs = BASE_DELAY_MS * (1L << attempt); // 2s, 4s, 8s

                log.warn("Transient error on row {}, attempt {}/{}, retrying in {}ms — {}",
                    row.getRowNumber(), attempt, MAX_RETRIES, delayMs, e.getMessage());

                if (attempt < MAX_RETRIES) {
                    sleep(delayMs);
                }
            }
        }

        // All retries exhausted — send to DLQ
        String reason = "All " + MAX_RETRIES + " retries failed. Last error: "
            + (lastException != null ? lastException.getMessage() : "unknown");
        log.error("Row {} exhausted retries — sending to DLQ: {}", row.getRowNumber(), reason);
        dlqSender.send(row, reason);
        return false;
    }

    private void sleep(long ms) {
        try {
            Thread.sleep(ms);
        } catch (InterruptedException ie) {
            Thread.currentThread().interrupt();
        }
    }
}
```

**Retry timeline example for a transient error:**
```
Attempt 1 fails (SQLTransientConnectionException) → wait 2s
Attempt 2 fails (SQLTransientConnectionException) → wait 4s
Attempt 3 fails (SQLTransientConnectionException) → wait 8s
All retries exhausted → DLQ
```

---

### 3 — Row Validator (all non-transient by nature)

```java
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;

public class RowValidator {

    private static final Pattern EMAIL_PATTERN =
        Pattern.compile("^[\\w.-]+@[\\w.-]+\\.[a-zA-Z]{2,}$");

    // Validation errors are ALWAYS non-transient.
    // Bad data never fixes itself — send to DLQ immediately.
    public List<String> validate(Row row) {
        List<String> errors = new ArrayList<>();

        // Required fields
        if (isBlank(row.getCustomerId())) errors.add("customer_id is empty");
        if (isBlank(row.getEmail()))      errors.add("email is empty");
        if (isBlank(row.getAmount()))     errors.add("amount is empty");
        if (isBlank(row.getName()))       errors.add("name is empty");

        // Type checks — NumberFormatException and DateTimeParseException are non-transient
        if (!isBlank(row.getAmount()) && !isValidNumber(row.getAmount()))
            errors.add("amount '" + row.getAmount() + "' is not a valid number");

        if (!isBlank(row.getDate()) && !isValidDate(row.getDate()))
            errors.add("date '" + row.getDate() + "' is not a valid date (expected YYYY-MM-DD)");

        // Format checks
        if (!isBlank(row.getEmail()) && !EMAIL_PATTERN.matcher(row.getEmail()).matches())
            errors.add("email '" + row.getEmail() + "' is not a valid email address");

        // Length limits
        if (!isBlank(row.getName()) && row.getName().length() > 100)
            errors.add("name exceeds 100 characters (length=" + row.getName().length() + ")");

        // Business rules
        if (!isBlank(row.getAmount()) && isValidNumber(row.getAmount())) {
            double amount = Double.parseDouble(row.getAmount());
            if (amount <= 0) errors.add("amount must be greater than 0, got " + amount);
        }

        return errors; // empty list = valid row
    }

    private boolean isBlank(String s)       { return s == null || s.isBlank(); }
    private boolean isValidNumber(String s) {
        try { Double.parseDouble(s); return true; } catch (NumberFormatException e) { return false; }
    }
    private boolean isValidDate(String s) {
        try { LocalDate.parse(s); return true; } catch (DateTimeParseException e) { return false; }
    }
}
```

---

### 4 — DB Writer (where transient exceptions can occur)

```java
import java.sql.*;
import java.util.List;

public class DbWriter {

    private final Connection connection;

    public DbWriter(Connection connection) {
        this.connection = connection;
    }

    // Bulk insert for a batch — uses a transaction so all-or-nothing
    public void insertBatch(List<Row> rows) throws SQLException {
        String sql = "INSERT INTO customers (customer_id, name, email, amount, date) VALUES (?, ?, ?, ?, ?)";

        connection.setAutoCommit(false); // start transaction

        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            for (Row row : rows) {
                ps.setString(1, row.getCustomerId());
                ps.setString(2, row.getName());
                ps.setString(3, row.getEmail());
                ps.setDouble(4, Double.parseDouble(row.getAmount()));
                ps.setDate(5, Date.valueOf(row.getDate()));
                ps.addBatch();
            }
            ps.executeBatch();
            connection.commit(); // commit all rows at once

        } catch (SQLIntegrityConstraintViolationException e) {
            // NON-TRANSIENT — duplicate customer_id or NOT NULL violated
            // Caller must send these rows to DLQ — retrying won't fix it
            connection.rollback();
            throw e;

        } catch (SQLTransientConnectionException | SQLTimeoutException e) {
            // TRANSIENT — DB was busy or connection dropped
            // Caller's RetryHandler will retry
            connection.rollback();
            throw e;

        } catch (SQLException e) {
            // Check SQLSTATE for deadlock (transient) vs other SQL errors (non-transient)
            connection.rollback();
            throw e;
        }
    }

    // Single row insert — used when a batch fails and you process row by row
    public void insert(Row row) throws SQLException {
        String sql = "INSERT INTO customers (customer_id, name, email, amount, date) VALUES (?, ?, ?, ?, ?)";

        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setString(1, row.getCustomerId());
            ps.setString(2, row.getName());
            ps.setString(3, row.getEmail());
            ps.setDouble(4, Double.parseDouble(row.getAmount()));
            ps.setDate(5, Date.valueOf(row.getDate()));
            ps.executeUpdate();
        }
    }
}
```

---

### 5 — DLQ Sender

```java
import com.fasterxml.jackson.databind.ObjectMapper;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.SendMessageRequest;
import java.time.Instant;
import java.util.List;

public class SqsDlqSender {

    private static final Logger log = LoggerFactory.getLogger(SqsDlqSender.class);

    private final SqsClient    sqsClient;
    private final String       dlqUrl;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public SqsDlqSender(SqsClient sqsClient, String dlqUrl) {
        this.sqsClient = sqsClient;
        this.dlqUrl    = dlqUrl;
    }

    public void send(Row row, String reason) {
        try {
            var dlqMessage = new DlqMessage(
                row.getFileName(),
                row.getBatchNumber(),
                row.getRowNumber(),
                row.getRawData(),
                List.of(reason),
                Instant.now().toString()
            );

            String body = objectMapper.writeValueAsString(dlqMessage);

            sqsClient.sendMessage(SendMessageRequest.builder()
                .queueUrl(dlqUrl)
                .messageBody(body)
                .build());

            log.info("Row {} sent to DLQ. Reason: {}", row.getRowNumber(), reason);

        } catch (Exception e) {
            // Log but do NOT throw — failing to write to DLQ should not crash the whole batch
            log.error("CRITICAL: Could not send row {} to DLQ: {}", row.getRowNumber(), e.getMessage());
        }
    }
}
```

---

### 6 — Full Row Processor — Everything Together

```java
public class RowProcessor {

    private static final Logger log = LoggerFactory.getLogger(RowProcessor.class);

    private final RowValidator validator;
    private final RetryHandler retryHandler;
    private final DbWriter     dbWriter;
    private final SqsDlqSender dlqSender;

    public RowResult process(Row row) {

        // Step 1: Validate — all validation errors are non-transient
        List<String> errors = validator.validate(row);
        if (!errors.isEmpty()) {
            log.warn("Row {} failed validation — DLQ immediately: {}", row.getRowNumber(), errors);
            dlqSender.send(row, "Validation failed: " + String.join(", ", errors));
            return RowResult.INVALID; // do NOT retry
        }

        // Step 2: Write to DB with retry logic for transient errors
        boolean written = retryHandler.processWithRetry(row, dbWriter, dlqSender);
        return written ? RowResult.SUCCESS : RowResult.FAILED;
    }

    public enum RowResult { SUCCESS, INVALID, FAILED }
}
```

---

### 7 — Batch Processor

```java
public class BatchProcessor {

    private static final Logger log = LoggerFactory.getLogger(BatchProcessor.class);

    private final RowProcessor rowProcessor;

    public BatchSummary processBatch(List<Row> batch, int batchNumber) {
        int success = 0, invalid = 0, failed = 0;

        for (Row row : batch) {
            RowResult result = rowProcessor.process(row);

            switch (result) {
                case SUCCESS -> success++;
                case INVALID -> invalid++;  // validation failure, sent to DLQ immediately
                case FAILED  -> failed++;   // transient retries exhausted, sent to DLQ
            }
        }

        log.info("{\"level\":\"INFO\",\"message\":\"Batch complete\",\"batch\":{},\"success\":{},\"invalid\":{},\"failed\":{}}",
            batchNumber, success, invalid, failed);

        return new BatchSummary(batchNumber, success, invalid, failed);
    }
}
```

---

### 8 — Lambda Handler Entry Point

```java
import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.S3Event;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.sqs.SqsClient;

public class FilePipelineHandler implements RequestHandler<S3Event, String> {

    private final S3Client  s3Client  = S3Client.create();
    private final SqsClient sqsClient = SqsClient.create();
    private final String    dlqUrl    = System.getenv("SQS_DLQ_URL");
    private final int       batchSize = Integer.parseInt(System.getenv("BATCH_SIZE"));

    @Override
    public String handleRequest(S3Event event, Context context) {
        String bucket  = event.getRecords().get(0).getS3().getBucket().getName();
        String fileKey = event.getRecords().get(0).getS3().getObject().getKey();

        log.info("File received: s3://{}/{}", bucket, fileKey);

        SqsDlqSender  dlqSender      = new SqsDlqSender(sqsClient, dlqUrl);
        RowValidator   validator      = new RowValidator();
        DbWriter       dbWriter       = new DbWriter(getConnection());
        RetryHandler   retryHandler   = new RetryHandler();
        RowProcessor   rowProcessor   = new RowProcessor(validator, retryHandler, dbWriter, dlqSender);
        BatchProcessor batchProcessor = new BatchProcessor(rowProcessor);

        try (CsvStreamReader reader = new CsvStreamReader(s3Client, bucket, fileKey, batchSize)) {

            // File-level validation — non-transient, quarantine immediately if bad
            if (!reader.isValidFile()) {
                quarantineFile(bucket, fileKey);
                return "QUARANTINED";
            }

            int batchNumber  = 1;
            int totalSuccess = 0, totalInvalid = 0, totalFailed = 0;

            List<Row> batch;
            while (!(batch = reader.nextBatch()).isEmpty()) {
                BatchSummary summary = batchProcessor.processBatch(batch, batchNumber++);
                totalSuccess += summary.success();
                totalInvalid += summary.invalid();
                totalFailed  += summary.failed();
            }

            log.info("Processing complete — success={}, invalid={}, failed={}",
                totalSuccess, totalInvalid, totalFailed);
            return "SUCCESS";

        } catch (Exception e) {
            log.error("Pipeline failed for file {}: {}", fileKey, e.getMessage(), e);
            return "ERROR";
        }
    }
}
```

---

### Decision Flowchart — Retry or DLQ?

```
Row fails to write to DB
         |
         v
  Is the exception transient?
  (network timeout, DB busy,
   AWS throttle, SQL deadlock)
         |
    YES  |  NO
    |         |
    v         v
Retry up    Send to DLQ
to 3x with  immediately
backoff     (bad data, constraint
    |        violation, code bug)
    |
    v
Did all retries fail?
    |
  YES |
    |
    v
Send to DLQ
("Max retries exhausted")
```

---

### Quick Reference — Retry vs DLQ

```
RETRY (transient — infrastructure problem)
  - java.net.SocketTimeoutException
  - java.net.ConnectException
  - java.sql.SQLTransientConnectionException
  - java.sql.SQLTimeoutException
  - java.sql.SQLException with SQLSTATE 40001 (deadlock)
  - java.sql.SQLException with MSSQL error code 1205 (deadlock)
  - AwsServiceException with HTTP 429 (throttling)
  - AwsServiceException with HTTP 500/503 (AWS server error)

DLQ IMMEDIATELY (non-transient — data or code problem)
  - java.sql.SQLIntegrityConstraintViolationException  (duplicate key, NOT NULL)
  - java.lang.NumberFormatException                   (amount="abc")
  - java.time.format.DateTimeParseException           (date="2026-13-45")
  - Validation failure (empty required field)
  - Column count mismatch (malformed row)
  - AwsServiceException with HTTP 400 (bad request)
  - java.lang.NullPointerException                    (code bug)
```

---

## DLQ → SES — How to Wire It

SQS **cannot directly call SES**. You need a bridge Lambda in between.

```
Option A (recommended — full control over email content):
SQS DLQ → Lambda (DLQ processor) → SES

Option B (simpler — no custom email body):
SQS DLQ → CloudWatch Alarm → SNS → SES (email subscription)
```

Option A is better because you can batch messages, format the email with row details, and group by file name. Option B just tells you "DLQ has N messages" — no row details.

---

### Option A — DLQ Processor Lambda (Java)

**Step 1 — Configure SQS as a trigger for a second Lambda:**

```
Event Source        : SQS
Queue ARN           : arn:aws:sqs:us-east-1:123456789:file-processing-dlq
Batch size          : 10      ← collect up to 10 DLQ messages, send 1 email
Max batching window : 60s     ← wait up to 60s to collect messages before firing
```

This means Lambda fires once with up to 10 DLQ messages — you send one summary email instead of one email per row.

**Step 2 — Java Lambda that reads DLQ messages and sends SES email:**

```java
import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.SQSEvent;
import software.amazon.awssdk.services.ses.SesClient;
import software.amazon.awssdk.services.ses.model.*;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.List;
import java.util.stream.Collectors;

public class DlqEmailHandler implements RequestHandler<SQSEvent, Void> {

    private final SesClient    sesClient    = SesClient.create();
    private final ObjectMapper objectMapper = new ObjectMapper();
    private final String       fromEmail    = System.getenv("SES_FROM_EMAIL");
    private final String       devTeam      = System.getenv("DEV_TEAM_EMAIL");

    @Override
    public Void handleRequest(SQSEvent event, Context context) {
        List<DlqMessage> messages = event.getRecords().stream()
            .map(record -> parseDlqMessage(record.getBody()))
            .collect(Collectors.toList());

        if (!messages.isEmpty()) {
            sendEmailSummary(messages);
        }
        return null;
    }

    private void sendEmailSummary(List<DlqMessage> messages) {
        String fileName = messages.get(0).getFileName();
        int    count    = messages.size();

        StringBuilder body = new StringBuilder();
        body.append("File   : ").append(fileName).append("\n");
        body.append("Invalid rows received in DLQ: ").append(count).append("\n\n");

        for (DlqMessage msg : messages) {
            body.append("  Row ").append(msg.getRowNumber())
                .append(" (Batch ").append(msg.getBatchNumber()).append(")")
                .append(" — ").append(String.join(", ", msg.getErrors()))
                .append("\n");
        }

        sesClient.sendEmail(SendEmailRequest.builder()
            .source(fromEmail)
            .destination(Destination.builder().toAddresses(devTeam).build())
            .message(Message.builder()
                .subject(Content.builder()
                    .data("[DLQ ALERT] " + count + " invalid rows — " + fileName)
                    .build())
                .body(Body.builder()
                    .text(Content.builder().data(body.toString()).build())
                    .build())
                .build())
            .build());
    }

    private DlqMessage parseDlqMessage(String body) {
        try {
            return objectMapper.readValue(body, DlqMessage.class);
        } catch (Exception e) {
            return new DlqMessage("unknown", 0, 0, body, List.of("parse error"), "");
        }
    }
}
```

**IAM for the DLQ processor Lambda:**

```json
{
  "Effect": "Allow",
  "Action": ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"],
  "Resource": "arn:aws:sqs:us-east-1:123456789:file-processing-dlq"
},
{
  "Effect": "Allow",
  "Action": ["ses:SendEmail"],
  "Resource": "*"
}
```

**Sample email the DLQ Lambda sends:**

```
Subject : [DLQ ALERT] 4 invalid rows — uploads/data_2026-06-05.csv

File   : uploads/data_2026-06-05.csv
Invalid rows received in DLQ: 4

  Row 1347 (Batch 3) — email empty, amount not a number, invalid date
  Row 1389 (Batch 3) — customer_id empty
  Row 1402 (Batch 3) — amount is negative
  Row 1456 (Batch 3) — name exceeds 100 characters
```

---

### Option B — CloudWatch Alarm → SNS → SES (no code, but no row details)

```
1. SQS Console → your DLQ → Monitoring tab → View in CloudWatch

2. Create Alarm:
   Metric    : ApproximateNumberOfMessagesVisible
   Threshold : > 0  (any message in DLQ triggers alert)
   Period    : 1 minute

3. Alarm Action → SNS Topic → "file-dlq-alerts"

4. SNS Topic → Create email subscription → dev-team@company.com

5. Confirm the subscription from the email AWS sends you
```

Limitation: email just says "DLQ has 5 messages" — no file name, no row details, no error reasons.

---

## CloudWatch Logs — What Is Automatic vs What Needs Config

| Thing | Automatic? | Action needed |
|---|---|---|
| Log group `/aws/lambda/your-function` | **Yes — auto-created on first run** | Nothing |
| Logs appear when Lambda runs | **Yes** | Nothing |
| Log retention period | **No — default is never expires** | Set it manually |
| Metric filters (count ERRORs, etc.) | **No** | Create separately |
| CloudWatch Alarms | **No** | Create separately |
| CloudWatch Insights queries | **No** | Create/save separately |
| Log group for DLQ Lambda | **Yes — auto-created** | Nothing |

**Basic logging = zero config. Retention + alarms + filters = separate setup (do this once).**

---

### Set Log Retention (otherwise logs grow forever)

```bash
aws logs put-retention-policy \
  --log-group-name "/aws/lambda/file-pipeline-handler" \
  --retention-in-days 30

aws logs put-retention-policy \
  --log-group-name "/aws/lambda/dlq-email-handler" \
  --retention-in-days 30
```

---

### Metric Filters + Alarms — Do This Once After Deploying Lambda

**Filter 1 — Count errors, alarm if > 5 in 5 minutes:**

```bash
# Step 1: create the metric filter
aws logs put-metric-filter \
  --log-group-name "/aws/lambda/file-pipeline-handler" \
  --filter-name "ErrorCount" \
  --filter-pattern "ERROR" \
  --metric-transformations \
      metricName=LambdaErrorCount,metricNamespace=FilePipeline,metricValue=1

# Step 2: create the alarm on that metric
aws cloudwatch put-metric-alarm \
  --alarm-name "FilePipeline-HighErrorRate" \
  --metric-name LambdaErrorCount \
  --namespace FilePipeline \
  --statistic Sum \
  --period 300 \
  --threshold 5 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1 \
  --alarm-actions arn:aws:sns:us-east-1:123456789:dev-team-alerts
```

**Filter 2 — Alarm immediately when any file is quarantined:**

```bash
aws logs put-metric-filter \
  --log-group-name "/aws/lambda/file-pipeline-handler" \
  --filter-name "InvalidFileAlert" \
  --filter-pattern "File validation failed" \
  --metric-transformations \
      metricName=InvalidFileCount,metricNamespace=FilePipeline,metricValue=1

aws cloudwatch put-metric-alarm \
  --alarm-name "FilePipeline-InvalidFile" \
  --metric-name InvalidFileCount \
  --namespace FilePipeline \
  --statistic Sum \
  --period 60 \
  --threshold 1 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --evaluation-periods 1 \
  --alarm-actions arn:aws:sns:us-east-1:123456789:dev-team-alerts
```

**SNS topic email subscription (so the alarm actually emails you):**

```bash
# Create the SNS topic (once)
aws sns create-topic --name dev-team-alerts

# Subscribe dev-team email to it (once)
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:123456789:dev-team-alerts \
  --protocol email \
  --notification-endpoint dev-team@company.com

# Dev-team must click confirmation link in the email AWS sends
```

---

### Final Architecture with Everything Wired

```
[S3 Input Bucket]
    |
    | s3:ObjectCreated → triggers
    v
[Lambda: file-pipeline-handler]
    |
    |--- valid rows ──────────────────────> [RDS MSSQL]
    |
    |--- invalid rows (validation fail) ──> [SQS DLQ]
    |                                           |
    |--- transient retries exhausted ──────> [SQS DLQ]
    |                                           |
    |                                       triggers (batch=10, window=60s)
    |                                           |
    |                                           v
    |                                  [Lambda: dlq-email-handler]
    |                                           |
    |                                           v
    |                                        [SES] ──> DEV-TEAM email
    |
    |--- invalid file ────────────────────> [S3 Quarantine Bucket]
    |                                    + [SES] ──> DEV-TEAM email
    |
    |--- success ─────────────────────────> [SES] ──> DEV-TEAM email
    |
    +--- all logs ────────────────────────> [CloudWatch Logs]
                                                |
                                         Metric Filters
                                         (ERROR, "File validation failed")
                                                |
                                         CloudWatch Alarms
                                                |
                                             [SNS]
                                                |
                                             [SES] ──> DEV-TEAM email
```
