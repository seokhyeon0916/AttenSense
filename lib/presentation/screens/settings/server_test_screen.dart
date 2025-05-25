import 'package:flutter/material.dart';

class ServerTestScreen extends StatefulWidget {
  const ServerTestScreen({super.key});
  // ... (existing code)

  @override
  State<ServerTestScreen> createState() => _ServerTestScreenState();
}

class _ServerTestScreenState extends State<ServerTestScreen> {
  late TextEditingController _serverUrlController;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    // 기본 서버 URL 설정
    _serverUrlController = TextEditingController(
      text: 'http://192.168.1.4:3000',
    );
    _statusMessage = '서버 연결 상태를 확인하려면 "서버 상태 확인" 버튼을 누르세요.';
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }

  // 서버 상태 확인 함수
  Future<void> _checkServerStatus() async {
    setState(() {
      _statusMessage = '서버 연결 확인 중...';
    });

    try {
      // TODO: 실제 서버 연결 로직 구현
      // 예시로 2초 후 성공했다고 가정
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _statusMessage = '서버 연결 성공: ${_serverUrlController.text}';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '서버 연결 실패: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('서버 테스트')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _serverUrlController,
              decoration: const InputDecoration(
                labelText: '서버 URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _checkServerStatus,
              child: const Text('서버 상태 확인'),
            ),
            const SizedBox(height: 24.0),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                _statusMessage,
                style: const TextStyle(fontSize: 16.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
