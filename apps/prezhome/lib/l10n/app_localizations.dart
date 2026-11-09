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

  /// No description provided for @loginConfirmEmailSent.
  ///
  /// In es, this message translates to:
  /// **'Te hemos enviado un correo para confirmar tu cuenta. Ábrelo desde este móvil y entrarás solo.'**
  String get loginConfirmEmailSent;

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
  /// **'El primero será tu súper principal: buscaremos ahí los productos de tu lista de la compra.'**
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

  /// No description provided for @homeGreeting.
  ///
  /// In es, this message translates to:
  /// **'{part, select, morning{Buenos días} afternoon{Buenas tardes} other{Buenas noches}}'**
  String homeGreeting(String part);

  /// No description provided for @homeCustomize.
  ///
  /// In es, this message translates to:
  /// **'Personalizar Inicio'**
  String get homeCustomize;

  /// No description provided for @homeYourData.
  ///
  /// In es, this message translates to:
  /// **'Tus datos'**
  String get homeYourData;

  /// No description provided for @homeYourHome.
  ///
  /// In es, this message translates to:
  /// **'Tu hogar'**
  String get homeYourHome;

  /// No description provided for @homeTodayTag.
  ///
  /// In es, this message translates to:
  /// **'Hoy · {meal}'**
  String homeTodayTag(String meal);

  /// No description provided for @mealType.
  ///
  /// In es, this message translates to:
  /// **'{type, select, breakfast{Desayuno} lunch{Comida} snack{Merienda} dinner{Cena} dessert{Postre} drink{Bebida} other{Comida}}'**
  String mealType(String type);

  /// No description provided for @homeEatingOut.
  ///
  /// In es, this message translates to:
  /// **'Fuera de casa'**
  String get homeEatingOut;

  /// No description provided for @homeWhatToEat.
  ///
  /// In es, this message translates to:
  /// **'¿Qué comemos hoy?'**
  String get homeWhatToEat;

  /// No description provided for @homeNothingPlanned.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay nada planificado para hoy.'**
  String get homeNothingPlanned;

  /// No description provided for @homePlan.
  ///
  /// In es, this message translates to:
  /// **'Planificar'**
  String get homePlan;

  /// No description provided for @homeWithWhatIHave.
  ///
  /// In es, this message translates to:
  /// **'Con lo que tengo'**
  String get homeWithWhatIHave;

  /// No description provided for @homeExpiring.
  ///
  /// In es, this message translates to:
  /// **'Por caducar'**
  String get homeExpiring;

  /// No description provided for @homeTasksToday.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Tarea hoy} other{Tareas hoy}}'**
  String homeTasksToday(int count);

  /// No description provided for @homeInShopping.
  ///
  /// In es, this message translates to:
  /// **'En la compra'**
  String get homeInShopping;

  /// No description provided for @homeShortcuts.
  ///
  /// In es, this message translates to:
  /// **'Atajos'**
  String get homeShortcuts;

  /// No description provided for @homeForToday.
  ///
  /// In es, this message translates to:
  /// **'Para hoy'**
  String get homeForToday;

  /// No description provided for @homeSeeAll.
  ///
  /// In es, this message translates to:
  /// **'Ver todo'**
  String get homeSeeAll;

  /// No description provided for @homePoints.
  ///
  /// In es, this message translates to:
  /// **'{points} pts'**
  String homePoints(int points);

  /// No description provided for @homePointsSnack.
  ///
  /// In es, this message translates to:
  /// **'+{points} puntos'**
  String homePointsSnack(int points);

  /// No description provided for @homeToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get homeToday;

  /// No description provided for @homeTomorrow.
  ///
  /// In es, this message translates to:
  /// **'Mañana'**
  String get homeTomorrow;

  /// No description provided for @homeCaloriesTitle.
  ///
  /// In es, this message translates to:
  /// **'Calcula tu objetivo de calorías'**
  String get homeCaloriesTitle;

  /// No description provided for @homeCaloriesHint.
  ///
  /// In es, this message translates to:
  /// **'Responde unas preguntas rápidas y adaptaré PrezHome a ti.'**
  String get homeCaloriesHint;

  /// No description provided for @homeOf.
  ///
  /// In es, this message translates to:
  /// **'de {total}'**
  String homeOf(String total);

  /// No description provided for @homeCaloriesToday.
  ///
  /// In es, this message translates to:
  /// **'Calorías de hoy'**
  String get homeCaloriesToday;

  /// No description provided for @homeKcal.
  ///
  /// In es, this message translates to:
  /// **'{kcal} kcal'**
  String homeKcal(int kcal);

  /// No description provided for @homeKcalLeft.
  ///
  /// In es, this message translates to:
  /// **'Te quedan {kcal} kcal'**
  String homeKcalLeft(int kcal);

  /// No description provided for @homeKcalOver.
  ///
  /// In es, this message translates to:
  /// **'Te has pasado {kcal} kcal'**
  String homeKcalOver(int kcal);

  /// No description provided for @homeMonthSpend.
  ///
  /// In es, this message translates to:
  /// **'Gasto del mes'**
  String get homeMonthSpend;

  /// No description provided for @homeMoneyLeft.
  ///
  /// In es, this message translates to:
  /// **'Te quedan {amount}'**
  String homeMoneyLeft(String amount);

  /// No description provided for @homeMoneyOver.
  ///
  /// In es, this message translates to:
  /// **'Te has pasado {amount} del presupuesto'**
  String homeMoneyOver(String amount);

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @homeCardsSection.
  ///
  /// In es, this message translates to:
  /// **'Tarjetas (arrastra para ordenar)'**
  String get homeCardsSection;

  /// No description provided for @homeQuickSection.
  ///
  /// In es, this message translates to:
  /// **'Accesos rápidos'**
  String get homeQuickSection;

  /// No description provided for @homeQuickHint.
  ///
  /// In es, this message translates to:
  /// **'Elige los atajos que verás arriba del Inicio.'**
  String get homeQuickHint;

  /// No description provided for @dashCard.
  ///
  /// In es, this message translates to:
  /// **'{id, select, meals{Comidas de hoy} calories{Calorías de hoy} tasks{Tareas} other{Gasto del mes}}'**
  String dashCard(String id);

  /// No description provided for @quickAction.
  ///
  /// In es, this message translates to:
  /// **'{id, select, add_inventory{Añadir a despensa} scan_ticket{Escanear ticket} shopping{Lista de la compra} add_recipe{Nueva receta} meal_plan{Plan semanal} other{Diario de calorías}}'**
  String quickAction(String id);

  /// No description provided for @shopPickStore.
  ///
  /// In es, this message translates to:
  /// **'Elegir supermercado'**
  String get shopPickStore;

  /// No description provided for @shopAddFromPlan.
  ///
  /// In es, this message translates to:
  /// **'Añadir lo del plan de la semana'**
  String get shopAddFromPlan;

  /// No description provided for @shopListOptions.
  ///
  /// In es, this message translates to:
  /// **'Opciones de la lista'**
  String get shopListOptions;

  /// No description provided for @shopAllInCart.
  ///
  /// In es, this message translates to:
  /// **'Todo en el carro'**
  String get shopAllInCart;

  /// No description provided for @shopPending.
  ///
  /// In es, this message translates to:
  /// **'{pending} por comprar · {done} en el carro'**
  String shopPending(int pending, int done);

  /// No description provided for @shopUnpriced.
  ///
  /// In es, this message translates to:
  /// **' · {count} sin precio'**
  String shopUnpriced(int count);

  /// No description provided for @shopAddProduct.
  ///
  /// In es, this message translates to:
  /// **'Añadir producto'**
  String get shopAddProduct;

  /// No description provided for @shopSearchStore.
  ///
  /// In es, this message translates to:
  /// **'Buscar en el súper'**
  String get shopSearchStore;

  /// No description provided for @shopAddDetailed.
  ///
  /// In es, this message translates to:
  /// **'Añadir con detalles'**
  String get shopAddDetailed;

  /// No description provided for @moreOptions.
  ///
  /// In es, this message translates to:
  /// **'Más opciones'**
  String get moreOptions;

  /// No description provided for @less.
  ///
  /// In es, this message translates to:
  /// **'Menos'**
  String get less;

  /// No description provided for @more.
  ///
  /// In es, this message translates to:
  /// **'Más'**
  String get more;

  /// No description provided for @shopAdded.
  ///
  /// In es, this message translates to:
  /// **'{name}, añadido'**
  String shopAdded(String name);

  /// No description provided for @shopAdd.
  ///
  /// In es, this message translates to:
  /// **'Añadir {name}'**
  String shopAdd(String name);

  /// No description provided for @shopLiveOffline.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión en vivo ahora mismo; se actualizará al recargar.'**
  String get shopLiveOffline;

  /// No description provided for @couldNotUpdate.
  ///
  /// In es, this message translates to:
  /// **'No se pudo actualizar'**
  String get couldNotUpdate;

  /// No description provided for @shopSavedToPantry.
  ///
  /// In es, this message translates to:
  /// **'{count} productos guardados en la despensa'**
  String shopSavedToPantry(int count);

  /// No description provided for @shopRemoveFromList.
  ///
  /// In es, this message translates to:
  /// **'Quitar de la lista'**
  String get shopRemoveFromList;

  /// No description provided for @shopRemovedOne.
  ///
  /// In es, this message translates to:
  /// **'Quitado \"{name}\"'**
  String shopRemovedOne(String name);

  /// No description provided for @couldNotChangePhoto.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cambiar la foto'**
  String get couldNotChangePhoto;

  /// No description provided for @shopAddToList.
  ///
  /// In es, this message translates to:
  /// **'Añadir a la lista'**
  String get shopAddToList;

  /// No description provided for @shopTypeFood.
  ///
  /// In es, this message translates to:
  /// **'Comida'**
  String get shopTypeFood;

  /// No description provided for @shopTypeHome.
  ///
  /// In es, this message translates to:
  /// **'Hogar/Limpieza'**
  String get shopTypeHome;

  /// No description provided for @name.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get name;

  /// No description provided for @product.
  ///
  /// In es, this message translates to:
  /// **'Producto'**
  String get product;

  /// No description provided for @quantity.
  ///
  /// In es, this message translates to:
  /// **'Cantidad'**
  String get quantity;

  /// No description provided for @unit.
  ///
  /// In es, this message translates to:
  /// **'Unidad'**
  String get unit;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @add.
  ///
  /// In es, this message translates to:
  /// **'Añadir'**
  String get add;

  /// No description provided for @nameEmpty.
  ///
  /// In es, this message translates to:
  /// **'El nombre no puede estar vacío.'**
  String get nameEmpty;

  /// No description provided for @couldNotAdd.
  ///
  /// In es, this message translates to:
  /// **'No se pudo añadir'**
  String get couldNotAdd;

  /// No description provided for @shopPlanAllAtHome.
  ///
  /// In es, this message translates to:
  /// **'Ya tienes en casa todo lo del plan'**
  String get shopPlanAllAtHome;

  /// No description provided for @shopAddedFromPlan.
  ///
  /// In es, this message translates to:
  /// **'Añadidos {count} productos del plan'**
  String shopAddedFromPlan(int count);

  /// No description provided for @shopListTitle.
  ///
  /// In es, this message translates to:
  /// **'Lista de la compra'**
  String get shopListTitle;

  /// No description provided for @shopMainList.
  ///
  /// In es, this message translates to:
  /// **'Lista principal'**
  String get shopMainList;

  /// No description provided for @couldNotCreateList.
  ///
  /// In es, this message translates to:
  /// **'No se pudo crear la lista'**
  String get couldNotCreateList;

  /// No description provided for @shopRecipesUseStore.
  ///
  /// In es, this message translates to:
  /// **'Los productos de tu lista se buscarán en este súper. Las recetas sirven para cualquiera.'**
  String get shopRecipesUseStore;

  /// No description provided for @shopStoreSaveError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar el supermercado. Inténtalo de nuevo.'**
  String get shopStoreSaveError;

  /// No description provided for @shopGroupByAisle.
  ///
  /// In es, this message translates to:
  /// **'Agrupar por pasillo'**
  String get shopGroupByAisle;

  /// No description provided for @shopGroupHint.
  ///
  /// In es, this message translates to:
  /// **'Verduras, carne, limpieza…'**
  String get shopGroupHint;

  /// No description provided for @shopShowPhotos.
  ///
  /// In es, this message translates to:
  /// **'Mostrar fotos de los productos'**
  String get shopShowPhotos;

  /// No description provided for @shopShowIcons.
  ///
  /// In es, this message translates to:
  /// **'Mostrar dibujos cuando no hay foto'**
  String get shopShowIcons;

  /// No description provided for @shopMyLists.
  ///
  /// In es, this message translates to:
  /// **'Mis listas'**
  String get shopMyLists;

  /// No description provided for @categories.
  ///
  /// In es, this message translates to:
  /// **'Categorías'**
  String get categories;

  /// No description provided for @shopFinish.
  ///
  /// In es, this message translates to:
  /// **'Terminar compra'**
  String get shopFinish;

  /// No description provided for @shopFinishCount.
  ///
  /// In es, this message translates to:
  /// **'Terminar compra ({count})'**
  String shopFinishCount(int count);

  /// No description provided for @shopScanTicket.
  ///
  /// In es, this message translates to:
  /// **'Escanear ticket'**
  String get shopScanTicket;

  /// No description provided for @shopAllBought.
  ///
  /// In es, this message translates to:
  /// **'Todo comprado'**
  String get shopAllBought;

  /// No description provided for @shopToBuy.
  ///
  /// In es, this message translates to:
  /// **'Por comprar'**
  String get shopToBuy;

  /// No description provided for @shopUsual.
  ///
  /// In es, this message translates to:
  /// **'Lo habitual'**
  String get shopUsual;

  /// No description provided for @shopInCart.
  ///
  /// In es, this message translates to:
  /// **'En el carrito'**
  String get shopInCart;

  /// No description provided for @shopRemovedMany.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Quitado 1 producto} other{Quitados {count} productos}}'**
  String shopRemovedMany(int count);

  /// No description provided for @couldNotRemove.
  ///
  /// In es, this message translates to:
  /// **'No se pudo quitar'**
  String get couldNotRemove;

  /// No description provided for @undo.
  ///
  /// In es, this message translates to:
  /// **'Deshacer'**
  String get undo;

  /// No description provided for @couldNotUndo.
  ///
  /// In es, this message translates to:
  /// **'No se pudo deshacer'**
  String get couldNotUndo;

  /// No description provided for @shopToCart.
  ///
  /// In es, this message translates to:
  /// **'Al carrito'**
  String get shopToCart;

  /// No description provided for @shopFromPlan.
  ///
  /// In es, this message translates to:
  /// **'Del plan de la semana'**
  String get shopFromPlan;

  /// No description provided for @changePhoto.
  ///
  /// In es, this message translates to:
  /// **'Cambiar foto'**
  String get changePhoto;

  /// No description provided for @shopEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu lista está vacía'**
  String get shopEmptyTitle;

  /// No description provided for @shopEmptyHint.
  ///
  /// In es, this message translates to:
  /// **'Escribe arriba lo que necesitas o trae lo del plan.'**
  String get shopEmptyHint;

  /// No description provided for @shopFromPlanAction.
  ///
  /// In es, this message translates to:
  /// **'Desde el plan'**
  String get shopFromPlanAction;

  /// No description provided for @shopDoneTitle.
  ///
  /// In es, this message translates to:
  /// **'Compra completada'**
  String get shopDoneTitle;

  /// No description provided for @shopDoneHint.
  ///
  /// In es, this message translates to:
  /// **'Ya tienes todo lo de la lista. ¡Buen trabajo!'**
  String get shopDoneHint;

  /// No description provided for @panUsedInOne.
  ///
  /// In es, this message translates to:
  /// **'Quitado lo que usaste en {meal}'**
  String panUsedInOne(String meal);

  /// No description provided for @panUsedInMany.
  ///
  /// In es, this message translates to:
  /// **'Quitado lo que usaste en {count} comidas del plan'**
  String panUsedInMany(int count);

  /// No description provided for @view.
  ///
  /// In es, this message translates to:
  /// **'Ver'**
  String get view;

  /// No description provided for @couldNotDelete.
  ///
  /// In es, this message translates to:
  /// **'No se pudo eliminar'**
  String get couldNotDelete;

  /// No description provided for @panNoLongerShop.
  ///
  /// In es, this message translates to:
  /// **'{name} ya no aparecerá en la compra.'**
  String panNoLongerShop(String name);

  /// No description provided for @panBackToShop.
  ///
  /// In es, this message translates to:
  /// **'{name} volverá a aparecer en la compra.'**
  String panBackToShop(String name);

  /// No description provided for @panCouldNotMarkOut.
  ///
  /// In es, this message translates to:
  /// **'No se pudo marcar {name} como agotado'**
  String panCouldNotMarkOut(String name);

  /// No description provided for @panMarkedOut.
  ///
  /// In es, this message translates to:
  /// **'He marcado {name} como agotado.'**
  String panMarkedOut(String name);

  /// No description provided for @panOutNotAdded.
  ///
  /// In es, this message translates to:
  /// **'{name} quedó agotado, pero no pude añadirlo a la compra'**
  String panOutNotAdded(String name);

  /// No description provided for @panAlreadyInList.
  ///
  /// In es, this message translates to:
  /// **'{name} ya está en tu lista de la compra.'**
  String panAlreadyInList(String name);

  /// No description provided for @panAddedToShop.
  ///
  /// In es, this message translates to:
  /// **'He añadido {name} a la compra'**
  String panAddedToShop(String name);

  /// No description provided for @panAddManual.
  ///
  /// In es, this message translates to:
  /// **'Añadir a mano'**
  String get panAddManual;

  /// No description provided for @panScanBarcode.
  ///
  /// In es, this message translates to:
  /// **'Escanear código de barras'**
  String get panScanBarcode;

  /// No description provided for @panFreezeDish.
  ///
  /// In es, this message translates to:
  /// **'Plato cocinado al congelador'**
  String get panFreezeDish;

  /// No description provided for @panFreezeDishHint.
  ///
  /// In es, this message translates to:
  /// **'Elige la receta y cuántas raciones'**
  String get panFreezeDishHint;

  /// No description provided for @panSaveRecipeFirst.
  ///
  /// In es, this message translates to:
  /// **'Primero guarda alguna receta.'**
  String get panSaveRecipeFirst;

  /// No description provided for @panWhichDish.
  ///
  /// In es, this message translates to:
  /// **'¿Qué plato vas a congelar?'**
  String get panWhichDish;

  /// No description provided for @panHowManyServings.
  ///
  /// In es, this message translates to:
  /// **'¿Cuántas raciones congelas?'**
  String get panHowManyServings;

  /// No description provided for @panTitle.
  ///
  /// In es, this message translates to:
  /// **'Despensa y Nevera'**
  String get panTitle;

  /// No description provided for @panAddTooltip.
  ///
  /// In es, this message translates to:
  /// **'Añadir a la despensa'**
  String get panAddTooltip;

  /// No description provided for @panLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el inventario'**
  String get panLoadError;

  /// No description provided for @panEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu despensa está vacía'**
  String get panEmptyTitle;

  /// No description provided for @panEmptyHint.
  ///
  /// In es, this message translates to:
  /// **'Añade lo que tienes en casa o tacha la compra y llegará solo.'**
  String get panEmptyHint;

  /// No description provided for @panAddProduct.
  ///
  /// In es, this message translates to:
  /// **'Añadir producto'**
  String get panAddProduct;

  /// No description provided for @panWhatToCook.
  ///
  /// In es, this message translates to:
  /// **'¿Qué cocino con esto?'**
  String get panWhatToCook;

  /// No description provided for @panExpiringHeader.
  ///
  /// In es, this message translates to:
  /// **'Caducados y a punto de caducar'**
  String get panExpiringHeader;

  /// No description provided for @panNothingHere.
  ///
  /// In es, this message translates to:
  /// **'Aquí no hay nada.'**
  String get panNothingHere;

  /// No description provided for @kitchenZone.
  ///
  /// In es, this message translates to:
  /// **'{zone, select, nevera{Nevera} congelador{Congelador} despensa{Despensa} bebidas{Bebidas} especias{Condimentos} limpieza{Limpieza} hogar{Higiene y hogar} other{{zone}}}'**
  String kitchenZone(String zone);

  /// No description provided for @kitchenReview.
  ///
  /// In es, this message translates to:
  /// **'Revisar'**
  String get kitchenReview;

  /// No description provided for @expiryGroup.
  ///
  /// In es, this message translates to:
  /// **'{group, select, expired{Caducado} week{Esta semana} later{Más adelante} other{Sin fecha}}'**
  String expiryGroup(String group);

  /// No description provided for @panExpiredAgo.
  ///
  /// In es, this message translates to:
  /// **'Caducó hace {days} días'**
  String panExpiredAgo(int days);

  /// No description provided for @panExpiredYesterday.
  ///
  /// In es, this message translates to:
  /// **'Caducó ayer'**
  String get panExpiredYesterday;

  /// No description provided for @panExpiresToday.
  ///
  /// In es, this message translates to:
  /// **'Caduca hoy'**
  String get panExpiresToday;

  /// No description provided for @panExpiresTomorrow.
  ///
  /// In es, this message translates to:
  /// **'Caduca mañana'**
  String get panExpiresTomorrow;

  /// No description provided for @panExpiresIn.
  ///
  /// In es, this message translates to:
  /// **'Caduca en {days} días'**
  String panExpiresIn(int days);

  /// No description provided for @panDays.
  ///
  /// In es, this message translates to:
  /// **'{days} días'**
  String panDays(int days);

  /// No description provided for @panNotBought.
  ///
  /// In es, this message translates to:
  /// **'No se compra'**
  String get panNotBought;

  /// No description provided for @panConsumed.
  ///
  /// In es, this message translates to:
  /// **'Consumido'**
  String get panConsumed;

  /// No description provided for @panToShopping.
  ///
  /// In es, this message translates to:
  /// **'A la compra'**
  String get panToShopping;

  /// No description provided for @panCouldNotAddToShop.
  ///
  /// In es, this message translates to:
  /// **'No pude añadir {name} a la compra'**
  String panCouldNotAddToShop(String name);

  /// No description provided for @panExpiredDeleted.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Caducado eliminado} other{{count} caducados eliminados}}'**
  String panExpiredDeleted(int count);

  /// No description provided for @panMyKitchen.
  ///
  /// In es, this message translates to:
  /// **'Mi cocina'**
  String get panMyKitchen;

  /// No description provided for @panUsedHistory.
  ///
  /// In es, this message translates to:
  /// **'Lo que se ha gastado'**
  String get panUsedHistory;

  /// No description provided for @panNothingExpired.
  ///
  /// In es, this message translates to:
  /// **'Nada caducado'**
  String get panNothingExpired;

  /// No description provided for @panDeleteExpired.
  ///
  /// In es, this message translates to:
  /// **'Eliminar caducados ({count})'**
  String panDeleteExpired(int count);

  /// No description provided for @panEmptyZone.
  ///
  /// In es, this message translates to:
  /// **'Vaciar {where}'**
  String panEmptyZone(String where);

  /// No description provided for @panEmptyAsk.
  ///
  /// In es, this message translates to:
  /// **'¿Vaciar {where}?'**
  String panEmptyAsk(String where);

  /// No description provided for @panWillDelete.
  ///
  /// In es, this message translates to:
  /// **'Se eliminarán {count} productos.'**
  String panWillDelete(int count);

  /// No description provided for @panEmpty.
  ///
  /// In es, this message translates to:
  /// **'Vaciar'**
  String get panEmpty;

  /// No description provided for @panDeleted.
  ///
  /// In es, this message translates to:
  /// **'{count} productos eliminados'**
  String panDeleted(int count);

  /// No description provided for @edit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @panShopAgain.
  ///
  /// In es, this message translates to:
  /// **'Volver a añadir a la compra'**
  String get panShopAgain;

  /// No description provided for @panDontShop.
  ///
  /// In es, this message translates to:
  /// **'No añadir a la compra'**
  String get panDontShop;

  /// No description provided for @panStapleHint.
  ///
  /// In es, this message translates to:
  /// **'Para básicos que siempre tienes'**
  String get panStapleHint;

  /// No description provided for @panWillAddToShop.
  ///
  /// In es, this message translates to:
  /// **'Lo añadiré a la compra'**
  String get panWillAddToShop;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get delete;

  /// No description provided for @panDeleteAsk.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar {name}?'**
  String panDeleteAsk(String name);

  /// No description provided for @panConsumedOn.
  ///
  /// In es, this message translates to:
  /// **'{name}, consumido {day}'**
  String panConsumedOn(String name, String day);

  /// No description provided for @todayLower.
  ///
  /// In es, this message translates to:
  /// **'hoy'**
  String get todayLower;

  /// No description provided for @yesterdayLower.
  ///
  /// In es, this message translates to:
  /// **'ayer'**
  String get yesterdayLower;

  /// No description provided for @panOnDate.
  ///
  /// In es, this message translates to:
  /// **'el {day}/{month}'**
  String panOnDate(int day, int month);

  /// No description provided for @panWhen.
  ///
  /// In es, this message translates to:
  /// **'¿Cuándo?'**
  String get panWhen;

  /// No description provided for @today.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In es, this message translates to:
  /// **'Ayer'**
  String get yesterday;

  /// No description provided for @panOtherDay.
  ///
  /// In es, this message translates to:
  /// **'Otro día'**
  String get panOtherDay;

  /// No description provided for @panWhichDay.
  ///
  /// In es, this message translates to:
  /// **'¿Qué día?'**
  String get panWhichDay;

  /// No description provided for @panHowMany.
  ///
  /// In es, this message translates to:
  /// **'¿Cuántos?'**
  String get panHowMany;

  /// No description provided for @panAll.
  ///
  /// In es, this message translates to:
  /// **'Todo ({qty})'**
  String panAll(String qty);

  /// No description provided for @couldNotLoad.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar'**
  String get couldNotLoad;

  /// No description provided for @panNothingYet.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay nada.'**
  String get panNothingYet;

  /// No description provided for @panWhenCooking.
  ///
  /// In es, this message translates to:
  /// **'Al cocinar'**
  String get panWhenCooking;

  /// No description provided for @planHowLong.
  ///
  /// In es, this message translates to:
  /// **'¿Para cuánto tiempo?'**
  String get planHowLong;

  /// No description provided for @thisWeek.
  ///
  /// In es, this message translates to:
  /// **'Esta semana'**
  String get thisWeek;

  /// No description provided for @planWeeks.
  ///
  /// In es, this message translates to:
  /// **'{count} semanas'**
  String planWeeks(int count);

  /// No description provided for @planMonth4.
  ///
  /// In es, this message translates to:
  /// **'Un mes (4 semanas)'**
  String get planMonth4;

  /// No description provided for @planPickDates.
  ///
  /// In es, this message translates to:
  /// **'Elegir fechas'**
  String get planPickDates;

  /// No description provided for @planDates.
  ///
  /// In es, this message translates to:
  /// **'Fechas del plan'**
  String get planDates;

  /// No description provided for @planMaxTwoMonths.
  ///
  /// In es, this message translates to:
  /// **'Como mucho dos meses de una vez.'**
  String get planMaxTwoMonths;

  /// No description provided for @planReadyAllHome.
  ///
  /// In es, this message translates to:
  /// **'Plan listo. Ya tienes en casa todo lo que necesitas'**
  String get planReadyAllHome;

  /// No description provided for @planListReady.
  ///
  /// In es, this message translates to:
  /// **'Plan listo. Lista de la compra con {count} productos'**
  String planListReady(int count);

  /// No description provided for @planBackInPlan.
  ///
  /// In es, this message translates to:
  /// **'Vuelve a estar en el plan'**
  String get planBackInPlan;

  /// No description provided for @planEntryTitle.
  ///
  /// In es, this message translates to:
  /// **'{meal} · {recipe}'**
  String planEntryTitle(String meal, String recipe);

  /// No description provided for @planNoRecipe.
  ///
  /// In es, this message translates to:
  /// **'Sin receta'**
  String get planNoRecipe;

  /// No description provided for @planChangeRecipe.
  ///
  /// In es, this message translates to:
  /// **'Cambiar receta'**
  String get planChangeRecipe;

  /// No description provided for @planWhoEats.
  ///
  /// In es, this message translates to:
  /// **'Quién come'**
  String get planWhoEats;

  /// No description provided for @planMarkHome.
  ///
  /// In es, this message translates to:
  /// **'Marcar en casa'**
  String get planMarkHome;

  /// No description provided for @planMarkOut.
  ///
  /// In es, this message translates to:
  /// **'Marcar como fuera'**
  String get planMarkOut;

  /// No description provided for @planStopRepeat.
  ///
  /// In es, this message translates to:
  /// **'Dejar de repetir'**
  String get planStopRepeat;

  /// No description provided for @planStopRepeatHint.
  ///
  /// In es, this message translates to:
  /// **'Quita las siguientes veces'**
  String get planStopRepeatHint;

  /// No description provided for @planRepeat.
  ///
  /// In es, this message translates to:
  /// **'Repetir'**
  String get planRepeat;

  /// No description provided for @planRepeatHint.
  ///
  /// In es, this message translates to:
  /// **'Cada día, cada semana… o para siempre'**
  String get planRepeatHint;

  /// No description provided for @planRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar del plan'**
  String get planRemove;

  /// No description provided for @planRepeatTitle.
  ///
  /// In es, this message translates to:
  /// **'Repetir {meal}'**
  String planRepeatTitle(String meal);

  /// No description provided for @planHowOften.
  ///
  /// In es, this message translates to:
  /// **'¿Cada cuánto?'**
  String get planHowOften;

  /// No description provided for @planEveryDays.
  ///
  /// In es, this message translates to:
  /// **'{days, plural, =1{Cada día} other{Cada {days} días}}'**
  String planEveryDays(int days);

  /// No description provided for @planEveryWeeks.
  ///
  /// In es, this message translates to:
  /// **'{weeks, plural, =1{Cada semana} other{Cada {weeks} semanas}}'**
  String planEveryWeeks(int weeks);

  /// No description provided for @planUntilWhen.
  ///
  /// In es, this message translates to:
  /// **'¿Hasta cuándo?'**
  String get planUntilWhen;

  /// No description provided for @planForever.
  ///
  /// In es, this message translates to:
  /// **'Para siempre'**
  String get planForever;

  /// No description provided for @planMonths.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 mes} other{{count} meses}}'**
  String planMonths(int count);

  /// No description provided for @planRepeatDone.
  ///
  /// In es, this message translates to:
  /// **'Hecho. Lo verás en el plan las próximas semanas; si un día ya tiene otra cosa, se respeta.'**
  String get planRepeatDone;

  /// No description provided for @planWhoAtHome.
  ///
  /// In es, this message translates to:
  /// **'¿Quién come en casa?'**
  String get planWhoAtHome;

  /// No description provided for @planCalendarPermission.
  ///
  /// In es, this message translates to:
  /// **'Da permiso al calendario en los ajustes del móvil'**
  String get planCalendarPermission;

  /// No description provided for @planInFast.
  ///
  /// In es, this message translates to:
  /// **'Cae en el ayuno'**
  String get planInFast;

  /// No description provided for @planSettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes del plan'**
  String get planSettings;

  /// No description provided for @planBatchCook.
  ///
  /// In es, this message translates to:
  /// **'Cocino en tanda'**
  String get planBatchCook;

  /// No description provided for @planBatchCookHint.
  ///
  /// In es, this message translates to:
  /// **'Día de compra, de cocina y tápers'**
  String get planBatchCookHint;

  /// No description provided for @planTimes.
  ///
  /// In es, this message translates to:
  /// **'Horas'**
  String get planTimes;

  /// No description provided for @planFasting.
  ///
  /// In es, this message translates to:
  /// **'Ayuno intermitente'**
  String get planFasting;

  /// No description provided for @no.
  ///
  /// In es, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @planEatWindow.
  ///
  /// In es, this message translates to:
  /// **'Comes de {from} a {to}. Se mueve con la hora de la cena.'**
  String planEatWindow(String from, String to);

  /// No description provided for @planCalendar.
  ///
  /// In es, this message translates to:
  /// **'Calendario'**
  String get planCalendar;

  /// No description provided for @planToCalendar.
  ///
  /// In es, this message translates to:
  /// **'Pasar al calendario'**
  String get planToCalendar;

  /// No description provided for @planCalendarLinked.
  ///
  /// In es, this message translates to:
  /// **'Calendario conectado'**
  String get planCalendarLinked;

  /// No description provided for @planCalendarHint.
  ///
  /// In es, this message translates to:
  /// **'Comidas y tareas con hora, en Google Calendar'**
  String get planCalendarHint;

  /// No description provided for @planCalendarUpdates.
  ///
  /// In es, this message translates to:
  /// **'Se actualiza al abrir el plan'**
  String get planCalendarUpdates;

  /// No description provided for @remove.
  ///
  /// In es, this message translates to:
  /// **'Quitar'**
  String get remove;

  /// No description provided for @planPickRecipe.
  ///
  /// In es, this message translates to:
  /// **'Elige una receta'**
  String get planPickRecipe;

  /// No description provided for @planDayFull.
  ///
  /// In es, this message translates to:
  /// **'Ese día ya tiene todas las comidas.'**
  String get planDayFull;

  /// No description provided for @planWhichMeal.
  ///
  /// In es, this message translates to:
  /// **'¿Qué comida añades?'**
  String get planWhichMeal;

  /// No description provided for @planTitle.
  ///
  /// In es, this message translates to:
  /// **'Plan semanal'**
  String get planTitle;

  /// No description provided for @planNoHome.
  ///
  /// In es, this message translates to:
  /// **'No perteneces a ningún hogar.'**
  String get planNoHome;

  /// No description provided for @planMake.
  ///
  /// In es, this message translates to:
  /// **'Hacer plan'**
  String get planMake;

  /// No description provided for @planRemake.
  ///
  /// In es, this message translates to:
  /// **'Rehacer plan'**
  String get planRemake;

  /// No description provided for @planNeedRecipes.
  ///
  /// In es, this message translates to:
  /// **'Añade algunas recetas primero'**
  String get planNeedRecipes;

  /// No description provided for @planNeedRecipesHint.
  ///
  /// In es, this message translates to:
  /// **'El planificador reparte tus recetas por la semana. Guarda unas cuantas en la pestaña Comidas.'**
  String get planNeedRecipesHint;

  /// No description provided for @planPrevWeek.
  ///
  /// In es, this message translates to:
  /// **'Semana anterior'**
  String get planPrevWeek;

  /// No description provided for @planNextWeekLabel.
  ///
  /// In es, this message translates to:
  /// **'La próxima semana'**
  String get planNextWeekLabel;

  /// No description provided for @planLastWeek.
  ///
  /// In es, this message translates to:
  /// **'La semana pasada'**
  String get planLastWeek;

  /// No description provided for @planWeek.
  ///
  /// In es, this message translates to:
  /// **'Semana'**
  String get planWeek;

  /// No description provided for @planBackToToday.
  ///
  /// In es, this message translates to:
  /// **'Volver a hoy'**
  String get planBackToToday;

  /// No description provided for @planNextWeek.
  ///
  /// In es, this message translates to:
  /// **'Semana siguiente'**
  String get planNextWeek;

  /// No description provided for @planDay.
  ///
  /// In es, this message translates to:
  /// **'Día'**
  String get planDay;

  /// No description provided for @planMonthCalendar.
  ///
  /// In es, this message translates to:
  /// **'Calendario del mes'**
  String get planMonthCalendar;

  /// No description provided for @planNoPlanYet.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay plan para esta semana.'**
  String get planNoPlanYet;

  /// No description provided for @recipe.
  ///
  /// In es, this message translates to:
  /// **'Receta'**
  String get recipe;

  /// No description provided for @planCookMode.
  ///
  /// In es, this message translates to:
  /// **'Modo cocina'**
  String get planCookMode;

  /// No description provided for @planCookWeek.
  ///
  /// In es, this message translates to:
  /// **'Cocina la semana de una vez'**
  String get planCookWeek;

  /// No description provided for @planBatch.
  ///
  /// In es, this message translates to:
  /// **'Cocina en lote'**
  String get planBatch;

  /// No description provided for @planCookDays.
  ///
  /// In es, this message translates to:
  /// **'{days, plural, =1{1 día de cocina} other{{days} días de cocina}} · {recipes, plural, =1{1 receta} other{{recipes} recetas}}'**
  String planCookDays(int days, int recipes);

  /// No description provided for @planBatchEmpty.
  ///
  /// In es, this message translates to:
  /// **'Con el plan hecho te digo cuándo comprar, cuándo cocinar y qué va a la nevera o al congelador.'**
  String get planBatchEmpty;

  /// No description provided for @planCookedToFreezer.
  ///
  /// In es, this message translates to:
  /// **'Ya cocinado · al congelador'**
  String get planCookedToFreezer;

  /// No description provided for @planFrozen.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Guardado en el congelador con su foto.} other{{count} platos guardados en el congelador.}}'**
  String planFrozen(int count);

  /// No description provided for @planEnergyLow.
  ///
  /// In es, this message translates to:
  /// **'Poco'**
  String get planEnergyLow;

  /// No description provided for @planEnergyNormal.
  ///
  /// In es, this message translates to:
  /// **'Normal'**
  String get planEnergyNormal;

  /// No description provided for @planEnergyHigh.
  ///
  /// In es, this message translates to:
  /// **'Mucho'**
  String get planEnergyHigh;

  /// No description provided for @planEnergyHint.
  ///
  /// In es, this message translates to:
  /// **'Con \"poco\" el plan tira más del congelador.'**
  String get planEnergyHint;

  /// No description provided for @planHowMuchCook.
  ///
  /// In es, this message translates to:
  /// **'Cuánto cocinar'**
  String get planHowMuchCook;

  /// No description provided for @planServings.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 ración} other{{count} raciones}}'**
  String planServings(int count);

  /// No description provided for @close.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get close;

  /// No description provided for @planSearchRecipe.
  ///
  /// In es, this message translates to:
  /// **'Buscar receta...'**
  String get planSearchRecipe;

  /// No description provided for @planNoMatch.
  ///
  /// In es, this message translates to:
  /// **'Sin recetas que coincidan.'**
  String get planNoMatch;

  /// No description provided for @diaDeleteError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo borrar la comida.'**
  String get diaDeleteError;

  /// No description provided for @diaManual.
  ///
  /// In es, this message translates to:
  /// **'A mano'**
  String get diaManual;

  /// No description provided for @diaManualHint.
  ///
  /// In es, this message translates to:
  /// **'Escribe el nombre y las calorías'**
  String get diaManualHint;

  /// No description provided for @diaFromRecipe.
  ///
  /// In es, this message translates to:
  /// **'Desde una receta'**
  String get diaFromRecipe;

  /// No description provided for @diaFromRecipeHint.
  ///
  /// In es, this message translates to:
  /// **'Registra una receta tuya como comida'**
  String get diaFromRecipeHint;

  /// No description provided for @diaWithPhoto.
  ///
  /// In es, this message translates to:
  /// **'Con una foto'**
  String get diaWithPhoto;

  /// No description provided for @diaWithPhotoHint.
  ///
  /// In es, this message translates to:
  /// **'Haz una foto al plato y calculamos las calorías'**
  String get diaWithPhotoHint;

  /// No description provided for @diaAddManual.
  ///
  /// In es, this message translates to:
  /// **'Añadir a mano'**
  String get diaAddManual;

  /// No description provided for @diaKcalField.
  ///
  /// In es, this message translates to:
  /// **'Calorías (kcal)'**
  String get diaKcalField;

  /// No description provided for @diaMealTypeOptional.
  ///
  /// In es, this message translates to:
  /// **'Tipo de comida (opcional)'**
  String get diaMealTypeOptional;

  /// No description provided for @diaNoType.
  ///
  /// In es, this message translates to:
  /// **'Sin tipo'**
  String get diaNoType;

  /// No description provided for @diaProteinG.
  ///
  /// In es, this message translates to:
  /// **'Proteína (g)'**
  String get diaProteinG;

  /// No description provided for @diaCarbsG.
  ///
  /// In es, this message translates to:
  /// **'Carbos (g)'**
  String get diaCarbsG;

  /// No description provided for @diaFatG.
  ///
  /// In es, this message translates to:
  /// **'Grasa (g)'**
  String get diaFatG;

  /// No description provided for @diaNeedNameKcal.
  ///
  /// In es, this message translates to:
  /// **'Pon al menos un nombre y las calorías.'**
  String get diaNeedNameKcal;

  /// No description provided for @diaSaveError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar la comida.'**
  String get diaSaveError;

  /// No description provided for @diaRecipesLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las recetas.'**
  String get diaRecipesLoadError;

  /// No description provided for @diaNoRecipes.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes recetas que registrar.'**
  String get diaNoRecipes;

  /// No description provided for @diaKcalPerServing.
  ///
  /// In es, this message translates to:
  /// **'{kcal} kcal por ración'**
  String diaKcalPerServing(int kcal);

  /// No description provided for @diaNoKcal.
  ///
  /// In es, this message translates to:
  /// **'Sin calorías registradas'**
  String get diaNoKcal;

  /// No description provided for @diaServings.
  ///
  /// In es, this message translates to:
  /// **'Raciones'**
  String get diaServings;

  /// No description provided for @diaServingsError.
  ///
  /// In es, this message translates to:
  /// **'Pon un número de raciones mayor que 0.'**
  String get diaServingsError;

  /// No description provided for @diaLog.
  ///
  /// In es, this message translates to:
  /// **'Registrar'**
  String get diaLog;

  /// No description provided for @diaRecipeLogError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo registrar la receta.'**
  String get diaRecipeLogError;

  /// No description provided for @diaTitle.
  ///
  /// In es, this message translates to:
  /// **'Mi diario'**
  String get diaTitle;

  /// No description provided for @diaAddMeal.
  ///
  /// In es, this message translates to:
  /// **'Añadir comida'**
  String get diaAddMeal;

  /// No description provided for @previous.
  ///
  /// In es, this message translates to:
  /// **'Anterior'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get next;

  /// No description provided for @diaDayCalories.
  ///
  /// In es, this message translates to:
  /// **'Calorías del día'**
  String get diaDayCalories;

  /// No description provided for @diaOfTarget.
  ///
  /// In es, this message translates to:
  /// **'de {kcal} kcal'**
  String diaOfTarget(int kcal);

  /// No description provided for @diaNoTarget.
  ///
  /// In es, this message translates to:
  /// **'Completa tu perfil para fijar un objetivo diario de calorías y ver cuánto te queda cada día.'**
  String get diaNoTarget;

  /// No description provided for @diaCompleteProfile.
  ///
  /// In es, this message translates to:
  /// **'Completar mi perfil'**
  String get diaCompleteProfile;

  /// No description provided for @diaOthers.
  ///
  /// In es, this message translates to:
  /// **'Otras'**
  String get diaOthers;

  /// No description provided for @diaMeal.
  ///
  /// In es, this message translates to:
  /// **'Comida'**
  String get diaMeal;

  /// No description provided for @diaLast7.
  ///
  /// In es, this message translates to:
  /// **'Tus últimos 7 días'**
  String get diaLast7;

  /// No description provided for @diaTargetPerDay.
  ///
  /// In es, this message translates to:
  /// **'Objetivo: {kcal} kcal al día'**
  String diaTargetPerDay(int kcal);

  /// No description provided for @diaTarget.
  ///
  /// In es, this message translates to:
  /// **'Objetivo'**
  String get diaTarget;

  /// No description provided for @diaTodaySplit.
  ///
  /// In es, this message translates to:
  /// **'Reparto de hoy'**
  String get diaTodaySplit;

  /// No description provided for @diaNoMacros.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay macros registrados hoy.'**
  String get diaNoMacros;

  /// No description provided for @diaProtein.
  ///
  /// In es, this message translates to:
  /// **'Proteína'**
  String get diaProtein;

  /// No description provided for @diaCarbs.
  ///
  /// In es, this message translates to:
  /// **'Carbos'**
  String get diaCarbs;

  /// No description provided for @diaFat.
  ///
  /// In es, this message translates to:
  /// **'Grasa'**
  String get diaFat;

  /// No description provided for @diaAteThePlan.
  ///
  /// In es, this message translates to:
  /// **'¿Has comido lo del plan?'**
  String get diaAteThePlan;

  /// No description provided for @diaAskLine.
  ///
  /// In es, this message translates to:
  /// **'{day}, {meal}: {name} · {kcal} kcal'**
  String diaAskLine(String day, String meal, String name, int kcal);

  /// No description provided for @yes.
  ///
  /// In es, this message translates to:
  /// **'Sí'**
  String get yes;

  /// No description provided for @diaAnswerError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar la respuesta.'**
  String get diaAnswerError;

  /// No description provided for @diaAskFirst.
  ///
  /// In es, this message translates to:
  /// **'Preguntarme antes de apuntar el plan'**
  String get diaAskFirst;

  /// No description provided for @diaAskOn.
  ///
  /// In es, this message translates to:
  /// **'Te preguntamos si has comido cada comida del plan.'**
  String get diaAskOn;

  /// No description provided for @diaAskOff.
  ///
  /// In es, this message translates to:
  /// **'Las comidas del plan se apuntan solas al pasar su hora.'**
  String get diaAskOff;

  /// No description provided for @diaSettingError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar el ajuste.'**
  String get diaSettingError;

  /// No description provided for @diaEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no has apuntado nada este día.\nAñade tu primera comida.'**
  String get diaEmpty;

  /// No description provided for @recUnfavorite.
  ///
  /// In es, this message translates to:
  /// **'Quitar de favoritas'**
  String get recUnfavorite;

  /// No description provided for @recFavorite.
  ///
  /// In es, this message translates to:
  /// **'Marcar como favorita'**
  String get recFavorite;

  /// No description provided for @recDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar receta'**
  String get recDelete;

  /// No description provided for @recDeleteAsk.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar receta?'**
  String get recDeleteAsk;

  /// No description provided for @recRemoveAsk.
  ///
  /// In es, this message translates to:
  /// **'Se borrará \"{name}\" y sus ingredientes.'**
  String recRemoveAsk(String name);

  /// No description provided for @recDeleted.
  ///
  /// In es, this message translates to:
  /// **'\"{name}\" eliminada.'**
  String recDeleted(String name);

  /// No description provided for @recTitle.
  ///
  /// In es, this message translates to:
  /// **'Recetas'**
  String get recTitle;

  /// No description provided for @recNew.
  ///
  /// In es, this message translates to:
  /// **'Nueva receta'**
  String get recNew;

  /// No description provided for @recLoadError.
  ///
  /// In es, this message translates to:
  /// **'No he podido cargar las recetas'**
  String get recLoadError;

  /// No description provided for @recEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay recetas'**
  String get recEmptyTitle;

  /// No description provided for @recEmptyHint.
  ///
  /// In es, this message translates to:
  /// **'Crea la primera o pide ideas con lo que tienes.'**
  String get recEmptyHint;

  /// No description provided for @recIdeas.
  ///
  /// In es, this message translates to:
  /// **'Ideas con lo que tengo'**
  String get recIdeas;

  /// No description provided for @recNoResults.
  ///
  /// In es, this message translates to:
  /// **'Sin resultados'**
  String get recNoResults;

  /// No description provided for @recCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 receta} other{{count} recetas}}'**
  String recCount(int count);

  /// No description provided for @recWhatToCook.
  ///
  /// In es, this message translates to:
  /// **'¿Qué cocino con lo que tengo?'**
  String get recWhatToCook;

  /// No description provided for @recPantryIdeas.
  ///
  /// In es, this message translates to:
  /// **'Ideas con lo que hay en tu despensa'**
  String get recPantryIdeas;

  /// No description provided for @recAll.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get recAll;

  /// No description provided for @recFavorites.
  ///
  /// In es, this message translates to:
  /// **'Favoritas'**
  String get recFavorites;

  /// No description provided for @recOther.
  ///
  /// In es, this message translates to:
  /// **'Otras'**
  String get recOther;

  /// No description provided for @recSeeAll.
  ///
  /// In es, this message translates to:
  /// **'Ver las {count}'**
  String recSeeAll(int count);

  /// No description provided for @recNoFilter.
  ///
  /// In es, this message translates to:
  /// **'No hay recetas con este filtro.\nPrueba con otra categoría.'**
  String get recNoFilter;

  /// No description provided for @clear.
  ///
  /// In es, this message translates to:
  /// **'Limpiar'**
  String get clear;

  /// No description provided for @recNoMatch.
  ///
  /// In es, this message translates to:
  /// **'No hay recetas que coincidan con\n\"{query}\".'**
  String recNoMatch(String query);

  /// No description provided for @rdPhoto.
  ///
  /// In es, this message translates to:
  /// **'Foto de la receta'**
  String get rdPhoto;

  /// No description provided for @rdAutoPhoto.
  ///
  /// In es, this message translates to:
  /// **'Buscar otra foto automática'**
  String get rdAutoPhoto;

  /// No description provided for @rdAutoPhotoHint.
  ///
  /// In es, this message translates to:
  /// **'Busca una imagen nueva por el nombre'**
  String get rdAutoPhotoHint;

  /// No description provided for @rdGallery.
  ///
  /// In es, this message translates to:
  /// **'Elegir de la galería'**
  String get rdGallery;

  /// No description provided for @rdNoBetterPhoto.
  ///
  /// In es, this message translates to:
  /// **'No he encontrado otra foto mejor por ahora'**
  String get rdNoBetterPhoto;

  /// No description provided for @rdUploadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo subir la foto'**
  String get rdUploadError;

  /// No description provided for @rdShareText.
  ///
  /// In es, this message translates to:
  /// **'Te paso mi receta de {title} en PrezHome. En la app, ve a Recetas, toca Añadir receta y luego Con un código: {code}'**
  String rdShareText(String title, String code);

  /// No description provided for @rdSavedFreezer.
  ///
  /// In es, this message translates to:
  /// **'Guardado en el congelador.'**
  String get rdSavedFreezer;

  /// No description provided for @couldNotSave.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar'**
  String get couldNotSave;

  /// No description provided for @rdVideoError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir el enlace del video'**
  String get rdVideoError;

  /// No description provided for @rdWatchVideo.
  ///
  /// In es, this message translates to:
  /// **'Ver vídeo'**
  String get rdWatchVideo;

  /// No description provided for @share.
  ///
  /// In es, this message translates to:
  /// **'Compartir'**
  String get share;

  /// No description provided for @rdEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar receta'**
  String get rdEdit;

  /// No description provided for @rdMinutes.
  ///
  /// In es, this message translates to:
  /// **'Minutos'**
  String get rdMinutes;

  /// No description provided for @rdKcalServing.
  ///
  /// In es, this message translates to:
  /// **'Kcal/ración'**
  String get rdKcalServing;

  /// No description provided for @rdPerServingShort.
  ///
  /// In es, this message translates to:
  /// **'por ración'**
  String get rdPerServingShort;

  /// No description provided for @rdServingWord.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Ración} other{Raciones}}'**
  String rdServingWord(int count);

  /// No description provided for @rdFreezable.
  ///
  /// In es, this message translates to:
  /// **'Congelable'**
  String get rdFreezable;

  /// No description provided for @rdIngredients.
  ///
  /// In es, this message translates to:
  /// **'Ingredientes'**
  String get rdIngredients;

  /// No description provided for @rdStepsWord.
  ///
  /// In es, this message translates to:
  /// **'Pasos'**
  String get rdStepsWord;

  /// No description provided for @rdSteps.
  ///
  /// In es, this message translates to:
  /// **'Pasos ({count})'**
  String rdSteps(int count);

  /// No description provided for @rdNutrition.
  ///
  /// In es, this message translates to:
  /// **'Nutrición'**
  String get rdNutrition;

  /// No description provided for @rdNoIngredients.
  ///
  /// In es, this message translates to:
  /// **'Sin ingredientes registrados.'**
  String get rdNoIngredients;

  /// No description provided for @rdOriginal.
  ///
  /// In es, this message translates to:
  /// **'Receta original: {servings}'**
  String rdOriginal(String servings);

  /// No description provided for @rdForHome.
  ///
  /// In es, this message translates to:
  /// **'Para tu hogar hoy: {servings}'**
  String rdForHome(String servings);

  /// No description provided for @rdHaveAll.
  ///
  /// In es, this message translates to:
  /// **'Tienes todo en casa'**
  String get rdHaveAll;

  /// No description provided for @rdHaveSome.
  ///
  /// In es, this message translates to:
  /// **'Tienes {have} de {total} en casa'**
  String rdHaveSome(int have, int total);

  /// No description provided for @rdMissing.
  ///
  /// In es, this message translates to:
  /// **'Faltan {count}'**
  String rdMissing(int count);

  /// No description provided for @rdAtHome.
  ///
  /// In es, this message translates to:
  /// **'En casa'**
  String get rdAtHome;

  /// No description provided for @rdLacking.
  ///
  /// In es, this message translates to:
  /// **'Falta'**
  String get rdLacking;

  /// No description provided for @rdNoSteps.
  ///
  /// In es, this message translates to:
  /// **'Esta receta no tiene pasos. Puedes añadirlos editándola.'**
  String get rdNoSteps;

  /// No description provided for @rdPerServingTitle.
  ///
  /// In es, this message translates to:
  /// **'Por ración'**
  String get rdPerServingTitle;

  /// No description provided for @rdNoNutrition.
  ///
  /// In es, this message translates to:
  /// **'Sin datos de nutrición.'**
  String get rdNoNutrition;

  /// No description provided for @rdPerServing.
  ///
  /// In es, this message translates to:
  /// **'{amount} por ración'**
  String rdPerServing(String amount);

  /// No description provided for @rdTotal.
  ///
  /// In es, this message translates to:
  /// **'≈ {amount} total'**
  String rdTotal(String amount);

  /// No description provided for @rdApproxCost.
  ///
  /// In es, this message translates to:
  /// **'Coste aproximado. Escanea tickets para afinarlo con tus precios reales.'**
  String get rdApproxCost;

  /// No description provided for @rdStartCooking.
  ///
  /// In es, this message translates to:
  /// **'Empezar a cocinar'**
  String get rdStartCooking;

  /// No description provided for @rdAddedMissing.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Añadido a la lista de la compra} other{Añadidos {count} productos a la compra}}'**
  String rdAddedMissing(int count);

  /// No description provided for @rdNeedProfile.
  ///
  /// In es, this message translates to:
  /// **'Completa un Perfil Nutricional para ver cuántos gramos y calorías corresponden a cada persona.'**
  String get rdNeedProfile;

  /// No description provided for @rdMember.
  ///
  /// In es, this message translates to:
  /// **'Miembro'**
  String get rdMember;

  /// No description provided for @rdAdjustSplit.
  ///
  /// In es, this message translates to:
  /// **'Ajusta el reparto de calorías por comida en el perfil para este tipo de receta.'**
  String get rdAdjustSplit;

  /// No description provided for @rdByProfile.
  ///
  /// In es, this message translates to:
  /// **'Según el perfil de cada uno'**
  String get rdByProfile;

  /// No description provided for @rdByProfileHint.
  ///
  /// In es, this message translates to:
  /// **'Cantidad y calorías por persona para esta comida.'**
  String get rdByProfileHint;

  /// No description provided for @arWriteName.
  ///
  /// In es, this message translates to:
  /// **'Escribe el nombre'**
  String get arWriteName;

  /// No description provided for @arWriteNameHint.
  ///
  /// In es, this message translates to:
  /// **'Escribe el nombre o pega una receta entera…'**
  String get arWriteNameHint;

  /// No description provided for @arGenerate.
  ///
  /// In es, this message translates to:
  /// **'Generar'**
  String get arGenerate;

  /// No description provided for @arFilled.
  ///
  /// In es, this message translates to:
  /// **'Receta rellenada. Revísala antes de guardar.'**
  String get arFilled;

  /// No description provided for @arFillError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar la receta'**
  String get arFillError;

  /// No description provided for @arImport.
  ///
  /// In es, this message translates to:
  /// **'Importar receta'**
  String get arImport;

  /// No description provided for @arPasteRecipe.
  ///
  /// In es, this message translates to:
  /// **'Pega la receta'**
  String get arPasteRecipe;

  /// No description provided for @arImportHint.
  ///
  /// In es, this message translates to:
  /// **'Pega el enlace de TikTok, YouTube o una web, o el texto de la receta. En Instagram copia la descripción del post y pégala aquí.'**
  String get arImportHint;

  /// No description provided for @arLinkOrText.
  ///
  /// In es, this message translates to:
  /// **'Enlace o texto de la receta'**
  String get arLinkOrText;

  /// No description provided for @arRecipeText.
  ///
  /// In es, this message translates to:
  /// **'Texto de la receta'**
  String get arRecipeText;

  /// No description provided for @paste.
  ///
  /// In es, this message translates to:
  /// **'Pegar'**
  String get paste;

  /// No description provided for @arImportBtn.
  ///
  /// In es, this message translates to:
  /// **'Importar'**
  String get arImportBtn;

  /// No description provided for @arNeedLink.
  ///
  /// In es, this message translates to:
  /// **'Pega un enlace o el texto completo de la receta.'**
  String get arNeedLink;

  /// No description provided for @arImported.
  ///
  /// In es, this message translates to:
  /// **'Receta importada. Revísala antes de guardar.'**
  String get arImported;

  /// No description provided for @arImportLinkError.
  ///
  /// In es, this message translates to:
  /// **'No pude importar la receta de ese enlace'**
  String get arImportLinkError;

  /// No description provided for @arImportError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo importar'**
  String get arImportError;

  /// No description provided for @arPickMealType.
  ///
  /// In es, this message translates to:
  /// **'Elige al menos un tipo de comida.'**
  String get arPickMealType;

  /// No description provided for @arVideoNotUrl.
  ///
  /// In es, this message translates to:
  /// **'El enlace de video no parece una URL, pero lo guardamos igual.'**
  String get arVideoNotUrl;

  /// No description provided for @arRecalculated.
  ///
  /// In es, this message translates to:
  /// **'Calorías y macros recalculadas con los ingredientes.'**
  String get arRecalculated;

  /// No description provided for @arPhotoFailed.
  ///
  /// In es, this message translates to:
  /// **'Receta guardada, pero la foto no se pudo subir: {error}'**
  String arPhotoFailed(String error);

  /// No description provided for @arSaveError.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar'**
  String get arSaveError;

  /// No description provided for @arReadingVideo.
  ///
  /// In es, this message translates to:
  /// **'Leyendo la receta del vídeo…'**
  String get arReadingVideo;

  /// No description provided for @arCompleting.
  ///
  /// In es, this message translates to:
  /// **'Completando la receta…'**
  String get arCompleting;

  /// No description provided for @arAddPhoto.
  ///
  /// In es, this message translates to:
  /// **'Añadir foto (opcional)'**
  String get arAddPhoto;

  /// No description provided for @arTitleField.
  ///
  /// In es, this message translates to:
  /// **'Título'**
  String get arTitleField;

  /// No description provided for @arTitleRequired.
  ///
  /// In es, this message translates to:
  /// **'Ponle un título'**
  String get arTitleRequired;

  /// No description provided for @arDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción (opcional)'**
  String get arDescription;

  /// No description provided for @arVideoLink.
  ///
  /// In es, this message translates to:
  /// **'Enlace de video (opcional)'**
  String get arVideoLink;

  /// No description provided for @arMealTypes.
  ///
  /// In es, this message translates to:
  /// **'Tipo de comida (puedes elegir varios)'**
  String get arMealTypes;

  /// No description provided for @arAuto.
  ///
  /// In es, this message translates to:
  /// **'Auto'**
  String get arAuto;

  /// No description provided for @arServingsHelper.
  ///
  /// In es, this message translates to:
  /// **'Para cuántas es'**
  String get arServingsHelper;

  /// No description provided for @arGramsServing.
  ///
  /// In es, this message translates to:
  /// **'Gramos / ración'**
  String get arGramsServing;

  /// No description provided for @arNutritionTitle.
  ///
  /// In es, this message translates to:
  /// **'Valores nutricionales (por ración)'**
  String get arNutritionTitle;

  /// No description provided for @arCooking.
  ///
  /// In es, this message translates to:
  /// **'Cocina'**
  String get arCooking;

  /// No description provided for @arPrepMin.
  ///
  /// In es, this message translates to:
  /// **'Preparación (min)'**
  String get arPrepMin;

  /// No description provided for @arCookMin.
  ///
  /// In es, this message translates to:
  /// **'Cocción (min)'**
  String get arCookMin;

  /// No description provided for @arAppliance.
  ///
  /// In es, this message translates to:
  /// **'Aparato principal'**
  String get arAppliance;

  /// No description provided for @arFreezable.
  ///
  /// In es, this message translates to:
  /// **'Es congelable'**
  String get arFreezable;

  /// No description provided for @arAddIngredient.
  ///
  /// In es, this message translates to:
  /// **'Añadir ingrediente'**
  String get arAddIngredient;

  /// No description provided for @arStepsTitle.
  ///
  /// In es, this message translates to:
  /// **'Pasos de preparación'**
  String get arStepsTitle;

  /// No description provided for @arStepsHint.
  ///
  /// In es, this message translates to:
  /// **'Escribe los pasos, uno por línea…'**
  String get arStepsHint;

  /// No description provided for @arSaveChanges.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get arSaveChanges;

  /// No description provided for @arSaveRecipe.
  ///
  /// In es, this message translates to:
  /// **'Guardar Receta'**
  String get arSaveRecipe;

  /// No description provided for @arIngredient.
  ///
  /// In es, this message translates to:
  /// **'Ingrediente'**
  String get arIngredient;

  /// No description provided for @tskWhoDid.
  ///
  /// In es, this message translates to:
  /// **'¿Quién hizo la tarea?'**
  String get tskWhoDid;

  /// No description provided for @tskTheHome.
  ///
  /// In es, this message translates to:
  /// **'el hogar'**
  String get tskTheHome;

  /// No description provided for @tskPointsFor.
  ///
  /// In es, this message translates to:
  /// **'+{points} puntos para {who}'**
  String tskPointsFor(int points, String who);

  /// No description provided for @tskPointsForPantry.
  ///
  /// In es, this message translates to:
  /// **'+{points} puntos para {who}. {count} productos a la despensa'**
  String tskPointsForPantry(int points, String who, int count);

  /// No description provided for @tskYou.
  ///
  /// In es, this message translates to:
  /// **'{name} (tú)'**
  String tskYou(String name);

  /// No description provided for @tskThisMember.
  ///
  /// In es, this message translates to:
  /// **'este miembro'**
  String get tskThisMember;

  /// No description provided for @tskResetPoints.
  ///
  /// In es, this message translates to:
  /// **'Reiniciar puntos'**
  String get tskResetPoints;

  /// No description provided for @tskResetAsk.
  ///
  /// In es, this message translates to:
  /// **'Se pondrán a 0 los puntos de {name}. Esto no se puede deshacer. ¿Seguro?'**
  String tskResetAsk(String name);

  /// No description provided for @tskReset.
  ///
  /// In es, this message translates to:
  /// **'Reiniciar'**
  String get tskReset;

  /// No description provided for @tskResetDone.
  ///
  /// In es, this message translates to:
  /// **'Puntos de {name} reiniciados.'**
  String tskResetDone(String name);

  /// No description provided for @tskDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar tarea?'**
  String get tskDeleteTitle;

  /// No description provided for @tskDeleteAsk.
  ///
  /// In es, this message translates to:
  /// **'Se borrará \"{title}\".'**
  String tskDeleteAsk(String title);

  /// No description provided for @tskClaimed.
  ///
  /// In es, this message translates to:
  /// **'\"{title}\" es tuya'**
  String tskClaimed(String title);

  /// No description provided for @tskDone.
  ///
  /// In es, this message translates to:
  /// **'Hecha'**
  String get tskDone;

  /// No description provided for @tskToTomorrow.
  ///
  /// In es, this message translates to:
  /// **'Pasar a mañana'**
  String get tskToTomorrow;

  /// No description provided for @tskToNextWeek.
  ///
  /// In es, this message translates to:
  /// **'Pasar a la próxima semana'**
  String get tskToNextWeek;

  /// No description provided for @tskTitle.
  ///
  /// In es, this message translates to:
  /// **'Tareas'**
  String get tskTitle;

  /// No description provided for @tskEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'No hay tareas todavía'**
  String get tskEmptyTitle;

  /// No description provided for @tskEmptyHint.
  ///
  /// In es, this message translates to:
  /// **'Añade la primera.'**
  String get tskEmptyHint;

  /// No description provided for @tskNew.
  ///
  /// In es, this message translates to:
  /// **'Nueva tarea'**
  String get tskNew;

  /// No description provided for @tskAnyone.
  ///
  /// In es, this message translates to:
  /// **'Cualquiera'**
  String get tskAnyone;

  /// No description provided for @tskForToday.
  ///
  /// In es, this message translates to:
  /// **'Para hoy'**
  String get tskForToday;

  /// No description provided for @tskUpcoming.
  ///
  /// In es, this message translates to:
  /// **'Próximos días'**
  String get tskUpcoming;

  /// No description provided for @tskPoolEmpty.
  ///
  /// In es, this message translates to:
  /// **'Nada en la bolsa. Todo tiene dueño.'**
  String get tskPoolEmpty;

  /// No description provided for @tskSwipeToClaim.
  ///
  /// In es, this message translates to:
  /// **'Desliza a la izquierda para pedírtela.'**
  String get tskSwipeToClaim;

  /// No description provided for @tskNothingDone.
  ///
  /// In es, this message translates to:
  /// **'Hoy aún no hay nada hecho.'**
  String get tskNothingDone;

  /// No description provided for @tskAll.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get tskAll;

  /// No description provided for @tskMine.
  ///
  /// In es, this message translates to:
  /// **'Mías'**
  String get tskMine;

  /// No description provided for @tskAllDoneToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy está todo hecho'**
  String get tskAllDoneToday;

  /// No description provided for @tskNextBelow.
  ///
  /// In es, this message translates to:
  /// **'Lo siguiente, abajo.'**
  String get tskNextBelow;

  /// No description provided for @tskNothingLeft.
  ///
  /// In es, this message translates to:
  /// **'No queda nada pendiente.'**
  String get tskNothingLeft;

  /// No description provided for @tskScoreboard.
  ///
  /// In es, this message translates to:
  /// **'MARCADOR'**
  String get tskScoreboard;

  /// No description provided for @tskPointsPerPerson.
  ///
  /// In es, this message translates to:
  /// **'PUNTOS POR PERSONA'**
  String get tskPointsPerPerson;

  /// No description provided for @tskNoPoints.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay puntos'**
  String get tskNoPoints;

  /// No description provided for @tskNoPointsHint.
  ///
  /// In es, this message translates to:
  /// **'Completa tareas para ir sumando.'**
  String get tskNoPointsHint;

  /// No description provided for @tskSomeDays.
  ///
  /// In es, this message translates to:
  /// **'Algunos días'**
  String get tskSomeDays;

  /// No description provided for @tskOnce.
  ///
  /// In es, this message translates to:
  /// **'Una vez'**
  String get tskOnce;

  /// No description provided for @tskNothingToday.
  ///
  /// In es, this message translates to:
  /// **'Nada para hoy'**
  String get tskNothingToday;

  /// No description provided for @tskAllDone.
  ///
  /// In es, this message translates to:
  /// **'Todo hecho'**
  String get tskAllDone;

  /// No description provided for @tskLeft.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Queda 1} other{Quedan {count}}}'**
  String tskLeft(int count);

  /// No description provided for @tskOverdueCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 atrasada} other{{count} atrasadas}}'**
  String tskOverdueCount(int count);

  /// No description provided for @tskMarkDone.
  ///
  /// In es, this message translates to:
  /// **'Marcar {title} como hecha'**
  String tskMarkDone(String title);

  /// No description provided for @tskClaim.
  ///
  /// In es, this message translates to:
  /// **'Pedirme {title}'**
  String tskClaim(String title);

  /// No description provided for @tskOverdue.
  ///
  /// In es, this message translates to:
  /// **'Atrasada'**
  String get tskOverdue;

  /// No description provided for @tskPts.
  ///
  /// In es, this message translates to:
  /// **'{points} pts'**
  String tskPts(int points);

  /// No description provided for @tskView.
  ///
  /// In es, this message translates to:
  /// **'{view, select, pending{Pendientes} pool{Bolsa} other{Hechas}}'**
  String tskView(String view);

  /// No description provided for @tskOtherDay.
  ///
  /// In es, this message translates to:
  /// **'Otro día'**
  String get tskOtherDay;

  /// No description provided for @tskEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar tarea'**
  String get tskEdit;

  /// No description provided for @tskNameHint.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la tarea'**
  String get tskNameHint;

  /// No description provided for @tskOrTypeAnother.
  ///
  /// In es, this message translates to:
  /// **'O escribe otra'**
  String get tskOrTypeAnother;

  /// No description provided for @tskWhen.
  ///
  /// In es, this message translates to:
  /// **'Cuándo'**
  String get tskWhen;

  /// No description provided for @tomorrow.
  ///
  /// In es, this message translates to:
  /// **'Mañana'**
  String get tomorrow;

  /// No description provided for @tskNoDate.
  ///
  /// In es, this message translates to:
  /// **'Sin fecha'**
  String get tskNoDate;

  /// No description provided for @tskRepeats.
  ///
  /// In es, this message translates to:
  /// **'Se repite'**
  String get tskRepeats;

  /// No description provided for @tskWho.
  ///
  /// In es, this message translates to:
  /// **'Quién'**
  String get tskWho;

  /// No description provided for @tskMe.
  ///
  /// In es, this message translates to:
  /// **'Yo'**
  String get tskMe;

  /// No description provided for @tskAddPersonHint.
  ///
  /// In es, this message translates to:
  /// **'Para asignarla a alguien, añade a esa persona en Hogar (aunque no tenga cuenta).'**
  String get tskAddPersonHint;

  /// No description provided for @tskDetails.
  ///
  /// In es, this message translates to:
  /// **'Detalles'**
  String get tskDetails;

  /// No description provided for @tskNoTime.
  ///
  /// In es, this message translates to:
  /// **'Sin hora'**
  String get tskNoTime;

  /// No description provided for @tskRemoveTime.
  ///
  /// In es, this message translates to:
  /// **'Quitar hora'**
  String get tskRemoveTime;

  /// No description provided for @tskFreeAt.
  ///
  /// In es, this message translates to:
  /// **'Libre a las {time}'**
  String tskFreeAt(String time);

  /// No description provided for @tskNotes.
  ///
  /// In es, this message translates to:
  /// **'Notas'**
  String get tskNotes;

  /// No description provided for @tskPoints.
  ///
  /// In es, this message translates to:
  /// **'Puntos'**
  String get tskPoints;

  /// No description provided for @tskAdd.
  ///
  /// In es, this message translates to:
  /// **'Añadir tarea'**
  String get tskAdd;

  /// No description provided for @arcTitle.
  ///
  /// In es, this message translates to:
  /// **'Añadir receta'**
  String get arcTitle;

  /// No description provided for @arcLinkTitle.
  ///
  /// In es, this message translates to:
  /// **'Pegar enlace de vídeo'**
  String get arcLinkTitle;

  /// No description provided for @arcLinkSub.
  ///
  /// In es, this message translates to:
  /// **'De TikTok o YouTube, o el texto de Instagram'**
  String get arcLinkSub;

  /// No description provided for @arcNameTitle.
  ///
  /// In es, this message translates to:
  /// **'Escribe el nombre'**
  String get arcNameTitle;

  /// No description provided for @arcNameSub.
  ///
  /// In es, this message translates to:
  /// **'Se completa con ingredientes, pasos y macros'**
  String get arcNameSub;

  /// No description provided for @arcIdeasTitle.
  ///
  /// In es, this message translates to:
  /// **'Ideas para ti'**
  String get arcIdeasTitle;

  /// No description provided for @arcIdeasSub.
  ///
  /// In es, this message translates to:
  /// **'Según tu súper, objetivo y presupuesto'**
  String get arcIdeasSub;

  /// No description provided for @arcManualTitle.
  ///
  /// In es, this message translates to:
  /// **'A mano'**
  String get arcManualTitle;

  /// No description provided for @arcManualSub.
  ///
  /// In es, this message translates to:
  /// **'Rellena tú cada campo'**
  String get arcManualSub;

  /// No description provided for @arcCodeTitle.
  ///
  /// In es, this message translates to:
  /// **'Con un código'**
  String get arcCodeTitle;

  /// No description provided for @arcCodeSub.
  ///
  /// In es, this message translates to:
  /// **'Guarda una receta que te han compartido'**
  String get arcCodeSub;

  /// No description provided for @arcCodeDialog.
  ///
  /// In es, this message translates to:
  /// **'Código de la receta'**
  String get arcCodeDialog;

  /// No description provided for @search.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get search;

  /// No description provided for @arcNoCode.
  ///
  /// In es, this message translates to:
  /// **'No hay ninguna receta con ese código'**
  String get arcNoCode;

  /// No description provided for @arcIngredientsAsk.
  ///
  /// In es, this message translates to:
  /// **'{count} ingredientes. ¿La guardas en tus recetas?'**
  String arcIngredientsAsk(int count);

  /// No description provided for @arcSaved.
  ///
  /// In es, this message translates to:
  /// **'Receta guardada'**
  String get arcSaved;

  /// No description provided for @nutLoadError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar el perfil'**
  String get nutLoadError;

  /// No description provided for @nutSaved.
  ///
  /// In es, this message translates to:
  /// **'Perfil guardado'**
  String get nutSaved;

  /// No description provided for @nutSaveError.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar'**
  String get nutSaveError;

  /// No description provided for @nutBirthDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de nacimiento'**
  String get nutBirthDate;

  /// No description provided for @nutTitle.
  ///
  /// In es, this message translates to:
  /// **'Mi perfil nutricional'**
  String get nutTitle;

  /// No description provided for @nutDiary.
  ///
  /// In es, this message translates to:
  /// **'Diario de calorías'**
  String get nutDiary;

  /// No description provided for @nutWizard.
  ///
  /// In es, this message translates to:
  /// **'Configurar paso a paso'**
  String get nutWizard;

  /// No description provided for @nutWizardSub.
  ///
  /// In es, this message translates to:
  /// **'Un asistente te hace unas preguntas y calcula tu objetivo.'**
  String get nutWizardSub;

  /// No description provided for @nutHowCook.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo cocinas?'**
  String get nutHowCook;

  /// No description provided for @nutDaily.
  ///
  /// In es, this message translates to:
  /// **'Del día'**
  String get nutDaily;

  /// No description provided for @nutDailySub.
  ///
  /// In es, this message translates to:
  /// **'Cocino cada día'**
  String get nutDailySub;

  /// No description provided for @nutBatch.
  ///
  /// In es, this message translates to:
  /// **'Cocinar en lote'**
  String get nutBatch;

  /// No description provided for @nutBatchSub.
  ///
  /// In es, this message translates to:
  /// **'Cocino de una vez para varios días'**
  String get nutBatchSub;

  /// No description provided for @nutAmounts.
  ///
  /// In es, this message translates to:
  /// **'Cantidades'**
  String get nutAmounts;

  /// No description provided for @nutPractical.
  ///
  /// In es, this message translates to:
  /// **'Prácticas'**
  String get nutPractical;

  /// No description provided for @nutPracticalSub.
  ///
  /// In es, this message translates to:
  /// **'Formatos de súper'**
  String get nutPracticalSub;

  /// No description provided for @nutExact.
  ///
  /// In es, this message translates to:
  /// **'Exactas'**
  String get nutExact;

  /// No description provided for @nutExactSub.
  ///
  /// In es, this message translates to:
  /// **'Al gramo'**
  String get nutExactSub;

  /// No description provided for @nutSex.
  ///
  /// In es, this message translates to:
  /// **'Sexo'**
  String get nutSex;

  /// No description provided for @nutFemale.
  ///
  /// In es, this message translates to:
  /// **'Mujer'**
  String get nutFemale;

  /// No description provided for @nutMale.
  ///
  /// In es, this message translates to:
  /// **'Hombre'**
  String get nutMale;

  /// No description provided for @nutSelect.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar…'**
  String get nutSelect;

  /// No description provided for @nutAge.
  ///
  /// In es, this message translates to:
  /// **'({age} años)'**
  String nutAge(int age);

  /// No description provided for @nutHeight.
  ///
  /// In es, this message translates to:
  /// **'Altura (cm)'**
  String get nutHeight;

  /// No description provided for @nutWeight.
  ///
  /// In es, this message translates to:
  /// **'Peso (kg)'**
  String get nutWeight;

  /// No description provided for @nutActivityLevel.
  ///
  /// In es, this message translates to:
  /// **'Nivel de actividad'**
  String get nutActivityLevel;

  /// No description provided for @nutGoalLabel.
  ///
  /// In es, this message translates to:
  /// **'Objetivo'**
  String get nutGoalLabel;

  /// No description provided for @nutActivity.
  ///
  /// In es, this message translates to:
  /// **'{level, select, sedentary{Sedentario (poco o nada de ejercicio)} light{Ligero (1-3 días/semana)} moderate{Moderado (3-5 días/semana)} active{Activo (6-7 días/semana)} other{Muy activo (ejercicio intenso o trabajo físico)}}'**
  String nutActivity(String level);

  /// No description provided for @nutGoal.
  ///
  /// In es, this message translates to:
  /// **'{goal, select, lose{Perder peso} gain{Ganar peso} other{Mantener peso}}'**
  String nutGoal(String goal);

  /// No description provided for @nutSplit.
  ///
  /// In es, this message translates to:
  /// **'Reparto de calorías por comida'**
  String get nutSplit;

  /// No description provided for @nutTotal.
  ///
  /// In es, this message translates to:
  /// **'Total: {pct}%'**
  String nutTotal(int pct);

  /// No description provided for @nutSplitHint.
  ///
  /// In es, this message translates to:
  /// **'Pon 0% en las comidas que no haces. La suma debería ser 100%.'**
  String get nutSplitHint;

  /// No description provided for @nutAtHome.
  ///
  /// In es, this message translates to:
  /// **'Comidas en casa'**
  String get nutAtHome;

  /// No description provided for @nutAtHomeHint.
  ///
  /// In es, this message translates to:
  /// **'Marca los días que haces cada comida en casa. Si comes fuera (p. ej. en el trabajo), desmarca ese día y no se contará.'**
  String get nutAtHomeHint;

  /// No description provided for @nutShare.
  ///
  /// In es, this message translates to:
  /// **'Compartir mi perfil con el hogar'**
  String get nutShare;

  /// No description provided for @nutShareSub.
  ///
  /// In es, this message translates to:
  /// **'Si está desactivado, tu perfil es privado.'**
  String get nutShareSub;

  /// No description provided for @nutSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar perfil'**
  String get nutSave;

  /// No description provided for @nutIncomplete.
  ///
  /// In es, this message translates to:
  /// **'Completa sexo, fecha de nacimiento, altura y peso para calcular tus calorías y macros diarios.'**
  String get nutIncomplete;

  /// No description provided for @nutDailyTarget.
  ///
  /// In es, this message translates to:
  /// **'Tu objetivo diario (aprox.)'**
  String get nutDailyTarget;

  /// No description provided for @nutKcalDay.
  ///
  /// In es, this message translates to:
  /// **'{kcal} kcal / día'**
  String nutKcalDay(int kcal);

  /// No description provided for @nutPerMeal.
  ///
  /// In es, this message translates to:
  /// **'≈ {kcal} kcal por comida ({meals} comidas)'**
  String nutPerMeal(int kcal, int meals);

  /// No description provided for @ecoBudgetTitle.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto mensual'**
  String get ecoBudgetTitle;

  /// No description provided for @ecoAmount.
  ///
  /// In es, this message translates to:
  /// **'Importe ({symbol})'**
  String ecoAmount(String symbol);

  /// No description provided for @ecoDeleteTicket.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar ticket?'**
  String get ecoDeleteTicket;

  /// No description provided for @ecoDeleteTicketSub.
  ///
  /// In es, this message translates to:
  /// **'Dejará de contar en tus gastos.'**
  String get ecoDeleteTicketSub;

  /// No description provided for @ecoRedeemed.
  ///
  /// In es, this message translates to:
  /// **'Has canjeado \"{title}\"'**
  String ecoRedeemed(String title);

  /// No description provided for @ecoRedeemFail.
  ///
  /// In es, this message translates to:
  /// **'No se ha podido canjear. Puede que te falte saldo.'**
  String get ecoRedeemFail;

  /// No description provided for @ecoNewReward.
  ///
  /// In es, this message translates to:
  /// **'Nueva recompensa'**
  String get ecoNewReward;

  /// No description provided for @ecoRewardTitle.
  ///
  /// In es, this message translates to:
  /// **'Título'**
  String get ecoRewardTitle;

  /// No description provided for @ecoRewardDesc.
  ///
  /// In es, this message translates to:
  /// **'Descripción (opcional)'**
  String get ecoRewardDesc;

  /// No description provided for @ecoRewardCost.
  ///
  /// In es, this message translates to:
  /// **'Coste en puntos'**
  String get ecoRewardCost;

  /// No description provided for @ecoTitle.
  ///
  /// In es, this message translates to:
  /// **'Gastos y tickets'**
  String get ecoTitle;

  /// No description provided for @ecoStats.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas de la compra'**
  String get ecoStats;

  /// No description provided for @ecoScan.
  ///
  /// In es, this message translates to:
  /// **'Escanear ticket'**
  String get ecoScan;

  /// No description provided for @ecoTicketsOf.
  ///
  /// In es, this message translates to:
  /// **'Tickets de {month}'**
  String ecoTicketsOf(String month);

  /// No description provided for @ecoPointsBalance.
  ///
  /// In es, this message translates to:
  /// **'Balanza de puntos'**
  String get ecoPointsBalance;

  /// No description provided for @ecoPointsBalanceSub.
  ///
  /// In es, this message translates to:
  /// **'Saldo de cada miembro para canjear recompensas.'**
  String get ecoPointsBalanceSub;

  /// No description provided for @ecoNoPoints.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay puntos que repartir'**
  String get ecoNoPoints;

  /// No description provided for @ecoNoPointsSub.
  ///
  /// In es, this message translates to:
  /// **'Completad tareas del hogar para llenar la balanza.'**
  String get ecoNoPointsSub;

  /// No description provided for @ecoRewards.
  ///
  /// In es, this message translates to:
  /// **'Recompensas'**
  String get ecoRewards;

  /// No description provided for @ecoBalance.
  ///
  /// In es, this message translates to:
  /// **'Tu saldo: {points} pts'**
  String ecoBalance(int points);

  /// No description provided for @ecoRedeem.
  ///
  /// In es, this message translates to:
  /// **'Canjear'**
  String get ecoRedeem;

  /// No description provided for @ecoNoRewards.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay recompensas'**
  String get ecoNoRewards;

  /// No description provided for @ecoNoRewardsSub.
  ///
  /// In es, this message translates to:
  /// **'Crea la primera con el botón \"Nueva recompensa\".'**
  String get ecoNoRewardsSub;

  /// No description provided for @ecoTotalSpent.
  ///
  /// In es, this message translates to:
  /// **'Gasto total registrado'**
  String get ecoTotalSpent;

  /// No description provided for @ecoTicketCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 ticket en total} other{{count} tickets en total}}'**
  String ecoTicketCount(int count);

  /// No description provided for @ecoThisMonth.
  ///
  /// In es, this message translates to:
  /// **'Este mes'**
  String get ecoThisMonth;

  /// No description provided for @ecoBudget.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto: {amount}'**
  String ecoBudget(String amount);

  /// No description provided for @ecoSetBudget.
  ///
  /// In es, this message translates to:
  /// **'Fijar presupuesto'**
  String get ecoSetBudget;

  /// No description provided for @ecoOver.
  ///
  /// In es, this message translates to:
  /// **'Te has pasado {amount} del presupuesto'**
  String ecoOver(String amount);

  /// No description provided for @ecoLeft.
  ///
  /// In es, this message translates to:
  /// **'Te quedan {amount}'**
  String ecoLeft(String amount);

  /// No description provided for @ecoLastMonths.
  ///
  /// In es, this message translates to:
  /// **'Gasto de los últimos meses'**
  String get ecoLastMonths;

  /// No description provided for @ecoBudgetPerMonth.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto: {amount} al mes'**
  String ecoBudgetPerMonth(String amount);

  /// No description provided for @ecoBudgetShort.
  ///
  /// In es, this message translates to:
  /// **'Presupuesto'**
  String get ecoBudgetShort;

  /// No description provided for @ecoNoTrend.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay gasto registrado en los últimos meses.\nCuando escanees tickets verás aquí tu tendencia.'**
  String get ecoNoTrend;

  /// No description provided for @ecoTicket.
  ///
  /// In es, this message translates to:
  /// **'Ticket'**
  String get ecoTicket;

  /// No description provided for @ecoNoTickets.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay tickets este mes.\nEscanea el primero.'**
  String get ecoNoTickets;

  /// No description provided for @stOthers.
  ///
  /// In es, this message translates to:
  /// **'Otros'**
  String get stOthers;

  /// No description provided for @stNoCategory.
  ///
  /// In es, this message translates to:
  /// **'Sin categoría'**
  String get stNoCategory;

  /// No description provided for @stThisWeek.
  ///
  /// In es, this message translates to:
  /// **'Esta'**
  String get stThisWeek;

  /// No description provided for @stTitle.
  ///
  /// In es, this message translates to:
  /// **'Tus datos'**
  String get stTitle;

  /// No description provided for @stSpendByMonth.
  ///
  /// In es, this message translates to:
  /// **'Gasto por mes'**
  String get stSpendByMonth;

  /// No description provided for @stForecastFooter.
  ///
  /// In es, this message translates to:
  /// **'En claro, lo que falta para la previsión'**
  String get stForecastFooter;

  /// No description provided for @stNoSpend.
  ///
  /// In es, this message translates to:
  /// **'Escanea un ticket y verás tu gasto mes a mes.'**
  String get stNoSpend;

  /// No description provided for @stWhereSpend.
  ///
  /// In es, this message translates to:
  /// **'En qué gastas este mes'**
  String get stWhereSpend;

  /// No description provided for @stNoTicketsMonth.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay tickets este mes.'**
  String get stNoTicketsMonth;

  /// No description provided for @stTopProducts.
  ///
  /// In es, this message translates to:
  /// **'Lo que más compras'**
  String get stTopProducts;

  /// No description provided for @stTopProductsFooter.
  ///
  /// In es, this message translates to:
  /// **'Veces en tus tickets de los últimos 3 meses'**
  String get stTopProductsFooter;

  /// No description provided for @stTopProductsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Saldrá cuando escanees tickets.'**
  String get stTopProductsEmpty;

  /// No description provided for @stPantry.
  ///
  /// In es, this message translates to:
  /// **'Tu despensa'**
  String get stPantry;

  /// No description provided for @stMealsHome.
  ///
  /// In es, this message translates to:
  /// **'Comidas en casa'**
  String get stMealsHome;

  /// No description provided for @stPerWeek.
  ///
  /// In es, this message translates to:
  /// **'Por semana'**
  String get stPerWeek;

  /// No description provided for @stMealsOut.
  ///
  /// In es, this message translates to:
  /// **'Por semana · {count} fuera de casa'**
  String stMealsOut(int count);

  /// No description provided for @stMealsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Planifica comidas y verás cuántas hacéis en casa.'**
  String get stMealsEmpty;

  /// No description provided for @stTasksDone.
  ///
  /// In es, this message translates to:
  /// **'Tareas hechas'**
  String get stTasksDone;

  /// No description provided for @stTasksFooter.
  ///
  /// In es, this message translates to:
  /// **'Por semana y quién ha hecho más este mes'**
  String get stTasksFooter;

  /// No description provided for @stTasksEmpty.
  ///
  /// In es, this message translates to:
  /// **'Cuando completéis tareas aparecerán aquí.'**
  String get stTasksEmpty;

  /// No description provided for @stSoFar.
  ///
  /// In es, this message translates to:
  /// **'Llevas este mes'**
  String get stSoFar;

  /// No description provided for @stForecast.
  ///
  /// In es, this message translates to:
  /// **'Previsión: '**
  String get stForecast;

  /// No description provided for @stMoreThanAvg.
  ///
  /// In es, this message translates to:
  /// **', un {pct} % más que tu media'**
  String stMoreThanAvg(int pct);

  /// No description provided for @stLessThanAvg.
  ///
  /// In es, this message translates to:
  /// **', un {pct} % menos que tu media'**
  String stLessThanAvg(int pct);

  /// No description provided for @stTickets.
  ///
  /// In es, this message translates to:
  /// **'Tickets'**
  String get stTickets;

  /// No description provided for @stExpired.
  ///
  /// In es, this message translates to:
  /// **'Caducado'**
  String get stExpired;

  /// No description provided for @stExpiringSoon.
  ///
  /// In es, this message translates to:
  /// **'Caduca pronto'**
  String get stExpiringSoon;

  /// No description provided for @stFresh.
  ///
  /// In es, this message translates to:
  /// **'Bien'**
  String get stFresh;

  /// No description provided for @stOverForecast.
  ///
  /// In es, this message translates to:
  /// **'A este ritmo te pasarás {amount} del presupuesto'**
  String stOverForecast(String amount);

  /// No description provided for @stForecastTip.
  ///
  /// In es, this message translates to:
  /// **'Previsión {amount}'**
  String stForecastTip(String amount);

  /// No description provided for @pwPickOption.
  ///
  /// In es, this message translates to:
  /// **'Elige una opción para continuar.'**
  String get pwPickOption;

  /// No description provided for @pwPickBirth.
  ///
  /// In es, this message translates to:
  /// **'Selecciona tu fecha de nacimiento.'**
  String get pwPickBirth;

  /// No description provided for @pwBadHeight.
  ///
  /// In es, this message translates to:
  /// **'Escribe una altura válida en centímetros.'**
  String get pwBadHeight;

  /// No description provided for @pwBadWeight.
  ///
  /// In es, this message translates to:
  /// **'Escribe un peso válido en kilos.'**
  String get pwBadWeight;

  /// No description provided for @pwCompleteStep.
  ///
  /// In es, this message translates to:
  /// **'Completa este paso para continuar.'**
  String get pwCompleteStep;

  /// No description provided for @pwStart.
  ///
  /// In es, this message translates to:
  /// **'Empezar a usar PrezHome'**
  String get pwStart;

  /// No description provided for @pwSeeGoal.
  ///
  /// In es, this message translates to:
  /// **'Ver mi objetivo'**
  String get pwSeeGoal;

  /// No description provided for @pwFinish.
  ///
  /// In es, this message translates to:
  /// **'Terminar'**
  String get pwFinish;

  /// No description provided for @pwIntroTitle.
  ///
  /// In es, this message translates to:
  /// **'Vamos a conocerte'**
  String get pwIntroTitle;

  /// No description provided for @pwIntroSub.
  ///
  /// In es, this message translates to:
  /// **'Unas preguntas rápidas para adaptar PrezHome a ti. Puedes cambiarlo cuando quieras.'**
  String get pwIntroSub;

  /// No description provided for @pwTrackKcal.
  ///
  /// In es, this message translates to:
  /// **'Quiero llevar la cuenta de calorías'**
  String get pwTrackKcal;

  /// No description provided for @pwTrackKcalSub.
  ///
  /// In es, this message translates to:
  /// **'Las comidas del plan se apuntan solas al pasar.'**
  String get pwTrackKcalSub;

  /// No description provided for @pwOnlyHome.
  ///
  /// In es, this message translates to:
  /// **'Solo organizar la casa'**
  String get pwOnlyHome;

  /// No description provided for @pwOnlyHomeSub.
  ///
  /// In es, this message translates to:
  /// **'Sin peso ni medidas.'**
  String get pwOnlyHomeSub;

  /// No description provided for @pwSex.
  ///
  /// In es, this message translates to:
  /// **'Tu sexo'**
  String get pwSex;

  /// No description provided for @pwSexSub.
  ///
  /// In es, this message translates to:
  /// **'Lo usamos para calcular tu metabolismo con más precisión.'**
  String get pwSexSub;

  /// No description provided for @pwPickDate.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar fecha'**
  String get pwPickDate;

  /// No description provided for @pwBirthTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cuándo naciste?'**
  String get pwBirthTitle;

  /// No description provided for @pwBirthSub.
  ///
  /// In es, this message translates to:
  /// **'La edad nos ayuda a afinar el cálculo de calorías.'**
  String get pwBirthSub;

  /// No description provided for @pwAgeYears.
  ///
  /// In es, this message translates to:
  /// **'{age} años'**
  String pwAgeYears(int age);

  /// No description provided for @pwHeightTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cuánto mides?'**
  String get pwHeightTitle;

  /// No description provided for @pwHeightSub.
  ///
  /// In es, this message translates to:
  /// **'Indica tu altura en centímetros.'**
  String get pwHeightSub;

  /// No description provided for @pwWeightTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cuánto pesas?'**
  String get pwWeightTitle;

  /// No description provided for @pwWeightSub.
  ///
  /// In es, this message translates to:
  /// **'Indica tu peso actual en kilos.'**
  String get pwWeightSub;

  /// No description provided for @pwActivityTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu nivel de actividad'**
  String get pwActivityTitle;

  /// No description provided for @pwActivitySub.
  ///
  /// In es, this message translates to:
  /// **'Elige la opción que mejor describa tu semana.'**
  String get pwActivitySub;

  /// No description provided for @pwGoalTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cuál es tu objetivo?'**
  String get pwGoalTitle;

  /// No description provided for @pwGoalSub.
  ///
  /// In es, this message translates to:
  /// **'Ajustaremos tus calorías según lo que quieras conseguir.'**
  String get pwGoalSub;

  /// No description provided for @pwGoalDesc.
  ///
  /// In es, this message translates to:
  /// **'{goal, select, lose{Déficit suave para bajar de peso poco a poco.} gain{Superávit suave para ganar masa de forma sana.} other{Mantener tu peso actual y sentirte bien.}}'**
  String pwGoalDesc(String goal);

  /// No description provided for @pwDietTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo te alimentas?'**
  String get pwDietTitle;

  /// No description provided for @pwDietSub.
  ///
  /// In es, this message translates to:
  /// **'Las recetas se adaptarán a tu dieta.'**
  String get pwDietSub;

  /// No description provided for @pwDiet.
  ///
  /// In es, this message translates to:
  /// **'{diet, select, vegetariana{Vegetariana} vegana{Vegana} pescetariana{Pescetariana} baja_carbo{Baja en carbohidratos} sin_gluten{Sin gluten} other{De todo}}'**
  String pwDiet(String diet);

  /// No description provided for @pwAllergiesTitle.
  ///
  /// In es, this message translates to:
  /// **'Alergias o intolerancias'**
  String get pwAllergiesTitle;

  /// No description provided for @pwOptional.
  ///
  /// In es, this message translates to:
  /// **'Opcional.'**
  String get pwOptional;

  /// No description provided for @pwAllergy.
  ///
  /// In es, this message translates to:
  /// **'{allergy, select, frutossecos{frutos secos} lactosa{lactosa} gluten{gluten (celiaquía)} huevo{huevo} marisco{marisco} soja{soja} other{pescado}}'**
  String pwAllergy(String allergy);

  /// No description provided for @pwCuisinesTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Qué te gusta comer?'**
  String get pwCuisinesTitle;

  /// No description provided for @pwCuisinesSub.
  ///
  /// In es, this message translates to:
  /// **'Elige las que quieras.'**
  String get pwCuisinesSub;

  /// No description provided for @pwCuisine.
  ///
  /// In es, this message translates to:
  /// **'{cuisine, select, casera{Casera de siempre} mediterranea{Mediterránea} ligera{Ligera} rapida{Rápida y sencilla} italiana{Italiana} asiatica{Asiática} mexicana{Mexicana} other{De todo el mundo}}'**
  String pwCuisine(String cuisine);

  /// No description provided for @pwAppliancesTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Qué tienes en la cocina?'**
  String get pwAppliancesTitle;

  /// No description provided for @pwAppliancesSub.
  ///
  /// In es, this message translates to:
  /// **'El plan solo usará recetas que puedas hacer.'**
  String get pwAppliancesSub;

  /// No description provided for @appliance.
  ///
  /// In es, this message translates to:
  /// **'{appliance, select, oven{Horno} stovetop{Sartén} pot{Olla} airfryer{Airfryer} microwave{Microondas} blender{Batidora} other{Ninguno}}'**
  String appliance(String appliance);

  /// No description provided for @pwDislikedTitle.
  ///
  /// In es, this message translates to:
  /// **'Ingredientes que no te gustan'**
  String get pwDislikedTitle;

  /// No description provided for @pwDislikedSub.
  ///
  /// In es, this message translates to:
  /// **'Separados por comas. Opcional.'**
  String get pwDislikedSub;

  /// No description provided for @pwDislikedHint.
  ///
  /// In es, this message translates to:
  /// **'cebolla, cilantro...'**
  String get pwDislikedHint;

  /// No description provided for @pwCookTimeTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cuánto tiempo quieres cocinar?'**
  String get pwCookTimeTitle;

  /// No description provided for @pwCookTimeSub.
  ///
  /// In es, this message translates to:
  /// **'Así ajusto las recetas a tu ritmo. Puedes dejarlo sin elegir.'**
  String get pwCookTimeSub;

  /// No description provided for @pwCookTime.
  ///
  /// In es, this message translates to:
  /// **'{time, select, rapido{Rápido (menos de 20 min)} elaborado{Elaborado (me gusta cocinar)} other{Normal}}'**
  String pwCookTime(String time);

  /// No description provided for @pwCookTimeDesc.
  ///
  /// In es, this message translates to:
  /// **'{time, select, rapido{Platos resueltos en poco tiempo.} elaborado{Disfruto cocinando con calma.} other{Un equilibrio entre rápido y elaborado.}}'**
  String pwCookTimeDesc(String time);

  /// No description provided for @pwCookStyleTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo prefieres cocinar?'**
  String get pwCookStyleTitle;

  /// No description provided for @pwChangeAnytime.
  ///
  /// In es, this message translates to:
  /// **'Puedes cambiarlo cuando quieras.'**
  String get pwChangeAnytime;

  /// No description provided for @cookStyle.
  ///
  /// In es, this message translates to:
  /// **'{style, select, batch{En lote} mixed{Mixto} other{Diario}}'**
  String cookStyle(String style);

  /// No description provided for @cookStyleSub.
  ///
  /// In es, this message translates to:
  /// **'{style, select, batch{Cocino en tandas para varios días} mixed{Combino tandas y cocina del día} other{Cocino cada día lo del momento}}'**
  String cookStyleSub(String style);

  /// No description provided for @pwModulesTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Qué quieres activar?'**
  String get pwModulesTitle;

  /// No description provided for @pwModulesSub.
  ///
  /// In es, this message translates to:
  /// **'Lo que apagues no se mostrará.'**
  String get pwModulesSub;

  /// No description provided for @homeModule.
  ///
  /// In es, this message translates to:
  /// **'{module, select, points{Modo Puntos} tasks{Tareas} other{Cocina en lote}}'**
  String homeModule(String module);

  /// No description provided for @homeModuleDesc.
  ///
  /// In es, this message translates to:
  /// **'{module, select, points{Gana puntos y recompensas por tus tareas.} tasks{Organiza las tareas del hogar.} other{Cocina en tandas y planifica preparaciones.}}'**
  String homeModuleDesc(String module);

  /// No description provided for @pwAllSet.
  ///
  /// In es, this message translates to:
  /// **'Todo listo'**
  String get pwAllSet;

  /// No description provided for @pwAllSetSub.
  ///
  /// In es, this message translates to:
  /// **'Recetas, plan y compra se adaptan a lo que has contado.'**
  String get pwAllSetSub;

  /// No description provided for @pwDailyGoal.
  ///
  /// In es, this message translates to:
  /// **'Tu objetivo diario'**
  String get pwDailyGoal;

  /// No description provided for @pwKcalDay.
  ///
  /// In es, this message translates to:
  /// **'kcal / día'**
  String get pwKcalDay;

  /// No description provided for @pwEstimate.
  ///
  /// In es, this message translates to:
  /// **'Es una estimación para empezar. Las comidas del plan se apuntarán solas en tu diario cuando pasen.'**
  String get pwEstimate;

  /// No description provided for @phCantAnalyze.
  ///
  /// In es, this message translates to:
  /// **'No se pudo analizar la comida'**
  String get phCantAnalyze;

  /// No description provided for @phAnalyzeError.
  ///
  /// In es, this message translates to:
  /// **'Error al analizar la foto: {error}'**
  String phAnalyzeError(String error);

  /// No description provided for @phAnalyzeFail.
  ///
  /// In es, this message translates to:
  /// **'Error al analizar la foto'**
  String get phAnalyzeFail;

  /// No description provided for @phAddOne.
  ///
  /// In es, this message translates to:
  /// **'Añade al menos un alimento con nombre.'**
  String get phAddOne;

  /// No description provided for @phTitle.
  ///
  /// In es, this message translates to:
  /// **'Registrar con foto'**
  String get phTitle;

  /// No description provided for @phLooking.
  ///
  /// In es, this message translates to:
  /// **'Mirando el plato…'**
  String get phLooking;

  /// No description provided for @phStartTitle.
  ///
  /// In es, this message translates to:
  /// **'Haz una foto a tu plato'**
  String get phStartTitle;

  /// No description provided for @phStartSub.
  ///
  /// In es, this message translates to:
  /// **'Calculamos los alimentos y sus calorías. Podrás corregirlo antes de guardar.'**
  String get phStartSub;

  /// No description provided for @takePhoto.
  ///
  /// In es, this message translates to:
  /// **'Hacer foto'**
  String get takePhoto;

  /// No description provided for @phReview.
  ///
  /// In es, this message translates to:
  /// **'Revisa y corrige lo detectado'**
  String get phReview;

  /// No description provided for @phApprox.
  ///
  /// In es, this message translates to:
  /// **'Las calorías son aproximadas.'**
  String get phApprox;

  /// No description provided for @phMealType.
  ///
  /// In es, this message translates to:
  /// **'Tipo de comida (opcional)'**
  String get phMealType;

  /// No description provided for @phNoType.
  ///
  /// In es, this message translates to:
  /// **'Sin tipo'**
  String get phNoType;

  /// No description provided for @day.
  ///
  /// In es, this message translates to:
  /// **'Día'**
  String get day;

  /// No description provided for @phNothing.
  ///
  /// In es, this message translates to:
  /// **'No se ha reconocido ningún alimento. Añádelos a mano.'**
  String get phNothing;

  /// No description provided for @phFoods.
  ///
  /// In es, this message translates to:
  /// **'ALIMENTOS ({count})'**
  String phFoods(int count);

  /// No description provided for @phAddFood.
  ///
  /// In es, this message translates to:
  /// **'Añadir alimento'**
  String get phAddFood;

  /// No description provided for @phFood.
  ///
  /// In es, this message translates to:
  /// **'Alimento'**
  String get phFood;

  /// No description provided for @phGrams.
  ///
  /// In es, this message translates to:
  /// **'g (aprox)'**
  String get phGrams;

  /// No description provided for @phP.
  ///
  /// In es, this message translates to:
  /// **'P (g)'**
  String get phP;

  /// No description provided for @phC.
  ///
  /// In es, this message translates to:
  /// **'C (g)'**
  String get phC;

  /// No description provided for @phF.
  ///
  /// In es, this message translates to:
  /// **'G (g)'**
  String get phF;

  /// No description provided for @total.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @kcalAmount.
  ///
  /// In es, this message translates to:
  /// **'{kcal} kcal'**
  String kcalAmount(int kcal);

  /// No description provided for @phSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar en el diario'**
  String get phSave;

  /// No description provided for @stkOpenError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir el ticket'**
  String get stkOpenError;

  /// No description provided for @stkReadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo leer el ticket'**
  String get stkReadError;

  /// No description provided for @stkScanError.
  ///
  /// In es, this message translates to:
  /// **'Error al escanear'**
  String get stkScanError;

  /// No description provided for @stkPantryError.
  ///
  /// In es, this message translates to:
  /// **'El ticket se guardó, pero no se pudo actualizar la despensa'**
  String get stkPantryError;

  /// No description provided for @stkCrossed.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 producto tachado de la lista} other{{count} productos tachados de la lista}}'**
  String stkCrossed(int count);

  /// No description provided for @stkEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar ticket'**
  String get stkEdit;

  /// No description provided for @stkReading.
  ///
  /// In es, this message translates to:
  /// **'Leyendo el ticket…'**
  String get stkReading;

  /// No description provided for @stkStartTitle.
  ///
  /// In es, this message translates to:
  /// **'Escanea el ticket de la compra'**
  String get stkStartTitle;

  /// No description provided for @stkStartSub.
  ///
  /// In es, this message translates to:
  /// **'Sacamos los productos y precios. Podrás revisarlo después.'**
  String get stkStartSub;

  /// No description provided for @stkReview.
  ///
  /// In es, this message translates to:
  /// **'Revisa y corrige lo que haga falta'**
  String get stkReview;

  /// No description provided for @stkRemember.
  ///
  /// In es, this message translates to:
  /// **'Tus correcciones se recordarán para la próxima vez.'**
  String get stkRemember;

  /// No description provided for @stkStore.
  ///
  /// In es, this message translates to:
  /// **'Tienda'**
  String get stkStore;

  /// No description provided for @date.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get date;

  /// No description provided for @stkAddPantry.
  ///
  /// In es, this message translates to:
  /// **'Añadir a la despensa'**
  String get stkAddPantry;

  /// No description provided for @stkAddPantrySub.
  ///
  /// In es, this message translates to:
  /// **'Cada producto va a su zona'**
  String get stkAddPantrySub;

  /// No description provided for @stkProducts.
  ///
  /// In es, this message translates to:
  /// **'PRODUCTOS ({count})'**
  String stkProducts(int count);

  /// No description provided for @stkRaw.
  ///
  /// In es, this message translates to:
  /// **'Ticket: \"{name}\"'**
  String stkRaw(String name);

  /// No description provided for @category.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get category;

  /// No description provided for @stkQty.
  ///
  /// In es, this message translates to:
  /// **'Cant.'**
  String get stkQty;

  /// No description provided for @stkSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar ticket'**
  String get stkSave;

  /// No description provided for @foodCategory.
  ///
  /// In es, this message translates to:
  /// **'{cat, select, verdura{Verduras} fruta{Frutas} carne{Carne} pescado{Pescado} lacteos{Lácteos} preparados{Platos preparados} panaderia{Panadería} cereales{Pasta, arroz y legumbres} conservas{Conservas} congelados{Congelados} dulces{Dulces y snacks} bebidas{Bebidas} especias{Especias y condimentos} higiene{Higiene} limpieza{Limpieza} hogar{Hogar} other{Otros}}'**
  String foodCategory(String cat);

  /// No description provided for @cookMode.
  ///
  /// In es, this message translates to:
  /// **'Modo cocina'**
  String get cookMode;

  /// No description provided for @bpMeanwhile.
  ///
  /// In es, this message translates to:
  /// **'Mientras tanto'**
  String get bpMeanwhile;

  /// No description provided for @bpTapers.
  ///
  /// In es, this message translates to:
  /// **'Tápers · {title}'**
  String bpTapers(String title);

  /// No description provided for @bpBatchCook.
  ///
  /// In es, this message translates to:
  /// **'Cocina en tanda'**
  String get bpBatchCook;

  /// No description provided for @bpStart.
  ///
  /// In es, this message translates to:
  /// **'Empezar paso a paso'**
  String get bpStart;

  /// No description provided for @bpEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay nada que cocinar ahora mismo'**
  String get bpEmpty;

  /// No description provided for @bpEmptySub.
  ///
  /// In es, this message translates to:
  /// **'Cuando tengas recetas planificadas, aquí te prepararé un plan de cocina para hacerlo todo de una vez.'**
  String get bpEmptySub;

  /// No description provided for @bpNeed.
  ///
  /// In es, this message translates to:
  /// **'Lo que necesitas'**
  String get bpNeed;

  /// No description provided for @bpSplit.
  ///
  /// In es, this message translates to:
  /// **'Reparte en tápers'**
  String get bpSplit;

  /// No description provided for @bpSplitSub.
  ///
  /// In es, this message translates to:
  /// **'Se apuntan solos en Mi cocina'**
  String get bpSplitSub;

  /// No description provided for @bpYourPlan.
  ///
  /// In es, this message translates to:
  /// **'Tu plan de cocina'**
  String get bpYourPlan;

  /// No description provided for @bpTotalMinutes.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Unos 1 minuto en total} other{Unos {count} minutos en total}}'**
  String bpTotalMinutes(int count);

  /// No description provided for @minutesShort.
  ///
  /// In es, this message translates to:
  /// **'{count} min'**
  String minutesShort(int count);

  /// No description provided for @bpParallel.
  ///
  /// In es, this message translates to:
  /// **'En paralelo'**
  String get bpParallel;

  /// No description provided for @bpFor.
  ///
  /// In es, this message translates to:
  /// **'Para {recipes}'**
  String bpFor(String recipes);

  /// No description provided for @ready.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get ready;

  /// No description provided for @pause.
  ///
  /// In es, this message translates to:
  /// **'Pausar'**
  String get pause;

  /// No description provided for @start.
  ///
  /// In es, this message translates to:
  /// **'Iniciar'**
  String get start;

  /// No description provided for @reset.
  ///
  /// In es, this message translates to:
  /// **'Reiniciar'**
  String get reset;

  /// No description provided for @bpDone.
  ///
  /// In es, this message translates to:
  /// **'Hecho'**
  String get bpDone;

  /// No description provided for @bpMarkDone.
  ///
  /// In es, this message translates to:
  /// **'Marcar como hecho'**
  String get bpMarkDone;

  /// No description provided for @cmStep.
  ///
  /// In es, this message translates to:
  /// **'Paso {n}'**
  String cmStep(int n);

  /// No description provided for @cmTime.
  ///
  /// In es, this message translates to:
  /// **'Tiempo'**
  String get cmTime;

  /// No description provided for @cmSeeStep.
  ///
  /// In es, this message translates to:
  /// **'Ver paso'**
  String get cmSeeStep;

  /// No description provided for @ok.
  ///
  /// In es, this message translates to:
  /// **'Vale'**
  String get ok;

  /// No description provided for @cmMicPermission.
  ///
  /// In es, this message translates to:
  /// **'Para usar la voz, permite el micrófono en Ajustes.'**
  String get cmMicPermission;

  /// No description provided for @ingredients.
  ///
  /// In es, this message translates to:
  /// **'Ingredientes'**
  String get ingredients;

  /// No description provided for @cmExit.
  ///
  /// In es, this message translates to:
  /// **'Salir del modo cocina'**
  String get cmExit;

  /// No description provided for @cmHandsFreeOff.
  ///
  /// In es, this message translates to:
  /// **'Quitar manos libres'**
  String get cmHandsFreeOff;

  /// No description provided for @cmHandsFree.
  ///
  /// In es, this message translates to:
  /// **'Manos libres'**
  String get cmHandsFree;

  /// No description provided for @cmVoiceHint.
  ///
  /// In es, this message translates to:
  /// **'Di «siguiente», «anterior», «repite» o «temporizador»'**
  String get cmVoiceHint;

  /// No description provided for @cmStop.
  ///
  /// In es, this message translates to:
  /// **'Parar'**
  String get cmStop;

  /// No description provided for @cmStepOf.
  ///
  /// In es, this message translates to:
  /// **'PASO {n} DE {total}'**
  String cmStepOf(int n, int total);

  /// No description provided for @cmTimerRunning.
  ///
  /// In es, this message translates to:
  /// **'Temporizador en marcha'**
  String get cmTimerRunning;

  /// No description provided for @cmTimerMin.
  ///
  /// In es, this message translates to:
  /// **'Temporizador {count} min'**
  String cmTimerMin(int count);

  /// No description provided for @cmThen.
  ///
  /// In es, this message translates to:
  /// **'Luego'**
  String get cmThen;

  /// No description provided for @cmNextStep.
  ///
  /// In es, this message translates to:
  /// **'Siguiente paso'**
  String get cmNextStep;

  /// No description provided for @shopSugDue.
  ///
  /// In es, this message translates to:
  /// **'Te toca'**
  String get shopSugDue;

  /// No description provided for @shopSugOut.
  ///
  /// In es, this message translates to:
  /// **'Te falta en casa'**
  String get shopSugOut;

  /// No description provided for @shopOutAtHome.
  ///
  /// In es, this message translates to:
  /// **'Agotado en casa'**
  String get shopOutAtHome;

  /// No description provided for @shopGridView.
  ///
  /// In es, this message translates to:
  /// **'Ver en cuadrícula'**
  String get shopGridView;

  /// No description provided for @shopGridHint.
  ///
  /// In es, this message translates to:
  /// **'Fotos grandes, dos por fila'**
  String get shopGridHint;

  /// No description provided for @shopShowSuggestions.
  ///
  /// In es, this message translates to:
  /// **'Mostrar sugerencias'**
  String get shopShowSuggestions;

  /// No description provided for @shopSuggestionsHint.
  ///
  /// In es, this message translates to:
  /// **'Lo que te toca reponer y lo que se acabó en casa'**
  String get shopSuggestionsHint;

  /// No description provided for @shopShowPrices.
  ///
  /// In es, this message translates to:
  /// **'Mostrar precios'**
  String get shopShowPrices;

  /// No description provided for @shopEveryDays.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{Cada día} other{Cada {n} días}}'**
  String shopEveryDays(int n);

  /// No description provided for @slNewList.
  ///
  /// In es, this message translates to:
  /// **'Nueva lista'**
  String get slNewList;

  /// No description provided for @slMyLists.
  ///
  /// In es, this message translates to:
  /// **'Mis listas'**
  String get slMyLists;

  /// No description provided for @slActive.
  ///
  /// In es, this message translates to:
  /// **'Activa'**
  String get slActive;

  /// No description provided for @slNewCat.
  ///
  /// In es, this message translates to:
  /// **'Nueva categoría'**
  String get slNewCat;

  /// No description provided for @slRenameCat.
  ///
  /// In es, this message translates to:
  /// **'Renombrar categoría'**
  String get slRenameCat;

  /// No description provided for @slCategories.
  ///
  /// In es, this message translates to:
  /// **'Categorías'**
  String get slCategories;

  /// No description provided for @slAddCat.
  ///
  /// In es, this message translates to:
  /// **'Añadir categoría'**
  String get slAddCat;

  /// No description provided for @slNoCats.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay categorías. Añade la primera con el botón de abajo.'**
  String get slNoCats;

  /// No description provided for @rename.
  ///
  /// In es, this message translates to:
  /// **'Renombrar'**
  String get rename;

  /// No description provided for @ppDayMeals.
  ///
  /// In es, this message translates to:
  /// **'{day}, {count, plural, =1{1 comida} other{{count} comidas}}'**
  String ppDayMeals(String day, int count);

  /// No description provided for @ppFastTime.
  ///
  /// In es, this message translates to:
  /// **'{time} · Ayuno'**
  String ppFastTime(String time);

  /// No description provided for @ppEatOut.
  ///
  /// In es, this message translates to:
  /// **'· Fuera'**
  String get ppEatOut;

  /// No description provided for @mealAdd.
  ///
  /// In es, this message translates to:
  /// **'{type, select, breakfast{Añadir desayuno} lunch{Añadir comida} snack{Añadir merienda} dinner{Añadir cena} dessert{Añadir postre} other{Añadir comida}}'**
  String mealAdd(String type);

  /// No description provided for @ppFromFreezer.
  ///
  /// In es, this message translates to:
  /// **'Del congelador'**
  String get ppFromFreezer;

  /// No description provided for @ppServings.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 ración} other{{count} rac.}}'**
  String ppServings(int count);

  /// No description provided for @ppFresh.
  ///
  /// In es, this message translates to:
  /// **'Recién hecho'**
  String get ppFresh;

  /// No description provided for @ppFridge.
  ///
  /// In es, this message translates to:
  /// **'Nevera · {days}'**
  String ppFridge(String days);

  /// No description provided for @ppFreezer.
  ///
  /// In es, this message translates to:
  /// **'Congelador · {days}'**
  String ppFreezer(String days);

  /// No description provided for @ppTapersAuto.
  ///
  /// In es, this message translates to:
  /// **'Los tápers se apuntan solos en Mi cocina'**
  String get ppTapersAuto;

  /// No description provided for @drGoal.
  ///
  /// In es, this message translates to:
  /// **'{goal, select, lose{Perder grasa} gain{Ganar músculo} protein{Alta proteína} other{Mantener}}'**
  String drGoal(String goal);

  /// No description provided for @drDiet.
  ///
  /// In es, this message translates to:
  /// **'{diet, select, veg{Vegetariana} vegan{Vegana} quick{Rápida} lowcarb{Baja en carbohidratos} other{Sin restricción}}'**
  String drDiet(String diet);

  /// No description provided for @drFreeOf.
  ///
  /// In es, this message translates to:
  /// **'{allergen, select, gluten{Sin gluten (celiaquía)} lactosa{Sin lactosa} huevo{Sin huevo} marisco{Sin marisco} soja{Sin soja} other{Sin frutos secos}}'**
  String drFreeOf(String allergen);

  /// No description provided for @drAnyType.
  ///
  /// In es, this message translates to:
  /// **'Cualquiera'**
  String get drAnyType;

  /// No description provided for @drNoIdeas.
  ///
  /// In es, this message translates to:
  /// **'No se recibieron ideas'**
  String get drNoIdeas;

  /// No description provided for @drSaved.
  ///
  /// In es, this message translates to:
  /// **'Guardada en tus recetas'**
  String get drSaved;

  /// No description provided for @drSearchSuper.
  ///
  /// In es, this message translates to:
  /// **'Buscar supermercado...'**
  String get drSearchSuper;

  /// No description provided for @drNoSuper.
  ///
  /// In es, this message translates to:
  /// **'No encontramos ese súper.'**
  String get drNoSuper;

  /// No description provided for @drTitlePantry.
  ///
  /// In es, this message translates to:
  /// **'¿Qué cocino con esto?'**
  String get drTitlePantry;

  /// No description provided for @drTitle.
  ///
  /// In es, this message translates to:
  /// **'Ideas personalizadas'**
  String get drTitle;

  /// No description provided for @drNewIdeas.
  ///
  /// In es, this message translates to:
  /// **'Ideas nuevas'**
  String get drNewIdeas;

  /// No description provided for @drWithPantry.
  ///
  /// In es, this message translates to:
  /// **'Con lo que tengo'**
  String get drWithPantry;

  /// No description provided for @drPantryLoading.
  ///
  /// In es, this message translates to:
  /// **'Mirando tu despensa…'**
  String get drPantryLoading;

  /// No description provided for @drPantryEmpty.
  ///
  /// In es, this message translates to:
  /// **'Tu despensa está vacía: añade lo que tienes en casa para recibir ideas con ello.'**
  String get drPantryEmpty;

  /// No description provided for @drPantryUse.
  ///
  /// In es, this message translates to:
  /// **'Usaremos {count} alimentos de tu despensa, empezando por lo que caduca antes.'**
  String drPantryUse(int count);

  /// No description provided for @drCraving.
  ///
  /// In es, this message translates to:
  /// **'¿Qué te apetece?'**
  String get drCraving;

  /// No description provided for @drSupers.
  ///
  /// In es, this message translates to:
  /// **'Supermercados'**
  String get drSupers;

  /// No description provided for @drSupersHint.
  ///
  /// In es, this message translates to:
  /// **'Opcional. Si no eliges ninguno, las recetas valen para cualquier súper.'**
  String get drSupersHint;

  /// No description provided for @drGoalTitle.
  ///
  /// In es, this message translates to:
  /// **'Objetivo'**
  String get drGoalTitle;

  /// No description provided for @drDietTitle.
  ///
  /// In es, this message translates to:
  /// **'Dieta'**
  String get drDietTitle;

  /// No description provided for @drDietLocked.
  ///
  /// In es, this message translates to:
  /// **'Usamos la dieta de tu perfil: {diet}'**
  String drDietLocked(String diet);

  /// No description provided for @drAllergyTitle.
  ///
  /// In es, this message translates to:
  /// **'Intolerancias y alergias'**
  String get drAllergyTitle;

  /// No description provided for @drAllergyHint.
  ///
  /// In es, this message translates to:
  /// **'Nunca saldrán en las recetas.'**
  String get drAllergyHint;

  /// No description provided for @drAppliances.
  ///
  /// In es, this message translates to:
  /// **'Electrodomésticos'**
  String get drAppliances;

  /// No description provided for @drMaxCost.
  ///
  /// In es, this message translates to:
  /// **'Coste máximo por ración'**
  String get drMaxCost;

  /// No description provided for @drMaxCostHint.
  ///
  /// In es, this message translates to:
  /// **'Opcional, p. ej. 2,50'**
  String get drMaxCostHint;

  /// No description provided for @drSearching.
  ///
  /// In es, this message translates to:
  /// **'Buscando ideas…'**
  String get drSearching;

  /// No description provided for @drSeeIdeas.
  ///
  /// In es, this message translates to:
  /// **'Ver ideas'**
  String get drSeeIdeas;

  /// No description provided for @drAddedToShop.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Añadido a la lista de la compra} other{Añadidos {count} productos a la compra}}'**
  String drAddedToShop(int count);

  /// No description provided for @drAddFail.
  ///
  /// In es, this message translates to:
  /// **'No se pudo añadir a la compra. Revisa la conexión e inténtalo de nuevo.'**
  String get drAddFail;

  /// No description provided for @drProteinShort.
  ///
  /// In es, this message translates to:
  /// **'P: {grams}g'**
  String drProteinShort(String grams);

  /// No description provided for @drCostTip.
  ///
  /// In es, this message translates to:
  /// **'Orientativo: precios de tus tickets o, si no, precios medios de supermercado.'**
  String get drCostTip;

  /// No description provided for @drPerServing.
  ///
  /// In es, this message translates to:
  /// **'≈ {price}/ración'**
  String drPerServing(String price);

  /// No description provided for @drHave.
  ///
  /// In es, this message translates to:
  /// **'Tienes:'**
  String get drHave;

  /// No description provided for @drMissing.
  ///
  /// In es, this message translates to:
  /// **'Te falta:'**
  String get drMissing;

  /// No description provided for @drAddedShort.
  ///
  /// In es, this message translates to:
  /// **'Añadido a la compra'**
  String get drAddedShort;

  /// No description provided for @drAddMissing.
  ///
  /// In es, this message translates to:
  /// **'Añadir lo que falta'**
  String get drAddMissing;

  /// No description provided for @drSavedShort.
  ///
  /// In es, this message translates to:
  /// **'Guardada'**
  String get drSavedShort;

  /// No description provided for @drSaveToRecipes.
  ///
  /// In es, this message translates to:
  /// **'Guardar en mis recetas'**
  String get drSaveToRecipes;

  /// No description provided for @taskKind.
  ///
  /// In es, this message translates to:
  /// **'{kind, select, bano{Baño} ropa{Ropa} compra{Compra} basura{Basura} platos{Platos} limpieza{Limpieza} plantas{Plantas} cama{Cama} mascota{Mascota} cocinar{Cocinar} pagos{Pagos} other{Tarea}}'**
  String taskKind(String kind);

  /// No description provided for @taskPreset.
  ///
  /// In es, this message translates to:
  /// **'{preset, select, dishes{Fregar los platos} vacuum{Aspirar} bathroom{Limpiar el baño} laundry{Poner lavadora} trash{Sacar la basura} shopping{Hacer la compra} plants{Regar las plantas} other{Cambiar sábanas}}'**
  String taskPreset(String preset);

  /// No description provided for @recQuick.
  ///
  /// In es, this message translates to:
  /// **'Rápidas'**
  String get recQuick;

  /// No description provided for @recLight.
  ///
  /// In es, this message translates to:
  /// **'Ligeras'**
  String get recLight;

  /// No description provided for @recFreezer.
  ///
  /// In es, this message translates to:
  /// **'Congelables'**
  String get recFreezer;

  /// No description provided for @recSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Busca por nombre o ingrediente'**
  String get recSearchHint;

  /// No description provided for @recSort.
  ///
  /// In es, this message translates to:
  /// **'Ordenar'**
  String get recSort;

  /// No description provided for @recSortRecent.
  ///
  /// In es, this message translates to:
  /// **'Más nuevas'**
  String get recSortRecent;

  /// No description provided for @recSortAz.
  ///
  /// In es, this message translates to:
  /// **'De la A a la Z'**
  String get recSortAz;

  /// No description provided for @recSortFastest.
  ///
  /// In es, this message translates to:
  /// **'Más rápidas primero'**
  String get recSortFastest;

  /// No description provided for @recSortLightest.
  ///
  /// In es, this message translates to:
  /// **'Menos calorías primero'**
  String get recSortLightest;

  /// No description provided for @recClearFilters.
  ///
  /// In es, this message translates to:
  /// **'Quitar filtros'**
  String get recClearFilters;

  /// No description provided for @recMore.
  ///
  /// In es, this message translates to:
  /// **'Más'**
  String get recMore;

  /// No description provided for @recLess.
  ///
  /// In es, this message translates to:
  /// **'Menos'**
  String get recLess;
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
