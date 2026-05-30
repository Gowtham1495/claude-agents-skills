---
name: spring-boot
description: Spring Boot 3 + Java 21 coding patterns. Use when building or editing controllers, services, repositories, or entities. Covers the Controller-Service-Repository pattern, PATCH DTOs, RBAC, exception handling, and testing.
---

# Spring Boot 3 + Java 21 Patterns

Read `CLAUDE.md` in the project root for package names, RBAC roles, test profile, and exception handler conventions before writing code.

---

## Layered architecture

```
Controller  →  Service  →  Repository (JpaRepository)  →  Entity (@Entity)
```

- Controllers: routing, request/response mapping, `@PreAuthorize`
- Services: business logic, `@Transactional` on writes
- Repositories: data access only, named queries or `@Query`
- Never return JPA entities from controllers — always convert to a response DTO

## Response DTOs — use Java records

```java
public record PersonResponse(
        String id,
        String name,
        String email,
        AppRole appRole
) {}
```

## PATCH request DTOs — presence flags

To distinguish "field was sent as null" vs "field was not sent at all":

```java
public class PersonPatchRequest {
    private String name;

    @JsonProperty("oid")
    private String oid;
    private boolean oidPresent;

    @JsonSetter("oid")
    public void setOid(String oid) {
        this.oid = oid;
        this.oidPresent = true;
    }

    public boolean isOidPresent() { return oidPresent; }
    public String getOid() { return oid; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
}
```

In the service, check presence before updating:
```java
if (request.isOidPresent()) {
    // update oid, even if null (means clear it)
}
if (request.getName() != null) {
    // update name only if provided
}
```

## RBAC — @PreAuthorize

```java
@PreAuthorize("hasAnyRole('MANAGER', 'SENIOR_MANAGER', 'SYNERGHUB_ADMIN')")
public ResponseEntity<PersonResponse> create(...) { ... }

@PreAuthorize("hasRole('SYNERGHUB_ADMIN')")
public ResponseEntity<Void> delete(...) { ... }
```

Check CLAUDE.md for the full list of roles in this project.

## Exception handling

```java
// 404
throw new ResourceNotFoundException("Person not found: " + id);

// 400
throw new IllegalArgumentException("Name cannot be blank");

// 409
throw new ResponseStatusException(HttpStatus.CONFLICT, "OID already linked to another person.");

// 403
throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Your account is not linked to a person record.");
```

Check CLAUDE.md to see which exceptions the global `ApiExceptionHandler` already covers.

## Service — transactional write

```java
@Transactional
public PersonResponse patch(String id, PersonPatchRequest request) {
    Person person = peopleRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Person not found: " + id));
    // ... apply changes ...
    Person saved = peopleRepository.save(person);
    return toResponse(saved);
}
```

## Entity

```java
@Entity
@Table(name = "my_table")
public class MyEntity {
    @Id
    @Column(nullable = false, length = 36)
    private String id;

    @PrePersist
    protected void onCreate() {
        if (id == null) id = UUID.randomUUID().toString();
        createdAt = Instant.now();
        updatedAt = Instant.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = Instant.now();
    }
}
```

## Tests

```java
@SpringBootTest
@ActiveProfiles("unit-test")      // check CLAUDE.md for correct profile name
@AutoConfigureMockMvc
class MyFeatureIntegrationTests {

    @Autowired MockMvc mockMvc;

    @Test
    void shouldReturnList() throws Exception {
        mockMvc.perform(get("/api/my"))
               .andExpect(status().isOk())
               .andExpect(jsonPath("$", hasSize(greaterThanOrEqualTo(0))));
    }
}
```

## DB schema changes

Always apply the `liquibase` skill — **never alter schema without a migration**. Check CLAUDE.md for:
- Current latest migration version
- Author name convention
- Any project-specific gotchas
