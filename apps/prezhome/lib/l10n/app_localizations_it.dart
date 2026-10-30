// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String tabLabel(String tab) {
    String _temp0 = intl.Intl.selectLogic(tab, {
      'inicio': 'Oggi',
      'comidas': 'Pasti',
      'compra': 'Spesa',
      'despensa': 'Dispensa',
      'tareas': 'Faccende',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get country => 'Paese';

  @override
  String get countryHint => 'Valuta, supermercati e prezzi di riferimento';

  @override
  String get continueLabel => 'Continua';

  @override
  String get back => 'Indietro';

  @override
  String get oneMoment => 'Un momento…';

  @override
  String get retry => 'Riprova';

  @override
  String get loginAccountCreated => 'Account creato. Benvenuto su PrezHome';

  @override
  String get loginAuthError => 'Errore di accesso';

  @override
  String loginProviderError(String provider) {
    return 'Impossibile accedere con $provider';
  }

  @override
  String get loginResetNeedsEmail =>
      'Scrivi prima la tua email e ti invierò il link per reimpostare la password.';

  @override
  String get loginResetSent =>
      'Ti ho inviato un\'email per reimpostare la password.';

  @override
  String get loginResetError => 'Impossibile inviare l\'email';

  @override
  String get loginWelcomeBack => 'Bentornato';

  @override
  String get loginCreateAccount => 'Crea il tuo account';

  @override
  String get loginTagline => 'PrezHome, la tua casa organizzata';

  @override
  String loginContinueWith(String provider) {
    return 'Continua con $provider';
  }

  @override
  String get loginOrEmail => 'o con la tua email';

  @override
  String get loginEmail => 'Email';

  @override
  String get loginEmailInvalid => 'Inserisci un\'email valida';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginShowPassword => 'Mostra password';

  @override
  String get loginHidePassword => 'Nascondi password';

  @override
  String get loginPasswordShort => 'Almeno 6 caratteri';

  @override
  String get loginForgot => 'Hai dimenticato la password?';

  @override
  String get loginSignIn => 'Accedi';

  @override
  String get loginSignUp => 'Registrati';

  @override
  String get loginNoAccount => 'Non hai un account? Registrati';

  @override
  String get loginHaveAccount => 'Hai già un account? Accedi';

  @override
  String get homeCodeFormat =>
      'Il codice ha 8 lettere e numeri (ad esempio ABCD-EFGH).';

  @override
  String get homeSetupError => 'Impossibile configurare la casa';

  @override
  String get homeLastStep => 'Ultimo passo: la tua casa';

  @override
  String get homeCreateHint =>
      'Creala ora e, quando vuoi, invita chi vive con te da Oggi.';

  @override
  String get homeCreate => 'Crea la mia casa';

  @override
  String get homeInvited => 'Sono stato invitato in una casa';

  @override
  String get homeInviteCode => 'Codice di invito';

  @override
  String get homeJoin => 'Unisciti a una casa';

  @override
  String get sessionLoadError => 'Impossibile caricare il tuo profilo.';

  @override
  String get onbSectionHome => 'La tua casa';

  @override
  String get onbPeopleTitle => 'Quante persone vivete?';

  @override
  String get onbPeopleHint =>
      'Per calcolare porzioni, spesa e divisione delle faccende.';

  @override
  String get onbSectionGoals => 'Ciò che ti impegna';

  @override
  String get onbGoalsTitle => 'Cosa vuoi toglierti dalla testa?';

  @override
  String get onbGoalsHint =>
      'Scegli tutto ciò che vuoi. Il resto resterà nascosto.';

  @override
  String get onbPickOne => 'Scegline almeno una';

  @override
  String onbContinueCount(int count) {
    return 'Continua ($count)';
  }

  @override
  String get onbSectionKitchen => 'In cucina';

  @override
  String get onbCookingTitle => 'Come cucinate?';

  @override
  String get onbCookingHint =>
      'Così sappiamo se organizzare preparazioni e congelatore.';

  @override
  String get onbSectionShopping => 'La spesa';

  @override
  String get onbShopTitle => 'Dove fai la spesa?';

  @override
  String get onbShopHint =>
      'Il primo sarà il tuo supermercato principale: le ricette useranno prodotti facili da trovare lì.';

  @override
  String get onbSkipSeeHome => 'Salta e vedi la mia casa';

  @override
  String get onbSeeHome => 'Vedi la mia casa';

  @override
  String get onbSlogan => 'Casa in ordine, mente tranquilla.';

  @override
  String get onbStart => 'Inizia';

  @override
  String get onbHaveAccount => 'Ho già un account';

  @override
  String get onbOneLess => 'Una in meno';

  @override
  String get onbOneMore => 'Una in più';

  @override
  String onbPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persone',
      one: 'Solo io',
    );
    return '$_temp0';
  }

  @override
  String get onbProfileBadge => 'Il tuo profilo di casa';

  @override
  String onbProfileName(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'solo': 'In solitaria',
      'duo': 'Il Duo',
      'tribu': 'La Tribù',
      'other': 'La Famiglia',
    });
    return '$_temp0';
  }

  @override
  String onbProfileDescription(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'solo':
          'Tutta la casa dipende da te. PrezHome ricorda cosa c\'è, cosa scade e cosa tocca fare, così non devi farlo tu.',
      'duo':
          'Due persone, una casa. PrezHome divide il carico in modo visibile, così nessuno deve tenere tutto a mente.',
      'other':
          'Tante bocche e tante cose insieme. PrezHome pianifica pasti, spesa e faccende per tutti, e ricorda a ognuno la sua parte.',
    });
    return '$_temp0';
  }

  @override
  String get onbLoadToday => 'Carico mentale oggi';

  @override
  String get onbLoadWithApp => 'Con PrezHome';

  @override
  String onbLoad(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'high': 'pesante',
      'medium': 'media',
      'other': 'leggera',
    });
    return '$_temp0';
  }

  @override
  String get onbCreateAccount => 'Crea il mio account';

  @override
  String onbFeature(String f) {
    String _temp0 = intl.Intl.selectLogic(f, {
      'compra': 'Lista della spesa',
      'comidas': 'Cosa mangiamo',
      'despensa': 'Dispensa e scadenze',
      'tareas': 'Faccende di casa',
      'other': 'Spese di casa',
    });
    return '$_temp0';
  }

  @override
  String goalLabel(String g) {
    String _temp0 = intl.Intl.selectLogic(g, {
      'comidas': 'Cosa mangiamo',
      'compra': 'La spesa',
      'despensa': 'Cosa c\'è in casa',
      'tareas': 'Faccende di casa',
      'lote': 'Cucinare in anticipo',
      'other': 'Spese di casa',
    });
    return '$_temp0';
  }

  @override
  String goalHint(String g) {
    String _temp0 = intl.Intl.selectLogic(g, {
      'comidas': 'Piano pasti e ricette',
      'compra': 'Una lista che si scrive da sola',
      'despensa': 'Dispensa, frigo e scadenze',
      'tareas': 'Divisione giusta e promemoria',
      'lote': 'Contenitori e congelatore in ordine',
      'other': 'Budget e scontrini',
    });
    return '$_temp0';
  }

  @override
  String cookingLabel(String c) {
    String _temp0 = intl.Intl.selectLogic(c, {
      'diario': 'Ogni giorno',
      'lote': 'In anticipo',
      'mixto': 'Un po\' e un po\'',
      'other': 'Quasi mai',
    });
    return '$_temp0';
  }

  @override
  String cookingHint(String c) {
    String _temp0 = intl.Intl.selectLogic(c, {
      'diario': 'Cucino al momento',
      'lote': 'Preparo più giorni in una volta',
      'mixto': 'Alcuni giorni in anticipo',
      'other': 'Mangio fuori o qualcosa di veloce',
    });
    return '$_temp0';
  }
}
