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

  @override
  String homeGreeting(String part) {
    String _temp0 = intl.Intl.selectLogic(part, {
      'morning': 'Buongiorno',
      'afternoon': 'Buon pomeriggio',
      'other': 'Buonasera',
    });
    return '$_temp0';
  }

  @override
  String get homeCustomize => 'Personalizza Oggi';

  @override
  String get homeYourData => 'I tuoi dati';

  @override
  String get homeYourHome => 'La tua casa';

  @override
  String homeTodayTag(String meal) {
    return 'Oggi · $meal';
  }

  @override
  String mealType(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'breakfast': 'Colazione',
      'lunch': 'Pranzo',
      'snack': 'Merenda',
      'dinner': 'Cena',
      'dessert': 'Dolce',
      'drink': 'Bevanda',
      'other': 'Pasto',
    });
    return '$_temp0';
  }

  @override
  String get homeEatingOut => 'Fuori casa';

  @override
  String get homeWhatToEat => 'Cosa mangiamo oggi?';

  @override
  String get homeNothingPlanned =>
      'Non c\'è ancora niente in programma per oggi.';

  @override
  String get homePlan => 'Pianifica';

  @override
  String get homeWithWhatIHave => 'Con quello che ho';

  @override
  String get homeExpiring => 'In scadenza';

  @override
  String homeTasksToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Faccende oggi',
      one: 'Faccenda oggi',
    );
    return '$_temp0';
  }

  @override
  String get homeInShopping => 'Nella spesa';

  @override
  String get homeShortcuts => 'Scorciatoie';

  @override
  String get homeForToday => 'Per oggi';

  @override
  String get homeSeeAll => 'Vedi tutto';

  @override
  String homePoints(int points) {
    return '$points pt';
  }

  @override
  String homePointsSnack(int points) {
    return '+$points punti';
  }

  @override
  String get homeToday => 'Oggi';

  @override
  String get homeTomorrow => 'Domani';

  @override
  String get homeCaloriesTitle => 'Calcola il tuo obiettivo di calorie';

  @override
  String get homeCaloriesHint =>
      'Rispondi a qualche domanda veloce e adatterò PrezHome a te.';

  @override
  String homeOf(String total) {
    return 'di $total';
  }

  @override
  String get homeCaloriesToday => 'Calorie di oggi';

  @override
  String homeKcal(int kcal) {
    return '$kcal kcal';
  }

  @override
  String homeKcalLeft(int kcal) {
    return 'Ti restano $kcal kcal';
  }

  @override
  String homeKcalOver(int kcal) {
    return 'Hai superato di $kcal kcal';
  }

  @override
  String get homeMonthSpend => 'Spesa del mese';

  @override
  String homeMoneyLeft(String amount) {
    return 'Ti restano $amount';
  }

  @override
  String homeMoneyOver(String amount) {
    return 'Hai superato il budget di $amount';
  }

  @override
  String get save => 'Salva';

  @override
  String get homeCardsSection => 'Schede (trascina per ordinare)';

  @override
  String get homeQuickSection => 'Accessi rapidi';

  @override
  String get homeQuickHint =>
      'Scegli le scorciatoie che vedrai in cima a Oggi.';

  @override
  String dashCard(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'meals': 'Pasti di oggi',
      'calories': 'Calorie di oggi',
      'tasks': 'Faccende',
      'other': 'Spesa del mese',
    });
    return '$_temp0';
  }

  @override
  String quickAction(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'add_inventory': 'Aggiungi alla dispensa',
      'scan_ticket': 'Scansiona scontrino',
      'shopping': 'Lista della spesa',
      'add_recipe': 'Nuova ricetta',
      'meal_plan': 'Piano settimanale',
      'other': 'Diario delle calorie',
    });
    return '$_temp0';
  }

  @override
  String get shopPickStore => 'Scegli supermercato';

  @override
  String get shopAddFromPlan => 'Aggiungi il piano della settimana';

  @override
  String get shopListOptions => 'Opzioni della lista';

  @override
  String get shopAllInCart => 'Tutto nel carrello';

  @override
  String shopPending(int pending, int done) {
    return '$pending da comprare · $done nel carrello';
  }

  @override
  String shopUnpriced(int count) {
    return ' · $count senza prezzo';
  }

  @override
  String get shopAddProduct => 'Aggiungi prodotto';

  @override
  String get shopSearchStore => 'Cerca nel supermercato';

  @override
  String get moreOptions => 'Altre opzioni';

  @override
  String get less => 'Meno';

  @override
  String get more => 'Più';

  @override
  String shopAdded(String name) {
    return '$name, aggiunto';
  }

  @override
  String shopAdd(String name) {
    return 'Aggiungi $name';
  }

  @override
  String get shopLiveOffline =>
      'Nessuna connessione in tempo reale; si aggiornerà ricaricando.';

  @override
  String get couldNotUpdate => 'Impossibile aggiornare';

  @override
  String shopSavedToPantry(int count) {
    return '$count prodotti salvati in dispensa';
  }

  @override
  String get shopRemoveFromList => 'Togli dalla lista';

  @override
  String shopRemovedOne(String name) {
    return 'Tolto \"$name\"';
  }

  @override
  String get couldNotChangePhoto => 'Impossibile cambiare la foto';

  @override
  String get shopAddToList => 'Aggiungi alla lista';

  @override
  String get shopTypeFood => 'Cibo';

  @override
  String get shopTypeHome => 'Casa/Pulizia';

  @override
  String get name => 'Nome';

  @override
  String get product => 'Prodotto';

  @override
  String get quantity => 'Quantità';

  @override
  String get unit => 'Unità';

  @override
  String get cancel => 'Annulla';

  @override
  String get add => 'Aggiungi';

  @override
  String get nameEmpty => 'Il nome non può essere vuoto.';

  @override
  String get couldNotAdd => 'Impossibile aggiungere';

  @override
  String get shopPlanAllAtHome => 'Hai già in casa tutto quello del piano';

  @override
  String shopAddedFromPlan(int count) {
    return 'Aggiunti $count prodotti dal piano';
  }

  @override
  String get shopListTitle => 'Lista della spesa';

  @override
  String get shopMainList => 'Lista principale';

  @override
  String get couldNotCreateList => 'Impossibile creare la lista';

  @override
  String get shopRecipesUseStore =>
      'Le ricette useranno prodotti di questo supermercato.';

  @override
  String get shopStoreSaveError =>
      'Impossibile salvare il supermercato. Riprova.';

  @override
  String get shopGroupByAisle => 'Raggruppa per corsia';

  @override
  String get shopGroupHint => 'Verdure, carne, pulizia…';

  @override
  String get shopShowPhotos => 'Mostra foto dei prodotti';

  @override
  String get shopShowIcons => 'Mostra disegni quando non c\'è la foto';

  @override
  String get shopMyLists => 'Le mie liste';

  @override
  String get categories => 'Categorie';

  @override
  String get shopFinish => 'Termina la spesa';

  @override
  String shopFinishCount(int count) {
    return 'Termina la spesa ($count)';
  }

  @override
  String get shopScanTicket => 'Scansiona scontrino';

  @override
  String get shopAllBought => 'Tutto comprato';

  @override
  String get shopToBuy => 'Da comprare';

  @override
  String get shopUsual => 'Il solito';

  @override
  String get shopInCart => 'Nel carrello';

  @override
  String shopRemovedMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tolti $count prodotti',
      one: 'Tolto 1 prodotto',
    );
    return '$_temp0';
  }

  @override
  String get couldNotRemove => 'Impossibile togliere';

  @override
  String get undo => 'Annulla';

  @override
  String get couldNotUndo => 'Impossibile annullare';

  @override
  String get shopToCart => 'Nel carrello';

  @override
  String get shopFromPlan => 'Dal piano della settimana';

  @override
  String get changePhoto => 'Cambia foto';

  @override
  String get shopEmptyTitle => 'La tua lista è vuota';

  @override
  String get shopEmptyHint =>
      'Scrivi sopra ciò che ti serve o porta quello del piano.';

  @override
  String get shopFromPlanAction => 'Dal piano';

  @override
  String get shopDoneTitle => 'Spesa completata';

  @override
  String get shopDoneHint => 'Hai tutto quello della lista. Ottimo lavoro!';

  @override
  String panUsedInOne(String meal) {
    return 'Tolto ciò che hai usato per $meal';
  }

  @override
  String panUsedInMany(int count) {
    return 'Tolto ciò che hai usato per $count pasti del piano';
  }

  @override
  String get view => 'Vedi';

  @override
  String get couldNotDelete => 'Impossibile eliminare';

  @override
  String panNoLongerShop(String name) {
    return '$name non apparirà più nella spesa.';
  }

  @override
  String panBackToShop(String name) {
    return '$name riapparirà nella spesa.';
  }

  @override
  String panCouldNotMarkOut(String name) {
    return 'Impossibile segnare $name come finito';
  }

  @override
  String panMarkedOut(String name) {
    return 'Ho segnato $name come finito.';
  }

  @override
  String panOutNotAdded(String name) {
    return '$name è finito, ma non sono riuscito ad aggiungerlo alla spesa';
  }

  @override
  String panAlreadyInList(String name) {
    return '$name è già nella tua lista della spesa.';
  }

  @override
  String panAddedToShop(String name) {
    return 'Ho aggiunto $name alla spesa';
  }

  @override
  String get panAddManual => 'Aggiungi a mano';

  @override
  String get panScanBarcode => 'Scansiona codice a barre';

  @override
  String get panFreezeDish => 'Piatto cucinato in freezer';

  @override
  String get panFreezeDishHint => 'Scegli la ricetta e quante porzioni';

  @override
  String get panSaveRecipeFirst => 'Prima salva una ricetta.';

  @override
  String get panWhichDish => 'Quale piatto congeli?';

  @override
  String get panHowManyServings => 'Quante porzioni congeli?';

  @override
  String get panTitle => 'Dispensa e Frigo';

  @override
  String get panAddTooltip => 'Aggiungi alla dispensa';

  @override
  String get panLoadError => 'Impossibile caricare l\'inventario';

  @override
  String get panEmptyTitle => 'La tua dispensa è vuota';

  @override
  String get panEmptyHint =>
      'Aggiungi ciò che hai in casa o spunta la spesa e arriverà da solo.';

  @override
  String get panAddProduct => 'Aggiungi prodotto';

  @override
  String get panWhatToCook => 'Cosa cucino con questo?';

  @override
  String get panExpiringHeader => 'Scaduti e in scadenza';

  @override
  String get panNothingHere => 'Qui non c\'è niente.';

  @override
  String kitchenZone(String zone) {
    String _temp0 = intl.Intl.selectLogic(zone, {
      'nevera': 'Frigo',
      'congelador': 'Freezer',
      'despensa': 'Dispensa',
      'bebidas': 'Bevande',
      'especias': 'Condimenti',
      'limpieza': 'Pulizia',
      'hogar': 'Igiene e casa',
      'other': '$zone',
    });
    return '$_temp0';
  }

  @override
  String get kitchenReview => 'Controlla';

  @override
  String expiryGroup(String group) {
    String _temp0 = intl.Intl.selectLogic(group, {
      'expired': 'Scaduto',
      'week': 'Questa settimana',
      'later': 'Più avanti',
      'other': 'Senza data',
    });
    return '$_temp0';
  }

  @override
  String panExpiredAgo(int days) {
    return 'Scaduto da $days giorni';
  }

  @override
  String get panExpiredYesterday => 'Scaduto ieri';

  @override
  String get panExpiresToday => 'Scade oggi';

  @override
  String get panExpiresTomorrow => 'Scade domani';

  @override
  String panExpiresIn(int days) {
    return 'Scade tra $days giorni';
  }

  @override
  String panDays(int days) {
    return '$days giorni';
  }

  @override
  String get panNotBought => 'Non si compra';

  @override
  String get panConsumed => 'Consumato';

  @override
  String get panToShopping => 'Alla spesa';

  @override
  String panCouldNotAddToShop(String name) {
    return 'Non sono riuscito ad aggiungere $name alla spesa';
  }

  @override
  String panExpiredDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count scaduti eliminati',
      one: 'Scaduto eliminato',
    );
    return '$_temp0';
  }

  @override
  String get panMyKitchen => 'La mia cucina';

  @override
  String get panUsedHistory => 'Ciò che è stato consumato';

  @override
  String get panNothingExpired => 'Niente di scaduto';

  @override
  String panDeleteExpired(int count) {
    return 'Elimina scaduti ($count)';
  }

  @override
  String panEmptyZone(String where) {
    return 'Svuota $where';
  }

  @override
  String panEmptyAsk(String where) {
    return 'Svuotare $where?';
  }

  @override
  String panWillDelete(int count) {
    return 'Verranno eliminati $count prodotti.';
  }

  @override
  String get panEmpty => 'Svuota';

  @override
  String panDeleted(int count) {
    return '$count prodotti eliminati';
  }

  @override
  String get edit => 'Modifica';

  @override
  String get panShopAgain => 'Aggiungi di nuovo alla spesa';

  @override
  String get panDontShop => 'Non aggiungere alla spesa';

  @override
  String get panStapleHint => 'Per i prodotti base che hai sempre';

  @override
  String get panWillAddToShop => 'Lo aggiungerò alla spesa';

  @override
  String get delete => 'Elimina';

  @override
  String panDeleteAsk(String name) {
    return 'Eliminare $name?';
  }

  @override
  String panConsumedOn(String name, String day) {
    return '$name, consumato $day';
  }

  @override
  String get todayLower => 'oggi';

  @override
  String get yesterdayLower => 'ieri';

  @override
  String panOnDate(int day, int month) {
    return 'il $day/$month';
  }

  @override
  String get panWhen => 'Quando?';

  @override
  String get today => 'Oggi';

  @override
  String get yesterday => 'Ieri';

  @override
  String get panOtherDay => 'Un altro giorno';

  @override
  String get panWhichDay => 'Quale giorno?';

  @override
  String get panHowMany => 'Quanti?';

  @override
  String panAll(String qty) {
    return 'Tutto ($qty)';
  }

  @override
  String get couldNotLoad => 'Impossibile caricare';

  @override
  String get panNothingYet => 'Ancora niente.';

  @override
  String get panWhenCooking => 'Cucinando';

  @override
  String get planHowLong => 'Per quanto tempo?';

  @override
  String get thisWeek => 'Questa settimana';

  @override
  String planWeeks(int count) {
    return '$count settimane';
  }

  @override
  String get planMonth4 => 'Un mese (4 settimane)';

  @override
  String get planPickDates => 'Scegli le date';

  @override
  String get planDates => 'Date del piano';

  @override
  String get planMaxTwoMonths => 'Al massimo due mesi alla volta.';

  @override
  String get planReadyAllHome =>
      'Piano pronto. Hai già in casa tutto il necessario';

  @override
  String planListReady(int count) {
    return 'Piano pronto. Lista della spesa con $count prodotti';
  }

  @override
  String get planBackInPlan => 'È di nuovo nel piano';

  @override
  String planEntryTitle(String meal, String recipe) {
    return '$meal · $recipe';
  }

  @override
  String get planNoRecipe => 'Senza ricetta';

  @override
  String get planChangeRecipe => 'Cambia ricetta';

  @override
  String get planWhoEats => 'Chi mangia';

  @override
  String get planMarkHome => 'Segna a casa';

  @override
  String get planMarkOut => 'Segna come fuori';

  @override
  String get planStopRepeat => 'Smetti di ripetere';

  @override
  String get planStopRepeatHint => 'Toglie le prossime volte';

  @override
  String get planRepeat => 'Ripeti';

  @override
  String get planRepeatHint => 'Ogni giorno, ogni settimana… o per sempre';

  @override
  String get planRemove => 'Togli dal piano';

  @override
  String planRepeatTitle(String meal) {
    return 'Ripeti $meal';
  }

  @override
  String get planHowOften => 'Ogni quanto?';

  @override
  String planEveryDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Ogni $days giorni',
      one: 'Ogni giorno',
    );
    return '$_temp0';
  }

  @override
  String planEveryWeeks(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: 'Ogni $weeks settimane',
      one: 'Ogni settimana',
    );
    return '$_temp0';
  }

  @override
  String get planUntilWhen => 'Fino a quando?';

  @override
  String get planForever => 'Per sempre';

  @override
  String planMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mesi',
      one: '1 mese',
    );
    return '$_temp0';
  }

  @override
  String get planRepeatDone =>
      'Fatto. Lo vedrai nel piano nelle prossime settimane; se un giorno ha già altro, resta così.';

  @override
  String get planWhoAtHome => 'Chi mangia a casa?';

  @override
  String get planCalendarPermission =>
      'Consenti l\'accesso al calendario nelle impostazioni del telefono';

  @override
  String get planInFast => 'Cade durante il digiuno';

  @override
  String get planSettings => 'Impostazioni del piano';

  @override
  String get planBatchCook => 'Cucino in anticipo';

  @override
  String get planBatchCookHint => 'Giorno di spesa, di cucina e contenitori';

  @override
  String get planTimes => 'Orari';

  @override
  String get planFasting => 'Digiuno intermittente';

  @override
  String get no => 'No';

  @override
  String planEatWindow(String from, String to) {
    return 'Mangi dalle $from alle $to. Si sposta con l\'orario della cena.';
  }

  @override
  String get planCalendar => 'Calendario';

  @override
  String get planToCalendar => 'Passa al calendario';

  @override
  String get planCalendarLinked => 'Calendario collegato';

  @override
  String get planCalendarHint =>
      'Pasti e attività con orario, in Google Calendar';

  @override
  String get planCalendarUpdates => 'Si aggiorna aprendo il piano';

  @override
  String get remove => 'Togli';

  @override
  String get planPickRecipe => 'Scegli una ricetta';

  @override
  String get planDayFull => 'Quel giorno ha già tutti i pasti.';

  @override
  String get planWhichMeal => 'Quale pasto aggiungi?';

  @override
  String get planTitle => 'Piano settimanale';

  @override
  String get planNoHome => 'Non fai parte di nessuna casa.';

  @override
  String get planMake => 'Crea piano';

  @override
  String get planRemake => 'Rifai piano';

  @override
  String get planNeedRecipes => 'Aggiungi prima qualche ricetta';

  @override
  String get planNeedRecipesHint =>
      'Il pianificatore distribuisce le tue ricette nella settimana. Salvane qualcuna nella scheda Pasti.';

  @override
  String get planPrevWeek => 'Settimana precedente';

  @override
  String get planNextWeekLabel => 'La prossima settimana';

  @override
  String get planLastWeek => 'La settimana scorsa';

  @override
  String get planWeek => 'Settimana';

  @override
  String get planBackToToday => 'Torna a oggi';

  @override
  String get planNextWeek => 'Settimana successiva';

  @override
  String get planDay => 'Giorno';

  @override
  String get planMonthCalendar => 'Calendario del mese';

  @override
  String get planNoPlanYet => 'Ancora nessun piano per questa settimana.';

  @override
  String get recipe => 'Ricetta';

  @override
  String get planCookMode => 'Modalità cucina';

  @override
  String get planCookWeek => 'Cucina la settimana in una volta';

  @override
  String get planBatch => 'Cucina in anticipo';

  @override
  String planCookDays(int days, int recipes) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days giorni di cucina',
      one: '1 giorno di cucina',
    );
    String _temp1 = intl.Intl.pluralLogic(
      recipes,
      locale: localeName,
      other: '$recipes ricette',
      one: '1 ricetta',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get planBatchEmpty =>
      'Con il piano pronto ti dico quando fare la spesa, quando cucinare e cosa va in frigo o in freezer.';

  @override
  String get planCookedToFreezer => 'Cucinato · in freezer';

  @override
  String planFrozen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count piatti salvati in freezer.',
      one: 'Salvato in freezer con la sua foto.',
    );
    return '$_temp0';
  }

  @override
  String get planEnergyLow => 'Poco';

  @override
  String get planEnergyNormal => 'Normale';

  @override
  String get planEnergyHigh => 'Molto';

  @override
  String get planEnergyHint => 'Con \"poco\" il piano usa di più il freezer.';

  @override
  String get planHowMuchCook => 'Quanto cucinare';

  @override
  String planServings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count porzioni',
      one: '1 porzione',
    );
    return '$_temp0';
  }

  @override
  String get close => 'Chiudi';

  @override
  String get planSearchRecipe => 'Cerca ricetta...';

  @override
  String get planNoMatch => 'Nessuna ricetta corrispondente.';

  @override
  String get diaDeleteError => 'Impossibile eliminare il pasto.';

  @override
  String get diaManual => 'A mano';

  @override
  String get diaManualHint => 'Scrivi il nome e le calorie';

  @override
  String get diaFromRecipe => 'Da una ricetta';

  @override
  String get diaFromRecipeHint => 'Registra una tua ricetta come pasto';

  @override
  String get diaWithPhoto => 'Con una foto';

  @override
  String get diaWithPhotoHint =>
      'Fai una foto al piatto e calcoliamo le calorie';

  @override
  String get diaAddManual => 'Aggiungi a mano';

  @override
  String get diaKcalField => 'Calorie (kcal)';

  @override
  String get diaMealTypeOptional => 'Tipo di pasto (facoltativo)';

  @override
  String get diaNoType => 'Senza tipo';

  @override
  String get diaProteinG => 'Proteine (g)';

  @override
  String get diaCarbsG => 'Carboidrati (g)';

  @override
  String get diaFatG => 'Grassi (g)';

  @override
  String get diaNeedNameKcal => 'Inserisci almeno un nome e le calorie.';

  @override
  String get diaSaveError => 'Impossibile salvare il pasto.';

  @override
  String get diaRecipesLoadError => 'Impossibile caricare le ricette.';

  @override
  String get diaNoRecipes => 'Non hai ancora ricette da registrare.';

  @override
  String diaKcalPerServing(int kcal) {
    return '$kcal kcal a porzione';
  }

  @override
  String get diaNoKcal => 'Nessuna caloria registrata';

  @override
  String get diaServings => 'Porzioni';

  @override
  String get diaServingsError =>
      'Inserisci un numero di porzioni maggiore di 0.';

  @override
  String get diaLog => 'Registra';

  @override
  String get diaRecipeLogError => 'Impossibile registrare la ricetta.';

  @override
  String get diaTitle => 'Il mio diario';

  @override
  String get diaAddMeal => 'Aggiungi pasto';

  @override
  String get previous => 'Precedente';

  @override
  String get next => 'Successivo';

  @override
  String get diaDayCalories => 'Calorie del giorno';

  @override
  String diaOfTarget(int kcal) {
    return 'su $kcal kcal';
  }

  @override
  String get diaNoTarget =>
      'Completa il tuo profilo per fissare un obiettivo calorico giornaliero e vedere quanto ti resta ogni giorno.';

  @override
  String get diaCompleteProfile => 'Completa il mio profilo';

  @override
  String get diaOthers => 'Altri';

  @override
  String get diaMeal => 'Pasto';

  @override
  String get diaLast7 => 'I tuoi ultimi 7 giorni';

  @override
  String diaTargetPerDay(int kcal) {
    return 'Obiettivo: $kcal kcal al giorno';
  }

  @override
  String get diaTarget => 'Obiettivo';

  @override
  String get diaTodaySplit => 'Ripartizione di oggi';

  @override
  String get diaNoMacros => 'Ancora nessun macro registrato oggi.';

  @override
  String get diaProtein => 'Proteine';

  @override
  String get diaCarbs => 'Carboidrati';

  @override
  String get diaFat => 'Grassi';

  @override
  String get diaAteThePlan => 'Hai mangiato quello del piano?';

  @override
  String diaAskLine(String day, String meal, String name, int kcal) {
    return '$day, $meal: $name · $kcal kcal';
  }

  @override
  String get yes => 'Sì';

  @override
  String get diaAnswerError => 'Impossibile salvare la risposta.';

  @override
  String get diaAskFirst => 'Chiedimi prima di registrare il piano';

  @override
  String get diaAskOn => 'Ti chiediamo se hai mangiato ogni pasto del piano.';

  @override
  String get diaAskOff =>
      'I pasti del piano si registrano da soli passata l\'ora.';

  @override
  String get diaSettingError => 'Impossibile salvare l\'impostazione.';

  @override
  String get diaEmpty =>
      'Non hai ancora registrato nulla in questo giorno.\nAggiungi il tuo primo pasto.';

  @override
  String get recUnfavorite => 'Togli dai preferiti';

  @override
  String get recFavorite => 'Segna come preferita';

  @override
  String get recDelete => 'Elimina ricetta';

  @override
  String get recDeleteAsk => 'Eliminare la ricetta?';

  @override
  String recRemoveAsk(String name) {
    return '\"$name\" e i suoi ingredienti verranno eliminati.';
  }

  @override
  String recDeleted(String name) {
    return '\"$name\" eliminata.';
  }

  @override
  String get recTitle => 'Ricette';

  @override
  String get recNew => 'Nuova ricetta';

  @override
  String get recLoadError => 'Non sono riuscito a caricare le ricette';

  @override
  String get recEmptyTitle => 'Ancora nessuna ricetta';

  @override
  String get recEmptyHint => 'Crea la prima o chiedi idee con quello che hai.';

  @override
  String get recIdeas => 'Idee con quello che ho';

  @override
  String get recNoResults => 'Nessun risultato';

  @override
  String recCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ricette',
      one: '1 ricetta',
    );
    return '$_temp0';
  }

  @override
  String get recWhatToCook => 'Cosa cucino con quello che ho?';

  @override
  String get recPantryIdeas => 'Idee con quello che hai in dispensa';

  @override
  String get recAll => 'Tutte';

  @override
  String get recFavorites => 'Preferite';

  @override
  String get recNoFilter =>
      'Nessuna ricetta con questo filtro.\nProva un\'altra categoria.';

  @override
  String get clear => 'Cancella';

  @override
  String recNoMatch(String query) {
    return 'Nessuna ricetta corrisponde a\n\"$query\".';
  }
}
