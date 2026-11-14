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
  String get loginConfirmEmailSent =>
      'Te hemos enviado un correo para confirmar tu cuenta. Ábrelo desde este móvil y entrarás solo.';

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
      'El primero será tu súper principal: buscaremos ahí los productos de tu lista de la compra.';

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
  String get homeYourDay => 'Tu día';

  @override
  String get homeNextUp => 'Lo siguiente';

  @override
  String get homeNextDone => 'Hecho';

  @override
  String get homeNextLater => 'Más tarde';

  @override
  String get homeNextOpen => 'Ver';

  @override
  String homeDefrost(String names) {
    return 'Saca del congelador: $names';
  }

  @override
  String homeExpiringLine(String names) {
    return 'Caduca pronto: $names';
  }

  @override
  String homeExpiredLine(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count productos caducados: revísalos',
      one: '1 producto caducado: revísalo',
    );
    return '$_temp0';
  }

  @override
  String homeMoreTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'y $count tareas más',
      one: 'y 1 tarea más',
    );
    return '$_temp0';
  }

  @override
  String homeShoppingLine(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count productos en la lista de la compra',
      one: '1 producto en la lista de la compra',
    );
    return '$_temp0';
  }

  @override
  String get homeAllDone => 'La casa está al día';

  @override
  String get homeAllDoneSub => 'No queda nada pendiente para hoy.';

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
  String get shopStoreModeOn => 'Estoy en la tienda';

  @override
  String get shopStoreModeOff => 'Salir del modo tienda';

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
  String get shopAddDetailed => 'Añadir con detalles';

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
      'Los productos de tu lista se buscarán en este súper. Las recetas sirven para cualquiera.';

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
  String get shopCountIn => 'Contar en';

  @override
  String get shopCountPack => 'Envases del súper';

  @override
  String get shopCountPiece => 'Piezas';

  @override
  String get shopCountWeight => 'Peso o volumen';

  @override
  String get shopPackNotFound =>
      'No encuentro el envase de este producto en tu súper';

  @override
  String shopPackNeed(String need) {
    return 'para $need';
  }

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
  String panReviewTitle(int position, int total) {
    return 'Repaso rápido · $position de $total';
  }

  @override
  String panReviewAsk(String name) {
    return '¿Sigue bien: $name?';
  }

  @override
  String panReviewExpiredAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días',
      one: '1 día',
    );
    return 'Caducó hace $_temp0';
  }

  @override
  String get panReviewOk => 'Sigue bien';

  @override
  String get panReviewUsed => 'Se acabó';

  @override
  String get panReviewThrown => 'A la basura';

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
      'hogar': 'Varios',
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
  String planCostEstimate(String amount) {
    return 'Este plan te costará unos $amount en ingredientes.';
  }

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
  String get planAddDish => 'Añadir otro plato';

  @override
  String get planAutoDessert => 'Postre automático';

  @override
  String get planAutoDessertHint => 'El plan pone un postre en estas comidas';

  @override
  String get planBoughtReady => 'Comprado hecho';

  @override
  String get planBoughtReadyHint => 'Un preparado del súper, sin cocinar';

  @override
  String get planYourReady => 'Tus preparados';

  @override
  String get planReadySearch => 'Buscar en el súper';

  @override
  String get planReadyEmpty =>
      'Aún no tienes preparados de confianza. Búscalos en el catálogo del súper.';

  @override
  String get planReadyMain => 'Plato';

  @override
  String get planReadyDessert => 'Postre';

  @override
  String get planReadyKcal => 'Calorías por ración (opcional)';

  @override
  String get planReadyRemove => 'Quitar de tus preparados';

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
      'Comidas y tareas con hora, en el calendario del móvil (Google, Outlook…)';

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
  String get planEnergyHint =>
      'Con \"poco\" el plan elige recetas rápidas y tira del congelador y de tus preparados.';

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
  String get recReadyNow => 'Puedes hacerlas ya';

  @override
  String get recHaveAll => 'Tienes todo';

  @override
  String get recMissingOne => 'Falta 1';

  @override
  String get recOther => 'Otras';

  @override
  String recSeeAll(int count) {
    return 'Ver las $count';
  }

  @override
  String get recNoFilter =>
      'No hay recetas con este filtro.\nPrueba con otra categoría.';

  @override
  String get clear => 'Limpiar';

  @override
  String recNoMatch(String query) {
    return 'No hay recetas que coincidan con\n\"$query\".';
  }

  @override
  String get rdPhoto => 'Foto de la receta';

  @override
  String get rdAutoPhoto => 'Buscar otra foto automática';

  @override
  String get rdAutoPhotoHint => 'Busca una imagen nueva por el nombre';

  @override
  String get rdGallery => 'Elegir de la galería';

  @override
  String get rdNoBetterPhoto => 'No he encontrado otra foto mejor por ahora';

  @override
  String get rdRemovePhoto => 'Quitar la foto';

  @override
  String get rdRemovePhotoHint => 'Se verá el dibujo del plato';

  @override
  String get rdUploadError => 'No se pudo subir la foto';

  @override
  String rdShareText(String title, String code) {
    return 'Te paso mi receta de $title en PrezHome. En la app, ve a Recetas, toca Añadir receta y luego Con un código: $code';
  }

  @override
  String get rdSavedFreezer => 'Guardado en el congelador.';

  @override
  String get couldNotSave => 'No se pudo guardar';

  @override
  String get rdVideoError => 'No se pudo abrir el enlace del video';

  @override
  String get rdWatchVideo => 'Ver vídeo';

  @override
  String get share => 'Compartir';

  @override
  String get rdEdit => 'Editar receta';

  @override
  String get rdMinutes => 'Minutos';

  @override
  String get rdKcalServing => 'Kcal/ración';

  @override
  String get rdPerServingShort => 'por ración';

  @override
  String rdServingWord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Raciones',
      one: 'Ración',
    );
    return '$_temp0';
  }

  @override
  String get rdFreezable => 'Congelable';

  @override
  String get rdIngredients => 'Ingredientes';

  @override
  String get rdStepsWord => 'Pasos';

  @override
  String rdSteps(int count) {
    return 'Pasos ($count)';
  }

  @override
  String get rdNutrition => 'Nutrición';

  @override
  String get rdNoIngredients => 'Sin ingredientes registrados.';

  @override
  String rdOriginal(String servings) {
    return 'Receta original: $servings';
  }

  @override
  String rdForHome(String servings) {
    return 'Para tu hogar hoy: $servings';
  }

  @override
  String get rdHaveAll => 'Tienes todo en casa';

  @override
  String rdHaveSome(int have, int total) {
    return 'Tienes $have de $total en casa';
  }

  @override
  String rdMissing(int count) {
    return 'Faltan $count';
  }

  @override
  String get rdAtHome => 'En casa';

  @override
  String get rdLacking => 'Falta';

  @override
  String get rdNoSteps =>
      'Esta receta no tiene pasos. Puedes añadirlos editándola.';

  @override
  String get rdPerServingTitle => 'Por ración';

  @override
  String get rdNoNutrition => 'Sin datos de nutrición.';

  @override
  String rdPerServing(String amount) {
    return '$amount por ración';
  }

  @override
  String rdTotal(String amount) {
    return '≈ $amount total';
  }

  @override
  String get rdApproxCost =>
      'Coste aproximado. Escanea tickets para afinarlo con tus precios reales.';

  @override
  String get rdStartCooking => 'Empezar a cocinar';

  @override
  String rdAddedMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Añadidos $count productos a la compra',
      one: 'Añadido a la lista de la compra',
    );
    return '$_temp0';
  }

  @override
  String get rdNeedProfile =>
      'Completa un Perfil Nutricional para ver cuántos gramos y calorías corresponden a cada persona.';

  @override
  String get rdMember => 'Miembro';

  @override
  String get rdAdjustSplit =>
      'Ajusta el reparto de calorías por comida en el perfil para este tipo de receta.';

  @override
  String get rdByProfile => 'Según el perfil de cada uno';

  @override
  String get rdByProfileHint =>
      'Cantidad y calorías por persona para esta comida.';

  @override
  String get arWriteName => 'Escribe el nombre';

  @override
  String get arWriteNameHint => 'Escribe el nombre o pega una receta entera…';

  @override
  String get arGenerate => 'Generar';

  @override
  String get arFilled => 'Receta rellenada. Revísala antes de guardar.';

  @override
  String get arFillError => 'No se pudo completar la receta';

  @override
  String get arImport => 'Importar receta';

  @override
  String get arPasteRecipe => 'Pega la receta';

  @override
  String get arImportHint =>
      'Pega el enlace de TikTok, YouTube o una web, o el texto de la receta. En Instagram copia la descripción del post y pégala aquí.';

  @override
  String get arLinkOrText => 'Enlace o texto de la receta';

  @override
  String get arRecipeText => 'Texto de la receta';

  @override
  String get paste => 'Pegar';

  @override
  String get arImportBtn => 'Importar';

  @override
  String get arNeedLink => 'Pega un enlace o el texto completo de la receta.';

  @override
  String get arImported => 'Receta importada. Revísala antes de guardar.';

  @override
  String get arImportLinkError => 'No pude importar la receta de ese enlace';

  @override
  String get arImportError => 'No se pudo importar';

  @override
  String get arPickMealType => 'Elige al menos un tipo de comida.';

  @override
  String get arVideoNotUrl =>
      'El enlace de video no parece una URL, pero lo guardamos igual.';

  @override
  String get arRecalculated =>
      'Calorías y macros recalculadas con los ingredientes.';

  @override
  String arPhotoFailed(String error) {
    return 'Receta guardada, pero la foto no se pudo subir: $error';
  }

  @override
  String get arSaveError => 'Error al guardar';

  @override
  String get arReadingVideo => 'Leyendo la receta del vídeo…';

  @override
  String get arCompleting => 'Completando la receta…';

  @override
  String get arAddPhoto => 'Añadir foto (opcional)';

  @override
  String get arTitleField => 'Título';

  @override
  String get arTitleRequired => 'Ponle un título';

  @override
  String get arDescription => 'Descripción (opcional)';

  @override
  String get arVideoLink => 'Enlace de video (opcional)';

  @override
  String get arMealTypes => 'Tipo de comida (puedes elegir varios)';

  @override
  String get arAuto => 'Auto';

  @override
  String get arServingsHelper => 'Para cuántas es';

  @override
  String get arGramsServing => 'Gramos / ración';

  @override
  String get arNutritionTitle => 'Valores nutricionales (por ración)';

  @override
  String get arCooking => 'Cocina';

  @override
  String get arPrepMin => 'Preparación (min)';

  @override
  String get arCookMin => 'Cocción (min)';

  @override
  String get arAppliance => 'Aparato principal';

  @override
  String get arFreezable => 'Es congelable';

  @override
  String get arAddIngredient => 'Añadir ingrediente';

  @override
  String get arStepsTitle => 'Pasos de preparación';

  @override
  String get arStepsHint => 'Escribe los pasos, uno por línea…';

  @override
  String get arSaveChanges => 'Guardar cambios';

  @override
  String get arSaveRecipe => 'Guardar Receta';

  @override
  String get arIngredient => 'Ingrediente';

  @override
  String get tskWhoDid => '¿Quién hizo la tarea?';

  @override
  String get tskTheHome => 'el hogar';

  @override
  String tskPointsFor(int points, String who) {
    return '+$points puntos para $who';
  }

  @override
  String tskPointsForPantry(int points, String who, int count) {
    return '+$points puntos para $who. $count productos a la despensa';
  }

  @override
  String tskYou(String name) {
    return '$name (tú)';
  }

  @override
  String get tskThisMember => 'este miembro';

  @override
  String get tskResetPoints => 'Reiniciar puntos';

  @override
  String tskResetAsk(String name) {
    return 'Se pondrán a 0 los puntos de $name. Esto no se puede deshacer. ¿Seguro?';
  }

  @override
  String get tskReset => 'Reiniciar';

  @override
  String tskResetDone(String name) {
    return 'Puntos de $name reiniciados.';
  }

  @override
  String get tskDeleteTitle => '¿Eliminar tarea?';

  @override
  String tskDeleteAsk(String title) {
    return 'Se borrará \"$title\".';
  }

  @override
  String tskClaimed(String title) {
    return '\"$title\" es tuya';
  }

  @override
  String get tskDone => 'Hecha';

  @override
  String get tskToTomorrow => 'Pasar a mañana';

  @override
  String get tskToNextWeek => 'Pasar a la próxima semana';

  @override
  String get tskTitle => 'Tareas';

  @override
  String get tskEmptyTitle => 'No hay tareas todavía';

  @override
  String get tskEmptyHint => 'Añade la primera.';

  @override
  String get tskNew => 'Nueva tarea';

  @override
  String get tskAnyone => 'Cualquiera';

  @override
  String get tskRotates => 'Por turnos';

  @override
  String get tskRotatesHint => 'Al hacerla, le toca a la siguiente persona';

  @override
  String tskTurnOf(String name) {
    return 'Turno de $name';
  }

  @override
  String get tskForToday => 'Para hoy';

  @override
  String get tskUpcoming => 'Próximos días';

  @override
  String get tskPoolEmpty => 'Nada en la bolsa. Todo tiene dueño.';

  @override
  String get tskSwipeToClaim => 'Desliza a la izquierda para pedírtela.';

  @override
  String get tskNothingDone => 'Hoy aún no hay nada hecho.';

  @override
  String get tskAll => 'Todas';

  @override
  String get tskMine => 'Mías';

  @override
  String get tskAllDoneToday => 'Hoy está todo hecho';

  @override
  String get tskNextBelow => 'Lo siguiente, abajo.';

  @override
  String get tskNothingLeft => 'No queda nada pendiente.';

  @override
  String get tskScoreboard => 'MARCADOR';

  @override
  String get tskPointsPerPerson => 'PUNTOS POR PERSONA';

  @override
  String get tskNoPoints => 'Aún no hay puntos';

  @override
  String get tskNoPointsHint => 'Completa tareas para ir sumando.';

  @override
  String get tskSomeDays => 'Algunos días';

  @override
  String get tskOnce => 'Una vez';

  @override
  String get tskNothingToday => 'Nada para hoy';

  @override
  String get tskAllDone => 'Todo hecho';

  @override
  String tskLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Quedan $count',
      one: 'Queda 1',
    );
    return '$_temp0';
  }

  @override
  String tskOverdueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count atrasadas',
      one: '1 atrasada',
    );
    return '$_temp0';
  }

  @override
  String tskMarkDone(String title) {
    return 'Marcar $title como hecha';
  }

  @override
  String tskClaim(String title) {
    return 'Pedirme $title';
  }

  @override
  String get tskOverdue => 'Atrasada';

  @override
  String tskPts(int points) {
    return '$points pts';
  }

  @override
  String tskView(String view) {
    String _temp0 = intl.Intl.selectLogic(view, {
      'pending': 'Pendientes',
      'pool': 'Bolsa',
      'other': 'Hechas',
    });
    return '$_temp0';
  }

  @override
  String get tskOtherDay => 'Otro día';

  @override
  String get tskEdit => 'Editar tarea';

  @override
  String get tskNameHint => 'Nombre de la tarea';

  @override
  String get tskOrTypeAnother => 'O escribe otra';

  @override
  String get tskWhen => 'Cuándo';

  @override
  String get tomorrow => 'Mañana';

  @override
  String get tskNoDate => 'Sin fecha';

  @override
  String get tskRepeats => 'Se repite';

  @override
  String get tskWho => 'Quién';

  @override
  String get tskMe => 'Yo';

  @override
  String get tskAddPersonHint =>
      'Para asignarla a alguien, añade a esa persona en Hogar (aunque no tenga cuenta).';

  @override
  String get tskDetails => 'Detalles';

  @override
  String get tskNoTime => 'Sin hora';

  @override
  String get tskRemoveTime => 'Quitar hora';

  @override
  String tskFreeAt(String time) {
    return 'Libre a las $time';
  }

  @override
  String get tskNotes => 'Notas';

  @override
  String get tskPoints => 'Puntos';

  @override
  String get tskAdd => 'Añadir tarea';

  @override
  String get arcTitle => 'Añadir receta';

  @override
  String get arcLinkTitle => 'Pegar enlace de vídeo';

  @override
  String get arcLinkSub => 'De TikTok o YouTube, o el texto de Instagram';

  @override
  String get arcNameTitle => 'Escribe el nombre';

  @override
  String get arcNameSub => 'Se completa con ingredientes, pasos y macros';

  @override
  String get arcIdeasTitle => 'Ideas para ti';

  @override
  String get arcIdeasSub => 'Según tu súper, objetivo y presupuesto';

  @override
  String get arcManualTitle => 'A mano';

  @override
  String get arcManualSub => 'Rellena tú cada campo';

  @override
  String get arcCodeTitle => 'Con un código';

  @override
  String get arcCodeSub => 'Guarda una receta que te han compartido';

  @override
  String get arcCodeDialog => 'Código de la receta';

  @override
  String get search => 'Buscar';

  @override
  String get arcNoCode => 'No hay ninguna receta con ese código';

  @override
  String arcIngredientsAsk(int count) {
    return '$count ingredientes. ¿La guardas en tus recetas?';
  }

  @override
  String get arcSaved => 'Receta guardada';

  @override
  String get nutLoadError => 'Error al cargar el perfil';

  @override
  String get nutSaved => 'Perfil guardado';

  @override
  String get nutSaveError => 'Error al guardar';

  @override
  String get nutBirthDate => 'Fecha de nacimiento';

  @override
  String get nutTitle => 'Mi perfil nutricional';

  @override
  String get nutDiary => 'Diario de calorías';

  @override
  String get nutWizard => 'Configurar paso a paso';

  @override
  String get nutWizardSub =>
      'Un asistente te hace unas preguntas y calcula tu objetivo.';

  @override
  String get nutHowCook => '¿Cómo cocinas?';

  @override
  String get nutDaily => 'Del día';

  @override
  String get nutDailySub => 'Cocino cada día';

  @override
  String get nutBatch => 'Cocinar en lote';

  @override
  String get nutBatchSub => 'Cocino de una vez para varios días';

  @override
  String get nutAmounts => 'Cantidades';

  @override
  String get nutPractical => 'Prácticas';

  @override
  String get nutPracticalSub => 'Formatos de súper';

  @override
  String get nutExact => 'Exactas';

  @override
  String get nutExactSub => 'Al gramo';

  @override
  String get nutSex => 'Sexo';

  @override
  String get nutFemale => 'Mujer';

  @override
  String get nutMale => 'Hombre';

  @override
  String get nutSelect => 'Seleccionar…';

  @override
  String nutAge(int age) {
    return '($age años)';
  }

  @override
  String get nutHeight => 'Altura (cm)';

  @override
  String get nutWeight => 'Peso (kg)';

  @override
  String get nutActivityLevel => 'Nivel de actividad';

  @override
  String get nutGoalLabel => 'Objetivo';

  @override
  String nutActivity(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'sedentary': 'Sedentario (poco o nada de ejercicio)',
      'light': 'Ligero (1-3 días/semana)',
      'moderate': 'Moderado (3-5 días/semana)',
      'active': 'Activo (6-7 días/semana)',
      'other': 'Muy activo (ejercicio intenso o trabajo físico)',
    });
    return '$_temp0';
  }

  @override
  String nutGoal(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'lose': 'Perder peso',
      'gain': 'Ganar peso',
      'other': 'Mantener peso',
    });
    return '$_temp0';
  }

  @override
  String get nutSplit => 'Reparto de calorías por comida';

  @override
  String nutTotal(int pct) {
    return 'Total: $pct%';
  }

  @override
  String get nutSplitHint =>
      'Pon 0% en las comidas que no haces. La suma debería ser 100%.';

  @override
  String get nutAtHome => 'Comidas en casa';

  @override
  String get nutAtHomeHint =>
      'Marca los días que haces cada comida en casa. Si comes fuera (p. ej. en el trabajo), desmarca ese día y no se contará.';

  @override
  String get nutShare => 'Compartir mi perfil con el hogar';

  @override
  String get nutShareSub => 'Si está desactivado, tu perfil es privado.';

  @override
  String get nutSave => 'Guardar perfil';

  @override
  String get nutIncomplete =>
      'Completa sexo, fecha de nacimiento, altura y peso para calcular tus calorías y macros diarios.';

  @override
  String get nutDailyTarget => 'Tu objetivo diario (aprox.)';

  @override
  String nutKcalDay(int kcal) {
    return '$kcal kcal / día';
  }

  @override
  String nutPerMeal(int kcal, int meals) {
    return '≈ $kcal kcal por comida ($meals comidas)';
  }

  @override
  String get ecoBudgetTitle => 'Presupuesto mensual';

  @override
  String ecoAmount(String symbol) {
    return 'Importe ($symbol)';
  }

  @override
  String get ecoDeleteTicket => '¿Eliminar ticket?';

  @override
  String get ecoDeleteTicketSub => 'Dejará de contar en tus gastos.';

  @override
  String ecoRedeemed(String title) {
    return 'Has canjeado \"$title\"';
  }

  @override
  String get ecoRedeemFail =>
      'No se ha podido canjear. Puede que te falte saldo.';

  @override
  String get ecoNewReward => 'Nueva recompensa';

  @override
  String get ecoRewardTitle => 'Título';

  @override
  String get ecoRewardDesc => 'Descripción (opcional)';

  @override
  String get ecoRewardCost => 'Coste en puntos';

  @override
  String get ecoTitle => 'Gastos y tickets';

  @override
  String get ecoStats => 'Estadísticas de la compra';

  @override
  String get ecoScan => 'Escanear ticket';

  @override
  String ecoTicketsOf(String month) {
    return 'Tickets de $month';
  }

  @override
  String get ecoPointsBalance => 'Balanza de puntos';

  @override
  String get ecoPointsBalanceSub =>
      'Saldo de cada miembro para canjear recompensas.';

  @override
  String get ecoNoPoints => 'Aún no hay puntos que repartir';

  @override
  String get ecoNoPointsSub =>
      'Completad tareas del hogar para llenar la balanza.';

  @override
  String get ecoRewards => 'Recompensas';

  @override
  String ecoBalance(int points) {
    return 'Tu saldo: $points pts';
  }

  @override
  String get ecoRedeem => 'Canjear';

  @override
  String get ecoNoRewards => 'Todavía no hay recompensas';

  @override
  String get ecoNoRewardsSub =>
      'Crea la primera con el botón \"Nueva recompensa\".';

  @override
  String get ecoTotalSpent => 'Gasto total registrado';

  @override
  String ecoTicketCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tickets en total',
      one: '1 ticket en total',
    );
    return '$_temp0';
  }

  @override
  String get ecoThisMonth => 'Este mes';

  @override
  String ecoBudget(String amount) {
    return 'Presupuesto: $amount';
  }

  @override
  String get ecoSetBudget => 'Fijar presupuesto';

  @override
  String ecoOver(String amount) {
    return 'Te has pasado $amount del presupuesto';
  }

  @override
  String ecoLeft(String amount) {
    return 'Te quedan $amount';
  }

  @override
  String get ecoLastMonths => 'Gasto de los últimos meses';

  @override
  String ecoBudgetPerMonth(String amount) {
    return 'Presupuesto: $amount al mes';
  }

  @override
  String get ecoBudgetShort => 'Presupuesto';

  @override
  String get ecoNoTrend =>
      'Aún no hay gasto registrado en los últimos meses.\nCuando escanees tickets verás aquí tu tendencia.';

  @override
  String get ecoTicket => 'Ticket';

  @override
  String get ecoNoTickets =>
      'Aún no hay tickets este mes.\nEscanea el primero.';

  @override
  String get stOthers => 'Otros';

  @override
  String get stNoCategory => 'Sin categoría';

  @override
  String get stThisWeek => 'Esta';

  @override
  String get stTitle => 'Tus datos';

  @override
  String get stSpendByMonth => 'Gasto por mes';

  @override
  String get stForecastFooter => 'En claro, lo que falta para la previsión';

  @override
  String get stNoSpend => 'Escanea un ticket y verás tu gasto mes a mes.';

  @override
  String get stWhereSpend => 'En qué gastas este mes';

  @override
  String get stNoTicketsMonth => 'Aún no hay tickets este mes.';

  @override
  String get stTopProducts => 'Lo que más compras';

  @override
  String get stTopProductsFooter =>
      'Veces en tus tickets de los últimos 3 meses';

  @override
  String get stTopProductsEmpty => 'Saldrá cuando escanees tickets.';

  @override
  String get stPantry => 'Tu despensa';

  @override
  String get stMealsHome => 'Comidas en casa';

  @override
  String get stPerWeek => 'Por semana';

  @override
  String stMealsOut(int count) {
    return 'Por semana · $count fuera de casa';
  }

  @override
  String get stMealsEmpty =>
      'Planifica comidas y verás cuántas hacéis en casa.';

  @override
  String get stTasksDone => 'Tareas hechas';

  @override
  String get stTasksFooter => 'Por semana y quién ha hecho más este mes';

  @override
  String get stTasksEmpty => 'Cuando completéis tareas aparecerán aquí.';

  @override
  String get stSoFar => 'Llevas este mes';

  @override
  String get stForecast => 'Previsión: ';

  @override
  String stMoreThanAvg(int pct) {
    return ', un $pct % más que tu media';
  }

  @override
  String stLessThanAvg(int pct) {
    return ', un $pct % menos que tu media';
  }

  @override
  String get stTickets => 'Tickets';

  @override
  String get stExpired => 'Caducado';

  @override
  String get stExpiringSoon => 'Caduca pronto';

  @override
  String get stFresh => 'Bien';

  @override
  String stOverForecast(String amount) {
    return 'A este ritmo te pasarás $amount del presupuesto';
  }

  @override
  String stForecastTip(String amount) {
    return 'Previsión $amount';
  }

  @override
  String get pwPickOption => 'Elige una opción para continuar.';

  @override
  String get pwPickBirth => 'Selecciona tu fecha de nacimiento.';

  @override
  String get pwBadHeight => 'Escribe una altura válida en centímetros.';

  @override
  String get pwBadWeight => 'Escribe un peso válido en kilos.';

  @override
  String get pwCompleteStep => 'Completa este paso para continuar.';

  @override
  String get pwStart => 'Empezar a usar PrezHome';

  @override
  String get pwSeeGoal => 'Ver mi objetivo';

  @override
  String get pwFinish => 'Terminar';

  @override
  String get pwIntroTitle => 'Vamos a conocerte';

  @override
  String get pwIntroSub =>
      'Unas preguntas rápidas para adaptar PrezHome a ti. Puedes cambiarlo cuando quieras.';

  @override
  String get pwTrackKcal => 'Quiero llevar la cuenta de calorías';

  @override
  String get pwTrackKcalSub =>
      'Las comidas del plan se apuntan solas al pasar.';

  @override
  String get pwOnlyHome => 'Solo organizar la casa';

  @override
  String get pwOnlyHomeSub => 'Sin peso ni medidas.';

  @override
  String get pwSex => 'Tu sexo';

  @override
  String get pwSexSub =>
      'Lo usamos para calcular tu metabolismo con más precisión.';

  @override
  String get pwPickDate => 'Seleccionar fecha';

  @override
  String get pwBirthTitle => '¿Cuándo naciste?';

  @override
  String get pwBirthSub => 'La edad nos ayuda a afinar el cálculo de calorías.';

  @override
  String pwAgeYears(int age) {
    return '$age años';
  }

  @override
  String get pwHeightTitle => '¿Cuánto mides?';

  @override
  String get pwHeightSub => 'Indica tu altura en centímetros.';

  @override
  String get pwWeightTitle => '¿Cuánto pesas?';

  @override
  String get pwWeightSub => 'Indica tu peso actual en kilos.';

  @override
  String get pwActivityTitle => 'Tu nivel de actividad';

  @override
  String get pwActivitySub => 'Elige la opción que mejor describa tu semana.';

  @override
  String get pwGoalTitle => '¿Cuál es tu objetivo?';

  @override
  String get pwGoalSub =>
      'Ajustaremos tus calorías según lo que quieras conseguir.';

  @override
  String pwGoalDesc(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'lose': 'Déficit suave para bajar de peso poco a poco.',
      'gain': 'Superávit suave para ganar masa de forma sana.',
      'other': 'Mantener tu peso actual y sentirte bien.',
    });
    return '$_temp0';
  }

  @override
  String get pwDietTitle => '¿Cómo te alimentas?';

  @override
  String get pwDietSub => 'Las recetas se adaptarán a tu dieta.';

  @override
  String pwDiet(String diet) {
    String _temp0 = intl.Intl.selectLogic(diet, {
      'vegetariana': 'Vegetariana',
      'vegana': 'Vegana',
      'pescetariana': 'Pescetariana',
      'baja_carbo': 'Baja en carbohidratos',
      'sin_gluten': 'Sin gluten',
      'other': 'De todo',
    });
    return '$_temp0';
  }

  @override
  String get pwAllergiesTitle => 'Alergias o intolerancias';

  @override
  String get pwOptional => 'Opcional.';

  @override
  String pwAllergy(String allergy) {
    String _temp0 = intl.Intl.selectLogic(allergy, {
      'frutossecos': 'frutos secos',
      'lactosa': 'lactosa',
      'gluten': 'gluten (celiaquía)',
      'huevo': 'huevo',
      'marisco': 'marisco',
      'soja': 'soja',
      'other': 'pescado',
    });
    return '$_temp0';
  }

  @override
  String get pwCuisinesTitle => '¿Qué te gusta comer?';

  @override
  String get pwCuisinesSub => 'Elige las que quieras.';

  @override
  String pwCuisine(String cuisine) {
    String _temp0 = intl.Intl.selectLogic(cuisine, {
      'casera': 'Casera de siempre',
      'mediterranea': 'Mediterránea',
      'ligera': 'Ligera',
      'rapida': 'Rápida y sencilla',
      'italiana': 'Italiana',
      'asiatica': 'Asiática',
      'mexicana': 'Mexicana',
      'other': 'De todo el mundo',
    });
    return '$_temp0';
  }

  @override
  String get pwAppliancesTitle => '¿Qué tienes en la cocina?';

  @override
  String get pwAppliancesSub => 'El plan solo usará recetas que puedas hacer.';

  @override
  String appliance(String appliance) {
    String _temp0 = intl.Intl.selectLogic(appliance, {
      'oven': 'Horno',
      'stovetop': 'Sartén',
      'pot': 'Olla',
      'airfryer': 'Airfryer',
      'microwave': 'Microondas',
      'blender': 'Batidora',
      'other': 'Ninguno',
    });
    return '$_temp0';
  }

  @override
  String get pwDislikedTitle => 'Ingredientes que no te gustan';

  @override
  String get pwDislikedSub => 'Separados por comas. Opcional.';

  @override
  String get pwDislikedHint => 'cebolla, cilantro...';

  @override
  String get pwCookTimeTitle => '¿Cuánto tiempo quieres cocinar?';

  @override
  String get pwCookTimeSub =>
      'Así ajusto las recetas a tu ritmo. Puedes dejarlo sin elegir.';

  @override
  String pwCookTime(String time) {
    String _temp0 = intl.Intl.selectLogic(time, {
      'rapido': 'Rápido (menos de 20 min)',
      'elaborado': 'Elaborado (me gusta cocinar)',
      'other': 'Normal',
    });
    return '$_temp0';
  }

  @override
  String pwCookTimeDesc(String time) {
    String _temp0 = intl.Intl.selectLogic(time, {
      'rapido': 'Platos resueltos en poco tiempo.',
      'elaborado': 'Disfruto cocinando con calma.',
      'other': 'Un equilibrio entre rápido y elaborado.',
    });
    return '$_temp0';
  }

  @override
  String get pwCookStyleTitle => '¿Cómo prefieres cocinar?';

  @override
  String get pwChangeAnytime => 'Puedes cambiarlo cuando quieras.';

  @override
  String cookStyle(String style) {
    String _temp0 = intl.Intl.selectLogic(style, {
      'batch': 'En lote',
      'mixed': 'Mixto',
      'other': 'Diario',
    });
    return '$_temp0';
  }

  @override
  String cookStyleSub(String style) {
    String _temp0 = intl.Intl.selectLogic(style, {
      'batch': 'Cocino en tandas para varios días',
      'mixed': 'Combino tandas y cocina del día',
      'other': 'Cocino cada día lo del momento',
    });
    return '$_temp0';
  }

  @override
  String get pwModulesTitle => '¿Qué quieres activar?';

  @override
  String get pwModulesSub => 'Lo que apagues no se mostrará.';

  @override
  String homeModule(String module) {
    String _temp0 = intl.Intl.selectLogic(module, {
      'points': 'Modo Puntos',
      'tasks': 'Tareas',
      'other': 'Cocina en lote',
    });
    return '$_temp0';
  }

  @override
  String homeModuleDesc(String module) {
    String _temp0 = intl.Intl.selectLogic(module, {
      'points': 'Gana puntos y recompensas por tus tareas.',
      'tasks': 'Organiza las tareas del hogar.',
      'other': 'Cocina en tandas y planifica preparaciones.',
    });
    return '$_temp0';
  }

  @override
  String get pwAllSet => 'Todo listo';

  @override
  String get pwAllSetSub =>
      'Recetas, plan y compra se adaptan a lo que has contado.';

  @override
  String get pwDailyGoal => 'Tu objetivo diario';

  @override
  String get pwKcalDay => 'kcal / día';

  @override
  String get pwEstimate =>
      'Es una estimación para empezar. Las comidas del plan se apuntarán solas en tu diario cuando pasen.';

  @override
  String get phCantAnalyze => 'No se pudo analizar la comida';

  @override
  String phAnalyzeError(String error) {
    return 'Error al analizar la foto: $error';
  }

  @override
  String get phAnalyzeFail => 'Error al analizar la foto';

  @override
  String get phAddOne => 'Añade al menos un alimento con nombre.';

  @override
  String get phTitle => 'Registrar con foto';

  @override
  String get phLooking => 'Mirando el plato…';

  @override
  String get phStartTitle => 'Haz una foto a tu plato';

  @override
  String get phStartSub =>
      'Calculamos los alimentos y sus calorías. Podrás corregirlo antes de guardar.';

  @override
  String get takePhoto => 'Hacer foto';

  @override
  String get phReview => 'Revisa y corrige lo detectado';

  @override
  String get phApprox => 'Las calorías son aproximadas.';

  @override
  String get phMealType => 'Tipo de comida (opcional)';

  @override
  String get phNoType => 'Sin tipo';

  @override
  String get day => 'Día';

  @override
  String get phNothing =>
      'No se ha reconocido ningún alimento. Añádelos a mano.';

  @override
  String phFoods(int count) {
    return 'ALIMENTOS ($count)';
  }

  @override
  String get phAddFood => 'Añadir alimento';

  @override
  String get phFood => 'Alimento';

  @override
  String get phGrams => 'g (aprox)';

  @override
  String get phP => 'P (g)';

  @override
  String get phC => 'C (g)';

  @override
  String get phF => 'G (g)';

  @override
  String get total => 'Total';

  @override
  String kcalAmount(int kcal) {
    return '$kcal kcal';
  }

  @override
  String get phSave => 'Guardar en el diario';

  @override
  String get stkOpenError => 'No se pudo abrir el ticket';

  @override
  String get stkReadError => 'No se pudo leer el ticket';

  @override
  String get stkScanError => 'Error al escanear';

  @override
  String get stkPantryError =>
      'El ticket se guardó, pero no se pudo actualizar la despensa';

  @override
  String stkCrossed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count productos tachados de la lista',
      one: '1 producto tachado de la lista',
    );
    return '$_temp0';
  }

  @override
  String get stkEdit => 'Editar ticket';

  @override
  String get stkReading => 'Leyendo el ticket…';

  @override
  String get stkStartTitle => 'Escanea el ticket de la compra';

  @override
  String get stkStartSub =>
      'Sacamos los productos y precios. Podrás revisarlo después.';

  @override
  String get stkReview => 'Revisa y corrige lo que haga falta';

  @override
  String get stkRemember =>
      'Tus correcciones se recordarán para la próxima vez.';

  @override
  String get stkStore => 'Tienda';

  @override
  String get date => 'Fecha';

  @override
  String get stkAddPantry => 'Añadir a la despensa';

  @override
  String get stkAddPantrySub => 'Cada producto va a su zona';

  @override
  String stkProducts(int count) {
    return 'PRODUCTOS ($count)';
  }

  @override
  String stkRaw(String name) {
    return 'Ticket: \"$name\"';
  }

  @override
  String get category => 'Categoría';

  @override
  String get stkQty => 'Cant.';

  @override
  String get stkSave => 'Guardar ticket';

  @override
  String foodCategory(String cat) {
    String _temp0 = intl.Intl.selectLogic(cat, {
      'verdura': 'Verduras',
      'fruta': 'Frutas',
      'carne': 'Carne',
      'pescado': 'Pescado',
      'lacteos': 'Lácteos',
      'preparados': 'Platos preparados',
      'panaderia': 'Panadería',
      'cereales': 'Pasta, arroz y legumbres',
      'conservas': 'Conservas',
      'congelados': 'Congelados',
      'dulces': 'Dulces y snacks',
      'bebidas': 'Bebidas',
      'especias': 'Especias y condimentos',
      'higiene': 'Higiene',
      'limpieza': 'Limpieza',
      'hogar': 'Hogar',
      'other': 'Otros',
    });
    return '$_temp0';
  }

  @override
  String get cookMode => 'Modo cocina';

  @override
  String get bpMeanwhile => 'Mientras tanto';

  @override
  String bpTapers(String title) {
    return 'Tápers · $title';
  }

  @override
  String get bpBatchCook => 'Cocina en tanda';

  @override
  String get bpStart => 'Empezar paso a paso';

  @override
  String bpHeroTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recetas de una vez',
      one: '1 receta de una vez',
    );
    return '$_temp0';
  }

  @override
  String bpSteps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pasos',
      one: '1 paso',
    );
    return '$_temp0';
  }

  @override
  String get bpStepsTitle => 'Así irá la tanda';

  @override
  String get bpCooking => 'Qué vas a cocinar';

  @override
  String get cmTimer => 'Temporizador';

  @override
  String cmIngredientsReady(int done, int total) {
    return '$done de $total listos';
  }

  @override
  String get bpEmpty => 'No hay nada que cocinar ahora mismo';

  @override
  String get bpEmptySub =>
      'Cuando tengas recetas planificadas, aquí te prepararé un plan de cocina para hacerlo todo de una vez.';

  @override
  String get bpNeed => 'Lo que necesitas';

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String get ready => 'Listo';

  @override
  String get pause => 'Pausar';

  @override
  String get start => 'Iniciar';

  @override
  String get reset => 'Reiniciar';

  @override
  String cmStep(int n) {
    return 'Paso $n';
  }

  @override
  String get cmTime => 'Tiempo';

  @override
  String get cmSeeStep => 'Ver paso';

  @override
  String get ok => 'Vale';

  @override
  String get cmMicPermission =>
      'Para usar la voz, permite el micrófono en Ajustes.';

  @override
  String get ingredients => 'Ingredientes';

  @override
  String get cmExit => 'Salir del modo cocina';

  @override
  String get cmHandsFreeOff => 'Quitar manos libres';

  @override
  String get cmHandsFree => 'Manos libres';

  @override
  String get cmVoiceHint =>
      'Di «siguiente», «anterior», «repite» o «temporizador»';

  @override
  String get cmStop => 'Parar';

  @override
  String cmStepOf(int n, int total) {
    return 'PASO $n DE $total';
  }

  @override
  String get cmTimerRunning => 'Temporizador en marcha';

  @override
  String get cmThen => 'Luego';

  @override
  String get cmNextStep => 'Siguiente paso';

  @override
  String get shopSugDue => 'Te toca';

  @override
  String get shopSugOut => 'Te falta en casa';

  @override
  String get shopOutAtHome => 'Agotado en casa';

  @override
  String get shopGridView => 'Ver en cuadrícula';

  @override
  String get shopGridHint => 'Fotos grandes, dos por fila';

  @override
  String get shopShowSuggestions => 'Mostrar sugerencias';

  @override
  String get shopSuggestionsHint =>
      'Lo que te toca reponer y lo que se acabó en casa';

  @override
  String get shopShowPrices => 'Mostrar precios';

  @override
  String shopEveryDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Cada $n días',
      one: 'Cada día',
    );
    return '$_temp0';
  }

  @override
  String get slNewList => 'Nueva lista';

  @override
  String get slMyLists => 'Mis listas';

  @override
  String get slActive => 'Activa';

  @override
  String get slNewCat => 'Nueva categoría';

  @override
  String get slRenameCat => 'Renombrar categoría';

  @override
  String get slCategories => 'Categorías';

  @override
  String get slAddCat => 'Añadir categoría';

  @override
  String get slNoCats =>
      'Aún no hay categorías. Añade la primera con el botón de abajo.';

  @override
  String get rename => 'Renombrar';

  @override
  String ppDayMeals(String day, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comidas',
      one: '1 comida',
    );
    return '$day, $_temp0';
  }

  @override
  String ppFastTime(String time) {
    return '$time · Ayuno';
  }

  @override
  String get ppEatOut => '· Fuera';

  @override
  String mealAdd(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'breakfast': 'Añadir desayuno',
      'lunch': 'Añadir comida',
      'snack': 'Añadir merienda',
      'dinner': 'Añadir cena',
      'dessert': 'Añadir postre',
      'other': 'Añadir comida',
    });
    return '$_temp0';
  }

  @override
  String get ppFromFreezer => 'Del congelador';

  @override
  String ppServings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rac.',
      one: '1 ración',
    );
    return '$_temp0';
  }

  @override
  String get ppFresh => 'Recién hecho';

  @override
  String ppFridge(String days) {
    return 'Nevera · $days';
  }

  @override
  String ppFreezer(String days) {
    return 'Congelador · $days';
  }

  @override
  String get ppTapersAuto => 'Los tápers se apuntan solos en Mi cocina';

  @override
  String drGoal(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'lose': 'Perder grasa',
      'gain': 'Ganar músculo',
      'protein': 'Alta proteína',
      'other': 'Mantener',
    });
    return '$_temp0';
  }

  @override
  String drDiet(String diet) {
    String _temp0 = intl.Intl.selectLogic(diet, {
      'veg': 'Vegetariana',
      'vegan': 'Vegana',
      'quick': 'Rápida',
      'lowcarb': 'Baja en carbohidratos',
      'other': 'Sin restricción',
    });
    return '$_temp0';
  }

  @override
  String drFreeOf(String allergen) {
    String _temp0 = intl.Intl.selectLogic(allergen, {
      'gluten': 'Sin gluten (celiaquía)',
      'lactosa': 'Sin lactosa',
      'huevo': 'Sin huevo',
      'marisco': 'Sin marisco',
      'soja': 'Sin soja',
      'other': 'Sin frutos secos',
    });
    return '$_temp0';
  }

  @override
  String get drAnyType => 'Cualquiera';

  @override
  String get drNoIdeas => 'No se recibieron ideas';

  @override
  String get drSaved => 'Guardada en tus recetas';

  @override
  String get drSearchSuper => 'Buscar supermercado...';

  @override
  String get drNoSuper => 'No encontramos ese súper.';

  @override
  String get drTitlePantry => '¿Qué cocino con esto?';

  @override
  String get drTitle => 'Ideas personalizadas';

  @override
  String get drNewIdeas => 'Ideas nuevas';

  @override
  String get drWithPantry => 'Con lo que tengo';

  @override
  String get drPantryLoading => 'Mirando tu despensa…';

  @override
  String get drPantryEmpty =>
      'Tu despensa está vacía: añade lo que tienes en casa para recibir ideas con ello.';

  @override
  String drPantryUse(int count) {
    return 'Usaremos $count alimentos de tu despensa, empezando por lo que caduca antes.';
  }

  @override
  String get drCraving => '¿Qué te apetece?';

  @override
  String get drSupers => 'Supermercados';

  @override
  String get drSupersHint =>
      'Opcional. Si no eliges ninguno, las recetas valen para cualquier súper.';

  @override
  String get drGoalTitle => 'Objetivo';

  @override
  String get drDietTitle => 'Dieta';

  @override
  String drDietLocked(String diet) {
    return 'Usamos la dieta de tu perfil: $diet';
  }

  @override
  String get drAllergyTitle => 'Intolerancias y alergias';

  @override
  String get drAllergyHint => 'Nunca saldrán en las recetas.';

  @override
  String get drAppliances => 'Electrodomésticos';

  @override
  String get drMaxCost => 'Coste máximo por ración';

  @override
  String get drMaxCostHint => 'Opcional, p. ej. 2,50';

  @override
  String get drSearching => 'Buscando ideas…';

  @override
  String get drSeeIdeas => 'Ver ideas';

  @override
  String drAddedToShop(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Añadidos $count productos a la compra',
      one: 'Añadido a la lista de la compra',
    );
    return '$_temp0';
  }

  @override
  String get drAddFail =>
      'No se pudo añadir a la compra. Revisa la conexión e inténtalo de nuevo.';

  @override
  String drProteinShort(String grams) {
    return 'P: ${grams}g';
  }

  @override
  String get drCostTip =>
      'Orientativo: precios de tus tickets o, si no, precios medios de supermercado.';

  @override
  String drPerServing(String price) {
    return '≈ $price/ración';
  }

  @override
  String get drHave => 'Tienes:';

  @override
  String get drMissing => 'Te falta:';

  @override
  String get drAddedShort => 'Añadido a la compra';

  @override
  String get drAddMissing => 'Añadir lo que falta';

  @override
  String get drSavedShort => 'Guardada';

  @override
  String get drSaveToRecipes => 'Guardar en mis recetas';

  @override
  String taskKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'bano': 'Baño',
      'ropa': 'Ropa',
      'compra': 'Compra',
      'basura': 'Basura',
      'platos': 'Platos',
      'limpieza': 'Limpieza',
      'plantas': 'Plantas',
      'cama': 'Cama',
      'mascota': 'Mascota',
      'cocinar': 'Cocinar',
      'pagos': 'Pagos',
      'other': 'Tarea',
    });
    return '$_temp0';
  }

  @override
  String taskPreset(String preset) {
    String _temp0 = intl.Intl.selectLogic(preset, {
      'dishes': 'Fregar los platos',
      'vacuum': 'Aspirar',
      'bathroom': 'Limpiar el baño',
      'laundry': 'Poner lavadora',
      'trash': 'Sacar la basura',
      'shopping': 'Hacer la compra',
      'plants': 'Regar las plantas',
      'other': 'Cambiar sábanas',
    });
    return '$_temp0';
  }

  @override
  String get recQuick => 'Rápidas';

  @override
  String get recLight => 'Ligeras';

  @override
  String get recFreezer => 'Congelables';

  @override
  String get recSearchHint => 'Busca por nombre o ingrediente';

  @override
  String get recSort => 'Ordenar';

  @override
  String get recSortRecent => 'Más nuevas';

  @override
  String get recSortAz => 'De la A a la Z';

  @override
  String get recSortFastest => 'Más rápidas primero';

  @override
  String get recSortLightest => 'Menos calorías primero';

  @override
  String get recClearFilters => 'Quitar filtros';

  @override
  String get recMore => 'Más';

  @override
  String get recLess => 'Menos';

  @override
  String get planBusyAware => 'Organizar según mi calendario';

  @override
  String get planBusyAwareHint =>
      'Los días cargados tocan recetas rápidas o del congelador, se cocina en el día más libre y las tareas sin hora van a un hueco. Se aplica al hacer el plan.';

  @override
  String get planBusyDay => 'Día cargado';

  @override
  String get nutAlternate => 'Cada dos días';

  @override
  String get nutAlternateSub =>
      'Cocino de más y al día siguiente como las sobras';

  @override
  String get planHowYouCook => 'Cómo cocinas';

  @override
  String get planModeDaily => 'Cada día';

  @override
  String get planModeAlternate => 'Cada 2 días';

  @override
  String get planModeBatch => 'En lote';

  @override
  String get planLeftoverMeals => 'Qué se repite al día siguiente';

  @override
  String get planLeftover => 'Sobras de ayer';

  @override
  String get planOldTapersTitle => 'Tápers del plan anterior';

  @override
  String planOldTapersBody(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'quedan $count tápers',
      one: 'queda 1 táper',
    );
    return 'En la nevera $_temp0 que el plan nuevo ya no usa: $names. ¿Los quitas de Mi cocina?';
  }

  @override
  String get planOldTapersKeep => 'Dejarlos';

  @override
  String get hhCreateError => 'No se pudo crear el hogar';

  @override
  String get hhJoinTitle => 'Unirme a un hogar';

  @override
  String get hhInviteCode => 'Código de invitación';

  @override
  String get hhJoin => 'Unirme';

  @override
  String get hhCodeFormat => 'El código tiene 8 letras y números';

  @override
  String get hhCodeInvalid => 'Código no válido o caducado';

  @override
  String get hhCodeCreateError => 'No se pudo crear el código';

  @override
  String get hhThisMember => 'este miembro';

  @override
  String hhRemoveMemberTitle(String name) {
    return '¿Quitar a $name del hogar?';
  }

  @override
  String get hhRemoveMemberBody =>
      'Dejará de ver la compra, la despensa y el plan.';

  @override
  String get hhRemoveError => 'No se pudo quitar';

  @override
  String get hhAddGuestTitle => 'Añadir persona sin cuenta';

  @override
  String get hhAddGuestBody =>
      'Para alguien de casa que no usa la app. Podrás asignarle tareas y apuntar las que haga.';

  @override
  String get hhAddError => 'No se pudo añadir';

  @override
  String hhRemoveGuestTitle(String name) {
    return '¿Quitar a $name?';
  }

  @override
  String get hhRemoveGuestBody =>
      'Se borrarán sus puntos y sus tareas quedarán sin asignar.';

  @override
  String get hhLeaveTitle => '¿Salir del hogar?';

  @override
  String get hhLeaveBody =>
      'Dejarás de ver sus datos. Para volver necesitarás un código nuevo.';

  @override
  String get hhLeave => 'Salir';

  @override
  String get hhLeaveError => 'No se pudo salir del hogar';

  @override
  String get hhNameTitle => 'Nombre del hogar';

  @override
  String get hhRenameError => 'No se pudo renombrar';

  @override
  String get hhDeleteAccountTitle => '¿Borrar tu cuenta?';

  @override
  String get hhDeleteAccountBody =>
      'Se borran tu cuenta y tus datos. Si eres la única persona del hogar, también el hogar entero. No se puede deshacer.';

  @override
  String get hhDeleteConfirm => 'Borrar';

  @override
  String get hhDeleteAccountError => 'No se pudo borrar la cuenta';

  @override
  String get hhDeleteAccount => 'Borrar mi cuenta';

  @override
  String get hhMyHome => 'Mi Hogar';

  @override
  String get hhSignOut => 'Cerrar sesión';

  @override
  String get hhNoHome => 'Aún no perteneces a ningún hogar.';

  @override
  String get hhCreateHome => 'Crear un hogar nuevo';

  @override
  String get hhJoinExisting => 'Unirme a un hogar existente';

  @override
  String get hhRename => 'Renombrar hogar';

  @override
  String hhPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Un hogar de $count personas.',
      one: 'Tu hogar, de momento para ti.',
    );
    return '$_temp0';
  }

  @override
  String hhMembers(int count) {
    return 'Miembros ($count)';
  }

  @override
  String get hhAdmin => 'Administrador';

  @override
  String get hhRemoveFromHome => 'Quitar del hogar';

  @override
  String get hhYou => 'Tú';

  @override
  String get hhNoAccount => 'Sin cuenta';

  @override
  String get hhLeaveHome => 'Salir del hogar';

  @override
  String get hhSettings => 'Hogar y ajustes';

  @override
  String get modeTitle => 'Cómo usas PrezHome';

  @override
  String get modeHint =>
      'Elige qué quieres ver. Puedes cambiarlo cuando quieras.';

  @override
  String get modeCustomHint =>
      'Lo has ajustado a tu manera. Elige un modo para volver a uno de estos.';

  @override
  String get modeEssential => 'Esencial';

  @override
  String get modeEssentialSub => 'Compra, despensa y qué comer';

  @override
  String get modeKitchen => 'Cocina';

  @override
  String get modeKitchenSub => 'Lo esencial, más cocina en lote y calorías';

  @override
  String get modeComplete => 'Completo';

  @override
  String get modeCompleteSub => 'Todo: tareas por turnos, puntos y cocina';

  @override
  String get hhAppearance => 'Apariencia';

  @override
  String get hhPhoneAlerts => 'Avisos en el móvil';

  @override
  String get hhYourData => 'Tus datos';

  @override
  String get hhYourDataSub => 'Gráficas de gasto, compra, cocina y tareas';

  @override
  String get hhExpenses => 'Gastos y tickets';

  @override
  String get hhExpensesSub => 'Presupuesto, tickets escaneados y gasto por mes';

  @override
  String get hhYourPlan => 'Tu plan';

  @override
  String get hhYourPlanSub => 'Usos que te quedan este mes';

  @override
  String get hhNutrition => 'Mi perfil nutricional';

  @override
  String get hhNutritionSub => 'Objetivo de calorías, preferencias y asistente';

  @override
  String get hhInvite => 'Invitar a alguien';

  @override
  String get hhCreateCode => 'Crear código';

  @override
  String get hhCopy => 'Copiar';

  @override
  String get hhCodeCopied => 'Código copiado';

  @override
  String hhValidUntil(String date) {
    return 'Vale hasta el $date';
  }

  @override
  String get hhNewCode => 'Nuevo código';

  @override
  String get hhChoose => 'Elegir';

  @override
  String get hhSupersHint =>
      'Las recetas se adaptarán a lo que haya en tus súper. Es opcional.';

  @override
  String get hhNoSuper => 'Sin supermercado elegido.';

  @override
  String get hhCountryError => 'No se pudo cambiar el país';

  @override
  String get hhWhereShop => '¿Dónde compráis?';

  @override
  String get hhPickMany => 'Puedes elegir varios. Es opcional.';

  @override
  String get hhSaveError => 'No se pudo guardar';

  @override
  String themeMode(String mode) {
    String _temp0 = intl.Intl.selectLogic(mode, {
      'claro': 'Claro',
      'oscuro': 'Oscuro',
      'other': 'Sistema',
    });
    return '$_temp0';
  }

  @override
  String get bcNotFound =>
      'No encontré ese código en Open Food Facts, puedes añadirlo a mano.';

  @override
  String get bcTitle => 'Escanear código';

  @override
  String get bcSearching => 'Buscando el producto…';

  @override
  String get bcNoPermission =>
      'Necesito permiso para usar la cámara y poder escanear el código. Puedes concederlo en los ajustes del teléfono.';

  @override
  String get bcCameraError =>
      'No pude abrir la cámara para escanear. Puedes añadir el producto a mano desde el inventario.';

  @override
  String planFeature(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'scan_ticket': 'Escanear tickets',
      'recipes': 'Ideas y recetas',
      'meal_photo': 'Foto de lo que comes',
      'other': 'Recetas desde un enlace',
    });
    return '$_temp0';
  }

  @override
  String puPlanName(String plan) {
    String _temp0 = intl.Intl.selectLogic(plan, {
      'pro': 'Plan Pro',
      'other': 'Plan gratis',
    });
    return '$_temp0';
  }

  @override
  String get puExplain =>
      'La despensa, la compra, las tareas y el plan no tienen límite. Esto es lo que te queda este mes; se renueva el día 1. Si algo falla, no cuenta.';

  @override
  String get puGoPro => 'Pasar a Pro';

  @override
  String puLeft(int left, int limit) {
    return 'Te quedan $left de $limit';
  }

  @override
  String get psTitle => 'Estadísticas de la compra';

  @override
  String get psMostBought => 'Lo que más compras';

  @override
  String get psMostSpent => 'En lo que más gastas';

  @override
  String get psPriciest => 'Los más caros (por unidad)';

  @override
  String get psHistory => 'Tu historial de compra';

  @override
  String psTotal(String amount) {
    return 'Gasto total registrado: $amount';
  }

  @override
  String get psNoPrices => 'Aún no hay suficientes datos de precios.';

  @override
  String get psEmptyTitle => 'Aún no hay estadísticas';

  @override
  String get psEmptyBody =>
      'Escanea tickets de la compra y aquí verás lo que más compras, en qué gastas más y los productos más caros.';

  @override
  String get meals => 'Comidas';

  @override
  String get mcNoHome => 'No perteneces a ningún hogar.';

  @override
  String mcPrep(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'compra': 'Compra',
      'cocina': 'Cocinar',
      'other': 'Sacar',
    });
    return '$_temp0';
  }

  @override
  String get mcPlanIt => 'Planificar';

  @override
  String get mcSeeInPlan => 'Ver en el plan';

  @override
  String get mcNothing => 'Nada planificado este día.';

  @override
  String get tasks => 'Tareas';

  @override
  String proPeriod(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'annual': 'Al año',
      'sixMonth': 'Cada 6 meses',
      'threeMonth': 'Cada 3 meses',
      'twoMonth': 'Cada 2 meses',
      'monthly': 'Al mes',
      'weekly': 'A la semana',
      'lifetime': 'Para siempre',
      'other': 'Pro',
    });
    return '$_temp0';
  }

  @override
  String get proAlready => 'Ya tienes Pro';

  @override
  String get proMoreUses => 'Más usos cada mes';

  @override
  String get proRestSame =>
      'Lo demás sigue igual: sin límite y para todo el hogar.';

  @override
  String get proFree => 'Gratis';

  @override
  String get proSoon => 'Pro estará disponible muy pronto.';

  @override
  String get proNothingToRestore => 'No hay compras que restaurar.';

  @override
  String get proRestore => 'Restaurar compras';

  @override
  String get proRenews =>
      'Se renueva solo. Puedes cancelar cuando quieras desde la tienda.';

  @override
  String get proTerms => 'Condiciones';

  @override
  String get proPrivacy => 'Privacidad';

  @override
  String get aiSaveError => 'Error al guardar';

  @override
  String get aiStoreProduct => 'Producto del súper';

  @override
  String get aiRemoveProduct => 'Quitar producto';

  @override
  String get aiEditTitle => 'Editar producto';

  @override
  String get aiAddTitle => 'Añadir al inventario';

  @override
  String get aiChangePhoto => 'Cambiar foto';

  @override
  String get aiProductType => 'Tipo de producto';

  @override
  String get aiWhatIsIt => '¿Qué es?';

  @override
  String aiDishKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'ingredient': 'Ingrediente para cocinar',
      'base': 'Base ya preparada',
      'other': 'Plato listo para comer',
    });
    return '$_temp0';
  }

  @override
  String get aiSearchStore => 'Buscar en el súper';

  @override
  String get aiSearchStoreLong => 'Buscar el producto del súper con foto';

  @override
  String get aiQuickAdd => 'Añade los de siempre con un toque';

  @override
  String get aiLocation => 'Ubicación';

  @override
  String get aiCategory => 'Categoría';

  @override
  String get aiQuantity => 'Cantidad';

  @override
  String get aiUnit => 'Unidad';

  @override
  String get aiServings => 'Raciones que representa (opcional)';

  @override
  String get aiFrozenDate => 'Fecha de congelación';

  @override
  String get aiFrozenOn => 'Congelado el (opcional)';

  @override
  String get aiWillEstimate => 'Calcularemos cuánto aguanta en el congelador.';

  @override
  String aiBestBefore(String date) {
    return 'Mejor consumir antes del $date (aprox.).';
  }

  @override
  String get aiExpiryDate => 'Fecha de caducidad';

  @override
  String get aiExpires => 'Caduca el';

  @override
  String get aiExpiresApprox => 'Caduca el (aprox.)';

  @override
  String get aiNotToList => 'No añadir a la compra';

  @override
  String get aiStaplesSub => 'Básicos que siempre tienes';

  @override
  String get aiSaveChanges => 'Guardar cambios';

  @override
  String get aiSaveNew => 'Guardar en el inventario';

  @override
  String get kzMyKitchen => 'Mi cocina';

  @override
  String get kzEmpty => 'Vacía';

  @override
  String get kzAllGood => 'Al día';

  @override
  String get phStore => 'Elegir producto del súper';

  @override
  String get phCamera => 'Hacer una foto';

  @override
  String get phGallery => 'Elegir de la galería';

  @override
  String get phError => 'No se pudo cambiar la foto';

  @override
  String get psStoreTitle => 'Productos del súper';

  @override
  String psStoreTitleOf(String store) {
    return 'Productos de $store';
  }

  @override
  String get psHint => 'Leche, yogur griego, detergente…';

  @override
  String get psTypeHint => 'Escribe un producto y pulsa buscar.';

  @override
  String get psThrottled =>
      'Demasiadas búsquedas seguidas. Prueba en un minuto.';

  @override
  String get psOffline =>
      'Sin conexión a internet. Puedes añadirlo igualmente.';

  @override
  String get psDown =>
      'El buscador de productos no responde ahora. Prueba en un rato o añádelo igualmente.';

  @override
  String get psNotInStore => 'No está en el súper. Puedes añadirlo igualmente.';

  @override
  String psNoResultsIn(String store) {
    return 'Sin resultados en $store. Estos son de otros súper.';
  }

  @override
  String psNotYet(String store) {
    return 'Aún no tenemos los productos de $store. Estos son de otros súper.';
  }

  @override
  String get psOffData => 'Datos de Open Food Facts.';

  @override
  String psAddAsIs(String q) {
    return 'Añadir \"$q\" sin elegir producto';
  }

  @override
  String get offlineExplain =>
      'Puedes seguir usando la lista de la compra y la despensa: lo que apuntes se guarda en el móvil y se envía solo cuando vuelva. Lo demás se actualizará entonces.';

  @override
  String get offlineNow => 'Sin conexión ahora mismo';

  @override
  String streakMilestone(int days) {
    return '¡$days días seguidos!';
  }

  @override
  String streakMilestoneSub(int next) {
    return 'Hito conseguido. Siguiente: $next días.';
  }

  @override
  String streakDoneSub(int next) {
    return 'Hoy ya cuenta. Próximo hito: $next días.';
  }

  @override
  String get streakKeepSub =>
      'Tacha una tarea o apunta una comida para seguir.';

  @override
  String get streakStart => 'Empieza tu racha';

  @override
  String get streakStartSub => 'Tacha una tarea o apunta una comida hoy.';

  @override
  String streakDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días seguidos',
      one: '1 día seguido',
    );
    return '$_temp0';
  }

  @override
  String get syncSaved => 'Guardado. Se sincronizará al volver la conexión.';

  @override
  String get fzTitle => '¿Guardas raciones en el congelador?';

  @override
  String get fzSave => 'Guardar en el congelador';

  @override
  String get notNow => 'Ahora no';

  @override
  String get fastIn => 'En ayuno';

  @override
  String get fastCanEat => 'Puedes comer';

  @override
  String fastLeft(String left, String time) {
    return 'Quedan $left · Comes a las $time';
  }

  @override
  String fastUntil(String time) {
    return 'Hasta las $time';
  }

  @override
  String get shWeekReady =>
      'Tu semana está lista: comidas, cenas y lista de la compra';

  @override
  String get comingSoon => 'PRÓXIMAMENTE';

  @override
  String psSummary(int distinct, int lines) {
    return '$distinct productos distintos · $lines compras';
  }

  @override
  String get errNoConnection =>
      'Parece que no hay conexión. Inténtalo de nuevo en un momento.';

  @override
  String get errBadLogin => 'El correo o la contraseña no son correctos.';

  @override
  String get errConfirmEmail =>
      'Confirma tu correo (revisa tu bandeja de entrada) y vuelve a intentarlo.';

  @override
  String get errSession => 'Tu sesión ha caducado. Vuelve a iniciar sesión.';

  @override
  String get errPermission =>
      'No tienes permiso para hacer esto en este hogar.';

  @override
  String get errRateLimit =>
      'Demasiadas peticiones seguidas. Prueba en un rato.';

  @override
  String get errExists => 'Eso ya existe.';

  @override
  String get errUpload =>
      'No se pudo subir la imagen. Prueba con otra más pequeña.';

  @override
  String get errGeneric => 'Algo ha fallado. Inténtalo de nuevo.';

  @override
  String get errBadQuantity => 'Introduce una cantidad válida.';

  @override
  String get errRecipeComplete => 'No se pudo completar la receta';

  @override
  String get errRecipeImport => 'No pude importar la receta de ese enlace';

  @override
  String get someone => 'Alguien';

  @override
  String get reward => 'Recompensa';

  @override
  String remKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'tasks': 'Tareas con hora',
      'kitchen': 'Congelador y cocina',
      'expiry': 'Productos que caducan',
      'other': 'Racha de casa al día',
    });
    return '$_temp0';
  }

  @override
  String remTaskOne(String title) {
    return 'Toca: $title';
  }

  @override
  String remTaskMany(int count) {
    return 'Tocan $count tareas';
  }

  @override
  String get remTaskOneBody => 'Cuando la acabes, táchala para sumar puntos.';

  @override
  String remTaskManyBody(String list) {
    return '$list. Táchalas al acabar para sumar puntos.';
  }

  @override
  String remExpiryOne(String name) {
    return 'Mañana caduca: $name';
  }

  @override
  String remExpiryMany(int count) {
    return 'Mañana caducan $count productos';
  }

  @override
  String get remExpiryBody =>
      'Cocina hoy con ello o congela lo que no vayas a usar.';

  @override
  String remStreakMilestone(int days) {
    return 'Hoy llegas a $days días';
  }

  @override
  String get remStreakMilestoneBody =>
      'Tacha una tarea o apunta una comida y lo celebras.';

  @override
  String remStreakDays(int days) {
    return 'Llevas $days días con la casa al día';
  }

  @override
  String get remStreakDaysBody =>
      'Tacha una tarea o apunta una comida para no perder la racha.';

  @override
  String get remHowIsHome => '¿Cómo va la casa hoy?';

  @override
  String get remHowIsHomeBody =>
      'Un gesto basta para sumar un día más a tu racha.';

  @override
  String get remStreakAlive => 'Tu racha sigue viva';

  @override
  String get remStreakAliveBody =>
      'Apunta lo que has comido o tacha una tarea antes de dormir.';

  @override
  String listAnd(String items, String last) {
    return '$items y $last';
  }

  @override
  String listMore(String items, int count) {
    return '$items y $count más';
  }

  @override
  String get planMovedLater => 'Lo dejo para otro momento';

  @override
  String get planTheDish => 'el plato';

  @override
  String planMovedTo(String recipe, String day) {
    return 'Movido $recipe al $day';
  }

  @override
  String weekday(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '1': 'lunes',
      '2': 'martes',
      '3': 'miércoles',
      '4': 'jueves',
      '5': 'viernes',
      '6': 'sábado',
      'other': 'domingo',
    });
    return '$_temp0';
  }

  @override
  String weekdayShortName(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '1': 'lun',
      '2': 'mar',
      '3': 'mié',
      '4': 'jue',
      '5': 'vie',
      '6': 'sáb',
      'other': 'dom',
    });
    return '$_temp0';
  }

  @override
  String get prepShopTitle => 'Hacer la compra';

  @override
  String prepShopLine(String day) {
    return 'Para cocinar en tanda el $day';
  }

  @override
  String get prepCookTitle => 'Cocinar en tanda';

  @override
  String get prepAutoTapers => 'Los tápers se apuntan solos en Mi cocina';

  @override
  String get prepThawTitle => 'Del congelador a la nevera';

  @override
  String prepThawLine(String recipe, int count, String day) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tápers',
      one: '1 táper',
    );
    return '$recipe: $_temp0 para el $day';
  }

  @override
  String get taperFresh => 'recién hecho';

  @override
  String taperFridge(String days) {
    return 'nevera para el $days';
  }

  @override
  String taperFreezer(String days) {
    return 'congelador para el $days';
  }

  @override
  String stepPrepare(String recipe) {
    return 'Preparar $recipe';
  }

  @override
  String stepUseAppliance(String appliance, String recipes) {
    String _temp0 = intl.Intl.selectLogic(appliance, {
      'oven': 'Enciende el horno',
      'stovetop': 'Enciende los fogones',
      'pot': 'Enciende la olla',
      'airfryer': 'Enciende la freidora de aire',
      'microwave': 'Enciende el microondas',
      'blender': 'Enciende la batidora',
      'other': 'Usa $appliance',
    });
    return '$_temp0 para $recipes';
  }

  @override
  String comidasTab(String tab) {
    String _temp0 = intl.Intl.selectLogic(tab, {
      'plan': 'Plan',
      'recipes': 'Recetas',
      'other': 'Diario',
    });
    return '$_temp0';
  }

  @override
  String bannerExpiring(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Caducan pronto',
      one: 'Caduca pronto',
    );
    return '$_temp0';
  }

  @override
  String get bannerIdeas => 'Ideas';

  @override
  String get bannerHide => 'Ocultar hasta mañana';

  @override
  String get loading => 'Cargando';

  @override
  String get mascot => 'Mascota';

  @override
  String voiceStep(int n) {
    return 'Paso $n.';
  }

  @override
  String voiceTime(String what) {
    return 'Tiempo. $what.';
  }

  @override
  String get voiceLastStep => 'Es el último paso.';

  @override
  String get voiceNoTime => 'Este paso no tiene tiempo.';

  @override
  String voiceTimer(int minutes) {
    return 'Temporizador de $minutes minutos.';
  }

  @override
  String get voiceNoTimers => 'No hay temporizadores.';

  @override
  String get voiceStopped => 'Parado.';

  @override
  String get voiceNoIngredients => 'No hay lista de ingredientes.';

  @override
  String unitOne(String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'unidad': 'unidad',
      'diente': 'diente',
      'loncha': 'loncha',
      'lata': 'lata',
      'bote': 'bote',
      'bolsa': 'bolsa',
      'comida': 'comida',
      'cucharada': 'cucharada',
      'cucharadita': 'cucharadita',
      'pizca': 'pizca',
      'other': '$unit',
    });
    return '$_temp0';
  }

  @override
  String unitMany(String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'unidad': 'unidades',
      'diente': 'dientes',
      'loncha': 'lonchas',
      'lata': 'latas',
      'bote': 'botes',
      'bolsa': 'bolsas',
      'comida': 'comidas',
      'cucharada': 'cucharadas',
      'cucharadita': 'cucharaditas',
      'pizca': 'pizcas',
      'other': '$unit',
    });
    return '$_temp0';
  }

  @override
  String unitShort(String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'unidad': 'ud',
      'cucharada': 'cda',
      'cucharadita': 'cdta',
      'other': '$unit',
    });
    return '$_temp0';
  }

  @override
  String unitToTaste(String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'a_ojo': 'a ojo',
      'other': 'al gusto',
    });
    return '$_temp0';
  }

  @override
  String aiItemType(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'hogar': 'Hogar/Limpieza',
      'other': 'Comida',
    });
    return '$_temp0';
  }

  @override
  String aiKindShort(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'prep': 'Preparado',
      'dish': 'Plato listo',
      'other': 'Ingrediente',
    });
    return '$_temp0';
  }

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get hhSettingsSub => 'Modo de uso, apariencia, avisos y país';

  @override
  String get hhCustomizeHomeSub => 'Tarjetas y atajos que ves en Hoy';

  @override
  String get onbFoodTitle => '¿Hay algo que no se pueda comer en casa?';

  @override
  String get onbFoodHint =>
      'El plan de comidas nunca lo propondrá. Lo puedes cambiar en tu perfil.';

  @override
  String get onbFoodNone => 'Comemos de todo';

  @override
  String get onbFoodAllergies => 'ALERGIAS O INTOLERANCIAS';

  @override
  String get onbFoodDiet => 'DIETA';

  @override
  String get onbFoodVeg => 'Vegetariana';

  @override
  String get onbFoodVegan => 'Vegana';

  @override
  String rdAllergyWarn(String allergen) {
    return 'Lleva $allergen y alguien en casa no puede tomarlo.';
  }

  @override
  String rdDietWarn(String diet) {
    String _temp0 = intl.Intl.selectLogic(diet, {
      'vegana': 'vegana',
      'pescetariana': 'pescetariana',
      'other': 'vegetariana',
    });
    return 'No encaja con la dieta de casa ($_temp0).';
  }

  @override
  String remDefrostOne(String name) {
    return 'Saca $name del congelador';
  }

  @override
  String remDefrostMany(int count) {
    return 'Saca $count platos del congelador';
  }

  @override
  String get remDefrostBody =>
      'Déjalo en la nevera esta noche y mañana estará listo.';

  @override
  String get remBatchTomorrow => 'Mañana toca cocinar en lote';

  @override
  String remBatchTomorrowBody(int servings) {
    return '$servings raciones. Mira si tienes todo antes de dormir.';
  }

  @override
  String get shopShareList => 'Mandar la lista';

  @override
  String shopShareTitle(String name) {
    return 'Lista de la compra: $name';
  }

  @override
  String get shopShareFooter => 'Hecha con PrezHome';

  @override
  String get shopShareCopied => 'Lista copiada: pégala donde quieras';

  @override
  String get hhSendInvite => 'Mandar invitación';

  @override
  String hhInviteMessage(String code) {
    return '¡Únete a nuestra casa en PrezHome! Así compartimos el plan de comidas, la lista de la compra y las tareas.\n\n1. Instala PrezHome y crea tu cuenta.\n2. Copia este mensaje y toca \"Me han invitado a un hogar\": el código se pondrá solo.\n\nCódigo: $code';
  }
}
