// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String tabLabel(String tab) {
    String _temp0 = intl.Intl.selectLogic(tab, {
      'inicio': 'Today',
      'comidas': 'Meals',
      'compra': 'Shopping',
      'despensa': 'Pantry',
      'tareas': 'Chores',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get country => 'Country';

  @override
  String get countryHint => 'Currency, supermarkets and reference prices';

  @override
  String get continueLabel => 'Continue';

  @override
  String get back => 'Back';

  @override
  String get oneMoment => 'One moment…';

  @override
  String get retry => 'Try again';

  @override
  String get loginAccountCreated => 'Account created. Welcome to PrezHome';

  @override
  String get loginAuthError => 'Sign-in error';

  @override
  String loginProviderError(String provider) {
    return 'Couldn\'t sign in with $provider';
  }

  @override
  String get loginResetNeedsEmail =>
      'Enter your email first and I\'ll send you a link to reset your password.';

  @override
  String get loginResetSent =>
      'I\'ve sent you an email to reset your password.';

  @override
  String get loginResetError => 'Couldn\'t send the email';

  @override
  String get loginWelcomeBack => 'Welcome back';

  @override
  String get loginCreateAccount => 'Create your account';

  @override
  String get loginTagline => 'PrezHome, your home organised';

  @override
  String loginContinueWith(String provider) {
    return 'Continue with $provider';
  }

  @override
  String get loginOrEmail => 'or with your email';

  @override
  String get loginEmail => 'Email';

  @override
  String get loginEmailInvalid => 'Enter a valid email';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginShowPassword => 'Show password';

  @override
  String get loginHidePassword => 'Hide password';

  @override
  String get loginPasswordShort => 'At least 6 characters';

  @override
  String get loginForgot => 'Forgot your password?';

  @override
  String get loginSignIn => 'Sign in';

  @override
  String get loginSignUp => 'Sign up';

  @override
  String get loginNoAccount => 'No account? Sign up';

  @override
  String get loginHaveAccount => 'Already have an account? Sign in';

  @override
  String get homeCodeFormat =>
      'The code has 8 letters and numbers (for example ABCD-EFGH).';

  @override
  String get homeSetupError => 'Couldn\'t set up the home';

  @override
  String get homeLastStep => 'Last step: your home';

  @override
  String get homeCreateHint =>
      'Create it now and, whenever you like, invite the people you live with from Today.';

  @override
  String get homeCreate => 'Create my home';

  @override
  String get homeInvited => 'I\'ve been invited to a home';

  @override
  String get homeInviteCode => 'Invitation code';

  @override
  String get homeJoin => 'Join a home';

  @override
  String get sessionLoadError => 'Couldn\'t load your profile.';

  @override
  String get onbSectionHome => 'Your home';

  @override
  String get onbPeopleTitle => 'How many people live with you?';

  @override
  String get onbPeopleHint =>
      'To work out portions, shopping and how chores are shared.';

  @override
  String get onbSectionGoals => 'What keeps you busy';

  @override
  String get onbGoalsTitle => 'What would you like off your mind?';

  @override
  String get onbGoalsHint =>
      'Pick as many as you like. The rest will stay hidden.';

  @override
  String get onbPickOne => 'Pick at least one';

  @override
  String onbContinueCount(int count) {
    return 'Continue ($count)';
  }

  @override
  String get onbSectionKitchen => 'In the kitchen';

  @override
  String get onbCookingTitle => 'How do you cook?';

  @override
  String get onbCookingHint =>
      'So we know whether to plan batches and the freezer.';

  @override
  String get onbSectionShopping => 'Shopping';

  @override
  String get onbShopTitle => 'Where do you shop?';

  @override
  String get onbShopHint =>
      'The first one will be your main supermarket: recipes will use products that are easy to find there.';

  @override
  String get onbSkipSeeHome => 'Skip and see my home';

  @override
  String get onbSeeHome => 'See my home';

  @override
  String get onbSlogan => 'A tidy home, a calm mind.';

  @override
  String get onbStart => 'Get started';

  @override
  String get onbHaveAccount => 'I already have an account';

  @override
  String get onbOneLess => 'One fewer';

  @override
  String get onbOneMore => 'One more';

  @override
  String onbPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: 'Just me',
    );
    return '$_temp0';
  }

  @override
  String get onbProfileBadge => 'Your home profile';

  @override
  String onbProfileName(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'solo': 'Solo',
      'duo': 'The Duo',
      'tribu': 'The Tribe',
      'other': 'The Family',
    });
    return '$_temp0';
  }

  @override
  String onbProfileDescription(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'solo':
          'The whole home depends on you. PrezHome remembers what you have, what\'s about to expire and what\'s due, so you don\'t have to.',
      'duo':
          'Two people, one home. PrezHome shares the load where you can both see it, so nobody keeps track of everything in their head.',
      'other':
          'Lots of mouths and lots going on. PrezHome plans meals, shopping and chores for everyone, and reminds each person of their part.',
    });
    return '$_temp0';
  }

  @override
  String get onbLoadToday => 'Mental load today';

  @override
  String get onbLoadWithApp => 'With PrezHome';

  @override
  String onbLoad(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'high': 'heavy',
      'medium': 'medium',
      'other': 'light',
    });
    return '$_temp0';
  }

  @override
  String get onbCreateAccount => 'Create my account';

  @override
  String onbFeature(String f) {
    String _temp0 = intl.Intl.selectLogic(f, {
      'compra': 'Shopping list',
      'comidas': 'What we eat',
      'despensa': 'Pantry and expiry dates',
      'tareas': 'Household chores',
      'other': 'Home spending',
    });
    return '$_temp0';
  }

  @override
  String goalLabel(String g) {
    String _temp0 = intl.Intl.selectLogic(g, {
      'comidas': 'What we eat',
      'compra': 'Shopping',
      'despensa': 'What\'s at home',
      'tareas': 'Household chores',
      'lote': 'Batch cooking',
      'other': 'Home spending',
    });
    return '$_temp0';
  }

  @override
  String goalHint(String g) {
    String _temp0 = intl.Intl.selectLogic(g, {
      'comidas': 'Meal plan and recipes',
      'compra': 'A list that writes itself',
      'despensa': 'Pantry, fridge and expiry dates',
      'tareas': 'Fair sharing and reminders',
      'lote': 'Containers and freezer organised',
      'other': 'Budget and receipts',
    });
    return '$_temp0';
  }

  @override
  String cookingLabel(String c) {
    String _temp0 = intl.Intl.selectLogic(c, {
      'diario': 'Every day',
      'lote': 'In batches',
      'mixto': 'A bit of both',
      'other': 'Hardly ever',
    });
    return '$_temp0';
  }

  @override
  String cookingHint(String c) {
    String _temp0 = intl.Intl.selectLogic(c, {
      'diario': 'I cook as I go',
      'lote': 'I prep several days at once',
      'mixto': 'Some days in batches',
      'other': 'I eat out or grab something quick',
    });
    return '$_temp0';
  }
}
