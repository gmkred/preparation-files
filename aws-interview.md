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
7. [CI/CD with Jenkins on AWS — Microservices](#7-cicd-with-jenkins-on-aws--microservices)
8. [Java Spring Boot + S3 Code Examples](#8-java-spring-boot--s3-code-examples)
9. [Angular 15 + S3 Code Examples](#9-angular-15--s3-code-examples)
10. [Scenario-Based Questions & Answers](#10-scenario-based-questions--answers)
11. [Centralized Logging — Sleuth + Zipkin + CloudWatch](#11-centralized-logging--sleuth--zipkin--cloudwatch)
    - Spring Cloud Sleuth (traceId propagation)
    - Zipkin (distributed trace visualization)
    - CloudWatch Logs Insights (query across all services)
    - Fluent Bit log shipping
12. [Container & Pod Failure Analysis](#12-container--pod-failure-analysis)
    - CrashLoopBackOff, OOMKilled, ImagePullBackOff, Pending
    - Docker exit codes
    - Step-by-step debugging workflow
13. [Essential Developer Commands](#13-essential-developer-commands)
    - kubectl, docker, docker-compose, aws cli
    - Where to execute each command
14. [Docker Compose for Single-Service Development](#14-docker-compose-for-single-service-development)
    - Why you need it even for one service
    - WireMock for stubbing other microservices
    - TestContainers for integration tests
15. [AWS Lambda — Java Implementation & All Trigger Types](#15-aws-lambda--java-implementation--all-trigger-types)
    - All 12 trigger types
    - Java code for API Gateway, S3, SQS, EventBridge
    - Cold start solutions
16. [AWS Fargate — Serverless Containers](#16-aws-fargate--serverless-containers)
    - ECS vs EKS, where Fargate fits
    - Task Definition, Jenkins deployment
17. [How Java Microservices Connect to AWS Services](#17-how-java-microservices-connect-to-aws-services)
    - Why tokens are needed
    - Credentials Provider Chain
    - IRSA (IAM Roles for Service Accounts)
    - Roles & policies per microservice
18. [End-to-End Deployment Flow — DEV and PROD](#18-end-to-end-deployment-flow--dev-and-prod)
    - Full architecture for DEV and PROD environments
    - Step-by-step deployment walk-through
    - Console navigation for every AWS service involved
    - S3, ECR, EKS, RDS, Secrets Manager navigation steps
19. [ALB — Application Load Balancer In Depth](#19-alb--application-load-balancer-in-depth)
    - Creating ALB via console (step by step)
    - Target groups, listener rules, health checks
    - HTTPS with ACM certificates
    - ALB access logs and metrics
20. [CloudWatch — Logs, Alarms and Alerts](#20-cloudwatch--logs-alarms-and-alerts)
    - How to view logs in CloudWatch console (step by step)
    - CloudWatch Logs Insights queries
    - Setting up alarms and thresholds
    - SNS notifications (email/Slack on alarm)
    - CloudWatch Container Insights
    - What to check when production crashes
21. [Monitoring Metrics — Pod, EC2 and Application](#21-monitoring-metrics--pod-ec2-and-application)
    - Critical EC2 metrics and what they mean
    - Critical Kubernetes pod metrics
    - Prometheus + Grafana for container monitoring
    - When to alert vs when to investigate
22. [Rollout Strategies — How Deployments Work](#22-rollout-strategies--how-deployments-work)
    - Rolling update (Kubernetes default)
    - Blue-Green deployment
    - Canary deployment
    - Which container type handles each strategy
    - Rollback — instant vs gradual
23. [Local Microservice Testing with Docker](#23-local-microservice-testing-with-docker)
    - Testing a single microservice end-to-end locally
    - Stubbing dependent services with WireMock
    - Common Docker debugging scenarios
    - How to test what you'll see in production
24. [Developer Access — EC2, RDS, EKS, ECR and KMS](#24-developer-access--ec2-rds-eks-ecr-and-kms)
    - IAM groups and policies for developers (DEV vs PROD access)
    - How to SSH into EC2 (key pair and Session Manager)
    - How to connect to RDS from your laptop
    - How to access EKS cluster with kubectl
    - How to login to ECR and push/pull images
    - KMS Encryption Keys — what they are and how developers use them
    - End-to-end: how a new developer gets set up from day one
25. [Testing Microservices in DEV Environment](#25-testing-microservices-in-dev-environment)
    - What DEV environment looks like vs local
    - How to hit DEV APIs from your laptop
    - Port-forwarding pods to test without exposing via ALB
    - Reading DEV logs from CloudWatch
    - Common DEV vs local differences and how to handle them

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


---

## 11. CENTRALIZED LOGGING — SLEUTH + ZIPKIN + CLOUDWATCH

> In a microservices system, a single user request can travel through 5 different services. If something goes wrong, you need to find ALL the logs for that ONE request across ALL services — in the right order. This is the problem centralized logging + distributed tracing solves.

---

### 11.1 The Problem Without Centralized Logging

```
User places an order → order-service → customer-service → payment-service → notification-service

User reports: "My order failed."

Without tracing:
  - order-service logs:   1000 log lines from all users
  - customer-service logs: 800 log lines from all users
  - payment-service logs:  600 log lines
  → Which logs belong to THIS user's failed request? You have no idea.

With Sleuth + trace ID:
  - Every log line for this request has:  traceId=a1b2c3d4, spanId=x1y2
  - Filter ALL service logs by traceId=a1b2c3d4 → see exact journey of that one request
```

---

### 11.2 Spring Cloud Sleuth — What It Does

**Sleuth is a library that automatically adds trace IDs to every log line and HTTP header, with zero code change from you.**

When you add Sleuth to your Spring Boot app, every log line automatically includes:
- **traceId** — same for the entire request journey across ALL services
- **spanId** — unique to each service hop

```
[order-service]    INFO  [traceId=a1b2c3d4, spanId=1111]  OrderService - Creating order for customer 42
[order-service]    INFO  [traceId=a1b2c3d4, spanId=1111]  OrderService - Calling customer-service to validate
[customer-service] INFO  [traceId=a1b2c3d4, spanId=2222]  CustomerService - Validating customer 42
[customer-service] INFO  [traceId=a1b2c3d4, spanId=2222]  CustomerService - Customer valid, returning OK
[order-service]    INFO  [traceId=a1b2c3d4, spanId=1111]  OrderService - Order created successfully: ORD-999
```

Notice: traceId `a1b2c3d4` is the **same** across both services. spanId is **different** per service.

**How Sleuth propagates the trace ID:**
When order-service calls customer-service via HTTP, Sleuth automatically adds HTTP headers:
```
X-B3-TraceId: a1b2c3d4  ← same trace for the whole journey
X-B3-SpanId: 2222       ← new span for this service hop
X-B3-ParentSpanId: 1111 ← who called me
```
customer-service reads these headers and continues the trace.

**pom.xml — add Sleuth:**
```xml
<!-- Spring Boot 2.x / Spring Cloud -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-sleuth</artifactId>
</dependency>

<!-- To also send traces to Zipkin -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-sleuth-zipkin</artifactId>
</dependency>
```

**application.yml — configure Zipkin:**
```yaml
spring:
  zipkin:
    base-url: http://zipkin-server:9411   # Zipkin server URL
  sleuth:
    sampler:
      probability: 1.0   # 1.0 = trace 100% of requests (use 0.1 in high-traffic prod)
```

---

### 11.3 Zipkin — Visualize the Full Request Journey

Zipkin is a UI + storage that receives trace data from all your microservices and shows you:
- How long each service took
- Which service failed
- The complete timeline of a request

```
Zipkin UI view for traceId=a1b2c3d4:

Timeline:
  order-service      [==========  120ms total  ===========]
    customer-service   [====  45ms  ====]   (called by order-service)
    payment-service         [========  60ms  ========]   (called after customer-service)
  
  → order-service spent 15ms of its own work + 105ms waiting for downstream calls
  → payment-service took 60ms — this is the bottleneck
```

**Running Zipkin locally (Docker):**
```bash
docker run -d -p 9411:9411 openzipkin/zipkin
# Access at http://localhost:9411
```

**Running Zipkin on EKS (production):**
```yaml
# k8s/zipkin-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: zipkin
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: zipkin
  template:
    metadata:
      labels:
        app: zipkin
    spec:
      containers:
        - name: zipkin
          image: openzipkin/zipkin:latest
          ports:
            - containerPort: 9411
          env:
            - name: STORAGE_TYPE
              value: elasticsearch   # store traces in Elasticsearch for long-term
            - name: ES_HOSTS
              value: http://elasticsearch:9200
---
apiVersion: v1
kind: Service
metadata:
  name: zipkin-server
  namespace: monitoring
spec:
  selector:
    app: zipkin
  ports:
    - port: 9411
      targetPort: 9411
```

---

### 11.4 CloudWatch Logs — Single Place for ALL Microservice Logs on AWS

On EKS, every pod's stdout/stderr logs are shipped to **CloudWatch Logs** by a log forwarder called **Fluent Bit** (AWS's recommended log shipper).

```
Pod (order-service)  → prints to stdout → Fluent Bit (runs on every node) 
    → CloudWatch Logs → Log Group: /eks/prod/order-service
    
Pod (customer-service) → prints to stdout → Fluent Bit
    → CloudWatch Logs → Log Group: /eks/prod/customer-service
```

**Fluent Bit is deployed as a DaemonSet** — one pod per node, automatically collects all container logs on that node and ships to CloudWatch.

```yaml
# fluent-bit sends logs to CloudWatch — configured via ConfigMap
# AWS provides a ready-made Helm chart for this:
helm repo add aws https://aws.github.io/eks-charts
helm install aws-for-fluent-bit aws/aws-for-fluent-bit \
  --namespace kube-system \
  --set cloudWatch.region=us-east-1 \
  --set cloudWatch.logGroupName=/eks/prod
```

**Viewing logs in CloudWatch Logs Insights:**

This is the most powerful feature — query logs from MULTIPLE log groups at once using a trace ID:

```sql
-- Query in CloudWatch Logs Insights:
-- Select BOTH log groups to search across both services at once

fields @timestamp, @message, @logStream
| filter @message like "a1b2c3d4"    -- your traceId
| sort @timestamp asc
| limit 200
```

Result — you see ALL logs for that one request, in time order, from all services:
```
2024-01-15 10:00:00.001  order-service   [traceId=a1b2c3d4] Creating order for customer 42
2024-01-15 10:00:00.010  order-service   [traceId=a1b2c3d4] Calling customer-service
2024-01-15 10:00:00.025  customer-service [traceId=a1b2c3d4] Received validate request
2024-01-15 10:00:00.045  customer-service [traceId=a1b2c3d4] Customer valid
2024-01-15 10:00:00.048  order-service   [traceId=a1b2c3d4] Customer valid, proceeding
2024-01-15 10:00:00.110  order-service   [traceId=a1b2c3d4] ERROR: Payment service timeout
```

**How to get the traceId to show the user:**
Return it in the API response header so the user can provide it in a bug report:
```java
// order-service — return traceId in response header
@GetMapping("/api/orders/{id}")
public ResponseEntity<Order> getOrder(@PathVariable Long id) {
    // Sleuth automatically sets traceId in MDC (Mapped Diagnostic Context)
    String traceId = MDC.get("traceId");
    return ResponseEntity.ok()
        .header("X-Trace-Id", traceId)
        .body(orderService.getOrder(id));
}
```

---

### 11.5 Complete Logging Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                    PRODUCTION LOGGING SETUP                         │
├────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  User Request → order-service → customer-service                   │
│       │              │                │                            │
│       │         [Sleuth adds     [Sleuth reads                     │
│       │          traceId to       traceId from                     │
│       │          all log lines]   HTTP headers,                    │
│       │                           continues same trace]            │
│       │                                                            │
│       │         stdout logs   stdout logs                          │
│       │              ↓              ↓                              │
│       │         [Fluent Bit]  [Fluent Bit]  ← DaemonSet on nodes  │
│       │              ↓              ↓                              │
│       │      CloudWatch Logs Group: /eks/prod                      │
│       │              ↓                                             │
│       │      CloudWatch Logs Insights → query by traceId           │
│       │                                                            │
│       │         Zipkin receives trace spans from both services     │
│       │              ↓                                             │
│       │      Zipkin UI → visualize timeline, find bottleneck       │
│       │                                                            │
│  traceId returned in X-Trace-Id response header to user           │
└────────────────────────────────────────────────────────────────────┘
```

**Interview Q: Where do you view logs across microservices?**
> "We use Spring Cloud Sleuth to inject a traceId into every log line and propagate it across service calls via HTTP headers. All pod logs are shipped to CloudWatch Logs using Fluent Bit. To debug a specific request, I take the traceId from the response header, go to CloudWatch Logs Insights, select all relevant log groups, and filter by that traceId — I get all logs for that one request across all services in time order. For timing/bottleneck analysis, I use Zipkin which visualizes the full trace as a timeline."

---

## 12. CONTAINER & POD FAILURE ANALYSIS

> When something goes wrong in production, you need to quickly find out: what failed, where it failed, and why. This section covers every common failure type and the exact commands to diagnose them.

---

### 12.1 Pod Status States — What Each One Means

Run `kubectl get pods -n production` and you'll see these STATUS values:

```
NAME                             READY   STATUS             RESTARTS   AGE
order-service-7d9f8b-xk2p9      1/1     Running            0          2d
order-service-7d9f8b-abc12      0/1     CrashLoopBackOff   5          10m
customer-service-6c5d9-xyz99    0/1     OOMKilled           2          5m
customer-service-6c5d9-pqr11    0/1     ImagePullBackOff   0          2m
payment-service-4b3e1-mno88     0/1     Pending            0          3m
order-service-7d9f8b-def34      0/1     Error              1          1m
```

---

### 12.2 CrashLoopBackOff — The Most Common Failure

**What it means:** The pod starts, crashes immediately, Kubernetes restarts it, it crashes again. After several attempts Kubernetes backs off and waits longer between retries.

**Why it happens:**
```
1. Spring Boot cannot connect to the database on startup
   Error: com.zaxxer.hikari.pool.HikariPool$PoolInitializationException
          Cannot connect to jdbc:postgresql://localhost:5432/orders_db
   Fix:   DB_URL env var is wrong, or DB is not reachable from this pod

2. Required environment variable is missing or null
   Error: java.lang.IllegalStateException: Could not resolve placeholder 'JWT_SECRET'
   Fix:   Secret not mounted — check ExternalSecret or ConfigMap

3. Port already in use (rare in K8s, common in Docker)
   Error: java.net.BindException: Address already in use: 8080
   Fix:   Two containers trying to use same port

4. Application code throws exception on @PostConstruct or startup bean
   Error: Application context failed to start
   Fix:   Fix the initialization code

5. JVM can't start — too little memory
   Error: java.lang.OutOfMemoryError: Java heap space  (on startup)
   Fix:   Increase memory limit in deployment.yaml
```

**How to diagnose CrashLoopBackOff:**
```bash
# Step 1: See the error message
kubectl logs order-service-abc12 -n production

# Step 2: If the pod already crashed and restarted, see PREVIOUS run's logs
kubectl logs order-service-abc12 -n production --previous

# Step 3: Get detailed events (most useful — shows EXACTLY why K8s killed it)
kubectl describe pod order-service-abc12 -n production
# Look at the "Events" section at the bottom — it shows:
# "Back-off restarting failed container"
# "Started container order-service"
# "Killing container with id docker://xxx: Need to kill Pod"
```

---

### 12.3 OOMKilled — Out of Memory

**What it means:** Your container used more memory than its `limits.memory` setting. Linux kernel kills it with SIGKILL (exit code 137).

**Why it happens:**
```
1. JVM heap size not configured for container
   By default JVM takes 25% of total host RAM, not container memory limit
   Container limit: 512Mi → JVM takes 512MB heap → exceeds limit → OOMKilled
   Fix: Add -XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 to Dockerfile
        (JVM then reads the container cgroup limit, not host RAM)

2. Memory leak in application code
   Connection pool not releasing connections
   Static collections that keep growing
   Cache without eviction policy
   Fix: Fix the leak, use APM (Datadog/New Relic) to find which object is leaking

3. Memory limit set too low for the workload
   Spring Boot with lots of dependencies needs at least 300-512MB
   Fix: Increase memory limit in deployment.yaml

4. Large response payloads loaded into memory
   Loading a 500MB file from S3 into byte[] array
   Fix: Use streaming (InputStream) instead of loading all bytes at once
```

**How to diagnose OOMKilled:**
```bash
# See the exit code and reason
kubectl describe pod customer-service-xyz -n production
# Output will show:
#   Last State: Terminated
#     Reason:   OOMKilled
#     Exit Code: 137

# See memory usage before it died (if you have metrics server)
kubectl top pod customer-service-xyz -n production

# Check the current memory usage of all pods
kubectl top pods -n production
```

---

### 12.4 ImagePullBackOff — Cannot Download the Docker Image

**What it means:** Kubernetes cannot pull the Docker image from ECR (or Docker Hub).

**Why it happens:**
```
1. Image does not exist in ECR
   You deployed with tag :99 but that build never pushed to ECR
   Fix: Check ECR console for available tags; verify the build pipeline ran

2. Wrong ECR registry URL in deployment.yaml
   image: 123456789.dkr.ecr.us-east-1.amazonaws.com/order-service:42
   But the account ID or region is wrong
   Fix: Verify the exact ECR URI

3. EKS node does not have permission to pull from ECR
   Node group IAM role is missing: ecr:GetDownloadUrlForLayer, ecr:BatchGetImage
   Fix: Add AmazonEC2ContainerRegistryReadOnly policy to node IAM role

4. ECR auth token expired (rare — EKS refreshes automatically via IRSA)
   Fix: kubectl delete pod <pod-name> to trigger a fresh pull attempt
```

**How to diagnose ImagePullBackOff:**
```bash
kubectl describe pod payment-service-mno88 -n production
# Events section will show:
#   Failed to pull image "123456789.dkr.ecr.us-east-1.amazonaws.com/payment-service:99":
#   rpc error: repository does not exist or may require 'docker login'
```

---

### 12.5 Pending — Pod Cannot Be Scheduled

**What it means:** The pod exists in Kubernetes but no node can run it yet.

**Why it happens:**
```
1. Insufficient CPU or memory on all nodes
   All nodes are at capacity, new pod needs 500m CPU but none available
   Fix: Scale up the node group (add more EC2 nodes) or reduce resource requests

2. Pod anti-affinity rule can't be satisfied
   You required pods in 3 AZs but only 2 AZ nodes exist
   Fix: Change affinity from requiredDuringScheduling to preferredDuringScheduling

3. Taint on nodes that pod doesn't tolerate
   Node has taint: spot-instance=true:NoSchedule
   Fix: Add toleration to pod spec or use a different node group

4. PVC (volume) not yet bound
   Pod needs a PersistentVolumeClaim but no PV is available
   Fix: Check PVC status with kubectl get pvc
```

**How to diagnose Pending:**
```bash
kubectl describe pod order-service-def34 -n production
# Events section:
#   Warning  FailedScheduling  0/3 nodes are available:
#   3 Insufficient memory. preemption: 0/3 nodes are eligible for preemption
```

---

### 12.6 Running but NOT Ready — Readiness Probe Failing

**What it means:** Pod is running but the readiness probe keeps failing, so Kubernetes doesn't send it any traffic (Service routes around it).

**Why it happens:**
```
1. Spring Boot started but database connection pool initialization failing
   /actuator/health/readiness returns 503 because DataSource is DOWN
   Fix: Fix DB connectivity — wrong password, DB not reachable

2. Downstream service health check makes readiness probe fail
   Your service checks customer-service in /readiness → customer-service is down
   → your pod is not ready even though it's fine
   Fix: Don't include downstream services in readiness probe — only check self

3. Spring Boot is slow to fully initialize
   Readiness probe starts checking too early (before beans are ready)
   Fix: Use startupProbe with long enough failureThreshold to give app time to start

4. Service returning errors on health endpoint
   A bug causes /actuator/health to throw exception
   Fix: Fix the bug, check logs
```

---

### 12.7 Docker Container Exit Codes

When a container exits, the exit code tells you why:

| Exit Code | Meaning | Common Cause |
|---|---|---|
| 0 | Clean exit | Normal shutdown |
| 1 | Application error | Uncaught Java exception on startup |
| 137 | SIGKILL — OOMKilled | Container exceeded memory limit |
| 139 | Segmentation fault | JVM native crash (rare) |
| 143 | SIGTERM — graceful shutdown | Kubernetes sent termination signal (normal) |

```bash
# See exit code of a stopped Docker container
docker inspect <container-id> --format '{{.State.ExitCode}}'

# See all container stats
docker stats   # live CPU/memory usage
docker inspect <container-id>   # full metadata
```

---

### 12.8 Debugging Workflow — Step by Step

When a pod fails in production, follow this exact sequence:

```bash
# ─── Step 1: Get the big picture ──────────────────────────────────
kubectl get pods -n production
# Note the STATUS (CrashLoopBackOff, OOMKilled, etc.) and RESTARTS count

# ─── Step 2: Look at pod events ───────────────────────────────────
kubectl describe pod <pod-name> -n production
# Read the Events section at the bottom — this is the most important part
# It shows: why K8s couldn't schedule, why health check failed, etc.

# ─── Step 3: See the crash logs ───────────────────────────────────
kubectl logs <pod-name> -n production
# If pod already crashed and was restarted, get the previous instance's logs:
kubectl logs <pod-name> -n production --previous

# ─── Step 4: If pod is running, check live logs ───────────────────
kubectl logs -f <pod-name> -n production --tail=100
# -f = follow (stream live), --tail=100 = last 100 lines first

# ─── Step 5: If app is running but misbehaving, exec in ───────────
kubectl exec -it <pod-name> -n production -- sh
# Now you're inside the running container:
curl localhost:8080/actuator/health    # check health
curl localhost:8080/actuator/env       # check all environment variables
env | grep DB                          # check DB env vars
# Try to reach the database from inside the pod:
nc -vz orders-rds.prod.internal 5432  # test DB connectivity

# ─── Step 6: Check resource usage ─────────────────────────────────
kubectl top pods -n production
kubectl top nodes
# If a pod shows 999m/1000m CPU → it's CPU throttled (responses slow)
# If memory is near limit → risk of OOMKill
```

---

## 13. ESSENTIAL DEVELOPER COMMANDS

> As a Java microservices developer, you'll use these tools daily. Here's every important command, what it does, and where you run it.

**Where to run each:**
- `kubectl` — Your laptop (with kubeconfig from `aws eks update-kubeconfig`) or Jenkins
- `docker` — Your laptop (Docker Desktop) or the Jenkins build server
- `aws` — Your laptop (with IAM user credentials) or Jenkins (with IAM role)

---

### 13.1 kubectl — Kubernetes Commands

```bash
# ── VIEWING RESOURCES ──────────────────────────────────────────────

kubectl get pods -n production               # list all pods in namespace
kubectl get pods -n production -o wide       # also shows which node each pod is on
kubectl get pods --all-namespaces            # pods in ALL namespaces
kubectl get deployments -n production        # list deployments
kubectl get services -n production           # list services (and their ClusterIP / ports)
kubectl get ingress -n production            # list ingress (and ALB hostname)
kubectl get hpa -n production                # horizontal pod autoscalers + current replicas
kubectl get pdb -n production                # pod disruption budgets
kubectl get configmaps -n production         # configmaps
kubectl get secrets -n production            # secrets (values are base64 — use describe to see)
kubectl get nodes                            # list all cluster nodes + their status
kubectl get events -n production --sort-by='.lastTimestamp'  # recent cluster events

# ── DEBUGGING ─────────────────────────────────────────────────────

kubectl describe pod <pod-name> -n production        # full pod details + events
kubectl describe deployment order-service -n production  # deployment status + conditions
kubectl logs <pod-name> -n production                # current logs
kubectl logs <pod-name> -n production --previous     # logs from the PREVIOUS crashed container
kubectl logs -f <pod-name> -n production             # stream logs live (follow)
kubectl logs <pod-name> -n production --tail=200     # last 200 lines
kubectl logs <pod-name> -n production -c <container> # specific container (in multi-container pod)
kubectl exec -it <pod-name> -n production -- sh      # open shell inside running pod
kubectl exec -it <pod-name> -n production -- env     # print all env vars without entering pod
kubectl top pods -n production                       # live CPU and memory per pod
kubectl top nodes                                    # live CPU and memory per node
kubectl port-forward pod/<pod-name> 8080:8080 -n production  # forward pod port to your laptop

# ── DEPLOYING & MANAGING ──────────────────────────────────────────

kubectl apply -f k8s/order-service/ -n production   # create/update all resources in directory
kubectl apply -f deployment.yaml -n production       # apply single file
kubectl delete -f deployment.yaml -n production      # delete resource from file
kubectl delete pod <pod-name> -n production          # delete pod (K8s will recreate it)

# Change the image (deploy new version):
kubectl set image deployment/order-service \
  order-service=123456789.dkr.ecr.us-east-1.amazonaws.com/order-service:43 \
  -n production

kubectl rollout status deployment/order-service -n production    # wait for rollout to finish
kubectl rollout history deployment/order-service -n production   # show rollout history
kubectl rollout undo deployment/order-service -n production      # ROLLBACK to previous version
kubectl rollout undo deployment/order-service --to-revision=3 -n production  # rollback to specific revision
kubectl rollout restart deployment/order-service -n production   # rolling restart (all pods)
kubectl scale deployment order-service --replicas=5 -n production  # manually scale pods

# ── CONTEXT MANAGEMENT ────────────────────────────────────────────
# A "context" = which cluster + namespace you're connected to

aws eks update-kubeconfig --region us-east-1 --name prod-eks-cluster  # add EKS cluster
kubectl config get-contexts                  # list all contexts (clusters)
kubectl config use-context <context-name>    # switch to different cluster
kubectl config current-context               # which cluster am I on right now?
kubectl config set-context --current --namespace=production  # set default namespace
```

---

### 13.2 Docker Commands

```bash
# ── BUILDING ──────────────────────────────────────────────────────

docker build -t order-service:latest .                  # build image from Dockerfile in current dir
docker build -t order-service:42 --platform=linux/amd64 .  # force build for AWS Linux nodes (important on Mac M1/M2)
docker build --no-cache -t order-service:latest .       # build without using cached layers

# ── RUNNING ───────────────────────────────────────────────────────

docker run -p 8080:8080 order-service:latest            # run and expose port
docker run -d -p 8080:8080 order-service:latest         # run in background (detached)
docker run -d -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=local \
  -e DB_URL=jdbc:postgresql://host.docker.internal:5432/orders_db \
  order-service:latest                                  # run with environment variables

# host.docker.internal = your laptop's IP, reachable from inside the container

# ── MANAGING CONTAINERS ───────────────────────────────────────────

docker ps                       # running containers
docker ps -a                    # all containers (including stopped)
docker stop <container-id>      # graceful stop (SIGTERM → waits → SIGKILL)
docker kill <container-id>      # immediate kill (SIGKILL)
docker rm <container-id>        # remove stopped container
docker rm -f <container-id>     # force remove running container

# ── DEBUGGING ─────────────────────────────────────────────────────

docker logs <container-id>                   # see container logs
docker logs -f <container-id>                # follow logs live
docker logs --tail=100 <container-id>        # last 100 lines
docker exec -it <container-id> sh            # open shell inside running container
docker inspect <container-id>               # full container metadata (ports, mounts, env vars)
docker inspect <container-id> --format '{{.State.ExitCode}}'  # get exit code
docker stats                                 # live CPU/memory for all running containers
docker stats <container-id>                  # live stats for one container

# ── IMAGES ───────────────────────────────────────────────────────

docker images                   # list local images
docker rmi order-service:latest # remove image
docker tag order-service:42 123456789.dkr.ecr.us-east-1.amazonaws.com/order-service:42  # tag for ECR
docker pull openjdk:21-jre      # pull from Docker Hub
docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/order-service:42  # push to ECR

# ── CLEANUP ───────────────────────────────────────────────────────

docker system prune              # remove all stopped containers + unused images
docker system prune -a           # also remove unused images (aggressive cleanup)
docker volume prune              # remove unused volumes

# ── DOCKER COMPOSE ────────────────────────────────────────────────

docker-compose up                          # start all services defined in docker-compose.yml
docker-compose up --build                  # rebuild images first, then start
docker-compose up -d                       # start in background
docker-compose up order-service            # start only ONE service (and its depends_on)
docker-compose down                        # stop all containers
docker-compose down -v                     # stop + remove volumes (wipe DBs)
docker-compose logs -f order-service       # follow logs for specific service
docker-compose exec order-service sh       # shell into running service container
docker-compose ps                          # status of all compose services
docker-compose restart order-service       # restart one service
```

---

### 13.3 AWS CLI Commands

```bash
# ── AUTHENTICATION ────────────────────────────────────────────────

aws configure                               # set up credentials (access key, secret, region)
aws sts get-caller-identity                 # who am I? (shows account ID, IAM user/role)

# ── ECR ───────────────────────────────────────────────────────────

# Login Docker to ECR (needed before push/pull):
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin 123456789.dkr.ecr.us-east-1.amazonaws.com

aws ecr list-images --repository-name order-service    # list images in a repo
aws ecr describe-image-scan-findings \                 # check image vulnerability scan results
  --repository-name order-service --image-id imageTag=42

# ── EKS ───────────────────────────────────────────────────────────

aws eks list-clusters                                  # list your EKS clusters
aws eks describe-cluster --name prod-eks-cluster       # cluster details
aws eks update-kubeconfig --region us-east-1 \
  --name prod-eks-cluster                              # add cluster to kubectl config

# ── S3 ────────────────────────────────────────────────────────────

aws s3 ls                                             # list all buckets
aws s3 ls s3://my-bucket/uploads/                    # list files in a bucket/prefix
aws s3 cp localfile.txt s3://my-bucket/path/          # upload file
aws s3 cp s3://my-bucket/path/file.txt ./             # download file
aws s3 sync ./build/ s3://my-frontend-bucket/ --delete  # sync directory to S3
aws s3 rm s3://my-bucket/path/file.txt               # delete file

# ── CLOUDWATCH LOGS ───────────────────────────────────────────────

aws logs describe-log-groups                          # list all log groups
aws logs filter-log-events \
  --log-group-name /eks/prod/order-service \
  --filter-pattern "ERROR"                            # search logs for ERROR

# ── SECRETS MANAGER ───────────────────────────────────────────────

aws secretsmanager list-secrets                       # list all secrets
aws secretsmanager get-secret-value \
  --secret-id /prod/order-service/db                 # get secret value

# ── LAMBDA ────────────────────────────────────────────────────────

aws lambda list-functions                             # list all Lambda functions
aws lambda invoke \
  --function-name order-processor \
  --payload '{"orderId": "123"}' \
  response.json                                       # manually trigger a Lambda
aws lambda get-function --function-name order-processor  # function details

# ── ECS (FARGATE) ─────────────────────────────────────────────────

aws ecs list-clusters                                 # list ECS clusters
aws ecs list-services --cluster prod-cluster          # list services in cluster
aws ecs describe-services \
  --cluster prod-cluster \
  --services order-service                            # service status
aws ecs update-service \
  --cluster prod-cluster \
  --service order-service \
  --force-new-deployment                              # redeploy (like kubectl rollout restart)
```

---

### 13.4 Where to Execute These Commands

```
YOUR LAPTOP:
  kubectl → needs: aws eks update-kubeconfig (add EKS cluster to ~/.kube/config)
            needs: IAM user with eks:DescribeCluster permission
  docker  → needs: Docker Desktop installed
  aws cli → needs: aws configure (IAM user access key + secret)

JENKINS SERVER (automated):
  kubectl → configured via: aws eks update-kubeconfig in pipeline script
            uses IAM Role attached to Jenkins EC2 (no hardcoded credentials)
  docker  → Jenkins user must be in 'docker' group (sudo usermod -aG docker jenkins)
  aws cli → uses IAM Role on Jenkins EC2 instance automatically

INSIDE AN EKS POD (via kubectl exec):
  curl    → test internal service connectivity
  wget    → download files / health checks
  env     → list all environment variables
  nc -vz  → test TCP connectivity to DB: nc -vz postgres-host 5432
  nslookup/ dig → test DNS resolution inside cluster
```

---

## 14. DOCKER COMPOSE FOR SINGLE-SERVICE DEVELOPMENT

> "If one team works on one microservice, why do we need Docker Compose? We test individually using test cases."

This is a great question and the answer is: **you need Docker Compose because your microservice almost always depends on infrastructure (database, cache, message queue) that you don't have installed locally, and because local environment consistency matters.**

---

### 14.1 What Happens Without Docker Compose

**Scenario:** You're a developer working ONLY on `order-service`. You want to run it locally.

```
order-service needs:
  1. PostgreSQL database (orders_db)
  2. Redis (for caching orders)
  3. Maybe: a mock of customer-service (since order-service calls it)

Without Docker Compose:
  Option A: Install PostgreSQL on your laptop
    - macOS: brew install postgresql@16
    - Windows: download installer, set PATH, create service
    - Linux: apt install postgresql
    → Different versions between developers
    → "Works on my machine" problem
    → Pollutes your laptop with services running in background
    → DB data persists across test runs — tests can interfere with each other

  Option B: Use a shared dev database
    → Developers overwrite each other's data
    → Test A deletes the row Test B needs
    → Can't run tests in parallel
    → Not isolated

  Option C: H2 in-memory database (common mistake)
    → H2 is not PostgreSQL — syntax differs
    → Tests pass on H2 but fail against real PostgreSQL
    → Hides real bugs
```

---

### 14.2 What Docker Compose Solves

```yaml
# docker-compose.yml in order-service repo (maintained by order-service team)
version: '3.9'

services:
  # All infrastructure this service needs — no manual installation
  postgres-orders:
    image: postgres:16-alpine
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
      interval: 5s
      retries: 10

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  # WireMock: fake customer-service so order-service can call it
  # You control what the fake returns — no dependency on customer-service team
  customer-service-mock:
    image: wiremock/wiremock:latest
    ports:
      - "8081:8080"
    volumes:
      - ./wiremock-stubs:/home/wiremock   # put JSON stub files here

  order-service:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
    environment:
      SPRING_PROFILES_ACTIVE: local
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres-orders:5432/orders_db
      SPRING_DATASOURCE_USERNAME: orders_user
      SPRING_DATASOURCE_PASSWORD: orders_secret
      SPRING_REDIS_HOST: redis
      CUSTOMER_SERVICE_URL: http://customer-service-mock:8080   # points to WireMock
    depends_on:
      postgres-orders:
        condition: service_healthy

volumes:
  orders-data:
```

**WireMock stub** — fake customer-service response:
```json
// wiremock-stubs/mappings/validate-customer.json
{
  "request": {
    "method": "GET",
    "urlPattern": "/api/customers/[0-9]+"
  },
  "response": {
    "status": 200,
    "headers": { "Content-Type": "application/json" },
    "body": "{\"id\": 42, \"name\": \"John Doe\", \"active\": true}"
  }
}
```

Now `order-service` thinks it's talking to a real `customer-service`. The order-service developer doesn't need the customer-service codebase at all.

---

### 14.3 TestContainers — Docker Compose Inside JUnit Tests

**Testcontainers** starts real Docker containers as part of your JUnit test, then tears them down after. No docker-compose.yml needed for running tests.

```java
// OrderServiceIntegrationTest.java
@SpringBootTest
@Testcontainers
class OrderServiceIntegrationTest {

    // Starts a REAL PostgreSQL container for this test class
    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine")
            .withDatabaseName("orders_db")
            .withUsername("test_user")
            .withPassword("test_pass");

    // Dynamically set the datasource URL from the container
    @DynamicPropertySource
    static void configure(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    @Autowired
    private OrderService orderService;

    @Test
    void shouldCreateOrderSuccessfully() {
        // This test runs against a real PostgreSQL container
        // Not H2, not a shared dev DB — isolated, clean, real
        Order order = orderService.createOrder(new CreateOrderRequest(42L, "Laptop", 1));
        assertThat(order.getId()).isNotNull();
        assertThat(order.getStatus()).isEqualTo(OrderStatus.CREATED);
    }
}
```

**Summary — when to use each:**

| Approach | When to Use |
|---|---|
| Docker Compose | Running the full service locally for manual testing / development |
| TestContainers | Integration tests in CI/CD — starts infra per test, tears down after |
| H2 in-memory | Unit tests only — never for integration tests |
| WireMock | Stub out other microservices your service depends on |

---

## 15. AWS LAMBDA — JAVA IMPLEMENTATION & ALL TRIGGER TYPES

> Lambda is AWS's serverless compute — you write a function, AWS runs it when triggered. You pay only for the milliseconds it runs. No servers to manage.

---

### 15.1 How Lambda Works (Simple Mental Model)

```
Traditional EC2/EKS:
  Server runs 24/7 → you pay 24/7 → even when no users

Lambda:
  Event happens → AWS wakes up your code → runs it → stops → you pay for those milliseconds only
  
Analogy: EC2 = leaving the lights on in every room all day
         Lambda = lights with motion sensors — only on when someone is in the room
```

**Execution model:**
```
Event (HTTP call, S3 upload, message, schedule)
    ↓
Lambda Service (AWS-managed)
    ↓ (cold start: JVM warms up — first request is slower)
Your Java Handler Function executes
    ↓
Returns result / writes to DB / sends notification
    ↓
Container idles (kept warm for ~15 min) or destroyed
```

---

### 15.2 All Lambda Trigger Types

There are **12 main ways** to trigger a Lambda:

| # | Trigger | Use Case |
|---|---|---|
| 1 | **API Gateway** | HTTP REST API endpoint |
| 2 | **S3 Event** | File uploaded → process it |
| 3 | **SQS** | Message queue → process messages |
| 4 | **SNS** | Notification → fan-out to Lambda |
| 5 | **DynamoDB Stream** | DB change → react to it |
| 6 | **EventBridge (CloudWatch Events)** | Scheduled (cron) or rule-based events |
| 7 | **Kinesis** | Real-time data stream processing |
| 8 | **ALB (Application Load Balancer)** | HTTP request via load balancer |
| 9 | **Cognito** | User pool events (pre-signup, post-confirm) |
| 10 | **CloudFront (Lambda@Edge)** | Run code at edge CDN nodes |
| 11 | **IoT Rule** | IoT device events |
| 12 | **Manual / SDK** | Direct invoke from code or AWS CLI |

---

### 15.3 Lambda Handler — Java Code for Each Trigger Type

**pom.xml — Lambda dependencies:**
```xml
<dependency>
    <groupId>com.amazonaws</groupId>
    <artifactId>aws-lambda-java-core</artifactId>
    <version>1.2.3</version>
</dependency>
<dependency>
    <groupId>com.amazonaws</groupId>
    <artifactId>aws-lambda-java-events</artifactId>
    <version>3.11.4</version>
</dependency>
```

---

**Trigger 1: API Gateway — HTTP REST Endpoint**

```java
// Receives HTTP request from API Gateway, returns HTTP response
public class OrderHandler
        implements RequestHandler<APIGatewayProxyRequestEvent, APIGatewayProxyResponseEvent> {

    private final ObjectMapper mapper = new ObjectMapper();

    @Override
    public APIGatewayProxyResponseEvent handleRequest(
            APIGatewayProxyRequestEvent event, Context context) {

        LambdaLogger log = context.getLogger();

        // HTTP method and path
        String method = event.getHttpMethod();     // "GET", "POST", etc.
        String path   = event.getPath();           // "/api/orders/42"

        // Path parameters: GET /api/orders/{id}
        String orderId = event.getPathParameters().get("id");

        // Query parameters: GET /api/orders?status=PENDING
        String status = event.getQueryStringParameters().get("status");

        // Request body (for POST/PUT)
        String body = event.getBody();
        // Parse JSON body:
        // CreateOrderRequest req = mapper.readValue(body, CreateOrderRequest.class);

        // Request headers
        String authHeader = event.getHeaders().get("Authorization");

        log.log("Processing " + method + " " + path + " orderId=" + orderId);

        try {
            // Your business logic here
            Order order = OrderRepository.findById(Long.parseLong(orderId));

            return new APIGatewayProxyResponseEvent()
                    .withStatusCode(200)
                    .withHeaders(Map.of("Content-Type", "application/json"))
                    .withBody(mapper.writeValueAsString(order));

        } catch (OrderNotFoundException e) {
            return new APIGatewayProxyResponseEvent()
                    .withStatusCode(404)
                    .withBody("{\"error\": \"Order not found\"}");
        }
    }
}
```

---

**Trigger 2: S3 Event — React to File Upload**

```java
// Triggered when a file is uploaded to S3
// Use case: user uploads a PDF invoice → Lambda converts it to CSV
public class S3FileProcessor implements RequestHandler<S3Event, String> {

    private final S3Client s3 = S3Client.builder()
            .region(Region.US_EAST_1)
            .credentialsProvider(DefaultCredentialsProvider.create())
            .build();

    @Override
    public String handleRequest(S3Event event, Context context) {
        LambdaLogger log = context.getLogger();

        // S3 event can contain multiple records (batch upload)
        for (S3EventNotification.S3EventNotificationRecord record : event.getRecords()) {
            String bucketName = record.getS3().getBucket().getName();
            String objectKey  = record.getS3().getObject().getUrlDecodedKey();
            String eventType  = record.getEventName();   // "ObjectCreated:Put", "ObjectRemoved:Delete"

            log.log("Event: " + eventType + " | Bucket: " + bucketName + " | Key: " + objectKey);

            if (eventType.startsWith("ObjectCreated")) {
                // Download the uploaded file
                GetObjectRequest getReq = GetObjectRequest.builder()
                        .bucket(bucketName)
                        .key(objectKey)
                        .build();

                try (ResponseInputStream<GetObjectResponse> s3Stream = s3.getObject(getReq)) {
                    byte[] fileBytes = s3Stream.readAllBytes();
                    // Process file: convert PDF to CSV, extract data, etc.
                    processFile(fileBytes, objectKey);
                    log.log("Processed file: " + objectKey);
                } catch (IOException e) {
                    log.log("ERROR processing file: " + e.getMessage());
                    throw new RuntimeException(e);
                }
            }
        }
        return "Processed " + event.getRecords().size() + " S3 events";
    }

    private void processFile(byte[] bytes, String key) {
        // Business logic: parse, transform, store result
    }
}
```

**S3 trigger configuration (in AWS console or Terraform):**
```
S3 Bucket → Properties → Event Notifications → Add notification
  Event types: s3:ObjectCreated:* (all uploads)
  Prefix filter: invoices/   ← only trigger for files in "invoices/" folder
  Suffix filter: .pdf        ← only trigger for PDFs
  Destination: Lambda → your-lambda-function
```

---

**Trigger 3: SQS — Process Queue Messages**

```java
// Triggered by messages in an SQS queue
// Use case: order-service sends a message to SQS when order is placed
//           Lambda reads it and sends a confirmation email
public class OrderEmailSender implements RequestHandler<SQSEvent, Void> {

    @Override
    public Void handleRequest(SQSEvent event, Context context) {
        LambdaLogger log = context.getLogger();

        // Lambda receives a BATCH of messages (configurable, up to 10 at once)
        for (SQSEvent.SQSMessage message : event.getRecords()) {
            String messageBody = message.getBody();
            String messageId   = message.getMessageId();

            log.log("Processing SQS message: " + messageId);

            try {
                // Parse the order event from the message body
                OrderCreatedEvent orderEvent = parseOrderEvent(messageBody);

                // Send confirmation email via SES
                sendEmail(orderEvent.getCustomerEmail(), orderEvent.getOrderId());

                // Successfully processed — Lambda automatically deletes from queue
                log.log("Email sent for order: " + orderEvent.getOrderId());

            } catch (Exception e) {
                // If you throw an exception, message goes back to queue
                // After maxReceiveCount attempts → sent to Dead Letter Queue (DLQ)
                log.log("FAILED to process message " + messageId + ": " + e.getMessage());
                throw new RuntimeException("Failed processing: " + messageId, e);
            }
        }
        return null;
    }
}
```

---

**Trigger 4: EventBridge — Scheduled (Cron)**

```java
// Triggered on a schedule (like cron job)
// Use case: every day at midnight, clean up expired orders
public class OrderCleanupScheduler implements RequestHandler<ScheduledEvent, String> {

    @Override
    public String handleRequest(ScheduledEvent event, Context context) {
        LambdaLogger log = context.getLogger();

        // event.getTime() = when Lambda was triggered
        // event.getSource() = "aws.events"
        log.log("Scheduled cleanup triggered at: " + event.getTime());

        // Delete orders older than 90 days with status CANCELLED
        int deletedCount = deleteExpiredOrders();

        String result = "Cleaned up " + deletedCount + " expired orders";
        log.log(result);
        return result;
    }

    private int deleteExpiredOrders() {
        // Database cleanup logic
        return 0;
    }
}
```

**EventBridge rule — schedule (like cron):**
```
In AWS Console → EventBridge → Rules → Create rule
  Event Source: Schedule
  Cron expression: cron(0 0 * * ? *)   ← runs every day at midnight UTC
  Target: Lambda → order-cleanup-scheduler
```

---

### 15.4 Lambda Configuration in AWS

```
Function settings (important for interviews):
  Runtime:  Java 21  (or Java 17 — both supported)
  Memory:   512 MB to 10 GB  (CPU scales proportionally with memory)
  Timeout:  Max 15 minutes (default 3 seconds — increase for long tasks)
  Handler:  com.myapp.OrderHandler::handleRequest
            ↑ full class name :: method name

Execution Role: IAM Role attached to Lambda
  → Defines what AWS services Lambda can access
  → e.g., role with S3:GetObject lets Lambda read S3 files
  → role with SES:SendEmail lets Lambda send emails
```

---

### 15.5 Cold Start — The Main Java Lambda Challenge

```
Cold Start: When Lambda hasn't run recently, AWS must:
  1. Provision a new container (micro-VM)
  2. Download and unzip your JAR (~50-200 MB)
  3. Start the JVM
  4. Load Spring context (if using Spring) — most expensive step
  5. Execute your handler

Cold start time for Java:
  Simple handler (no Spring): 200-500ms
  Spring Boot Lambda:         1-3 seconds  ← this is the problem

Warm start: Container stays alive for ~15 min after last invocation
  Warm start time: 5-50ms

Solutions:
  1. Provisioned Concurrency: AWS keeps X containers pre-warmed (paid feature)
     → No cold start at all — instant response every time
     
  2. GraalVM Native Image: Compile Spring Boot to native binary
     → JVM doesn't start — binary starts in <100ms
     → Requires Spring Boot 3.x + Spring Native
     
  3. Use AWS Lambda SnapStart (Java 21 feature):
     → AWS snapshots the JVM state after initialization
     → Restores from snapshot instead of re-initializing
     → Cold start: ~200ms instead of 2s
     
  4. Keep Lambda warm artificially: EventBridge rule pings Lambda every 5 min
     → Free but hacky
```

---

## 16. AWS FARGATE — SERVERLESS CONTAINERS

> Fargate = "I want to run Docker containers but I don't want to manage any EC2 servers." AWS handles all the infrastructure — you just say "run this container with 1 CPU and 2GB RAM" and it does it.

---

### 16.1 The Problem Fargate Solves

```
Without Fargate (using EC2 nodes in EKS/ECS):
  You create EC2 instances → configure them → patch OS → monitor them
  Cluster has 10 nodes → you pay for all 10 even if only 3 are busy
  Node gets hacked → you must patch and rotate

With Fargate:
  You define: container image + CPU + memory
  AWS handles: finding the hardware, starting it, networking, security
  You pay: per task per second (only when your container is actually running)
  No EC2 to manage, patch, or secure
```

**Analogy:** EC2 nodes = buying a car (you maintain it). Fargate = Uber (you just say where to go).

---

### 16.2 ECS vs EKS — And Where Fargate Fits

Fargate is a **compute engine** (not an orchestrator). It works with **both** ECS and EKS:

```
ECS (Elastic Container Service)   →  AWS's own orchestrator  →  can use Fargate or EC2
EKS (Elastic Kubernetes Service)  →  Kubernetes orchestrator →  can use Fargate or EC2

You choose:
  1. What orchestrates your containers: ECS or EKS?
  2. What runs them:                    Fargate (serverless) or EC2 (managed)?

Common combinations:
  ECS + Fargate  → Simple, fully managed, no K8s complexity  (good for teams new to containers)
  EKS + EC2      → Full K8s features + custom node control   (good for K8s-mature teams)
  EKS + Fargate  → K8s features + no node management         (simpler but some K8s features unavailable)
```

---

### 16.3 ECS + Fargate — Key Concepts

```
ECS Cluster
  └── Service (like a K8s Deployment — keeps N tasks running)
        └── Task (like a K8s Pod — one running instance of your container)
              └── Container (your Docker container)

ECS Task Definition (like a K8s Pod spec — defines what to run):
  - Container image
  - CPU (256 = 0.25 vCPU, 512 = 0.5 vCPU, 1024 = 1 vCPU)
  - Memory (512MB to 30GB)
  - Port mappings
  - Environment variables
  - Secrets from Secrets Manager
  - Log configuration (CloudWatch Logs)
  - IAM Task Role (like K8s ServiceAccount with IRSA)
```

**ECS Task Definition for order-service (Fargate):**
```json
{
  "family": "order-service",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "arn:aws:iam::123456789:role/ecs-execution-role",
  "taskRoleArn": "arn:aws:iam::123456789:role/order-service-task-role",
  "containerDefinitions": [
    {
      "name": "order-service",
      "image": "123456789.dkr.ecr.us-east-1.amazonaws.com/order-service:42",
      "portMappings": [{"containerPort": 8080, "protocol": "tcp"}],
      "environment": [
        {"name": "SPRING_PROFILES_ACTIVE", "value": "prod"},
        {"name": "SERVER_PORT", "value": "8080"}
      ],
      "secrets": [
        {
          "name": "SPRING_DATASOURCE_PASSWORD",
          "valueFrom": "arn:aws:secretsmanager:us-east-1:123456789:secret:/prod/order-service/db:password::"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/prod/order-service",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "healthCheck": {
        "command": ["CMD-SHELL", "curl -f http://localhost:8080/actuator/health || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      }
    }
  ]
}
```

---

### 16.4 Is Fargate Compatible with Jenkins?

**Yes, absolutely.** Jenkins deploys to ECS Fargate using AWS CLI commands in the pipeline.

```groovy
// Jenkinsfile stage for ECS Fargate deployment
stage('Deploy to ECS Fargate') {
    steps {
        sh """
            # Step 1: Register a new task definition revision with the new image tag
            TASK_DEF=\$(aws ecs describe-task-definition \
                --task-definition order-service \
                --query 'taskDefinition' \
                --output json)

            # Update the image in the task definition JSON
            NEW_TASK_DEF=\$(echo \$TASK_DEF | jq \
                '.containerDefinitions[0].image = "123456789.dkr.ecr.us-east-1.amazonaws.com/order-service:${BUILD_NUMBER}"' | \
                jq 'del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .compatibilities, .registeredAt, .registeredBy)')

            # Register the new task definition
            NEW_REVISION=\$(aws ecs register-task-definition \
                --cli-input-json "\$NEW_TASK_DEF" \
                --query 'taskDefinition.revision' \
                --output text)

            echo "Registered task definition revision: \$NEW_REVISION"

            # Step 2: Update the ECS Service to use the new task definition
            aws ecs update-service \
                --cluster prod-ecs-cluster \
                --service order-service \
                --task-definition order-service:\$NEW_REVISION \
                --desired-count 3

            # Step 3: Wait for deployment to complete
            aws ecs wait services-stable \
                --cluster prod-ecs-cluster \
                --services order-service

            echo "ECS Fargate deployment complete — order-service:${BUILD_NUMBER} is live"
        """
    }
}
```

**ECS vs EKS for Jenkins:**

| | ECS (Fargate) | EKS (Kubernetes) |
|---|---|---|
| Jenkins command to deploy | `aws ecs update-service` | `kubectl set image` |
| Complexity | Simple — one CLI command | More complex — kubectl + manifests |
| Jenkins plugin needed | AWS CLI (or ECS plugin) | kubectl + aws eks update-kubeconfig |

---

### 16.5 ECS Fargate vs EKS — When to Use Which

| Situation | Use ECS + Fargate | Use EKS |
|---|---|---|
| Small team, new to containers | ✅ | — |
| Simple microservices, no K8s expertise | ✅ | — |
| You need Kubernetes features (NetworkPolicy, CRDs, Helm) | — | ✅ |
| Multi-cloud or on-prem later | — | ✅ |
| CI/CD needs to stay simple | ✅ | — |
| Large org with K8s platform team | — | ✅ |

---

## 17. HOW JAVA MICROSERVICES CONNECT TO AWS SERVICES

> This section explains the WHY behind AWS authentication — why tokens exist, how IAM roles work, and exactly what happens when your Java app calls S3, Secrets Manager, or any other AWS service.

---

### 17.1 The Core Problem — Why Tokens Are Needed

**Without any auth:** Anyone who knows your S3 bucket name could read/write your files. AWS would have no way to charge you or protect your data.

**Solution:** Every call to any AWS API must be **signed** with credentials that prove who you are. AWS then checks: "Is this identity allowed to do this action on this resource?"

```
Your Java app calls: s3Client.getObject(bucket, key)
     ↓
AWS SDK signs the HTTP request with your credentials (creates a cryptographic signature)
     ↓
AWS receives the signed request
     ↓
AWS IAM verifies the signature and checks: 
  "Does the identity that signed this have s3:GetObject permission on this bucket?"
     ↓
  YES → returns the object
  NO  → AccessDeniedException (403)
```

---

### 17.2 Types of Credentials — How AWS Knows Who You Are

There are three main types:

**Type 1: IAM User — Long-term credentials (for developers on laptops)**
```
IAM User has:
  Access Key ID:     AKIAIOSFODNN7EXAMPLE   (like a username)
  Secret Access Key: wJalrXUtn.../...       (like a password — keep secret!)

Stored in: ~/.aws/credentials on your laptop
  [default]
  aws_access_key_id = AKIAIOSFODNN7EXAMPLE
  aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

Problem: If leaked (committed to GitHub) → anyone can use your AWS account
         These never expire → long-lived risk
         NEVER put these in application.properties or Dockerfile
```

**Type 2: IAM Role — Temporary credentials (for services/applications)**
```
IAM Role does NOT have an access key.
Instead, when your application ASSUMES a role, AWS's STS service issues:
  - Temporary Access Key ID
  - Temporary Secret Access Key
  - Session Token (extra security token)
  - Expiry time (15 minutes to 12 hours)

These temporary credentials:
  ✅ Auto-rotate → even if leaked, expire soon
  ✅ Scoped to only what the role allows
  ✅ No secret to manage — AWS handles it automatically
  ✅ Auditable in CloudTrail
```

**Type 3: Instance Profile / Task Role / IRSA — Auto-fetched credentials (zero config)**
```
EC2 Instance Profile:     EC2 gets temp credentials from metadata service automatically
ECS Task Role:            ECS task gets temp credentials from task metadata endpoint
EKS IRSA:                 K8s pod gets temp credentials via projected service account token
```

---

### 17.3 AWS Credentials Provider Chain

When your Java code calls `DefaultCredentialsProvider.create()`, the AWS SDK searches for credentials in this ORDER, using the first one it finds:

```
Priority 1: Environment variables
  AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
  → Used in Docker containers or CI/CD when set explicitly

Priority 2: Java system properties
  -Daws.accessKeyId=xxx -Daws.secretKey=xxx
  → Rarely used, mostly for legacy

Priority 3: AWS credentials file
  ~/.aws/credentials on developer laptops
  → Good for local development

Priority 4: AWS SSO (Single Sign-On)
  ~/.aws/sso/cache/xxx.json
  → Enterprise setups where devs log in via corporate SSO

Priority 5: ECS container credentials endpoint
  http://169.254.170.2/v2/credentials/<UUID>
  → Automatically used in ECS Fargate tasks (ECS Task Role)

Priority 6: EC2 Instance Metadata Service (IMDS)
  http://169.254.169.254/latest/meta-data/iam/security-credentials/
  → Automatically used in EC2 instances and EKS pods with IRSA

Priority 7: (None found) → throws SdkClientException
```

**What this means for your code:**
```java
// This ONE line works everywhere — laptop, EC2, EKS, ECS — no changes needed
S3Client s3 = S3Client.builder()
    .region(Region.US_EAST_1)
    .credentialsProvider(DefaultCredentialsProvider.create())  // auto-detects!
    .build();

// On developer laptop:   uses ~/.aws/credentials
// On Jenkins EC2:        uses EC2 instance profile (IAM Role on the EC2)
// On EKS pod:            uses IRSA (IAM Role linked to K8s ServiceAccount)
// On ECS Fargate task:   uses ECS Task Role
// → Same code, zero config changes between environments
```

---

### 17.4 IRSA — IAM Roles for Service Accounts (EKS Deep Dive)

This is how EKS pods get AWS credentials without any access keys. It's the production-standard way.

```
How IRSA works:

1. You create an IAM Role with the permissions your service needs
   e.g., "order-service-role" with policy: s3:GetObject on order-attachments-bucket

2. You create a K8s ServiceAccount annotated with that role ARN
3. Pods that use that ServiceAccount get a projected JWT token
4. AWS STS exchanges that JWT for temporary AWS credentials
5. AWS SDK finds these credentials automatically via Priority 6 in the chain

No access keys anywhere. Zero secrets to manage.
```

**Step 1: Create IAM Role (Terraform example):**
```hcl
resource "aws_iam_role" "order_service_role" {
  name = "order-service-role"
  
  # Trust policy: only EKS pods from our cluster can assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::123456789:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE:sub" =
            "system:serviceaccount:production:order-service-sa"  # only THIS serviceaccount
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "order_service_policy" {
  name = "order-service-permissions"
  role = aws_iam_role.order_service_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject"]
        Resource = "arn:aws:s3:::order-attachments-prod/*"
      },
      {
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue"]
        Resource = "arn:aws:secretsmanager:us-east-1:123456789:secret:/prod/order-service/*"
      },
      {
        Effect = "Allow"
        Action = ["sns:Publish"]
        Resource = "arn:aws:sns:us-east-1:123456789:order-events"
      }
    ]
  })
}
```

**Step 2: K8s ServiceAccount annotated with IAM Role:**
```yaml
# k8s/order-service/serviceaccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: order-service-sa
  namespace: production
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789:role/order-service-role
    # This annotation is the magic — EKS sees this and automatically
    # provides AWS credentials to pods using this ServiceAccount
```

**Step 3: Reference ServiceAccount in Deployment:**
```yaml
spec:
  template:
    spec:
      serviceAccountName: order-service-sa   # links to IAM Role via IRSA
      containers:
        - name: order-service
          ...
```

**Now your Java code just works:**
```java
// No credentials anywhere — IRSA provides them automatically
S3Client s3 = S3Client.builder()
    .region(Region.US_EAST_1)
    .credentialsProvider(DefaultCredentialsProvider.create())
    .build();

s3.getObject(GetObjectRequest.builder()
    .bucket("order-attachments-prod")
    .key("orders/ORD-123/invoice.pdf")
    .build());
```

---

### 17.5 IAM Roles and Policies — What to Set for Each Service

Think of an IAM Role as a **job description** and Policies as **specific permissions on that job**.

**Principle of Least Privilege:** Give each service ONLY the permissions it needs. Never use AdministratorAccess or wildcard (*) resources in production.

**order-service role — what it needs:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadWriteOrderAttachments",
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
      "Resource": "arn:aws:s3:::order-attachments-prod/*"
    },
    {
      "Sid": "ReadDBPassword",
      "Effect": "Allow",
      "Action": ["secretsmanager:GetSecretValue"],
      "Resource": "arn:aws:secretsmanager:us-east-1:123456789:secret:/prod/order-service/db-*"
    },
    {
      "Sid": "PublishOrderEvents",
      "Effect": "Allow",
      "Action": ["sns:Publish"],
      "Resource": "arn:aws:sns:us-east-1:123456789:order-events"
    },
    {
      "Sid": "SendOrderEmails",
      "Effect": "Allow",
      "Action": ["ses:SendEmail"],
      "Resource": "arn:aws:ses:us-east-1:123456789:identity/orders@myapp.com"
    }
  ]
}
```

**customer-service role — different service, different permissions:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadCustomerDocuments",
      "Effect": "Allow",
      "Action": ["s3:GetObject"],
      "Resource": "arn:aws:s3:::customer-documents-prod/*"
    },
    {
      "Sid": "ReadDBPassword",
      "Effect": "Allow",
      "Action": ["secretsmanager:GetSecretValue"],
      "Resource": "arn:aws:secretsmanager:us-east-1:123456789:secret:/prod/customer-service/db-*"
    }
  ]
}
```

Notice: customer-service cannot publish to order-events SNS. order-service cannot read customer documents. **Each service only has access to what it owns.**

---

### 17.6 Complete Java Service → AWS Service Connection Example

```java
// Complete production-ready setup for order-service connecting to S3 and Secrets Manager

@Configuration
public class AwsConfig {

    @Value("${cloud.aws.region:us-east-1}")
    private String region;

    @Bean
    public S3Client s3Client() {
        return S3Client.builder()
                .region(Region.of(region))
                // DefaultCredentialsProvider checks credentials in priority order:
                // local dev:    ~/.aws/credentials (your IAM user)
                // EC2:          instance profile
                // EKS pod:      IRSA token (IAM Role linked to ServiceAccount)
                // ECS task:     task role
                // → same code everywhere, zero changes between environments
                .credentialsProvider(DefaultCredentialsProvider.create())
                .build();
    }

    @Bean
    public SecretsManagerClient secretsManagerClient() {
        return SecretsManagerClient.builder()
                .region(Region.of(region))
                .credentialsProvider(DefaultCredentialsProvider.create())
                .build();
    }
}

@Service
public class OrderAttachmentService {

    private final S3Client s3Client;
    private final SecretsManagerClient secretsManager;

    @Value("${aws.s3.bucket:order-attachments-prod}")
    private String bucket;

    public OrderAttachmentService(S3Client s3Client, SecretsManagerClient secretsManager) {
        this.s3Client = s3Client;
        this.secretsManager = secretsManager;
    }

    // Upload order attachment to S3
    public String uploadAttachment(String orderId, MultipartFile file) throws IOException {
        String key = "orders/" + orderId + "/" + UUID.randomUUID() + "_" + file.getOriginalFilename();

        s3Client.putObject(
            PutObjectRequest.builder()
                .bucket(bucket)
                .key(key)
                .contentType(file.getContentType())
                .serverSideEncryption(ServerSideEncryption.AES256)  // encrypt at rest
                .build(),
            RequestBody.fromBytes(file.getBytes())
        );
        return key;
    }

    // Get a temporary download URL (expires in 60 min)
    public String generatePresignedUrl(String key) {
        S3Presigner presigner = S3Presigner.builder()
            .region(Region.of("us-east-1"))
            .credentialsProvider(DefaultCredentialsProvider.create())
            .build();

        PresignedGetObjectRequest presignedRequest = presigner.presignGetObject(r -> r
            .getObjectRequest(g -> g.bucket(bucket).key(key))
            .signatureDuration(Duration.ofHours(1))
        );

        return presignedRequest.url().toString();
    }

    // Read a secret from Secrets Manager (e.g., third-party API key)
    public String getSecret(String secretPath) {
        GetSecretValueResponse response = secretsManager.getSecretValue(
            GetSecretValueRequest.builder()
                .secretId(secretPath)
                .build()
        );
        return response.secretString();
    }
}
```

---

### 17.7 Interview Questions on AWS Auth

**Q: Why not put AWS credentials in application.properties?**
> Because application.properties is checked into Git. Any developer, CI tool, or attacker with repo access gets permanent AWS credentials. Use IAM Roles with temporary credentials instead — no secrets in code ever.

**Q: What is the difference between Execution Role and Task Role in Lambda/ECS?**
> - **Execution Role:** Used by the Lambda/ECS infrastructure itself — to pull the Docker image from ECR, write logs to CloudWatch. AWS manages this.
> - **Task Role (Lambda: Execution Role called "Function Role"):** Used by YOUR APPLICATION CODE — to call S3, Secrets Manager, SNS, etc. This is what you configure with the permissions your service needs.

**Q: How does an EKS pod get AWS credentials without any access key?**
> Via IRSA (IAM Roles for Service Accounts). The K8s ServiceAccount is annotated with an IAM Role ARN. EKS's webhook injects a projected JWT token into the pod. The AWS SDK exchanges that JWT with AWS STS for temporary credentials. Your app calls DefaultCredentialsProvider.create() and the SDK finds these credentials automatically from the pod's metadata endpoint.

**Q: What happens if you give a service * (wildcard) resource in its IAM policy?**
> It can access ALL resources of that type in your account — all S3 buckets, all secrets, all SNS topics. If that service is compromised, the attacker has access to everything. Always use specific resource ARNs (Principle of Least Privilege).

---

*This guide covers what you need as a Java fullstack developer for AWS interviews. Focus especially on the Architecture section (IAM, VPC, Security Groups), EC2, S3, CI/CD with Jenkins, and the new sections on Logging, Failure Debugging, and AWS Authentication — these come up in almost every senior interview. The scenario questions at the end represent how real interviews are structured.*

---

## 18. END-TO-END DEPLOYMENT FLOW — DEV AND PROD

> This section walks through the COMPLETE journey of code from a developer's laptop all the way to production. Every AWS service touched is shown with exact console navigation steps so you know exactly where to go and what to click.

---

### 18.1 The Architecture — What DEV and PROD Look Like

```
───────────────────────────── DEV ENVIRONMENT ────────────────────────────────

Developer Laptop
  └─ git push origin develop
          │
          ▼
    GitHub (develop branch)
          │  webhook
          ▼
    Jenkins CI Server (EC2 t3.large)
      ├─ mvn clean package (build + test)
      ├─ docker build
      ├─ docker push → ECR (dev-order-service repo)
      └─ kubectl apply → EKS dev cluster (namespace: development)
                              │
                    ┌─────────┴─────────┐
                    │  EKS Dev Cluster   │
                    │  namespace: dev    │
                    │  replicas: 1       │
                    │  t3.medium nodes   │
                    └─────────┬─────────┘
                              │
                    ALB (dev-alb) → dev.api.myapp.com
                              │
                    RDS PostgreSQL (db.t3.small, single AZ)
                    Secrets Manager (/dev/order-service/db)

───────────────────────────── PROD ENVIRONMENT ───────────────────────────────

Developer Laptop
  └─ git push origin main (or PR merged to main)
          │
          ▼
    GitHub (main branch)
          │  webhook
          ▼
    Jenkins CI Server (same, but different pipeline)
      ├─ mvn clean package
      ├─ SonarQube SAST check
      ├─ docker build --platform=linux/amd64
      ├─ docker push → ECR (prod-order-service repo)
      ├─ ECR vulnerability scan (block on CRITICAL CVEs)
      ├─ kubectl apply → EKS STAGING cluster → smoke test → DAST
      └─ kubectl apply → EKS PROD cluster (namespace: production)
                              │
                    ┌─────────┴──────────────────────┐
                    │    EKS Prod Cluster             │
                    │    namespace: production        │
                    │    replicas: 3 (multi-AZ)       │
                    │    m5.large nodes               │
                    │    HPA: scale 3→15 on CPU>70%   │
                    └─────────┬──────────────────────┘
                              │
                    ALB (prod-alb) → api.myapp.com
                    WAF (Web Application Firewall)
                    CloudFront (optional CDN layer)
                              │
                    RDS PostgreSQL Multi-AZ (db.r5.large)
                    ElastiCache Redis (for caching)
                    Secrets Manager (/prod/order-service/db)
                    CloudWatch Logs (via Fluent Bit)
```

---

### 18.2 Step-by-Step Console Navigation for Each AWS Service

This is exactly what you'd do manually (or verify in the console) for each service in the deployment.

---

#### ECR — Elastic Container Registry

**Scenario: Verify your Docker image was pushed correctly**

```
AWS Console → Services → ECR (Elastic Container Registry)
  → Repositories
  → Click "order-service"                         ← your repo
  → Images tab
  → Find your image by tag (e.g., :42)
  → Check columns:
      Image URI: 123456789.dkr.ecr.us-east-1.amazonaws.com/order-service:42
      Push date:  2024-01-15  10:30:00
      Size:       145 MB
      Scan status: Complete — 0 Critical, 0 High    ← check this!

If scan status shows "Failed" or has CRITICAL findings:
  → Click on the image tag
  → "Scan results" tab → see exactly which package has the vulnerability
  → Fix in Dockerfile (update base image or dependency) and push again
```

**Scenario: Change lifecycle policy (keep only last 10 images)**

```
ECR → Repositories → order-service
  → Lifecycle Policy tab → Edit lifecycle policy
  → Add rule:
      Rule priority: 1
      Description: Keep last 10 images
      Image status: Any
      Match criteria: Image count more than 10
      Action: Expire
  → Save
```

---

#### S3 — Changing Storage Class of Objects

**Scenario: Move old logs to cheaper storage (Glacier)**

```
AWS Console → Services → S3
  → Find and click your bucket (e.g., "myapp-logs-prod")
  → Objects tab → navigate to folder (e.g., "logs/2023/")
  → Select objects (tick checkbox) or "Select all"
  → Actions dropdown → Change storage class
  → Choose: S3 Glacier Flexible Retrieval
  → Click "Change storage class"

--- OR set a Lifecycle Rule (recommended — automates this) ---

S3 → your bucket → Management tab → Create lifecycle rule
  → Rule name: "archive-old-logs"
  → Apply to all objects in bucket: YES (or specify prefix "logs/")
  → Lifecycle rule actions:
      ✅ Transition current versions to another storage class
  → Add transition:
      Days after object creation: 30
      Storage class: S3 Standard-IA
  → Add another transition:
      Days after object creation: 90
      Storage class: S3 Glacier Flexible Retrieval
  → Create rule
```

**Scenario: Enable versioning on a bucket**

```
S3 → your bucket → Properties tab
  → Bucket Versioning section → Edit
  → Enable → Save changes
```

**Scenario: Configure S3 static website hosting for Angular app**

```
S3 → your bucket → Properties tab → Static website hosting → Edit
  → Enable
  → Index document: index.html
  → Error document: index.html  (needed for Angular routing)
  → Save changes

Then set bucket policy to allow public read:
  S3 → your bucket → Permissions tab → Bucket policy → Edit
  → Paste the policy:
    {
      "Version": "2012-10-17",
      "Statement": [{
        "Effect": "Allow",
        "Principal": "*",
        "Action": "s3:GetObject",
        "Resource": "arn:aws:s3:::your-bucket-name/*"
      }]
    }
  → Save
```

---

#### Secrets Manager — Viewing and Rotating Secrets

**Scenario: Check what secret value is stored for a service**

```
AWS Console → Services → Secrets Manager
  → Secrets (left menu)
  → Search for "/prod/order-service/db"
  → Click on the secret
  → Secret value section → Retrieve secret value
  → Shows: {"username": "orders_user", "password": "****"}
  → Click "Show" to reveal password

To rotate the secret automatically:
  → Rotation tab → Enable automatic rotation
  → Rotation schedule: Every 30 days
  → Lambda function: Use a managed rotation function
  → Save
```

---

#### EKS — Verifying Deployment in Console

**Scenario: Check pod status after deployment**

```
AWS Console → Services → EKS (Elastic Kubernetes Service)
  → Clusters
  → Click "prod-eks-cluster"
  → Workloads tab (left menu)
  → Filter by namespace: production
  → Find "order-service" deployment
  → Click it → Pods tab
  → See all 3 pods:
      order-service-7d9f8b-abc12  Running  1/1
      order-service-7d9f8b-def34  Running  1/1
      order-service-7d9f8b-ghi56  Running  1/1
  → Click on any pod → Logs tab → See live logs

But ALWAYS prefer kubectl for this — console is slow.
```

---

#### RDS — Database Monitoring

**Scenario: Check database performance**

```
AWS Console → Services → RDS
  → Databases
  → Click your DB identifier (e.g., "orders-prod-db")
  → Monitoring tab
  → See metrics:
      CPUUtilization: 23%       ← OK (alert if >80%)
      DatabaseConnections: 45   ← OK (alert if near max)
      FreeStorageSpace: 50 GB   ← OK (alert if <10 GB)
      ReadLatency: 0.001s       ← OK (alert if >0.1s)
      WriteLatency: 0.002s      ← OK
  → Logs & events tab → see DB error logs
  → Configuration tab → shows instance class, storage type, Multi-AZ status
```

---

### 18.3 Full DEV Deployment Walk-Through

**Developer pushes code to develop branch:**

```
Step 1 — Developer machine
  git commit -m "feat: add order search endpoint"
  git push origin develop

Step 2 — GitHub
  GitHub detects push to "develop"
  GitHub sends webhook HTTP POST to Jenkins:
    POST http://jenkins-server:8080/github-webhook/
    Body: {ref: "refs/heads/develop", commits: [...]}

Step 3 — Jenkins (pipeline triggered)
  a. Checkout code from GitHub develop branch
  b. mvn clean package -DskipTests=false
      → compile, run unit tests, integration tests
      → if tests fail → pipeline stops, Slack notification
  c. docker build --platform=linux/amd64 -t order-service:${BUILD_NUMBER} .
  d. aws ecr get-login-password | docker login ...
  e. docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/dev-order-service:${BUILD_NUMBER}
  f. aws eks update-kubeconfig --name dev-eks-cluster
  g. kubectl set image deployment/order-service \
       order-service=123456789.dkr.ecr.us-east-1.amazonaws.com/dev-order-service:${BUILD_NUMBER} \
       -n development
  h. kubectl rollout status deployment/order-service -n development --timeout=180s
  i. Smoke test: curl http://dev.api.myapp.com/actuator/health

Step 4 — EKS Dev Cluster
  K8s starts rolling update:
    → New pod created with new image
    → Health checks run (startupProbe, readinessProbe)
    → If ready: old pod is terminated
    → Repeat for each pod (but dev has only 1 replica)

Step 5 — Application is live
  Developer or QA accesses: http://dev.api.myapp.com/api/orders
  Logs visible in: CloudWatch Logs → /eks/dev/order-service
```

---

### 18.4 Full PROD Deployment Walk-Through

```
Step 1 — PR merged to main
  PR reviewed and approved → merge to main branch

Step 2 — Jenkins prod pipeline triggered
  a. Checkout main branch
  b. mvn clean package (build + full test suite)
  c. SonarQube SAST scan + Quality Gate check
      → Coverage < 80% or new vulnerabilities → STOP
  d. docker build --platform=linux/amd64
  e. docker push to prod ECR repo
  f. aws ecr wait image-scan-complete ...
      → Wait for ECR vulnerability scan
      → CRITICAL CVEs found → STOP
  g. Deploy to STAGING namespace
  h. Run smoke tests on staging
  i. Run OWASP ZAP DAST scan on staging
      → HIGH/CRITICAL security findings → STOP
  j. Deploy to PRODUCTION namespace:
      kubectl set image deployment/order-service ...
      kubectl rollout status ... --timeout=300s
  k. Production smoke test
  l. Slack: "order-service #42 deployed to production"

Step 3 — K8s Rolling Update in Production
  Before:  [v1-pod-1] [v1-pod-2] [v1-pod-3]    ← 3 pods serving traffic
  
  K8s adds new pod: (maxSurge=1)
           [v1-pod-1] [v1-pod-2] [v1-pod-3] [v2-pod-1-starting]
  
  v2-pod-1 passes startupProbe (up to 300s):
           [v1-pod-1] [v1-pod-2] [v1-pod-3] [v2-pod-1-ready]
  
  v2-pod-1 passes readinessProbe → ALB starts sending traffic to it
  K8s terminates v1-pod-1: (maxUnavailable=0 → always 3+ ready)
           [v1-pod-2] [v1-pod-3] [v2-pod-1] [v2-pod-2-starting]
  
  → Repeat until all 3 pods are v2
  After:   [v2-pod-1] [v2-pod-2] [v2-pod-3]    ← new version serving traffic

Step 4 — Monitoring (first 30 min after deploy)
  Watch these in CloudWatch / Grafana:
  → Error rate: should stay < 0.1% (5xx responses from ALB)
  → Latency (p99): should be similar to before deploy
  → CPU/memory: should settle within 5 min
  → Pod logs: no WARN/ERROR spike
  If something goes wrong:
    Jenkins post-failure block runs:
    kubectl rollout undo deployment/order-service -n production
    → K8s rolls back to previous image immediately
```

---

### 18.5 Environment Differences — DEV vs PROD

| Aspect | DEV | PROD |
|--------|-----|------|
| EKS cluster | dev-eks-cluster | prod-eks-cluster |
| Namespace | development | production |
| Replicas | 1 | 3 (multi-AZ) |
| Node type | t3.medium | m5.large |
| RDS | db.t3.small, single AZ | db.r5.large, Multi-AZ |
| DB name | /dev/order-service/db | /prod/order-service/db |
| ECR repo | dev-order-service | order-service |
| ALB | dev-alb | prod-alb |
| CloudWatch log group | /eks/dev/order-service | /eks/prod/order-service |
| Pipeline | No SAST/DAST/ECR scan | Full security gates |
| HPA | No | Yes (3→15 pods) |
| PDB | No | Yes (minAvailable: 2) |

---

## 19. ALB — APPLICATION LOAD BALANCER IN DEPTH

> ALB (Application Load Balancer) is what receives internet traffic and distributes it to your pods/EC2 instances. It operates at Layer 7 (HTTP/HTTPS) so it can make routing decisions based on URL path, host, headers, and query strings.

---

### 19.1 Why ALB Exists

```
WITHOUT ALB:
  Users → EC2 instance IP address (fixed, single point of failure)
  → If that EC2 dies, your app is down
  → No way to handle 1000 users hitting 1 server

WITH ALB:
  Users → ALB DNS name (e.g., myapp-alb-123456.us-east-1.elb.amazonaws.com)
  → ALB distributes to any of: [EC2-1, EC2-2, EC2-3] or [Pod-1, Pod-2, Pod-3]
  → If one instance fails: ALB detects via health check, stops routing to it
  → Scale to 100 EC2s — ALB automatically balances across all of them
```

**ALB Key Features:**
- **Path-based routing:** `/api/orders/*` → order-service, `/api/customers/*` → customer-service
- **Host-based routing:** `api.myapp.com` → backend, `app.myapp.com` → frontend  
- **HTTPS termination:** ALB handles SSL/TLS, your app only needs HTTP
- **Health checks:** Automatically removes unhealthy targets
- **Sticky sessions:** Same user always goes to same backend (for stateful apps)
- **Access logs:** Log every request with timestamp, IP, status, latency

---

### 19.2 Creating ALB via AWS Console (Step by Step)

```
AWS Console → Services → EC2 → Load Balancers (left menu) → Create load balancer
  → Choose type: Application Load Balancer → Create

─── BASIC CONFIGURATION ──────────────────────────────────────────────────────
  Name: prod-order-alb
  Scheme: Internet-facing     ← accessible from internet (for production APIs)
           Internal           ← only accessible within VPC (for internal services)
  IP address type: IPv4

─── NETWORK MAPPING ──────────────────────────────────────────────────────────
  VPC: prod-vpc
  Mappings (select at least 2 AZs for high availability):
    ✅ us-east-1a → Public Subnet 1a (10.0.1.0/24)
    ✅ us-east-1b → Public Subnet 1b (10.0.2.0/24)
    ✅ us-east-1c → Public Subnet 1c (10.0.3.0/24)

─── SECURITY GROUPS ──────────────────────────────────────────────────────────
  Remove default security group
  Add: alb-sg
    Inbound rules:
      HTTP  port 80   source: 0.0.0.0/0   (everyone on internet)
      HTTPS port 443  source: 0.0.0.0/0   (everyone on internet)

─── LISTENERS AND ROUTING ────────────────────────────────────────────────────
  Listener 1:
    Protocol: HTTP  Port: 80
    Default action: Redirect to HTTPS (port 443)
  
  Listener 2:
    Protocol: HTTPS  Port: 443
    Default action: Forward to target group → Create target group (see below)

─── SSL CERTIFICATE (for HTTPS listener) ─────────────────────────────────────
  Certificate source: ACM (AWS Certificate Manager)
  Certificate: *.myapp.com (wildcard cert)
    → If you don't have one: 
       ACM → Request certificate → Request public certificate
       → Domain name: *.myapp.com and myapp.com
       → Validation method: DNS validation
       → Create records in Route 53 → Certificate issued in ~5 min

─── REVIEW AND CREATE ────────────────────────────────────────────────────────
  → Create load balancer
  → Wait 3-5 min for ALB to become "Active"
  → Note the DNS name: prod-order-alb-123456.us-east-1.elb.amazonaws.com
```

---

### 19.3 Target Groups — Where ALB Sends Traffic

A target group defines the set of targets (EC2 instances, pods, IPs) that receive traffic.

```
ALB Console → Target Groups → Create target group

─── TARGET GROUP FOR order-service ──────────────────────────────────────────
  Target type: IP   ← for EKS pods (pod IPs change constantly)
               Instance ← for EC2 instances (more common for non-K8s)
  
  Name: prod-order-service-tg
  Protocol: HTTP
  Port: 8080   ← the port your Spring Boot app listens on
  VPC: prod-vpc
  Protocol version: HTTP1

─── HEALTH CHECK ─────────────────────────────────────────────────────────────
  Protocol: HTTP
  Path: /actuator/health        ← Spring Boot Actuator health endpoint
  Port: Traffic port (8080)
  Healthy threshold:   2        ← 2 consecutive successes = healthy
  Unhealthy threshold: 2        ← 2 consecutive failures = unhealthy (remove from rotation)
  Timeout: 5 seconds
  Interval: 15 seconds          ← check every 15 seconds
  Success codes: 200            ← 200 OK = healthy

─── REGISTER TARGETS ─────────────────────────────────────────────────────────
  For EKS (Kubernetes): targets are registered automatically by the
  AWS Load Balancer Controller when you apply the Ingress manifest.
  You don't register manually.
  
  For EC2: 
  → Select your EC2 instances → Include as pending → Create target group
```

---

### 19.4 Listener Rules — Path-Based Routing

```
ALB → Your ALB → Listeners tab → Click "HTTPS:443" → Manage rules

─── DEFAULT RULE (at bottom) ────────────────────────────────────────────────
  IF: (no condition) THEN: Return 404 fixed response

─── ADD CUSTOM RULES (above default) ────────────────────────────────────────
  Rule 1 (priority 1):
    IF: Path is "/api/orders/*"
    THEN: Forward to → prod-order-service-tg

  Rule 2 (priority 2):
    IF: Path is "/api/customers/*"
    THEN: Forward to → prod-customer-service-tg

  Rule 3 (priority 3):
    IF: Path is "/actuator/health"
    THEN: Forward to → prod-order-service-tg  (for monitoring)
    
  Rule 4 (priority 99, default):
    IF: (catches everything else)
    THEN: Return 404
```

**Interview tip:** In EKS, you don't set these rules manually. The AWS Load Balancer Controller reads your `Ingress` YAML and creates/updates the ALB rules automatically.

---

### 19.5 ALB Access Logs

Access logs record every single request to your ALB — time, client IP, request, response code, latency.

```
ALB Console → Your ALB → Attributes tab → Edit
  → Access logs: Enable
  → S3 location: s3://myapp-alb-logs-prod/order-alb/
  → Save changes

Access log format (each line):
  2024-01-15T10:30:45.123Z  https  200  client:1.2.3.4  
  GET /api/orders/42  0.034 (response time in seconds)
  user-agent: Mozilla/5.0...

Where to find: S3 → myapp-alb-logs-prod → order-alb → year/month/day
Use Athena to query these logs with SQL if you need analysis.
```

---

### 19.6 How In-Cluster Services Use ALB (Kubernetes Ingress)

In EKS, the **AWS Load Balancer Controller** watches your `Ingress` resources and automatically manages the ALB. You never manually configure the ALB — the Kubernetes manifest IS your configuration.

```yaml
# This YAML → AWS Load Balancer Controller reads it → creates/updates the ALB automatically
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: production-ingress
  namespace: production
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip       # route to pod IPs directly
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443},{"HTTP":80}]'
    alb.ingress.kubernetes.io/ssl-redirect: "443"   # redirect HTTP→HTTPS
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:...
    alb.ingress.kubernetes.io/healthcheck-path: /actuator/health
    alb.ingress.kubernetes.io/healthcheck-interval-seconds: "15"
    alb.ingress.kubernetes.io/healthy-threshold-count: "2"
    alb.ingress.kubernetes.io/unhealthy-threshold-count: "2"
    alb.ingress.kubernetes.io/load-balancer-attributes: |
      access_logs.s3.enabled=true,
      access_logs.s3.bucket=myapp-alb-logs-prod,
      access_logs.s3.prefix=order-alb
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

---

### 19.7 Common ALB Interview Questions

**Q: What is the difference between ALB and NLB (Network Load Balancer)?**
```
ALB (Application Load Balancer):
  → Layer 7 (HTTP/HTTPS) — understands URLs, headers, cookies
  → Can route /api/orders to service A and /api/customers to service B
  → Supports WebSocket, HTTP/2
  → Use for: REST APIs, web apps, microservices

NLB (Network Load Balancer):
  → Layer 4 (TCP/UDP) — does not understand HTTP
  → Routes based on IP + port only
  → Extremely low latency (microseconds)
  → Preserves client IP address (ALB does not)
  → Use for: databases, gaming servers, raw TCP connections, IoT
```

**Q: How does ALB health check work?**
```
Every 15 seconds (configurable), ALB sends HTTP GET to /actuator/health on each target.
  → 200 response received: target is healthy, ALB routes traffic to it
  → Non-200 or timeout: mark as "1 failure"
  → After 2 consecutive failures: unhealthy → ALB stops routing to that target
  → After 2 consecutive successes: healthy again → ALB resumes routing

This is why Spring Boot Actuator /actuator/health is critical in production.
If your app gets into a bad state (DB down, out of memory), make the health
endpoint return 503 so ALB removes you from rotation.
```

**Q: A pod is running but users are getting 503 errors from the ALB. What do you check?**
```
Step 1: kubectl get pods -n production
  → Is the pod Running? Status = Running, Ready = 1/1?

Step 2: Check Target Group health
  ALB → Target Groups → prod-order-service-tg → Targets tab
  → See if targets (pod IPs) show "healthy" or "unhealthy"
  → If unhealthy: expand the row → see health check failure reason:
      "Health checks failed with these codes: [503]" → app is returning 503 from /actuator/health
      "Request timed out" → app is not responding

Step 3: kubectl logs <pod-name> -n production | grep -i error
  → Look for errors in your app logs

Step 4: kubectl exec -it <pod-name> -n production -- sh
  → curl localhost:8080/actuator/health
  → See the raw response — database DOWN? Redis DOWN?
```

---

## 20. CLOUDWATCH — LOGS, ALARMS AND ALERTS

> CloudWatch is AWS's central monitoring service. It collects logs, metrics, and lets you set up alarms to notify you when something goes wrong. As a developer, you use it to see what your app is doing in production — and to get paged when it breaks.

---

### 20.1 CloudWatch Core Concepts

```
CloudWatch
  ├─ Logs
  │    ├─ Log Group: container for related log streams
  │    │     e.g., /eks/prod/order-service
  │    ├─ Log Stream: one source of log events
  │    │     e.g., order-service-pod-abc123  (one per pod)
  │    └─ Log Events: individual log lines with timestamps
  │
  ├─ Metrics: numeric measurements over time
  │     e.g., EC2 CPUUtilization, ALB RequestCount, RDS DatabaseConnections
  │
  ├─ Alarms: watch a metric, trigger action when threshold is crossed
  │     e.g., "If EC2 CPU > 80% for 5 min → notify via SNS"
  │
  └─ Logs Insights: SQL-like query engine over your logs
        e.g., "Find all ERROR logs with traceId=abc in last 1 hour"
```

---

### 20.2 How to View Logs in CloudWatch Console (Step by Step)

**Scenario: Your app is throwing errors in production. Find the logs.**

```
AWS Console → Services → CloudWatch
  → Logs (left menu) → Log groups
  → Search for: /eks/prod/order-service
  → Click on the log group

─── LOG STREAMS ──────────────────────────────────────────────────────────────
  You'll see a list of log streams — one per pod per day:
    2024/01/15/[app]abc12345  (pod order-service-7d9f8b-abc12)
    2024/01/15/[app]def67890  (pod order-service-7d9f8b-def34)
  
  Click on the most recent stream → see live logs

─── FILTER / SEARCH within a log stream ─────────────────────────────────────
  Filter events box (top right):
    Type: ERROR         ← shows only lines containing "ERROR"
    Type: ?WARN ?ERROR  ← shows lines with WARN or ERROR

─── USE LOG INSIGHTS INSTEAD (much more powerful) ────────────────────────────
  CloudWatch → Logs → Logs Insights
  → Select log group(s): /eks/prod/order-service
  → Time range: Last 1 hour
  → Type your query → Run query
```

---

### 20.3 CloudWatch Logs Insights — Essential Queries

**Find all errors in the last hour:**
```sql
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 100
```

**Find all logs for a specific request (by traceId):**
```sql
fields @timestamp, @message, @logStream
| filter @message like "a1b2c3d4e5f6"     -- your traceId
| sort @timestamp asc
```

**Find all logs for a specific user:**
```sql
fields @timestamp, @message
| filter @message like "userId=12345"
| sort @timestamp asc
| limit 200
```

**Count errors per minute (to find the exact time of an incident):**
```sql
filter @message like /ERROR/
| stats count() as errorCount by bin(1m)
| sort @timestamp asc
```

**Find slow requests (over 2 seconds) in access logs:**
```sql
fields @timestamp, @message
| filter @message like /Completed in/ 
| parse @message "Completed in * ms" as duration
| filter duration > 2000
| sort duration desc
| limit 50
```

**Find OOMKilled events across all pods:**
```sql
fields @timestamp, @message
| filter @message like /OOMKilled/ or @message like /OutOfMemoryError/
| sort @timestamp desc
```

**Search ACROSS MULTIPLE log groups at once (multi-service debugging):**
```
Logs Insights → Log groups selector → Add multiple:
  /eks/prod/order-service
  /eks/prod/customer-service
  /eks/prod/payment-service
→ All their logs searched together

fields @timestamp, @logStream, @message
| filter @message like "a1b2c3d4"   -- traceId appears in all of them
| sort @timestamp asc
```

---

### 20.4 Setting Up CloudWatch Alarms (Step by Step)

An alarm watches a metric and triggers an action (send email, trigger Lambda, scale EC2).

**Scenario: Alert when your EC2 CPU is above 80%**

```
CloudWatch → Alarms → Create alarm → Select metric

─── STEP 1: SELECT METRIC ────────────────────────────────────────────────────
  → Browse metrics → EC2 → Per-Instance Metrics
  → Find your instance ID → CPUUtilization → Select metric
  → Metric name: CPUUtilization
  → Period: 5 minutes (evaluation period)
  → Statistic: Average

─── STEP 2: DEFINE CONDITIONS ────────────────────────────────────────────────
  Threshold type: Static
  Alarm condition: Greater/Equal (≥)
  Threshold value: 80           ← alert when CPU ≥ 80%
  Datapoints to alarm: 2 out of 2
    (must stay above 80% for TWO consecutive 5-min periods = 10 min)
    This avoids false alarms from brief CPU spikes

─── STEP 3: CONFIGURE ACTIONS ────────────────────────────────────────────────
  Alarm state trigger: In alarm
  Send notification to: Create new SNS topic
    Topic name: prod-alerts
    Email endpoint: your-team@company.com   ← emails this address when alarm fires
  → Create topic

─── STEP 4: NAME AND DESCRIPTION ─────────────────────────────────────────────
  Alarm name: "EC2-order-service-cpu-high"
  Description: "CPU above 80% for 10 min — investigate scaling or performance issue"

─── STEP 5: CREATE ───────────────────────────────────────────────────────────
  → Create alarm
  → Alarm starts in "Insufficient data" state (no data yet)
  → After 10 min of data: moves to "OK" or "ALARM"

State colors:
  GREEN (OK):           Metric is below threshold — all good
  RED (ALARM):          Metric crossed threshold — action triggered
  GREY (Insufficient):  No data collected yet
```

---

### 20.5 SNS — How Alarm Notifications Are Sent

SNS (Simple Notification Service) is the messaging layer between CloudWatch alarms and your notification channels (email, Slack, PagerDuty, SMS).

```
CloudWatch Alarm → fires → SNS Topic → delivers to:
  ├─ Email subscription: team@company.com
  ├─ Lambda subscription: post to Slack webhook
  ├─ SQS subscription: queue the alert for processing
  └─ HTTP subscription: call PagerDuty API

Setting up email alerts:
  SNS → Topics → Create topic
  → Type: Standard
  → Name: prod-alerts
  → Create topic

  → Subscriptions → Create subscription
  → Protocol: Email
  → Endpoint: your-email@company.com
  → Create subscription
  → CHECK YOUR EMAIL → confirm the subscription link
  (CloudWatch alarm will now email this address when it fires)
```

**Slack alert via Lambda (common real-world setup):**
```
1. Create Lambda function that calls Slack webhook:
   def handler(event, context):
       message = json.loads(event['Records'][0]['Sns']['Message'])
       requests.post(SLACK_WEBHOOK_URL, json={
           "text": f"🚨 ALARM: {message['AlarmName']}\n{message['NewStateReason']}"
       })

2. Create SNS subscription:
   SNS → prod-alerts topic → Create subscription
   → Protocol: Lambda
   → Endpoint: arn:aws:lambda:...:slack-alert-lambda

Now when alarm fires: CloudWatch → SNS → Lambda → Slack
```

---

### 20.6 Important Alarms Every Developer Should Know About

| Alarm | Metric | Threshold | Why |
|-------|--------|-----------|-----|
| EC2 CPU high | EC2 CPUUtilization | > 80% for 10 min | App under load or stuck thread |
| EC2 memory | CloudWatch Agent MemoryUtilization | > 85% | Risk of OOMKill |
| ALB 5xx errors | ALB HTTPCode_ELB_5XX_Count | > 10 in 5 min | App is crashing/throwing 500s |
| ALB latency | ALB TargetResponseTime | > 2 seconds (p99) | App is slow — check DB, threads |
| ALB 4xx errors | ALB HTTPCode_Target_4XX_Count | > 100 in 1 min | Clients hitting bad endpoints |
| RDS CPU | RDS CPUUtilization | > 80% | DB under load |
| RDS connections | RDS DatabaseConnections | > 80% of max | Connection pool exhausted |
| RDS free storage | RDS FreeStorageSpace | < 10 GB | DB about to run out of disk |
| Pod restarts | K8s pod restart count (via Container Insights) | > 3 in 1 hour | CrashLoopBackOff starting |
| SQS queue depth | SQS ApproximateNumberOfMessagesVisible | > 1000 | Messages not being consumed |

---

### 20.7 CloudWatch Container Insights — Pod-Level Monitoring on EKS

Container Insights is AWS's out-of-the-box monitoring for EKS/ECS — it automatically collects CPU, memory, network, and disk metrics per pod, per node, and per cluster.

**Enable Container Insights:**
```
AWS Console → CloudWatch → Container Insights → View dashboard
  (If not enabled yet)
  aws eks create-addon --cluster-name prod-eks-cluster \
    --addon-name amazon-cloudwatch-observability \
    --region us-east-1

Then navigate to:
  CloudWatch → Container Insights → Performance monitoring
  → Select: EKS Pods
  → Cluster: prod-eks-cluster
  → Namespace: production
  → Pod: order-service-7d9f8b-abc12

  See: CPU usage, memory usage, network in/out, disk read/write
  All without any custom setup on your part.
```

**Viewing pod logs from Container Insights:**
```
CloudWatch → Container Insights → Performance monitoring
  → Find your pod → Click Actions → View logs
  → Redirects to CloudWatch Logs for that pod's log stream
```

---

### 20.8 What to Check When Production Crashes — CloudWatch Checklist

When you get an alert at 2am that production is down, here is the EXACT sequence:

```
─── IMMEDIATE (first 2 minutes) ──────────────────────────────────────────────
1. kubectl get pods -n production
   → Any CrashLoopBackOff or OOMKilled? → start there (Section 12)

2. Check ALB metrics:
   CloudWatch → Metrics → ApplicationELB → Per AppELB
   → HTTPCode_ELB_5XX_Count: spike? (production crash)
   → TargetResponseTime: spike? (production slowdown)

3. Check CloudWatch Logs Insights (last 15 min):
   fields @timestamp, @message
   | filter @message like /ERROR/ or @message like /FATAL/
   | sort @timestamp desc
   | limit 50
   → Read the first few errors — what exception? what line?

─── NEXT (next 5 minutes) ────────────────────────────────────────────────────
4. kubectl describe pod <failing-pod> -n production
   → Events section: why did K8s take action?

5. kubectl logs <failing-pod> -n production --previous
   → Logs from the container that just crashed

6. Check RDS:
   CloudWatch → Metrics → RDS → CPUUtilization, DatabaseConnections, ReadLatency
   → DB overloaded? Too many connections? Latency spike?

7. Check if a recent deployment caused this:
   kubectl rollout history deployment/order-service -n production
   → Was there a deployment in the last 30 min?
   → If yes: kubectl rollout undo deployment/order-service -n production
             This is the fastest fix — rollback immediately.

─── DEEPER INVESTIGATION ─────────────────────────────────────────────────────
8. CloudWatch → Container Insights → see CPU/memory spike before the crash

9. If memory spike: OOMKill pattern
   kubectl describe pod <pod> | grep -A5 "OOMKilled"

10. If CPU spike: possible infinite loop or thread deadlock
    kubectl exec -it <pod> -n production -- sh
    kill -3 <java-pid>  ← sends SIGQUIT to Java, dumps thread stack trace to stdout
    kubectl logs <pod> -n production | tail -500  ← read the thread dump
```

---

## 21. MONITORING METRICS — POD, EC2 AND APPLICATION

> Knowing WHICH metrics matter and WHAT they mean is a key developer skill. You don't need to be a DevOps expert, but you DO need to know what to look at when things go wrong.

---

### 21.1 Critical EC2 Metrics

These are available in CloudWatch → Metrics → EC2 out of the box (no agent needed).

| Metric | What It Measures | Good Range | Alert If |
|--------|-----------------|------------|----------|
| **CPUUtilization** | % of vCPU used | 10–70% normal | > 80% sustained |
| **NetworkIn / NetworkOut** | Bytes received/sent | Depends on app | Sudden spike or drop |
| **DiskReadOps / DiskWriteOps** | Read/write IOPS | Depends on EBS type | Near EBS limit |
| **StatusCheckFailed** | EC2 or underlying hardware failure | 0 (always) | Any non-zero value |

**What CPUUtilization > 90% means:**
```
Causes:
  1. Too many requests (need to scale up or add more instances)
  2. Inefficient code (N+1 queries, missing index on DB, infinite loop)
  3. Garbage collection storm (Java heap too small → constant GC)
  4. Memory-mapped I/O saturation

What to check:
  ssh into EC2: top -p $(pgrep java)   → what threads are using CPU?
  kubectl exec into pod: kill -3 <pid>  → Java thread dump shows what's running
```

**Metrics NOT available by default (need CloudWatch Agent):**
```
Memory (RAM) usage     ← EC2 doesn't report this to CloudWatch by default!
Disk space usage       ← also not reported by default

To enable:
  Install CloudWatch Agent on EC2 with config:
  {
    "metrics": {
      "namespace": "CWAgent",
      "metrics_collected": {
        "mem": { "measurement": ["mem_used_percent"] },
        "disk": { "measurement": ["disk_used_percent"] }
      }
    }
  }
```

---

### 21.2 Critical Kubernetes Pod Metrics

These come from Kubernetes metrics-server (for kubectl top) and Prometheus (for Grafana dashboards).

| Metric | What It Measures | Alert Threshold |
|--------|-----------------|-----------------|
| **CPU usage vs request** | How much CPU the pod uses vs what it requested | > 90% of limit = throttling |
| **Memory usage vs limit** | How much memory used vs limit | > 85% of limit = OOMKill risk |
| **Pod restart count** | How many times the pod restarted | > 2 restarts in 1 hour |
| **Readiness status** | Is the pod receiving traffic | Any pod NOT ready = investigate |
| **HTTP error rate** | % of requests returning 5xx | > 0.1% = something is wrong |
| **HTTP p99 latency** | Slowest 1% of responses | > 2 seconds = user experience degraded |

**Checking pod metrics with kubectl:**
```bash
kubectl top pods -n production
# Output:
# NAME                             CPU(cores)   MEMORY(bytes)
# order-service-7d9f8b-abc12      245m         612Mi     ← 245 millicores CPU, 612MB memory
# order-service-7d9f8b-def34      980m         998Mi     ← HIGH! Near 1000m limit
# customer-service-6c5d9-xyz99    85m          210Mi

# If CPU is near limit (1000m in our deployment.yaml):
#   → Pod is CPU throttled → responses slow
#   → Either increase CPU limit in deployment.yaml or fix inefficient code

# If memory is near limit (1Gi in our deployment.yaml):  
#   → Risk of OOMKill
#   → Either increase memory limit or fix memory leak

kubectl top nodes
# NAME               CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
# ip-10-0-1-45       1823m        91%    6234Mi          79%    ← Node is stressed!
# ip-10-0-2-12       456m         22%    2100Mi          26%    ← Healthy
```

---

### 21.3 Application-Level Metrics with Spring Boot Actuator + Prometheus

Spring Boot automatically exposes metrics at `/actuator/prometheus` when you add the Micrometer dependency. These metrics are far more useful than EC2/pod metrics for debugging.

**Important Spring Boot metrics:**
```
─── JVM METRICS ──────────────────────────────────────────────────────────────
jvm_memory_used_bytes{area="heap"}    ← heap memory used (Java heap)
jvm_memory_max_bytes{area="heap"}     ← max heap size
jvm_gc_pause_seconds_sum              ← time spent in garbage collection
jvm_threads_live_threads              ← number of active threads

─── HTTP REQUEST METRICS ─────────────────────────────────────────────────────
http_server_requests_seconds_count{uri="/api/orders",status="200"}  ← request count
http_server_requests_seconds_sum{uri="/api/orders"}                  ← total time
http_server_requests_seconds_max{uri="/api/orders"}                  ← max latency

─── DATASOURCE (DB CONNECTION POOL) ─────────────────────────────────────────
hikaricp_connections_active           ← active DB connections right now
hikaricp_connections_max              ← max pool size (e.g., 10)
hikaricp_connections_pending          ← requests waiting for a connection
  ← If pending > 0: pool is exhausted → DB is the bottleneck

─── CUSTOM METRICS (you add these in your code) ──────────────────────────────
orders_created_total                  ← business metric: how many orders created
payment_processing_seconds            ← how long payment takes
```

**Add to pom.xml:**
```xml
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```

**Add to application.yml:**
```yaml
management:
  endpoints:
    web:
      exposure:
        include: health, info, metrics, prometheus
  metrics:
    export:
      prometheus:
        enabled: true
```

Now curl `http://localhost:8080/actuator/prometheus` — you'll see hundreds of metrics.

---

### 21.4 Prometheus + Grafana — The Standard Monitoring Stack

**Architecture:**
```
Spring Boot pods → expose /actuator/prometheus
       ↑
Prometheus (scrapes every 15s) → stores metric time series
       ↑
Grafana → queries Prometheus → shows dashboards and graphs

ALB → exposes metrics to CloudWatch automatically
EC2 → exposes metrics to CloudWatch automatically
```

**In EKS, Prometheus finds pods automatically via annotations in your deployment:**
```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"          # yes, collect metrics from this pod
    prometheus.io/path: "/actuator/prometheus"   # where to scrape
    prometheus.io/port: "8080"            # which port
```

**Key Grafana dashboards to know:**
```
JVM Micrometer dashboard (ID: 4701):
  → Shows heap memory, GC pauses, thread counts, HTTP response times

Spring Boot Statistics (ID: 6756):
  → Shows HTTP request rates, error rates, DB pool usage

Kubernetes / Pods dashboard:
  → CPU and memory per pod, over time

How to access:
  kubectl port-forward svc/grafana 3000:3000 -n monitoring
  Open browser: http://localhost:3000
  Login: admin / admin
```

---

### 21.5 What Metrics to Look At When Something Is Slow

**User says "the app is slow" — debugging path:**

```
Step 1: Is it the ALB or the app?
  CloudWatch → ALB → TargetResponseTime
  → Is ALB reporting slow backend responses? YES → problem is in the pod
  → Is ALB responding fast but users are slow? → problem is network/CDN/DNS

Step 2: Is it all endpoints or just one?
  Grafana → Spring Boot dashboard → HTTP request latency by URI
  → /api/orders is slow but /api/customers is fast → issue specific to order logic

Step 3: Is it the database?
  Grafana → hikaricp_connections_pending > 0 → connection pool exhausted
  CloudWatch → RDS → ReadLatency / WriteLatency → spike → DB is slow
  CloudWatch → RDS → DatabaseConnections → near max → too many connections

Step 4: Is it JVM garbage collection?
  Grafana → jvm_gc_pause_seconds_sum → increase → GC is pausing app threads
  → Cause: heap too small, memory leak, or large objects being allocated

Step 5: Is it thread starvation?
  Grafana → jvm_threads_live_threads → high (>500) → thread leak
  kubectl exec into pod: kill -3 <pid>  → thread dump
  Look for: "BLOCKED" or "WAITING" threads → deadlock or lock contention
```

---

## 22. ROLLOUT STRATEGIES — HOW DEPLOYMENTS WORK

> When you deploy a new version of your app, you need zero downtime. These are the three main strategies. Kubernetes uses Rolling Update by default. Blue-Green and Canary are more controlled.

---

### 22.1 Rolling Update — Kubernetes Default

**How it works:**
```
Initial state:
  [v1-pod-1] [v1-pod-2] [v1-pod-3]    ← all 3 pods serve traffic

Deploy new version (kubectl set image or kubectl apply):

Step 1 — K8s adds 1 new pod (maxSurge=1):
  [v1-pod-1] [v1-pod-2] [v1-pod-3] [v2-pod-4-starting]
  
  The new pod must:
  a. Pass startupProbe (can take up to 300s for slow Spring Boot start)
  b. Pass readinessProbe (3 consecutive successes)
  
  Until readinessProbe passes, v2-pod-4 receives ZERO traffic.

Step 2 — v2-pod-4 is ready, ALB adds it to rotation:
  [v1-pod-1] [v1-pod-2] [v1-pod-3] [v2-pod-4-ready]
  
  All 4 pods serve traffic.

Step 3 — K8s terminates v1-pod-1 (maxUnavailable=0 → always 3+ ready):
  [v1-pod-2] [v1-pod-3] [v2-pod-4] [v2-pod-5-starting]
  
  v1-pod-1 receives preStop hook first (sleep 10s → ALB finishes draining)
  then gets SIGTERM → Spring Boot graceful shutdown (60s window) → SIGKILL

Step 4 — Continue until all pods are v2:
  [v2-pod-4] [v2-pod-5] [v2-pod-6]    ← new version fully deployed

Total time: ~5-10 min for 3 pods (depends on startup time)
Downtime: ZERO (always 3 pods ready if health checks pass)
```

**Rollback:**
```bash
kubectl rollout undo deployment/order-service -n production
# K8s immediately starts replacing v2 pods with v1 pods using same rolling strategy
# Old pod spec is stored in rollout history — no re-pull from ECR needed

kubectl rollout history deployment/order-service -n production
# REVISION  CHANGE-CAUSE
# 1         first deployment
# 2         git commit abc123 → build #41
# 3         git commit def456 → build #42  ← current

kubectl rollout undo deployment/order-service --to-revision=1 -n production
# Roll back to a specific revision
```

**The container used in Rolling Update:**
```
Rolling update uses Docker containers in Kubernetes pods.
Container runtime: containerd (default in modern EKS, not Docker daemon)
Image: pulled from ECR (only if not already cached on the node)
Format: OCI-compliant Docker image (same Dockerfile you build locally)
```

---

### 22.2 Blue-Green Deployment

**How it works:**
```
"Blue" = current production (v1)
"Green" = new version (v2) — deployed but receives NO traffic yet

Step 1: Current state
  ALB Listener Rule → Blue Target Group → [v1-pod-1] [v1-pod-2] [v1-pod-3]
  Green Target Group is EMPTY (or not yet created)

Step 2: Deploy Green (new version) — no traffic goes to it yet
  kubectl apply -f k8s/order-service-green.yaml -n production
  kubectl rollout status deployment/order-service-green -n production
  
  Now:
  ALB → Blue TG → [v1-pod-1] [v1-pod-2] [v1-pod-3]    ← 100% traffic
  Green TG → [v2-pod-1] [v2-pod-2] [v2-pod-3]          ← 0% traffic

Step 3: Run automated tests against Green (smoke tests, integration tests)
  curl http://green-internal-endpoint/actuator/health
  curl http://green-internal-endpoint/api/orders/1
  (Use a Test ALB listener or a separate internal ALB target)

Step 4: Switch ALL traffic to Green (instant cutover — no mixed versions)
  aws elbv2 modify-listener \
    --listener-arn arn:aws:elasticloadbalancing:...:listener/xxx \
    --default-actions '[{"Type":"forward","TargetGroupArn":"<GREEN_TG_ARN>"}]'
  
  Now:
  ALB → Green TG → [v2-pod-1] [v2-pod-2] [v2-pod-3]  ← 100% traffic
  Blue TG → [v1-pod-1] [v1-pod-2] [v1-pod-3]          ← 0% traffic (kept alive)

Step 5: Monitor for 15-30 min

Step 6a: If all good → Delete Blue deployment
  kubectl delete deployment order-service-blue -n production

Step 6b: If something is wrong → Instant rollback (switch back to Blue)
  aws elbv2 modify-listener --listener-arn ... \
    --default-actions '[{"Type":"forward","TargetGroupArn":"<BLUE_TG_ARN>"}]'
  Rollback is instantaneous — zero pod restart needed.
```

**In Kubernetes, Blue-Green is done with two Deployments and label switching:**
```yaml
# Blue deployment (v1) — kept alive during transition
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service-blue
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: order-service
      version: blue
  template:
    metadata:
      labels:
        app: order-service
        version: blue      # ← label identifies blue pods
    spec:
      containers:
        - name: order-service
          image: .../order-service:41  # old version

# Green deployment (v2) — new version
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service-green
spec:
  replicas: 3
  template:
    metadata:
      labels:
        app: order-service
        version: green
    spec:
      containers:
        - name: order-service
          image: .../order-service:42  # new version

# Service — switch traffic by changing selector
apiVersion: v1
kind: Service
metadata:
  name: order-service
spec:
  selector:
    app: order-service
    version: blue   # ← change this to "green" to switch traffic instantly
  ports:
    - port: 8080
```

```bash
# Instant traffic switch — change service selector
kubectl patch service order-service -n production \
  -p '{"spec":{"selector":{"version":"green"}}}'

# Rollback — switch back to blue
kubectl patch service order-service -n production \
  -p '{"spec":{"selector":{"version":"blue"}}}'
```

---

### 22.3 Canary Deployment

**How it works:**
```
Deploy new version to 1 pod (10% of traffic) while 9 pods run old version.
Watch for 30 min. If good → gradually increase to 100%.

Initial state: 3 v1 pods (100% traffic)

Step 1: Add 1 canary pod (v2)
  [v1] [v1] [v1] [v2-canary]
  ALB distributes evenly: 25% to canary → traffic split 75% v1 / 25% v2

Step 2: Watch metrics:
  → Error rate for canary pod vs main pods
  → Latency for canary pod
  → If canary shows higher errors: kubectl delete pod canary-pod → done, no blast radius

Step 3: If canary is healthy → roll out to all pods (rolling update from v1 → v2)

Canary in Kubernetes using Argo Rollouts (advanced):
  5% → 25% → 50% → 100% with automated analysis at each step

Basic canary with plain kubectl:
  Start with replicas: 10 (9 x v1, 1 x v2 = 10% canary traffic)
  Deploy the v2 pod manually → watch → then do full rolling update
```

---

### 22.4 Strategy Comparison

| Strategy | Rollback Speed | Cost | Downtime | Mixed Versions in Prod |
|----------|---------------|------|----------|----------------------|
| Rolling Update | Slow (one pod at a time) | Normal | None | Brief (both v1+v2 run during rollout) |
| Blue-Green | Instant (ALB switch) | 2x infra cost during transition | None | No (clean cutover) |
| Canary | Instant (delete canary pod) | Slight extra cost (1 extra pod) | None | Yes (intentionally) |

**When to use which:**
```
Rolling Update:  Default for most deployments. Simple, built-in to K8s.
                 Good when: your API is backwards-compatible and brief mixed-version is OK.

Blue-Green:      Use for high-stakes deployments or when you can't have any mixed versions.
                 Good when: DB schema changes, breaking API changes.
                 Cost: 2x infrastructure for the transition period.

Canary:          Use when you want to test on real production traffic before full rollout.
                 Good when: uncertain about performance, testing a risky feature flag.
                 Best with: Argo Rollouts for automation.
```

---

### 22.5 What Container Is Used in Each Strategy

All three strategies use the same container type:

```
Container format: Docker (OCI-compliant image)
Container runtime: containerd (EKS 1.24+) — replaces Docker daemon in nodes
Image registry: Amazon ECR
Image tag: build number (:42, :43, etc.) — NEVER :latest in production
Base image: eclipse-temurin:21-jre-alpine (for Java apps)

The ONLY thing that changes between strategies is HOW and WHEN
the container is deployed and how traffic is routed to it.

Blue-Green: two Deployments, same image format, different versions
Rolling:    one Deployment, K8s replaces pods one at a time
Canary:     one extra pod with the new image, manually monitored
```

---

## 23. LOCAL MICROSERVICE TESTING WITH DOCKER

> You need to be able to run your microservice on your laptop and test it the same way it runs in production. This section covers the complete local setup.

---

### 23.1 Why You Need Docker Even for Local Testing

```
Your microservice needs:
  ├─ PostgreSQL database
  ├─ Redis (cache)
  ├─ Another microservice (customer-service)
  └─ Maybe: Kafka/SQS for messaging

Without Docker:
  → Install PostgreSQL, Redis, other services on your laptop
  → Pollutes your machine
  → Different versions between developers
  → "Works on my machine" problem
  → Test data persists between runs — tests interfere

With Docker Compose:
  → One command: docker-compose up --build
  → Everything starts in containers (isolated, correct version)
  → docker-compose down -v → all data wiped, clean state
  → Every developer has identical environment
  → Same container versions as production
```

---

### 23.2 Complete Local Testing Setup for One Microservice

**Scenario: You're working on `order-service` only. Customer-service is another team.**

**Step 1 — Build and test without Docker (unit/integration tests):**
```bash
# From order-service directory
mvn clean test                        # run unit tests only (no Docker needed)
mvn clean verify                      # run integration tests (needs DB — use Testcontainers)

# With TestContainers (automatically starts PostgreSQL container for tests):
# No docker-compose needed — the test itself manages the container
mvn clean verify -Dspring.profiles.active=test
```

**Step 2 — Run the full service locally with Docker Compose:**
```bash
# From order-service directory (where docker-compose.yml lives)
docker-compose up --build             # build the JAR → build Docker image → start all containers
docker-compose up --build -d          # same but in background

# After startup (takes ~60s for Spring Boot):
# Access your service: http://localhost:8080/api/orders
# Access PostgreSQL: localhost:5432 (use DBeaver or psql)
# Access WireMock (fake customer-service): http://localhost:8081

# View logs:
docker-compose logs -f order-service  # follow order-service logs
docker-compose logs -f                # follow ALL service logs

# Restart just your service (after code change):
# Rebuild and restart only order-service (not postgres, not redis):
docker-compose up --build -d --no-deps order-service

# Stop everything and wipe all data:
docker-compose down -v               # removes containers AND volumes (DB data wiped)
docker-compose down                  # removes containers but KEEPS volumes (DB data preserved)
```

**Step 3 — Verify the service works as expected:**
```bash
# Health check
curl http://localhost:8080/actuator/health
# Expected: {"status":"UP","components":{"db":{"status":"UP"},...}}

# Test an API endpoint
curl http://localhost:8080/api/orders
curl -X POST http://localhost:8080/api/orders \
  -H "Content-Type: application/json" \
  -d '{"customerId": 42, "product": "Laptop"}'

# Check what customer-service (WireMock) returns when order-service calls it
curl http://localhost:8081/api/customers/42
# WireMock returns your stubbed response from wiremock-stubs/mappings/

# Check DB contents (with psql):
docker exec -it postgres-orders psql -U orders_user -d orders_db
  \dt              -- list tables
  SELECT * FROM orders;  -- see all orders
  \q               -- quit
```

---

### 23.3 Debugging Containers Locally — Common Scenarios

**Scenario A: Service won't start — "Connection refused" on startup**
```bash
# Check which containers are actually running:
docker-compose ps
# Example output:
# postgres-orders   Up (healthy)   5432/tcp
# order-service     Restarting     8080/tcp   ← problem!

# See the error:
docker-compose logs order-service
# Output: Cannot connect to jdbc:postgresql://postgres-orders:5432/orders_db

# Debug steps:
# 1. Check container name: in docker-compose.yml, service is named "postgres-orders"
#    → URL must be jdbc:postgresql://postgres-orders:5432/... (container name, not localhost)
# 2. Is postgres healthy?
#    docker-compose logs postgres-orders
# 3. Can order-service reach postgres?
#    docker exec -it order-service ping postgres-orders  ← should resolve
#    docker exec -it order-service nc -vz postgres-orders 5432
```

**Scenario B: Code change → test quickly without full rebuild**
```bash
# Option 1: Volume mount (for scripts — not great for Java JARs)
# Option 2: Build new JAR, rebuild Docker image, restart container
mvn clean package -DskipTests      # build JAR (~30s)
docker-compose up --build -d --no-deps order-service  # rebuild image and restart

# Option 3: For quick testing, run Spring Boot directly on your laptop
# (skip Docker for the app, but keep DB in Docker):
docker-compose up -d postgres-orders   # only start the database
export SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/orders_db
export SPRING_DATASOURCE_USERNAME=orders_user
export SPRING_DATASOURCE_PASSWORD=orders_secret
export CUSTOMER_SERVICE_URL=http://localhost:8081  # WireMock
mvn spring-boot:run   # start app directly (hot-reload works with DevTools)
```

**Scenario C: Check environment variables inside a running container**
```bash
docker exec -it order-service env | grep SPRING      # see Spring-related env vars
docker exec -it order-service env | grep DB          # see DB config
docker exec -it order-service env                    # see ALL env vars

# Compare with what docker-compose.yml defines:
docker-compose config     # shows the fully resolved docker-compose config
```

**Scenario D: The service starts but API calls fail**
```bash
# Shell into the container:
docker exec -it order-service sh

# Test DB connection from inside container:
nc -vz postgres-orders 5432       # can I reach DB?
# Expected: Connection to postgres-orders 5432 port [tcp/postgresql] succeeded!

# Test calling the mocked customer-service:
wget -qO- http://customer-service-mock:8080/api/customers/42
# Expected: {"id":42,"name":"John Doe","active":true}  ← your WireMock stub

# Hit your own health endpoint:
wget -qO- http://localhost:8080/actuator/health
```

**Scenario E: Check container resource usage**
```bash
docker stats                    # live CPU, memory, network for all containers
docker stats order-service      # live stats for just order-service

# Typical output:
# CONTAINER        CPU%   MEM USAGE/LIMIT  MEM%    NET I/O
# order-service    12.3%  380MiB/1GiB      37.1%   1.2MB/850KB
# postgres-orders   2.1%  120MiB/512MiB    23.4%   400KB/200KB
```

---

### 23.4 WireMock — Stubbing Dependent Services

WireMock is a fake HTTP server. Instead of running the real customer-service, you run WireMock and configure it to return whatever responses you need.

**Why WireMock:**
```
Without WireMock:
  order-service calls customer-service → customer-service must be running
  → You need the full codebase of customer-service
  → Changes in customer-service break your local tests
  → Can't test error scenarios easily (how do you make customer-service return 500?)

With WireMock:
  order-service calls http://localhost:8081/api/customers/42
  WireMock intercepts and returns your configured JSON
  → You control what the response is
  → Test the happy path: customer exists, returns 200
  → Test error paths: customer not found (404), service down (503)
  → No dependency on other team's code
```

**WireMock stub files:**
```json
// wiremock-stubs/mappings/get-customer-success.json
{
  "request": {
    "method": "GET",
    "urlPattern": "/api/customers/[0-9]+"
  },
  "response": {
    "status": 200,
    "headers": { "Content-Type": "application/json" },
    "body": "{\"id\": 42, \"name\": \"John Doe\", \"email\": \"john@example.com\", \"active\": true}"
  }
}
```

```json
// wiremock-stubs/mappings/get-customer-not-found.json
// Test the "customer not found" path:
{
  "request": {
    "method": "GET",
    "url": "/api/customers/999"
  },
  "response": {
    "status": 404,
    "headers": { "Content-Type": "application/json" },
    "body": "{\"error\": \"Customer not found\"}"
  }
}
```

```json
// wiremock-stubs/mappings/customer-service-down.json
// Test circuit breaker / resilience4j behavior:
{
  "request": {
    "method": "GET",
    "url": "/api/customers/1000"
  },
  "response": {
    "status": 503,
    "body": "Service Unavailable"
  }
}
```

---

### 23.5 Interview Q&A — Local Testing

**Q: How do you run your microservice locally without a full AWS environment?**
> "We use Docker Compose. Our repository includes a docker-compose.yml that spins up the service with all its infrastructure dependencies — PostgreSQL, Redis — in containers. For services this microservice calls, we use WireMock stubs to simulate their responses. This gives us a fully isolated, reproducible local environment. For integration tests, we use TestContainers to start real databases inside JUnit tests."

**Q: How do you test a scenario where customer-service returns an error?**
> "WireMock lets us configure any response for any URL pattern. We add a stub that matches `GET /api/customers/999` and returns a 503. We then test our order-service with a request for customer 999 and verify that our resilience logic (Resilience4j circuit breaker or fallback) handles the error gracefully."

**Q: Why not use H2 in-memory database for testing?**
> "H2 is not PostgreSQL. It has different SQL syntax, different behavior for certain queries (like JSON operators, specific functions, locking behavior), and different default settings. Tests that pass on H2 can fail against real PostgreSQL. TestContainers starts a real PostgreSQL container for each test run — same database we use in production — so tests are actually meaningful."

**Q: How do you debug a `CrashLoopBackOff` that only happens in Docker and not locally?**
> "CrashLoopBackOff in Docker usually means: wrong environment variable, container can't reach a dependency, or the app runs out of memory. Steps:
> 1. `docker-compose logs order-service` — read the exception  
> 2. Compare env vars: `docker exec -it order-service env` vs what's in docker-compose.yml
> 3. Check connectivity: `docker exec -it order-service nc -vz postgres-orders 5432`
> 4. If OOMKill: `docker stats` and increase memory in compose, or add `-XX:MaxRAMPercentage=75.0` to JVM args"

**Q: What is the difference between `docker-compose down` and `docker-compose down -v`?**
> "`down` stops and removes containers and networks, but keeps volumes — so your database data persists. `down -v` also removes named volumes, which wipes all database data. Use `down -v` when you want a completely clean slate (start fresh with empty database) or when running tests that need a clean database state."

---

*This guide covers everything a Java fullstack developer needs for AWS interviews — from architecture fundamentals through to CloudWatch alarms, production debugging, and local Docker testing. The sections most frequently tested in senior interviews are: VPC/Security Groups, CI/CD flow, Pod failure analysis, CloudWatch, and how to explain a complete deployment end-to-end. Practice explaining the deployment flow out loud — interviewers love walk-through questions.*

---

## 24. DEVELOPER ACCESS — EC2, RDS, EKS, ECR AND KMS

> This section covers how a developer actually gets access to AWS resources day-to-day — from IAM setup on day one, to SSHing into EC2, querying the database, running kubectl, and understanding encryption keys.

---

### 24.1 IAM Groups for Developers — Who Gets What Access

In a real company, AWS access is controlled by IAM Groups. Every developer is added to one or more groups depending on their role and which environment they can touch.

**Typical IAM group structure:**

```
IAM Groups:
  ├─ dev-developers
  │    Purpose: All developers get this group
  │    Access:
  │      - EKS: describe clusters (to run kubectl)
  │      - ECR: push/pull images (to build and test Docker images)
  │      - CloudWatch Logs: read logs from /eks/dev/* log groups
  │      - S3: read/write to dev buckets only
  │      - Secrets Manager: read /dev/* secrets only
  │      - RDS: NO direct access (connect via bastion or port-forward)
  │      - EC2: describe instances (to see what's running) — NOT SSH by default
  │
  ├─ dev-leads
  │    Purpose: Tech leads and seniors
  │    Access: Everything in dev-developers PLUS:
  │      - EC2: start/stop/reboot dev EC2 instances
  │      - Secrets Manager: create and update /dev/* secrets
  │      - CloudWatch: create alarms in dev environment
  │
  ├─ prod-readonly
  │    Purpose: Developers can VIEW prod but NOT change it
  │    Access:
  │      - CloudWatch Logs: read /eks/prod/* (to debug prod issues)
  │      - EKS: describe only (can run kubectl get, kubectl describe, kubectl logs)
  │      - ECR: read only (can pull, can't push)
  │      - RDS: NO direct access
  │      - S3: read only on prod buckets
  │
  └─ devops-admins
       Purpose: DevOps/platform team
       Access: Full access to everything in all environments
```

**How to create and assign an IAM group (console):**
```
AWS Console → IAM → User groups → Create group
  Group name: dev-developers

  Attach permission policies:
    → Search and add:
        AmazonEKSDescribeCluster          ← to run kubectl
        AmazonEC2ContainerRegistryPowerUser  ← push/pull ECR images
        CloudWatchLogsReadOnlyAccess      ← read logs
    → Add custom inline policy (for S3/Secrets scoped to dev only):

Inline policy JSON:
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DevS3Access",
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject", "s3:ListBucket"],
      "Resource": [
        "arn:aws:s3:::myapp-dev-*",
        "arn:aws:s3:::myapp-dev-*/*"
      ]
    },
    {
      "Sid": "DevSecretsAccess",
      "Effect": "Allow",
      "Action": ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"],
      "Resource": "arn:aws:secretsmanager:us-east-1:123456789:secret:/dev/*"
    },
    {
      "Sid": "EKSAccess",
      "Effect": "Allow",
      "Action": ["eks:DescribeCluster", "eks:ListClusters"],
      "Resource": "*"
    }
  ]
}

→ Create group

To add a developer to the group:
  IAM → Users → Click user (e.g., "john.doe") → Groups tab → Add user to group
  → Select: dev-developers → Add to group
```

**Least Privilege in Practice:**
```
Rule: Developers should NEVER have admin access to production.
      They should be able to READ prod logs (to debug customer issues)
      but NEVER write/deploy to prod directly — only the CI/CD pipeline does that.

Common mistake: Giving developers the "AdministratorAccess" policy
→ Any mistake (wrong kubectl command, wrong aws CLI command) can take down prod
→ Keys leaking = full account compromise

Correct: Developers have read-only prod access. Jenkins EC2 has the deploy IAM role.
```

---

### 24.2 Day-One Developer Setup — Step by Step

**When a new developer joins:**

```
Step 1 — IT/DevOps creates IAM user:
  IAM → Users → Create user
  → Username: firstname.lastname
  → Enable console access: YES
  → Auto-generated password + require password reset on first login
  → Add to group: dev-developers

Step 2 — Developer receives:
  - AWS Console URL: https://123456789.signin.aws.amazon.com/console
  - Username: firstname.lastname
  - Temporary password (must change on first login)

Step 3 — Developer logs into AWS Console:
  Go to the URL above → enter username + temp password → set new password
  → Enable MFA (strongly recommended):
     IAM → Users → your username → Security credentials tab
     → Multi-factor authentication → Assign MFA device
     → Authenticator app (Google Authenticator / Authy)
     → Scan QR code → Enter two consecutive codes → Assign MFA

Step 4 — Developer creates Access Keys (for CLI/SDK use):
  IAM → Users → your username → Security credentials tab
  → Access keys → Create access key
  → Use case: CLI
  → Download .csv file (KEEP SAFE — this is shown only once)

Step 5 — Developer configures AWS CLI on laptop:
  aws configure
  AWS Access Key ID: AKIAIOSFODNN7EXAMPLE        ← from the .csv
  AWS Secret Access Key: wJalrXUtn...             ← from the .csv
  Default region: us-east-1
  Default output format: json

  Verify it works:
  aws sts get-caller-identity
  # Output:
  # {
  #   "UserId": "AIDIOSFODNN7EXAMPLE",
  #   "Account": "123456789",
  #   "Arn": "arn:aws:iam::123456789:user/firstname.lastname"
  # }
```

---

### 24.3 Logging Into EC2 — Two Methods

There are two ways to get a shell on an EC2 instance. Knowing both is important for interviews.

---

#### Method 1: SSH with Key Pair (Traditional)

**When creating EC2 instance:**
```
EC2 → Instances → Launch instance
  → Key pair (login) section:
     Create new key pair → Name: dev-keypair → Type: RSA → Format: .pem
     → Download .pem file (saved to your Downloads folder)

On your laptop (Linux/Mac):
  chmod 400 ~/Downloads/dev-keypair.pem   ← required: makes key read-only
  ssh -i ~/Downloads/dev-keypair.pem ec2-user@<public-ip>
  # ec2-user = default user for Amazon Linux
  # ubuntu   = default user for Ubuntu AMI
  # root     = NOT recommended

On Windows (PowerShell with OpenSSH):
  ssh -i C:\Users\you\Downloads\dev-keypair.pem ec2-user@<public-ip>

On Windows with PuTTY:
  First convert .pem to .ppk using PuTTYgen
  Then use PuTTY → SSH → Auth → browse to .ppk file
```

**To SSH into a PRIVATE subnet EC2 (no public IP — production pattern):**
```
You cannot SSH directly into private subnet EC2 (no public IP, no route from internet).
You need a BASTION HOST (also called a Jump Box).

Bastion host = a small EC2 in the PUBLIC subnet that you SSH into first,
               then from there SSH into the private EC2.

Architecture:
  Your laptop → SSH → Bastion (public subnet, has public IP)
                         → SSH → App EC2 (private subnet, no public IP)

SSH command with jump (one-liner from your laptop):
  ssh -i dev-keypair.pem \
      -J ec2-user@<bastion-public-ip> \
      ec2-user@<app-ec2-private-ip>

  # -J = jump through bastion
  # First connects to bastion, then from bastion connects to app EC2

Or configure in ~/.ssh/config (cleaner):
  Host bastion
    HostName <bastion-public-ip>
    User ec2-user
    IdentityFile ~/Downloads/dev-keypair.pem

  Host app-dev
    HostName 10.0.3.45     ← private IP of app EC2
    User ec2-user
    IdentityFile ~/Downloads/dev-keypair.pem
    ProxyJump bastion      ← jump via bastion

  Then simply: ssh app-dev
```

---

#### Method 2: AWS Systems Manager Session Manager (Recommended for Production)

Session Manager lets you open a shell to EC2 WITHOUT any SSH keys, without opening port 22, without a bastion host — through the AWS Console or CLI.

**Why Session Manager is better:**
```
Traditional SSH:
  - EC2 must be in public subnet OR you need a bastion host
  - Security group must allow port 22 from somewhere
  - You must manage and distribute SSH keys
  - Hard to audit who ran what commands

Session Manager:
  - Works on PRIVATE subnet EC2 (no inbound port needed)
  - No port 22 needed — traffic goes through AWS's internal network
  - No SSH keys to manage
  - Full audit trail in CloudTrail (every session, every command logged)
  - Access controlled by IAM policies
```

**How to enable Session Manager on EC2:**
```
1. EC2 must have the SSM agent installed (pre-installed on Amazon Linux 2+, Ubuntu 20+)

2. EC2 must have an IAM role with this policy:
   AmazonSSMManagedInstanceCore  ← AWS-managed policy, attach to EC2 IAM role

3. EC2 must be able to reach SSM endpoints:
   Option A: EC2 in public subnet (has internet access) → SSM works automatically
   Option B: EC2 in private subnet → add VPC Endpoints for SSM:
     VPC → Endpoints → Create endpoint
     → Service: com.amazonaws.us-east-1.ssm
     → Service: com.amazonaws.us-east-1.ssmmessages
     → Service: com.amazonaws.us-east-1.ec2messages
```

**Starting a session (console):**
```
AWS Console → Systems Manager → Session Manager → Start session
  → Select your EC2 instance from the list
  → Start session → Browser opens a terminal

OR via AWS CLI:
  aws ssm start-session --target i-1234567890abcdef0

This opens a shell directly — no SSH, no keys, no bastion.
```

**Developer IAM permission for Session Manager:**
```json
{
  "Effect": "Allow",
  "Action": [
    "ssm:StartSession",
    "ssm:TerminateSession",
    "ssm:DescribeSessions"
  ],
  "Resource": [
    "arn:aws:ec2:us-east-1:123456789:instance/i-dev-*",
    "arn:aws:ssm:us-east-1:123456789:session/${aws:username}-*"
  ]
}
```

---

### 24.4 Connecting to RDS from Your Laptop

RDS runs in a **private subnet** — it has no public IP and is not reachable from the internet. You connect via one of three methods.

---

#### Method 1: SSH Tunnel Through Bastion (Most Common)

```
Your laptop connects to RDS by tunneling through the bastion EC2.

Command:
  ssh -i dev-keypair.pem \
      -L 5433:orders-rds.prod.internal:5432 \
      ec2-user@<bastion-public-ip> \
      -N

  # -L 5433:orders-rds...:5432 = forward local port 5433 to RDS port 5432 via bastion
  # -N = don't execute a remote command, just forward the port
  # Leave this terminal open (it's a running tunnel)

Now in another terminal (or DBeaver):
  Host:     localhost
  Port:     5433          ← your local port (tunneled to RDS 5432)
  Database: orders_db
  Username: orders_user
  Password: (from Secrets Manager)
  → Connect

Looks like you're connecting to localhost, but traffic goes:
  Your laptop:5433 → Bastion EC2 → RDS:5432
```

**In DBeaver (GUI Database Tool):**
```
DBeaver → New Connection → PostgreSQL
  Host: localhost
  Port: 5433
  Database: orders_db
  Username: orders_user
  Password: (paste from Secrets Manager)
→ Test Connection → Finish
```

---

#### Method 2: kubectl Port-Forward (For DEV on EKS — No Bastion Needed)

If your app is running in EKS dev cluster and that pod can reach RDS, you can tunnel through the pod:

```bash
# Forward local port 5432 to RDS via a pod that can reach it
kubectl run db-tunnel --image=alpine --rm -it --restart=Never -n development -- \
  sh -c "apk add --no-cache socat && socat TCP-LISTEN:5432,fork TCP:orders-rds.dev.internal:5432"

# In another terminal:
kubectl port-forward pod/db-tunnel 5432:5432 -n development

# Now connect with DBeaver/psql to localhost:5432 → tunneled to RDS
```

Or simpler — forward a running app pod's port and use the actuator:
```bash
# Just use a debug pod that has psql installed:
kubectl run pg-client --image=postgres:16 --rm -it --restart=Never -n development -- \
  psql -h orders-rds.dev.internal -U orders_user -d orders_db
# Enter password → you're in psql directly inside the cluster
```

---

#### Method 3: RDS Proxy + IAM Authentication (Production Best Practice)

For production, never expose RDS credentials in connection strings. Use RDS Proxy with IAM authentication:

```
RDS Proxy sits in front of RDS:
  - Manages connection pooling (reduces DB connections)
  - Supports IAM token authentication (no password needed — temporary token)
  - Automatic failover to Multi-AZ standby

Java connection with IAM auth:
  // Generate temporary token (expires in 15 min)
  String token = RdsIamAuthTokenGenerator.builder()
      .credentials(DefaultCredentialsProvider.create())
      .region("us-east-1")
      .build()
      .generateAuthToken(
          GetIamAuthTokenRequest.builder()
              .hostname("orders-proxy.proxy-xxx.us-east-1.rds.amazonaws.com")
              .port(5432)
              .userName("orders_user")
              .build()
      );

  // Use token as password
  DataSource ds = DataSourceBuilder.create()
      .url("jdbc:postgresql://orders-proxy.proxy-xxx.us-east-1.rds.amazonaws.com:5432/orders_db")
      .username("orders_user")
      .password(token)  ← IAM token, not hardcoded password
      .build();
```

---

### 24.5 Accessing the EKS Cluster with kubectl

Before you can run any `kubectl` command against an EKS cluster, you need to add it to your kubeconfig.

**Step 1 — Make sure your IAM user has EKS access:**
```bash
# Your IAM user needs eks:DescribeCluster permission (in dev-developers group)
aws eks list-clusters --region us-east-1
# If this returns cluster names, your IAM permissions are fine
```

**Step 2 — Add the EKS cluster to your kubeconfig:**
```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name dev-eks-cluster \
  --alias dev   # optional: a short alias instead of the full ARN

# This writes cluster credentials to ~/.kube/config
# Now kubectl knows how to talk to your cluster
```

**Step 3 — IMPORTANT: EKS aws-auth ConfigMap (developer must be added here)**

Adding the cluster to kubeconfig is not enough. EKS has its own internal authorization called `aws-auth` — your IAM user must be listed there to actually run commands.

```bash
# DevOps/admin adds your IAM user to the cluster's aws-auth ConfigMap:
kubectl edit configmap aws-auth -n kube-system

# The ConfigMap looks like this:
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapUsers: |
    - userarn: arn:aws:iam::123456789:user/john.doe
      username: john.doe
      groups:
        - dev-readonly   # K8s RBAC group → controls what this user can DO inside K8s
    - userarn: arn:aws:iam::123456789:user/jane.doe
      username: jane.doe
      groups:
        - dev-readonly
```

**Step 4 — RBAC: What developers can do inside the cluster**

```yaml
# k8s/rbac/dev-readonly-role.yaml
# ClusterRole defines permissions
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: dev-readonly
rules:
  - apiGroups: ["", "apps", "autoscaling"]
    resources: ["pods", "deployments", "services", "configmaps",
                "replicasets", "horizontalpodautoscalers"]
    verbs: ["get", "list", "watch"]   # read-only (no create, update, delete)
  - apiGroups: [""]
    resources: ["pods/log"]
    verbs: ["get"]                     # kubectl logs is allowed
  - apiGroups: [""]
    resources: ["pods/exec"]
    verbs: ["create"]                  # kubectl exec is allowed (to debug)
---
# Bind this role to the IAM group "dev-readonly"
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: dev-readonly-binding
subjects:
  - kind: Group
    name: dev-readonly   # matches the group in aws-auth ConfigMap
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: dev-readonly
  apiGroup: rbac.authorization.k8s.io
```

**Step 5 — Verify access:**
```bash
kubectl config current-context      # which cluster am I on?
# output: dev   (the alias you set)

kubectl config get-contexts         # list all configured clusters
# CURRENT  NAME   CLUSTER                                     AUTHINFO
# *        dev    dev-eks-cluster.us-east-1.eksctl.io         john.doe@dev-eks-cluster
#          prod   prod-eks-cluster.us-east-1.eksctl.io        john.doe@prod-eks-cluster

kubectl config use-context prod     # switch to prod cluster
kubectl config use-context dev      # switch back to dev

# Test access:
kubectl get pods -n development     # should work (read-only)
kubectl delete pod xyz -n development  # should be DENIED if you only have dev-readonly
```

**Adding multiple clusters (common for devs with DEV + PROD access):**
```bash
aws eks update-kubeconfig --region us-east-1 --name dev-eks-cluster  --alias dev
aws eks update-kubeconfig --region us-east-1 --name prod-eks-cluster --alias prod

# Now both clusters are in ~/.kube/config
# Switch between them:
kubectl config use-context dev    # work on dev
kubectl config use-context prod   # switch to prod
```

---

### 24.6 Logging Into ECR — Push and Pull Docker Images

ECR requires authentication before you can push or pull images. The auth token is temporary (12 hours).

**Login to ECR:**
```bash
# Get the account ID first:
aws sts get-caller-identity --query Account --output text
# Output: 123456789

# Login to ECR (replaces `docker login` for ECR):
aws ecr get-login-password --region us-east-1 | \
  docker login \
  --username AWS \
  --password-stdin \
  123456789.dkr.ecr.us-east-1.amazonaws.com

# Success output: "Login Succeeded"
# Token is valid for 12 hours — you need to re-run this after it expires

# If you get "no basic auth credentials" when doing docker push → token expired
# Just re-run the login command above
```

**Create a new ECR repository:**
```bash
aws ecr create-repository \
  --repository-name order-service \
  --image-scanning-configuration scanOnPush=true \
  --encryption-configuration encryptionType=KMS \   ← use KMS encryption
  --region us-east-1
```

**Push your Docker image to ECR:**
```bash
# Build:
docker build --platform=linux/amd64 -t order-service:42 .

# Tag with full ECR URI:
docker tag order-service:42 \
  123456789.dkr.ecr.us-east-1.amazonaws.com/order-service:42

# Push:
docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/order-service:42
```

**Pull from ECR:**
```bash
# Pull (after logging in):
docker pull 123456789.dkr.ecr.us-east-1.amazonaws.com/order-service:42

# Run locally with the ECR image (exactly as it would run in EKS):
docker run -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=local \
  -e SPRING_DATASOURCE_URL=jdbc:postgresql://host.docker.internal:5432/orders_db \
  123456789.dkr.ecr.us-east-1.amazonaws.com/order-service:42
```

**ECR developer IAM permission (in dev-developers group):**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ECRAuthToken",
      "Effect": "Allow",
      "Action": "ecr:GetAuthorizationToken",
      "Resource": "*"
    },
    {
      "Sid": "ECRPushPull",
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage",
        "ecr:DescribeImages",
        "ecr:ListImages"
      ],
      "Resource": "arn:aws:ecr:us-east-1:123456789:repository/dev-*"
      // dev-* = only dev repos. Prod repos need a separate prod-deploy role.
    }
  ]
}
```

---

### 24.7 KMS — Encryption Keys for Developers

KMS (Key Management Service) manages the encryption keys that protect your data at rest. As a developer you typically don't manage KMS directly, but you need to understand it for interviews and for debugging `AccessDeniedException` errors.

---

#### What KMS Encrypts in a Typical App

```
Every sensitive data store is encrypted with a KMS key:

  ├─ S3 bucket (documents, logs)        → SSE-KMS: KMS key encrypts S3 objects
  ├─ RDS database                        → KMS key encrypts all data on disk
  ├─ EBS volumes (EC2 hard drive)        → KMS key encrypts the disk
  ├─ Secrets Manager secrets             → KMS key encrypts the secret value
  ├─ ECR Docker images                   → KMS key encrypts images in the registry
  └─ EKS Secrets (Kubernetes)            → KMS key encrypts K8s Secrets at rest
```

**Two types of KMS keys:**

```
AWS Managed Keys (aws/s3, aws/rds, aws/ecr):
  → AWS creates and manages these automatically
  → Free, zero setup
  → Less control (can't change rotation schedule, can't see key material)
  → Sufficient for most use cases

Customer Managed Keys (CMK):
  → You create and manage these in KMS
  → You control: who can use the key (key policy), rotation (annual or manual)
  → Costs $1/month per key + $0.03 per 10,000 API calls
  → Required for: cross-account access, strict compliance, custom rotation

Interview answer: "We use Customer Managed Keys for databases and Secrets Manager
because we can audit every key usage in CloudTrail and control key access independently
of the service's own IAM permissions."
```

---

#### Creating a KMS Key (Console Navigation)

```
AWS Console → Services → KMS (Key Management Service)
  → Customer managed keys → Create key

─── KEY CONFIGURATION ────────────────────────────────────────────────────────
  Key type: Symmetric          ← one key for both encrypt and decrypt (most common)
  Key usage: Encrypt and decrypt
  Key material origin: KMS    ← AWS generates the key material

─── KEY LABELS ───────────────────────────────────────────────────────────────
  Alias: alias/prod-order-service    ← friendly name (reference by alias in code)
  Description: "Encrypts order-service RDS and S3 data"
  Tags: Environment=prod, Service=order-service

─── KEY ADMINISTRATORS ───────────────────────────────────────────────────────
  Select IAM users/roles that can manage this key:
    ✅ devops-admins (IAM group)
    ✅ jenkins-role (to allow Jenkins to create encrypted resources)
  These users can: update/delete/disable the key
  They CANNOT automatically use the key to encrypt/decrypt — that's separate

─── KEY USERS ────────────────────────────────────────────────────────────────
  Select who can USE this key to encrypt/decrypt:
    ✅ order-service-task-role      ← pod IAM role can use the key to read Secrets
    ✅ rds-service-role             ← RDS can use the key to encrypt its data
    ✅ dev-developers (IAM group)   ← devs can read encrypted Secrets Manager values

→ Finish → Key ID: 1234abcd-12ab-34cd-56ef-1234567890ab
→ Key ARN: arn:aws:kms:us-east-1:123456789:key/1234abcd-...
```

**Using a KMS key in code (Spring Boot encrypts/decrypts via SDK):**
```java
// Most of the time KMS is transparent — AWS services use it under the hood.
// You rarely call KMS directly. But if you need to encrypt custom data:

@Service
public class EncryptionService {

    private final KmsClient kmsClient = KmsClient.builder()
            .region(Region.US_EAST_1)
            .credentialsProvider(DefaultCredentialsProvider.create())
            .build();

    private static final String KEY_ARN =
        "arn:aws:kms:us-east-1:123456789:key/1234abcd-12ab-34cd-56ef-1234567890ab";

    public byte[] encrypt(String plaintext) {
        EncryptResponse response = kmsClient.encrypt(EncryptRequest.builder()
                .keyId(KEY_ARN)
                .plaintext(SdkBytes.fromUtf8String(plaintext))
                .build());
        return response.ciphertextBlob().asByteArray();
    }

    public String decrypt(byte[] ciphertext) {
        DecryptResponse response = kmsClient.decrypt(DecryptRequest.builder()
                .keyId(KEY_ARN)
                .ciphertextBlob(SdkBytes.fromByteArray(ciphertext))
                .build());
        return response.plaintext().asUtf8String();
    }
}
```

---

#### KMS-Related Interview Questions

**Q: Your Lambda function throws `AccessDeniedException: kms:Decrypt` when reading a secret from Secrets Manager. What do you check?**
```
The Lambda's execution role needs permission to USE the KMS key that encrypted the secret.

Step 1: Find which KMS key encrypted this secret:
  Secrets Manager → your secret → Encryption key column
  → Shows the KMS key ARN

Step 2: Check the KMS key policy:
  KMS → Customer managed keys → find the key → Key policy tab
  → Does the Lambda's execution role appear under "Key users"? NO → add it.

Step 3: Check the Lambda's IAM role:
  IAM → Roles → lambda-execution-role → Permissions
  → Does it have kms:Decrypt on that key? 
  → If key policy has a resource policy that restricts to specific roles,
    that overrides IAM → must be in BOTH places.

Fix: In KMS key policy, add the Lambda role as a key user.
     OR add this to the Lambda role's IAM policy:
     {
       "Effect": "Allow",
       "Action": "kms:Decrypt",
       "Resource": "arn:aws:kms:us-east-1:123456789:key/1234abcd-..."
     }
```

**Q: What is the difference between SSE-S3 and SSE-KMS for S3 encryption?**
```
SSE-S3 (Server-Side Encryption with S3-managed keys):
  → AWS manages everything
  → No cost for encryption/decryption
  → No audit trail of individual object access
  → Enabled by default on all new S3 buckets

SSE-KMS (Server-Side Encryption with KMS-managed keys):
  → You control the key (can add a key policy, audit in CloudTrail)
  → Every GetObject call is a KMS Decrypt API call → logged in CloudTrail
  → Cost: $0.03 per 10,000 API calls
  → Supports key rotation
  → Required for strict compliance (HIPAA, PCI-DSS)

When to use SSE-KMS:
  → You need to audit exactly who accessed which file and when
  → You need cross-account access to S3 objects
  → Compliance requires customer-managed key
```

---

### 24.8 Summary — What a Developer Needs to Access Each Service

| Service | How to Access | What You Need |
|---------|--------------|---------------|
| **EC2 (public subnet)** | `ssh -i key.pem ec2-user@<public-ip>` | Key pair file + security group allows SSH |
| **EC2 (private subnet)** | SSH via bastion OR Session Manager | Bastion keypair OR IAM SSM permission |
| **RDS** | SSH tunnel via bastion, then connect to localhost:<tunnel-port> | Bastion access + DB credentials from Secrets Manager |
| **EKS** | `aws eks update-kubeconfig` + `kubectl` | IAM permission eks:DescribeCluster + entry in aws-auth ConfigMap |
| **ECR** | `aws ecr get-login-password | docker login ...` | IAM: ecr:GetAuthorizationToken + ecr:BatchGetImage |
| **Secrets Manager** | AWS Console or `aws secretsmanager get-secret-value` | IAM: secretsmanager:GetSecretValue on specific secret ARN |
| **S3** | AWS Console or `aws s3 ls s3://bucket` | IAM: s3:GetObject + s3:ListBucket on specific bucket |
| **CloudWatch Logs** | AWS Console → CloudWatch → Logs | IAM: logs:DescribeLogGroups + logs:GetLogEvents |
| **KMS** | Transparent (used by other services) | IAM: kms:Decrypt on the key — required to read KMS-encrypted data |

---

## 25. TESTING MICROSERVICES IN DEV ENVIRONMENT

> This section covers the difference between testing locally vs testing in the actual DEV environment on AWS, and the exact steps for each scenario.

---

### 25.1 Local vs DEV Environment — Key Differences

```
LOCAL (docker-compose on your laptop):
  ├─ All containers on your machine
  ├─ No AWS services (use WireMock, local PostgreSQL, local Redis)
  ├─ Fastest feedback loop (restart in seconds)
  ├─ Full control — change DB data, restart any service instantly
  ├─ No network latency between services
  └─ Uses local files for config (.env, application-local.yml)

DEV (EKS dev cluster on AWS):
  ├─ Real Kubernetes pods in AWS
  ├─ Real AWS services (actual RDS, actual S3, actual Secrets Manager)
  ├─ Tests your IAM roles, VPC connectivity, security groups
  ├─ Other developers' services running too
  ├─ Slower feedback (build → push ECR → deploy → wait ~2 min)
  └─ Uses ConfigMaps and Secrets from the cluster

When to use which:
  LOCAL:   Unit development, quick iteration, debugging a specific bug
  DEV AWS: Integration testing with real AWS, testing IAM configs,
           testing against other team's real services, pre-PR validation
```

---

### 25.2 How to Hit the DEV API from Your Laptop

**Option A: Via the DEV ALB DNS (simplest — if allowed by security group)**
```bash
# Get the ALB hostname:
kubectl get ingress -n development
# NAME               HOSTS   ADDRESS                                          PORTS
# dev-ingress        *       dev-alb-123.us-east-1.elb.amazonaws.com         80

# Hit the API directly:
curl http://dev-alb-123.us-east-1.elb.amazonaws.com/api/orders/health
curl http://dev-alb-123.us-east-1.elb.amazonaws.com/api/orders

# With auth token:
curl -H "Authorization: Bearer eyJhbGc..." \
     http://dev-alb-123.us-east-1.elb.amazonaws.com/api/orders

# Point your Postman or frontend to:
# http://dev-alb-123.us-east-1.elb.amazonaws.com
```

**Option B: kubectl port-forward (no ALB needed — direct to pod)**
```bash
# Forward a pod's port to your laptop:
kubectl port-forward pod/order-service-7d9f8b-abc12 8080:8080 -n development
# Forwarding from 127.0.0.1:8080 -> 8080
# Forwarding from [::1]:8080 -> 8080

# Now in another terminal:
curl http://localhost:8080/api/orders/health
curl http://localhost:8080/actuator/health

# This is direct pod access — bypasses the ALB, Service, and Ingress
# Useful for: testing a specific pod, debugging a specific instance
# Traffic is encrypted by kubectl to the API server then to the pod

# Port-forward a Kubernetes Service (load-balances across all pods):
kubectl port-forward service/order-service 8080:8080 -n development
```

**Option C: Port-forward the whole stack (DEV DB, Redis, etc.):**
```bash
# Forward DEV RDS to your laptop:
kubectl port-forward pod/db-access-pod 5432:5432 -n development
# Now you can connect DBeaver to localhost:5432 → reaches DEV RDS

# Forward DEV Redis to your laptop:
kubectl port-forward service/redis 6379:6379 -n development
# Now you can use redis-cli to inspect DEV cache
```

---

### 25.3 Deploying Your Code to DEV and Testing It

**The full cycle when you want to test in DEV:**

```bash
# Step 1: Make code change, build JAR
mvn clean package -DskipTests

# Step 2: Build Docker image
docker build --platform=linux/amd64 -t order-service:dev-test .

# Step 3: Login to ECR (if token expired — valid for 12h)
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  123456789.dkr.ecr.us-east-1.amazonaws.com

# Step 4: Tag and push to ECR dev repo
docker tag order-service:dev-test \
  123456789.dkr.ecr.us-east-1.amazonaws.com/dev-order-service:dev-test

docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/dev-order-service:dev-test

# Step 5: Connect to DEV cluster
aws eks update-kubeconfig --region us-east-1 --name dev-eks-cluster --alias dev
kubectl config use-context dev

# Step 6: Deploy your image to DEV namespace
kubectl set image deployment/order-service \
  order-service=123456789.dkr.ecr.us-east-1.amazonaws.com/dev-order-service:dev-test \
  -n development

# Step 7: Watch the rollout
kubectl rollout status deployment/order-service -n development
# Waiting for deployment "order-service" rollout to finish: 0 of 1 updated replicas are available...
# deployment "order-service" successfully rolled out

# Step 8: Check the pod is running
kubectl get pods -n development
# NAME                             READY   STATUS    RESTARTS   AGE
# order-service-7d9f8b-newpod     1/1     Running   0          45s

# Step 9: Test via port-forward or ALB
kubectl port-forward deployment/order-service 8080:8080 -n development
curl http://localhost:8080/api/orders/health
```

---

### 25.4 Reading DEV Logs from CloudWatch

**Via console:**
```
CloudWatch → Logs → Log groups
  → /eks/dev/order-service
  → Log streams: one per pod per day
  → Click most recent stream → see logs

Filter for your test:
  → Filter events: ?ERROR ?WARN   ← see warnings and errors
  → Filter events: "userId=42"   ← see logs for a specific user you're testing with
```

**Via AWS CLI (faster for quick checks):**
```bash
# Get the log group name:
aws logs describe-log-groups \
  --log-group-name-prefix /eks/dev \
  --query 'logGroups[*].logGroupName' \
  --output table

# Tail logs from DEV order-service (last 5 min):
aws logs filter-log-events \
  --log-group-name /eks/dev/order-service \
  --start-time $(date -d '5 minutes ago' +%s000) \
  --filter-pattern "ERROR" \
  --query 'events[*].message' \
  --output text

# Follow logs in real-time (keep running):
aws logs tail /eks/dev/order-service --follow
```

**Via kubectl (simplest — no CloudWatch needed):**
```bash
# Watch pod logs live while you test:
kubectl logs -f deployment/order-service -n development
# OR if there are multiple pods:
kubectl logs -f -l app=order-service -n development --prefix
# output: [pod/order-service-abc12] 2024-01-15 INFO OrderService - ...
#          [pod/order-service-def34] 2024-01-15 INFO OrderService - ...
```

---

### 25.5 Checking DEV Environment Health

**Before testing — verify everything is working:**
```bash
# Are all DEV pods running?
kubectl get pods -n development
# All should be: STATUS=Running, READY=1/1, RESTARTS=0 (or low)

# Are there any recent pod crashes?
kubectl get events -n development --sort-by='.lastTimestamp' | tail -20
# Look for: FailedScheduling, OOMKilling, BackOff messages

# Is the DEV database reachable from pods?
kubectl exec -it deployment/order-service -n development -- \
  nc -vz orders-rds.dev.internal 5432
# Expected: Connection to orders-rds.dev.internal 5432 port succeeded!

# Does the health endpoint respond?
kubectl exec -it deployment/order-service -n development -- \
  wget -qO- http://localhost:8080/actuator/health | python3 -m json.tool
# Should show: {"status":"UP", "components": {"db": {"status":"UP"}, ...}}

# Check current image tag running in DEV:
kubectl get deployment order-service -n development \
  -o jsonpath='{.spec.template.spec.containers[0].image}'
# output: 123456789.dkr.ecr.us-east-1.amazonaws.com/dev-order-service:dev-test
```

---

### 25.6 Testing Specific Scenarios in DEV

**Scenario: Test that your service handles DEV RDS correctly**
```bash
# Port-forward your pod, then test an endpoint that hits the DB:
kubectl port-forward deployment/order-service 8080:8080 -n development

# Create a test order (hits your order-service → DEV RDS):
curl -X POST http://localhost:8080/api/orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <dev-jwt-token>" \
  -d '{"customerId": 1, "product": "Laptop", "quantity": 1}'

# Expected response: {"id": 1, "status": "CREATED", "customerId": 1, ...}

# Verify it was saved to DEV DB:
# Connect to DEV RDS via SSH tunnel (see Section 24.4)
# psql> SELECT * FROM orders WHERE customer_id = 1;
```

**Scenario: Test that your service can read from DEV S3**
```bash
# Upload a test file to DEV S3:
aws s3 cp test-file.pdf s3://myapp-dev-order-attachments/test/test-file.pdf

# Call your API to retrieve it:
curl http://localhost:8080/api/files/presigned-url?key=test/test-file.pdf \
  -H "Authorization: Bearer <dev-jwt-token>"
# Should return a pre-signed URL

# Test the pre-signed URL actually works:
curl -o downloaded.pdf "<presigned-url>"
# Should download the file
```

**Scenario: Test that secrets are loaded correctly from Secrets Manager**
```bash
# Check what secrets your DEV pod is using:
kubectl exec -it deployment/order-service -n development -- env | grep -v PASSWORD | sort
# Should show all env vars (without showing actual passwords)

# Check the health of the datasource specifically:
kubectl exec -it deployment/order-service -n development -- \
  wget -qO- http://localhost:8080/actuator/health | python3 -m json.tool
# Should show:
# {
#   "status": "UP",
#   "components": {
#     "db": {
#       "status": "UP",       ← DB connected using credentials from Secrets Manager
#       "details": {"database": "PostgreSQL"}
#     }
#   }
# }
```

**Scenario: Test calling another microservice in DEV (e.g., customer-service)**
```bash
# Check that order-service can reach customer-service via K8s DNS:
kubectl exec -it deployment/order-service -n development -- \
  wget -qO- http://customer-service.development.svc.cluster.local:8081/actuator/health
# K8s DNS format: <service-name>.<namespace>.svc.cluster.local:<port>

# If this fails → K8s DNS is not resolving → check:
kubectl get service customer-service -n development
# Is the service there? Does the port match?

kubectl exec -it deployment/order-service -n development -- \
  nslookup customer-service.development.svc.cluster.local
# Should resolve to the ClusterIP of customer-service
```

---

### 25.7 Common DEV Environment Issues and Fixes

| Problem | Symptom | Cause | Fix |
|---------|---------|-------|-----|
| **Pod not starting** | `ImagePullBackOff` | Wrong ECR image tag or auth expired | Re-run ECR login, verify image exists in ECR |
| **DB connection fails** | `CrashLoopBackOff`, HikariPool error | Wrong DB hostname or secret not mounted | Check ConfigMap DB URL, check ExternalSecret status |
| **Cannot reach other service** | 503 when calling customer-service | K8s DNS or Service not found | `kubectl get svc -n development`, check DNS with nslookup |
| **IAM error reading S3** | `AccessDeniedException` | IRSA not configured or wrong role ARN | Check ServiceAccount annotation, check IAM role trust policy |
| **Secret not decrypted** | `kms:Decrypt AccessDeniedException` | Lambda/pod role not in KMS key users | Add the pod's IAM role to the KMS key's key users list |
| **Logs not in CloudWatch** | No log streams for your pod | Fluent Bit DaemonSet not running | `kubectl get pods -n kube-system | grep fluent` |
| **Port-forward dies** | `kubectl port-forward` disconnects | Pod restarted or network timeout | Re-run the port-forward command |

---

### 25.8 Interview Q&A — Developer Access and DEV Testing

**Q: How does a new developer get access to the AWS environment?**
> "On day one, DevOps creates an IAM user for them, adds it to the `dev-developers` IAM group (which has scoped permissions for ECR, CloudWatch Logs, and read-only EKS access on the dev cluster), and provides temporary console credentials. The developer configures AWS CLI with their access keys, then runs `aws eks update-kubeconfig` to connect to the dev EKS cluster. DevOps also adds their IAM user ARN to the cluster's `aws-auth` ConfigMap so kubectl commands work. The developer has read-only access to prod logs via the `prod-readonly` group, but cannot deploy to prod — only Jenkins CI/CD can."

**Q: How do you connect to an RDS database in a private subnet?**
> "RDS is in a private subnet with no public access. There are three ways: First, SSH tunneling through a bastion host — you forward a local port through the bastion EC2 to the RDS endpoint, then connect any DB tool to localhost with that port. Second, for Kubernetes environments, you can create a debug pod inside the cluster with psql and connect directly. Third, for production, we use RDS Proxy with IAM token authentication so no passwords are ever used in connection strings."

**Q: How do you test your microservice against real AWS services in the DEV environment?**
> "I build the Docker image locally, push it to the ECR dev repository, then use `kubectl set image` to deploy it to the dev EKS namespace. For quick testing, I use `kubectl port-forward` to expose the pod's port to my laptop and hit it directly with curl or Postman. I watch logs with `kubectl logs -f` to see real-time output. For DB verification, I SSH-tunnel through the bastion to the DEV RDS. This tests the full stack — real DB, real Secrets Manager, real IAM roles — without any mocking."

**Q: Why do developers only have read-only access to production?**
> "Principle of least privilege and separation of concerns. A developer accidentally running `kubectl delete deployment order-service -n production` would cause an outage. Only the CI/CD pipeline (Jenkins) should deploy to production, and only after all tests pass. This also means if a developer's IAM credentials are compromised, the blast radius is limited — an attacker can read logs but cannot modify production infrastructure."

**Q: How does kubectl know which cluster to connect to?**
> "kubectl reads from `~/.kube/config`, which is populated by `aws eks update-kubeconfig`. Each cluster gets a context with a name. You switch between clusters with `kubectl config use-context dev` or `kubectl config use-context prod`. In Jenkins, the pipeline runs `aws eks update-kubeconfig` at the start of the deploy stage — it uses the Jenkins EC2's IAM role (which has eks:DescribeCluster permission) to authenticate, so no static credentials are needed."

**Q: What happens if you accidentally push to the prod ECR repo instead of dev?**
> "Push to ECR doesn't deploy anything — it just stores the image. The image only gets deployed when Jenkins explicitly runs `kubectl set image` with that image tag. Since developers don't have permission to run `kubectl set image` on the production cluster (their IAM user is only in the `prod-readonly` K8s RBAC group), nothing would happen even if they pushed. The image would just sit in ECR unused until the Jenkins pipeline picks it up from the main branch."

---

*This guide covers everything a Java fullstack developer needs for AWS interviews — from architecture fundamentals through to CloudWatch alarms, production debugging, developer access patterns, and end-to-end testing workflows. The sections most frequently tested in senior interviews are: VPC/Security Groups, CI/CD flow, Pod failure analysis, CloudWatch, developer IAM setup, and how to explain a complete deployment end-to-end. Practice explaining the deployment flow out loud — interviewers love walk-through questions.*
