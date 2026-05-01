import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:mocktail/mocktail.dart';

import 'package:unii_app/data/models/auth.dart';
import 'package:unii_app/data/repositories/auth_repo.dart';
import 'package:unii_app/modules/auth/auth_controller.dart';

class _MockAuthRepo extends Mock implements AuthRepo {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockAuthRepo repo;
  late AuthController controller;

  TokensDto sampleTokens() => const TokensDto(
    accessToken: 'a.b.c',
    refreshToken: 'r.r.r',
    expiresIn: 3600,
    user: UserDto(
      id: 1,
      phone: '13800001111',
      username: 'alice',
      needsMapSetup: true,
    ),
  );

  setUp(() {
    Get.reset();
    Get.testMode = true;
    repo = _MockAuthRepo();
    controller = AuthController(repo: repo, notify: (_, __) {});
  });

  test('rejects invalid phone before calling repo', () async {
    controller.phone.value = 'not-a-phone';
    controller.password.value = r'Pa$$w0rd';
    await controller.submit();

    verifyNever(
      () => repo.login(
        phone: any(named: 'phone'),
        password: any(named: 'password'),
      ),
    );
    expect(controller.isLoading.value, false);
  });

  test('rejects weak password before calling repo', () async {
    controller.phone.value = '13800001111';
    controller.password.value = 'short';
    await controller.submit();

    verifyNever(
      () => repo.login(
        phone: any(named: 'phone'),
        password: any(named: 'password'),
      ),
    );
  });

  test('login flips loading and calls repo on valid input', () async {
    when(
      () => repo.login(
        phone: any(named: 'phone'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => sampleTokens());

    controller.phone.value = '13800001111';
    controller.password.value = r'Pa$$w0rd';

    await controller.submit();

    expect(controller.isLoading.value, false);
    verify(
      () => repo.login(phone: '13800001111', password: r'Pa$$w0rd'),
    ).called(1);
  });

  test('shows snackbar when login throws DioException 401', () async {
    when(
      () => repo.login(
        phone: any(named: 'phone'),
        password: any(named: 'password'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/api/v1/auth/login'),
        response: Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/api/v1/auth/login'),
          statusCode: 401,
          data: const {
            'code': 1001,
            'msg': 'invalid credentials',
            'data': null,
          },
        ),
      ),
    );

    controller.phone.value = '13800001111';
    controller.password.value = r'Pa$$w0rd';

    await controller.submit();

    expect(controller.isLoading.value, false);
  });
}
