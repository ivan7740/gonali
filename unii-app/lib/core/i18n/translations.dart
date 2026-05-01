import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en': {
      'login_title': 'Sign in',
      'register_title': 'Create account',
      'phone': 'Phone',
      'password': 'Password',
      'confirm_password': 'Confirm password',
      'username': 'Username',
      'submit': 'Submit',
      'switch_to_register': 'No account? Register',
      'switch_to_login': 'Have an account? Sign in',
      'tab_discover': 'Discover',
      'tab_team': 'Team',
      'tab_chat': 'Chat',
      'tab_profile': 'Profile',
      'coming_soon': 'Coming in W{wave}',
      'login_failed': 'Login failed',
      'network_error': 'Network error',
      'invalid_phone': 'Invalid phone number',
      'invalid_password':
          'Password must be 8-64 chars and contain a letter and a digit',
      'passwords_dont_match': 'Passwords do not match',
    },
    'zh': {
      'login_title': '登录',
      'register_title': '注册',
      'phone': '手机号',
      'password': '密码',
      'confirm_password': '确认密码',
      'username': '用户名',
      'submit': '提交',
      'switch_to_register': '还没账号？去注册',
      'switch_to_login': '已有账号？去登录',
      'tab_discover': '推荐',
      'tab_team': '团队',
      'tab_chat': '私聊',
      'tab_profile': '我的',
      'coming_soon': 'W{wave} 期发布',
      'login_failed': '登录失败',
      'network_error': '网络错误',
      'invalid_phone': '手机号格式不正确',
      'invalid_password': '密码 8-64 位且必须含字母和数字',
      'passwords_dont_match': '两次密码不一致',
    },
  };
}
