// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String tabLabel(String tab) {
    String _temp0 = intl.Intl.selectLogic(tab, {
      'inicio': 'Heute',
      'comidas': 'Essen',
      'compra': 'Einkauf',
      'despensa': 'Vorrat',
      'tareas': 'Aufgaben',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get country => 'Land';

  @override
  String get countryHint => 'Währung, Supermärkte und Richtpreise';

  @override
  String get continueLabel => 'Weiter';

  @override
  String get back => 'Zurück';

  @override
  String get oneMoment => 'Einen Moment…';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get loginAccountCreated => 'Konto erstellt. Willkommen bei PrezHome';

  @override
  String get loginAuthError => 'Anmeldefehler';

  @override
  String loginProviderError(String provider) {
    return 'Anmeldung mit $provider fehlgeschlagen';
  }

  @override
  String get loginResetNeedsEmail =>
      'Gib zuerst deine E-Mail ein, dann schicke ich dir einen Link zum Zurücksetzen des Passworts.';

  @override
  String get loginResetSent =>
      'Ich habe dir eine E-Mail zum Zurücksetzen des Passworts geschickt.';

  @override
  String get loginResetError => 'E-Mail konnte nicht gesendet werden';

  @override
  String get loginWelcomeBack => 'Willkommen zurück';

  @override
  String get loginCreateAccount => 'Erstelle dein Konto';

  @override
  String get loginTagline => 'PrezHome, dein Zuhause organisiert';

  @override
  String loginContinueWith(String provider) {
    return 'Weiter mit $provider';
  }

  @override
  String get loginOrEmail => 'oder mit deiner E-Mail';

  @override
  String get loginEmail => 'E-Mail';

  @override
  String get loginEmailInvalid => 'Gib eine gültige E-Mail ein';

  @override
  String get loginPassword => 'Passwort';

  @override
  String get loginShowPassword => 'Passwort anzeigen';

  @override
  String get loginHidePassword => 'Passwort verbergen';

  @override
  String get loginPasswordShort => 'Mindestens 6 Zeichen';

  @override
  String get loginForgot => 'Passwort vergessen?';

  @override
  String get loginSignIn => 'Anmelden';

  @override
  String get loginSignUp => 'Registrieren';

  @override
  String get loginNoAccount => 'Kein Konto? Registrieren';

  @override
  String get loginHaveAccount => 'Schon ein Konto? Anmelden';

  @override
  String get homeCodeFormat =>
      'Der Code hat 8 Buchstaben und Ziffern (zum Beispiel ABCD-EFGH).';

  @override
  String get homeSetupError => 'Zuhause konnte nicht eingerichtet werden';

  @override
  String get homeLastStep => 'Letzter Schritt: dein Zuhause';

  @override
  String get homeCreateHint =>
      'Erstelle es jetzt und lade später unter Heute ein, wer mit dir wohnt.';

  @override
  String get homeCreate => 'Mein Zuhause erstellen';

  @override
  String get homeInvited => 'Ich wurde in ein Zuhause eingeladen';

  @override
  String get homeInviteCode => 'Einladungscode';

  @override
  String get homeJoin => 'Einem Zuhause beitreten';

  @override
  String get sessionLoadError => 'Dein Profil konnte nicht geladen werden.';

  @override
  String get onbSectionHome => 'Dein Zuhause';

  @override
  String get onbPeopleTitle => 'Wie viele Personen wohnen bei euch?';

  @override
  String get onbPeopleHint =>
      'Für Portionen, Einkauf und die Aufteilung der Aufgaben.';

  @override
  String get onbSectionGoals => 'Was dich beschäftigt';

  @override
  String get onbGoalsTitle => 'Was möchtest du aus dem Kopf haben?';

  @override
  String get onbGoalsHint =>
      'Wähle so viel du willst. Der Rest bleibt verborgen.';

  @override
  String get onbPickOne => 'Wähle mindestens eins';

  @override
  String onbContinueCount(int count) {
    return 'Weiter ($count)';
  }

  @override
  String get onbSectionKitchen => 'In der Küche';

  @override
  String get onbCookingTitle => 'Wie kocht ihr?';

  @override
  String get onbCookingHint =>
      'So wissen wir, ob wir Vorkochen und Gefrierfach planen.';

  @override
  String get onbSectionShopping => 'Einkauf';

  @override
  String get onbShopTitle => 'Wo kaufst du ein?';

  @override
  String get onbShopHint =>
      'Der erste wird dein Hauptsupermarkt: Rezepte nutzen Produkte, die es dort leicht gibt.';

  @override
  String get onbSkipSeeHome => 'Überspringen und mein Zuhause ansehen';

  @override
  String get onbSeeHome => 'Mein Zuhause ansehen';

  @override
  String get onbSlogan => 'Ein Zuhause in Ordnung, ein ruhiger Kopf.';

  @override
  String get onbStart => 'Los geht\'s';

  @override
  String get onbHaveAccount => 'Ich habe schon ein Konto';

  @override
  String get onbOneLess => 'Eine weniger';

  @override
  String get onbOneMore => 'Eine mehr';

  @override
  String onbPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Personen',
      one: 'Nur ich',
    );
    return '$_temp0';
  }

  @override
  String get onbProfileBadge => 'Dein Haushaltsprofil';

  @override
  String onbProfileName(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'solo': 'Solo',
      'duo': 'Das Duo',
      'tribu': 'Der Clan',
      'other': 'Die Familie',
    });
    return '$_temp0';
  }

  @override
  String onbProfileDescription(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'solo':
          'Das ganze Zuhause hängt an dir. PrezHome merkt sich, was da ist, was abläuft und was ansteht, damit du es nicht musst.',
      'duo':
          'Zwei Personen, ein Zuhause. PrezHome verteilt die Last sichtbar, damit niemand alles im Kopf behalten muss.',
      'other':
          'Viele Münder und vieles gleichzeitig. PrezHome plant Essen, Einkauf und Aufgaben für alle und erinnert jeden an seinen Teil.',
    });
    return '$_temp0';
  }

  @override
  String get onbLoadToday => 'Mentale Last heute';

  @override
  String get onbLoadWithApp => 'Mit PrezHome';

  @override
  String onbLoad(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'high': 'hoch',
      'medium': 'mittel',
      'other': 'gering',
    });
    return '$_temp0';
  }

  @override
  String get onbCreateAccount => 'Mein Konto erstellen';

  @override
  String onbFeature(String f) {
    String _temp0 = intl.Intl.selectLogic(f, {
      'compra': 'Einkaufsliste',
      'comidas': 'Was wir essen',
      'despensa': 'Vorrat und Ablaufdaten',
      'tareas': 'Hausarbeit',
      'other': 'Haushaltsausgaben',
    });
    return '$_temp0';
  }

  @override
  String goalLabel(String g) {
    String _temp0 = intl.Intl.selectLogic(g, {
      'comidas': 'Was wir essen',
      'compra': 'Einkauf',
      'despensa': 'Was zu Hause ist',
      'tareas': 'Hausarbeit',
      'lote': 'Vorkochen',
      'other': 'Haushaltsausgaben',
    });
    return '$_temp0';
  }

  @override
  String goalHint(String g) {
    String _temp0 = intl.Intl.selectLogic(g, {
      'comidas': 'Essensplan und Rezepte',
      'compra': 'Eine Liste, die sich selbst schreibt',
      'despensa': 'Vorrat, Kühlschrank und Ablaufdaten',
      'tareas': 'Faire Aufteilung und Erinnerungen',
      'lote': 'Dosen und Gefrierfach im Griff',
      'other': 'Budget und Kassenbons',
    });
    return '$_temp0';
  }

  @override
  String cookingLabel(String c) {
    String _temp0 = intl.Intl.selectLogic(c, {
      'diario': 'Jeden Tag',
      'lote': 'Vorkochen',
      'mixto': 'Ein bisschen von beidem',
      'other': 'Fast nie',
    });
    return '$_temp0';
  }

  @override
  String cookingHint(String c) {
    String _temp0 = intl.Intl.selectLogic(c, {
      'diario': 'Ich koche spontan',
      'lote': 'Ich koche für mehrere Tage vor',
      'mixto': 'An manchen Tagen vorgekocht',
      'other': 'Ich esse auswärts oder etwas Schnelles',
    });
    return '$_temp0';
  }
}
