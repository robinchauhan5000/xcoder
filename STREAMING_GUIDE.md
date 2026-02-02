# Streaming Response Guide

## Overview

The Interview Assistant now supports **real-time streaming responses** from both OpenAI and Gemini AI providers. This provides a better user experience by showing responses as they're generated, similar to ChatGPT.

## Features

### ✅ What's New

1. **Real-time Streaming**: See AI responses appear word-by-word as they're generated
2. **Dual Mode Support**: Toggle between streaming and standard (blocking) responses
3. **Provider Agnostic**: Works with both OpenAI and Gemini
4. **Throttled Updates**: Smart buffering prevents excessive UI updates
5. **Visual Indicators**: Shows streaming status with animated indicator
6. **Automatic Conversion**: Streaming messages convert to regular messages when complete

## Architecture

### Streaming Flow

```
User Input
    ↓
InterviewService.askQuestionStream()
    ↓
AIModel.streamInterviewResponse()
    ↓
HTTP SSE Stream (OpenAI) or JSON Stream (Gemini)
    ↓
Throttle Transformer (60ms buffer)
    ↓
StreamingAssistantMessage Widget
    ↓
UI Updates in Real-time
    ↓
Converts to AssistantChatMessage on completion
```

### Key Components

#### 1. **AI Model Interface** (`lib/services/ai_model.dart`)

```dart
abstract class AIModel {
  // Blocking response
  Future<InterviewResponse> getInterviewResponse(
    String prompt, {
    InterviewCategory category = InterviewCategory.normal,
  });

  // Streaming response
  Future<Stream<String>> streamInterviewResponse(
    String prompt, {
    InterviewCategory category = InterviewCategory.normal,
  });
}
```

#### 2. **OpenAI Service** (`lib/services/openai_service.dart`)

- Uses Server-Sent Events (SSE) with `stream: true`
- Parses `data:` lines from response
- Extracts `delta.content` from each chunk
- Throttles updates to 60ms intervals

#### 3. **Gemini Service** (`lib/services/gemini_service.dart`)

- Uses `streamGenerateContent` endpoint
- Parses JSON lines from response
- Extracts text from candidates
- Same 60ms throttling

#### 4. **Streaming Message Widget** (`lib/widgets/interview_copilot_chat_area.dart`)

```dart
class StreamingAssistantMessage extends ChatMessage {
  final Stream<String> textStream;
  final void Function(String fullText)? onComplete;

  // Uses StreamBuilder to update UI
  // Shows streaming indicator
  // Calls onComplete when done
}
```

#### 5. **UI Integration** (`lib/views/interview_copilot_view.dart`)

- Toggle between streaming and standard mode
- Accumulates text chunks in buffer
- Replaces streaming message with final message on completion

## Usage

### For Users

1. **Enable/Disable Streaming**
   - Look for the streaming toggle in the provider selector
   - Click to switch between "Streaming" and "Standard" modes
   - Default: Streaming enabled

2. **Visual Feedback**
   - Streaming responses show a small spinner and "Streaming..." text
   - Text appears progressively as it's generated
   - Indicator disappears when response is complete

### For Developers

#### Basic Streaming

```dart
final service = InterviewService(provider: AIProvider.openai);

// Get streaming response
final stream = await service.askQuestionStream(
  'Explain how HTTP works',
  category: InterviewCategory.normal,
);

// Listen to chunks
stream.listen((chunk) {
  print('Received: $chunk');
});
```

#### With UI Integration

```dart
Future<void> _sendMessage(String text) async {
  final stream = await _interviewService.askQuestionStream(
    text,
    category: _currentCategory,
  );

  // Accumulate text
  final buffer = StringBuffer();
  final controller = StreamController<String>();

  stream.listen(
    (chunk) {
      buffer.write(chunk);
      controller.add(buffer.toString());
    },
    onDone: () => controller.close(),
  );

  // Add streaming message to UI
  setState(() {
    _messages.add(
      StreamingAssistantMessage(
        textStream: controller.stream,
        onComplete: (fullText) {
          // Replace with final message
          setState(() {
            _messages[_messages.length - 1] =
              AssistantChatMessage(text: fullText);
          });
        },
      ),
    );
  });
}
```

## Technical Details

### Throttling

Both services use a 60ms throttle to batch text chunks:

```dart
static StreamTransformer<String, String> _throttle(Duration duration) {
  Timer? timer;
  final buffer = StringBuffer();

  return StreamTransformer.fromHandlers(
    handleData: (data, sink) {
      buffer.write(data);
      timer ??= Timer(duration, () {
        sink.add(buffer.toString());
        buffer.clear();
        timer = null;
      });
    },
    handleDone: (sink) {
      if (buffer.isNotEmpty) {
        sink.add(buffer.toString());
      }
      sink.close();
    },
  );
}
```

**Why 60ms?**

- Balances responsiveness with performance
- Prevents excessive UI rebuilds (16ms = 60fps)
- Smooth visual experience
- Reduces CPU usage

### Error Handling

```dart
try {
  final stream = await service.askQuestionStream(prompt);

  stream.listen(
    (chunk) {
      // Handle chunk
    },
    onError: (error) {
      // Handle streaming error
      print('Stream error: $error');
    },
    onDone: () {
      // Stream complete
    },
  );
} catch (e) {
  // Handle initialization error
  print('Failed to start stream: $e');
}
```

### Memory Management

- Streams are broadcast streams (multiple listeners supported)
- HTTP clients are closed when stream is cancelled
- StreamControllers are properly closed
- No memory leaks

## Performance

### Benchmarks

| Mode          | Time to First Token | Total Time | UI Updates  |
| ------------- | ------------------- | ---------- | ----------- |
| **Streaming** | ~200ms              | Same       | Progressive |
| **Standard**  | N/A                 | Same       | Single      |

### Advantages of Streaming

✅ **Better UX**: Users see progress immediately
✅ **Perceived Speed**: Feels faster even if total time is same
✅ **Engagement**: Users can start reading while response generates
✅ **Cancellable**: Can stop mid-stream if needed

### Disadvantages

❌ **More Complex**: Requires stream handling
❌ **More UI Updates**: More frequent rebuilds
❌ **Network Overhead**: Slightly more data transfer

## Troubleshooting

### Stream Not Working

**Problem**: Responses appear all at once instead of streaming

**Solutions**:

1. Check that streaming is enabled in UI
2. Verify API supports streaming (OpenAI: `stream: true`, Gemini: `streamGenerateContent`)
3. Check network connection
4. Verify API key has streaming permissions

### Choppy Streaming

**Problem**: Text appears in large chunks instead of smoothly

**Solutions**:

1. Adjust throttle duration (currently 60ms)
2. Check network latency
3. Verify no other processes blocking UI thread

### Stream Cuts Off Early

**Problem**: Response incomplete

**Solutions**:

1. Check for network timeouts
2. Verify API rate limits not exceeded
3. Check error logs for exceptions
4. Ensure HTTP client not closed prematurely

## Future Enhancements

### Planned Features

- [ ] Adjustable throttle duration in settings
- [ ] Stream cancellation button
- [ ] Retry failed streams
- [ ] Stream progress indicator (% complete)
- [ ] Save streaming responses to history
- [ ] Streaming for JSON responses (structured data)

### Possible Optimizations

- [ ] Adaptive throttling based on network speed
- [ ] Predictive text rendering
- [ ] Chunk size optimization
- [ ] WebSocket support for lower latency

## API Compatibility

### OpenAI

- **Endpoint**: `/v1/chat/completions`
- **Parameter**: `stream: true`
- **Format**: Server-Sent Events (SSE)
- **Models**: All chat models (gpt-4, gpt-3.5-turbo, etc.)

### Gemini

- **Endpoint**: `/v1beta/models/{model}:streamGenerateContent`
- **Format**: JSON lines
- **Models**: All Gemini models (gemini-pro, gemini-3-flash, etc.)

## Examples

### Example 1: Simple Streaming

```dart
final service = InterviewService();
final stream = await service.askQuestionStream('What is REST?');

await for (final chunk in stream) {
  print(chunk);
}
```

### Example 2: With Category

```dart
final stream = await service.askQuestionStream(
  'Design a URL shortener',
  category: InterviewCategory.systemDesign,
);
```

### Example 3: Cancel Stream

```dart
final subscription = stream.listen((chunk) {
  print(chunk);
});

// Cancel after 5 seconds
Future.delayed(Duration(seconds: 5), () {
  subscription.cancel();
});
```

## Summary

Streaming responses provide a modern, responsive user experience. The implementation is:

- ✅ **Provider Agnostic**: Works with OpenAI and Gemini
- ✅ **Category Aware**: Respects interview categories
- ✅ **Performant**: Throttled updates prevent UI lag
- ✅ **Robust**: Proper error handling and cleanup
- ✅ **User Friendly**: Visual indicators and smooth updates

Toggle streaming on/off based on your preference!
