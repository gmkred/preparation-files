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

## 7. CI/CD WITH JENKINS ON AWS

> CI/CD automates the path from "developer pushes code" to "code is live in production." Jenkins is the most popular open-source automation server for this.

```
Developer pushes code to GitHub
         │
         ▼
Jenkins detects change (via webhook)
         │
         ├─ Stage 1: CHECKOUT          — pull latest code
         ├─ Stage 2: BUILD & TEST       — mvn clean package, unit + integration tests
         ├─ Stage 3: SAST               — SonarQube scans SOURCE CODE for vulnerabilities  ◀── security
         ├─ Stage 4: DOCKER BUILD       — build Docker image
         ├─ Stage 5: PUSH TO ECR        — push image to AWS ECR
         ├─ Stage 6: DEPLOY TO STAGING  — deploy to staging/test environment
         ├─ Stage 7: DAST               — OWASP ZAP attacks the RUNNING staging app        ◀── security
         ├─ Stage 8: DEPLOY TO PROD     — rolling update in EKS production
         └─ Stage 9: NOTIFY             — Slack/email on success or failure

  SAST  = scans the CODE (app does NOT need to be running)
  DAST  = attacks the LIVE app (app MUST be deployed to staging first)
```

---

### 7.1 Setting Up Jenkins on EC2

**Typical Setup:**
- Launch an EC2 instance (t3.medium or t3.large)
- Install Jenkins, Java, Maven, Docker
- Attach an IAM Role to EC2 with ECR + EKS permissions

```bash
# Install Jenkins on Amazon Linux 2
sudo yum update -y
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum install -y java-17-amazon-corretto jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Install Docker on Jenkins server
sudo yum install -y docker
sudo systemctl start docker
sudo usermod -aG docker jenkins  # give Jenkins permission to run docker
sudo systemctl restart jenkins
```

### 7.2 Jenkins Pipeline — Jenkinsfile

The **Jenkinsfile** is stored in your repository root and defines the entire CI/CD pipeline as code.

**Complete Spring Boot + ECR + EKS Jenkinsfile:**
```groovy
pipeline {
    agent any

    environment {
        AWS_REGION          = 'us-east-1'
        ECR_REGISTRY        = '123456789.dkr.ecr.us-east-1.amazonaws.com'
        IMAGE_NAME          = 'order-service'
        EKS_CLUSTER_NAME    = 'prod-cluster'
        KUBECONFIG_PATH     = '/var/lib/jenkins/.kube/config'
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/myorg/order-service.git',
                    credentialsId: 'github-credentials'
            }
        }

        stage('Build & Test') {
            steps {
                sh 'mvn clean package -DskipTests=false'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'  // publish test results
                }
            }
        }

        // ── SAST: runs immediately after build, before Docker image is created ──
        stage('SAST - SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube-Server') {  // 'SonarQube-Server' = name configured in Jenkins
                    sh """
                        mvn sonar:sonar \
                            -Dsonar.projectKey=order-service \
                            -Dsonar.projectName='Order Service' \
                            -Dsonar.java.coveragePlugin=jacoco \
                            -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
                    """
                }
            }
        }

        stage('SAST - Quality Gate') {
            steps {
                // Wait for SonarQube to finish analysing and return pass/fail
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                    // abortPipeline: true  → pipeline FAILS if quality gate not met
                    // Quality gate checks: code coverage < 80%, critical bugs > 0, vulnerabilities > 0
                }
            }
        }

        stage('Docker Build') {
            steps {
                sh """
                    docker build \
                        --platform=linux/amd64 \
                        -t ${IMAGE_NAME}:${BUILD_NUMBER} \
                        -t ${IMAGE_NAME}:latest \
                        .
                """
            }
        }

        stage('Push to ECR') {
            steps {
                sh """
                    aws ecr get-login-password --region ${AWS_REGION} | \
                    docker login --username AWS --password-stdin ${ECR_REGISTRY}

                    docker tag ${IMAGE_NAME}:${BUILD_NUMBER} \
                        ${ECR_REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}

                    docker tag ${IMAGE_NAME}:latest \
                        ${ECR_REGISTRY}/${IMAGE_NAME}:latest

                    docker push ${ECR_REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}
                    docker push ${ECR_REGISTRY}/${IMAGE_NAME}:latest
                """
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh """
                    aws eks update-kubeconfig \
                        --region ${AWS_REGION} \
                        --name ${EKS_CLUSTER_NAME}

                    # Update image in deployment
                    kubectl set image deployment/order-service-deployment \
                        order-service=${ECR_REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER} \
                        --record

                    # Wait for rollout to complete
                    kubectl rollout status deployment/order-service-deployment \
                        --timeout=300s
                """
            }
        }

        stage('Smoke Test - Staging') {
            steps {
                sh """
                    # Get staging ALB DNS
                    ALB_DNS=\$(kubectl get service order-service -n staging -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
                    sleep 30
                    curl -f http://\${ALB_DNS}/actuator/health || exit 1
                    echo "Smoke test PASSED"
                    # Export for DAST stage
                    echo \${ALB_DNS} > /tmp/staging_url.txt
                """
            }
        }

        // ── DAST: runs AFTER staging deployment, attacks the live app ──
        stage('DAST - OWASP ZAP Scan') {
            steps {
                sh """
                    STAGING_URL=http://\$(cat /tmp/staging_url.txt)

                    # Pull OWASP ZAP Docker image and run a baseline scan against staging
                    docker run --rm \
                        -v \$(pwd)/zap-reports:/zap/wrk/:rw \
                        ghcr.io/zaproxy/zaproxy:stable \
                        zap-baseline.py \
                            -t \${STAGING_URL} \
                            -r zap-report.html \
                            -J zap-report.json \
                            -I \
                            -l WARN
                    # -t  = target URL (the running staging app)
                    # -r  = HTML report output
                    # -J  = JSON report output
                    # -I  = do not fail on warnings, only fail on FAIL-level findings
                    # -l WARN = log WARNING and above findings
                """
            }
            post {
                always {
                    // Publish ZAP HTML report in Jenkins as an artifact
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'zap-reports',
                        reportFiles: 'zap-report.html',
                        reportName: 'OWASP ZAP Security Report'
                    ])
                }
                failure {
                    error "DAST scan found HIGH/CRITICAL vulnerabilities. Blocking deployment to production."
                }
            }
        }

        // ── Only reaches production if BOTH SAST and DAST passed ──
        stage('Deploy to Production') {
            steps {
                sh """
                    aws eks update-kubeconfig \
                        --region ${AWS_REGION} \
                        --name ${EKS_CLUSTER_NAME}

                    kubectl set image deployment/order-service-deployment \
                        order-service=${ECR_REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER} \
                        -n production \
                        --record

                    kubectl rollout status deployment/order-service-deployment \
                        -n production \
                        --timeout=300s
                """
            }
        }
    }

    post {
        success {
            echo "Deployment successful! Build #${BUILD_NUMBER}"
            // slackSend channel: '#deploys', message: "SUCCESS: order-service #${BUILD_NUMBER}"
        }
        failure {
            echo "Deployment FAILED! Check logs."
            // slackSend channel: '#deploys', message: "FAILED: order-service #${BUILD_NUMBER}"
            sh "kubectl rollout undo deployment/order-service-deployment -n production || true"
        }
        always {
            sh "docker rmi ${IMAGE_NAME}:${BUILD_NUMBER} || true"
            sh "docker rmi ${ECR_REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER} || true"
        }
    }
}
```

---

### 7.3 Jenkins + GitHub Webhook

1. In GitHub repo → Settings → Webhooks → Add webhook
2. Payload URL: `http://<jenkins-ec2-public-ip>:8080/github-webhook/`
3. Content type: `application/json`
4. Trigger on: Push events

Now every `git push` to `main` automatically triggers the Jenkins pipeline.

---

### 7.4 IAM Role for Jenkins EC2

Jenkins EC2 needs permissions to:
- Push/pull images to/from ECR
- Update EKS deployments

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster"
      ],
      "Resource": "*"
    }
  ]
}
```

---

### 7.5 Blue-Green vs Rolling Deployment

**Rolling Update (default in Kubernetes):**
- Old pods are replaced one at a time with new pods
- Zero downtime (if health checks pass)
- If new pods fail health checks, rollout stops and old pods keep running
- Rollback: `kubectl rollout undo deployment/order-service-deployment`

```
Before: [v1] [v1] [v1] [v1]
Step 1: [v2] [v1] [v1] [v1]
Step 2: [v2] [v2] [v1] [v1]
Step 3: [v2] [v2] [v2] [v1]
After:  [v2] [v2] [v2] [v2]
```

**Blue-Green Deployment:**
- Run two full environments: Blue (current production) and Green (new version)
- Switch traffic from Blue → Green in one cut (via ALB listener rules)
- Rollback is instant — just switch back to Blue
- More expensive (double infrastructure running temporarily)

```
ALB → Blue (v1) [100% traffic]

Deploy Green (v2), run tests → Green passes

ALB → Green (v2) [100% traffic]   ← switch happens here (instant)
Blue (v1) → standby (or terminate after confidence period)
```

---

### 7.6 SAST & DAST — Security Testing in CI/CD

> As a Java developer you write code and deploy it. But code can have security holes even if it compiles and tests pass. SAST and DAST are two automated security checks that catch different kinds of vulnerabilities — and they plug into your Jenkins pipeline at different stages.

---

#### What is SAST? (Static Application Security Testing)

**Analogy:** A proofreader reads your manuscript looking for grammatical mistakes *before* the book is printed. The book never needs to exist for the proofreader to find problems.

- SAST **reads your source code** without running it
- Finds security issues in the code itself: hardcoded passwords, SQL injection patterns, null pointer risks, insecure API usage
- **Runs early** in the pipeline — right after `mvn clean package`, before Docker is built
- The app does **NOT** need to be deployed or even runnable
- Fast feedback: developer finds out about the problem within minutes of pushing code

**Tool: SonarQube**
- Most popular SAST tool for Java
- Runs as a server (you deploy it on an EC2 instance)
- Jenkins sends the compiled code + test coverage to SonarQube for analysis
- SonarQube checks against rules like OWASP Top 10, CWE, CERT
- Returns a **Quality Gate** result (PASSED/FAILED) back to Jenkins

**What SonarQube catches in Java:**
```
- SQL Injection:   String query = "SELECT * FROM users WHERE id=" + userId;
                   → FLAGGED: user input concatenated into SQL string

- Hardcoded cred:  String password = "admin123";
                   → FLAGGED: sensitive data in source code

- XSS risk:        response.getWriter().print(request.getParameter("name"));
                   → FLAGGED: unescaped user input written to response

- Null deref:      User user = repo.findById(id);
                   user.getName();   // no null check
                   → FLAGGED: possible NullPointerException

- Weak crypto:     MessageDigest.getInstance("MD5")
                   → FLAGGED: MD5 is broken, use SHA-256 or bcrypt

- Code coverage:   If tests cover less than 80% of code → Quality Gate FAILS
```

**SonarQube Setup in Jenkins:**

Step 1 — Install SonarQube on EC2:
```bash
# SonarQube runs as a standalone server (needs Java 17, ~4GB RAM)
# Run as Docker container on a t3.large EC2:
docker run -d \
  --name sonarqube \
  -p 9000:9000 \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  sonarqube:community

# Access at http://<ec2-ip>:9000
# Default login: admin / admin (change immediately)
```

Step 2 — Generate a SonarQube token (in SonarQube UI):
```
My Account → Security → Generate Token → copy the token
```

Step 3 — Add token to Jenkins:
```
Jenkins → Manage Jenkins → Credentials → Add Secret Text
  ID: sonarqube-token
  Secret: <paste token here>
```

Step 4 — Configure SonarQube server in Jenkins:
```
Jenkins → Manage Jenkins → Configure System → SonarQube servers
  Name: SonarQube-Server      ← this name is used in withSonarQubeEnv()
  Server URL: http://<sonarqube-ec2-ip>:9000
  Server authentication token: sonarqube-token
```

Step 5 — Add sonar plugin to pom.xml:
```xml
<plugin>
    <groupId>org.sonarsource.scanner.maven</groupId>
    <artifactId>sonar-maven-plugin</artifactId>
    <version>3.10.0.2594</version>
</plugin>
```

**SonarQube Quality Gate — what it checks:**
```
Quality Gate "Sonar Way" (default):
  ✅ New Code coverage >= 80%
  ✅ New Bugs = 0
  ✅ New Vulnerabilities = 0
  ✅ New Security Hotspots reviewed = 100%
  ✅ New Code smells (duplications, complexity) within threshold

If ANY condition fails → Quality Gate = FAILED → Jenkins pipeline aborts
The developer must fix the issue and push again before the pipeline proceeds.
```

---

#### What is DAST? (Dynamic Application Security Testing)

**Analogy:** A quality tester actually drives the car on a test track and deliberately tries to crash it, brake hard, go in reverse, test every edge — while the car is running. They find problems that nobody noticed by just reading the blueprint.

- DAST **attacks a running application** with real HTTP requests — like an ethical hacker
- Finds vulnerabilities that only appear at runtime: broken authentication, XSS, SQL injection in practice, exposed endpoints, misconfigured HTTP headers, open redirects
- **Runs after staging deployment** — the app must be live and reachable
- Slower than SAST (minutes to an hour depending on scan depth)

**Tool: OWASP ZAP (Zed Attack Proxy)**
- Free, open-source tool from OWASP (Open Web Application Security Project)
- Industry standard for web application security testing
- Can run as a Docker container — no installation needed on Jenkins
- Multiple scan modes: Baseline (fast, passive), Full Scan (deep, active attacks)

---

#### DAST — How OWASP ZAP Works Step by Step

**Scenario:** Your order-service is deployed to staging at `http://staging.myapp.com`. ZAP is about to test it.

```
STAGE: DAST - OWASP ZAP Scan
        │
        ▼
Step 1: SPIDER — ZAP crawls the app
        ZAP sends GET http://staging.myapp.com
        Discovers links, forms, API endpoints from responses
        Found endpoints:
          GET  /api/orders
          GET  /api/orders/{id}
          POST /api/orders
          GET  /api/orders/search?query=...
          POST /api/users/login
          ...

        ▼
Step 2: PASSIVE SCAN — ZAP observes all responses (no attacks yet)
        Checks HTTP response headers for missing security headers
        Flags:
          ❌ Missing: X-Content-Type-Options header
          ❌ Missing: X-Frame-Options header (clickjacking risk)
          ❌ Missing: Content-Security-Policy header
          ❌ Server header reveals: "Apache Tomcat/9.0.65" (version disclosure)

        ▼
Step 3: ACTIVE SCAN — ZAP sends attack payloads (only in Full Scan)
        ZAP modifies requests and injects attack strings:

        Attack A — XSS test on search endpoint:
          Original:  GET /api/orders/search?query=laptop
          ZAP sends: GET /api/orders/search?query=<script>alert(1)</script>
          If response body contains <script>alert(1)</script> unescaped → XSS FOUND

        Attack B — SQL Injection test on login:
          Original:  POST /api/users/login  body: {"username":"john","password":"pass"}
          ZAP sends: POST /api/users/login  body: {"username":"' OR '1'='1","password":"x"}
          If response is 200 OK (logged in!) → SQL INJECTION FOUND

        Attack C — Path traversal test on file download:
          Original:  GET /api/files/download?name=report.pdf
          ZAP sends: GET /api/files/download?name=../../etc/passwd
          If response contains root:x:0:0 → PATH TRAVERSAL FOUND

        Attack D — Broken authentication test:
          ZAP sends requests to /api/admin/users WITHOUT auth token
          If response is 200 OK → BROKEN ACCESS CONTROL FOUND

        ▼
Step 4: REPORT GENERATED
        zap-report.html  (human-readable, colour-coded by severity)
        zap-report.json  (machine-readable, for Jenkins to parse)
        
        Sample report findings:
          CRITICAL: SQL Injection in /api/users/login
          HIGH:     XSS in /api/orders/search
          MEDIUM:   Missing X-Frame-Options header
          LOW:      Server version disclosure in Server header
          INFO:     Cookie without Secure flag

        ▼
Step 5: JENKINS DECISION
        If CRITICAL or HIGH findings exist → pipeline FAILS → production blocked
        If only MEDIUM/LOW/INFO → pipeline PASSES with warning (configurable)
```

---

#### DAST — Complete Jenkins Stage with ZAP

```groovy
stage('DAST - OWASP ZAP Scan') {
    environment {
        // Staging URL where the app was just deployed
        STAGING_URL = "http://${STAGING_ALB_DNS}"
    }
    steps {
        script {
            // Create output directory for ZAP reports
            sh 'mkdir -p zap-reports'

            // Run ZAP baseline scan using Docker — no ZAP installation needed
            // zap-baseline.py = passive scan only (safe, no actual attacks)
            // zap-full-scan.py = active scan with attack payloads (use only on staging/test)
            def zapResult = sh(
                returnStatus: true,
                script: """
                    docker run --rm \
                        --network host \
                        -v \$(pwd)/zap-reports:/zap/wrk/:rw \
                        -u root \
                        ghcr.io/zaproxy/zaproxy:stable \
                        zap-full-scan.py \
                            -t ${STAGING_URL} \
                            -r zap-report.html \
                            -J zap-report.json \
                            -x zap-report.xml \
                            -I \
                            -l WARN \
                            -z "-config scanner.attackStrength=MEDIUM"
                """
                // -t  target URL
                // -r  HTML report
                // -J  JSON report
                // -x  XML report (for Jenkins plugin parsing)
                // -I  ignore warnings (don't fail on WARN, only FAIL level)
                // -l  WARN = log warnings and above
                // -z  ZAP config options: attack strength LOW/MEDIUM/HIGH
            )

            // Parse JSON report to count findings by severity
            def report = readJSON file: 'zap-reports/zap-report.json'
            def alerts = report.site[0].alerts

            def criticalCount = alerts.count { it.riskcode == "3" }  // 3 = High
            def highCount     = alerts.count { it.riskcode == "2" }  // 2 = Medium
            def mediumCount   = alerts.count { it.riskcode == "1" }  // 1 = Low

            echo "ZAP Scan Results:"
            echo "  Critical/High findings : ${criticalCount}"
            echo "  Medium findings        : ${highCount}"
            echo "  Low findings           : ${mediumCount}"

            // Fail pipeline if any Critical or High severity findings
            if (criticalCount > 0 || highCount > 0) {
                error """
                    DAST FAILED: Found ${criticalCount} critical and ${highCount} high severity vulnerabilities.
                    Check the ZAP report for details: zap-reports/zap-report.html
                    Fix these issues before deploying to production!
                """
            }
        }
    }
    post {
        always {
            // Archive the ZAP report so it is visible in Jenkins build page
            publishHTML([
                allowMissing         : false,
                alwaysLinkToLastBuild: true,
                keepAll              : true,
                reportDir            : 'zap-reports',
                reportFiles          : 'zap-report.html',
                reportName           : 'OWASP ZAP Security Report'
            ])
            archiveArtifacts artifacts: 'zap-reports/zap-report.json', allowEmptyArchive: true
        }
    }
}
```

---

#### SAST vs DAST — Side by Side Comparison

| | SAST | DAST |
|---|---|---|
| **Full Name** | Static Application Security Testing | Dynamic Application Security Testing |
| **What it scans** | Source code / bytecode | Running application (HTTP requests) |
| **App needs to run?** | NO | YES (deployed to staging) |
| **When in pipeline** | After build, before Docker | After staging deploy, before prod |
| **Tool used** | SonarQube | OWASP ZAP |
| **Speed** | Fast (1–3 min) | Slower (5–30 min depending on app size) |
| **Finds** | Code-level bugs, hardcoded secrets, bad patterns | Runtime issues: XSS, SQLi, auth bypass, misconfig |
| **Does NOT find** | Runtime misconfigs (e.g., wrong HTTP headers) | Logic bugs deep in code paths |
| **Fixes by** | Developer fixes code and re-pushes | Developer fixes code, redeploys staging, re-runs ZAP |
| **Who blocks deploy?** | Quality Gate threshold | Critical/High severity findings |

---

#### Where They Fit in the Full Pipeline — Visual

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     JENKINS CI/CD PIPELINE                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  [1] Checkout   →  [2] Build & Test  →  [3] SAST (SonarQube)           │
│                                              │                          │
│                                    ┌─────────┴──────────┐              │
│                              Quality Gate PASS?          │              │
│                            YES ↓              NO → ❌ FAIL              │
│                                                                         │
│  [4] Docker Build  →  [5] Push ECR  →  [6] Deploy Staging              │
│                                              │                          │
│                                   [7] DAST (OWASP ZAP)                 │
│                                              │                          │
│                                    ┌─────────┴──────────┐              │
│                               ZAP PASS?                  │              │
│                            YES ↓              NO → ❌ FAIL              │
│                                                                         │
│  [8] Deploy Production  →  [9] Smoke Test  →  [10] Notify              │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘

  Code never reaches production if EITHER security gate fails.
```

---

#### Common Interview Questions on SAST/DAST

**Q: Can SAST replace DAST or vice versa?**  
No. They are complementary. SAST finds problems in how the code is written. DAST finds problems in how the running application behaves. You need both because:
- A developer could write perfectly clean code that is deployed with wrong environment configs (DAST catches this, SAST cannot)
- An app can have SQL injection patterns in dead code paths (SAST catches this, DAST may miss it if ZAP never triggers that path)

**Q: Why do we run DAST only on staging and not production?**  
DAST tools like ZAP send attack payloads (SQL injection strings, XSS scripts, fuzzing). Running this against production would:
- Create garbage data in your production database
- Trigger alerts in your WAF/monitoring
- Potentially crash production endpoints
- Be illegal in some cases if the system is shared/regulated

**Q: What is a "false positive" in SAST?**  
SonarQube flags an issue that is not actually a vulnerability. Example: SonarQube flags a hardcoded string thinking it is a password, but it's actually a non-sensitive constant like `"DEFAULT_ROLE"`. Developers can mark these as "Won't Fix" or "False Positive" in SonarQube to suppress future alerts.

**Q: Can you run ZAP without Docker in Jenkins?**  
Yes — ZAP can be installed on the Jenkins EC2 directly and invoked as a command. But using Docker is preferred because:
- No version management headache
- Always get the latest ZAP
- Clean environment per run (no state from previous scan leaks into next scan)

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
