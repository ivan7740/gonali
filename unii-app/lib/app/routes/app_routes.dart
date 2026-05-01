abstract class Routes {
  Routes._();

  static const String login = '/login';
  static const String home = '/home';
  static const String mapPicker = '/onboarding/map';

  // Profile (W2)
  static const String profileEdit = '/profile/edit';
  static const String passwordChange = '/profile/security/password';
  static const String accountSecurity = '/profile/security';
  static const String privacy = '/profile/privacy';
  static const String about = '/profile/about';
  static const String mapSettings = '/profile/map';

  // Discover (W5)
  static const String postCreate = '/post/create';
  static const String postDetail = '/post/detail';

  // Chat & moments (W6)
  static const String chatPicker = '/chat/picker';
  static const String conversation = '/chat/conversation';
  static const String teamMoments = '/team/moments';

  // Team & activity (W3)
  static const String teamCreate = '/team/create';
  static const String teamJoin = '/team/join';
  static const String teamDetail = '/team/detail';
  static const String teamMembers = '/team/members';
  static const String activityForm = '/activity/form';
  static const String activityDetail = '/activity/detail';
}
