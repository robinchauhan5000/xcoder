# Structured Streaming Implementation

## ✅ Architecture: Streaming API Call → Section Parser → Incremental Renderer

The streaming implementation now follows the proper architecture:

```
┌─────────────────────────────────────────────────────────────┐
│                    USER SENDS QUESTION                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              1. STREAMING API CALL                           │
│  OpenAI/Gemini streams JSON response token by token         │
│  {"title": "...", "sections": [{"type": "...", ...}]}       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              2. SECTION PARSER                               │
│  StreamingResponseParser incrementally parses JSON          │
│  - Accumulates tokens in buffer                             │
│  - Detects complete sections                                │
│  - Emits StreamingInterviewResponse updates                 │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              3. INCREMENTAL RENDERER                         │
│  StreamingAssistantMessage widget                           │
│  - Receives StreamingInterviewResponse updates              │
│  - Renders sections as they arrive                          │
│  - Shows title, short_answer, details, code incrementally   │
└─────────────────────────────────────────────────────────────┘
```

## Key Components

### 1. StreamingResponseParser (`lib/models/streaming_response.dart`)

**Purpose**: Incrementally parse JSON chunks into structured sections

**Features**:

- Accumulates text chunks in a buffer
- Detects complete JSON objects by counting braces
- Parses sections as they become complete
- Handles partial JSON gracefully
- Emits `StreamingInterviewResponse` updates

**Example**:

```dart
final parser = StreamingResponseParser();

// Add chunks as they arrive
parser.addChunk('{"title": "Binary Search",');
parser.addChunk(' "sections": [{"type": "short_answer",');
parser.addChunk(' "content": "Binary search is..."}]}');

// Complete parsing
parser.complete();

// Listen to parsed responses
parser.stream.listen((response) {
  print('Title: ${response.title}');
  print('Sections: ${response.sections.length}');
});
```

### 2. StreamingInterviewResponse Model

**Purpose**: Represents an interview response that builds incrementally

**Properties**:

- `title`: String - The response title
- `sections`: List<ResponseSection> - Parsed sections
- `isComplete`: bool - Whether streaming is finished

**Methods**:

- `copyWith()`: Create updated copy
- `toInterviewResponse()`: Convert to final response

### 3. Updated AI Services

Both OpenAI and Gemini services now:

1. Stream raw JSON tokens
2. Feed tokens to `StreamingResponseParser`
3. Return `Stream<StreamingInterviewResponse>`

**OpenAI**:

```dart
Future<Stream<StreamingInterviewResponse>> streamInterviewResponse(
  String prompt, {
  InterviewCategory category = InterviewCategory.normal,
}) async {
  // ... setup request with stream: true

  final parser = StreamingResponseParser();

  response.stream
    .transform(utf8.decoder)
    .transform(const LineSplitter())
    .where((line) => line.startsWith('data: '))
    .map((line) => extractContent(line))
    .listen(
      (chunk) => parser.addChunk(chunk),
      onDone: () => parser.complete(),
    );

  return parser.stream;
}
```

**Gemini**:

```dart
Future<Stream<StreamingInterviewResponse>> streamInterviewResponse(
  String prompt, {
  InterviewCategory category = InterviewCategory.normal,
}) async {
  // ... setup request with streamGenerateContent

  final parser = StreamingResponseParser();

  response.stream
    .transform(utf8.decoder)
    .transform(const LineSplitter())
    .map((line) => extractContent(line))
    .listen(
      (chunk) => parser.addChunk(chunk),
      onDone: () => parser.complete(),
    );

  return parser.stream;
}
```

### 4. StreamingAssistantMessage Widget

**Purpose**: Render streaming responses incrementally

**Features**:

- Uses `StreamBuilder` to listen to response updates
- Converts sections to markdown as they arrive
- Shows streaming indicator
- Calls `onComplete` when done

**Rendering Logic**:

````dart
String _buildMarkdownFromSections(StreamingInterviewResponse? response) {
  if (response == null) return '';

  final buffer = StringBuffer();

  // Add title
  if (response.title.isNotEmpty) {
    buffer.writeln('# ${response.title}\n');
  }

  // Add sections incrementally
  for (final section in response.sections) {
    switch (section.type) {
      case SectionType.shortAnswer:
        buffer.writeln(section.content);
        break;
      case SectionType.details:
        for (final detail in section.content) {
          buffer.writeln('- $detail');
        }
        break;
      case SectionType.code:
        buffer.writeln('```${section.language}');
        buffer.writeln(section.content);
        buffer.writeln('```');
        break;
    }
  }

  return buffer.toString();
}
````

## Flow Example

### User asks: "Explain binary search"

**Step 1: API Streams JSON**

```
Chunk 1: {"title": "Binary Search",
Chunk 2:  "sections": [
Chunk 3:    {"type": "short_answer",
Chunk 4:     "content": "Binary search is an efficient..."},
Chunk 5:    {"type": "code",
Chunk 6:     "language": "python",
Chunk 7:     "content": "def binary_search(arr, target):..."}
Chunk 8:  ]}
```

**Step 2: Parser Processes**

```
After Chunk 1: title = "Binary Search", sections = []
After Chunk 4: title = "Binary Search", sections = [short_answer]
After Chunk 7: title = "Binary Search", sections = [short_answer, code]
After Chunk 8: isComplete = true
```

**Step 3: UI Renders Incrementally**

```
Update 1: Shows title "Binary Search"
Update 2: Shows title + short answer paragraph
Update 3: Shows title + short answer + code block
Update 4: Streaming indicator disappears
```

## Benefits

### ✅ Structured Data

- Not just raw text streaming
- Proper sections (short_answer, details, code)
- Maintains response structure

### ✅ Incremental Rendering

- Title appears first
- Sections render as they're parsed
- No waiting for complete response

### ✅ Better UX

- Users see structured content immediately
- Code blocks render properly
- Lists format correctly

### ✅ Category Aware

- Works with all interview categories
- System design shows architecture sections
- Coding round shows code sections
- Short answers show brief responses

## Usage

### Basic Streaming

```dart
final service = InterviewService();

// Stream structured response
final stream = await service.askQuestionStream(
  'Explain quicksort',
  category: InterviewCategory.codingRound,
);

// Listen to updates
stream.listen((response) {
  print('Title: ${response.title}');
  print('Sections so far: ${response.sections.length}');

  for (final section in response.sections) {
    print('  - ${section.type}: ${section.content}');
  }

  if (response.isComplete) {
    print('Streaming complete!');
  }
});
```

### In UI

```dart
StreamingAssistantMessage(
  responseStream: stream,
  onComplete: (finalResponse) {
    // Replace with final message
    setState(() {
      messages[index] = AssistantChatMessage(
        text: formatResponse(finalResponse),
      );
    });
  },
)
```

## Files Modified

### New Files

1. `lib/models/streaming_response.dart` - Parser and model

### Modified Files

2. `lib/services/ai_model.dart` - Updated interface
3. `lib/services/openai_service.dart` - Structured streaming
4. `lib/services/gemini_service.dart` - Structured streaming
5. `lib/services/interview_service.dart` - Added streaming method
6. `lib/widgets/interview_copilot_chat_area.dart` - Updated widget
7. `lib/views/interview_copilot_view.dart` - Integrated streaming
8. `lib/models/models.dart` - Export new model

## Testing

### Test Scenarios

1. **Short Answer Category**
   - Should stream brief response
   - Single short_answer section
   - Quick completion

2. **Normal Category**
   - Should stream comprehensive answer
   - Multiple sections (short_answer + details)
   - Moderate length

3. **System Design Category**
   - Should stream architecture details
   - Many detail sections
   - Code sections for APIs/schemas
   - Longer streaming time

4. **Coding Round Category**
   - Should stream code implementation
   - Short_answer for approach
   - Code section with implementation
   - Details for complexity

### Manual Testing

```bash
# Run the app
flutter run -d macos

# Test each category:
1. Select "Short Answers" → Ask "What is REST?"
2. Select "Normal" → Ask "Explain HTTP caching"
3. Select "System Design" → Ask "Design Twitter"
4. Select "Coding Round" → Ask "Implement merge sort"

# Verify:
- Sections appear incrementally
- Structure is maintained
- Streaming indicator shows
- Final message is properly formatted
```

## Performance

### Parsing Overhead

- Minimal: O(n) where n = response length
- Brace counting is fast
- JSON parsing only on complete objects

### Memory Usage

- Buffer accumulates tokens (small)
- Sections stored as parsed (efficient)
- No memory leaks

### UI Updates

- Only when new sections complete
- Not on every token (efficient)
- Smooth rendering

## Troubleshooting

### Sections Not Appearing

**Problem**: Only seeing "..." or empty response

**Solution**:

- Check JSON format from AI
- Verify parser is receiving chunks
- Check for JSON parsing errors

### Choppy Rendering

**Problem**: UI updates too frequently

**Solution**:

- Parser only emits on complete sections
- Should be smooth by design
- Check network latency

### Incomplete Response

**Problem**: Streaming stops early

**Solution**:

- Check `parser.complete()` is called
- Verify HTTP stream completes
- Check for exceptions in logs

## Summary

The streaming implementation now properly follows:

**Streaming API Call** → **Section Parser** → **Incremental Renderer**

This provides:

- ✅ Structured data streaming (not just text)
- ✅ Incremental section rendering
- ✅ Proper formatting (markdown, code blocks)
- ✅ Category-aware responses
- ✅ Efficient parsing and rendering
- ✅ Great user experience

The architecture is clean, maintainable, and performant!
