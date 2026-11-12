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
  String get loginConfirmEmailSent =>
      'Ti abbiamo inviato un\'email per confermare l\'account. Aprila da questo telefono e accederai.';

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
      'Il primo sarà il tuo supermercato principale: cercheremo lì i prodotti della tua lista della spesa.';

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
  String get shopAddDetailed => 'Aggiungi con dettagli';

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
      'I prodotti della tua lista verranno cercati in questo supermercato. Le ricette vanno bene per qualsiasi.';

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
      'hogar': 'Varie',
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
  String get planAddDish => 'Aggiungi un altro piatto';

  @override
  String get planAutoDessert => 'Dolce automatico';

  @override
  String get planAutoDessertHint => 'Il piano aggiunge un dolce a questi pasti';

  @override
  String get planBoughtReady => 'Comprato pronto';

  @override
  String get planBoughtReadyHint =>
      'Un piatto pronto del supermercato, senza cucinare';

  @override
  String get planYourReady => 'I tuoi piatti pronti';

  @override
  String get planReadySearch => 'Cerca al supermercato';

  @override
  String get planReadyEmpty =>
      'Non hai ancora piatti pronti di fiducia. Cercali nel catalogo del supermercato.';

  @override
  String get planReadyMain => 'Piatto';

  @override
  String get planReadyDessert => 'Dolce';

  @override
  String get planReadyKcal => 'Calorie per porzione (facoltativo)';

  @override
  String get planReadyRemove => 'Togli dai tuoi piatti pronti';

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
  String get planEnergyHint =>
      'Con \"poco\" il piano sceglie ricette veloci e usa il congelatore e i tuoi piatti pronti.';

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
  String get recOther => 'Altre';

  @override
  String recSeeAll(int count) {
    return 'Vedi tutte e $count';
  }

  @override
  String get recNoFilter =>
      'Nessuna ricetta con questo filtro.\nProva un\'altra categoria.';

  @override
  String get clear => 'Cancella';

  @override
  String recNoMatch(String query) {
    return 'Nessuna ricetta corrisponde a\n\"$query\".';
  }

  @override
  String get rdPhoto => 'Foto della ricetta';

  @override
  String get rdAutoPhoto => 'Cerca un\'altra foto automatica';

  @override
  String get rdAutoPhotoHint => 'Cerca una nuova immagine dal nome';

  @override
  String get rdGallery => 'Scegli dalla galleria';

  @override
  String get rdNoBetterPhoto => 'Per ora non ho trovato una foto migliore';

  @override
  String get rdUploadError => 'Impossibile caricare la foto';

  @override
  String rdShareText(String title, String code) {
    return 'Ecco la mia ricetta di $title su PrezHome. Nell\'app, vai su Ricette, tocca Aggiungi ricetta e poi Con un codice: $code';
  }

  @override
  String get rdSavedFreezer => 'Salvato in freezer.';

  @override
  String get couldNotSave => 'Impossibile salvare';

  @override
  String get rdVideoError => 'Impossibile aprire il link del video';

  @override
  String get rdWatchVideo => 'Guarda il video';

  @override
  String get share => 'Condividi';

  @override
  String get rdEdit => 'Modifica ricetta';

  @override
  String get rdMinutes => 'Minuti';

  @override
  String get rdKcalServing => 'Kcal/porzione';

  @override
  String get rdPerServingShort => 'a porzione';

  @override
  String rdServingWord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Porzioni',
      one: 'Porzione',
    );
    return '$_temp0';
  }

  @override
  String get rdFreezable => 'Congelabile';

  @override
  String get rdIngredients => 'Ingredienti';

  @override
  String get rdStepsWord => 'Passaggi';

  @override
  String rdSteps(int count) {
    return 'Passaggi ($count)';
  }

  @override
  String get rdNutrition => 'Nutrizione';

  @override
  String get rdNoIngredients => 'Nessun ingrediente registrato.';

  @override
  String rdOriginal(String servings) {
    return 'Ricetta originale: $servings';
  }

  @override
  String rdForHome(String servings) {
    return 'Per la tua casa oggi: $servings';
  }

  @override
  String get rdHaveAll => 'Hai tutto in casa';

  @override
  String rdHaveSome(int have, int total) {
    return 'Hai $have su $total in casa';
  }

  @override
  String rdMissing(int count) {
    return 'Ne mancano $count';
  }

  @override
  String get rdAtHome => 'In casa';

  @override
  String get rdLacking => 'Manca';

  @override
  String get rdNoSteps =>
      'Questa ricetta non ha passaggi. Puoi aggiungerli modificandola.';

  @override
  String get rdPerServingTitle => 'A porzione';

  @override
  String get rdNoNutrition => 'Nessun dato nutrizionale.';

  @override
  String rdPerServing(String amount) {
    return '$amount a porzione';
  }

  @override
  String rdTotal(String amount) {
    return '≈ $amount in totale';
  }

  @override
  String get rdApproxCost =>
      'Costo approssimativo. Scansiona gli scontrini per affinarlo con i tuoi prezzi reali.';

  @override
  String get rdStartCooking => 'Inizia a cucinare';

  @override
  String rdAddedMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Aggiunti $count prodotti alla spesa',
      one: 'Aggiunto alla lista della spesa',
    );
    return '$_temp0';
  }

  @override
  String get rdNeedProfile =>
      'Completa un Profilo nutrizionale per vedere quanti grammi e calorie spettano a ciascuno.';

  @override
  String get rdMember => 'Membro';

  @override
  String get rdAdjustSplit =>
      'Regola la ripartizione delle calorie per pasto nel profilo per questo tipo di ricetta.';

  @override
  String get rdByProfile => 'Secondo il profilo di ciascuno';

  @override
  String get rdByProfileHint =>
      'Quantità e calorie a persona per questo pasto.';

  @override
  String get arWriteName => 'Scrivi il nome';

  @override
  String get arWriteNameHint => 'Scrivi il nome o incolla una ricetta intera…';

  @override
  String get arGenerate => 'Genera';

  @override
  String get arFilled => 'Ricetta compilata. Controllala prima di salvare.';

  @override
  String get arFillError => 'Impossibile completare la ricetta';

  @override
  String get arImport => 'Importa ricetta';

  @override
  String get arPasteRecipe => 'Incolla la ricetta';

  @override
  String get arImportHint =>
      'Incolla il link di TikTok, YouTube o di un sito, o il testo della ricetta. Su Instagram copia la descrizione del post e incollala qui.';

  @override
  String get arLinkOrText => 'Link o testo della ricetta';

  @override
  String get arRecipeText => 'Testo della ricetta';

  @override
  String get paste => 'Incolla';

  @override
  String get arImportBtn => 'Importa';

  @override
  String get arNeedLink => 'Incolla un link o il testo completo della ricetta.';

  @override
  String get arImported => 'Ricetta importata. Controllala prima di salvare.';

  @override
  String get arImportLinkError =>
      'Non sono riuscito a importare la ricetta da quel link';

  @override
  String get arImportError => 'Impossibile importare';

  @override
  String get arPickMealType => 'Scegli almeno un tipo di pasto.';

  @override
  String get arVideoNotUrl =>
      'Il link del video non sembra un URL, ma lo salviamo comunque.';

  @override
  String get arRecalculated => 'Calorie e macro ricalcolate dagli ingredienti.';

  @override
  String arPhotoFailed(String error) {
    return 'Ricetta salvata, ma non è stato possibile caricare la foto: $error';
  }

  @override
  String get arSaveError => 'Errore durante il salvataggio';

  @override
  String get arReadingVideo => 'Leggo la ricetta dal video…';

  @override
  String get arCompleting => 'Completo la ricetta…';

  @override
  String get arAddPhoto => 'Aggiungi foto (facoltativo)';

  @override
  String get arTitleField => 'Titolo';

  @override
  String get arTitleRequired => 'Dagli un titolo';

  @override
  String get arDescription => 'Descrizione (facoltativo)';

  @override
  String get arVideoLink => 'Link del video (facoltativo)';

  @override
  String get arMealTypes => 'Tipo di pasto (puoi sceglierne più di uno)';

  @override
  String get arAuto => 'Auto';

  @override
  String get arServingsHelper => 'Per quante persone';

  @override
  String get arGramsServing => 'Grammi / porzione';

  @override
  String get arNutritionTitle => 'Valori nutrizionali (a porzione)';

  @override
  String get arCooking => 'Cucina';

  @override
  String get arPrepMin => 'Preparazione (min)';

  @override
  String get arCookMin => 'Cottura (min)';

  @override
  String get arAppliance => 'Apparecchio principale';

  @override
  String get arFreezable => 'Si può congelare';

  @override
  String get arAddIngredient => 'Aggiungi ingrediente';

  @override
  String get arStepsTitle => 'Passaggi di preparazione';

  @override
  String get arStepsHint => 'Scrivi i passaggi, uno per riga…';

  @override
  String get arSaveChanges => 'Salva modifiche';

  @override
  String get arSaveRecipe => 'Salva ricetta';

  @override
  String get arIngredient => 'Ingrediente';

  @override
  String get tskWhoDid => 'Chi ha fatto il compito?';

  @override
  String get tskTheHome => 'la casa';

  @override
  String tskPointsFor(int points, String who) {
    return '+$points punti per $who';
  }

  @override
  String tskPointsForPantry(int points, String who, int count) {
    return '+$points punti per $who. $count prodotti in dispensa';
  }

  @override
  String tskYou(String name) {
    return '$name (tu)';
  }

  @override
  String get tskThisMember => 'questo membro';

  @override
  String get tskResetPoints => 'Azzera punti';

  @override
  String tskResetAsk(String name) {
    return 'I punti di $name verranno azzerati. Non si può annullare. Sicuro?';
  }

  @override
  String get tskReset => 'Azzera';

  @override
  String tskResetDone(String name) {
    return 'Punti di $name azzerati.';
  }

  @override
  String get tskDeleteTitle => 'Eliminare il compito?';

  @override
  String tskDeleteAsk(String title) {
    return '\"$title\" verrà eliminato.';
  }

  @override
  String tskClaimed(String title) {
    return '\"$title\" è tuo';
  }

  @override
  String get tskDone => 'Fatto';

  @override
  String get tskToTomorrow => 'Sposta a domani';

  @override
  String get tskToNextWeek => 'Sposta alla prossima settimana';

  @override
  String get tskTitle => 'Compiti';

  @override
  String get tskEmptyTitle => 'Ancora nessun compito';

  @override
  String get tskEmptyHint => 'Aggiungi il primo.';

  @override
  String get tskNew => 'Nuovo compito';

  @override
  String get tskAnyone => 'Chiunque';

  @override
  String get tskForToday => 'Per oggi';

  @override
  String get tskUpcoming => 'Prossimi giorni';

  @override
  String get tskPoolEmpty => 'Niente nel mucchio. Tutto ha un responsabile.';

  @override
  String get tskSwipeToClaim => 'Scorri a sinistra per prenderlo.';

  @override
  String get tskNothingDone => 'Oggi ancora niente di fatto.';

  @override
  String get tskAll => 'Tutti';

  @override
  String get tskMine => 'Miei';

  @override
  String get tskAllDoneToday => 'Oggi è tutto fatto';

  @override
  String get tskNextBelow => 'Il prossimo, qui sotto.';

  @override
  String get tskNothingLeft => 'Non resta niente da fare.';

  @override
  String get tskScoreboard => 'CLASSIFICA';

  @override
  String get tskPointsPerPerson => 'PUNTI PER PERSONA';

  @override
  String get tskNoPoints => 'Ancora nessun punto';

  @override
  String get tskNoPointsHint => 'Completa i compiti per accumulare punti.';

  @override
  String get tskSomeDays => 'Alcuni giorni';

  @override
  String get tskOnce => 'Una volta';

  @override
  String get tskNothingToday => 'Niente per oggi';

  @override
  String get tskAllDone => 'Tutto fatto';

  @override
  String tskLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ne restano $count',
      one: 'Ne resta 1',
    );
    return '$_temp0';
  }

  @override
  String tskOverdueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count in ritardo',
      one: '1 in ritardo',
    );
    return '$_temp0';
  }

  @override
  String tskMarkDone(String title) {
    return 'Segna $title come fatto';
  }

  @override
  String tskClaim(String title) {
    return 'Prendo $title';
  }

  @override
  String get tskOverdue => 'In ritardo';

  @override
  String tskPts(int points) {
    return '$points pt';
  }

  @override
  String tskView(String view) {
    String _temp0 = intl.Intl.selectLogic(view, {
      'pending': 'Da fare',
      'pool': 'Mucchio',
      'other': 'Fatti',
    });
    return '$_temp0';
  }

  @override
  String get tskOtherDay => 'Un altro giorno';

  @override
  String get tskEdit => 'Modifica compito';

  @override
  String get tskNameHint => 'Nome del compito';

  @override
  String get tskOrTypeAnother => 'O scrivine un altro';

  @override
  String get tskWhen => 'Quando';

  @override
  String get tomorrow => 'Domani';

  @override
  String get tskNoDate => 'Senza data';

  @override
  String get tskRepeats => 'Si ripete';

  @override
  String get tskWho => 'Chi';

  @override
  String get tskMe => 'Io';

  @override
  String get tskAddPersonHint =>
      'Per assegnarlo a qualcuno, aggiungi quella persona in Casa (anche senza account).';

  @override
  String get tskDetails => 'Dettagli';

  @override
  String get tskNoTime => 'Senza ora';

  @override
  String get tskRemoveTime => 'Togli ora';

  @override
  String tskFreeAt(String time) {
    return 'Libero alle $time';
  }

  @override
  String get tskNotes => 'Note';

  @override
  String get tskPoints => 'Punti';

  @override
  String get tskAdd => 'Aggiungi compito';

  @override
  String get arcTitle => 'Aggiungi ricetta';

  @override
  String get arcLinkTitle => 'Incolla un link video';

  @override
  String get arcLinkSub => 'Da TikTok o YouTube, o il testo di Instagram';

  @override
  String get arcNameTitle => 'Scrivi il nome';

  @override
  String get arcNameSub => 'Si completa con ingredienti, passaggi e macro';

  @override
  String get arcIdeasTitle => 'Idee per te';

  @override
  String get arcIdeasSub => 'In base a supermercato, obiettivo e budget';

  @override
  String get arcManualTitle => 'A mano';

  @override
  String get arcManualSub => 'Compila tu ogni campo';

  @override
  String get arcCodeTitle => 'Con un codice';

  @override
  String get arcCodeSub => 'Salva una ricetta condivisa con te';

  @override
  String get arcCodeDialog => 'Codice della ricetta';

  @override
  String get search => 'Cerca';

  @override
  String get arcNoCode => 'Nessuna ricetta con questo codice';

  @override
  String arcIngredientsAsk(int count) {
    return '$count ingredienti. La salvi nelle tue ricette?';
  }

  @override
  String get arcSaved => 'Ricetta salvata';

  @override
  String get nutLoadError => 'Impossibile caricare il profilo';

  @override
  String get nutSaved => 'Profilo salvato';

  @override
  String get nutSaveError => 'Errore nel salvataggio';

  @override
  String get nutBirthDate => 'Data di nascita';

  @override
  String get nutTitle => 'Il mio profilo nutrizionale';

  @override
  String get nutDiary => 'Diario delle calorie';

  @override
  String get nutWizard => 'Configura passo dopo passo';

  @override
  String get nutWizardSub =>
      'Un assistente ti fa qualche domanda e calcola il tuo obiettivo.';

  @override
  String get nutHowCook => 'Come cucini?';

  @override
  String get nutDaily => 'Giorno per giorno';

  @override
  String get nutDailySub => 'Cucino ogni giorno';

  @override
  String get nutBatch => 'Cucinare in anticipo';

  @override
  String get nutBatchSub => 'Cucino una volta per più giorni';

  @override
  String get nutAmounts => 'Quantità';

  @override
  String get nutPractical => 'Pratiche';

  @override
  String get nutPracticalSub => 'Formati del supermercato';

  @override
  String get nutExact => 'Esatte';

  @override
  String get nutExactSub => 'Al grammo';

  @override
  String get nutSex => 'Sesso';

  @override
  String get nutFemale => 'Donna';

  @override
  String get nutMale => 'Uomo';

  @override
  String get nutSelect => 'Seleziona…';

  @override
  String nutAge(int age) {
    return '($age anni)';
  }

  @override
  String get nutHeight => 'Altezza (cm)';

  @override
  String get nutWeight => 'Peso (kg)';

  @override
  String get nutActivityLevel => 'Livello di attività';

  @override
  String get nutGoalLabel => 'Obiettivo';

  @override
  String nutActivity(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'sedentary': 'Sedentario (poco o nessun esercizio)',
      'light': 'Leggero (1-3 giorni/settimana)',
      'moderate': 'Moderato (3-5 giorni/settimana)',
      'active': 'Attivo (6-7 giorni/settimana)',
      'other': 'Molto attivo (esercizio intenso o lavoro fisico)',
    });
    return '$_temp0';
  }

  @override
  String nutGoal(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'lose': 'Perdere peso',
      'gain': 'Aumentare di peso',
      'other': 'Mantenere il peso',
    });
    return '$_temp0';
  }

  @override
  String get nutSplit => 'Calorie per pasto';

  @override
  String nutTotal(int pct) {
    return 'Totale: $pct%';
  }

  @override
  String get nutSplitHint =>
      'Metti 0% ai pasti che salti. Il totale dovrebbe essere 100%.';

  @override
  String get nutAtHome => 'Pasti a casa';

  @override
  String get nutAtHomeHint =>
      'Segna i giorni in cui fai ogni pasto a casa. Se mangi fuori (es. al lavoro), togli quel giorno e non verrà contato.';

  @override
  String get nutShare => 'Condividi il mio profilo con la casa';

  @override
  String get nutShareSub => 'Se disattivato, il tuo profilo è privato.';

  @override
  String get nutSave => 'Salva profilo';

  @override
  String get nutIncomplete =>
      'Completa sesso, data di nascita, altezza e peso per calcolare calorie e macro giornalieri.';

  @override
  String get nutDailyTarget => 'Il tuo obiettivo giornaliero (circa)';

  @override
  String nutKcalDay(int kcal) {
    return '$kcal kcal / giorno';
  }

  @override
  String nutPerMeal(int kcal, int meals) {
    return '≈ $kcal kcal per pasto ($meals pasti)';
  }

  @override
  String get ecoBudgetTitle => 'Budget mensile';

  @override
  String ecoAmount(String symbol) {
    return 'Importo ($symbol)';
  }

  @override
  String get ecoDeleteTicket => 'Eliminare lo scontrino?';

  @override
  String get ecoDeleteTicketSub => 'Non conterà più nelle tue spese.';

  @override
  String ecoRedeemed(String title) {
    return 'Hai riscattato \"$title\"';
  }

  @override
  String get ecoRedeemFail =>
      'Impossibile riscattare. Forse non hai abbastanza punti.';

  @override
  String get ecoNewReward => 'Nuova ricompensa';

  @override
  String get ecoRewardTitle => 'Titolo';

  @override
  String get ecoRewardDesc => 'Descrizione (facoltativa)';

  @override
  String get ecoRewardCost => 'Costo in punti';

  @override
  String get ecoTitle => 'Spese e scontrini';

  @override
  String get ecoStats => 'Statistiche della spesa';

  @override
  String get ecoScan => 'Scansiona scontrino';

  @override
  String ecoTicketsOf(String month) {
    return 'Scontrini di $month';
  }

  @override
  String get ecoPointsBalance => 'Bilancia dei punti';

  @override
  String get ecoPointsBalanceSub =>
      'Saldo di ogni membro per riscattare ricompense.';

  @override
  String get ecoNoPoints => 'Ancora nessun punto da distribuire';

  @override
  String get ecoNoPointsSub =>
      'Completate i compiti di casa per riempire la bilancia.';

  @override
  String get ecoRewards => 'Ricompense';

  @override
  String ecoBalance(int points) {
    return 'Il tuo saldo: $points pt';
  }

  @override
  String get ecoRedeem => 'Riscatta';

  @override
  String get ecoNoRewards => 'Ancora nessuna ricompensa';

  @override
  String get ecoNoRewardsSub =>
      'Crea la prima con il pulsante \"Nuova ricompensa\".';

  @override
  String get ecoTotalSpent => 'Spesa totale registrata';

  @override
  String ecoTicketCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count scontrini in totale',
      one: '1 scontrino in totale',
    );
    return '$_temp0';
  }

  @override
  String get ecoThisMonth => 'Questo mese';

  @override
  String ecoBudget(String amount) {
    return 'Budget: $amount';
  }

  @override
  String get ecoSetBudget => 'Imposta budget';

  @override
  String ecoOver(String amount) {
    return 'Hai superato il budget di $amount';
  }

  @override
  String ecoLeft(String amount) {
    return 'Ti restano $amount';
  }

  @override
  String get ecoLastMonths => 'Spesa degli ultimi mesi';

  @override
  String ecoBudgetPerMonth(String amount) {
    return 'Budget: $amount al mese';
  }

  @override
  String get ecoBudgetShort => 'Budget';

  @override
  String get ecoNoTrend =>
      'Ancora nessuna spesa negli ultimi mesi.\nScansiona scontrini per vedere qui il tuo andamento.';

  @override
  String get ecoTicket => 'Scontrino';

  @override
  String get ecoNoTickets =>
      'Ancora nessuno scontrino questo mese.\nScansiona il primo.';

  @override
  String get stOthers => 'Altri';

  @override
  String get stNoCategory => 'Senza categoria';

  @override
  String get stThisWeek => 'Questa';

  @override
  String get stTitle => 'I tuoi dati';

  @override
  String get stSpendByMonth => 'Spesa per mese';

  @override
  String get stForecastFooter => 'In chiaro, quanto manca alla previsione';

  @override
  String get stNoSpend =>
      'Scansiona uno scontrino per vedere la spesa mese per mese.';

  @override
  String get stWhereSpend => 'In cosa spendi questo mese';

  @override
  String get stNoTicketsMonth => 'Ancora nessuno scontrino questo mese.';

  @override
  String get stTopProducts => 'Cosa compri di più';

  @override
  String get stTopProductsFooter =>
      'Volte nei tuoi scontrini degli ultimi 3 mesi';

  @override
  String get stTopProductsEmpty => 'Comparirà quando scansionerai scontrini.';

  @override
  String get stPantry => 'La tua dispensa';

  @override
  String get stMealsHome => 'Pasti a casa';

  @override
  String get stPerWeek => 'Per settimana';

  @override
  String stMealsOut(int count) {
    return 'Per settimana · $count fuori casa';
  }

  @override
  String get stMealsEmpty =>
      'Pianifica i pasti per vedere quanti ne fate a casa.';

  @override
  String get stTasksDone => 'Compiti fatti';

  @override
  String get stTasksFooter =>
      'Per settimana e chi ne ha fatti di più questo mese';

  @override
  String get stTasksEmpty => 'I compiti completati appariranno qui.';

  @override
  String get stSoFar => 'Speso finora questo mese';

  @override
  String get stForecast => 'Previsione: ';

  @override
  String stMoreThanAvg(int pct) {
    return ', il $pct% in più della tua media';
  }

  @override
  String stLessThanAvg(int pct) {
    return ', il $pct% in meno della tua media';
  }

  @override
  String get stTickets => 'Scontrini';

  @override
  String get stExpired => 'Scaduto';

  @override
  String get stExpiringSoon => 'Scade presto';

  @override
  String get stFresh => 'Ok';

  @override
  String stOverForecast(String amount) {
    return 'Di questo passo supererai il budget di $amount';
  }

  @override
  String stForecastTip(String amount) {
    return 'Previsione $amount';
  }

  @override
  String get pwPickOption => 'Scegli un\'opzione per continuare.';

  @override
  String get pwPickBirth => 'Seleziona la tua data di nascita.';

  @override
  String get pwBadHeight => 'Inserisci un\'altezza valida in centimetri.';

  @override
  String get pwBadWeight => 'Inserisci un peso valido in chili.';

  @override
  String get pwCompleteStep => 'Completa questo passaggio per continuare.';

  @override
  String get pwStart => 'Inizia a usare PrezHome';

  @override
  String get pwSeeGoal => 'Vedi il mio obiettivo';

  @override
  String get pwFinish => 'Fine';

  @override
  String get pwIntroTitle => 'Conosciamoci';

  @override
  String get pwIntroSub =>
      'Qualche domanda veloce per adattare PrezHome a te. Puoi cambiarlo quando vuoi.';

  @override
  String get pwTrackKcal => 'Voglio contare le calorie';

  @override
  String get pwTrackKcalSub => 'I pasti del piano si registrano da soli dopo.';

  @override
  String get pwOnlyHome => 'Solo organizzare la casa';

  @override
  String get pwOnlyHomeSub => 'Senza peso né misure.';

  @override
  String get pwSex => 'Il tuo sesso';

  @override
  String get pwSexSub =>
      'Lo usiamo per calcolare il tuo metabolismo con più precisione.';

  @override
  String get pwPickDate => 'Seleziona data';

  @override
  String get pwBirthTitle => 'Quando sei nato/a?';

  @override
  String get pwBirthSub => 'L\'età ci aiuta a calcolare meglio le calorie.';

  @override
  String pwAgeYears(int age) {
    return '$age anni';
  }

  @override
  String get pwHeightTitle => 'Quanto sei alto/a?';

  @override
  String get pwHeightSub => 'Indica la tua altezza in centimetri.';

  @override
  String get pwWeightTitle => 'Quanto pesi?';

  @override
  String get pwWeightSub => 'Indica il tuo peso attuale in chili.';

  @override
  String get pwActivityTitle => 'Il tuo livello di attività';

  @override
  String get pwActivitySub =>
      'Scegli l\'opzione che descrive meglio la tua settimana.';

  @override
  String get pwGoalTitle => 'Qual è il tuo obiettivo?';

  @override
  String get pwGoalSub => 'Adatteremo le calorie a ciò che vuoi ottenere.';

  @override
  String pwGoalDesc(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'lose': 'Deficit leggero per perdere peso poco a poco.',
      'gain': 'Surplus leggero per aumentare massa in modo sano.',
      'other': 'Mantenere il peso attuale e stare bene.',
    });
    return '$_temp0';
  }

  @override
  String get pwDietTitle => 'Come ti alimenti?';

  @override
  String get pwDietSub => 'Le ricette si adatteranno alla tua dieta.';

  @override
  String pwDiet(String diet) {
    String _temp0 = intl.Intl.selectLogic(diet, {
      'vegetariana': 'Vegetariana',
      'vegana': 'Vegana',
      'pescetariana': 'Pescetariana',
      'baja_carbo': 'Low carb',
      'sin_gluten': 'Senza glutine',
      'other': 'Di tutto',
    });
    return '$_temp0';
  }

  @override
  String get pwAllergiesTitle => 'Allergie o intolleranze';

  @override
  String get pwOptional => 'Facoltativo.';

  @override
  String pwAllergy(String allergy) {
    String _temp0 = intl.Intl.selectLogic(allergy, {
      'frutossecos': 'frutta secca',
      'lactosa': 'lattosio',
      'gluten': 'glutine (celiachia)',
      'huevo': 'uovo',
      'marisco': 'frutti di mare',
      'soja': 'soia',
      'other': 'pesce',
    });
    return '$_temp0';
  }

  @override
  String get pwCuisinesTitle => 'Cosa ti piace mangiare?';

  @override
  String get pwCuisinesSub => 'Scegli quelle che vuoi.';

  @override
  String pwCuisine(String cuisine) {
    String _temp0 = intl.Intl.selectLogic(cuisine, {
      'casera': 'Casalinga',
      'mediterranea': 'Mediterranea',
      'ligera': 'Leggera',
      'rapida': 'Veloce e semplice',
      'italiana': 'Italiana',
      'asiatica': 'Asiatica',
      'mexicana': 'Messicana',
      'other': 'Da tutto il mondo',
    });
    return '$_temp0';
  }

  @override
  String get pwAppliancesTitle => 'Cosa hai in cucina?';

  @override
  String get pwAppliancesSub => 'Il piano userà solo ricette che puoi fare.';

  @override
  String appliance(String appliance) {
    String _temp0 = intl.Intl.selectLogic(appliance, {
      'oven': 'Forno',
      'stovetop': 'Padella',
      'pot': 'Pentola',
      'airfryer': 'Friggitrice ad aria',
      'microwave': 'Microonde',
      'blender': 'Frullatore',
      'other': 'Nessuno',
    });
    return '$_temp0';
  }

  @override
  String get pwDislikedTitle => 'Ingredienti che non ti piacciono';

  @override
  String get pwDislikedSub => 'Separati da virgole. Facoltativo.';

  @override
  String get pwDislikedHint => 'cipolla, coriandolo...';

  @override
  String get pwCookTimeTitle => 'Quanto tempo vuoi cucinare?';

  @override
  String get pwCookTimeSub =>
      'Così adatto le ricette al tuo ritmo. Puoi lasciarlo vuoto.';

  @override
  String pwCookTime(String time) {
    String _temp0 = intl.Intl.selectLogic(time, {
      'rapido': 'Veloce (meno di 20 min)',
      'elaborado': 'Elaborato (mi piace cucinare)',
      'other': 'Normale',
    });
    return '$_temp0';
  }

  @override
  String pwCookTimeDesc(String time) {
    String _temp0 = intl.Intl.selectLogic(time, {
      'rapido': 'Piatti pronti in poco tempo.',
      'elaborado': 'Mi piace cucinare con calma.',
      'other': 'Un equilibrio tra veloce ed elaborato.',
    });
    return '$_temp0';
  }

  @override
  String get pwCookStyleTitle => 'Come preferisci cucinare?';

  @override
  String get pwChangeAnytime => 'Puoi cambiarlo quando vuoi.';

  @override
  String cookStyle(String style) {
    String _temp0 = intl.Intl.selectLogic(style, {
      'batch': 'In anticipo',
      'mixed': 'Misto',
      'other': 'Giornaliero',
    });
    return '$_temp0';
  }

  @override
  String cookStyleSub(String style) {
    String _temp0 = intl.Intl.selectLogic(style, {
      'batch': 'Cucino in blocco per più giorni',
      'mixed': 'Alterno cucina in blocco e del giorno',
      'other': 'Cucino ogni giorno al momento',
    });
    return '$_temp0';
  }

  @override
  String get pwModulesTitle => 'Cosa vuoi attivare?';

  @override
  String get pwModulesSub => 'Ciò che disattivi non verrà mostrato.';

  @override
  String homeModule(String module) {
    String _temp0 = intl.Intl.selectLogic(module, {
      'points': 'Modalità punti',
      'tasks': 'Compiti',
      'other': 'Cucina in anticipo',
    });
    return '$_temp0';
  }

  @override
  String homeModuleDesc(String module) {
    String _temp0 = intl.Intl.selectLogic(module, {
      'points': 'Guadagna punti e ricompense per i tuoi compiti.',
      'tasks': 'Organizza i compiti di casa.',
      'other': 'Cucina in blocco e pianifica le preparazioni.',
    });
    return '$_temp0';
  }

  @override
  String get pwAllSet => 'Tutto pronto';

  @override
  String get pwAllSetSub =>
      'Ricette, piano e spesa si adattano a ciò che hai detto.';

  @override
  String get pwDailyGoal => 'Il tuo obiettivo giornaliero';

  @override
  String get pwKcalDay => 'kcal / giorno';

  @override
  String get pwEstimate =>
      'È una stima per iniziare. I pasti del piano si registreranno da soli nel diario dopo.';

  @override
  String get phCantAnalyze => 'Impossibile analizzare il pasto';

  @override
  String phAnalyzeError(String error) {
    return 'Errore nell\'analisi della foto: $error';
  }

  @override
  String get phAnalyzeFail => 'Errore nell\'analisi della foto';

  @override
  String get phAddOne => 'Aggiungi almeno un alimento con nome.';

  @override
  String get phTitle => 'Registra con foto';

  @override
  String get phLooking => 'Guardo il piatto…';

  @override
  String get phStartTitle => 'Fai una foto al tuo piatto';

  @override
  String get phStartSub =>
      'Calcoliamo alimenti e calorie. Potrai correggere prima di salvare.';

  @override
  String get takePhoto => 'Scatta foto';

  @override
  String get phReview => 'Controlla e correggi ciò che è stato rilevato';

  @override
  String get phApprox => 'Le calorie sono approssimative.';

  @override
  String get phMealType => 'Pasto (facoltativo)';

  @override
  String get phNoType => 'Nessuno';

  @override
  String get day => 'Giorno';

  @override
  String get phNothing => 'Nessun alimento riconosciuto. Aggiungili a mano.';

  @override
  String phFoods(int count) {
    return 'ALIMENTI ($count)';
  }

  @override
  String get phAddFood => 'Aggiungi alimento';

  @override
  String get phFood => 'Alimento';

  @override
  String get phGrams => 'g (circa)';

  @override
  String get phP => 'P (g)';

  @override
  String get phC => 'C (g)';

  @override
  String get phF => 'G (g)';

  @override
  String get total => 'Totale';

  @override
  String kcalAmount(int kcal) {
    return '$kcal kcal';
  }

  @override
  String get phSave => 'Salva nel diario';

  @override
  String get stkOpenError => 'Impossibile aprire lo scontrino';

  @override
  String get stkReadError => 'Impossibile leggere lo scontrino';

  @override
  String get stkScanError => 'Errore di scansione';

  @override
  String get stkPantryError =>
      'Scontrino salvato, ma non è stato possibile aggiornare la dispensa';

  @override
  String stkCrossed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count prodotti spuntati dalla lista',
      one: '1 prodotto spuntato dalla lista',
    );
    return '$_temp0';
  }

  @override
  String get stkEdit => 'Modifica scontrino';

  @override
  String get stkReading => 'Leggo lo scontrino…';

  @override
  String get stkStartTitle => 'Scansiona lo scontrino della spesa';

  @override
  String get stkStartSub =>
      'Estraiamo prodotti e prezzi. Potrai controllare dopo.';

  @override
  String get stkReview => 'Controlla e correggi se serve';

  @override
  String get stkRemember =>
      'Le tue correzioni verranno ricordate la prossima volta.';

  @override
  String get stkStore => 'Negozio';

  @override
  String get date => 'Data';

  @override
  String get stkAddPantry => 'Aggiungi alla dispensa';

  @override
  String get stkAddPantrySub => 'Ogni prodotto va al suo posto';

  @override
  String stkProducts(int count) {
    return 'PRODOTTI ($count)';
  }

  @override
  String stkRaw(String name) {
    return 'Scontrino: \"$name\"';
  }

  @override
  String get category => 'Categoria';

  @override
  String get stkQty => 'Q.tà';

  @override
  String get stkSave => 'Salva scontrino';

  @override
  String foodCategory(String cat) {
    String _temp0 = intl.Intl.selectLogic(cat, {
      'verdura': 'Verdure',
      'fruta': 'Frutta',
      'carne': 'Carne',
      'pescado': 'Pesce',
      'lacteos': 'Latticini',
      'preparados': 'Piatti pronti',
      'panaderia': 'Panetteria',
      'cereales': 'Pasta, riso e legumi',
      'conservas': 'Conserve',
      'congelados': 'Surgelati',
      'dulces': 'Dolci e snack',
      'bebidas': 'Bevande',
      'especias': 'Spezie e condimenti',
      'higiene': 'Igiene',
      'limpieza': 'Pulizia',
      'hogar': 'Casa',
      'other': 'Altro',
    });
    return '$_temp0';
  }

  @override
  String get cookMode => 'Modalità cucina';

  @override
  String get bpMeanwhile => 'Nel frattempo';

  @override
  String bpTapers(String title) {
    return 'Contenitori · $title';
  }

  @override
  String get bpBatchCook => 'Cucina in blocco';

  @override
  String get bpStart => 'Inizia passo dopo passo';

  @override
  String bpHeroTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ricette in una volta',
      one: '1 ricetta in una volta',
    );
    return '$_temp0';
  }

  @override
  String bpSteps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count passi',
      one: '1 passo',
    );
    return '$_temp0';
  }

  @override
  String get bpStepsTitle => 'Come andrà';

  @override
  String get bpCooking => 'Cosa cucinerai';

  @override
  String get cmTimer => 'Timer';

  @override
  String cmIngredientsReady(int done, int total) {
    return '$done di $total pronti';
  }

  @override
  String get bpEmpty => 'Niente da cucinare adesso';

  @override
  String get bpEmptySub =>
      'Quando avrai ricette pianificate, qui ti preparerò un piano per fare tutto in una volta.';

  @override
  String get bpNeed => 'Cosa ti serve';

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String get ready => 'Pronto';

  @override
  String get pause => 'Pausa';

  @override
  String get start => 'Avvia';

  @override
  String get reset => 'Azzera';

  @override
  String cmStep(int n) {
    return 'Passo $n';
  }

  @override
  String get cmTime => 'Tempo scaduto';

  @override
  String get cmSeeStep => 'Vedi passo';

  @override
  String get ok => 'Ok';

  @override
  String get cmMicPermission =>
      'Per usare la voce, consenti il microfono nelle Impostazioni.';

  @override
  String get ingredients => 'Ingredienti';

  @override
  String get cmExit => 'Esci dalla modalità cucina';

  @override
  String get cmHandsFreeOff => 'Disattiva vivavoce';

  @override
  String get cmHandsFree => 'Vivavoce';

  @override
  String get cmVoiceHint =>
      'Di\' «siguiente», «anterior», «repite» o «temporizador» (per ora la voce è in spagnolo)';

  @override
  String get cmStop => 'Ferma';

  @override
  String cmStepOf(int n, int total) {
    return 'PASSO $n DI $total';
  }

  @override
  String get cmTimerRunning => 'Timer in corso';

  @override
  String get cmThen => 'Poi';

  @override
  String get cmNextStep => 'Passo successivo';

  @override
  String get shopSugDue => 'Da ricomprare';

  @override
  String get shopSugOut => 'Manca in casa';

  @override
  String get shopOutAtHome => 'Finito in casa';

  @override
  String get shopGridView => 'Vista a griglia';

  @override
  String get shopGridHint => 'Foto grandi, due per riga';

  @override
  String get shopShowSuggestions => 'Mostra suggerimenti';

  @override
  String get shopSuggestionsHint => 'Cosa ricomprare e cosa è finito in casa';

  @override
  String get shopShowPrices => 'Mostra prezzi';

  @override
  String shopEveryDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Ogni $n giorni',
      one: 'Ogni giorno',
    );
    return '$_temp0';
  }

  @override
  String get slNewList => 'Nuova lista';

  @override
  String get slMyLists => 'Le mie liste';

  @override
  String get slActive => 'Attiva';

  @override
  String get slNewCat => 'Nuova categoria';

  @override
  String get slRenameCat => 'Rinomina categoria';

  @override
  String get slCategories => 'Categorie';

  @override
  String get slAddCat => 'Aggiungi categoria';

  @override
  String get slNoCats =>
      'Ancora nessuna categoria. Aggiungi la prima con il pulsante qui sotto.';

  @override
  String get rename => 'Rinomina';

  @override
  String ppDayMeals(String day, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pasti',
      one: '1 pasto',
    );
    return '$day, $_temp0';
  }

  @override
  String ppFastTime(String time) {
    return '$time · Digiuno';
  }

  @override
  String get ppEatOut => '· Fuori';

  @override
  String mealAdd(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'breakfast': 'Aggiungi colazione',
      'lunch': 'Aggiungi pranzo',
      'snack': 'Aggiungi merenda',
      'dinner': 'Aggiungi cena',
      'dessert': 'Aggiungi dolce',
      'other': 'Aggiungi pasto',
    });
    return '$_temp0';
  }

  @override
  String get ppFromFreezer => 'Dal congelatore';

  @override
  String ppServings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count porz.',
      one: '1 porzione',
    );
    return '$_temp0';
  }

  @override
  String get ppFresh => 'Appena fatto';

  @override
  String ppFridge(String days) {
    return 'Frigo · $days';
  }

  @override
  String ppFreezer(String days) {
    return 'Congelatore · $days';
  }

  @override
  String get ppTapersAuto =>
      'I contenitori si aggiungono da soli in La mia cucina';

  @override
  String drGoal(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'lose': 'Perdere grasso',
      'gain': 'Aumentare muscoli',
      'protein': 'Ricco di proteine',
      'other': 'Mantenere',
    });
    return '$_temp0';
  }

  @override
  String drDiet(String diet) {
    String _temp0 = intl.Intl.selectLogic(diet, {
      'veg': 'Vegetariana',
      'vegan': 'Vegana',
      'quick': 'Veloce',
      'lowcarb': 'Pochi carboidrati',
      'other': 'Nessuna restrizione',
    });
    return '$_temp0';
  }

  @override
  String drFreeOf(String allergen) {
    String _temp0 = intl.Intl.selectLogic(allergen, {
      'gluten': 'Senza glutine (celiachia)',
      'lactosa': 'Senza lattosio',
      'huevo': 'Senza uova',
      'marisco': 'Senza frutti di mare',
      'soja': 'Senza soia',
      'other': 'Senza frutta secca',
    });
    return '$_temp0';
  }

  @override
  String get drAnyType => 'Qualsiasi';

  @override
  String get drNoIdeas => 'Nessuna idea ricevuta';

  @override
  String get drSaved => 'Salvata nelle tue ricette';

  @override
  String get drSearchSuper => 'Cerca supermercato...';

  @override
  String get drNoSuper => 'Non troviamo quel supermercato.';

  @override
  String get drTitlePantry => 'Cosa cucino con questo?';

  @override
  String get drTitle => 'Idee personalizzate';

  @override
  String get drNewIdeas => 'Nuove idee';

  @override
  String get drWithPantry => 'Con quello che ho';

  @override
  String get drPantryLoading => 'Guardiamo la tua dispensa…';

  @override
  String get drPantryEmpty =>
      'La tua dispensa è vuota: aggiungi quello che hai in casa per ricevere idee.';

  @override
  String drPantryUse(int count) {
    return 'Useremo $count alimenti della tua dispensa, iniziando da quelli che scadono prima.';
  }

  @override
  String get drCraving => 'Cosa ti va?';

  @override
  String get drSupers => 'Supermercati';

  @override
  String get drSupersHint =>
      'Facoltativo. Se non ne scegli nessuno, le ricette vanno bene per qualsiasi supermercato.';

  @override
  String get drGoalTitle => 'Obiettivo';

  @override
  String get drDietTitle => 'Dieta';

  @override
  String drDietLocked(String diet) {
    return 'Usiamo la dieta del tuo profilo: $diet';
  }

  @override
  String get drAllergyTitle => 'Intolleranze e allergie';

  @override
  String get drAllergyHint => 'Non compariranno mai nelle ricette.';

  @override
  String get drAppliances => 'Elettrodomestici';

  @override
  String get drMaxCost => 'Costo massimo per porzione';

  @override
  String get drMaxCostHint => 'Facoltativo, es. 2,50';

  @override
  String get drSearching => 'Cerco idee…';

  @override
  String get drSeeIdeas => 'Vedi idee';

  @override
  String drAddedToShop(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count prodotti aggiunti alla spesa',
      one: 'Aggiunto alla lista della spesa',
    );
    return '$_temp0';
  }

  @override
  String get drAddFail =>
      'Impossibile aggiungere alla spesa. Controlla la connessione e riprova.';

  @override
  String drProteinShort(String grams) {
    return 'P: ${grams}g';
  }

  @override
  String get drCostTip =>
      'Indicativo: prezzi dei tuoi scontrini o, altrimenti, prezzi medi del supermercato.';

  @override
  String drPerServing(String price) {
    return '≈ $price/porzione';
  }

  @override
  String get drHave => 'Hai:';

  @override
  String get drMissing => 'Ti manca:';

  @override
  String get drAddedShort => 'Aggiunto alla spesa';

  @override
  String get drAddMissing => 'Aggiungi ciò che manca';

  @override
  String get drSavedShort => 'Salvata';

  @override
  String get drSaveToRecipes => 'Salva nelle mie ricette';

  @override
  String taskKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'bano': 'Bagno',
      'ropa': 'Bucato',
      'compra': 'Spesa',
      'basura': 'Spazzatura',
      'platos': 'Piatti',
      'limpieza': 'Pulizie',
      'plantas': 'Piante',
      'cama': 'Letto',
      'mascota': 'Animale',
      'cocinar': 'Cucinare',
      'pagos': 'Pagamenti',
      'other': 'Attività',
    });
    return '$_temp0';
  }

  @override
  String taskPreset(String preset) {
    String _temp0 = intl.Intl.selectLogic(preset, {
      'dishes': 'Lavare i piatti',
      'vacuum': 'Passare l\'aspirapolvere',
      'bathroom': 'Pulire il bagno',
      'laundry': 'Fare il bucato',
      'trash': 'Portare fuori la spazzatura',
      'shopping': 'Fare la spesa',
      'plants': 'Annaffiare le piante',
      'other': 'Cambiare le lenzuola',
    });
    return '$_temp0';
  }

  @override
  String get recQuick => 'Veloci';

  @override
  String get recLight => 'Leggere';

  @override
  String get recFreezer => 'Congelabili';

  @override
  String get recSearchHint => 'Cerca per nome o ingrediente';

  @override
  String get recSort => 'Ordina';

  @override
  String get recSortRecent => 'Più recenti';

  @override
  String get recSortAz => 'Dalla A alla Z';

  @override
  String get recSortFastest => 'Più veloci prima';

  @override
  String get recSortLightest => 'Meno calorie prima';

  @override
  String get recClearFilters => 'Togli filtri';

  @override
  String get recMore => 'Altro';

  @override
  String get recLess => 'Meno';

  @override
  String get planBusyAware => 'Organizza secondo il mio calendario';

  @override
  String get planBusyAwareHint =>
      'Nei giorni pieni ricette veloci o dal congelatore, si cucina nel giorno più libero e le attività senza orario vanno in un momento libero. Si applica quando fai il piano.';

  @override
  String get planBusyDay => 'Giornata piena';

  @override
  String get nutAlternate => 'A giorni alterni';

  @override
  String get nutAlternateSub =>
      'Cucino di più e il giorno dopo mangio gli avanzi';

  @override
  String get planHowYouCook => 'Come cucini';

  @override
  String get planModeDaily => 'Ogni giorno';

  @override
  String get planModeAlternate => 'Ogni 2 giorni';

  @override
  String get planModeBatch => 'In lotto';

  @override
  String get planLeftoverMeals => 'Cosa si ripete il giorno dopo';

  @override
  String get planLeftover => 'Avanzi di ieri';

  @override
  String get planOldTapersTitle => 'Contenitori del piano precedente';

  @override
  String planOldTapersBody(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ci sono $count contenitori',
      one: 'c\'è 1 contenitore',
    );
    return 'In frigo $_temp0 che il nuovo piano non usa più: $names. Li togli da La mia cucina?';
  }

  @override
  String get planOldTapersKeep => 'Lasciali';

  @override
  String get hhCreateError => 'Impossibile creare la casa';

  @override
  String get hhJoinTitle => 'Unisciti a una casa';

  @override
  String get hhInviteCode => 'Codice di invito';

  @override
  String get hhJoin => 'Unisciti';

  @override
  String get hhCodeFormat => 'Il codice ha 8 lettere e numeri';

  @override
  String get hhCodeInvalid => 'Codice non valido o scaduto';

  @override
  String get hhCodeCreateError => 'Impossibile creare il codice';

  @override
  String get hhThisMember => 'questo membro';

  @override
  String hhRemoveMemberTitle(String name) {
    return 'Togliere $name dalla casa?';
  }

  @override
  String get hhRemoveMemberBody =>
      'Non vedrà più la spesa, la dispensa e il piano.';

  @override
  String get hhRemoveError => 'Impossibile togliere';

  @override
  String get hhAddGuestTitle => 'Aggiungi persona senza account';

  @override
  String get hhAddGuestBody =>
      'Per qualcuno di casa che non usa l\'app. Potrai assegnargli compiti e segnare quelli che fa.';

  @override
  String get hhAddError => 'Impossibile aggiungere';

  @override
  String hhRemoveGuestTitle(String name) {
    return 'Togliere $name?';
  }

  @override
  String get hhRemoveGuestBody =>
      'I suoi punti verranno cancellati e i suoi compiti resteranno senza assegnatario.';

  @override
  String get hhLeaveTitle => 'Uscire dalla casa?';

  @override
  String get hhLeaveBody =>
      'Non vedrai più i suoi dati. Per tornare ti servirà un nuovo codice.';

  @override
  String get hhLeave => 'Esci';

  @override
  String get hhLeaveError => 'Impossibile uscire dalla casa';

  @override
  String get hhNameTitle => 'Nome della casa';

  @override
  String get hhRenameError => 'Impossibile rinominare';

  @override
  String get hhDeleteAccountTitle => 'Eliminare il tuo account?';

  @override
  String get hhDeleteAccountBody =>
      'Verranno cancellati il tuo account e i tuoi dati. Se sei l\'unica persona della casa, anche la casa. Non si può annullare.';

  @override
  String get hhDeleteConfirm => 'Elimina';

  @override
  String get hhDeleteAccountError => 'Impossibile eliminare l\'account';

  @override
  String get hhDeleteAccount => 'Elimina il mio account';

  @override
  String get hhMyHome => 'La mia casa';

  @override
  String get hhSignOut => 'Esci';

  @override
  String get hhNoHome => 'Non fai ancora parte di nessuna casa.';

  @override
  String get hhCreateHome => 'Crea una nuova casa';

  @override
  String get hhJoinExisting => 'Unisciti a una casa esistente';

  @override
  String get hhRename => 'Rinomina casa';

  @override
  String hhPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Una casa di $count persone.',
      one: 'La tua casa, per ora solo per te.',
    );
    return '$_temp0';
  }

  @override
  String hhMembers(int count) {
    return 'Membri ($count)';
  }

  @override
  String get hhAdmin => 'Amministratore';

  @override
  String get hhRemoveFromHome => 'Togli dalla casa';

  @override
  String get hhYou => 'Tu';

  @override
  String get hhNoAccount => 'Senza account';

  @override
  String get hhLeaveHome => 'Esci dalla casa';

  @override
  String get hhSettings => 'Casa e impostazioni';

  @override
  String get hhAppearance => 'Aspetto';

  @override
  String get hhPhoneAlerts => 'Avvisi sul telefono';

  @override
  String get hhYourData => 'I tuoi dati';

  @override
  String get hhYourDataSub => 'Grafici di spesa, acquisti, cucina e compiti';

  @override
  String get hhExpenses => 'Spese e scontrini';

  @override
  String get hhExpensesSub => 'Budget, scontrini scansionati e spesa mensile';

  @override
  String get hhYourPlan => 'Il tuo piano';

  @override
  String get hhYourPlanSub => 'Utilizzi rimasti questo mese';

  @override
  String get hhNutrition => 'Il mio profilo nutrizionale';

  @override
  String get hhNutritionSub => 'Obiettivo calorico, preferenze e assistente';

  @override
  String get hhInvite => 'Invita qualcuno';

  @override
  String get hhCreateCode => 'Crea codice';

  @override
  String get hhCopy => 'Copia';

  @override
  String get hhCodeCopied => 'Codice copiato';

  @override
  String hhValidUntil(String date) {
    return 'Valido fino al $date';
  }

  @override
  String get hhNewCode => 'Nuovo codice';

  @override
  String get hhChoose => 'Scegli';

  @override
  String get hhSupersHint =>
      'Le ricette si adatteranno a ciò che c\'è nei tuoi supermercati. Facoltativo.';

  @override
  String get hhNoSuper => 'Nessun supermercato scelto.';

  @override
  String get hhCountryError => 'Impossibile cambiare paese';

  @override
  String get hhWhereShop => 'Dove fate la spesa?';

  @override
  String get hhPickMany => 'Puoi sceglierne più di uno. Facoltativo.';

  @override
  String get hhSaveError => 'Impossibile salvare';

  @override
  String themeMode(String mode) {
    String _temp0 = intl.Intl.selectLogic(mode, {
      'claro': 'Chiaro',
      'oscuro': 'Scuro',
      'other': 'Sistema',
    });
    return '$_temp0';
  }

  @override
  String get bcNotFound =>
      'Codice non trovato su Open Food Facts. Puoi aggiungerlo a mano.';

  @override
  String get bcTitle => 'Scansiona codice';

  @override
  String get bcSearching => 'Cerco il prodotto…';

  @override
  String get bcNoPermission =>
      'Mi serve il permesso della fotocamera per scansionare. Puoi darlo nelle impostazioni del telefono.';

  @override
  String get bcCameraError =>
      'Impossibile aprire la fotocamera. Puoi aggiungere il prodotto a mano dalla dispensa.';

  @override
  String planFeature(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'scan_ticket': 'Scansiona scontrini',
      'recipes': 'Idee e ricette',
      'meal_photo': 'Foto di ciò che mangi',
      'other': 'Ricette da un link',
    });
    return '$_temp0';
  }

  @override
  String puPlanName(String plan) {
    String _temp0 = intl.Intl.selectLogic(plan, {
      'pro': 'Piano Pro',
      'other': 'Piano gratuito',
    });
    return '$_temp0';
  }

  @override
  String get puExplain =>
      'Dispensa, spesa, compiti e piano non hanno limiti. Ecco cosa ti resta questo mese; si rinnova il giorno 1. Se qualcosa fallisce, non conta.';

  @override
  String get puGoPro => 'Passa a Pro';

  @override
  String puLeft(int left, int limit) {
    return 'Ti restano $left di $limit';
  }

  @override
  String get psTitle => 'Statistiche della spesa';

  @override
  String get psMostBought => 'Ciò che compri di più';

  @override
  String get psMostSpent => 'Dove spendi di più';

  @override
  String get psPriciest => 'I più cari (per unità)';

  @override
  String get psHistory => 'Il tuo storico della spesa';

  @override
  String psTotal(String amount) {
    return 'Spesa totale registrata: $amount';
  }

  @override
  String get psNoPrices => 'Non ci sono ancora abbastanza dati sui prezzi.';

  @override
  String get psEmptyTitle => 'Ancora nessuna statistica';

  @override
  String get psEmptyBody =>
      'Scansiona gli scontrini e qui vedrai cosa compri di più, dove spendi di più e i prodotti più cari.';

  @override
  String get meals => 'Pasti';

  @override
  String get mcNoHome => 'Non fai parte di nessuna casa.';

  @override
  String mcPrep(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'compra': 'Spesa',
      'cocina': 'Cucinare',
      'other': 'Tirare fuori',
    });
    return '$_temp0';
  }

  @override
  String get mcPlanIt => 'Pianifica';

  @override
  String get mcSeeInPlan => 'Vedi nel piano';

  @override
  String get mcNothing => 'Niente in programma questo giorno.';

  @override
  String get tasks => 'Compiti';

  @override
  String proPeriod(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'annual': 'All\'anno',
      'sixMonth': 'Ogni 6 mesi',
      'threeMonth': 'Ogni 3 mesi',
      'twoMonth': 'Ogni 2 mesi',
      'monthly': 'Al mese',
      'weekly': 'A settimana',
      'lifetime': 'Per sempre',
      'other': 'Pro',
    });
    return '$_temp0';
  }

  @override
  String get proAlready => 'Hai già Pro';

  @override
  String get proMoreUses => 'Più utilizzi ogni mese';

  @override
  String get proRestSame =>
      'Il resto resta uguale: senza limiti e per tutta la casa.';

  @override
  String get proFree => 'Gratis';

  @override
  String get proSoon => 'Pro sarà disponibile molto presto.';

  @override
  String get proNothingToRestore => 'Nessun acquisto da ripristinare.';

  @override
  String get proRestore => 'Ripristina acquisti';

  @override
  String get proRenews =>
      'Si rinnova da solo. Puoi annullare quando vuoi dallo store.';

  @override
  String get proTerms => 'Condizioni';

  @override
  String get proPrivacy => 'Privacy';

  @override
  String get aiSaveError => 'Errore nel salvataggio';

  @override
  String get aiStoreProduct => 'Prodotto del supermercato';

  @override
  String get aiRemoveProduct => 'Togli prodotto';

  @override
  String get aiEditTitle => 'Modifica prodotto';

  @override
  String get aiAddTitle => 'Aggiungi alla dispensa';

  @override
  String get aiChangePhoto => 'Cambia foto';

  @override
  String get aiProductType => 'Tipo di prodotto';

  @override
  String get aiWhatIsIt => 'Che cos\'è?';

  @override
  String aiDishKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'ingredient': 'Ingrediente da cucinare',
      'base': 'Base già pronta',
      'other': 'Piatto pronto',
    });
    return '$_temp0';
  }

  @override
  String get aiSearchStore => 'Cerca nel supermercato';

  @override
  String get aiSearchStoreLong => 'Cerca il prodotto del supermercato con foto';

  @override
  String get aiQuickAdd => 'Aggiungi i soliti con un tocco';

  @override
  String get aiLocation => 'Posizione';

  @override
  String get aiCategory => 'Categoria';

  @override
  String get aiQuantity => 'Quantità';

  @override
  String get aiUnit => 'Unità';

  @override
  String get aiServings => 'Porzioni (facoltativo)';

  @override
  String get aiFrozenDate => 'Data di congelamento';

  @override
  String get aiFrozenOn => 'Congelato il (facoltativo)';

  @override
  String get aiWillEstimate => 'Calcoleremo quanto dura in freezer.';

  @override
  String aiBestBefore(String date) {
    return 'Da consumarsi preferibilmente entro il $date (circa).';
  }

  @override
  String get aiExpiryDate => 'Data di scadenza';

  @override
  String get aiExpires => 'Scade il';

  @override
  String get aiExpiresApprox => 'Scade il (circa)';

  @override
  String get aiNotToList => 'Non aggiungere alla spesa';

  @override
  String get aiStaplesSub => 'Basi che hai sempre';

  @override
  String get aiSaveChanges => 'Salva modifiche';

  @override
  String get aiSaveNew => 'Salva in dispensa';

  @override
  String get kzMyKitchen => 'La mia cucina';

  @override
  String get kzAllGood => 'In ordine';

  @override
  String get phStore => 'Scegli prodotto del supermercato';

  @override
  String get phCamera => 'Scatta una foto';

  @override
  String get phGallery => 'Scegli dalla galleria';

  @override
  String get phError => 'Impossibile cambiare la foto';

  @override
  String get psStoreTitle => 'Prodotti del supermercato';

  @override
  String psStoreTitleOf(String store) {
    return 'Prodotti di $store';
  }

  @override
  String get psHint => 'Latte, yogurt greco, detersivo…';

  @override
  String get psTypeHint => 'Scrivi un prodotto e tocca cerca.';

  @override
  String get psThrottled => 'Troppe ricerche di fila. Riprova tra un minuto.';

  @override
  String get psOffline => 'Nessuna connessione. Puoi aggiungerlo comunque.';

  @override
  String get psDown =>
      'La ricerca prodotti non risponde. Riprova più tardi o aggiungilo comunque.';

  @override
  String get psNotInStore =>
      'Non è nel supermercato. Puoi aggiungerlo comunque.';

  @override
  String psNoResultsIn(String store) {
    return 'Nessun risultato in $store. Questi sono di altri supermercati.';
  }

  @override
  String psNotYet(String store) {
    return 'Non abbiamo ancora i prodotti di $store. Questi sono di altri supermercati.';
  }

  @override
  String get psOffData => 'Dati di Open Food Facts.';

  @override
  String psAddAsIs(String q) {
    return 'Aggiungi \"$q\" senza scegliere un prodotto';
  }

  @override
  String get offlineExplain =>
      'Puoi continuare a usare la lista della spesa e la dispensa: ciò che annoti viene salvato sul telefono e inviato quando torna la connessione. Il resto si aggiornerà allora.';

  @override
  String get offlineNow => 'Al momento sei offline';

  @override
  String streakMilestone(int days) {
    return '$days giorni di fila!';
  }

  @override
  String streakMilestoneSub(int next) {
    return 'Traguardo raggiunto. Prossimo: $next giorni.';
  }

  @override
  String streakDoneSub(int next) {
    return 'Oggi conta già. Prossimo traguardo: $next giorni.';
  }

  @override
  String get streakKeepSub =>
      'Spunta un compito o annota un pasto per continuare.';

  @override
  String get streakStart => 'Inizia la tua serie';

  @override
  String get streakStartSub => 'Spunta un compito o annota un pasto oggi.';

  @override
  String streakDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days giorni di fila',
      one: '1 giorno di fila',
    );
    return '$_temp0';
  }

  @override
  String get syncSaved =>
      'Salvato. Si sincronizzerà quando torna la connessione.';

  @override
  String get fzTitle => 'Metti porzioni in freezer?';

  @override
  String get fzSave => 'Metti in freezer';

  @override
  String get notNow => 'Non ora';

  @override
  String get fastIn => 'A digiuno';

  @override
  String get fastCanEat => 'Puoi mangiare';

  @override
  String fastLeft(String left, String time) {
    return 'Mancano $left · Mangi alle $time';
  }

  @override
  String fastUntil(String time) {
    return 'Fino alle $time';
  }

  @override
  String get shWeekReady =>
      'La tua settimana è pronta: pranzi, cene e lista della spesa';

  @override
  String get comingSoon => 'PROSSIMAMENTE';

  @override
  String psSummary(int distinct, int lines) {
    return '$distinct prodotti diversi · $lines acquisti';
  }

  @override
  String get errNoConnection =>
      'Sembra che non ci sia connessione. Riprova tra un momento.';

  @override
  String get errBadLogin => 'Email o password non corretti.';

  @override
  String get errConfirmEmail =>
      'Conferma la tua email (controlla la posta in arrivo) e riprova.';

  @override
  String get errSession => 'La sessione è scaduta. Accedi di nuovo.';

  @override
  String get errPermission => 'Non hai il permesso di farlo in questa casa.';

  @override
  String get errRateLimit => 'Troppe richieste di fila. Riprova tra poco.';

  @override
  String get errExists => 'Esiste già.';

  @override
  String get errUpload =>
      'Impossibile caricare l\'immagine. Provane una più piccola.';

  @override
  String get errGeneric => 'Qualcosa è andato storto. Riprova.';

  @override
  String get errBadQuantity => 'Inserisci una quantità valida.';

  @override
  String get errRecipeComplete => 'Impossibile completare la ricetta';

  @override
  String get errRecipeImport =>
      'Non sono riuscito a importare la ricetta da quel link';

  @override
  String get someone => 'Qualcuno';

  @override
  String get reward => 'Premio';

  @override
  String remKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'tasks': 'Compiti con orario',
      'expiry': 'Prodotti in scadenza',
      'other': 'Serie della casa',
    });
    return '$_temp0';
  }

  @override
  String remTaskOne(String title) {
    return 'Tocca a: $title';
  }

  @override
  String remTaskMany(int count) {
    return '$count compiti da fare';
  }

  @override
  String get remTaskOneBody =>
      'Quando hai finito, spuntalo per guadagnare punti.';

  @override
  String remTaskManyBody(String list) {
    return '$list. Spuntali alla fine per guadagnare punti.';
  }

  @override
  String remExpiryOne(String name) {
    return 'Scade domani: $name';
  }

  @override
  String remExpiryMany(int count) {
    return 'Domani scadono $count prodotti';
  }

  @override
  String get remExpiryBody => 'Cucinalo oggi o congela ciò che non userai.';

  @override
  String remStreakMilestone(int days) {
    return 'Oggi arrivi a $days giorni';
  }

  @override
  String get remStreakMilestoneBody =>
      'Spunta un compito o annota un pasto e festeggia.';

  @override
  String remStreakDays(int days) {
    return '$days giorni con la casa in ordine';
  }

  @override
  String get remStreakDaysBody =>
      'Spunta un compito o annota un pasto per non perdere la serie.';

  @override
  String get remHowIsHome => 'Come va la casa oggi?';

  @override
  String get remHowIsHomeBody =>
      'Basta un gesto per aggiungere un giorno alla serie.';

  @override
  String get remStreakAlive => 'La tua serie è ancora viva';

  @override
  String get remStreakAliveBody =>
      'Annota cosa hai mangiato o spunta un compito prima di dormire.';

  @override
  String listAnd(String items, String last) {
    return '$items e $last';
  }

  @override
  String listMore(String items, int count) {
    return '$items e altri $count';
  }

  @override
  String get planMovedLater => 'Lo lascio per un altro momento';

  @override
  String get planTheDish => 'il piatto';

  @override
  String planMovedTo(String recipe, String day) {
    return '$recipe spostato a $day';
  }

  @override
  String weekday(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '1': 'lunedì',
      '2': 'martedì',
      '3': 'mercoledì',
      '4': 'giovedì',
      '5': 'venerdì',
      '6': 'sabato',
      'other': 'domenica',
    });
    return '$_temp0';
  }

  @override
  String weekdayShortName(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '1': 'lun',
      '2': 'mar',
      '3': 'mer',
      '4': 'gio',
      '5': 'ven',
      '6': 'sab',
      'other': 'dom',
    });
    return '$_temp0';
  }

  @override
  String get prepShopTitle => 'Fare la spesa';

  @override
  String prepShopLine(String day) {
    return 'Per cucinare in blocco $day';
  }

  @override
  String get prepCookTitle => 'Cucinare in blocco';

  @override
  String get prepAutoTapers =>
      'I contenitori si aggiungono da soli a La mia cucina';

  @override
  String get prepThawTitle => 'Dal freezer al frigo';

  @override
  String prepThawLine(String recipe, int count, String day) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contenitori',
      one: '1 contenitore',
    );
    return '$recipe: $_temp0 per $day';
  }

  @override
  String get taperFresh => 'appena fatto';

  @override
  String taperFridge(String days) {
    return 'frigo per $days';
  }

  @override
  String taperFreezer(String days) {
    return 'freezer per $days';
  }

  @override
  String stepPrepare(String recipe) {
    return 'Preparare $recipe';
  }

  @override
  String stepUseAppliance(String appliance, String recipes) {
    String _temp0 = intl.Intl.selectLogic(appliance, {
      'oven': 'Accendi il forno',
      'stovetop': 'Accendi i fornelli',
      'pot': 'Accendi la pentola',
      'airfryer': 'Accendi la friggitrice ad aria',
      'microwave': 'Accendi il microonde',
      'blender': 'Accendi il frullatore',
      'other': 'Usa $appliance',
    });
    return '$_temp0 per $recipes';
  }

  @override
  String comidasTab(String tab) {
    String _temp0 = intl.Intl.selectLogic(tab, {
      'plan': 'Piano',
      'recipes': 'Ricette',
      'other': 'Diario',
    });
    return '$_temp0';
  }

  @override
  String bannerExpiring(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In scadenza',
    );
    return '$_temp0';
  }

  @override
  String get bannerIdeas => 'Idee';

  @override
  String get bannerHide => 'Nascondi fino a domani';

  @override
  String get loading => 'Caricamento';

  @override
  String get mascot => 'Mascotte';

  @override
  String voiceStep(int n) {
    return 'Passo $n.';
  }

  @override
  String voiceTime(String what) {
    return 'Tempo scaduto. $what.';
  }

  @override
  String get voiceLastStep => 'È l\'ultimo passo.';

  @override
  String get voiceNoTime => 'Questo passo non ha un tempo.';

  @override
  String voiceTimer(int minutes) {
    return 'Timer di $minutes minuti.';
  }

  @override
  String get voiceNoTimers => 'Nessun timer.';

  @override
  String get voiceStopped => 'Fermato.';

  @override
  String get voiceNoIngredients => 'Nessuna lista di ingredienti.';

  @override
  String unitOne(String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'unidad': 'pezzo',
      'diente': 'spicchio',
      'loncha': 'fetta',
      'lata': 'lattina',
      'bote': 'barattolo',
      'bolsa': 'sacchetto',
      'comida': 'pasto',
      'cucharada': 'cucchiaio',
      'cucharadita': 'cucchiaino',
      'other': '$unit',
    });
    return '$_temp0';
  }

  @override
  String unitMany(String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'unidad': 'pezzi',
      'diente': 'spicchi',
      'loncha': 'fette',
      'lata': 'lattine',
      'bote': 'barattoli',
      'bolsa': 'sacchetti',
      'comida': 'pasti',
      'cucharada': 'cucchiai',
      'cucharadita': 'cucchiaini',
      'other': '$unit',
    });
    return '$_temp0';
  }

  @override
  String unitShort(String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'unidad': 'pz',
      'cucharada': 'cucch.',
      'cucharadita': 'cucchiaino',
      'other': '$unit',
    });
    return '$_temp0';
  }

  @override
  String unitToTaste(String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'a_ojo': 'a occhio',
      'other': 'q.b.',
    });
    return '$_temp0';
  }

  @override
  String aiItemType(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'hogar': 'Casa/Pulizia',
      'other': 'Cibo',
    });
    return '$_temp0';
  }

  @override
  String aiKindShort(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'prep': 'Preparato',
      'dish': 'Piatto pronto',
      'other': 'Ingrediente',
    });
    return '$_temp0';
  }
}
