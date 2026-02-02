# Interview Assistant Services

## Overview

This directory contains the AI services for the Interview Assistant application. Both OpenAI and Gemini services now use a **common prompt builder** to ensure consistent behavior across providers.

## Architecture

```
┌─────────────────────────────────────┐
│     InterviewService                │
│  (High-level API)                   │
└──────────────┬──────────────────────┘
               │
       ┌───────┴────────┐
       │                │
┌──────▼──────┐  ┌─────▼──────┐
│ OpenAI      │  │ Gemini     │
│ Service     │  │ Service    │
└──────┬──────┘  └─────┬──────┘
       │                │
       └───────┬────────┘
               │
        ┌──────▼──────┐
        │ PromptBuilder│
        │  (Common)    │
        └──────────────┘
```

## Interview Categories

### 1. **Short Answers** (`InterviewCategory.shortAnswers`)

**Use Case:** Quick, rapid-fire interview questions

**Behavior:**

- Provides **brief, concise answers** (1-3 sentences)
- Minimal use of details or code
- Gets straight to the point
- Perfect for screening rounds or quick Q&A

**Example:**

```dart
Question: "What is REST?"
Answer: "REST (Representational State Transfer) is an architectural style for
designing networked applications using stateless HTTP requests. It uses standard
HTTP methods (GET, POST, PUT, DELETE) to perform CRUD operations on resources."
```

---

### 2. **Normal** (`InterviewCategory.normal`)

**Use Case:** Standard technical interview questions

**Behavior:**

- Provides **comprehensive, well-structured answers**
- 2-4 paragraphs of explanation
- Includes examples and context
- Balances depth with clarity
- Similar to how ChatGPT would answer

**Example:**

```dart
Question: "Explain how HTTP caching works"
Answer: Detailed explanation with:
- How caching works
- Cache-Control headers
- ETag and Last-Modified
- Real-world examples
- Best practices
```

---

### 3. **System Design** (`InterviewCategory.systemDesign`)

**Use Case:** System design interview rounds

**Behavior:**

- Provides **senior-level, comprehensive system design**
- Extensive use of details for architecture
- Covers all aspects:
  - High-level architecture
  - Component breakdown
  - Data models and schemas
  - API contracts
  - Trade-offs and alternatives
  - Scalability considerations
  - Technology choices with justifications
- Includes code for APIs, schemas, and pseudocode

**Example:**

```dart
Question: "Design a URL shortener like bit.ly"
Answer: Complete system design with:
- Requirements and constraints
- High-level architecture diagram
- Database schema
- API endpoints
- Hashing algorithm
- Scalability strategy
- Trade-offs (hash collisions, storage, etc.)
- Monitoring and analytics
```

---

### 4. **Coding Round** (`InterviewCategory.codingRound`)

**Use Case:** Coding interview rounds (LeetCode-style)

**Behavior:**

- Focuses on **working, production-quality code**
- Includes:
  - Problem approach explanation
  - Complete implementation
  - Time and space complexity analysis
  - Edge cases handled
  - Code comments
- Minimal short answers, maximum code

**Example:**

```dart
Question: "Implement a LRU Cache"
Answer:
- Approach: HashMap + Doubly Linked List
- Full implementation with comments
- Time: O(1) for get/put
- Space: O(capacity)
- Edge cases: capacity 0, null keys, etc.
```

---

## Usage

### Basic Usage

```dart
import 'package:your_app/services/interview_service.dart';
import 'package:your_app/models/interview_category.dart';

// Create service (defaults to OpenAI)
final service = InterviewService();

// Ask a question with specific category
final response = await service.askQuestion(
  'What is a binary search tree?',
  category: InterviewCategory.shortAnswers,
);

// Format and display
print(service.formatResponse(response));
```

### Switching Providers

```dart
// Use Gemini instead
final geminiService = InterviewService(
  provider: AIProvider.gemini,
);

// Use custom API key
final customService = InterviewService(
  provider: AIProvider.openai,
  apiKey: 'your-api-key',
);
```

### Category Examples

```dart
// Short answer for quick questions
await service.askQuestion(
  'What is polymorphism?',
  category: InterviewCategory.shortAnswers,
);

// Normal answer for standard questions
await service.askQuestion(
  'Explain the difference between TCP and UDP',
  category: InterviewCategory.normal,
);

// System design for architecture questions
await service.askQuestion(
  'Design Instagram',
  category: InterviewCategory.systemDesign,
);

// Coding round for algorithm questions
await service.askQuestion(
  'Implement merge sort',
  category: InterviewCategory.codingRound,
);
```

## Prompt Builder

The `PromptBuilder` class is the heart of the system. It generates detailed, category-specific prompts that guide the AI to produce appropriate responses.

### Key Features

1. **Consistent JSON Schema**: All responses follow the same structure
2. **Category-Specific Instructions**: Each category has tailored prompts
3. **Quality Guidelines**: Ensures professional, interview-ready answers
4. **Shared Across Providers**: Both OpenAI and Gemini use the same prompts

### Customization

To modify prompts, edit `lib/services/prompt_builder.dart`:

```dart
static String _getSystemDesignPrompt() {
  return '''
CATEGORY: System Design Interview

INSTRUCTIONS:
- Your custom instructions here
...
''';
}
```

## Response Structure

All responses follow this JSON structure:

```json
{
  "title": "Question Title",
  "sections": [
    {
      "type": "short_answer",
      "content": "Brief explanation..."
    },
    {
      "type": "details",
      "content": ["Point 1", "Point 2", "Point 3"]
    },
    {
      "type": "code",
      "language": "python",
      "content": "def example():\n    pass"
    }
  ]
}
```

## Testing

Run the example to see how different categories work:

```bash
dart run lib/examples/prompt_examples.dart
```

## Best Practices

1. **Choose the right category** for your question type
2. **Short Answers**: Use for definitions, quick facts
3. **Normal**: Use for explanations, concepts, how-things-work
4. **System Design**: Use for architecture, scalability, design questions
5. **Coding Round**: Use for algorithms, data structures, implementations

## Troubleshooting

### Responses are too short

- Make sure you're not using `InterviewCategory.shortAnswers` for detailed questions
- Use `normal` or `systemDesign` for comprehensive answers

### Not getting code

- Use `InterviewCategory.codingRound` for coding questions
- Ensure your question asks for implementation

### System design lacks detail

- Verify you're using `InterviewCategory.systemDesign`
- Ask specific questions about architecture, scalability, trade-offs

## Contributing

When adding new features:

1. Update `PromptBuilder` if changing prompt logic
2. Keep both OpenAI and Gemini services in sync
3. Add examples to demonstrate new functionality
4. Update this README
