# AWS Interview Preparation Guide — Java Fullstack Developer

> **Goal:** Crack any AWS interview as a Java fullstack developer. Everything is explained with real examples, easy analogies, and code. Architecture fundamentals come first so every service makes sense in context.

---

## TABLE OF CONTENTS

1. [AWS Architecture Fundamentals](#1-aws-architecture-fundamentals)
   - Regions, AZs, Edge Locations
   - IAM — Users, Groups, Roles, Policies
   - VPC — The Foundation of Everything
   - Subnets — Public vs Private
   - Route Tables
   - Internet Gateway
   - NAT Gateway
   - Security Groups
   - NACL
   - CIDR Notation
2. [EC2 — Elastic Compute Cloud](#2-ec2--elastic-compute-cloud)
3. [S3 — Simple Storage Service](#3-s3--simple-storage-service)
4. [AWS Lambda — Serverless](#4-aws-lambda--serverless)
5. [Docker on AWS](#5-docker-on-aws)
6. [Kubernetes & EKS](#6-kubernetes--eks)
7. [CI/CD with Jenkins on AWS](#7-cicd-with-jenkins-on-aws)
8. [Java Spring Boot + S3 Code Examples](#8-java-spring-boot--s3-code-examples)
9. [Angular 15 + S3 Code Examples](#9-angular-15--s3-code-examples)
10. [Scenario-Based Questions & Answers](#10-scenario-based-questions--answers)

---

## 1. AWS ARCHITECTURE FUNDAMENTALS

> Think of AWS as a massive global network of data centres. Before you use any service, you need to understand how this network is organized and how security is managed.

---

### 1.1 Regions, Availability Zones, and Edge Locations

```
WORLD
 └─ Region (e.g., us-east-1 = N. Virginia)
      ├─ Availability Zone 1a  ← physical data centre
      ├─ Availability Zone 1b  ← different building / power / network
      └─ Availability Zone 1c
```

**Region**
- A geographical area (e.g., Mumbai = `ap-south-1`, N. Virginia = `us-east-1`)
- Has at minimum 2 AZs
- You choose a region based on where your users are and compliance rules
- Resources in one region do NOT automatically exist in another

**Availability Zone (AZ)**
- A separate physical data centre within a region
- Has its own power, cooling, and networking
- Analogy: If a region is a city, an AZ is a different building in that city
- **Why it matters:** Deploy your app in 2 AZs — if one floods or burns, the other keeps running

**Edge Location**
- Mini-CDN data centres spread globally (200+ worldwide)
- Used by **CloudFront** to cache and serve content closer to users
- Analogy: Your app is in Virginia but a user in Mumbai gets content from an Edge Location in Mumbai, not Virginia — much faster

---

### 1.2 IAM — Identity and Access Management

> IAM is the security front door of AWS. Everything that needs to "do something" in AWS must go through IAM.

**Simple Rule to Remember:**
```
HUMAN needs access to AWS  →  IAM USER
HUMANS with same job role  →  IAM GROUP  (attach policy to group, not individuals)
AWS SERVICE needs AWS access →  IAM ROLE
WHAT actions are allowed  →  IAM POLICY
```

---

#### IAM User
- Represents a person (developer, admin, ops)
- Has username + password for Console access
- Has Access Key + Secret Key for CLI/SDK access
- Best practice: Never use the root account for daily work

#### IAM Group
- A collection of users (e.g., "developers", "devops", "testers")
- You attach policies to the group — every user in the group inherits those permissions
- Analogy: Like a department in a company. All "developers" get the same office pass (policy)

```
Group: "developers"
  ├─ Policy: AmazonEC2ReadOnlyAccess
  ├─ Policy: AmazonS3FullAccess
  │
  ├─ User: john
  ├─ User: priya   ← all 3 users inherit both policies
  └─ User: ravi
```

#### IAM Role
- Not a person — it is an identity that AWS SERVICES assume temporarily
- Example: Your EC2 application needs to read from S3 — instead of hardcoding credentials, you attach an IAM Role to EC2
- Roles are temporary; when a service assumes a role, it gets temporary credentials

```
Real Example:
  EC2 (your Spring Boot app)  →  assumes  →  Role "ec2-s3-read-role"
                                              └─ Policy: AmazonS3ReadOnlyAccess

  Lambda function  →  assumes  →  Role "lambda-dynamo-role"
                                   └─ Policy: AmazonDynamoDBFullAccess
```

#### IAM Policy
- A JSON document defining **what actions** are allowed or denied on **which resources**
- Two types:
  - **AWS Managed Policy:** Predefined by AWS (e.g., `AmazonS3FullAccess`)
  - **Customer Managed Policy / Inline Policy:** You write it yourself for fine-grained control

**Sample Policy (allow read-only S3 on one bucket):**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::my-app-bucket",
        "arn:aws:s3:::my-app-bucket/*"
      ]
    }
  ]
}
```

**Important IAM Rules:**
- **Deny always wins** — if a user has both Allow and Deny for same action, Deny wins
- **Least Privilege Principle** — give only what is needed, nothing more
- **MFA (Multi-Factor Authentication)** — always enable for root account and admins

---

### 1.3 VPC — Virtual Private Cloud

> VPC is your own private section of AWS — your own isolated network, like having your own private floor in a skyscraper.

**Without VPC:** Your EC2 is exposed to the internet by default — dangerous!  
**With VPC:** You control who can talk to what, using your own IP ranges, subnets, and firewall rules.

```
AWS Cloud
 └─ Your Account
      ├─ VPC: "prod-vpc"  (10.0.0.0/16)
      │    ├─ Public Subnet 1a  (10.0.1.0/24)  ← ALB lives here
      │    ├─ Public Subnet 1b  (10.0.2.0/24)  ← ALB lives here
      │    ├─ Private Subnet 1a (10.0.3.0/24)  ← EC2/App lives here
      │    ├─ Private Subnet 1b (10.0.4.0/24)  ← EC2/App lives here
      │    ├─ Private Subnet 1a (10.0.5.0/24)  ← RDS DB lives here
      │    └─ Private Subnet 1b (10.0.6.0/24)  ← RDS DB lives here
      │
      └─ VPC: "dev-vpc"   (10.1.0.0/16)
```

**Key Facts:**
- VPC spans all AZs in a region
- Each AWS account has a **Default VPC** — good for testing, not for production
- You can have multiple VPCs (e.g., one for dev, one for prod)
- Resources inside the same VPC can communicate by default using private IPs

---

### 1.4 Subnets — Public vs Private

A subnet is a segment of a VPC's IP range. Think of VPC as a big office building, and subnets as different floors.

**Public Subnet:**
- Has a route to the Internet Gateway
- Resources can have public IP addresses
- Visible from the internet
- **Used for:** Load Balancers (ALB), Bastion hosts, NAT Gateways

**Private Subnet:**
- NO route to the Internet Gateway
- Resources only have private IP addresses
- NOT reachable from the internet directly
- **Used for:** EC2 application servers, RDS databases, EKS nodes

```
INTERNET
    │
    ▼
Internet Gateway
    │
    ▼
PUBLIC SUBNET (ALB sits here)
    │
    ▼ (only ALB can talk to app — enforced by security group)
PRIVATE SUBNET (Your Spring Boot app EC2 sits here)
    │
    ▼ (only app can talk to DB — enforced by security group)
PRIVATE SUBNET (Your RDS PostgreSQL sits here)
```

**Why private subnets for apps and DBs?**
- Hackers cannot directly SSH into your app server
- Even if your ALB is attacked, DB is still safe
- This is called **Defence in Depth** in security

---

### 1.5 Route Tables

Route tables are like the GPS of your VPC — they tell traffic where to go.

Every subnet has an associated route table. When a packet leaves a resource, the route table decides where it goes.

**Public Subnet Route Table:**
```
Destination     | Target
----------------|------------------
10.0.0.0/16     | local            ← stay inside VPC
0.0.0.0/0       | igw-xxxx         ← go to internet via Internet Gateway
```

**Private Subnet Route Table:**
```
Destination     | Target
----------------|------------------
10.0.0.0/16     | local            ← stay inside VPC
0.0.0.0/0       | nat-xxxx         ← outbound internet via NAT Gateway
```

**Key Rule:** If a subnet's route table has `0.0.0.0/0 → Internet Gateway`, it is a PUBLIC subnet. Otherwise it's PRIVATE.

---

### 1.6 Internet Gateway (IGW)

- Attached to a VPC (one IGW per VPC)
- Allows **two-way** internet communication for resources in public subnets
- Without IGW, nothing in your VPC can reach the internet
- Free to use (you pay for data transfer, not the gateway itself)

```
EC2 (public subnet) → Internet Gateway → Internet
Internet → Internet Gateway → EC2 (public subnet)
```

---

### 1.7 NAT Gateway (Network Address Translation)

> Problem: Your app runs in a private subnet. It needs to download a software update from the internet, or connect to a 3rd-party API. But private subnets have no internet access!  
> Solution: NAT Gateway

- NAT Gateway lives in a **public subnet** and has a public IP (Elastic IP)
- Allows private subnet resources to make **outbound** internet requests
- But the internet CANNOT initiate connections INTO private subnet (one-way)
- This is the key security benefit — your DB or app server is hidden

```
Private Subnet EC2 ──(outbound request)──▶ NAT Gateway (public subnet)
                                                │
                                                ▼
                                           Internet (e.g., GitHub, DockerHub, 3rd party API)
                                                │
                                           Response comes back
                                                │
                                                ▼
                                           NAT Gateway (translates back to private IP)
                                                │
                                                ▼
Private Subnet EC2 ◀──(response)────────────────┘
```

**Important:** NAT Gateway is NOT free — you pay per hour + per GB. Create one per AZ for high availability in production.

---

### 1.8 Security Groups

> Security Groups are the virtual firewalls attached to individual AWS resources (EC2, RDS, ALB, Lambda, etc.)

**Key Rules:**
- **Stateful** — if inbound is allowed, the response is automatically allowed outbound (no need to write outbound rule)
- Only **ALLOW** rules — no deny rules
- Default: All inbound DENIED, all outbound ALLOWED
- Can reference other security groups as source (not just IP ranges)

**Real-World Setup:**
```
alb-sg         → Inbound: HTTP 80 from 0.0.0.0/0 (anywhere)
app-sg         → Inbound: TCP 8080 from alb-sg only
db-sg          → Inbound: PostgreSQL 5432 from app-sg only
```

This means:
- Only the load balancer can call your app
- Only your app can call the database
- Nobody from the internet can directly reach your app or DB

**Referencing Security Groups:**
```
Instead of:  Allow port 5432 from IP 10.0.3.45 (unreliable, IP might change)
Use:         Allow port 5432 from "app-sg" security group
```

---

### 1.9 NACL — Network Access Control List

> NACL is the second layer of firewall — at the subnet level, not the resource level.

| Feature         | Security Group           | NACL                              |
|-----------------|--------------------------|-----------------------------------|
| Level           | Resource (EC2, RDS, etc.)| Subnet                            |
| State           | Stateful                 | Stateless (need inbound + outbound rules) |
| Rules           | Allow only               | Allow AND Deny                    |
| Evaluation      | All rules evaluated      | Rules evaluated in number order (lowest first) |
| Default         | All inbound blocked      | All traffic allowed               |

**When to use NACL:**
- You want to **block a specific IP address** (you can't do this with Security Groups)
- Extra layer of defence if a Security Group is misconfigured
- Block countries or IP ranges (use with WAF for advanced)

**NACL Rule Example:**
```
Rule #  | Type        | Source          | Allow/Deny
--------|-------------|-----------------|------------
100     | HTTP(80)    | 0.0.0.0/0       | ALLOW
200     | HTTPS(443)  | 0.0.0.0/0       | ALLOW
300     | All Traffic | 192.168.1.0/24  | DENY       ← block this subnet
*       | All Traffic | 0.0.0.0/0       | DENY       ← default deny all
```

---

### 1.10 CIDR Notation

CIDR (Classless Inter-Domain Routing) — defines IP address ranges.

```
Format: X.X.X.X/N
  X.X.X.X  = starting IP address
  /N       = how many bits are FIXED (the network part)

Examples:
  10.0.0.0/32  → only 1 IP address   (32 bits fixed, 0 bits free)
  10.0.0.0/24  → 256 IP addresses    (24 bits fixed, 8 bits free: 10.0.0.0 to 10.0.0.255)
  10.0.0.0/16  → 65,536 IP addresses (16 bits fixed, 16 bits free: 10.0.0.0 to 10.0.255.255)
  0.0.0.0/0    → ALL IP addresses    (0 bits fixed = everywhere = internet)
```

**Practical Use in VPC Design:**
```
VPC CIDR:     10.0.0.0/16      (65,536 addresses — your whole building)
Subnet 1:     10.0.1.0/24      (256 addresses — floor 1)
Subnet 2:     10.0.2.0/24      (256 addresses — floor 2)
Subnet 3:     10.0.3.0/24      (256 addresses — floor 3)
```

---

## 2. EC2 — Elastic Compute Cloud

> EC2 is like renting a computer on the internet. You choose the size (CPU/RAM), the operating system, and you pay for what you use.

**Analogy:** EC2 is a virtual machine. Instead of buying a physical server for ₹5 lakhs, you rent one in AWS for $0.05/hour and can turn it off when you're done.

---

### 2.1 EC2 Instance Types

AWS organizes instances into families based on use case. You'll need this for scenario questions.

| Family | Name | Use Case | Example Instances |
|--------|------|----------|-------------------|
| **General Purpose** | Balanced CPU/RAM | Web apps, Java backends, dev/test | t3.micro, t3.medium, m5.large |
| **Compute Optimized** | High CPU | CPU-intensive tasks, gaming, batch | c5.large, c6i.xlarge |
| **Memory Optimized** | High RAM | Databases, Redis, in-memory processing | r5.large, x1e.32xlarge |
| **Storage Optimized** | Fast local disk I/O | Cassandra, HDFS, data warehousing | i3.large, d3.xlarge |
| **Accelerated Computing** | GPU/FPGA | Machine learning, video processing | p3.2xlarge, g4dn.xlarge |

**Instance Size Naming:**
```
m5.xlarge
│ │  └─── Size: nano, micro, small, medium, large, xlarge, 2xlarge...
│ └────── Generation: 5 (newer = better performance)
└──────── Family: m = general purpose
```

**For Java Spring Boot apps** — start with `t3.medium` (2 vCPU, 4GB RAM) or `m5.large` (2 vCPU, 8GB RAM).  
**For databases (RDS)** — use `r5` memory optimized series.

---

### 2.2 EC2 Pricing Models

| Model | Description | When to Use | Saving |
|-------|-------------|-------------|--------|
| **On-Demand** | Pay per hour, no commitment | Dev/test, unpredictable workloads | Baseline (no discount) |
| **Reserved** | 1 or 3 year commitment | Production apps with steady traffic | Up to 75% cheaper |
| **Savings Plans** | Commit to $/hour spend, flexible instance | Modern alternative to Reserved | Up to 66% cheaper |
| **Spot** | Use AWS spare capacity | Batch jobs, non-critical, can handle interruption | Up to 90% cheaper |
| **Dedicated Hosts** | Physical server, only yours | Compliance (license per-socket, HIPAA, etc.) | Most expensive |

**Key Spot Instance Fact for Interviews:**
> AWS can **reclaim** Spot instances with only **2 minutes warning**. Never run your production DB on Spot. Good for batch processing, video encoding, CI/CD build agents.

---

### 2.3 EC2 Key Configurations

#### Security Group
Attach to EC2 to control who can talk to it.
```
Typical Spring Boot EC2:
  Inbound: TCP 8080 from alb-sg    ← only ALB can call your app
  Inbound: SSH 22 from bastion-sg  ← only bastion host can SSH into it
  Outbound: all traffic allowed    ← your app can call DB, S3, etc.
```

#### Key Pair
Used for SSH access to the EC2 instance.
- Generate a `.pem` file during instance launch
- `chmod 400 mykey.pem` on Linux/Mac
- `ssh -i mykey.pem ec2-user@<public-ip>`

#### AMI — Amazon Machine Image
A snapshot/template of an EC2 instance (OS + installed software).
- AWS provides base AMIs (Amazon Linux 2, Ubuntu, Windows Server)
- You can create **custom AMIs** — install Java, Docker, your config, then save as AMI
- Use custom AMI to launch identical instances quickly (no re-installing every time)

#### User Data Script
Shell script that runs **once** when EC2 first launches.
```bash
#!/bin/bash
yum update -y
yum install -y java-17
# Install your app, configure, start service
```

#### EBS Volumes (Elastic Block Store)
- Persistent disk storage for EC2 (like the hard drive)
- Types: gp3 (general purpose SSD — recommended), io2 (high performance), st1 (HDD for throughput)
- Survives EC2 restart (unlike instance store which is ephemeral)

#### Elastic IP
- A static public IP address — does not change even if you stop/start the EC2
- Regular EC2 public IPs change on restart
- Useful for: servers that need a fixed public IP

---

### 2.4 EC2 Auto Scaling

Auto Scaling automatically adjusts the number of EC2 instances based on demand.

```
Auto Scaling Group (ASG)
  ├─ Min instances: 2
  ├─ Max instances: 10
  ├─ Desired: 2 (start with 2)
  └─ Scaling Policy:
       └─ If CPU > 70% for 5 min → add 1 instance
       └─ If CPU < 30% for 15 min → remove 1 instance
```

**Works with:** Load Balancer (ALB) — new instances automatically register with ALB, terminating instances automatically deregister.

---

### 2.5 ALB — Application Load Balancer

- Distributes incoming HTTP/HTTPS traffic across multiple EC2 instances
- Works at Layer 7 (HTTP) — can route based on URL path or host header
- **Health checks** — only routes to healthy instances

```
User request: GET /api/orders
   │
   ▼
ALB (public subnet, port 80/443)
   ├─ /api/orders/* → order-service-target-group
   ├─ /api/customers/* → customer-service-target-group
   └─ Default → 404
```

---

## 3. S3 — Simple Storage Service

> S3 is AWS's object storage — think of it as a giant hard drive in the cloud where you store files (objects). Unlike a file system, S3 is flat — there are no real folders, just key names that look like paths.

**Key Concepts:**
- **Bucket:** The container (like a top-level folder). Name must be globally unique across ALL of AWS
- **Object:** Any file (image, PDF, JSON, JAR, video, etc.)
- **Key:** The full "path" of the object within the bucket (e.g., `users/profile/photo.jpg`)
- Max object size: 5 TB
- Virtually unlimited number of objects

---

### 3.1 S3 Storage Classes

> S3 has multiple storage tiers. More access frequency = higher per-request cost + lower storage cost. Less access = lower storage cost but higher retrieval cost (and sometimes delay).

| Storage Class | Access Pattern | Retrieval Time | Use Case | Cost Relative |
|---------------|---------------|----------------|----------|---------------|
| **S3 Standard** | Frequently accessed | Milliseconds | Active user files, profile photos, app assets | Highest storage |
| **S3 Standard-IA** (Infrequent Access) | Monthly access | Milliseconds | Backups, disaster recovery files you rarely touch | ~40% cheaper storage |
| **S3 One Zone-IA** | Infrequent + only 1 AZ | Milliseconds | Reproducible data you can recreate | ~20% cheaper than Standard-IA |
| **S3 Intelligent-Tiering** | Unknown/varying pattern | Milliseconds | Auto-moves between Standard & IA based on access patterns | Small monitoring fee |
| **S3 Glacier Instant Retrieval** | Archive, accessed quarterly | Milliseconds | Medical images, compliance archives | Much cheaper storage |
| **S3 Glacier Flexible Retrieval** | Archive, accessed 1-2x/year | Minutes to hours | Audit logs, annual backups | Very cheap storage |
| **S3 Glacier Deep Archive** | Rarely ever accessed | 12-48 hours | 7-10 year regulatory retention | Cheapest storage |

**Interview Tip:** Be ready to pick the right class for a scenario:
- User uploads profile picture → **S3 Standard**
- Database backup done nightly, rarely restored → **S3 Standard-IA**
- 10-year audit logs that must be kept but almost never read → **S3 Glacier Deep Archive**
- You don't know your access pattern → **S3 Intelligent-Tiering**

---

### 3.2 S3 Key Features

#### Bucket Policy
JSON permissions attached to the bucket controlling who can access what.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudFrontOnly",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudfront.amazonaws.com"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::my-frontend-bucket/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "arn:aws:cloudfront::123456789:distribution/ABCDEF"
        }
      }
    }
  ]
}
```

#### Versioning
- When enabled, every upload creates a new version — old versions are preserved
- You can restore deleted or overwritten files
- Versioning cannot be fully disabled once enabled (only suspended)

#### Pre-Signed URL
- A time-limited URL that gives temporary access to a private S3 object
- Common use case: Generate a pre-signed URL for a user to download their invoice PDF without making the bucket public
- Expires after a set duration (e.g., 15 minutes, 1 hour)

#### Access Control
- **Block Public Access** — master switch to keep everything private (recommended for most use cases)
- **ACLs** (Access Control Lists) — legacy, avoid using these for new setups
- **Bucket Policy** — the right way to grant cross-account or public access

#### Encryption
- **SSE-S3:** AWS manages the keys (default, easy)
- **SSE-KMS:** You control via AWS Key Management Service (audit trail, rotate keys)
- **SSE-C:** You provide your own key (you manage key outside AWS)
- **Client-side:** Encrypt before uploading

#### Object Lock
- Write Once Read Many (WORM) — objects cannot be deleted or overwritten
- For compliance (financial records, healthcare data)

#### S3 Static Website Hosting
- Host a complete Angular/React app directly from S3
- Combine with CloudFront for HTTPS, caching, and performance

#### Lifecycle Rules
Automatically transition objects between storage classes or delete them.

```
Rule: "Move logs to Glacier"
  Day 0:   Object created → S3 Standard
  Day 30:  → S3 Standard-IA (automatically)
  Day 90:  → S3 Glacier Flexible Retrieval (automatically)
  Day 365: → Delete (automatically)
```

---

## 4. AWS LAMBDA — Serverless

> Lambda lets you run code WITHOUT managing any servers. You upload your code, define what triggers it, and AWS runs it on-demand. You pay only for the time your code actually runs (per millisecond).

**Analogy:** Instead of renting a house (EC2) and paying 24/7, with Lambda you pay only when someone rings the doorbell (event happens) and you're home to answer (code runs).

---

### 4.1 How Lambda Works

```
Event Source (Trigger)          Lambda Function              Output
─────────────────────           ────────────────             ──────
API Gateway HTTP call    ──▶   Your Java/Python/Node code   ──▶  HTTP Response
S3 file uploaded         ──▶   Process the file             ──▶  Write to DynamoDB
DynamoDB stream          ──▶   Send notification            ──▶  SNS/SES email
CloudWatch scheduled     ──▶   Cleanup old data             ──▶  Delete S3 objects
SQS message              ──▶   Process order                ──▶  Update DB
```

### 4.2 Lambda Key Concepts

**Handler:** The entry point of your function
```java
// Java Lambda Handler
public class OrderHandler implements RequestHandler<APIGatewayProxyRequestEvent, APIGatewayProxyResponseEvent> {
    
    @Override
    public APIGatewayProxyResponseEvent handleRequest(
            APIGatewayProxyRequestEvent input, 
            Context context) {
        
        String orderId = input.getPathParameters().get("id");
        // process order
        return new APIGatewayProxyResponseEvent()
            .withStatusCode(200)
            .withBody("{\"orderId\": \"" + orderId + "\"}");
    }
}
```

**Execution Role:** IAM Role attached to Lambda defining what AWS services it can access.

**Timeout:** Max time a Lambda can run — default 3 seconds, max 15 minutes.

**Memory:** 128MB to 10GB. CPU scales proportionally with memory.

**Cold Start:** When Lambda hasn't been invoked recently, AWS needs to initialize the runtime — first request is slower (200ms-2s). Subsequent calls are fast (warm start). Use Provisioned Concurrency to eliminate cold starts for critical functions.

**Environment Variables:** Pass config (DB URL, bucket name, API keys) without hardcoding.

### 4.3 Lambda Pricing
- **Free tier:** 1 million requests + 400,000 GB-seconds compute per month (very generous)
- After free tier: $0.0000002 per request + compute time per GB-second
- Great for low-to-medium traffic workloads

### 4.4 When to Use Lambda vs EC2

| Use Lambda | Use EC2/EKS |
|------------|-------------|
| Short-lived tasks (under 15 min) | Long-running processes |
| Event-driven (react to S3 upload, API call) | Always-running web servers |
| Low/unpredictable traffic | Consistent high traffic |
| Simple microservices | Complex stateful apps |
| Image processing, file conversion | WebSocket servers |

---

## 5. DOCKER ON AWS

> Docker packages your application and everything it needs (Java runtime, configs, dependencies) into a single container. This container runs identically everywhere — your laptop, test environment, or AWS.

### 5.1 Docker Core Concepts

```
Dockerfile      →  Recipe to build a Docker Image
Docker Image    →  Snapshot/template of your app + runtime
Docker Container→  Running instance of an Image
Docker Hub/ECR  →  Registry to store and share Images
```

**Dockerfile for Spring Boot:**
```dockerfile
# Use official Java 21 lightweight image from ECR public
FROM public.ecr.aws/docker/library/eclipse-temurin:21-jre-alpine

# Set working directory inside container
WORKDIR /usr/share/app

# Copy compiled JAR into container
COPY target/*.jar app.jar

# Expose port 8080
EXPOSE 8080

# Start the application
CMD ["java", "-jar", "app.jar"]
```

**Build and Run:**
```bash
# Build image
docker build -t my-spring-app .

# Run container (host port 8080 → container port 8080)
docker run -p 8080:8080 my-spring-app

# Run with environment variables
docker run -p 8080:8080 \
  -e SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/mydb \
  -e SPRING_PROFILES_ACTIVE=prod \
  my-spring-app
```

### 5.2 Docker Compose (Local Development)

```yaml
# docker-compose.yml
version: '3.8'

services:
  postgres:
    image: postgres:15
    container_name: myapp-postgres
    environment:
      POSTGRES_DB: mydb
      POSTGRES_USER: myuser
      POSTGRES_PASSWORD: mypassword
    ports:
      - "5432:5432"

  order-service:
    build: ./order-service
    container_name: order-service
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres:5432/mydb
      SPRING_DATASOURCE_USERNAME: myuser
      SPRING_DATASOURCE_PASSWORD: mypassword
    ports:
      - "8080:8080"
    depends_on:
      - postgres

  customer-service:
    build: ./customer-service
    container_name: customer-service
    ports:
      - "8081:8080"
    depends_on:
      - postgres
```

```bash
docker-compose up     # start all services
docker-compose down   # stop all services
docker-compose logs order-service  # view specific service logs
```

### 5.3 ECR — Elastic Container Registry

ECR is AWS's Docker image registry — like Docker Hub but private and integrated with AWS.

```bash
# 1. Authenticate Docker with ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  123456789.dkr.ecr.us-east-1.amazonaws.com

# 2. Build image (specify platform for AWS Linux nodes)
docker build --platform=linux/amd64 -t order-service .

# 3. Tag image with ECR repository URI
docker tag order-service:latest \
  123456789.dkr.ecr.us-east-1.amazonaws.com/order-service:latest

# 4. Push to ECR
docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/order-service:latest
```

---

## 6. KUBERNETES & EKS

> Kubernetes (K8s) is like a smart manager for your Docker containers. If you have 10 containers of your app running, K8s ensures they stay running, restarts crashed ones, balances load between them, and scales up/down as needed.

**EKS (Elastic Kubernetes Service)** = AWS's managed Kubernetes — AWS handles the control plane (master nodes), you manage your worker nodes.

---

### 6.1 Kubernetes Architecture

```
EKS Cluster
 │
 ├─ Control Plane (managed by AWS in EKS)
 │    ├─ API Server        ← receives kubectl commands
 │    ├─ Scheduler         ← decides which node runs which pod
 │    └─ Controller Manager← watches cluster state, ensures desired = actual
 │
 └─ Worker Nodes (your EC2 instances)
      ├─ kubelet           ← agent on each node, executes pod instructions
      ├─ kube-proxy        ← networking, service discovery
      └─ Pods
           └─ Containers (your Docker container runs here)
```

### 6.2 Core Kubernetes Objects

**Pod**
- Smallest deployable unit in Kubernetes
- One or more containers sharing network and storage
- Has its own IP address within the cluster
- Ephemeral — if it dies, K8s creates a new one with a different IP

```yaml
# pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: order-service-pod
spec:
  containers:
    - name: order-service
      image: 123456789.dkr.ecr.us-east-1.amazonaws.com/order-service:latest
      ports:
        - containerPort: 8080
      env:
        - name: SPRING_PROFILES_ACTIVE
          value: "prod"
```

**Deployment**
- Manages a set of identical Pods
- Ensures desired number of replicas are running
- Handles rolling updates

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service-deployment
spec:
  replicas: 3          # 3 pods always running
  selector:
    matchLabels:
      app: order-service
  template:
    metadata:
      labels:
        app: order-service
    spec:
      containers:
        - name: order-service
          image: 123456789.dkr.ecr.us-east-1.amazonaws.com/order-service:latest
          ports:
            - containerPort: 8080
          resources:
            requests:
              memory: "512Mi"
              cpu: "250m"
            limits:
              memory: "1Gi"
              cpu: "500m"
```

**Service**
- Gives a stable network endpoint to a group of pods
- Pods come and go with changing IPs — Service provides a fixed address

```yaml
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: order-service
spec:
  selector:
    app: order-service     # routes to pods with this label
  ports:
    - port: 80             # service port
      targetPort: 8080     # pod's container port
  type: ClusterIP          # internal only (within cluster)
```

Service Types:
- **ClusterIP** — internal to cluster only (default, for microservice-to-microservice)
- **NodePort** — exposes on each node's IP at a static port (dev use)
- **LoadBalancer** — creates an AWS ALB/NLB (for public-facing services)

**ConfigMap**
- Store non-sensitive configuration as key-value pairs

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: order-service-config
data:
  SPRING_PROFILES_ACTIVE: "prod"
  APP_LOG_LEVEL: "INFO"
```

**Secret**
- Store sensitive data (passwords, API keys) — base64 encoded
- In AWS: Use AWS Secrets Manager instead and inject via IAM role

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque
data:
  DB_PASSWORD: cGFzc3dvcmQxMjM=   # base64 encoded
```

**Ingress**
- Routes external HTTP/HTTPS traffic into the cluster
- Like ALB listener rules but for Kubernetes

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    kubernetes.io/ingress.class: alb
spec:
  rules:
    - http:
        paths:
          - path: /api/orders
            pathType: Prefix
            backend:
              service:
                name: order-service
                port:
                  number: 80
          - path: /api/customers
            pathType: Prefix
            backend:
              service:
                name: customer-service
                port:
                  number: 80
```

### 6.3 Horizontal Pod Autoscaler (HPA)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: order-service-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: order-service-deployment
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70   # scale when avg CPU > 70%
```

### 6.4 Common kubectl Commands

```bash
kubectl get pods                          # list all pods
kubectl get pods -n my-namespace          # in specific namespace
kubectl describe pod order-service-xyz    # detailed pod info
kubectl logs order-service-xyz            # view pod logs
kubectl logs -f order-service-xyz         # follow logs
kubectl exec -it order-service-xyz -- sh  # shell into pod
kubectl apply -f deployment.yaml          # create/update resources
kubectl delete -f deployment.yaml         # delete resources
kubectl get services                      # list services
kubectl get deployments                   # list deployments
kubectl rollout restart deployment/order-service  # rolling restart
```

---

## 7. CI/CD WITH JENKINS ON AWS — MICROSERVICES

> Two real microservices — `order-service` (port 8080) and `customer-service` (port 8081) — used as examples throughout. Every config below is production-ready.

```
SYSTEM OVERVIEW
───────────────
GitHub
  ├── order-service/     ← git push → Jenkins pipeline A
  └── customer-service/  ← git push → Jenkins pipeline B

Each pipeline independently:
  Checkout → Build & Test → SAST → Docker Build → ECR Scan → Push
      → Deploy Staging → Smoke Test → DAST (ZAP) → Deploy Production → Notify

Kubernetes cluster (EKS):
  namespace: staging
    ├── order-service    (2 pods, ClusterIP)
    └── customer-service (2 pods, ClusterIP)
  namespace: production
    ├── order-service    (3 pods, ClusterIP) ─┐
    └── customer-service (3 pods, ClusterIP) ─┴── ALB Ingress → api.myapp.com
```

| Service | Port | Database | Calls |
|---|---|---|---|
| order-service | 8080 | PostgreSQL orders_db | customer-service (validate customer on order creation) |
| customer-service | 8081 | PostgreSQL customers_db | — |

---

### 7.1 Production Dockerfiles — Multi-Stage Builds

Multi-stage builds strip Maven and the JDK out of the final image — only the JRE and the JAR are shipped.

```
Single-stage image: ~650 MB  (Maven + JDK + source + JAR)
Multi-stage image:  ~180 MB  (JRE + JAR only)
→ Smaller attack surface, faster ECR pull, cheaper storage
```

**order-service/Dockerfile**
```dockerfile
# ── Stage 1: Build ───────────────────────────────────────────────────
FROM maven:3.9-eclipse-temurin-21-alpine AS build

WORKDIR /build

# Copy pom first — Docker caches this layer; dependency download
# is skipped on subsequent builds when only src/ changes.
COPY pom.xml .
RUN mvn dependency:go-offline -B

COPY src ./src
RUN mvn clean package -DskipTests=false -B

# ── Stage 2: Runtime ─────────────────────────────────────────────────
FROM eclipse-temurin:21-jre-alpine AS runtime

# Never run as root inside a container
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

COPY --from=build /build/target/order-service-*.jar app.jar

RUN chown -R appuser:appgroup /app
USER appuser

EXPOSE 8080

# -XX:+UseContainerSupport  → JVM reads cgroup limits (not host CPU/RAM)
# -XX:MaxRAMPercentage=75.0 → heap = 75% of the container memory limit
# urandom entropy           → faster Tomcat startup on Linux
ENTRYPOINT ["java", \
  "-XX:+UseContainerSupport", \
  "-XX:MaxRAMPercentage=75.0", \
  "-Djava.security.egd=file:/dev/./urandom", \
  "-jar", "app.jar"]
```

**customer-service/Dockerfile** — identical pattern, different port:
```dockerfile
FROM maven:3.9-eclipse-temurin-21-alpine AS build
WORKDIR /build
COPY pom.xml .
RUN mvn dependency:go-offline -B
COPY src ./src
RUN mvn clean package -DskipTests=false -B

FROM eclipse-temurin:21-jre-alpine AS runtime
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
WORKDIR /app
COPY --from=build /build/target/customer-service-*.jar app.jar
RUN chown -R appuser:appgroup /app
USER appuser
EXPOSE 8081
ENTRYPOINT ["java", \
  "-XX:+UseContainerSupport", \
  "-XX:MaxRAMPercentage=75.0", \
  "-Djava.security.egd=file:/dev/./urandom", \
  "-jar", "app.jar"]
```

---

### 7.2 Docker Compose — Local Development (Both Services Together)

```yaml
# docker-compose.yml
version: '3.9'

services:
  # ── Databases ──────────────────────────────────────────────────────
  postgres-orders:
    image: postgres:16-alpine
    container_name: postgres-orders
    environment:
      POSTGRES_DB: orders_db
      POSTGRES_USER: orders_user
      POSTGRES_PASSWORD: orders_secret
    ports:
      - "5432:5432"
    volumes:
      - orders-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U orders_user -d orders_db"]
      interval: 10s
      timeout: 5s
      retries: 5

  postgres-customers:
    image: postgres:16-alpine
    container_name: postgres-customers
    environment:
      POSTGRES_DB: customers_db
      POSTGRES_USER: customers_user
      POSTGRES_PASSWORD: customers_secret
    ports:
      - "5433:5432"
    volumes:
      - customers-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U customers_user -d customers_db"]
      interval: 10s
      timeout: 5s
      retries: 5

  # ── Microservices ──────────────────────────────────────────────────
  order-service:
    build:
      context: ./order-service
      dockerfile: Dockerfile
    container_name: order-service
    ports:
      - "8080:8080"
    environment:
      SPRING_PROFILES_ACTIVE: local
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres-orders:5432/orders_db
      SPRING_DATASOURCE_USERNAME: orders_user
      SPRING_DATASOURCE_PASSWORD: orders_secret
      CUSTOMER_SERVICE_URL: http://customer-service:8081
    depends_on:
      postgres-orders:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider",
             "http://localhost:8080/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  customer-service:
    build:
      context: ./customer-service
      dockerfile: Dockerfile
    container_name: customer-service
    ports:
      - "8081:8081"
    environment:
      SPRING_PROFILES_ACTIVE: local
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres-customers:5432/customers_db
      SPRING_DATASOURCE_USERNAME: customers_user
      SPRING_DATASOURCE_PASSWORD: customers_secret
    depends_on:
      postgres-customers:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider",
             "http://localhost:8081/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

volumes:
  orders-data:
  customers-data:
```

```bash
docker-compose up --build          # build images and start all containers
docker-compose up -d               # start in background
docker-compose logs -f order-service   # tail logs for one service
docker-compose down -v             # stop and remove volumes (clean slate)
```

---

### 7.3 ECR — One Repository Per Microservice

```bash
# Create one repo per service (run once)
for SERVICE in order-service customer-service; do
  aws ecr create-repository \
    --repository-name $SERVICE \
    --image-scanning-configuration scanOnPush=true \
    --encryption-configuration encryptionType=AES256 \
    --region us-east-1

  # Keep only last 10 images — prevent storage bloat
  aws ecr put-lifecycle-policy \
    --repository-name $SERVICE \
    --lifecycle-policy-text '{
      "rules": [{
        "rulePriority": 1,
        "description": "Keep last 10 images",
        "selection": {
          "tagStatus": "any",
          "countType": "imageCountMoreThan",
          "countNumber": 10
        },
        "action": { "type": "expire" }
      }]
    }'
done
```

ECR URL pattern: `123456789.dkr.ecr.us-east-1.amazonaws.com/order-service:42`  
Tag with build number (never rely on `:latest` in K8s — it's not reproducible).

---

### 7.4 Kubernetes — Production Manifests

```
k8s/
├── namespaces.yaml
├── ingress.yaml                     ← single ALB routes both services
├── order-service/
│   ├── configmap.yaml
│   ├── externalsecret.yaml          ← pulls DB password from AWS Secrets Manager
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── hpa.yaml
│   ├── pdb.yaml
│   └── networkpolicy.yaml
└── customer-service/
    └── ... (same structure)
```

#### Namespaces

```yaml
# k8s/namespaces.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: staging
  labels:
    environment: staging
---
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    environment: production
```

#### ConfigMaps

```yaml
# k8s/order-service/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: order-service-config
  namespace: production
data:
  SPRING_PROFILES_ACTIVE: "prod"
  SERVER_PORT: "8080"
  # Service-to-service: K8s DNS resolves this within the cluster
  CUSTOMER_SERVICE_URL: "http://customer-service.production.svc.cluster.local:8081"
  SPRING_DATASOURCE_URL: "jdbc:postgresql://orders-rds.prod.internal:5432/orders_db"
  SPRING_DATASOURCE_USERNAME: "orders_user"
  MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE: "health,info,metrics,prometheus"
  MANAGEMENT_ENDPOINT_HEALTH_SHOW_DETAILS: "when-authorized"
---
# k8s/customer-service/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: customer-service-config
  namespace: production
data:
  SPRING_PROFILES_ACTIVE: "prod"
  SERVER_PORT: "8081"
  SPRING_DATASOURCE_URL: "jdbc:postgresql://customers-rds.prod.internal:5432/customers_db"
  SPRING_DATASOURCE_USERNAME: "customers_user"
  MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE: "health,info,metrics,prometheus"
  MANAGEMENT_ENDPOINT_HEALTH_SHOW_DETAILS: "when-authorized"
```

#### Secrets — AWS Secrets Manager via External Secrets Operator

Never commit passwords to Git. External Secrets Operator syncs from AWS Secrets Manager into regular K8s Secrets automatically and rotates them on a schedule.

```yaml
# k8s/order-service/externalsecret.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: order-service-secret
  namespace: production
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-store
    kind: ClusterSecretStore
  target:
    name: order-service-secret    # creates a standard K8s Secret with this name
    creationPolicy: Owner
  data:
    - secretKey: DB_PASSWORD
      remoteRef:
        key: /prod/order-service/db
        property: password
    - secretKey: JWT_SECRET
      remoteRef:
        key: /prod/order-service/jwt
        property: secret
---
# k8s/customer-service/externalsecret.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: customer-service-secret
  namespace: production
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-store
    kind: ClusterSecretStore
  target:
    name: customer-service-secret
    creationPolicy: Owner
  data:
    - secretKey: DB_PASSWORD
      remoteRef:
        key: /prod/customer-service/db
        property: password
    - secretKey: JWT_SECRET
      remoteRef:
        key: /prod/customer-service/jwt
        property: secret
```

#### Deployment — order-service (Full Production Config)

```yaml
# k8s/order-service/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service
  namespace: production
  labels:
    app: order-service
spec:
  replicas: 3
  selector:
    matchLabels:
      app: order-service
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # allow 1 extra pod during rollout (4 pods total temporarily)
      maxUnavailable: 0  # NEVER drop below 3 running pods → true zero-downtime rollout
  template:
    metadata:
      labels:
        app: order-service
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/path: "/actuator/prometheus"
        prometheus.io/port: "8080"
    spec:
      # Spread pods across AZs — no 2 order-service pods in the same AZ
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchExpressions:
                  - key: app
                    operator: In
                    values: [order-service]
              topologyKey: topology.kubernetes.io/zone

      terminationGracePeriodSeconds: 60   # give Spring Boot time for graceful shutdown

      serviceAccountName: order-service-sa   # IRSA: pod-level IAM Role for S3/Secrets

      containers:
        - name: order-service
          image: 123456789.dkr.ecr.us-east-1.amazonaws.com/order-service:latest
          ports:
            - containerPort: 8080
              name: http

          # Non-sensitive config from ConfigMap
          envFrom:
            - configMapRef:
                name: order-service-config

          # Sensitive values injected individually from Secret
          env:
            - name: SPRING_DATASOURCE_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: order-service-secret
                  key: DB_PASSWORD
            - name: JWT_SECRET
              valueFrom:
                secretKeyRef:
                  name: order-service-secret
                  key: JWT_SECRET

          resources:
            requests:
              memory: "512Mi"   # guaranteed memory on the node
              cpu: "250m"       # 0.25 vCPU guaranteed
            limits:
              memory: "1Gi"     # pod is OOMKilled if it exceeds this
              cpu: "1000m"      # throttled (not killed) if it exceeds this

          # Startup probe — K8s waits up to 300s for first boot before liveness kicks in
          # Without this, liveness would kill a slow-starting Spring Boot pod on first run
          startupProbe:
            httpGet:
              path: /actuator/health
              port: 8080
            failureThreshold: 30
            periodSeconds: 10

          # Liveness probe — pod is RESTARTED if this fails 3 times
          livenessProbe:
            httpGet:
              path: /actuator/health/liveness
              port: 8080
            periodSeconds: 10
            failureThreshold: 3
            timeoutSeconds: 5

          # Readiness probe — pod is REMOVED from Service (no traffic) if this fails
          readinessProbe:
            httpGet:
              path: /actuator/health/readiness
              port: 8080
            periodSeconds: 5
            failureThreshold: 3
            timeoutSeconds: 3

          # Give ALB 10s to drain connections before Spring Boot begins shutdown
          lifecycle:
            preStop:
              exec:
                command: ["sh", "-c", "sleep 10"]
```

#### Deployment — customer-service

```yaml
# k8s/customer-service/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: customer-service
  namespace: production
  labels:
    app: customer-service
spec:
  replicas: 3
  selector:
    matchLabels:
      app: customer-service
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: customer-service
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/path: "/actuator/prometheus"
        prometheus.io/port: "8081"
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchExpressions:
                  - key: app
                    operator: In
                    values: [customer-service]
              topologyKey: topology.kubernetes.io/zone
      terminationGracePeriodSeconds: 60
      serviceAccountName: customer-service-sa
      containers:
        - name: customer-service
          image: 123456789.dkr.ecr.us-east-1.amazonaws.com/customer-service:latest
          ports:
            - containerPort: 8081
              name: http
          envFrom:
            - configMapRef:
                name: customer-service-config
          env:
            - name: SPRING_DATASOURCE_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: customer-service-secret
                  key: DB_PASSWORD
            - name: JWT_SECRET
              valueFrom:
                secretKeyRef:
                  name: customer-service-secret
                  key: JWT_SECRET
          resources:
            requests:
              memory: "512Mi"
              cpu: "250m"
            limits:
              memory: "1Gi"
              cpu: "1000m"
          startupProbe:
            httpGet:
              path: /actuator/health
              port: 8081
            failureThreshold: 30
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /actuator/health/liveness
              port: 8081
            periodSeconds: 10
            failureThreshold: 3
            timeoutSeconds: 5
          readinessProbe:
            httpGet:
              path: /actuator/health/readiness
              port: 8081
            periodSeconds: 5
            failureThreshold: 3
            timeoutSeconds: 3
          lifecycle:
            preStop:
              exec:
                command: ["sh", "-c", "sleep 10"]
```

#### Services

```yaml
# k8s/order-service/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: order-service
  namespace: production
spec:
  selector:
    app: order-service
  ports:
    - name: http
      port: 8080
      targetPort: 8080
  type: ClusterIP   # internal only — Ingress exposes it externally
---
# k8s/customer-service/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: customer-service
  namespace: production
spec:
  selector:
    app: customer-service
  ports:
    - name: http
      port: 8081
      targetPort: 8081
  type: ClusterIP
```

#### Ingress — Single AWS ALB for Both Services

```yaml
# k8s/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: microservices-ingress
  namespace: production
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS": 443}, {"HTTP": 80}]'
    alb.ingress.kubernetes.io/ssl-redirect: "443"
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:123456789:certificate/your-cert-id
    alb.ingress.kubernetes.io/healthcheck-path: /actuator/health
    alb.ingress.kubernetes.io/healthcheck-interval-seconds: "15"
    alb.ingress.kubernetes.io/healthy-threshold-count: "2"
    alb.ingress.kubernetes.io/unhealthy-threshold-count: "2"
spec:
  rules:
    - host: api.myapp.com
      http:
        paths:
          - path: /api/orders
            pathType: Prefix
            backend:
              service:
                name: order-service
                port:
                  number: 8080
          - path: /api/customers
            pathType: Prefix
            backend:
              service:
                name: customer-service
                port:
                  number: 8081
```

#### HPA — Horizontal Pod Autoscaler

```yaml
# k8s/order-service/hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: order-service-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: order-service
  minReplicas: 3
  maxReplicas: 15
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60     # wait 60s before scaling up again
      policies:
        - type: Pods
          value: 2                        # add max 2 pods per scale event
          periodSeconds: 60
    scaleDown:
      stabilizationWindowSeconds: 300    # wait 5 min before scale-down (prevents flapping)
      policies:
        - type: Pods
          value: 1
          periodSeconds: 60
---
# k8s/customer-service/hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: customer-service-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: customer-service
  minReplicas: 3
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
```

#### PodDisruptionBudget — Survive Node Upgrades Without Outage

```yaml
# k8s/order-service/pdb.yaml
# During EKS node group upgrade (node drain), K8s must keep at least 2 pods running
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: order-service-pdb
  namespace: production
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: order-service
---
# k8s/customer-service/pdb.yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: customer-service-pdb
  namespace: production
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: customer-service
```

#### NetworkPolicy — Lock Down Pod-to-Pod Traffic

```yaml
# k8s/order-service/networkpolicy.yaml
# order-service: accepts traffic from ALB ingress controller only
#                can call customer-service and its own RDS
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: order-service-netpol
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: order-service
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system   # ALB ingress controller namespace
      ports:
        - protocol: TCP
          port: 8080
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: customer-service
      ports:
        - protocol: TCP
          port: 8081
    - ports:
        - protocol: UDP
          port: 53    # DNS
        - protocol: TCP
          port: 5432  # RDS PostgreSQL
---
# k8s/customer-service/networkpolicy.yaml
# customer-service: accepts from order-service and ALB
#                   cannot initiate calls to order-service (one-way dependency)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: customer-service-netpol
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: customer-service
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: order-service
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
      ports:
        - protocol: TCP
          port: 8081
  egress:
    - ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 5432
```

---

### 7.5 Setting Up Jenkins on EC2

```bash
# Amazon Linux 2023 — t3.large recommended (Jenkins + Docker builds are memory-hungry)
sudo yum update -y
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum install -y java-21-amazon-corretto jenkins
sudo systemctl start jenkins && sudo systemctl enable jenkins

# Docker — Jenkins uses it to build images and run OWASP ZAP
sudo yum install -y docker
sudo systemctl start docker
sudo usermod -aG docker jenkins   # allow Jenkins to run docker commands
sudo systemctl restart jenkins

# kubectl — Jenkins uses it to deploy to EKS
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install
```

---

### 7.6 Jenkinsfile — order-service (Full Production Pipeline)

Each microservice lives in its own GitHub repo with its own Jenkinsfile at the root.

```groovy
// order-service/Jenkinsfile
pipeline {
    agent any

    environment {
        AWS_REGION    = 'us-east-1'
        ECR_REGISTRY  = '123456789.dkr.ecr.us-east-1.amazonaws.com'
        SERVICE_NAME  = 'order-service'
        EKS_CLUSTER   = 'prod-eks-cluster'
        STAGING_NS    = 'staging'
        PROD_NS       = 'production'
        IMAGE_TAG     = "${BUILD_NUMBER}"
        FULL_IMAGE    = "${ECR_REGISTRY}/order-service:${BUILD_NUMBER}"
    }

    options {
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_SHORT = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()
                }
            }
        }

        stage('Build & Test') {
            steps {
                sh 'mvn clean package -DskipTests=false -B'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                    jacoco(
                        execPattern:   'target/jacoco.exec',
                        classPattern:  'target/classes',
                        sourcePattern: 'src/main/java'
                    )
                }
            }
        }

        // ── SAST: scans source code before Docker image is even built ──────
        stage('SAST - SonarQube') {
            steps {
                withSonarQubeEnv('SonarQube-Server') {
                    sh """
                        mvn sonar:sonar \
                          -Dsonar.projectKey=${SERVICE_NAME} \
                          -Dsonar.projectName='Order Service' \
                          -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
                    """
                }
            }
        }

        stage('SAST - Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                    // Pipeline aborts here if: coverage < 80%, any new bug/vulnerability
                }
            }
        }

        stage('Docker Build') {
            steps {
                sh """
                    docker build \
                      --platform=linux/amd64 \
                      --build-arg BUILD_DATE=\$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
                      --build-arg GIT_COMMIT=${GIT_SHORT} \
                      -t ${SERVICE_NAME}:${IMAGE_TAG} \
                      -t ${SERVICE_NAME}:latest \
                      .
                """
            }
        }

        // ── Push to ECR, then wait for ECR's built-in vulnerability scan ──
        stage('Push to ECR & Image Scan') {
            steps {
                sh """
                    aws ecr get-login-password --region ${AWS_REGION} | \
                      docker login --username AWS --password-stdin ${ECR_REGISTRY}

                    docker tag ${SERVICE_NAME}:${IMAGE_TAG} ${FULL_IMAGE}
                    docker tag ${SERVICE_NAME}:latest ${ECR_REGISTRY}/${SERVICE_NAME}:latest
                    docker push ${FULL_IMAGE}
                    docker push ${ECR_REGISTRY}/${SERVICE_NAME}:latest

                    # Block until ECR finishes scanning the image for OS/library CVEs
                    aws ecr wait image-scan-complete \
                      --repository-name ${SERVICE_NAME} \
                      --image-id imageTag=${IMAGE_TAG} \
                      --region ${AWS_REGION}

                    CRITICAL=\$(aws ecr describe-image-scan-findings \
                      --repository-name ${SERVICE_NAME} \
                      --image-id imageTag=${IMAGE_TAG} \
                      --region ${AWS_REGION} \
                      --query 'imageScanFindings.findingSeverityCounts.CRITICAL' \
                      --output text)

                    if [ "\$CRITICAL" != "None" ] && [ "\$CRITICAL" -gt "0" ]; then
                      echo "BLOCKED: \$CRITICAL CRITICAL CVEs found in Docker image"
                      exit 1
                    fi
                    echo "ECR image scan passed — 0 CRITICAL CVEs"
                """
            }
        }

        stage('Deploy to Staging') {
            steps {
                sh """
                    aws eks update-kubeconfig \
                      --region ${AWS_REGION} --name ${EKS_CLUSTER}

                    # Apply full K8s stack for this service in staging namespace
                    kubectl apply -f k8s/order-service/ -n ${STAGING_NS}

                    # Pin to exact build image — never use :latest tag in K8s deployments
                    kubectl set image deployment/${SERVICE_NAME} \
                      ${SERVICE_NAME}=${FULL_IMAGE} \
                      -n ${STAGING_NS}

                    kubectl rollout status deployment/${SERVICE_NAME} \
                      -n ${STAGING_NS} --timeout=300s
                """
            }
        }

        stage('Smoke Test - Staging') {
            steps {
                script {
                    sleep(30)  // wait for ALB target group registration
                    def host = sh(
                        script: """kubectl get ingress microservices-ingress \
                                     -n ${STAGING_NS} \
                                     -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'""",
                        returnStdout: true
                    ).trim()
                    env.STAGING_HOST = host

                    sh """
                        curl -f http://${STAGING_HOST}/actuator/health   || exit 1
                        curl -f http://${STAGING_HOST}/api/orders/health || exit 1
                        echo "Smoke test PASSED — order-service is healthy in staging"
                    """
                }
            }
        }

        // ── DAST: ZAP attacks the running staging app ─────────────────────
        stage('DAST - OWASP ZAP') {
            steps {
                sh 'mkdir -p zap-reports'
                script {
                    sh """
                        docker run --rm \
                          --network host \
                          -v \$(pwd)/zap-reports:/zap/wrk/:rw \
                          -u root \
                          ghcr.io/zaproxy/zaproxy:stable \
                          zap-baseline.py \
                            -t http://${STAGING_HOST}/api/orders \
                            -r zap-report.html \
                            -J zap-report.json \
                            -I -l WARN
                    """
                    def report   = readJSON file: 'zap-reports/zap-report.json'
                    def highCrit = report.site[0].alerts.count { it.riskcode == "3" }
                    if (highCrit > 0) {
                        error "DAST FAILED: ${highCrit} HIGH/CRITICAL findings — production deploy blocked"
                    }
                    echo "DAST passed — no HIGH/CRITICAL vulnerabilities"
                }
            }
            post {
                always {
                    publishHTML([
                        allowMissing:          false,
                        alwaysLinkToLastBuild: true,
                        keepAll:               true,
                        reportDir:             'zap-reports',
                        reportFiles:           'zap-report.html',
                        reportName:            'OWASP ZAP — Order Service'
                    ])
                }
            }
        }

        // ── Reaches production only if SAST + ECR scan + DAST all passed ──
        stage('Deploy to Production') {
            steps {
                sh """
                    kubectl apply -f k8s/order-service/ -n ${PROD_NS}

                    kubectl set image deployment/${SERVICE_NAME} \
                      ${SERVICE_NAME}=${FULL_IMAGE} \
                      -n ${PROD_NS}

                    # Rolling update: maxSurge=1, maxUnavailable=0 → zero-downtime
                    kubectl rollout status deployment/${SERVICE_NAME} \
                      -n ${PROD_NS} --timeout=300s
                """
            }
        }

        stage('Production Smoke Test') {
            steps {
                sh """
                    PROD_HOST=\$(kubectl get ingress microservices-ingress \
                      -n ${PROD_NS} \
                      -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
                    sleep 15
                    curl -f http://\${PROD_HOST}/api/orders/health || exit 1
                    echo "Production smoke test PASSED — order-service is live"
                """
            }
        }
    }

    post {
        success {
            slackSend(
                channel: '#deployments', color: 'good',
                message: "SUCCESS: order-service #${BUILD_NUMBER} (${GIT_SHORT}) deployed to production"
            )
        }
        failure {
            slackSend(
                channel: '#deployments', color: 'danger',
                message: "FAILED: order-service #${BUILD_NUMBER} — check Jenkins logs"
            )
            sh "kubectl rollout undo deployment/${SERVICE_NAME} -n ${PROD_NS} || true"
        }
        always {
            sh """
                docker rmi ${SERVICE_NAME}:${IMAGE_TAG} || true
                docker rmi ${FULL_IMAGE} || true
                docker system prune -f || true
            """
        }
    }
}
```

---

### 7.7 Jenkinsfile — customer-service

customer-service lives in its own GitHub repo with its own pipeline. Structure is identical — only these values differ:

```groovy
// customer-service/Jenkinsfile — only the differences from order-service

environment {
    SERVICE_NAME = 'customer-service'
    FULL_IMAGE   = "${ECR_REGISTRY}/customer-service:${BUILD_NUMBER}"
}

// SonarQube:
//   -Dsonar.projectKey=customer-service
//   -Dsonar.projectName='Customer Service'

// K8s manifests:
//   kubectl apply -f k8s/customer-service/ -n ${STAGING_NS}
//   kubectl apply -f k8s/customer-service/ -n ${PROD_NS}

// Smoke test targets:
//   curl -f http://${STAGING_HOST}/api/customers/health

// DAST target:
//   zap-baseline.py -t http://${STAGING_HOST}/api/customers
```

In Jenkins, create two separate **Multibranch Pipeline** jobs — one per repo. A push to `order-service` only triggers Pipeline A. A push to `customer-service` only triggers Pipeline B. The services deploy independently, at their own cadence.

---

### 7.8 IAM Role for Jenkins EC2

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ECRAllAccess",
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage",
        "ecr:DescribeImageScanFindings",
        "ecr:StartImageScan",
        "ecr:DescribeRepositories"
      ],
      "Resource": "*"
    },
    {
      "Sid": "EKSDescribe",
      "Effect": "Allow",
      "Action": ["eks:DescribeCluster", "eks:ListClusters"],
      "Resource": "*"
    },
    {
      "Sid": "SecretsManagerForDeployment",
      "Effect": "Allow",
      "Action": ["secretsmanager:GetSecretValue"],
      "Resource": "arn:aws:secretsmanager:us-east-1:123456789:secret:/prod/*"
    }
  ]
}
```

---

### 7.9 Jenkins + GitHub Webhook

Each repo gets its own webhook pointing to the same Jenkins server:

```
order-service repo → Settings → Webhooks:
  Payload URL:  http://<jenkins-ec2-ip>:8080/github-webhook/
  Content type: application/json
  Trigger:      Just the push event

customer-service repo → same webhook URL, different Jenkins job triggered
```

Now every `git push` to `main` in either repo automatically triggers the correct pipeline.

---

### 7.10 Blue-Green vs Rolling Deployment

**Rolling Update (used above — K8s default):**
```
Before:  [order-v1] [order-v1] [order-v1]
Step 1:  [order-v2] [order-v1] [order-v1]  ← maxSurge=1, maxUnavailable=0
Step 2:  [order-v2] [order-v2] [order-v1]
After:   [order-v2] [order-v2] [order-v2]

Each new pod must pass readinessProbe before traffic is shifted to it.
Rollback: kubectl rollout undo deployment/order-service -n production
```

**Blue-Green Deployment:**
```
State 1: ALB → order-service-blue (v1) [100% traffic]

Step 1:  Deploy Green (v2) — no traffic yet
         kubectl apply -f k8s/order-service-green.yaml -n production
         kubectl rollout status deployment/order-service-green -n production

Step 2:  Run automated tests against Green endpoint (zero real-user traffic)

Step 3:  Instant switch — all traffic moves from Blue to Green at once
         aws elbv2 modify-listener \
             --listener-arn $LISTENER_ARN \
             --default-actions Type=forward,TargetGroupArn=$GREEN_TG_ARN

Rollback (instant): switch back to Blue target group
         aws elbv2 modify-listener \
             --listener-arn $LISTENER_ARN \
             --default-actions Type=forward,TargetGroupArn=$BLUE_TG_ARN
```

| | Rolling | Blue-Green |
|---|---|---|
| Downtime | Zero (if health checks pass) | Zero |
| Rollback speed | Slow (roll back one pod at a time) | Instant (flip ALB rule) |
| Cost | Normal (1 extra pod briefly) | Double infra during transition |
| Mixed versions | Yes (briefly, both run simultaneously) | No (clean cutover) |

---

### 7.11 SAST & DAST — Security in the Microservices Pipeline

#### SAST (Static Application Security Testing) — SonarQube

Scans **source code** without running the app. Runs immediately after `mvn package`, before Docker is built. Each microservice is a separate SonarQube project.

**What SonarQube catches per service:**
```
order-service:
  - SQL injection: String q = "SELECT * FROM orders WHERE id=" + orderId
  - Null dereference: repo.findById(id).getName() without null check
  - Hardcoded secret in test: String secret = "my-jwt-secret"

customer-service:
  - Weak hashing: MessageDigest.getInstance("MD5") for passwords
  - XSS: response.getWriter().print(req.getParameter("name"))
  - Missing auth: @GetMapping("/admin/customers") without @PreAuthorize
```

**Quality Gate — blocks pipeline if any of these fail:**
```
New code coverage       < 80%
New bugs                > 0
New vulnerabilities     > 0
Unreviewed hotspots     > 0
```

SonarQube server (Docker on EC2):
```bash
docker run -d --name sonarqube -p 9000:9000 \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  sonarqube:community
# Default login: admin/admin — change on first login
```

#### DAST (Dynamic Application Security Testing) — OWASP ZAP

Attacks the **running staging app** with real HTTP requests — like an ethical hacker. Runs after staging deploy. Each service is scanned separately.

```
order-service staging  → ZAP targets /api/orders/*
customer-service staging → ZAP targets /api/customers/*
```

**What ZAP tests per service:**
```
order-service:
  GET /api/orders/{id}     → IDOR: can user A access user B's order?
  GET /api/orders/search?q → SQL injection via query param
  POST /api/orders         → XSS: script tag in order notes field

customer-service:
  POST /api/customers/login → SQLi: ' OR '1'='1 in username
  GET /api/customers/{id}   → auth bypass: request without JWT token
  PUT /api/customers/{id}   → mass assignment: inject isAdmin:true in body
```

#### Full Security Pipeline Flow

```
┌───────────────────────────────────────────────────────────────┐
│        JENKINS PIPELINE — EACH MICROSERVICE INDEPENDENTLY     │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│  Checkout → Build & Test → SAST (SonarQube) → Quality Gate  │
│                                  │                            │
│                            FAIL? → PIPELINE STOPS            │
│                                  │                            │
│  Docker Build → Push to ECR → ECR Vulnerability Scan         │
│                                  │                            │
│                    CRITICAL CVE? → PIPELINE STOPS            │
│                                  │                            │
│  Deploy Staging → Smoke Test → DAST (OWASP ZAP)             │
│                                  │                            │
│                         HIGH/CRIT? → PIPELINE STOPS         │
│                                  │                            │
│  Deploy Production → Smoke Test → Slack Notify              │
│                                  │                            │
│  On any failure: kubectl rollout undo in production          │
└───────────────────────────────────────────────────────────────┘

Three security gates before production:
  1. SAST Quality Gate  — code quality + static security analysis
  2. ECR Image Scan     — OS package and library CVEs in Docker image
  3. DAST ZAP           — runtime attack surface (XSS, SQLi, auth bypass)
```

**SAST vs DAST — Side-by-Side:**

| | SAST (SonarQube) | DAST (OWASP ZAP) |
|---|---|---|
| Scans | Source code | Running application (HTTP) |
| App needs to run? | No | Yes — must be deployed to staging |
| When in pipeline | After `mvn package`, before Docker | After staging deploy, before prod |
| Speed | 1–3 min | 5–30 min |
| Catches | Bad code patterns, hardcoded secrets | XSS, SQLi, auth bypass, missing headers |
| Does NOT catch | Runtime misconfigs (wrong headers) | Code logic buried in dead code paths |
| Blocks deploy if | Quality Gate fails | HIGH or CRITICAL severity findings |



---

## 8. JAVA SPRING BOOT + S3 CODE EXAMPLES

### 8.1 Dependencies (pom.xml)

```xml
<!-- AWS SDK v2 for S3 -->
<dependency>
    <groupId>software.amazon.awssdk</groupId>
    <artifactId>s3</artifactId>
    <version>2.25.0</version>
</dependency>

<!-- Or use Spring Cloud AWS (easier Spring integration) -->
<dependency>
    <groupId>io.awspring.cloud</groupId>
    <artifactId>spring-cloud-aws-starter-s3</artifactId>
    <version>3.1.1</version>
</dependency>

<!-- Spring Boot Web -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>
```

### 8.2 Application Properties

```yaml
# application.yml
spring:
  cloud:
    aws:
      region:
        static: us-east-1
      # When running on EC2/ECS/Lambda with IAM Role attached,
      # NO credentials needed — AWS SDK finds them automatically via Instance Metadata.
      # For local development, set these or use AWS CLI configured credentials:
      credentials:
        access-key: ${AWS_ACCESS_KEY_ID:}       # from env variable
        secret-key: ${AWS_SECRET_ACCESS_KEY:}   # from env variable

app:
  s3:
    bucket-name: ${S3_BUCKET_NAME:my-app-bucket}
    presigned-url-expiry-minutes: 60
```

### 8.3 S3 Configuration Bean

```java
package com.myapp.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;

@Configuration
public class S3Config {

    @Value("${spring.cloud.aws.region.static}")
    private String region;

    @Bean
    public S3Client s3Client() {
        return S3Client.builder()
                .region(Region.of(region))
                // DefaultCredentialsProvider automatically picks up:
                // 1. Environment variables (AWS_ACCESS_KEY_ID)
                // 2. AWS CLI config (~/.aws/credentials)
                // 3. IAM Role attached to EC2/Lambda (recommended for production)
                .credentialsProvider(DefaultCredentialsProvider.create())
                .build();
    }

    @Bean
    public S3Presigner s3Presigner() {
        return S3Presigner.builder()
                .region(Region.of(region))
                .credentialsProvider(DefaultCredentialsProvider.create())
                .build();
    }
}
```

### 8.4 S3 Service

```java
package com.myapp.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.ResponseInputStream;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.*;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PresignedGetObjectRequest;

import java.io.IOException;
import java.time.Duration;
import java.util.UUID;

@Service
public class S3Service {

    private final S3Client s3Client;
    private final S3Presigner s3Presigner;

    @Value("${app.s3.bucket-name}")
    private String bucketName;

    @Value("${app.s3.presigned-url-expiry-minutes}")
    private long presignedUrlExpiryMinutes;

    public S3Service(S3Client s3Client, S3Presigner s3Presigner) {
        this.s3Client = s3Client;
        this.s3Presigner = s3Presigner;
    }

    // Upload a file — returns the S3 key
    public String uploadFile(MultipartFile file, String folder) throws IOException {
        String key = folder + "/" + UUID.randomUUID() + "_" + file.getOriginalFilename();

        PutObjectRequest request = PutObjectRequest.builder()
                .bucket(bucketName)
                .key(key)
                .contentType(file.getContentType())
                .contentLength(file.getSize())
                // Optional: set storage class
                .storageClass(StorageClass.STANDARD)
                .build();

        s3Client.putObject(request, RequestBody.fromBytes(file.getBytes()));
        return key;
    }

    // Download a file — returns raw bytes
    public byte[] downloadFile(String key) throws IOException {
        GetObjectRequest request = GetObjectRequest.builder()
                .bucket(bucketName)
                .key(key)
                .build();

        try (ResponseInputStream<GetObjectResponse> response = s3Client.getObject(request)) {
            return response.readAllBytes();
        }
    }

    // Generate a pre-signed URL (temporary access link)
    public String generatePresignedUrl(String key) {
        GetObjectRequest getObjectRequest = GetObjectRequest.builder()
                .bucket(bucketName)
                .key(key)
                .build();

        GetObjectPresignRequest presignRequest = GetObjectPresignRequest.builder()
                .signatureDuration(Duration.ofMinutes(presignedUrlExpiryMinutes))
                .getObjectRequest(getObjectRequest)
                .build();

        PresignedGetObjectRequest presignedRequest = s3Presigner.presignGetObject(presignRequest);
        return presignedRequest.url().toString();
    }

    // Delete a file
    public void deleteFile(String key) {
        DeleteObjectRequest request = DeleteObjectRequest.builder()
                .bucket(bucketName)
                .key(key)
                .build();

        s3Client.deleteObject(request);
    }

    // List files in a folder
    public ListObjectsV2Response listFiles(String prefix) {
        ListObjectsV2Request request = ListObjectsV2Request.builder()
                .bucket(bucketName)
                .prefix(prefix)
                .build();

        return s3Client.listObjectsV2(request);
    }
}
```

### 8.5 REST Controller

```java
package com.myapp.controller;

import com.myapp.service.S3Service;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Map;

@RestController
@RequestMapping("/api/files")
@CrossOrigin(origins = "*")   // restrict in production to your Angular app's domain
public class FileController {

    private final S3Service s3Service;

    public FileController(S3Service s3Service) {
        this.s3Service = s3Service;
    }

    // Upload file — called from Angular with multipart/form-data
    @PostMapping("/upload")
    public ResponseEntity<Map<String, String>> uploadFile(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "folder", defaultValue = "uploads") String folder) {
        try {
            String key = s3Service.uploadFile(file, folder);
            String presignedUrl = s3Service.generatePresignedUrl(key);

            return ResponseEntity.ok(Map.of(
                "key", key,
                "url", presignedUrl,
                "message", "File uploaded successfully"
            ));
        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Upload failed: " + e.getMessage()));
        }
    }

    // Generate pre-signed URL for a file (so Angular can display/download it)
    @GetMapping("/presigned-url")
    public ResponseEntity<Map<String, String>> getPresignedUrl(@RequestParam String key) {
        String url = s3Service.generatePresignedUrl(key);
        return ResponseEntity.ok(Map.of("url", url));
    }

    // Download file directly through backend
    @GetMapping("/download/{key}")
    public ResponseEntity<byte[]> downloadFile(@PathVariable String key) {
        try {
            byte[] content = s3Service.downloadFile(key);
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + key + "\"")
                    .contentType(MediaType.APPLICATION_OCTET_STREAM)
                    .body(content);
        } catch (IOException e) {
            return ResponseEntity.notFound().build();
        }
    }

    // Delete file
    @DeleteMapping("/delete")
    public ResponseEntity<Map<String, String>> deleteFile(@RequestParam String key) {
        s3Service.deleteFile(key);
        return ResponseEntity.ok(Map.of("message", "File deleted: " + key));
    }
}
```

---

## 9. ANGULAR 15 + S3 CODE EXAMPLES

### 9.1 Angular Service — File Upload

```typescript
// src/app/services/file-upload.service.ts
import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders, HttpEventType, HttpRequest } from '@angular/common/http';
import { Observable, map, filter } from 'rxjs';
import { environment } from '../../environments/environment';

export interface UploadResponse {
  key: string;
  url: string;
  message: string;
}

@Injectable({
  providedIn: 'root'
})
export class FileUploadService {

  private apiBaseUrl = environment.apiBaseUrl;  // e.g., 'https://api.myapp.com'

  constructor(private http: HttpClient) {}

  // Upload file to backend (backend handles S3)
  uploadFile(file: File, folder: string = 'uploads'): Observable<UploadResponse> {
    const formData = new FormData();
    formData.append('file', file, file.name);
    formData.append('folder', folder);

    return this.http.post<UploadResponse>(
      `${this.apiBaseUrl}/api/files/upload`,
      formData
    );
  }

  // Upload with progress tracking
  uploadFileWithProgress(file: File, folder: string = 'uploads'): Observable<number | UploadResponse> {
    const formData = new FormData();
    formData.append('file', file, file.name);
    formData.append('folder', folder);

    const req = new HttpRequest('POST', `${this.apiBaseUrl}/api/files/upload`, formData, {
      reportProgress: true
    });

    return this.http.request(req).pipe(
      map(event => {
        if (event.type === HttpEventType.UploadProgress && event.total) {
          return Math.round(100 * event.loaded / event.total);  // percent
        }
        if (event.type === HttpEventType.Response) {
          return event.body as UploadResponse;
        }
        return 0;
      }),
      filter(result => result !== null)
    );
  }

  // Get pre-signed URL from backend for viewing/downloading
  getPresignedUrl(key: string): Observable<{ url: string }> {
    return this.http.get<{ url: string }>(
      `${this.apiBaseUrl}/api/files/presigned-url`,
      { params: { key } }
    );
  }

  // Delete file via backend
  deleteFile(key: string): Observable<{ message: string }> {
    return this.http.delete<{ message: string }>(
      `${this.apiBaseUrl}/api/files/delete`,
      { params: { key } }
    );
  }
}
```

### 9.2 Angular Component — File Upload with Progress

```typescript
// src/app/components/file-upload/file-upload.component.ts
import { Component } from '@angular/core';
import { FileUploadService, UploadResponse } from '../../services/file-upload.service';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-file-upload',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="upload-container">
      <h2>Upload File to S3</h2>

      <input
        type="file"
        #fileInput
        (change)="onFileSelected($event)"
        accept="image/*,application/pdf"
        style="display: none"
      />

      <button (click)="fileInput.click()" [disabled]="uploading">
        Select File
      </button>

      <div *ngIf="selectedFile" class="file-info">
        <p>Selected: {{ selectedFile.name }} ({{ formatSize(selectedFile.size) }})</p>
        <button (click)="upload()" [disabled]="uploading">
          {{ uploading ? 'Uploading...' : 'Upload to S3' }}
        </button>
      </div>

      <div *ngIf="uploadProgress > 0 && uploadProgress < 100" class="progress">
        <div class="progress-bar" [style.width.%]="uploadProgress">
          {{ uploadProgress }}%
        </div>
      </div>

      <div *ngIf="uploadedUrl" class="result">
        <p>Upload successful!</p>
        <a [href]="uploadedUrl" target="_blank">View / Download File</a>
        <p class="key">S3 Key: {{ uploadedKey }}</p>
      </div>

      <div *ngIf="errorMessage" class="error">
        {{ errorMessage }}
      </div>
    </div>
  `,
  styles: [`
    .upload-container { padding: 20px; max-width: 600px; }
    .progress { background: #eee; border-radius: 4px; margin: 10px 0; }
    .progress-bar { background: #007bff; color: white; padding: 5px; border-radius: 4px; transition: width 0.3s; }
    .error { color: red; margin-top: 10px; }
    .result { color: green; margin-top: 10px; }
    .key { font-size: 12px; color: #666; }
  `]
})
export class FileUploadComponent {
  selectedFile: File | null = null;
  uploading = false;
  uploadProgress = 0;
  uploadedUrl = '';
  uploadedKey = '';
  errorMessage = '';

  constructor(private fileUploadService: FileUploadService) {}

  onFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files.length > 0) {
      this.selectedFile = input.files[0];
      this.uploadedUrl = '';
      this.errorMessage = '';
      this.uploadProgress = 0;
    }
  }

  upload(): void {
    if (!this.selectedFile) return;

    this.uploading = true;
    this.errorMessage = '';

    this.fileUploadService.uploadFileWithProgress(this.selectedFile, 'user-docs').subscribe({
      next: (result) => {
        if (typeof result === 'number') {
          this.uploadProgress = result;
        } else {
          // Upload complete — result is UploadResponse
          this.uploadedUrl = result.url;
          this.uploadedKey = result.key;
          this.uploading = false;
          this.uploadProgress = 100;
        }
      },
      error: (err) => {
        this.errorMessage = 'Upload failed. Please try again.';
        this.uploading = false;
        console.error('Upload error:', err);
      }
    });
  }

  formatSize(bytes: number): string {
    if (bytes < 1024) return bytes + ' B';
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
    return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
  }
}
```

### 9.3 Environment Configuration

```typescript
// src/environments/environment.ts (development)
export const environment = {
  production: false,
  apiBaseUrl: 'http://localhost:8080'
};

// src/environments/environment.prod.ts (production)
export const environment = {
  production: true,
  apiBaseUrl: 'https://api.myapp.com'    // your ALB or API Gateway URL
};
```

### 9.4 HTTP Interceptor (add Auth token to all requests)

```typescript
// src/app/interceptors/auth.interceptor.ts
import { Injectable } from '@angular/core';
import { HttpInterceptor, HttpRequest, HttpHandler, HttpEvent } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable()
export class AuthInterceptor implements HttpInterceptor {

  intercept(req: HttpRequest<unknown>, next: HttpHandler): Observable<HttpEvent<unknown>> {
    const token = localStorage.getItem('authToken');

    if (token) {
      const authReq = req.clone({
        headers: req.headers.set('Authorization', `Bearer ${token}`)
      });
      return next.handle(authReq);
    }

    return next.handle(req);
  }
}
```

---

## 10. SCENARIO-BASED QUESTIONS & ANSWERS

---

### Q1. How would you design the infrastructure for a Java Spring Boot + Angular app that needs to be highly available and secure?

**Answer:**
```
Architecture:
  Route 53 (DNS)
      │
      ▼
  CloudFront (CDN — caches Angular static files globally)
      ├─ /api/* → ALB (internal)
      └─ /* → S3 (Angular build files: index.html, main.js, etc.)
      
  ALB (Application Load Balancer — public subnet)
      ├─ /api/orders/* → order-service ECS/EKS (private subnet)
      └─ /api/customers/* → customer-service ECS/EKS (private subnet)
      
  RDS PostgreSQL (private subnet — Multi-AZ for HA)
  
Security:
  - ALB: alb-sg allows port 80/443 from internet
  - App: app-sg allows port 8080 ONLY from alb-sg
  - DB: db-sg allows port 5432 ONLY from app-sg
  - Private subnets for all apps and DBs
  - NAT Gateway for outbound internet from private subnets
  - Secrets Manager for DB credentials (no hardcoding)
```

---

### Q2. Your Java app running on EC2 needs to read files from S3. What is the right way to give it access? 

**Answer:**
- **WRONG:** Hardcode AWS access keys in application.properties or environment variables on EC2
- **RIGHT:** Create an IAM Role with S3 read permission policy attached to EC2 instance

```
IAM Role: "ec2-s3-read-role"
  └─ Policy: AmazonS3ReadOnlyAccess (or custom least-privilege policy)

EC2 Instance → Actions → Security → Modify IAM Role → attach "ec2-s3-read-role"
```

In your Java code, `DefaultCredentialsProvider.create()` automatically uses the IAM Role — no credentials in code at all. This is the security best practice.

---

### Q3. What EC2 instance type would you choose for each scenario?

**Scenario A:** Spring Boot REST API serving 1,000 concurrent users  
→ **m5.large or m5.xlarge** (General Purpose — balanced CPU/RAM, 2-4 vCPU, 8-16GB RAM)

**Scenario B:** Machine learning model inference  
→ **p3.2xlarge or g4dn.xlarge** (GPU Accelerated)

**Scenario C:** Redis caching layer with 100GB of in-memory data  
→ **r5.4xlarge** (Memory Optimized — up to 128GB RAM)

**Scenario D:** Batch data processing job that runs at 3am daily  
→ **Spot instance** (c5.xlarge Compute Optimized — saves up to 90%, OK if interrupted since it's batch)

**Scenario E:** Compliance requirement — must run on dedicated physical hardware  
→ **Dedicated Host** (your own physical server, no sharing with other AWS customers)

---

### Q4. When do you use S3 Intelligent-Tiering vs picking a storage class manually?

**Answer:**
- Use **Intelligent-Tiering** when you don't know the access pattern of your data
- AWS monitors access and automatically moves objects between Frequent Access and Infrequent Access tiers
- Small monitoring fee per object ($0.0025 per 1,000 objects)
- Use **manual storage class** when you know the pattern:
  - User profile photos → Standard (accessed all the time)
  - Last year's audit logs → Glacier Flexible Retrieval (never accessed)

---

### Q5. What is the difference between Security Group and NACL? When would you use NACL?

**Answer:**
- Security Group: stateful, allow-only, attached to resources (EC2, RDS)
- NACL: stateless, allow + deny, attached to subnets
- Use NACL when you need to **block a specific IP address** — you can't do this with Security Groups
- Example: You detect an attacker from IP 1.2.3.4 — add a NACL DENY rule on the subnet to block all traffic from that IP, even before it reaches your EC2's security group

---

### Q6. Your Spring Boot app in a private subnet needs to download a Maven dependency from the internet during startup. Will it work?

**Answer:**
Not directly. Private subnets have no internet access. You need a **NAT Gateway** in the public subnet with a route table entry `0.0.0.0/0 → NAT Gateway` on the private subnet's route table. Then the EC2 can make outbound requests to the internet, but the internet cannot initiate connections back to the EC2.

---

### Q7. How would you set up CI/CD for a Spring Boot + Angular app on AWS using Jenkins?

**Answer:**
```
Infrastructure Setup:
  - Jenkins EC2 in public/private subnet (t3.medium)
  - Jenkins EC2 has IAM Role with ECR + EKS permissions
  - GitHub repo configured with webhook to Jenkins

Pipeline Flow:
  1. Developer pushes to GitHub main branch
  2. GitHub sends webhook to Jenkins
  3. Jenkins pipeline:
     a. git checkout
     b. mvn clean package (build + test)
     c. docker build --platform=linux/amd64
     d. docker push to ECR
     e. kubectl set image deployment/... → rolling update in EKS
     f. kubectl rollout status → wait for completion
     g. smoke test (curl /actuator/health)
  4. On failure: kubectl rollout undo → automatic rollback
  5. Notify team via Slack/email

For Angular:
  a. npm ci
  b. ng build --configuration=production
  c. aws s3 sync dist/my-app/ s3://my-frontend-bucket/ --delete
  d. aws cloudfront create-invalidation --paths "/*"  → clear CDN cache
```

---

### Q8. What is the difference between ECS (with Fargate) and EKS?

| Aspect | ECS + Fargate | EKS |
|--------|---------------|-----|
| Complexity | Simple, AWS-native | Complex, Kubernetes standard |
| Learning curve | Low | High |
| Portability | AWS-only (ECS is proprietary) | Kubernetes runs anywhere |
| Control | Less control over infrastructure | Full control |
| Pricing | Pay for Fargate compute | Pay for control plane + EC2/Fargate |
| Best for | Simple microservices, team new to containers | Large orgs already using K8s, multi-cloud plans |

**Interview answer:** "For most Java teams starting with containerization, ECS + Fargate is simpler and faster to set up. For organizations that need Kubernetes compatibility, multi-cloud portability, or already have K8s expertise, EKS is better."

---

### Q9. How does Lambda differ from EC2 for a Java developer?

**Answer:**
- **EC2:** Always-running server. You pay 24/7 even if no users. You manage OS, patches, scaling.
- **Lambda:** No server. Code runs only when triggered (API call, S3 upload, schedule). Pay only for actual execution time (per millisecond).

**When Lambda works for Java:**
- Short-lived operations (under 15 minutes)
- Event-driven tasks (file processing, notifications)
- Low/variable traffic

**When Lambda is not ideal for Java:**
- Cold start: JVM warm-up can take 1-3 seconds on first invocation. For latency-sensitive APIs, use Provisioned Concurrency or use GraalVM native image with Spring Boot 3
- Long-running processes
- Large Spring Boot apps (heavy cold starts)

---

### Q10. An S3 bucket is storing user-uploaded documents. Users should only be able to download their own documents. How do you implement this?

**Answer:**
Never make S3 bucket public. Use **Pre-signed URLs**:

```
Flow:
1. User uploads → Angular calls Spring Boot API → Spring Boot uploads to S3 with key "users/{userId}/{filename}"
2. Key is saved to DB linked to userId
3. User wants to view file → Angular calls GET /api/files/presigned-url?key=users/123/doc.pdf
4. Spring Boot validates that userId 123 matches the authenticated user
5. Spring Boot generates a pre-signed URL valid for 60 minutes
6. Returns URL to Angular
7. Angular opens the URL directly — user downloads their file
8. URL expires after 60 minutes automatically

S3 bucket remains PRIVATE the entire time. No public access.
```

---

### Q11. What is the purpose of VPC endpoints and when would you use them instead of NAT Gateway?

**Answer:**
- **NAT Gateway:** Routes all outbound traffic through the internet. Used for downloading packages from the internet, calling external APIs, etc.
- **VPC Endpoint:** A private connection from your VPC to AWS services WITHOUT going through the internet. Traffic stays on the AWS network.

**Example:** Your EC2 in a private subnet writes to S3. Without VPC endpoint, traffic goes: EC2 → NAT Gateway → Internet → S3. With **S3 VPC Gateway Endpoint**, traffic goes: EC2 → AWS private network → S3. It is free and faster.

For beginners: Start with NAT Gateway (simpler). Add VPC Endpoints for S3 and DynamoDB when you want to avoid internet routing for those services.

---

### Q12. How do Rolling and Blue-Green deployments differ in Jenkins/CI-CD context?

**Answer:**

**Rolling Update:**
- Jenkins updates Kubernetes deployment → K8s replaces pods gradually
- `kubectl set image deployment/my-app my-app=new-image:v2`
- K8s terminates one old pod → starts one new pod → repeats
- If new pod fails health check, rollout stops and old pods serve traffic
- Zero downtime but both versions run briefly simultaneously

**Blue-Green:**
- Jenkins deploys new version (Green) as a separate deployment
- Run automated tests against Green
- Jenkins switches ALB listener rules to route traffic from Blue to Green
- Instant cutover — no mixed versions serving traffic
- Rollback = switch ALB back to Blue (instant)

**In Jenkins:**
```groovy
// Blue-Green switch using AWS CLI
sh """
    # Deploy Green (new version)
    kubectl apply -f k8s/green-deployment.yaml
    kubectl rollout status deployment/app-green
    
    // Test Green
    curl -f http://green-service/actuator/health
    
    // Switch ALB target group from Blue to Green
    aws elbv2 modify-listener --listener-arn $ALB_LISTENER_ARN \
        --default-actions Type=forward,TargetGroupArn=$GREEN_TG_ARN
"""
```

---

### Q13. How would you debug a production issue in your Spring Boot app running on EKS?

**Answer:**
```
Step 1: Check pod status
  kubectl get pods -n production
  kubectl describe pod order-service-xyz -n production
  → Look for: CrashLoopBackOff, OOMKilled, ImagePullBackOff

Step 2: Check logs
  kubectl logs order-service-xyz -n production --tail=500
  kubectl logs order-service-xyz -n production --previous  ← logs from crashed pod

Step 3: If app is running but misbehaving
  → Check CloudWatch Logs (Fluent Bit ships logs there)
  → Search by correlation ID or userId using CloudWatch Logs Insights:
    fields @timestamp, @message
    | filter @message like /userId=982/
    | sort @timestamp desc

Step 4: Exec into pod for live debugging
  kubectl exec -it order-service-xyz -n production -- sh
  → curl localhost:8080/actuator/health
  → Check environment variables, DB connectivity

Step 5: Check resource limits
  kubectl top pods -n production  ← CPU/Memory usage
  → If OOMKilled: increase memory limits in deployment.yaml
```

---

### Q14. What is the IAM Role chain for a typical microservice architecture?

```
Scenario: customer-service (EKS pod) needs to:
  1. Read from S3 (user documents)
  2. Read DB credentials from Secrets Manager
  3. Publish events to SNS

Solution:
  IAM Role: "customer-service-task-role"
    ├─ Policy: custom-s3-read (only the user-docs bucket)
    ├─ Policy: SecretsManagerReadWrite (only /prod/myapp/db/* secrets)
    └─ Policy: SNS:Publish (only the customer-events topic)

  This role is attached to the Kubernetes ServiceAccount via IRSA
  (IAM Roles for Service Accounts) — each pod in K8s can have
  its own IAM role, so customer-service gets only what it needs
  and nothing more. (Least Privilege Principle)
```

---

### Q15. What happens when you do `git push` to main in a Jenkins CI/CD setup? Walk through end-to-end.

**Answer:**
```
1. Developer runs: git push origin main

2. GitHub receives the push and sends HTTP POST webhook to:
   http://<jenkins-ip>:8080/github-webhook/

3. Jenkins receives webhook and triggers the pipeline defined in Jenkinsfile:

   Stage 1 - Checkout:
     Jenkins agent clones the repository

   Stage 2 - Build & Test:
     mvn clean package  ← compiles code, runs unit tests, integration tests
     If tests fail: pipeline stops, sends failure notification

   Stage 3 - Docker Build:
     docker build --platform=linux/amd64 -t order-service:${BUILD_NUMBER} .

   Stage 4 - Push to ECR:
     aws ecr get-login-password | docker login ...
     docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/order-service:42

   Stage 5 - Deploy to EKS:
     aws eks update-kubeconfig --name prod-cluster
     kubectl set image deployment/order-service order-service=.../order-service:42
     kubectl rollout status deployment/order-service --timeout=300s
     ← K8s does rolling update: one pod at a time, health checks must pass

   Stage 6 - Smoke Test:
     curl -f http://<alb-dns>/actuator/health
     ← If this fails, kubectl rollout undo is called automatically

4. On success: Slack notification "Build #42 deployed to production"
5. On failure: Slack notification + automatic rollback
```

---

*This guide covers what you need as a Java fullstack developer for AWS interviews. Focus especially on the Architecture section (IAM, VPC, Security Groups) and then EC2, S3, and CI/CD with Jenkins — these come up in almost every interview. The scenario questions at the end represent how real interviews are structured.*
