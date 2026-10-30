// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String tabLabel(String tab) {
    String _temp0 = intl.Intl.selectLogic(tab, {
      'inicio': 'Hoy',
      'comidas': 'Comida',
      'compra': 'Compra',
      'despensa': 'Despensa',
      'tareas': 'Tareas',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get country => 'País';

  @override
  String get countryHint => 'Moneda, supermercados y precios de referencia';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get back => 'Atrás';

  @override
  String get oneMoment => 'Un momento…';

  @override
  String get retry => 'Reintentar';

  @override
  String get loginAccountCreated =>
      'Cuenta creada. Te damos la bienvenida a PrezHome';

  @override
  String get loginAuthError => 'Error de autenticación';

  @override
  String loginProviderError(String provider) {
    return 'No se pudo iniciar con $provider';
  }

  @override
  String get loginResetNeedsEmail =>
      'Escribe primero tu correo y te enviaré el enlace para restablecer tu contraseña.';

  @override
  String get loginResetSent =>
      'Te he enviado un correo para restablecer tu contraseña.';

  @override
  String get loginResetError => 'No se pudo enviar el correo';

  @override
  String get loginWelcomeBack => 'Hola de nuevo';

  @override
  String get loginCreateAccount => 'Crea tu cuenta';

  @override
  String get loginTagline => 'PrezHome, tu hogar organizado';

  @override
  String loginContinueWith(String provider) {
    return 'Continuar con $provider';
  }

  @override
  String get loginOrEmail => 'o con tu correo';

  @override
  String get loginEmail => 'Correo electrónico';

  @override
  String get loginEmailInvalid => 'Introduce un correo válido';

  @override
  String get loginPassword => 'Contraseña';

  @override
  String get loginShowPassword => 'Mostrar contraseña';

  @override
  String get loginHidePassword => 'Ocultar contraseña';

  @override
  String get loginPasswordShort => 'Mínimo 6 caracteres';

  @override
  String get loginForgot => '¿Has olvidado tu contraseña?';

  @override
  String get loginSignIn => 'Entrar';

  @override
  String get loginSignUp => 'Registrarme';

  @override
  String get loginNoAccount => '¿No tienes cuenta? Regístrate';

  @override
  String get loginHaveAccount => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get homeCodeFormat =>
      'El código tiene 8 letras y números (por ejemplo ABCD-EFGH).';

  @override
  String get homeSetupError => 'No se pudo configurar el hogar';

  @override
  String get homeLastStep => 'Último paso: tu hogar';

  @override
  String get homeCreateHint =>
      'Créalo ahora y, cuando quieras, invita a quien viva contigo desde Inicio.';

  @override
  String get homeCreate => 'Crear mi hogar';

  @override
  String get homeInvited => 'Me han invitado a un hogar';

  @override
  String get homeInviteCode => 'Código de invitación';

  @override
  String get homeJoin => 'Unirme a un hogar';

  @override
  String get sessionLoadError => 'No se pudo cargar tu perfil.';

  @override
  String get onbSectionHome => 'Tu hogar';

  @override
  String get onbPeopleTitle => '¿Cuántas personas vivís?';

  @override
  String get onbPeopleHint =>
      'Para calcular raciones, la compra y el reparto de tareas.';

  @override
  String get onbSectionGoals => 'Lo que te ocupa';

  @override
  String get onbGoalsTitle => '¿Qué quieres quitarte de la cabeza?';

  @override
  String get onbGoalsHint =>
      'Elige todo lo que quieras. Lo demás quedará escondido.';

  @override
  String get onbPickOne => 'Elige al menos una';

  @override
  String onbContinueCount(int count) {
    return 'Continuar ($count)';
  }

  @override
  String get onbSectionKitchen => 'En la cocina';

  @override
  String get onbCookingTitle => '¿Cómo cocináis?';

  @override
  String get onbCookingHint => 'Así sabemos si organizar tandas y congelador.';

  @override
  String get onbSectionShopping => 'La compra';

  @override
  String get onbShopTitle => '¿Dónde compras?';

  @override
  String get onbShopHint =>
      'El primero será tu súper principal: las recetas usarán productos fáciles de encontrar allí.';

  @override
  String get onbSkipSeeHome => 'Saltar y ver mi hogar';

  @override
  String get onbSeeHome => 'Ver mi hogar';

  @override
  String get onbSlogan => 'La casa en orden, la cabeza tranquila.';

  @override
  String get onbStart => 'Comenzar';

  @override
  String get onbHaveAccount => 'Ya tengo cuenta';

  @override
  String get onbOneLess => 'Una menos';

  @override
  String get onbOneMore => 'Una más';

  @override
  String onbPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas',
      one: 'Solo yo',
    );
    return '$_temp0';
  }

  @override
  String get onbProfileBadge => 'Tu perfil de hogar';

  @override
  String onbProfileName(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'solo': 'En Solitario',
      'duo': 'El Dúo',
      'tribu': 'La Tribu',
      'other': 'La Familia',
    });
    return '$_temp0';
  }

  @override
  String onbProfileDescription(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'solo':
          'Toda la casa depende de ti. PrezHome se acuerda de lo que hay, lo que caduca y lo que toca, para que tú no tengas que hacerlo.',
      'duo':
          'Dos personas y una casa. PrezHome reparte la carga a la vista, para que nadie lleve la cuenta de todo en la cabeza.',
      'other':
          'Muchas bocas y muchas cosas a la vez. PrezHome planifica comidas, compra y tareas para todos, y avisa a cada uno de lo suyo.',
    });
    return '$_temp0';
  }

  @override
  String get onbLoadToday => 'Carga mental hoy';

  @override
  String get onbLoadWithApp => 'Con PrezHome';

  @override
  String onbLoad(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'high': 'pesada',
      'medium': 'media',
      'other': 'ligera',
    });
    return '$_temp0';
  }

  @override
  String get onbCreateAccount => 'Crear mi cuenta';

  @override
  String onbFeature(String f) {
    String _temp0 = intl.Intl.selectLogic(f, {
      'compra': 'Lista de la compra',
      'comidas': 'Qué comemos',
      'despensa': 'Despensa y caducidades',
      'tareas': 'Tareas del hogar',
      'other': 'Gasto de la casa',
    });
    return '$_temp0';
  }

  @override
  String goalLabel(String g) {
    String _temp0 = intl.Intl.selectLogic(g, {
      'comidas': 'Qué comemos',
      'compra': 'La compra',
      'despensa': 'Lo que hay en casa',
      'tareas': 'Tareas del hogar',
      'lote': 'Cocinar en lote',
      'other': 'El gasto de la casa',
    });
    return '$_temp0';
  }

  @override
  String goalHint(String g) {
    String _temp0 = intl.Intl.selectLogic(g, {
      'comidas': 'Plan de comidas y recetas',
      'compra': 'Lista que se escribe sola',
      'despensa': 'Despensa, nevera y caducidades',
      'tareas': 'Reparto justo y recordatorios',
      'lote': 'Táperes y congelador organizados',
      'other': 'Presupuesto y tickets',
    });
    return '$_temp0';
  }

  @override
  String cookingLabel(String c) {
    String _temp0 = intl.Intl.selectLogic(c, {
      'diario': 'Cada día',
      'lote': 'En lote',
      'mixto': 'Un poco de todo',
      'other': 'Casi nunca',
    });
    return '$_temp0';
  }

  @override
  String cookingHint(String c) {
    String _temp0 = intl.Intl.selectLogic(c, {
      'diario': 'Cocino lo del momento',
      'lote': 'Preparo varios días de una vez',
      'mixto': 'Algunos días en lote',
      'other': 'Como fuera o algo rápido',
    });
    return '$_temp0';
  }

  @override
  String homeGreeting(String part) {
    String _temp0 = intl.Intl.selectLogic(part, {
      'morning': 'Buenos días',
      'afternoon': 'Buenas tardes',
      'other': 'Buenas noches',
    });
    return '$_temp0';
  }

  @override
  String get homeCustomize => 'Personalizar Inicio';

  @override
  String get homeYourData => 'Tus datos';

  @override
  String get homeYourHome => 'Tu hogar';

  @override
  String homeTodayTag(String meal) {
    return 'Hoy · $meal';
  }

  @override
  String mealType(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'breakfast': 'Desayuno',
      'lunch': 'Comida',
      'snack': 'Merienda',
      'dinner': 'Cena',
      'dessert': 'Postre',
      'drink': 'Bebida',
      'other': 'Comida',
    });
    return '$_temp0';
  }

  @override
  String get homeEatingOut => 'Fuera de casa';

  @override
  String get homeWhatToEat => '¿Qué comemos hoy?';

  @override
  String get homeNothingPlanned => 'Aún no hay nada planificado para hoy.';

  @override
  String get homePlan => 'Planificar';

  @override
  String get homeWithWhatIHave => 'Con lo que tengo';

  @override
  String get homeExpiring => 'Por caducar';

  @override
  String homeTasksToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tareas hoy',
      one: 'Tarea hoy',
    );
    return '$_temp0';
  }

  @override
  String get homeInShopping => 'En la compra';

  @override
  String get homeShortcuts => 'Atajos';

  @override
  String get homeForToday => 'Para hoy';

  @override
  String get homeSeeAll => 'Ver todo';

  @override
  String homePoints(int points) {
    return '$points pts';
  }

  @override
  String homePointsSnack(int points) {
    return '+$points puntos';
  }

  @override
  String get homeToday => 'Hoy';

  @override
  String get homeTomorrow => 'Mañana';

  @override
  String get homeCaloriesTitle => 'Calcula tu objetivo de calorías';

  @override
  String get homeCaloriesHint =>
      'Responde unas preguntas rápidas y adaptaré PrezHome a ti.';

  @override
  String homeOf(String total) {
    return 'de $total';
  }

  @override
  String get homeCaloriesToday => 'Calorías de hoy';

  @override
  String homeKcal(int kcal) {
    return '$kcal kcal';
  }

  @override
  String homeKcalLeft(int kcal) {
    return 'Te quedan $kcal kcal';
  }

  @override
  String homeKcalOver(int kcal) {
    return 'Te has pasado $kcal kcal';
  }

  @override
  String get homeMonthSpend => 'Gasto del mes';

  @override
  String homeMoneyLeft(String amount) {
    return 'Te quedan $amount';
  }

  @override
  String homeMoneyOver(String amount) {
    return 'Te has pasado $amount del presupuesto';
  }

  @override
  String get save => 'Guardar';

  @override
  String get homeCardsSection => 'Tarjetas (arrastra para ordenar)';

  @override
  String get homeQuickSection => 'Accesos rápidos';

  @override
  String get homeQuickHint => 'Elige los atajos que verás arriba del Inicio.';

  @override
  String dashCard(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'meals': 'Comidas de hoy',
      'calories': 'Calorías de hoy',
      'tasks': 'Tareas',
      'other': 'Gasto del mes',
    });
    return '$_temp0';
  }

  @override
  String quickAction(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'add_inventory': 'Añadir a despensa',
      'scan_ticket': 'Escanear ticket',
      'shopping': 'Lista de la compra',
      'add_recipe': 'Nueva receta',
      'meal_plan': 'Plan semanal',
      'other': 'Diario de calorías',
    });
    return '$_temp0';
  }

  @override
  String get shopPickStore => 'Elegir supermercado';

  @override
  String get shopAddFromPlan => 'Añadir lo del plan de la semana';

  @override
  String get shopListOptions => 'Opciones de la lista';

  @override
  String get shopAllInCart => 'Todo en el carro';

  @override
  String shopPending(int pending, int done) {
    return '$pending por comprar · $done en el carro';
  }

  @override
  String shopUnpriced(int count) {
    return ' · $count sin precio';
  }

  @override
  String get shopAddProduct => 'Añadir producto';

  @override
  String get shopSearchStore => 'Buscar en el súper';

  @override
  String get moreOptions => 'Más opciones';

  @override
  String get less => 'Menos';

  @override
  String get more => 'Más';

  @override
  String shopAdded(String name) {
    return '$name, añadido';
  }

  @override
  String shopAdd(String name) {
    return 'Añadir $name';
  }

  @override
  String get shopLiveOffline =>
      'Sin conexión en vivo ahora mismo; se actualizará al recargar.';

  @override
  String get couldNotUpdate => 'No se pudo actualizar';

  @override
  String shopSavedToPantry(int count) {
    return '$count productos guardados en la despensa';
  }

  @override
  String get shopRemoveFromList => 'Quitar de la lista';

  @override
  String shopRemovedOne(String name) {
    return 'Quitado \"$name\"';
  }

  @override
  String get couldNotChangePhoto => 'No se pudo cambiar la foto';

  @override
  String get shopAddToList => 'Añadir a la lista';

  @override
  String get shopTypeFood => 'Comida';

  @override
  String get shopTypeHome => 'Hogar/Limpieza';

  @override
  String get name => 'Nombre';

  @override
  String get product => 'Producto';

  @override
  String get quantity => 'Cantidad';

  @override
  String get unit => 'Unidad';

  @override
  String get cancel => 'Cancelar';

  @override
  String get add => 'Añadir';

  @override
  String get nameEmpty => 'El nombre no puede estar vacío.';

  @override
  String get couldNotAdd => 'No se pudo añadir';

  @override
  String get shopPlanAllAtHome => 'Ya tienes en casa todo lo del plan';

  @override
  String shopAddedFromPlan(int count) {
    return 'Añadidos $count productos del plan';
  }

  @override
  String get shopListTitle => 'Lista de la compra';

  @override
  String get shopMainList => 'Lista principal';

  @override
  String get couldNotCreateList => 'No se pudo crear la lista';

  @override
  String get shopRecipesUseStore =>
      'Las recetas usarán productos de este súper.';

  @override
  String get shopStoreSaveError =>
      'No se pudo guardar el supermercado. Inténtalo de nuevo.';

  @override
  String get shopGroupByAisle => 'Agrupar por pasillo';

  @override
  String get shopGroupHint => 'Verduras, carne, limpieza…';

  @override
  String get shopShowPhotos => 'Mostrar fotos de los productos';

  @override
  String get shopShowIcons => 'Mostrar dibujos cuando no hay foto';

  @override
  String get shopMyLists => 'Mis listas';

  @override
  String get categories => 'Categorías';

  @override
  String get shopFinish => 'Terminar compra';

  @override
  String shopFinishCount(int count) {
    return 'Terminar compra ($count)';
  }

  @override
  String get shopScanTicket => 'Escanear ticket';

  @override
  String get shopAllBought => 'Todo comprado';

  @override
  String get shopToBuy => 'Por comprar';

  @override
  String get shopUsual => 'Lo habitual';

  @override
  String get shopInCart => 'En el carrito';

  @override
  String shopRemovedMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Quitados $count productos',
      one: 'Quitado 1 producto',
    );
    return '$_temp0';
  }

  @override
  String get couldNotRemove => 'No se pudo quitar';

  @override
  String get undo => 'Deshacer';

  @override
  String get couldNotUndo => 'No se pudo deshacer';

  @override
  String get shopToCart => 'Al carrito';

  @override
  String get shopFromPlan => 'Del plan de la semana';

  @override
  String get changePhoto => 'Cambiar foto';

  @override
  String get shopEmptyTitle => 'Tu lista está vacía';

  @override
  String get shopEmptyHint =>
      'Escribe arriba lo que necesitas o trae lo del plan.';

  @override
  String get shopFromPlanAction => 'Desde el plan';

  @override
  String get shopDoneTitle => 'Compra completada';

  @override
  String get shopDoneHint => 'Ya tienes todo lo de la lista. ¡Buen trabajo!';

  @override
  String panUsedInOne(String meal) {
    return 'Quitado lo que usaste en $meal';
  }

  @override
  String panUsedInMany(int count) {
    return 'Quitado lo que usaste en $count comidas del plan';
  }

  @override
  String get view => 'Ver';

  @override
  String get couldNotDelete => 'No se pudo eliminar';

  @override
  String panNoLongerShop(String name) {
    return '$name ya no aparecerá en la compra.';
  }

  @override
  String panBackToShop(String name) {
    return '$name volverá a aparecer en la compra.';
  }

  @override
  String panCouldNotMarkOut(String name) {
    return 'No se pudo marcar $name como agotado';
  }

  @override
  String panMarkedOut(String name) {
    return 'He marcado $name como agotado.';
  }

  @override
  String panOutNotAdded(String name) {
    return '$name quedó agotado, pero no pude añadirlo a la compra';
  }

  @override
  String panAlreadyInList(String name) {
    return '$name ya está en tu lista de la compra.';
  }

  @override
  String panAddedToShop(String name) {
    return 'He añadido $name a la compra';
  }

  @override
  String get panAddManual => 'Añadir a mano';

  @override
  String get panScanBarcode => 'Escanear código de barras';

  @override
  String get panFreezeDish => 'Plato cocinado al congelador';

  @override
  String get panFreezeDishHint => 'Elige la receta y cuántas raciones';

  @override
  String get panSaveRecipeFirst => 'Primero guarda alguna receta.';

  @override
  String get panWhichDish => '¿Qué plato vas a congelar?';

  @override
  String get panHowManyServings => '¿Cuántas raciones congelas?';

  @override
  String get panTitle => 'Despensa y Nevera';

  @override
  String get panAddTooltip => 'Añadir a la despensa';

  @override
  String get panLoadError => 'No se pudo cargar el inventario';

  @override
  String get panEmptyTitle => 'Tu despensa está vacía';

  @override
  String get panEmptyHint =>
      'Añade lo que tienes en casa o tacha la compra y llegará solo.';

  @override
  String get panAddProduct => 'Añadir producto';

  @override
  String get panWhatToCook => '¿Qué cocino con esto?';

  @override
  String get panExpiringHeader => 'Caducados y a punto de caducar';

  @override
  String get panNothingHere => 'Aquí no hay nada.';

  @override
  String kitchenZone(String zone) {
    String _temp0 = intl.Intl.selectLogic(zone, {
      'nevera': 'Nevera',
      'congelador': 'Congelador',
      'despensa': 'Despensa',
      'bebidas': 'Bebidas',
      'especias': 'Condimentos',
      'limpieza': 'Limpieza',
      'hogar': 'Higiene y hogar',
      'other': '$zone',
    });
    return '$_temp0';
  }

  @override
  String get kitchenReview => 'Revisar';

  @override
  String expiryGroup(String group) {
    String _temp0 = intl.Intl.selectLogic(group, {
      'expired': 'Caducado',
      'week': 'Esta semana',
      'later': 'Más adelante',
      'other': 'Sin fecha',
    });
    return '$_temp0';
  }

  @override
  String panExpiredAgo(int days) {
    return 'Caducó hace $days días';
  }

  @override
  String get panExpiredYesterday => 'Caducó ayer';

  @override
  String get panExpiresToday => 'Caduca hoy';

  @override
  String get panExpiresTomorrow => 'Caduca mañana';

  @override
  String panExpiresIn(int days) {
    return 'Caduca en $days días';
  }

  @override
  String panDays(int days) {
    return '$days días';
  }

  @override
  String get panNotBought => 'No se compra';

  @override
  String get panConsumed => 'Consumido';

  @override
  String get panToShopping => 'A la compra';

  @override
  String panCouldNotAddToShop(String name) {
    return 'No pude añadir $name a la compra';
  }

  @override
  String panExpiredDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count caducados eliminados',
      one: 'Caducado eliminado',
    );
    return '$_temp0';
  }

  @override
  String get panMyKitchen => 'Mi cocina';

  @override
  String get panUsedHistory => 'Lo que se ha gastado';

  @override
  String get panNothingExpired => 'Nada caducado';

  @override
  String panDeleteExpired(int count) {
    return 'Eliminar caducados ($count)';
  }

  @override
  String panEmptyZone(String where) {
    return 'Vaciar $where';
  }

  @override
  String panEmptyAsk(String where) {
    return '¿Vaciar $where?';
  }

  @override
  String panWillDelete(int count) {
    return 'Se eliminarán $count productos.';
  }

  @override
  String get panEmpty => 'Vaciar';

  @override
  String panDeleted(int count) {
    return '$count productos eliminados';
  }

  @override
  String get edit => 'Editar';

  @override
  String get panShopAgain => 'Volver a añadir a la compra';

  @override
  String get panDontShop => 'No añadir a la compra';

  @override
  String get panStapleHint => 'Para básicos que siempre tienes';

  @override
  String get panWillAddToShop => 'Lo añadiré a la compra';

  @override
  String get delete => 'Eliminar';

  @override
  String panDeleteAsk(String name) {
    return '¿Eliminar $name?';
  }

  @override
  String panConsumedOn(String name, String day) {
    return '$name, consumido $day';
  }

  @override
  String get todayLower => 'hoy';

  @override
  String get yesterdayLower => 'ayer';

  @override
  String panOnDate(int day, int month) {
    return 'el $day/$month';
  }

  @override
  String get panWhen => '¿Cuándo?';

  @override
  String get today => 'Hoy';

  @override
  String get yesterday => 'Ayer';

  @override
  String get panOtherDay => 'Otro día';

  @override
  String get panWhichDay => '¿Qué día?';

  @override
  String get panHowMany => '¿Cuántos?';

  @override
  String panAll(String qty) {
    return 'Todo ($qty)';
  }

  @override
  String get couldNotLoad => 'No se pudo cargar';

  @override
  String get panNothingYet => 'Aún no hay nada.';

  @override
  String get panWhenCooking => 'Al cocinar';

  @override
  String get planHowLong => '¿Para cuánto tiempo?';

  @override
  String get thisWeek => 'Esta semana';

  @override
  String planWeeks(int count) {
    return '$count semanas';
  }

  @override
  String get planMonth4 => 'Un mes (4 semanas)';

  @override
  String get planPickDates => 'Elegir fechas';

  @override
  String get planDates => 'Fechas del plan';

  @override
  String get planMaxTwoMonths => 'Como mucho dos meses de una vez.';

  @override
  String get planReadyAllHome =>
      'Plan listo. Ya tienes en casa todo lo que necesitas';

  @override
  String planListReady(int count) {
    return 'Plan listo. Lista de la compra con $count productos';
  }

  @override
  String get planBackInPlan => 'Vuelve a estar en el plan';

  @override
  String planEntryTitle(String meal, String recipe) {
    return '$meal · $recipe';
  }

  @override
  String get planNoRecipe => 'Sin receta';

  @override
  String get planChangeRecipe => 'Cambiar receta';

  @override
  String get planWhoEats => 'Quién come';

  @override
  String get planMarkHome => 'Marcar en casa';

  @override
  String get planMarkOut => 'Marcar como fuera';

  @override
  String get planStopRepeat => 'Dejar de repetir';

  @override
  String get planStopRepeatHint => 'Quita las siguientes veces';

  @override
  String get planRepeat => 'Repetir';

  @override
  String get planRepeatHint => 'Cada día, cada semana… o para siempre';

  @override
  String get planRemove => 'Quitar del plan';

  @override
  String planRepeatTitle(String meal) {
    return 'Repetir $meal';
  }

  @override
  String get planHowOften => '¿Cada cuánto?';

  @override
  String planEveryDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Cada $days días',
      one: 'Cada día',
    );
    return '$_temp0';
  }

  @override
  String planEveryWeeks(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: 'Cada $weeks semanas',
      one: 'Cada semana',
    );
    return '$_temp0';
  }

  @override
  String get planUntilWhen => '¿Hasta cuándo?';

  @override
  String get planForever => 'Para siempre';

  @override
  String planMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count meses',
      one: '1 mes',
    );
    return '$_temp0';
  }

  @override
  String get planRepeatDone =>
      'Hecho. Lo verás en el plan las próximas semanas; si un día ya tiene otra cosa, se respeta.';

  @override
  String get planWhoAtHome => '¿Quién come en casa?';

  @override
  String get planCalendarPermission =>
      'Da permiso al calendario en los ajustes del móvil';

  @override
  String get planInFast => 'Cae en el ayuno';

  @override
  String get planSettings => 'Ajustes del plan';

  @override
  String get planBatchCook => 'Cocino en tanda';

  @override
  String get planBatchCookHint => 'Día de compra, de cocina y tápers';

  @override
  String get planTimes => 'Horas';

  @override
  String get planFasting => 'Ayuno intermitente';

  @override
  String get no => 'No';

  @override
  String planEatWindow(String from, String to) {
    return 'Comes de $from a $to. Se mueve con la hora de la cena.';
  }

  @override
  String get planCalendar => 'Calendario';

  @override
  String get planToCalendar => 'Pasar al calendario';

  @override
  String get planCalendarLinked => 'Calendario conectado';

  @override
  String get planCalendarHint =>
      'Comidas y tareas con hora, en Google Calendar';

  @override
  String get planCalendarUpdates => 'Se actualiza al abrir el plan';

  @override
  String get remove => 'Quitar';

  @override
  String get planPickRecipe => 'Elige una receta';

  @override
  String get planDayFull => 'Ese día ya tiene todas las comidas.';

  @override
  String get planWhichMeal => '¿Qué comida añades?';

  @override
  String get planTitle => 'Plan semanal';

  @override
  String get planNoHome => 'No perteneces a ningún hogar.';

  @override
  String get planMake => 'Hacer plan';

  @override
  String get planRemake => 'Rehacer plan';

  @override
  String get planNeedRecipes => 'Añade algunas recetas primero';

  @override
  String get planNeedRecipesHint =>
      'El planificador reparte tus recetas por la semana. Guarda unas cuantas en la pestaña Comidas.';

  @override
  String get planPrevWeek => 'Semana anterior';

  @override
  String get planNextWeekLabel => 'La próxima semana';

  @override
  String get planLastWeek => 'La semana pasada';

  @override
  String get planWeek => 'Semana';

  @override
  String get planBackToToday => 'Volver a hoy';

  @override
  String get planNextWeek => 'Semana siguiente';

  @override
  String get planDay => 'Día';

  @override
  String get planMonthCalendar => 'Calendario del mes';

  @override
  String get planNoPlanYet => 'Aún no hay plan para esta semana.';

  @override
  String get recipe => 'Receta';

  @override
  String get planCookMode => 'Modo cocina';

  @override
  String get planCookWeek => 'Cocina la semana de una vez';

  @override
  String get planBatch => 'Cocina en lote';

  @override
  String planCookDays(int days, int recipes) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días de cocina',
      one: '1 día de cocina',
    );
    String _temp1 = intl.Intl.pluralLogic(
      recipes,
      locale: localeName,
      other: '$recipes recetas',
      one: '1 receta',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get planBatchEmpty =>
      'Con el plan hecho te digo cuándo comprar, cuándo cocinar y qué va a la nevera o al congelador.';

  @override
  String get planCookedToFreezer => 'Ya cocinado · al congelador';

  @override
  String planFrozen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count platos guardados en el congelador.',
      one: 'Guardado en el congelador con su foto.',
    );
    return '$_temp0';
  }

  @override
  String get planEnergyLow => 'Poco';

  @override
  String get planEnergyNormal => 'Normal';

  @override
  String get planEnergyHigh => 'Mucho';

  @override
  String get planEnergyHint => 'Con \"poco\" el plan tira más del congelador.';

  @override
  String get planHowMuchCook => 'Cuánto cocinar';

  @override
  String planServings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count raciones',
      one: '1 ración',
    );
    return '$_temp0';
  }

  @override
  String get close => 'Cerrar';

  @override
  String get planSearchRecipe => 'Buscar receta...';

  @override
  String get planNoMatch => 'Sin recetas que coincidan.';

  @override
  String get diaDeleteError => 'No se pudo borrar la comida.';

  @override
  String get diaManual => 'A mano';

  @override
  String get diaManualHint => 'Escribe el nombre y las calorías';

  @override
  String get diaFromRecipe => 'Desde una receta';

  @override
  String get diaFromRecipeHint => 'Registra una receta tuya como comida';

  @override
  String get diaWithPhoto => 'Con una foto';

  @override
  String get diaWithPhotoHint =>
      'Haz una foto al plato y calculamos las calorías';

  @override
  String get diaAddManual => 'Añadir a mano';

  @override
  String get diaKcalField => 'Calorías (kcal)';

  @override
  String get diaMealTypeOptional => 'Tipo de comida (opcional)';

  @override
  String get diaNoType => 'Sin tipo';

  @override
  String get diaProteinG => 'Proteína (g)';

  @override
  String get diaCarbsG => 'Carbos (g)';

  @override
  String get diaFatG => 'Grasa (g)';

  @override
  String get diaNeedNameKcal => 'Pon al menos un nombre y las calorías.';

  @override
  String get diaSaveError => 'No se pudo guardar la comida.';

  @override
  String get diaRecipesLoadError => 'No se pudieron cargar las recetas.';

  @override
  String get diaNoRecipes => 'Aún no tienes recetas que registrar.';

  @override
  String diaKcalPerServing(int kcal) {
    return '$kcal kcal por ración';
  }

  @override
  String get diaNoKcal => 'Sin calorías registradas';

  @override
  String get diaServings => 'Raciones';

  @override
  String get diaServingsError => 'Pon un número de raciones mayor que 0.';

  @override
  String get diaLog => 'Registrar';

  @override
  String get diaRecipeLogError => 'No se pudo registrar la receta.';

  @override
  String get diaTitle => 'Mi diario';

  @override
  String get diaAddMeal => 'Añadir comida';

  @override
  String get previous => 'Anterior';

  @override
  String get next => 'Siguiente';

  @override
  String get diaDayCalories => 'Calorías del día';

  @override
  String diaOfTarget(int kcal) {
    return 'de $kcal kcal';
  }

  @override
  String get diaNoTarget =>
      'Completa tu perfil para fijar un objetivo diario de calorías y ver cuánto te queda cada día.';

  @override
  String get diaCompleteProfile => 'Completar mi perfil';

  @override
  String get diaOthers => 'Otras';

  @override
  String get diaMeal => 'Comida';

  @override
  String get diaLast7 => 'Tus últimos 7 días';

  @override
  String diaTargetPerDay(int kcal) {
    return 'Objetivo: $kcal kcal al día';
  }

  @override
  String get diaTarget => 'Objetivo';

  @override
  String get diaTodaySplit => 'Reparto de hoy';

  @override
  String get diaNoMacros => 'Aún no hay macros registrados hoy.';

  @override
  String get diaProtein => 'Proteína';

  @override
  String get diaCarbs => 'Carbos';

  @override
  String get diaFat => 'Grasa';

  @override
  String get diaAteThePlan => '¿Has comido lo del plan?';

  @override
  String diaAskLine(String day, String meal, String name, int kcal) {
    return '$day, $meal: $name · $kcal kcal';
  }

  @override
  String get yes => 'Sí';

  @override
  String get diaAnswerError => 'No se pudo guardar la respuesta.';

  @override
  String get diaAskFirst => 'Preguntarme antes de apuntar el plan';

  @override
  String get diaAskOn => 'Te preguntamos si has comido cada comida del plan.';

  @override
  String get diaAskOff =>
      'Las comidas del plan se apuntan solas al pasar su hora.';

  @override
  String get diaSettingError => 'No se pudo guardar el ajuste.';

  @override
  String get diaEmpty =>
      'Aún no has apuntado nada este día.\nAñade tu primera comida.';

  @override
  String get recUnfavorite => 'Quitar de favoritas';

  @override
  String get recFavorite => 'Marcar como favorita';

  @override
  String get recDelete => 'Eliminar receta';

  @override
  String get recDeleteAsk => '¿Eliminar receta?';

  @override
  String recRemoveAsk(String name) {
    return 'Se borrará \"$name\" y sus ingredientes.';
  }

  @override
  String recDeleted(String name) {
    return '\"$name\" eliminada.';
  }

  @override
  String get recTitle => 'Recetas';

  @override
  String get recNew => 'Nueva receta';

  @override
  String get recLoadError => 'No he podido cargar las recetas';

  @override
  String get recEmptyTitle => 'Aún no hay recetas';

  @override
  String get recEmptyHint => 'Crea la primera o pide ideas con lo que tienes.';

  @override
  String get recIdeas => 'Ideas con lo que tengo';

  @override
  String get recNoResults => 'Sin resultados';

  @override
  String recCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recetas',
      one: '1 receta',
    );
    return '$_temp0';
  }

  @override
  String get recWhatToCook => '¿Qué cocino con lo que tengo?';

  @override
  String get recPantryIdeas => 'Ideas con lo que hay en tu despensa';

  @override
  String get recAll => 'Todas';

  @override
  String get recFavorites => 'Favoritas';

  @override
  String get recNoFilter =>
      'No hay recetas con este filtro.\nPrueba con otra categoría.';

  @override
  String get clear => 'Limpiar';

  @override
  String recNoMatch(String query) {
    return 'No hay recetas que coincidan con\n\"$query\".';
  }
}
