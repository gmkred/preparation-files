# System Design & Low-Level Design — Complete Reference

---

## Table of Contents
1. [Database Normalization](#1-database-normalization)
2. [Threads & Concurrency](#2-threads--concurrency)
3. [Multi-threading in Java](#3-multi-threading-in-java)
4. [Synchronization — Mutex & Semaphore](#4-synchronization--mutex--semaphore)
5. [Atomic Types & Generics](#5-atomic-types--generics)
6. [SOLID Principles](#6-solid-principles)
7. [UML Diagrams](#7-uml-diagrams)
8. [Design Patterns — Creational](#8-design-patterns--creational)
9. [Design Patterns — Structural](#9-design-patterns--structural)
10. [Design Patterns — Behavioral](#10-design-patterns--behavioral)
11. [LLD Interview Types & Approach](#11-lld-interview-types--approach)
12. [Schema Design](#12-schema-design)
13. [System Architecture Patterns](#13-system-architecture-patterns)
14. [NoSQL & Database Selection](#14-nosql--database-selection)

---

## 1. Database Normalization

### What is Normalization?
Normalization is the process of organizing a database to reduce redundancy and improve data integrity by splitting tables into smaller, related ones.

### The Problem — Anomalies
Consider this denormalized table:

| StudentId | Name | Email | BatchId | BatchName |
|-----------|------|-------|---------|-----------|
| 1 | Alice | a@x.com | B1 | Java-2024 |
| 2 | Bob | b@x.com | B1 | Java-2024 |
| 3 | Carol | c@x.com | B2 | Python-2024 |

`BatchId` and `BatchName` are repeated — this causes 3 anomalies:

**1. Insertion Anomaly**
You cannot insert a new batch unless a student exists (StudentId is the PK — a row cannot exist without it).

**2. Deletion Anomaly**
If Carol (the only student in B2) is deleted, the batch Python-2024 is also lost — even though the batch still exists.

**3. Update Anomaly**
If Java-2024 is renamed to JavaFull-2024, you must update every row that mentions it. Missing one row leaves inconsistent data.

### Solution — Split into Normalized Tables

**Students table:**

| StudentId | Name | Email | BatchId |
|-----------|------|-------|---------|
| 1 | Alice | a@x.com | B1 |

**Batches table:**

| BatchId | BatchName |
|---------|-----------|
| B1 | Java-2024 |

Now `BatchName` lives in one place — no anomalies.

---

## 2. Threads & Concurrency

### Process vs Thread

| | Process | Thread |
|---|---------|--------|
| Definition | A program in execution with its own memory space | Smallest unit of CPU execution within a process |
| Memory | Own separate memory | Shares process memory (heap, code, data) |
| Creation cost | Expensive | Cheap |
| Communication | IPC required (Inter Process Communication) | Direct shared memory |

**Process block structure:**
```
Process
├── Code (instructions)
├── Data (heap, global vars)
├── Resources (file handles, I/O)
└── Threads
    ├── Thread-1 (has its own stack + program counter)
    └── Thread-2
```

### Concurrency vs Parallelism

**Concurrency** — Multiple threads in different stages of execution on a single core. Threads take turns via **context switching**.

```
Single Core Timeline:
T1: [run 2s][WAIT 1s]          [run 2s]
T2:          [run 1s][WAIT 2s][run 1s]
             ↑ context switch
```
Total time ≈ 4s instead of 6s — CPU is never idle.

**Parallelism** — Multiple cores each running a thread at exactly the same instant (true simultaneous execution).

```
Core 1: T1 running ─────────────────
Core 2: T2 running ─────────────────  (at the same time)
```

> **Key insight:** Context switching is the OS scheduler pausing one thread and resuming another. It gives the *illusion* of parallelism on a single core.

---

## 3. Multi-threading in Java

### Step 1 — Runnable + Thread (basic)

```java
// 1. Identify the task → create a class
class HelloPrinter implements Runnable {
    @Override
    public void run() {        // task lives here
        System.out.println("Hello from thread!");
    }
}

// 2. Inject into Thread and start
HelloPrinter task = new HelloPrinter();
Thread t = new Thread(task);
t.start();   // creates a NEW thread and calls run() on it
```

> `run()` holds the task. `start()` actually spawns the OS thread. Calling `run()` directly just executes it on the current thread.

### Step 2 — ExecutorService (production way)

Creating a new thread per request is expensive. **ExecutorService** manages a **thread pool** — threads are reused, not destroyed after each task.

```
Client request → [Waiting Queue] → [Thread Pool: T1 T2 T3 T4] → Result
                                         ↑ threads reused ↑
```

```java
ExecutorService executor = Executors.newFixedThreadPool(10);

for (int i = 1; i <= 50; i++) {
    executor.execute(new CubePrinter(i));   // submit Runnable
}

executor.shutdown();   // waits for current tasks, rejects new ones
```

**Thread pool types:**

| Factory method | Behavior |
|---|---|
| `newFixedThreadPool(n)` | Always exactly n threads, queues extras |
| `newCachedThreadPool()` | Grows as needed, removes idle threads after 60s |
| `newSingleThreadExecutor()` | One thread, tasks run sequentially |

### Step 3 — Callable + Future (when you need a return value)

`Runnable.run()` returns `void`. Use `Callable<T>` when the task must return a result.

```java
class ArrayAdder implements Callable<Integer> {
    private List<Integer> list;
    public ArrayAdder(List<Integer> list) { this.list = list; }

    @Override
    public Integer call() {
        return list.stream().mapToInt(i -> i).sum();
    }
}

// In client:
ExecutorService executor = Executors.newFixedThreadPool(2);

Future<Integer> fx = executor.submit(new ArrayAdder(list1));  // non-blocking
Future<Integer> fy = executor.submit(new ArrayAdder(list2));  // non-blocking

int result = fx.get() + fy.get();  // blocks here until both complete
```

**Future** is a placeholder/bucket. `.submit()` returns immediately with an empty bucket; `.get()` waits and fills it.

> Without Future, main thread waits for `x` before starting `y` → sequential.  
> With Future, both tasks start immediately → parallel.

### Thread.join()

```java
Thread t1 = new Thread(task1); t1.start();
Thread t2 = new Thread(task2); t2.start();

t1.join();   // main thread waits until t1 finishes
t2.join();   // main thread waits until t2 finishes

System.out.println("Both done");   // guaranteed to run after t1, t2
```

---

## 4. Synchronization — Mutex & Semaphore

### The Problem — Race Condition

```
Account balance: ₹1000
Thread 1 (Debit ₹200):   Read 1000 → subtract → write 800
Thread 2 (Credit ₹500):  Read 1000 → add     → write 1500

Final balance: ₹1500  ← WRONG (should be ₹1300)
```

Both threads read the same initial value before either writes back.

**Critical Section** — the part of code that reads/writes shared data. **Race Condition** occurs when multiple threads enter the critical section simultaneously.

### Properties of a Good Synchronization Solution

1. **Mutual Exclusion** — only one thread in critical section at a time
2. **Progress** — if no thread is in the CS, a waiting thread must be allowed in
3. **Bounded Waiting** — a thread must not wait forever
4. **No Busy Waiting** — threads should sleep, not spin-check

### Mutex — `synchronized` in Java

Every Java object has a built-in lock (monitor). `synchronized` uses it.

```java
class BankAccount {
    private int balance = 1000;
    private final Object lock = new Object();

    public void debit(int amount) {
        synchronized (lock) {          // acquires lock
            balance -= amount;         // critical section
        }                              // releases lock, notifies waiting threads
    }

    public void credit(int amount) {
        synchronized (lock) {
            balance += amount;
        }
    }
}
```

> Prefer `synchronized(object)` block over `synchronized` method — method-level locks block the entire method even if only one variable needs protection.

### Semaphore — controlling count of concurrent threads

A Semaphore is a counter + synchronization. Use it when you want **N threads** (not just 1) in the critical section.

**Producer-Consumer Example:**

```
Store capacity: 5 shirts
semaProducer = 5 (5 slots to fill)
semaConsumer = 0 (0 shirts to buy yet)

Producer: acquire(semaProducer) → add shirt → release(semaConsumer)
Consumer: acquire(semaConsumer) → remove shirt → release(semaProducer)
```

```java
Semaphore semaProducer = new Semaphore(5);   // 5 produce permits
Semaphore semaConsumer = new Semaphore(0);   // 0 consume permits initially

// Producer thread:
semaProducer.acquire();   // blocks if store is full
store.add(new Shirt());
semaConsumer.release();   // signals consumer: one shirt available

// Consumer thread:
semaConsumer.acquire();   // blocks if store is empty
store.remove();
semaProducer.release();   // signals producer: one slot freed
```

| | Mutex | Semaphore |
|---|---|---|
| Threads allowed | 1 | N (configurable) |
| Use case | Single shared resource | Pool of resources |
| Java keyword | `synchronized` | `java.util.concurrent.Semaphore` |

---

## 5. Atomic Types & Generics

### Atomic Data Types

Instead of wrapping every int/boolean in `synchronized` blocks, Java provides atomic wrappers that are inherently thread-safe:

```java
AtomicInteger counter = new AtomicInteger(0);
counter.incrementAndGet();    // thread-safe, no lock needed
counter.compareAndSet(5, 10); // compare-and-swap — atomic
```

| Primitive | Atomic version |
|---|---|
| `int` | `AtomicInteger` |
| `long` | `AtomicLong` |
| `boolean` | `AtomicBoolean` |
| `Object reference` | `AtomicReference<T>` |

### Generics

Generics let you write type-safe code that works for any type — no casting, no `ClassCastException`.

```java
// Without generics — unsafe
class ObjectPrinter {
    Object value;
    void print() { System.out.println(value); }  // loses type info
}

// With generics — type-safe
class Printer<T> {
    T value;
    void print() { System.out.println(value); }
}

Printer<Integer> intPrinter = new Printer<>();
intPrinter.value = 45;
intPrinter.print();   // 45

Printer<String> strPrinter = new Printer<>();
strPrinter.value = "Alice";
strPrinter.print();   // Alice
```

The compiler enforces the type — `intPrinter.value = "hello"` is a compile error.

---

## 6. SOLID Principles

SOLID = guidelines for writing maintainable, extensible code. Not rules — apply them with judgement.

### Bird Example (running through all 5 principles)

**Naive design:**
```java
class Bird {
    String name;
    void fly() { if(name.equals("crow")) {...} else if(...) {...} }
    void makeSound() { if(name.equals("crow")) {...} ... }
}
```

This is a mess — let's fix it with SOLID.

---

### S — Single Responsibility Principle (SRP)
> Every class/method should have exactly **one reason to change**.

**Violation:** `makeSound()` handles ALL birds with `if-else`. If a new bird is added, this method changes.

**How to detect SRP violation:**
- Methods with multiple `if-else` chains
- "Monster methods" (100+ lines)
- Classes named `Utils`, `Common`, `Helper`

**Fix:** Each bird is its own class with its own `makeSound()`.

---

### O — Open/Closed Principle (OCP)
> Code should be **open for extension** (add new classes) but **closed for modification** (don't change existing code).

**Violation:** Adding a new bird means editing `makeSound()` every time.

**Fix:** Use an abstract class:
```java
abstract class Bird {
    String name;
    abstract void fly();
    abstract void makeSound();
}

class Crow extends Bird {
    void fly() { /* crow-specific */ }
    void makeSound() { System.out.println("Caw caw"); }
}

class Sparrow extends Bird {
    void fly() { /* sparrow-specific */ }
    void makeSound() { System.out.println("Chirp"); }
}
```
Adding a new bird = new class, zero changes to existing code.

---

### L — Liskov Substitution Principle (LSP)
> You must be able to use any child object **wherever a parent is expected**, without breaking correctness.

**Violation:** Penguin extends Bird, but can't fly. `bird.fly()` on a Penguin throws an exception or does nothing — calling code breaks.

```java
void makeBirdDoThings(Bird b) {
    b.fly();        // BREAKS for Penguin
    b.makeSound();
}
```

**Fix:** Separate behaviors into interfaces:
```java
abstract class Bird { void eat(); }      // only fundamental behavior

interface IFlyable  { void fly(); }
interface IDanceable { void dance(); }

class Crow    extends Bird implements IFlyable, IDanceable { ... }
class Penguin extends Bird implements IDanceable           { ... }
```

Now `makeBirdDoThings(IFlyable b)` only accepts flying birds — no runtime surprises.

---

### I — Interface Segregation Principle (ISP)
> Don't force a class to implement methods it doesn't use.

**Violation:** A single `IBird` interface with `fly()`, `dance()`, `swim()` forces Penguin to implement `fly()` and Crow to implement `swim()`.

**Fix:** Split into focused interfaces:
```java
interface IFlyable  { void fly(); }
interface ISwimmable { void swim(); }
interface IDanceable { void dance(); }
```

Each class implements only what it actually does.

---

### D — Dependency Inversion Principle (DIP)
> High-level modules must not depend on low-level modules. Both should depend on **abstractions**.

**Violation:**
```java
class UserService {
    MySQLDatabase db = new MySQLDatabase();   // tightly coupled to MySQL
}
```

**Fix:** Depend on the interface:
```java
interface Database { void save(User u); }

class UserService {
    private final Database db;
    UserService(Database db) { this.db = db; }  // inject via constructor
}

// Now you can swap databases without touching UserService:
new UserService(new MySQLDatabase());
new UserService(new PostgresDatabase());
```

---

## 7. UML Diagrams

### Use Case Diagram — "What does the system do and for whom?"

**5 keywords:**
1. **System boundary** — rectangle box; inside = your system
2. **Use case** — oval; always a VERB ("Place Order", "Login")
3. **Actor** — stick figure; always a NOUN ("Customer", "Admin")
4. **Include** — parent always calls child (mandatory step)
5. **Extend** — variant/optional behavior ("Login" extended by "LoginByFB")

**Include vs Extend:**
```
placeOrder ──<<include>>──► selectAddress
placeOrder ──<<include>>──► pay

login ◄──<<extend>>── loginByEmail
login ◄──<<extend>>── loginByPhone
```

---

### Class Diagram — "How are classes structured and related?"

**Class box format:**
```
+-----------------------------+
|        ClassName            |   ← name (Italics if Abstract)
+-----------------------------+
| - name: String              |   ← attributes: <modifier> <name>: <type>
| # age: int                  |
| + email: String             |
+-----------------------------+
| + getName(): String         |   ← methods: <modifier> <name>(params): return
| + setName(n: String): void  |
+-----------------------------+
```

Access modifiers: `+` public, `-` private, `#` protected, nothing = default.  
Static = underline. Final = bold. Abstract class = italics.

**Relationships:**

| Relationship | Symbol | Meaning |
|---|---|---|
| Inheritance (IS-A) | Arrow from child to parent | `extends` or `implements` |
| Composition (HAS-A tight) | Filled diamond ◆ | Child cannot exist without parent |
| Aggregation (HAS-A loose) | Open diamond ◇ | Child exists independently |

**Example:**
- `User` ◆→ `Address` — Composition (delete user → delete address)
- `Instructor` ◇→ `Batch` — Aggregation (delete instructor, batch still exists)
- `PhonePe` ◇→ `BankAPIAdapter` — Aggregation (loose coupling)

---

## 8. Design Patterns — Creational

Creational patterns control **how objects are created**.

---

### 8.1 Singleton Pattern

**Definition:** Ensure a class has only **one instance** globally, with a single access point.

**When to use:**
- Database connection pool (one pool shared by all)
- Logger (all logs go to one file/stream)
- Config manager (one source of truth)
- Thread pool

**Why one instance?** Creating multiple DB connection objects wastes resources since the DB itself allows only N connections anyway.

**Basic implementation:**
```java
public class DatabasePool {
    private static DatabasePool instance;   // the single instance

    private DatabasePool() {}              // private constructor — no `new`

    public static DatabasePool getInstance() {
        if (instance == null) {
            instance = new DatabasePool();
        }
        return instance;
    }
}
```

**Problem with multi-threading — Double Checked Locking:**
```java
public class DatabasePool {
    // volatile ensures visibility across threads
    private static volatile DatabasePool instance;

    private DatabasePool() {}

    public static DatabasePool getInstance() {
        if (instance == null) {                        // check 1 (no lock)
            synchronized (DatabasePool.class) {
                if (instance == null) {                // check 2 (with lock)
                    instance = new DatabasePool();
                }
            }
        }
        return instance;
    }
}
```

Why double check? If two threads both pass check 1 simultaneously, only one acquires the lock and creates the instance. The second check prevents the second thread from creating a duplicate.

**Eager loading (simpler alternative):**
```java
private static final DatabasePool INSTANCE = new DatabasePool();  // created at class load
```
Cons: created even if never used; slower startup.

---

### 8.2 Builder Pattern

**Definition:** Use a helper Builder class to validate all data **before** creating the actual object.

**Problem:**
```java
// Constructor hell — 10 params, easy to mix up order
Student s = new Student("Alice", 25, "alice@x.com", "9999999999", 2024, "CSE", ...);
```

Also: if validation runs inside the constructor, the object is created first, then found invalid — wasteful.

**Solution:**
```java
public class Student {
    private final String name;
    private final int age;
    private final String email;
    private final String phone;

    private Student(Builder b) {    // private — only Builder can call this
        this.name = b.name;
        this.age = b.age;
        this.email = b.email;
        this.phone = b.phone;
    }

    // Static nested Builder class
    public static class Builder {
        private String name, email, phone;
        private int age;

        public Builder name(String name)   { this.name = name;   return this; }
        public Builder age(int age)        { this.age = age;     return this; }
        public Builder email(String email) { this.email = email; return this; }
        public Builder phone(String phone) { this.phone = phone; return this; }

        private void validate() {
            if (age < 22) throw new IllegalArgumentException("Age must be >= 22");
            if (!phone.matches("\\d{10}")) throw new IllegalArgumentException("Invalid phone");
            if (name == null || name.isBlank()) throw new IllegalArgumentException("Name required");
        }

        public Student build() {
            validate();                // validate BEFORE creating Student
            return new Student(this);  // Student only created if valid
        }
    }

    public static Builder builder() { return new Builder(); }
}

// Usage — readable, validates before creation:
Student s = Student.builder()
    .name("Alice")
    .age(25)
    .email("alice@x.com")
    .phone("9876543210")
    .build();    // throws exception here if invalid, no Student object wasted
```

**Benefits:**
- Readable named parameters (no more parameter order confusion)
- Validation before object creation (no half-baked objects)
- Private constructor forces use of Builder
- Supports optional fields without constructor overloading

---

### 8.3 Prototype Pattern

**Definition:** Clone an existing object instead of creating from scratch. Useful when most attributes are shared and only a few change.

**Problem with naive copying:**
```java
// Client code — violates SRP and OCP
Student s = new Student("Alice", 25);
if (s instanceof IntelligentStudent) {
    copy = new IntelligentStudent((IntelligentStudent) s);
} else {
    copy = new Student(s);
}
```

**Fix — let the object copy itself:**
```java
abstract class Student {
    String name;
    int age;
    abstract Student copy();   // each class knows how to copy itself
}

class IntelligentStudent extends Student {
    int iq;

    @Override
    IntelligentStudent copy() {
        IntelligentStudent copy = new IntelligentStudent();
        copy.name = this.name;
        copy.age = this.age;
        copy.iq = this.iq;
        return copy;
    }
}
```

**Real-world use case:**
```java
// SearchAPICall has url, location, device, authToken, searchQuery
// url/location/device/authToken are the same for most calls

SearchAPICall prototype = getSearchPrototype();  // pre-filled base

SearchAPICall s1 = prototype.copy();
s1.searchQuery = "Java design patterns";

SearchAPICall s2 = prototype.copy();
s2.searchQuery = "System design interview";
// All other fields already filled from prototype
```

---

### 8.4 Registry Pattern

**Definition:** A Map of named prototypes. Retrieve a prototype by key and clone it.

Used when you need multiple different prototypes and want to manage them centrally.

```java
public class StudentRegistry {
    private final Map<String, Student> registry = new HashMap<>();

    public void register(String key, Student prototype) {
        registry.put(key, prototype);
    }

    public Student get(String key) {
        Student proto = registry.get(key);
        if (proto == null) throw new IllegalArgumentException("No prototype for: " + key);
        return proto.copy();   // always return a copy, not the prototype itself
    }
}

// Setup:
StudentRegistry reg = new StudentRegistry();
reg.register("Apr2024", studentApr2024Prototype);
reg.register("May2024", studentMay2024Prototype);

// Usage:
Student alice = reg.get("Apr2024");
alice.name = "Alice";
```

---

### 8.5 Factory Patterns

#### Simple Factory / Factory Method

**Definition:** A method whose sole job is to create and return an object.

```java
// Inside OrderService:
private Order createOrder(OrderType type) {   // factory method
    if (type == PRIORITY) return new PriorityOrder();
    return new NormalOrder();
}
```

The method has one responsibility — object creation — nothing else.

---

#### Abstract Factory

**Definition:** A collection of factory methods grouped into an interface. Fixes SRP violation when one class both does operations AND creates objects.

**Example:** `Database` interface should only handle DB operations. Object creation moves to `DatabaseFactory`:

```java
interface Database {
    boolean connect();
    void setPoolSize(int size);
}

interface DatabaseFactory {   // Abstract Factory
    Query createQuery();
    Transaction createTransaction();
}

class MySQLDatabase implements Database { ... }
class MySQLFactory implements DatabaseFactory {
    public Query createQuery() { return new MySQLQuery(); }
    public Transaction createTransaction() { return new MySQLTransaction(); }
}
```

Benefits: ISP applied (two focused interfaces), SRP maintained.

---

#### Practical Factory

**Definition:** The factory that creates the appropriate factory based on config. The user only knows one entry point.

```java
// Cross-platform UI — user only knows Flutter class
class Flutter {
    private String platform;   // "ANDROID" or "IOS"

    public UIFactory createUIFactory() {
        if (platform.equals("ANDROID")) return new AndroidUIFactory();
        if (platform.equals("IOS"))     return new IOSUIFactory();
        throw new UnsupportedOperationException();
    }
}

interface UIFactory {
    Button createButton();
    Menu createMenu();
    Dropdown createDropdown();
}

class AndroidUIFactory implements UIFactory { ... }
class IOSUIFactory implements UIFactory { ... }
// Adding Windows? Just add WindowsUIFactory — no change to existing code (OCP)
```

User calls `flutter.createUIFactory()` — gets the right factory without knowing what's behind it.

---

## 9. Design Patterns — Structural

Structural patterns deal with **how classes and objects are composed**.

---

### 9.1 Adapter Pattern

**Definition:** An intermediary layer that translates one interface into another. Keeps your code decoupled from third-party libraries.

**Real-world analogy:** Apple's USB-C port + adapters. Your MacBook only knows USB-C; the adapter translates to HDMI/USB-A/Ethernet.

**Problem — tight coupling:**
```java
class PhonePe {
    YesBankAPI yesBankAPI = new YesBankAPI();   // tightly coupled

    void debit(long phone, double amount) {
        yesBankAPI.debitAmount(phone, amount);  // direct call
    }
}
// Now ICICI offers better rates → changing here requires retesting everything
```

**Fix — Adapter layer:**
```java
interface BankAPIAdapter {
    void debit(long phoneNumber, double amount);
    void credit(long phoneNumber, double amount);
}

class YesBankAdapter implements BankAPIAdapter {
    private YesBankAPI api = new YesBankAPI();

    @Override
    public void debit(long phone, double amount) {
        // YesBank might use different param names/types — adapter converts
        api.debitFromAccount(String.valueOf(phone), (float) amount);
    }
    // ... credit similarly
}

class ICICIBankAdapter implements BankAPIAdapter {
    private ICICIBankAPI api = new ICICIBankAPI();
    // ... converts ICICI's interface
}

class PhonePe {
    private BankAPIAdapter bankAdapter;   // depends on abstraction

    PhonePe(BankAPIAdapter adapter) { this.bankAdapter = adapter; }

    void debit(long phone, double amount) {
        bankAdapter.debit(phone, amount);   // no coupling to specific bank
    }
}

// Switching banks — zero change in PhonePe:
new PhonePe(new YesBankAdapter());
new PhonePe(new ICICIBankAdapter());
```

**Steps to apply Adapter:**
1. Never call 3rd party code directly in business logic
2. Define an interface for what you need from the 3rd party
3. Create an Adapter class per 3rd party that implements your interface
4. Inject the adapter into your service

---

### 9.2 Facade Pattern

**Definition:** A simplified interface that hides a complex subsystem behind a clean entry point.

**Analogy:** A Relationship Manager at a bank. You just say "I want an FD" — the RM handles all the complex paperwork internally.

**Problem — Amazon class doing too much:**
```java
class Amazon {
    void orderPlaced() {
        inventoryService.check();
        inventoryService.update();
        sellerService.notifySeller();
        logisticsService.createPickupRequest();
        emailService.notifyCustomer();
        notificationService.sendPushNotification();
        // 20 more lines...
    }
}
```

**Fix — Facade classes:**
```java
class OrderPlacedFacade {
    void handle() {
        inventoryService.check();
        inventoryService.update();
        sellerService.notifySeller();
        logisticsService.createPickupRequest();
        emailService.notifyCustomer();
        notificationService.sendPushNotification();
    }
}

class OrderCancelledFacade {
    void handle() { /* cancellation operations */ }
}

class Amazon {
    private OrderPlacedFacade orderPlacedFacade;
    private OrderCancelledFacade orderCancelledFacade;

    void orderPlaced()    { orderPlacedFacade.handle(); }    // clean and simple
    void orderCancelled() { orderCancelledFacade.handle(); }
}
```

**Rule:** Whenever a method does too much (6+ operations), extract it to a Facade/Helper class.

---

### 9.3 Decorator Pattern

**Definition:** Wrap an object with another object that adds behavior, while keeping the same interface. You can stack decorators.

**Problem — Ice cream shop:**
```
Cone + Vanilla Scoop + Chocolate Syrup + Vanilla Scoop
```
We need to track: order of additions, cost sum, description in order.

```java
interface IceCream {
    double getCost();
    String getDescription();
}

// Base (Cone — no wrapping needed)
class VanillaCone implements IceCream {
    public double getCost()        { return 30.0; }
    public String getDescription() { return "Vanilla Cone"; }
}

// Decorator (Topping — wraps an existing IceCream)
class ChocolateSyrup implements IceCream {
    private IceCream base;   // wraps the previous ice cream

    ChocolateSyrup(IceCream base) { this.base = base; }

    public double getCost()        { return base.getCost() + 10.0; }
    public String getDescription() { return base.getDescription() + " + Choco Syrup"; }
}

class VanillaScoop implements IceCream {
    private IceCream base;
    VanillaScoop(IceCream base) { this.base = base; }
    public double getCost()        { return base.getCost() + 20.0; }
    public String getDescription() { return base.getDescription() + " + Vanilla Scoop"; }
}

// Building the order (ORDER IS PRESERVED):
IceCream order = new VanillaCone();
order = new VanillaScoop(order);       // wrap
order = new ChocolateSyrup(order);     // wrap again
order = new VanillaScoop(order);       // wrap again

System.out.println(order.getDescription());
// "Vanilla Cone + Vanilla Scoop + Choco Syrup + Vanilla Scoop"
System.out.println(order.getCost());   // 80.0
```

**Where decorators appear in real life:**
- Java I/O: `new BufferedReader(new FileReader("file.txt"))` — BufferedReader decorates FileReader
- HTTP middleware chains
- `@Override`, `@Getter`, `@Setter` annotations — decorating behavior
- CSS classes stacking styles on HTML elements

---

### 9.4 Flyweight Pattern

**Definition:** Share common (intrinsic) data across many objects. Only keep unique (extrinsic) data per object.

**Problem — PUBG bullets:**
```
100,000 bullets × 1120 bytes each = 112 MB RAM
```

```
Bullet {
    weight, radius, damage, speed, gunType, range = same for all M416 bullets (intrinsic)
    direction, currentCoords, targetCoords = different per bullet (extrinsic)
}
```

**Fix — split into two classes:**
```java
class BulletType {   // SHARED — one object per bullet type
    float weight, radius, damage, speed, range;
    byte[] image;   // ~1KB
}

class Bullet {       // UNIQUE per bullet — references shared BulletType
    BulletType type;   // pointer (8 bytes) instead of duplicating 1KB
    float x, y, z;    // current coordinates  ~12 bytes
    float tx, ty, tz; // target coordinates   ~12 bytes
    float[] direction; // ~12 bytes
}
// Total per Bullet: ~50 bytes (was 1120 bytes)

// Registry of BulletTypes (Flyweight factory):
Map<String, BulletType> bulletTypes = new HashMap<>();
bulletTypes.put("M416_5.56", new BulletType(...));   // created once
```

100,000 bullets × 50 bytes = 5 MB (was 112 MB). The `BulletType` objects are shared.

---

## 10. Design Patterns — Behavioral

Behavioral patterns deal with **how objects communicate and perform actions**.

---

### 10.1 Strategy Pattern

**Definition:** When there are multiple algorithms/approaches to achieve the same goal, encapsulate each in its own class. Swap them at runtime without changing the caller.

**Problem — Google Maps routing:**
```java
class GoogleMaps {
    void findPath(String src, String dest, String mode) {
        if (mode.equals("CAR"))  { /* car routing logic */ }
        else if (mode.equals("BIKE")) { /* bike logic */ }
        else if (mode.equals("WALK")) { /* walk logic */ }
        // Adding TRAIN? Must modify this method → OCP violation
    }
}
```

**Fix — Strategy Pattern:**
```java
interface PathCalculator {
    List<Location> findPath(Location src, Location dest);
}

class CarPathCalculator  implements PathCalculator { ... }
class BikePathCalculator implements PathCalculator { ... }
class WalkPathCalculator implements PathCalculator { ... }
// Adding TRAIN: new TrainPathCalculator class — zero changes elsewhere (OCP)

class PathCalculatorFactory {
    public PathCalculator get(String mode) {
        return switch (mode) {
            case "CAR"  -> new CarPathCalculator();
            case "BIKE" -> new BikePathCalculator();
            case "WALK" -> new WalkPathCalculator();
            default     -> throw new IllegalArgumentException("Unknown mode: " + mode);
        };
    }
}

class GoogleMaps {
    private PathCalculatorFactory factory;

    void findPath(Location src, Location dest, String mode) {
        PathCalculator calculator = factory.get(mode);
        List<Location> route = calculator.findPath(src, dest);
        displayRoute(route);
    }
}
```

> `PathCalculator` implementations have no state (they just compute). Make them Singletons to avoid recreating them on every call.

**When to use Strategy:** You see a method with if-else chains where each branch represents a different algorithm doing the same job.

---

### 10.2 Observer Pattern

**Definition:** When one event triggers multiple reactions, use a Publisher-Subscriber model. Publishers broadcast events; Subscribers register to receive them. Easy to add/remove reactions without changing the publisher.

**Problem — order placed triggers many actions:**
```java
void orderPlaced() {
    generateInvoice();
    sendSMS();
    sendEmail();
    updateTracking();
    runAnalytics();
    // Adding loyalty points? Must edit this method → OCP violation
}
```

**Fix — Observer Pattern:**
```java
// Step 1: Interface for all subscribers
interface OrderPlacedSubscriber {
    void onOrderPlaced(Order order);
}

// Step 2: Implement subscribers
class NotificationService implements OrderPlacedSubscriber {
    public void onOrderPlaced(Order order) { sendSMS(order); sendEmail(order); }
}

class InvoiceGenerator implements OrderPlacedSubscriber {
    public void onOrderPlaced(Order order) { generateInvoice(order); }
}

class AnalyticsService implements OrderPlacedSubscriber {
    public void onOrderPlaced(Order order) { updateDashboard(order); }
}

// Step 3: Publisher manages subscribers
class Amazon {
    private List<OrderPlacedSubscriber> subscribers = new ArrayList<>();

    public void subscribe(OrderPlacedSubscriber s)   { subscribers.add(s); }
    public void unsubscribe(OrderPlacedSubscriber s) { subscribers.remove(s); }

    public void orderPlaced(Order order) {
        for (OrderPlacedSubscriber s : subscribers) {
            s.onOrderPlaced(order);   // notify all
        }
    }
}

// Setup:
Amazon amazon = new Amazon();
amazon.subscribe(new NotificationService());
amazon.subscribe(new InvoiceGenerator());
amazon.subscribe(new AnalyticsService());

// Adding loyalty points later — just subscribe:
amazon.subscribe(new LoyaltyPointsService());  // zero change to Amazon class
```

**Real-world Observer uses:**
- Event listeners (button click → multiple handlers)
- Message queues (Kafka: one topic, many consumer groups)
- Spring Events (`@EventListener`)
- Stock price changes notifying multiple UI components

---

## 11. LLD Interview Types & Approach

### Three Types of LLD Interviews

| Type | Companies | Time | Focus |
|---|---|---|---|
| **Theoretical** | Old tech, service-based, banks | 45 min | OOP concepts, Java syntax, SOLID |
| **Design** | Amazon, Google, Walmart, Atlassian | 60 min | Class diagrams, design patterns, schema |
| **Machine Coding** | Zepto, Swiggy, Flipkart, startups | 120 min | Full working code from a PRD |

### How to Approach Design Round (60 min)

**Step 0** — Clarify scope
- Do you need to persist data?
- How do users interact? (CLI / API / UI?)
- What features are MVP vs nice-to-have?

**Step 1** — Gather requirements and suggest features
- State what you're assuming, ask for confirmation
- Think edge cases and future extensibility

**Step 2** — Identify entities (Nouns from requirements)
- Physical nouns → classes
- Behaviors → methods

**Step 3** — Class diagram
- Show relationships (IS-A, HAS-A, composition, aggregation)
- Use access modifiers, return types

**Step 4** — Design patterns
- Explain WHY you chose each pattern
- Show how it prevents SRP/OCP violations

**Step 5** — Schema design

### Tic Tac Toe — Machine Coding Walk-through

**Requirements:**
- N×N board (user-defined)
- N-1 players (at most 1 bot)
- Unique symbols per player
- Win: same symbol fills a row, column, or diagonal
- Support: undo, replay, bot with difficulty levels

**Class diagram highlights:**
```
Game
├── Board (List<List<Cell>>)
├── List<Player> (includes Bot extends Player)
├── List<Move>
├── List<Board> boardStates   ← for undo
├── WinningStrategy           ← Strategy pattern
└── GameStatus (IN_PROGRESS, WIN, DRAW)

Bot extends Player
└── BotPlayingStrategy        ← Strategy pattern (Easy/Medium/Hard)
```

**Design patterns used:**
- **Builder** — `Game.Builder` validates players, bots, symbols before creating Game
- **Strategy** — `WinningStrategy` (O(1) winner check), `BotPlayingStrategy` (difficulty)
- **Observer** — (can be added for game events)

**Winning in O(1):**
```
Maintain per-symbol counters:
- N HashMaps for rows
- N HashMaps for cols
- 1 HashMap for left diagonal
- 1 HashMap for right diagonal

On each move:
  rowMap[row][symbol]++
  colMap[col][symbol]++
  if on left diagonal:  leftDiag[symbol]++
  if on right diagonal: rightDiag[symbol]++
  if any counter == N → winner found → O(1) per check
```

**Undo in O(1) — Doraemon approach:**
```
List<Board> boardStates   ← snapshot after each move

Undo 2 moves:
  currentBoard = boardStates.get(boardStates.size() - 3)
```
Trade-off: uses more memory (O(moves × N²)) but undo is instant.

---

## 12. Schema Design

### Cardinality → How to implement

| Relationship | Example | Implementation |
|---|---|---|
| One-to-One | Person ↔ Aadhaar | FK on either side |
| One-to-Many | Person → Cars | FK on the "many" side (Car.personId) |
| Many-to-Many | Students ↔ Courses | Junction/mapping table (student_id, course_id) |

**M-M Example:**
```sql
-- Actor and Movie are M-M
CREATE TABLE actor_movie (
    actor_id  INT REFERENCES actors(id),
    movie_id  INT REFERENCES movies(id),
    PRIMARY KEY (actor_id, movie_id)
);
```

---

## 13. System Architecture Patterns

### Layered (MVC) Architecture

All similar components grouped together:

```
/controllers   → handle HTTP request/response
/services      → business logic
/repositories  → database access (DAO)
/models        → entity classes
```

Simple, standard, familiar to most teams.

---

### Domain-Driven Architecture

Each domain/entity owns its full stack:

```
/user
  UserController
  UserService
  UserRepository

/product
  ProductController
  ProductService
  ProductRepository

/payment
  PaymentController
  PaymentService
  PaymentRepository
```

**Advantage:** Each domain is self-contained — easier to extract into independent microservices later.

**Interview tip:** Code feature by feature. Implement full Controller + Service + Repository for one entity before moving to the next — ensures at least one complete feature in the time limit.

---

## 14. NoSQL & Database Selection

### Why NoSQL?

ACID properties (Atomicity, Consistency, Isolation, Durability) are hard in distributed systems:
- **Atomicity** — transactions across multiple machines are risky
- **Consistency** — sometimes you trade consistency for low latency (eventual consistency)
- **Durability** — sometimes you store in cache, accepting possible data loss

### Types of NoSQL Databases

| Type | Examples | Best for | Query by |
|---|---|---|---|
| **Key-Value** | Redis, DynamoDB | Caching, session data | Key only |
| **Document** | MongoDB, Elasticsearch, Firestore | Variable schema per entity | Any attribute |
| **Columnar** | Cassandra | Time-series, write-heavy workloads | Column families |
| **Graph** | Neo4J | Relationships (social network, fraud) | Graph traversal |

**Key-Value DB:**
```
{ "user:123": { ... blob ... } }
```
Query only by `user:123` — can't query by name/email. Fast O(1) reads.
- Redis: in-memory, no persistence needed
- DynamoDB: persistent, managed

**Document DB (MongoDB):**
```json
Products: [
  { "id": 121, "name": "iPhone", "os": "iOS" },
  { "id": 132, "fabric": "cotton", "brand": "Nike" }
]
```
Flexible schema — products can have different attributes. Rich querying on any field.

### NoSQL vs SQL — Decision Guide

Use **SQL (PostgreSQL/MySQL)** when:
- Data is structured and relational
- ACID transactions are required (banking, payments)
- Complex joins and aggregations needed

Use **NoSQL** when:
- High write throughput (Cassandra)
- Flexible/variable schema (MongoDB)
- Simple key lookups at scale (Redis/DynamoDB)
- Full-text search (Elasticsearch)
- Graph relationships (Neo4J)

> Most NoSQL databases handle sharding internally. In SQL, you manage sharding at the application server level — extra complexity.

---

## Quick Reference — Design Pattern Cheat Sheet

| Pattern | Category | Trigger (when to use) | Key Idea |
|---|---|---|---|
| Singleton | Creational | Shared resource, expensive creation | One instance, private constructor |
| Builder | Creational | Many params, validate before creation | Helper class validates, then builds |
| Prototype | Creational | Copy objects, shared base attributes | Object clones itself |
| Registry | Creational | Multiple named prototypes | Map<String, Prototype> |
| Factory Method | Creational | Method that only creates objects | Single factory method |
| Abstract Factory | Creational | Group of factory methods | Interface of factory methods |
| Practical Factory | Creational | Create right factory based on config | Factory of factories |
| Adapter | Structural | Integrating 3rd party / legacy code | Interface + impl per vendor |
| Facade | Structural | Complex subsystem, simple entry point | Helper class hides complexity |
| Decorator | Structural | Stack behaviors, build incrementally | Wrap object with same interface |
| Flyweight | Structural | Millions of similar objects, memory | Share intrinsic, split extrinsic |
| Strategy | Behavioral | Multiple algorithms, same goal | One interface, multiple impls |
| Observer | Behavioral | One event, many reactions | Publisher/subscriber with interface |
