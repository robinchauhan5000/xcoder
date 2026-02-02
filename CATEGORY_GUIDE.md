# Interview Category Quick Guide

## 🎯 When to Use Each Category

### 📝 Short Answers

**Use when:** You need quick, concise definitions or facts
**Response:** 1-3 sentences, straight to the point
**Example Questions:**

- "What is REST?"
- "Define polymorphism"
- "What's the difference between TCP and UDP?"

**Sample Response:**

```
Q: What is REST?
A: REST (Representational State Transfer) is an architectural style
for designing networked applications using stateless HTTP requests.
It uses standard HTTP methods to perform CRUD operations on resources.
```

---

### 💬 Normal

**Use when:** You need comprehensive explanations
**Response:** 2-4 paragraphs with examples and context
**Example Questions:**

- "Explain how HTTP caching works"
- "What are the SOLID principles?"
- "How does garbage collection work in Java?"

**Sample Response:**

```
Q: Explain HTTP caching
A: [2-3 paragraphs explaining caching mechanisms]
   [Examples of Cache-Control headers]
   [Discussion of ETags and validation]
   [Best practices and common pitfalls]
```

---

### 🏗️ System Design

**Use when:** You need architecture and design discussions
**Response:** Complete system design with all details
**Example Questions:**

- "Design Twitter"
- "Design a URL shortener"
- "How would you build Netflix?"

**Sample Response:**

```
Q: Design a URL shortener
A:
1. Requirements & Constraints
   - 100M URLs per day
   - Read-heavy (100:1 read/write)
   - Low latency required

2. High-Level Architecture
   - Load Balancer
   - Application Servers
   - Cache Layer (Redis)
   - Database (Cassandra)
   - Analytics Service

3. Database Schema
   [Detailed schema with indexes]

4. API Design
   POST /shorten
   GET /{shortUrl}

5. URL Generation Algorithm
   [Base62 encoding explanation]
   [Hash collision handling]

6. Trade-offs
   - Base62 vs MD5 hash
   - SQL vs NoSQL
   - Caching strategy

7. Scalability
   - Horizontal scaling
   - Database sharding
   - CDN for static content

8. Monitoring & Analytics
   [Click tracking, metrics]
```

---

### 💻 Coding Round

**Use when:** You need algorithm implementations
**Response:** Working code with complexity analysis
**Example Questions:**

- "Implement a LRU Cache"
- "Find the longest palindromic substring"
- "Design a binary search tree"

**Sample Response:**

````
Q: Implement a LRU Cache

Approach:
We'll use a HashMap for O(1) lookups and a Doubly Linked List
to maintain access order. Most recently used items are at the head.

Implementation:
```python
class Node:
    def __init__(self, key, value):
        self.key = key
        self.value = value
        self.prev = None
        self.next = None

class LRUCache:
    def __init__(self, capacity: int):
        self.capacity = capacity
        self.cache = {}  # key -> Node
        self.head = Node(0, 0)  # dummy head
        self.tail = Node(0, 0)  # dummy tail
        self.head.next = self.tail
        self.tail.prev = self.head

    def get(self, key: int) -> int:
        if key not in self.cache:
            return -1
        node = self.cache[key]
        self._remove(node)
        self._add_to_head(node)
        return node.value

    def put(self, key: int, value: int) -> None:
        if key in self.cache:
            self._remove(self.cache[key])
        node = Node(key, value)
        self._add_to_head(node)
        self.cache[key] = node

        if len(self.cache) > self.capacity:
            lru = self.tail.prev
            self._remove(lru)
            del self.cache[lru.key]

    def _remove(self, node):
        node.prev.next = node.next
        node.next.prev = node.prev

    def _add_to_head(self, node):
        node.next = self.head.next
        node.prev = self.head
        self.head.next.prev = node
        self.head.next = node
````

Complexity Analysis:

- Time: O(1) for both get() and put()
- Space: O(capacity) for storing cache entries

Edge Cases Handled:

- Empty cache
- Single element
- Capacity of 0
- Updating existing keys

```

---

## 🔄 Comparison Table

| Category | Length | Code | Details | Best For |
|----------|--------|------|---------|----------|
| **Short Answers** | 1-3 sentences | Minimal | Minimal | Quick facts, definitions |
| **Normal** | 2-4 paragraphs | Some | Moderate | Explanations, concepts |
| **System Design** | Comprehensive | APIs/Schemas | Extensive | Architecture questions |
| **Coding Round** | Brief intro | Full implementation | Complexity | Algorithm problems |

---

## 💡 Pro Tips

### ✅ DO:
- Choose the category that matches your question type
- Use Short Answers for rapid-fire screening questions
- Use System Design for architecture discussions
- Use Coding Round for algorithm implementations
- Use Normal for everything else

### ❌ DON'T:
- Use Short Answers for complex topics
- Use Coding Round for conceptual questions
- Use Normal for algorithm implementations
- Mix categories - pick one that fits best

---

## 🧪 Testing Your Questions

Not sure which category to use? Ask yourself:

1. **Do I need just a definition?** → Short Answers
2. **Do I need an explanation?** → Normal
3. **Do I need to design a system?** → System Design
4. **Do I need code?** → Coding Round

---

## 📚 More Examples

### Short Answers Examples
- "What is a closure?"
- "Define Big O notation"
- "What's the CAP theorem?"

### Normal Examples
- "Explain how React hooks work"
- "What are the benefits of microservices?"
- "How does HTTPS encryption work?"

### System Design Examples
- "Design WhatsApp"
- "Design a rate limiter"
- "Design YouTube"

### Coding Round Examples
- "Reverse a linked list"
- "Find all anagrams in a string"
- "Implement a trie"

---

## 🎓 Remember

The AI will adapt its response based on the category you choose. Pick wisely!

- **Short** = Brief
- **Normal** = Comprehensive
- **System Design** = Architecture + Trade-offs
- **Coding** = Code + Analysis
```
