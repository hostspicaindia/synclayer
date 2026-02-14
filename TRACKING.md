# SyncLayer Usage Tracking

## How We Track Usage

SyncLayer collects **anonymous** usage data to help us improve the SDK.

### What We Collect

- SDK version
- Platform (Android, iOS, Web, etc.)
- Init count (how many times SDK is initialized)
- Feature usage (which APIs are called)

### What We DON'T Collect

❌ User data  
❌ App data  
❌ Device identifiers  
❌ Personal information  
❌ Location data  

### How to Disable

```dart
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    enableTelemetry: false, // Disable tracking
  ),
);
```

### Why We Track

- Understand which features are used
- Prioritize bug fixes and improvements
- Know which platforms need more support
- Measure adoption and growth

### Privacy Policy

We respect your privacy. All data is:
- Anonymous
- Aggregated
- Never sold
- Never shared with third parties

For questions: privacy@hostspica.com
