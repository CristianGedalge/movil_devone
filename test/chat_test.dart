import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movil_devone/models/chat_message_model.dart';
import 'package:movil_devone/services/chat_service.dart';
import 'package:movil_devone/services/onedev_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ChatMessage Model Tests', () {
    test('ChatMessage.user creates valid user message', () {
      final msg = ChatMessage.user('Hola SCMDev');
      expect(msg.text, 'Hola SCMDev');
      expect(msg.isUser, isTrue);
      expect(msg.isError, isFalse);
    });

    test('ChatMessage.assistant creates assistant message with suggestions', () {
      final msg = ChatMessage.assistant('Respuesta de prueba', suggestions: ['Opción 1', 'Opción 2']);
      expect(msg.text, 'Respuesta de prueba');
      expect(msg.isUser, isFalse);
      expect(msg.suggestedActions?.length, 2);
    });

    test('ChatMessage json serialization roundtrip', () {
      final original = ChatMessage.user('Mensaje test');
      final json = original.toJson();
      final restored = ChatMessage.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.text, original.text);
      expect(restored.isUser, original.isUser);
    });
  });

  group('ChatService Tests', () {
    test('Initializes with welcome message', () {
      final service = ChatService(OneDevService());
      expect(service.messages.isNotEmpty, isTrue);
      expect(service.messages.first.isUser, isFalse);
    });

    test('clearChat resets messages to welcome message', () {
      final service = ChatService(OneDevService());
      service.clearChat();
      expect(service.messages.length, 1);
      expect(service.messages.first.isUser, isFalse);
    });

    test('updateSettings updates provider and persists', () async {
      final service = ChatService(OneDevService());
      await service.updateSettings(
        providerType: AiProviderType.customLlm,
        llmBaseUrl: 'http://localhost:1234/v1',
        llmApiKey: 'test-key',
        llmModel: 'llama3',
      );

      expect(service.providerType, AiProviderType.customLlm);
      expect(service.llmBaseUrl, 'http://localhost:1234/v1');
      expect(service.llmApiKey, 'test-key');
      expect(service.llmModel, 'llama3');
    });
  });
}
