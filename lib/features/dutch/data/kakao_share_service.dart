import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';

abstract interface class KakaoShareService {
  Future<void> shareText(String message);
}

class KakaoSdkShareService implements KakaoShareService {
  const KakaoSdkShareService();

  static const int _textTemplateLimit = 200;

  @override
  Future<void> shareText(String message) async {
    final template = TextTemplate(
      text: _fitTextTemplate(message),
      link: Link(
        androidExecutionParams: const {'screen': 'dutch_request'},
        iosExecutionParams: const {'screen': 'dutch_request'},
      ),
      buttonTitle: '소비로그 열기',
    );

    if (await ShareClient.instance.isKakaoTalkSharingAvailable()) {
      await ShareClient.instance.shareDefault(template: template);
      return;
    }

    final webShareUrl = await WebSharerClient.instance.makeDefaultUrl(
      template: template,
    );
    await launchBrowser(webShareUrl);
  }

  String _fitTextTemplate(String message) {
    final characters = message.runes.toList(growable: false);
    if (characters.length <= _textTemplateLimit) return message;
    return '${String.fromCharCodes(characters.take(_textTemplateLimit - 1))}…';
  }
}
