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
