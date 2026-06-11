
# Helper functions
function Para($text, $bold = $false, $indent = 0) {
    $indAttr = if ($indent -gt 0) { "<w:ind w:left=`"$($indent * 360)`"/>" } else { "" }
    if ($bold) {
        return "<w:p><w:pPr>$indAttr</w:pPr><w:r><w:rPr><w:b/><w:bCs/></w:rPr><w:t xml:space=`"preserve`">$text</w:t></w:r></w:p>"
    }
    return "<w:p><w:pPr>$indAttr</w:pPr><w:r><w:t xml:space=`"preserve`">$text</w:t></w:r></w:p>"
}

function H1($text) {
    return "<w:p><w:pPr><w:pStyle w:val=`"Heading1`"/></w:pPr><w:r><w:t>$text</w:t></w:r></w:p>"
}

function H2($text) {
    return "<w:p><w:pPr><w:pStyle w:val=`"Heading2`"/></w:pPr><w:r><w:t>$text</w:t></w:r></w:p>"
}

function H4($text) {
    return "<w:p><w:pPr><w:pStyle w:val=`"Heading4`"/></w:pPr><w:r><w:t>$text</w:t></w:r></w:p>"
}

function Code($text) {
    $escaped = $text -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;'
    return "<w:p><w:pPr><w:shd w:val=`"clear`" w:color=`"auto`" w:fill=`"F2F2F2`"/><w:ind w:left=`"360`"/></w:pPr><w:r><w:rPr><w:rFonts w:ascii=`"Courier New`" w:hAnsi=`"Courier New`"/><w:sz w:val=`"18`"/><w:szCs w:val=`"18`"/></w:rPr><w:t xml:space=`"preserve`">$escaped</w:t></w:r></w:p>"
}

function Bullet($text, $level = 0) {
    $ilvl = $level
    $numId = 1
    $escaped = $text -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;'
    return "<w:p><w:pPr><w:pStyle w:val=`"ListParagraph`"/><w:numPr><w:ilvl w:val=`"$ilvl`"/><w:numId w:val=`"$numId`"/></w:numPr></w:pPr><w:r><w:t xml:space=`"preserve`">$escaped</w:t></w:r></w:p>"
}

function MixedPara($parts) {
    # parts: array of @{text=...; bold=$false; code=$false}
    $runs = ""
    foreach ($p in $parts) {
        $escaped = $p.text -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;'
        if ($p.bold -and $p.code) {
            $runs += "<w:r><w:rPr><w:b/><w:bCs/><w:rFonts w:ascii=`"Courier New`" w:hAnsi=`"Courier New`"/><w:sz w:val=`"18`"/><w:szCs w:val=`"18`"/></w:rPr><w:t xml:space=`"preserve`">$escaped</w:t></w:r>"
        } elseif ($p.bold) {
            $runs += "<w:r><w:rPr><w:b/><w:bCs/></w:rPr><w:t xml:space=`"preserve`">$escaped</w:t></w:r>"
        } elseif ($p.code) {
            $runs += "<w:r><w:rPr><w:rFonts w:ascii=`"Courier New`" w:hAnsi=`"Courier New`"/><w:sz w:val=`"18`"/><w:szCs w:val=`"18`"/></w:rPr><w:t xml:space=`"preserve`">$escaped</w:t></w:r>"
        } else {
            $runs += "<w:r><w:t xml:space=`"preserve`">$escaped</w:t></w:r>"
        }
    }
    return "<w:p>$runs</w:p>"
}

function EmptyLine() {
    return "<w:p><w:pPr></w:pPr></w:p>"
}

function PageBreak() {
    return "<w:p><w:r><w:br w:type=`"page`"/></w:r></w:p>"
}

# Build the new section XML
$newSection = @()

$newSection += PageBreak

# ===== MAIN HEADING =====
$newSection += H1("N+1 PROBLEM IN HIBERNATE")

# ===== WHAT IS IT =====
$newSection += H2("1. What Is the N+1 Problem?")
$newSection += Para("The N+1 problem occurs when an ORM executes 1 SQL query to load N parent entities, then fires N additional queries — one per entity — to lazily load their associated children. Total: N+1 database round trips.")
$newSection += EmptyLine
$newSection += Para("Classic trigger: iterating over a collection in LAZY mode without an explicit JOIN fetch.")
$newSection += EmptyLine
$newSection += MixedPara(@(
    @{text="Example: "; bold=$true; code=$false},
    @{text="Fetching 100 Authors → accessing their books → fires 101 SQL queries."; bold=$false; code=$false}
))

# ===== PROBLEM DEMO =====
$newSection += EmptyLine
$newSection += H2("2. Reproducing the Problem")
$newSection += Para("Entity setup:")
$newSection += Code("@Entity")
$newSection += Code("public class Author {")
$newSection += Code("    @Id Long id;")
$newSection += Code("    String name;")
$newSection += Code("")
$newSection += Code("    @OneToMany(mappedBy = `"author`", fetch = FetchType.LAZY)")
$newSection += Code("    private List<Book> books;  // lazy by default")
$newSection += Code("}")
$newSection += EmptyLine
$newSection += Para("Problematic code:")
$newSection += Code("List<Author> authors = em.createQuery(")
$newSection += Code("    `"SELECT a FROM Author a`", Author.class)")
$newSection += Code("    .getResultList();               // Query 1: SELECT * FROM author")
$newSection += Code("")
$newSection += Code("for (Author a : authors) {")
$newSection += Code("    System.out.println(a.getBooks().size());")
$newSection += Code("    // Each call fires: SELECT * FROM book WHERE author_id = ?")
$newSection += Code("    // → N separate queries for N authors")
$newSection += Code("}")
$newSection += Code("// TOTAL: 1 + N queries (N+1 problem)")
$newSection += EmptyLine
$newSection += Para("SQL output in logs (hibernate.show_sql=true):")
$newSection += Code("Hibernate: select * from author")
$newSection += Code("Hibernate: select * from book where author_id=1")
$newSection += Code("Hibernate: select * from book where author_id=2")
$newSection += Code("Hibernate: select * from book where author_id=3  -- ...N more")

# ===== SOLUTIONS =====
$newSection += EmptyLine
$newSection += H2("3. Solutions")

# --- JOIN FETCH ---
$newSection += H4("Solution 1: JOIN FETCH in JPQL (Most Common Answer)")
$newSection += Para("Fetches parent + children in a SINGLE SQL JOIN query. Best for small-to-medium result sets.")
$newSection += Code("List<Author> authors = em.createQuery(")
$newSection += Code("    `"SELECT DISTINCT a FROM Author a JOIN FETCH a.books`",")
$newSection += Code("    Author.class).getResultList();")
$newSection += Code("")
$newSection += Code("// SQL: SELECT DISTINCT a.*, b.* FROM author a")
$newSection += Code("//      INNER JOIN book b ON b.author_id = a.id")
$newSection += EmptyLine
$newSection += Para("Spring Data JPA equivalent:")
$newSection += Code("@Query(`"SELECT DISTINCT a FROM Author a JOIN FETCH a.books`")")
$newSection += Code("List<Author> findAllWithBooks();")
$newSection += EmptyLine
$newSection += MixedPara(@(
    @{text="Caution: "; bold=$true; code=$false},
    @{text="Cannot combine JOIN FETCH with pagination (LIMIT/OFFSET) — Hibernate loads ALL data in memory then paginates, emitting a warning (HHH90003004)."; bold=$false; code=$false}
))

# --- @EntityGraph ---
$newSection += EmptyLine
$newSection += H4("Solution 2: @EntityGraph (Spring Data JPA)")
$newSection += Para("Declaratively specifies which associations to eagerly load for a specific query — without changing the entity's default fetch type.")
$newSection += Code("// Repository")
$newSection += Code("@EntityGraph(attributePaths = {`"books`"})")
$newSection += Code("List<Author> findAll();")
$newSection += Code("")
$newSection += Code("// Named entity graph on entity")
$newSection += Code("@NamedEntityGraph(name = `"Author.books`",")
$newSection += Code("    attributeNodes = @NamedAttributeNode(`"books`"))")
$newSection += Code("@Entity public class Author { ... }")
$newSection += Code("")
$newSection += Code("@EntityGraph(`"Author.books`")")
$newSection += Code("List<Author> findByName(String name);")
$newSection += EmptyLine
$newSection += Para("Generates LEFT JOIN FETCH SQL — same as JOIN FETCH but more reusable.")

# --- @BatchSize ---
$newSection += EmptyLine
$newSection += H4("Solution 3: @BatchSize (Pagination-Safe)")
$newSection += Para("Instead of 1 query per collection, Hibernate loads multiple collections in a single IN-clause query. Reduces N queries to ceil(N / batchSize) queries.")
$newSection += Code("@Entity")
$newSection += Code("public class Author {")
$newSection += Code("    @OneToMany(mappedBy = `"author`")")
$newSection += Code("    @BatchSize(size = 25)")
$newSection += Code("    private List<Book> books;")
$newSection += Code("}")
$newSection += Code("")
$newSection += Code("// SQL: SELECT * FROM book WHERE author_id IN (1,2,3,...,25)")
$newSection += Code("// For 100 authors: 4 queries instead of 100")
$newSection += EmptyLine
$newSection += Para("Can also be set globally in persistence.xml / application.properties:")
$newSection += Code("spring.jpa.properties.hibernate.default_batch_fetch_size=25")
$newSection += EmptyLine
$newSection += MixedPara(@(
    @{text="Best for: "; bold=$true; code=$false},
    @{text="pagination scenarios — works correctly with LIMIT/OFFSET."; bold=$false; code=$false}
))

# --- @Fetch SUBSELECT ---
$newSection += EmptyLine
$newSection += H4("Solution 4: @Fetch(FetchMode.SUBSELECT)")
$newSection += Para("Loads ALL child collections with a single subselect query after the parent query — exactly 2 SQL queries total, regardless of N.")
$newSection += Code("@Entity")
$newSection += Code("public class Author {")
$newSection += Code("    @OneToMany(mappedBy = `"author`")")
$newSection += Code("    @Fetch(FetchMode.SUBSELECT)")
$newSection += Code("    private List<Book> books;")
$newSection += Code("}")
$newSection += Code("")
$newSection += Code("// Query 1: SELECT * FROM author")
$newSection += Code("// Query 2: SELECT * FROM book WHERE author_id IN")
$newSection += Code("//          (SELECT id FROM author)")
$newSection += EmptyLine
$newSection += MixedPara(@(
    @{text="vs @BatchSize: "; bold=$true; code=$false},
    @{text="SUBSELECT always fires query 2 even if you access no books; @BatchSize is on-demand."; bold=$false; code=$false}
))

# --- DTO Projection ---
$newSection += EmptyLine
$newSection += H4("Solution 5: DTO Projection (Best Read Performance)")
$newSection += Para("Skip entity loading entirely — project only the columns needed into a DTO. Zero collections, zero N+1 risk.")
$newSection += Code("public class AuthorBookDTO {")
$newSection += Code("    private Long authorId;")
$newSection += Code("    private String authorName;")
$newSection += Code("    private String bookTitle;")
$newSection += Code("    // constructor + getters")
$newSection += Code("}")
$newSection += Code("")
$newSection += Code("@Query(`"SELECT new com.example.AuthorBookDTO(a.id, a.name, b.title)`" +")
$newSection += Code("       `" FROM Author a JOIN a.books b`")")
$newSection += Code("List<AuthorBookDTO> findAllAuthorBooks();")
$newSection += Code("")
$newSection += Code("// Or use interface-based projection:")
$newSection += Code("public interface AuthorBookView {")
$newSection += Code("    String getAuthorName();")
$newSection += Code("    String getBookTitle();")
$newSection += Code("}")
$newSection += EmptyLine
$newSection += Para("Generates a single flat JOIN query. No entity overhead, no proxy initialization.")

# --- Criteria API ---
$newSection += EmptyLine
$newSection += H4("Solution 6: Criteria API with Fetch")
$newSection += Code("CriteriaBuilder cb = em.getCriteriaBuilder();")
$newSection += Code("CriteriaQuery<Author> cq = cb.createQuery(Author.class);")
$newSection += Code("Root<Author> root = cq.from(Author.class);")
$newSection += Code("root.fetch(`"books`", JoinType.LEFT);    // JOIN FETCH equivalent")
$newSection += Code("cq.select(root).distinct(true);")
$newSection += Code("List<Author> result = em.createQuery(cq).getResultList();")

# ===== DETECTING N+1 =====
$newSection += EmptyLine
$newSection += H2("4. How to Detect N+1 in Practice")

$newSection += H4("Enable SQL Logging")
$newSection += Code("# application.properties")
$newSection += Code("spring.jpa.show-sql=true")
$newSection += Code("spring.jpa.properties.hibernate.format_sql=true")
$newSection += Code("logging.level.org.hibernate.SQL=DEBUG")
$newSection += Code("logging.level.org.hibernate.type.descriptor.sql.BasicBinder=TRACE")

$newSection += EmptyLine
$newSection += H4("Hibernate Statistics")
$newSection += Code("spring.jpa.properties.hibernate.generate_statistics=true")
$newSection += Code("logging.level.org.hibernate.stat=DEBUG")
$newSection += Code("")
$newSection += Code("// In code:")
$newSection += Code("SessionFactory sf = em.getEntityManagerFactory().unwrap(SessionFactory.class);")
$newSection += Code("Statistics stats = sf.getStatistics();")
$newSection += Code("System.out.println(`"Queries: `" + stats.getQueryExecutionCount());")

$newSection += EmptyLine
$newSection += H4("datasource-proxy / p6spy (Production-safe)")
$newSection += Code("# pom.xml")
$newSection += Code("<dependency>")
$newSection += Code("    <groupId>com.github.gavlyukovskiy</groupId>")
$newSection += Code("    <artifactId>datasource-proxy-spring-boot-starter</artifactId>")
$newSection += Code("    <version>1.9.1</version>")
$newSection += Code("</dependency>")
$newSection += Code("")
$newSection += Code("# application.properties")
$newSection += Code("decorator.datasource.datasource-proxy.slow-query-threshold=50")

# ===== COMPARISON TABLE =====
$newSection += EmptyLine
$newSection += H2("5. Solution Comparison — Quick Reference")

$newSection += Para("When to use each solution:")
$newSection += EmptyLine

$newSection += MixedPara(@(@{text="JOIN FETCH"; bold=$true; code=$false}, @{text=" — Single query, no pagination. Best for: fetching all data at once."; bold=$false; code=$false}))
$newSection += MixedPara(@(@{text="@EntityGraph"; bold=$true; code=$false}, @{text=" — Same as JOIN FETCH but declarative, reusable across query methods."; bold=$false; code=$false}))
$newSection += MixedPara(@(@{text="@BatchSize"; bold=$true; code=$false}, @{text=" — Pagination-safe, on-demand loading in batches. Best for paginated lists."; bold=$false; code=$false}))
$newSection += MixedPara(@(@{text="SUBSELECT"; bold=$true; code=$false}, @{text=" — 2 total queries always. Best for: always-accessed large collections."; bold=$false; code=$false}))
$newSection += MixedPara(@(@{text="DTO Projection"; bold=$true; code=$false}, @{text=" — Fastest reads. Best for: read-only APIs, reporting, search results."; bold=$false; code=$false}))
$newSection += MixedPara(@(@{text="FetchType.EAGER"; bold=$true; code=$false}, @{text=" — Avoid globally. Only use for required associations that are always needed."; bold=$false; code=$false}))

# ===== INTERVIEW Q&A =====
$newSection += EmptyLine
$newSection += H2("6. Common Interview Questions and Answers")

$newSection += H4("Q1: What exactly is the N+1 problem in Hibernate?")
$newSection += Para("1 query fetches N parent entities, then Hibernate fires N additional queries (one per parent) to load their lazy associations. Result: N+1 database hits instead of 1.")

$newSection += EmptyLine
$newSection += H4("Q2: Why does LAZY loading cause N+1?")
$newSection += Para("LAZY associations are represented as uninitialized proxies. When you access the proxy (e.g., author.getBooks()), Hibernate fires a SELECT. Inside a for-loop over N parents, this creates N separate SELECTs.")

$newSection += EmptyLine
$newSection += H4("Q3: Does EAGER loading solve N+1?")
$newSection += Para("No — EAGER loading fires the extra queries immediately (at load time) rather than on access, but you still get N+1 queries unless a JOIN FETCH is specified. Making everything EAGER causes performance problems: it always loads associations even when you don't need them.")

$newSection += EmptyLine
$newSection += H4("Q4: JOIN FETCH vs @BatchSize — when to use each?")
$newSection += Bullet("JOIN FETCH: use when fetching a complete list without pagination. Produces 1 query but can't be combined with setFirstResult/setMaxResults on collections.")
$newSection += Bullet("@BatchSize: use when pagination is required or collections are large. Fires ceil(N/size) queries — far better than N, compatible with pagination.")

$newSection += EmptyLine
$newSection += H4("Q5: Can N+1 happen with @ManyToOne?")
$newSection += Para("Yes. Example: loading N Books with LAZY Author → N queries for Author. Same problem, fix with JOIN FETCH or @ManyToOne(fetch=EAGER) (safe here since it's a single object, not a collection).")
$newSection += Code("// Safe EAGER for @ManyToOne (no Cartesian product risk)")
$newSection += Code("@ManyToOne(fetch = FetchType.EAGER)")
$newSection += Code("private Author author;")

$newSection += EmptyLine
$newSection += H4("Q6: How do you fix N+1 in Spring Data JPA?")
$newSection += Bullet("Add @EntityGraph on the repository method")
$newSection += Bullet("Use @Query with JOIN FETCH")
$newSection += Bullet("Set @BatchSize on the entity collection")
$newSection += Bullet("Use a DTO projection @Query")

$newSection += EmptyLine
$newSection += H4("Q7: What is the HHH90003004 warning?")
$newSection += Para("Hibernate warning emitted when JOIN FETCH is used with pagination (setFirstResult/setMaxResults). Hibernate cannot apply LIMIT in SQL because JOIN FETCH inflates rows — it loads all data into memory and paginates there. Fix: use @BatchSize instead of JOIN FETCH when paginating.")

$newSection += EmptyLine
$newSection += H4("Q8: How would you prove N+1 is fixed?")
$newSection += Bullet("Enable show-sql and count the SELECT statements before and after fix")
$newSection += Bullet("Use Hibernate statistics (getQueryExecutionCount())")
$newSection += Bullet("Write an integration test asserting query count with datasource-proxy")
$newSection += Code("// Test with datasource-proxy asserting query count")
$newSection += Code("@Test void shouldLoadAuthorsInSingleQuery() {")
$newSection += Code("    QueryCountHolder.clear();")
$newSection += Code("    authorRepo.findAllWithBooks();")
$newSection += Code("    assertThat(QueryCountHolder.getGrandTotal().getSelect()).isEqualTo(1);")
$newSection += Code("}")

$newSection += EmptyLine
$newSection += H4("Q9: What is the Cartesian Product problem and how is it related?")
$newSection += Para("When fetching multiple collections via JOIN FETCH simultaneously (e.g., Author has Books AND Awards), SQL produces a Cartesian product: N * M rows. Hibernate de-duplicates in memory but performance suffers. Solution: use @BatchSize for one collection, JOIN FETCH for the other — or separate queries.")

$newSection += EmptyLine
$newSection += H4("Q10: Global default_batch_fetch_size — is it a silver bullet?")
$newSection += Para("Setting spring.jpa.properties.hibernate.default_batch_fetch_size=25 applies @BatchSize to all lazy associations automatically. It is a practical baseline that avoids N+1 for most use cases but still fires multiple queries. For critical read paths, explicit JOIN FETCH or DTO projections are preferred.")

# Final empty lines
$newSection += EmptyLine
$newSection += EmptyLine

# Join all paragraphs
$insertXml = $newSection -join ""

# Read document.xml
$docPath = "C:\workspace\preparation-files\hibernate_extracted\word\document.xml"
$content = [System.IO.File]::ReadAllText($docPath, [System.Text.Encoding]::UTF8)

# Insert before </w:body></w:document>
$marker = "</w:body></w:document>"
$newContent = $content.Replace($marker, "$insertXml$marker")

if ($newContent -eq $content) {
    Write-Error "Marker not found — document.xml not modified"
    exit 1
}

[System.IO.File]::WriteAllText($docPath, $newContent, [System.Text.Encoding]::UTF8)
Write-Host "document.xml updated successfully"

# Repack docx
$extractDir = "C:\workspace\preparation-files\hibernate_extracted"
$outputDocx = "C:\workspace\preparation-files\hibernate-interview-preparation.docx"
$tempZip = "C:\workspace\preparation-files\hibernate_temp.zip"

if (Test-Path $tempZip) { Remove-Item $tempZip -Force }

# Use .NET ZipFile to create the archive preserving correct structure
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($extractDir, $tempZip)

# Replace the original docx
Copy-Item $tempZip $outputDocx -Force
Remove-Item $tempZip -Force
Write-Host "DOCX repackaged: $outputDocx"

# Cleanup extracted dir
Remove-Item $extractDir -Recurse -Force
Write-Host "Done. Cleanup complete."
