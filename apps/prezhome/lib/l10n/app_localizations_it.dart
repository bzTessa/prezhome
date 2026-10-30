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
}
