// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bosnian (`bs`).
class AppLocalizationsBs extends AppLocalizations {
  AppLocalizationsBs([String locale = 'bs']) : super(locale);

  @override
  String tabLabel(String tab) {
    String _temp0 = intl.Intl.selectLogic(tab, {
      'inicio': 'Danas',
      'comidas': 'Obroci',
      'compra': 'Kupovina',
      'despensa': 'Ostava',
      'tareas': 'Zadaci',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get country => 'Država';

  @override
  String get countryHint => 'Valuta, supermarketi i okvirne cijene';

  @override
  String get continueLabel => 'Nastavi';

  @override
  String get back => 'Nazad';

  @override
  String get oneMoment => 'Trenutak…';

  @override
  String get retry => 'Pokušaj ponovo';

  @override
  String get loginAccountCreated => 'Račun je kreiran. Dobro došli u PrezHome';

  @override
  String get loginAuthError => 'Greška pri prijavi';

  @override
  String loginProviderError(String provider) {
    return 'Prijava putem $provider nije uspjela';
  }

  @override
  String get loginResetNeedsEmail =>
      'Prvo upiši svoj e-mail i poslat ću ti link za promjenu lozinke.';

  @override
  String get loginResetSent => 'Poslala sam ti e-mail za promjenu lozinke.';

  @override
  String get loginResetError => 'E-mail nije poslan';

  @override
  String get loginWelcomeBack => 'Dobro došli nazad';

  @override
  String get loginCreateAccount => 'Kreiraj svoj račun';

  @override
  String get loginTagline => 'PrezHome, tvoj organizovani dom';

  @override
  String loginContinueWith(String provider) {
    return 'Nastavi putem $provider';
  }

  @override
  String get loginOrEmail => 'ili putem e-maila';

  @override
  String get loginEmail => 'E-mail';

  @override
  String get loginEmailInvalid => 'Unesi ispravan e-mail';

  @override
  String get loginPassword => 'Lozinka';

  @override
  String get loginShowPassword => 'Prikaži lozinku';

  @override
  String get loginHidePassword => 'Sakrij lozinku';

  @override
  String get loginPasswordShort => 'Najmanje 6 znakova';

  @override
  String get loginForgot => 'Zaboravila si lozinku?';

  @override
  String get loginSignIn => 'Prijavi se';

  @override
  String get loginSignUp => 'Registruj se';

  @override
  String get loginNoAccount => 'Nemaš račun? Registruj se';

  @override
  String get loginHaveAccount => 'Već imaš račun? Prijavi se';

  @override
  String get homeCodeFormat =>
      'Kod ima 8 slova i brojeva (na primjer ABCD-EFGH).';

  @override
  String get homeSetupError => 'Dom nije podešen';

  @override
  String get homeLastStep => 'Zadnji korak: tvoj dom';

  @override
  String get homeCreateHint =>
      'Kreiraj ga sada i, kad poželiš, pozovi ukućane iz Danas.';

  @override
  String get homeCreate => 'Kreiraj moj dom';

  @override
  String get homeInvited => 'Pozvan/a sam u dom';

  @override
  String get homeInviteCode => 'Kod pozivnice';

  @override
  String get homeJoin => 'Pridruži se domu';

  @override
  String get sessionLoadError => 'Profil se nije mogao učitati.';

  @override
  String get onbSectionHome => 'Tvoj dom';

  @override
  String get onbPeopleTitle => 'Koliko vas živi u domu?';

  @override
  String get onbPeopleHint => 'Za porcije, kupovinu i podjelu zadataka.';

  @override
  String get onbSectionGoals => 'Šta te zaokuplja';

  @override
  String get onbGoalsTitle => 'Šta želiš izbaciti iz glave?';

  @override
  String get onbGoalsHint => 'Izaberi koliko želiš. Ostalo će biti sakriveno.';

  @override
  String get onbPickOne => 'Izaberi barem jednu';

  @override
  String onbContinueCount(int count) {
    return 'Nastavi ($count)';
  }

  @override
  String get onbSectionKitchen => 'U kuhinji';

  @override
  String get onbCookingTitle => 'Kako kuhate?';

  @override
  String get onbCookingHint =>
      'Tako znamo trebamo li planirati kuhanje unaprijed i zamrzivač.';

  @override
  String get onbSectionShopping => 'Kupovina';

  @override
  String get onbShopTitle => 'Gdje kupuješ?';

  @override
  String get onbShopHint =>
      'Prvi će biti tvoj glavni supermarket: recepti će koristiti proizvode koje je tamo lako naći.';

  @override
  String get onbSkipSeeHome => 'Preskoči i vidi moj dom';

  @override
  String get onbSeeHome => 'Vidi moj dom';

  @override
  String get onbSlogan => 'Uredan dom, miran um.';

  @override
  String get onbStart => 'Započni';

  @override
  String get onbHaveAccount => 'Već imam račun';

  @override
  String get onbOneLess => 'Jedna manje';

  @override
  String get onbOneMore => 'Jedna više';

  @override
  String onbPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count osoba',
      one: 'Samo ja',
    );
    return '$_temp0';
  }

  @override
  String get onbProfileBadge => 'Profil tvog doma';

  @override
  String onbProfileName(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'solo': 'Solo',
      'duo': 'Duo',
      'tribu': 'Pleme',
      'other': 'Porodica',
    });
    return '$_temp0';
  }

  @override
  String onbProfileDescription(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'solo':
          'Cijeli dom zavisi od tebe. PrezHome pamti šta imaš, šta ističe i šta treba uraditi, da ti ne moraš.',
      'duo':
          'Dvije osobe i jedan dom. PrezHome vidljivo dijeli obaveze, da niko ne mora sve držati u glavi.',
      'other':
          'Mnogo usta i mnogo stvari odjednom. PrezHome planira obroke, kupovinu i zadatke za sve i podsjeća svakog na njegov dio.',
    });
    return '$_temp0';
  }

  @override
  String get onbLoadToday => 'Mentalno opterećenje danas';

  @override
  String get onbLoadWithApp => 'Uz PrezHome';

  @override
  String onbLoad(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'high': 'teško',
      'medium': 'srednje',
      'other': 'lagano',
    });
    return '$_temp0';
  }

  @override
  String get onbCreateAccount => 'Kreiraj moj račun';

  @override
  String onbFeature(String f) {
    String _temp0 = intl.Intl.selectLogic(f, {
      'compra': 'Lista za kupovinu',
      'comidas': 'Šta jedemo',
      'despensa': 'Ostava i rokovi trajanja',
      'tareas': 'Kućni poslovi',
      'other': 'Troškovi doma',
    });
    return '$_temp0';
  }

  @override
  String goalLabel(String g) {
    String _temp0 = intl.Intl.selectLogic(g, {
      'comidas': 'Šta jedemo',
      'compra': 'Kupovina',
      'despensa': 'Šta ima u kući',
      'tareas': 'Kućni poslovi',
      'lote': 'Kuhanje unaprijed',
      'other': 'Troškovi doma',
    });
    return '$_temp0';
  }

  @override
  String goalHint(String g) {
    String _temp0 = intl.Intl.selectLogic(g, {
      'comidas': 'Plan obroka i recepti',
      'compra': 'Lista koja se sama piše',
      'despensa': 'Ostava, frižider i rokovi',
      'tareas': 'Pravedna podjela i podsjetnici',
      'lote': 'Posude i zamrzivač u redu',
      'other': 'Budžet i računi',
    });
    return '$_temp0';
  }

  @override
  String cookingLabel(String c) {
    String _temp0 = intl.Intl.selectLogic(c, {
      'diario': 'Svaki dan',
      'lote': 'Unaprijed',
      'mixto': 'Pomalo od svega',
      'other': 'Skoro nikad',
    });
    return '$_temp0';
  }

  @override
  String cookingHint(String c) {
    String _temp0 = intl.Intl.selectLogic(c, {
      'diario': 'Kuham kad treba',
      'lote': 'Spremam za više dana odjednom',
      'mixto': 'Neke dane unaprijed',
      'other': 'Jedem vani ili nešto brzo',
    });
    return '$_temp0';
  }

  @override
  String homeGreeting(String part) {
    String _temp0 = intl.Intl.selectLogic(part, {
      'morning': 'Dobro jutro',
      'afternoon': 'Dobar dan',
      'other': 'Dobro veče',
    });
    return '$_temp0';
  }

  @override
  String get homeCustomize => 'Prilagodi Danas';

  @override
  String get homeYourData => 'Tvoji podaci';

  @override
  String get homeYourHome => 'Tvoj dom';

  @override
  String homeTodayTag(String meal) {
    return 'Danas · $meal';
  }

  @override
  String mealType(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'breakfast': 'Doručak',
      'lunch': 'Ručak',
      'snack': 'Užina',
      'dinner': 'Večera',
      'dessert': 'Desert',
      'other': 'Obrok',
    });
    return '$_temp0';
  }

  @override
  String get homeEatingOut => 'Van kuće';

  @override
  String get homeWhatToEat => 'Šta jedemo danas?';

  @override
  String get homeNothingPlanned => 'Za danas još ništa nije planirano.';

  @override
  String get homePlan => 'Planiraj';

  @override
  String get homeWithWhatIHave => 'Sa onim što imam';

  @override
  String get homeExpiring => 'Ističe';

  @override
  String homeTasksToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zadaci danas',
      one: 'Zadatak danas',
    );
    return '$_temp0';
  }

  @override
  String get homeInShopping => 'Na listi';

  @override
  String get homeShortcuts => 'Prečice';

  @override
  String get homeForToday => 'Za danas';

  @override
  String get homeSeeAll => 'Vidi sve';

  @override
  String homePoints(int points) {
    return '$points bod.';
  }

  @override
  String homePointsSnack(int points) {
    return '+$points bodova';
  }

  @override
  String get homeToday => 'Danas';

  @override
  String get homeTomorrow => 'Sutra';

  @override
  String get homeCaloriesTitle => 'Izračunaj svoj cilj kalorija';

  @override
  String get homeCaloriesHint =>
      'Odgovori na nekoliko brzih pitanja i prilagodit ću PrezHome tebi.';

  @override
  String homeOf(String total) {
    return 'od $total';
  }

  @override
  String get homeCaloriesToday => 'Današnje kalorije';

  @override
  String homeKcal(int kcal) {
    return '$kcal kcal';
  }

  @override
  String homeKcalLeft(int kcal) {
    return 'Preostalo $kcal kcal';
  }

  @override
  String homeKcalOver(int kcal) {
    return 'Prešla si $kcal kcal';
  }

  @override
  String get homeMonthSpend => 'Potrošnja ovog mjeseca';

  @override
  String homeMoneyLeft(String amount) {
    return 'Preostalo $amount';
  }

  @override
  String homeMoneyOver(String amount) {
    return '$amount preko budžeta';
  }

  @override
  String get save => 'Sačuvaj';

  @override
  String get homeCardsSection => 'Kartice (prevuci za redoslijed)';

  @override
  String get homeQuickSection => 'Brze akcije';

  @override
  String get homeQuickHint => 'Izaberi prečice koje ćeš vidjeti na vrhu Danas.';

  @override
  String dashCard(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'meals': 'Današnji obroci',
      'calories': 'Današnje kalorije',
      'tasks': 'Zadaci',
      'other': 'Potrošnja ovog mjeseca',
    });
    return '$_temp0';
  }

  @override
  String quickAction(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'add_inventory': 'Dodaj u ostavu',
      'scan_ticket': 'Skeniraj račun',
      'shopping': 'Lista za kupovinu',
      'add_recipe': 'Novi recept',
      'meal_plan': 'Sedmični plan',
      'other': 'Dnevnik kalorija',
    });
    return '$_temp0';
  }

  @override
  String get shopPickStore => 'Izaberi supermarket';

  @override
  String get shopAddFromPlan => 'Dodaj sedmični plan';

  @override
  String get shopListOptions => 'Opcije liste';

  @override
  String get shopAllInCart => 'Sve je u korpi';

  @override
  String shopPending(int pending, int done) {
    return '$pending za kupiti · $done u korpi';
  }

  @override
  String shopUnpriced(int count) {
    return ' · $count bez cijene';
  }

  @override
  String get shopAddProduct => 'Dodaj proizvod';

  @override
  String get shopSearchStore => 'Traži u supermarketu';

  @override
  String get moreOptions => 'Više opcija';

  @override
  String get less => 'Manje';

  @override
  String get more => 'Više';

  @override
  String shopAdded(String name) {
    return '$name, dodano';
  }

  @override
  String shopAdd(String name) {
    return 'Dodaj $name';
  }

  @override
  String get shopLiveOffline =>
      'Trenutno nema veze uživo; ažurirat će se pri ponovnom učitavanju.';

  @override
  String get couldNotUpdate => 'Ažuriranje nije uspjelo';

  @override
  String shopSavedToPantry(int count) {
    return '$count proizvoda spremljeno u ostavu';
  }

  @override
  String get shopRemoveFromList => 'Ukloni s liste';

  @override
  String shopRemovedOne(String name) {
    return 'Uklonjeno \"$name\"';
  }

  @override
  String get couldNotChangePhoto => 'Fotografija nije promijenjena';

  @override
  String get shopAddToList => 'Dodaj na listu';

  @override
  String get shopTypeFood => 'Hrana';

  @override
  String get shopTypeHome => 'Dom/Čišćenje';

  @override
  String get name => 'Naziv';

  @override
  String get product => 'Proizvod';

  @override
  String get quantity => 'Količina';

  @override
  String get unit => 'Jedinica';

  @override
  String get cancel => 'Otkaži';

  @override
  String get add => 'Dodaj';

  @override
  String get nameEmpty => 'Naziv ne može biti prazan.';

  @override
  String get couldNotAdd => 'Dodavanje nije uspjelo';

  @override
  String get shopPlanAllAtHome => 'Već imaš kod kuće sve iz plana';

  @override
  String shopAddedFromPlan(int count) {
    return 'Dodano $count proizvoda iz plana';
  }

  @override
  String get shopListTitle => 'Lista za kupovinu';

  @override
  String get shopMainList => 'Glavna lista';

  @override
  String get couldNotCreateList => 'Lista nije kreirana';

  @override
  String get shopRecipesUseStore =>
      'Recepti će koristiti proizvode iz ovog supermarketa.';

  @override
  String get shopStoreSaveError => 'Supermarket nije sačuvan. Pokušaj ponovo.';

  @override
  String get shopGroupByAisle => 'Grupiši po odjeljku';

  @override
  String get shopGroupHint => 'Povrće, meso, čišćenje…';

  @override
  String get shopShowPhotos => 'Prikaži fotografije proizvoda';

  @override
  String get shopMyLists => 'Moje liste';

  @override
  String get categories => 'Kategorije';

  @override
  String get shopFinish => 'Završi kupovinu';

  @override
  String shopFinishCount(int count) {
    return 'Završi kupovinu ($count)';
  }

  @override
  String get shopScanTicket => 'Skeniraj račun';

  @override
  String get shopAllBought => 'Sve kupljeno';

  @override
  String get shopToBuy => 'Za kupiti';

  @override
  String get shopUsual => 'Uobičajeno';

  @override
  String get shopInCart => 'U korpi';

  @override
  String shopRemovedMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Uklonjeno $count proizvoda',
      one: 'Uklonjen 1 proizvod',
    );
    return '$_temp0';
  }

  @override
  String get couldNotRemove => 'Uklanjanje nije uspjelo';

  @override
  String get undo => 'Poništi';

  @override
  String get couldNotUndo => 'Poništavanje nije uspjelo';

  @override
  String get shopToCart => 'U korpu';

  @override
  String get shopFromPlan => 'Iz sedmičnog plana';

  @override
  String get changePhoto => 'Promijeni fotografiju';

  @override
  String get shopEmptyTitle => 'Tvoja lista je prazna';

  @override
  String get shopEmptyHint => 'Upiši gore šta ti treba ili preuzmi iz plana.';

  @override
  String get shopFromPlanAction => 'Iz plana';

  @override
  String get shopDoneTitle => 'Kupovina završena';

  @override
  String get shopDoneHint => 'Imaš sve s liste. Odlično!';
}
