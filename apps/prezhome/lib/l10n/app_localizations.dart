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
  /// **'{type, select, breakfast{Desayuno} lunch{Comida} snack{Merienda} dinner{Cena} dessert{Postre} other{Comida}}'**
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
  /// **'Las recetas usarán productos de este súper.'**
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
