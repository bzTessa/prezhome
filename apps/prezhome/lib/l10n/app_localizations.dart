import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bs.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bs'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('pt'),
  ];

  /// Pestaña de la barra inferior
  ///
  /// In es, this message translates to:
  /// **'{tab, select, inicio{Hoy} comidas{Comida} compra{Compra} despensa{Despensa} tareas{Tareas} other{}}'**
  String tabLabel(String tab);

  /// No description provided for @country.
  ///
  /// In es, this message translates to:
  /// **'País'**
  String get country;

  /// No description provided for @countryHint.
  ///
  /// In es, this message translates to:
  /// **'Moneda, supermercados y precios de referencia'**
  String get countryHint;

  /// No description provided for @continueLabel.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get continueLabel;

  /// No description provided for @back.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get back;

  /// No description provided for @oneMoment.
  ///
  /// In es, this message translates to:
  /// **'Un momento…'**
  String get oneMoment;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @loginAccountCreated.
  ///
  /// In es, this message translates to:
  /// **'Cuenta creada. Te damos la bienvenida a PrezHome'**
  String get loginAccountCreated;

  /// No description provided for @loginAuthError.
  ///
  /// In es, this message translates to:
  /// **'Error de autenticación'**
  String get loginAuthError;

  /// No description provided for @loginProviderError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo iniciar con {provider}'**
  String loginProviderError(String provider);

  /// No description provided for @loginResetNeedsEmail.
  ///
  /// In es, this message translates to:
  /// **'Escribe primero tu correo y te enviaré el enlace para restablecer tu contraseña.'**
  String get loginResetNeedsEmail;

  /// No description provided for @loginResetSent.
  ///
  /// In es, this message translates to:
  /// **'Te he enviado un correo para restablecer tu contraseña.'**
  String get loginResetSent;

  /// No description provided for @loginResetError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar el correo'**
  String get loginResetError;

  /// No description provided for @loginWelcomeBack.
  ///
  /// In es, this message translates to:
  /// **'Hola de nuevo'**
  String get loginWelcomeBack;

  /// No description provided for @loginCreateAccount.
  ///
  /// In es, this message translates to:
  /// **'Crea tu cuenta'**
  String get loginCreateAccount;

  /// No description provided for @loginTagline.
  ///
  /// In es, this message translates to:
  /// **'PrezHome, tu hogar organizado'**
  String get loginTagline;

  /// No description provided for @loginContinueWith.
  ///
  /// In es, this message translates to:
  /// **'Continuar con {provider}'**
  String loginContinueWith(String provider);

  /// No description provided for @loginOrEmail.
  ///
  /// In es, this message translates to:
  /// **'o con tu correo'**
  String get loginOrEmail;

  /// No description provided for @loginEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get loginEmail;

  /// No description provided for @loginEmailInvalid.
  ///
  /// In es, this message translates to:
  /// **'Introduce un correo válido'**
  String get loginEmailInvalid;

  /// No description provided for @loginPassword.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get loginPassword;

  /// No description provided for @loginShowPassword.
  ///
  /// In es, this message translates to:
  /// **'Mostrar contraseña'**
  String get loginShowPassword;

  /// No description provided for @loginHidePassword.
  ///
  /// In es, this message translates to:
  /// **'Ocultar contraseña'**
  String get loginHidePassword;

  /// No description provided for @loginPasswordShort.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 6 caracteres'**
  String get loginPasswordShort;

  /// No description provided for @loginForgot.
  ///
  /// In es, this message translates to:
  /// **'¿Has olvidado tu contraseña?'**
  String get loginForgot;

  /// No description provided for @loginSignIn.
  ///
  /// In es, this message translates to:
  /// **'Entrar'**
  String get loginSignIn;

  /// No description provided for @loginSignUp.
  ///
  /// In es, this message translates to:
  /// **'Registrarme'**
  String get loginSignUp;

  /// No description provided for @loginNoAccount.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta? Regístrate'**
  String get loginNoAccount;

  /// No description provided for @loginHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta? Inicia sesión'**
  String get loginHaveAccount;

  /// No description provided for @homeCodeFormat.
  ///
  /// In es, this message translates to:
  /// **'El código tiene 8 letras y números (por ejemplo ABCD-EFGH).'**
  String get homeCodeFormat;

  /// No description provided for @homeSetupError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo configurar el hogar'**
  String get homeSetupError;

  /// No description provided for @homeLastStep.
  ///
  /// In es, this message translates to:
  /// **'Último paso: tu hogar'**
  String get homeLastStep;

  /// No description provided for @homeCreateHint.
  ///
  /// In es, this message translates to:
  /// **'Créalo ahora y, cuando quieras, invita a quien viva contigo desde Inicio.'**
  String get homeCreateHint;

  /// No description provided for @homeCreate.
  ///
  /// In es, this message translates to:
  /// **'Crear mi hogar'**
  String get homeCreate;

  /// No description provided for @homeInvited.
  ///
  /// In es, this message translates to:
  /// **'Me han invitado a un hogar'**
  String get homeInvited;

  /// No description provided for @homeInviteCode.
  ///
  /// In es, this message translates to:
  /// **'Código de invitación'**
  String get homeInviteCode;

  /// No description provided for @homeJoin.
  ///
  /// In es, this message translates to:
  /// **'Unirme a un hogar'**
  String get homeJoin;

  /// No description provided for @sessionLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar tu perfil.'**
  String get sessionLoadError;

  /// No description provided for @onbSectionHome.
  ///
  /// In es, this message translates to:
  /// **'Tu hogar'**
  String get onbSectionHome;

  /// No description provided for @onbPeopleTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cuántas personas vivís?'**
  String get onbPeopleTitle;

  /// No description provided for @onbPeopleHint.
  ///
  /// In es, this message translates to:
  /// **'Para calcular raciones, la compra y el reparto de tareas.'**
  String get onbPeopleHint;

  /// No description provided for @onbSectionGoals.
  ///
  /// In es, this message translates to:
  /// **'Lo que te ocupa'**
  String get onbSectionGoals;

  /// No description provided for @onbGoalsTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Qué quieres quitarte de la cabeza?'**
  String get onbGoalsTitle;

  /// No description provided for @onbGoalsHint.
  ///
  /// In es, this message translates to:
  /// **'Elige todo lo que quieras. Lo demás quedará escondido.'**
  String get onbGoalsHint;

  /// No description provided for @onbPickOne.
  ///
  /// In es, this message translates to:
  /// **'Elige al menos una'**
  String get onbPickOne;

  /// No description provided for @onbContinueCount.
  ///
  /// In es, this message translates to:
  /// **'Continuar ({count})'**
  String onbContinueCount(int count);

  /// No description provided for @onbSectionKitchen.
  ///
  /// In es, this message translates to:
  /// **'En la cocina'**
  String get onbSectionKitchen;

  /// No description provided for @onbCookingTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo cocináis?'**
  String get onbCookingTitle;

  /// No description provided for @onbCookingHint.
  ///
  /// In es, this message translates to:
  /// **'Así sabemos si organizar tandas y congelador.'**
  String get onbCookingHint;

  /// No description provided for @onbSectionShopping.
  ///
  /// In es, this message translates to:
  /// **'La compra'**
  String get onbSectionShopping;

  /// No description provided for @onbShopTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Dónde compras?'**
  String get onbShopTitle;

  /// No description provided for @onbShopHint.
  ///
  /// In es, this message translates to:
  /// **'El primero será tu súper principal: las recetas usarán productos fáciles de encontrar allí.'**
  String get onbShopHint;

  /// No description provided for @onbSkipSeeHome.
  ///
  /// In es, this message translates to:
  /// **'Saltar y ver mi hogar'**
  String get onbSkipSeeHome;

  /// No description provided for @onbSeeHome.
  ///
  /// In es, this message translates to:
  /// **'Ver mi hogar'**
  String get onbSeeHome;

  /// No description provided for @onbSlogan.
  ///
  /// In es, this message translates to:
  /// **'La casa en orden, la cabeza tranquila.'**
  String get onbSlogan;

  /// No description provided for @onbStart.
  ///
  /// In es, this message translates to:
  /// **'Comenzar'**
  String get onbStart;

  /// No description provided for @onbHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'Ya tengo cuenta'**
  String get onbHaveAccount;

  /// No description provided for @onbOneLess.
  ///
  /// In es, this message translates to:
  /// **'Una menos'**
  String get onbOneLess;

  /// No description provided for @onbOneMore.
  ///
  /// In es, this message translates to:
  /// **'Una más'**
  String get onbOneMore;

  /// No description provided for @onbPeopleCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Solo yo} other{{count} personas}}'**
  String onbPeopleCount(int count);

  /// No description provided for @onbProfileBadge.
  ///
  /// In es, this message translates to:
  /// **'Tu perfil de hogar'**
  String get onbProfileBadge;

  /// No description provided for @onbProfileName.
  ///
  /// In es, this message translates to:
  /// **'{kind, select, solo{En Solitario} duo{El Dúo} tribu{La Tribu} other{La Familia}}'**
  String onbProfileName(String kind);

  /// No description provided for @onbProfileDescription.
  ///
  /// In es, this message translates to:
  /// **'{kind, select, solo{Toda la casa depende de ti. PrezHome se acuerda de lo que hay, lo que caduca y lo que toca, para que tú no tengas que hacerlo.} duo{Dos personas y una casa. PrezHome reparte la carga a la vista, para que nadie lleve la cuenta de todo en la cabeza.} other{Muchas bocas y muchas cosas a la vez. PrezHome planifica comidas, compra y tareas para todos, y avisa a cada uno de lo suyo.}}'**
  String onbProfileDescription(String kind);

  /// No description provided for @onbLoadToday.
  ///
  /// In es, this message translates to:
  /// **'Carga mental hoy'**
  String get onbLoadToday;

  /// No description provided for @onbLoadWithApp.
  ///
  /// In es, this message translates to:
  /// **'Con PrezHome'**
  String get onbLoadWithApp;

  /// No description provided for @onbLoad.
  ///
  /// In es, this message translates to:
  /// **'{level, select, high{pesada} medium{media} other{ligera}}'**
  String onbLoad(String level);

  /// No description provided for @onbCreateAccount.
  ///
  /// In es, this message translates to:
  /// **'Crear mi cuenta'**
  String get onbCreateAccount;

  /// No description provided for @onbFeature.
  ///
  /// In es, this message translates to:
  /// **'{f, select, compra{Lista de la compra} comidas{Qué comemos} despensa{Despensa y caducidades} tareas{Tareas del hogar} other{Gasto de la casa}}'**
  String onbFeature(String f);

  /// No description provided for @goalLabel.
  ///
  /// In es, this message translates to:
  /// **'{g, select, comidas{Qué comemos} compra{La compra} despensa{Lo que hay en casa} tareas{Tareas del hogar} lote{Cocinar en lote} other{El gasto de la casa}}'**
  String goalLabel(String g);

  /// No description provided for @goalHint.
  ///
  /// In es, this message translates to:
  /// **'{g, select, comidas{Plan de comidas y recetas} compra{Lista que se escribe sola} despensa{Despensa, nevera y caducidades} tareas{Reparto justo y recordatorios} lote{Táperes y congelador organizados} other{Presupuesto y tickets}}'**
  String goalHint(String g);

  /// No description provided for @cookingLabel.
  ///
  /// In es, this message translates to:
  /// **'{c, select, diario{Cada día} lote{En lote} mixto{Un poco de todo} other{Casi nunca}}'**
  String cookingLabel(String c);

  /// No description provided for @cookingHint.
  ///
  /// In es, this message translates to:
  /// **'{c, select, diario{Cocino lo del momento} lote{Preparo varios días de una vez} mixto{Algunos días en lote} other{Como fuera o algo rápido}}'**
  String cookingHint(String c);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'bs',
    'de',
    'en',
    'es',
    'fr',
    'it',
    'pt',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bs':
      return AppLocalizationsBs();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
