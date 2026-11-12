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
  String get loginConfirmEmailSent =>
      'Poslali smo vam e-mail za potvrdu računa. Otvorite ga na ovom telefonu i bit ćete prijavljeni.';

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
      'Prvi će biti tvoj glavni supermarket: tamo ćemo tražiti proizvode s tvoje liste za kupovinu.';

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
      'drink': 'Piće',
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
  String get shopAddDetailed => 'Dodaj s detaljima';

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
      'Proizvodi s tvoje liste tražit će se u ovom supermarketu. Recepti vrijede za svaki.';

  @override
  String get shopStoreSaveError => 'Supermarket nije sačuvan. Pokušaj ponovo.';

  @override
  String get shopGroupByAisle => 'Grupiši po odjeljku';

  @override
  String get shopGroupHint => 'Povrće, meso, čišćenje…';

  @override
  String get shopShowPhotos => 'Prikaži fotografije proizvoda';

  @override
  String get shopShowIcons => 'Prikaži crteže kada nema fotografije';

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

  @override
  String panUsedInOne(String meal) {
    return 'Uklonjeno ono što si iskoristio za $meal';
  }

  @override
  String panUsedInMany(int count) {
    return 'Uklonjeno ono što si iskoristio za $count obroka iz plana';
  }

  @override
  String get view => 'Pogledaj';

  @override
  String get couldNotDelete => 'Brisanje nije uspjelo';

  @override
  String panNoLongerShop(String name) {
    return '$name se više neće pojavljivati u kupovini.';
  }

  @override
  String panBackToShop(String name) {
    return '$name će se ponovo pojavljivati u kupovini.';
  }

  @override
  String panCouldNotMarkOut(String name) {
    return 'Nije moguće označiti $name kao potrošeno';
  }

  @override
  String panMarkedOut(String name) {
    return 'Označio sam $name kao potrošeno.';
  }

  @override
  String panOutNotAdded(String name) {
    return '$name je potrošeno, ali ga nisam mogao dodati u kupovinu';
  }

  @override
  String panAlreadyInList(String name) {
    return '$name je već na tvojoj listi za kupovinu.';
  }

  @override
  String panAddedToShop(String name) {
    return 'Dodao sam $name u kupovinu';
  }

  @override
  String get panAddManual => 'Dodaj ručno';

  @override
  String get panScanBarcode => 'Skeniraj barkod';

  @override
  String get panFreezeDish => 'Kuhano jelo u zamrzivač';

  @override
  String get panFreezeDishHint => 'Izaberi recept i broj porcija';

  @override
  String get panSaveRecipeFirst => 'Prvo sačuvaj neki recept.';

  @override
  String get panWhichDish => 'Koje jelo zamrzavaš?';

  @override
  String get panHowManyServings => 'Koliko porcija zamrzavaš?';

  @override
  String get panTitle => 'Ostava i Frižider';

  @override
  String get panAddTooltip => 'Dodaj u ostavu';

  @override
  String get panLoadError => 'Zalihe nisu učitane';

  @override
  String get panEmptyTitle => 'Tvoja ostava je prazna';

  @override
  String get panEmptyHint =>
      'Dodaj ono što imaš kod kuće ili označi kupovinu i stići će samo.';

  @override
  String get panAddProduct => 'Dodaj proizvod';

  @override
  String get panWhatToCook => 'Šta da skuham s ovim?';

  @override
  String get panExpiringHeader => 'Istekli i pred istekom';

  @override
  String get panNothingHere => 'Ovdje nema ničega.';

  @override
  String kitchenZone(String zone) {
    String _temp0 = intl.Intl.selectLogic(zone, {
      'nevera': 'Frižider',
      'congelador': 'Zamrzivač',
      'despensa': 'Ostava',
      'bebidas': 'Pića',
      'especias': 'Začini',
      'limpieza': 'Čišćenje',
      'hogar': 'Razno',
      'other': '$zone',
    });
    return '$_temp0';
  }

  @override
  String get kitchenReview => 'Provjeri';

  @override
  String expiryGroup(String group) {
    String _temp0 = intl.Intl.selectLogic(group, {
      'expired': 'Isteklo',
      'week': 'Ove sedmice',
      'later': 'Kasnije',
      'other': 'Bez datuma',
    });
    return '$_temp0';
  }

  @override
  String panExpiredAgo(int days) {
    return 'Isteklo prije $days dana';
  }

  @override
  String get panExpiredYesterday => 'Isteklo jučer';

  @override
  String get panExpiresToday => 'Ističe danas';

  @override
  String get panExpiresTomorrow => 'Ističe sutra';

  @override
  String panExpiresIn(int days) {
    return 'Ističe za $days dana';
  }

  @override
  String panDays(int days) {
    return '$days dana';
  }

  @override
  String get panNotBought => 'Ne kupuje se';

  @override
  String get panConsumed => 'Potrošeno';

  @override
  String get panToShopping => 'U kupovinu';

  @override
  String panCouldNotAddToShop(String name) {
    return 'Nisam mogao dodati $name u kupovinu';
  }

  @override
  String panExpiredDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count isteklih obrisano',
      one: 'Isteklo obrisano',
    );
    return '$_temp0';
  }

  @override
  String get panMyKitchen => 'Moja kuhinja';

  @override
  String get panUsedHistory => 'Šta je potrošeno';

  @override
  String get panNothingExpired => 'Ništa nije isteklo';

  @override
  String panDeleteExpired(int count) {
    return 'Obriši istekle ($count)';
  }

  @override
  String panEmptyZone(String where) {
    return 'Isprazni $where';
  }

  @override
  String panEmptyAsk(String where) {
    return 'Isprazniti $where?';
  }

  @override
  String panWillDelete(int count) {
    return 'Bit će obrisano $count proizvoda.';
  }

  @override
  String get panEmpty => 'Isprazni';

  @override
  String panDeleted(int count) {
    return '$count proizvoda obrisano';
  }

  @override
  String get edit => 'Uredi';

  @override
  String get panShopAgain => 'Ponovo dodavaj u kupovinu';

  @override
  String get panDontShop => 'Ne dodaji u kupovinu';

  @override
  String get panStapleHint => 'Za osnovne stvari koje uvijek imaš';

  @override
  String get panWillAddToShop => 'Dodat ću ga u kupovinu';

  @override
  String get delete => 'Obriši';

  @override
  String panDeleteAsk(String name) {
    return 'Obrisati $name?';
  }

  @override
  String panConsumedOn(String name, String day) {
    return '$name, potrošeno $day';
  }

  @override
  String get todayLower => 'danas';

  @override
  String get yesterdayLower => 'jučer';

  @override
  String panOnDate(int day, int month) {
    return '$day.$month.';
  }

  @override
  String get panWhen => 'Kada?';

  @override
  String get today => 'Danas';

  @override
  String get yesterday => 'Jučer';

  @override
  String get panOtherDay => 'Drugi dan';

  @override
  String get panWhichDay => 'Koji dan?';

  @override
  String get panHowMany => 'Koliko?';

  @override
  String panAll(String qty) {
    return 'Sve ($qty)';
  }

  @override
  String get couldNotLoad => 'Učitavanje nije uspjelo';

  @override
  String get panNothingYet => 'Još ništa.';

  @override
  String get panWhenCooking => 'Pri kuhanju';

  @override
  String get planHowLong => 'Za koliko vremena?';

  @override
  String get thisWeek => 'Ove sedmice';

  @override
  String planWeeks(int count) {
    return '$count sedmice';
  }

  @override
  String get planMonth4 => 'Mjesec (4 sedmice)';

  @override
  String get planPickDates => 'Izaberi datume';

  @override
  String get planDates => 'Datumi plana';

  @override
  String get planMaxTwoMonths => 'Najviše dva mjeseca odjednom.';

  @override
  String get planReadyAllHome =>
      'Plan je spreman. Već imaš kod kuće sve što ti treba';

  @override
  String planListReady(int count) {
    return 'Plan je spreman. Lista za kupovinu sa $count proizvoda';
  }

  @override
  String get planBackInPlan => 'Ponovo je u planu';

  @override
  String planEntryTitle(String meal, String recipe) {
    return '$meal · $recipe';
  }

  @override
  String get planNoRecipe => 'Bez recepta';

  @override
  String get planChangeRecipe => 'Promijeni recept';

  @override
  String get planWhoEats => 'Ko jede';

  @override
  String get planMarkHome => 'Označi kod kuće';

  @override
  String get planMarkOut => 'Označi kao vani';

  @override
  String get planStopRepeat => 'Prestani ponavljati';

  @override
  String get planStopRepeatHint => 'Uklanja sljedeće puta';

  @override
  String get planRepeat => 'Ponovi';

  @override
  String get planRepeatHint => 'Svaki dan, svake sedmice… ili zauvijek';

  @override
  String get planRemove => 'Ukloni iz plana';

  @override
  String planRepeatTitle(String meal) {
    return 'Ponovi $meal';
  }

  @override
  String get planHowOften => 'Koliko često?';

  @override
  String planEveryDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Svaka $days dana',
      one: 'Svaki dan',
    );
    return '$_temp0';
  }

  @override
  String planEveryWeeks(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: 'Svake $weeks sedmice',
      one: 'Svake sedmice',
    );
    return '$_temp0';
  }

  @override
  String get planUntilWhen => 'Do kada?';

  @override
  String get planForever => 'Zauvijek';

  @override
  String planMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mjeseca',
      one: '1 mjesec',
    );
    return '$_temp0';
  }

  @override
  String get planRepeatDone =>
      'Gotovo. Vidjet ćeš ga u planu narednih sedmica; ako dan već ima nešto drugo, to ostaje.';

  @override
  String get planWhoAtHome => 'Ko jede kod kuće?';

  @override
  String get planCalendarPermission =>
      'Dozvoli pristup kalendaru u postavkama telefona';

  @override
  String get planInFast => 'Pada u vrijeme posta';

  @override
  String get planSettings => 'Postavke plana';

  @override
  String get planBatchCook => 'Kuham unaprijed';

  @override
  String get planBatchCookHint => 'Dan kupovine, kuhanja i posude';

  @override
  String get planAddDish => 'Dodaj još jedno jelo';

  @override
  String get planAutoDessert => 'Automatski desert';

  @override
  String get planAutoDessertHint => 'Plan dodaje desert ovim obrocima';

  @override
  String get planBoughtReady => 'Kupljeno gotovo';

  @override
  String get planBoughtReadyHint =>
      'Gotov proizvod iz supermarketa, bez kuhanja';

  @override
  String get planYourReady => 'Tvoja gotova jela';

  @override
  String get planReadySearch => 'Traži u supermarketu';

  @override
  String get planReadyEmpty =>
      'Još nemaš gotovih jela od povjerenja. Potraži ih u katalogu supermarketa.';

  @override
  String get planReadyMain => 'Jelo';

  @override
  String get planReadyDessert => 'Desert';

  @override
  String get planReadyKcal => 'Kalorije po porciji (neobavezno)';

  @override
  String get planReadyRemove => 'Ukloni iz tvojih gotovih jela';

  @override
  String get planTimes => 'Vremena';

  @override
  String get planFasting => 'Povremeni post';

  @override
  String get no => 'Ne';

  @override
  String planEatWindow(String from, String to) {
    return 'Jedeš od $from do $to. Pomjera se s vremenom večere.';
  }

  @override
  String get planCalendar => 'Kalendar';

  @override
  String get planToCalendar => 'Prebaci u kalendar';

  @override
  String get planCalendarLinked => 'Kalendar povezan';

  @override
  String get planCalendarHint =>
      'Obroci i zadaci s vremenom, u Google kalendaru';

  @override
  String get planCalendarUpdates => 'Ažurira se kad otvoriš plan';

  @override
  String get remove => 'Ukloni';

  @override
  String get planPickRecipe => 'Izaberi recept';

  @override
  String get planDayFull => 'Taj dan već ima sve obroke.';

  @override
  String get planWhichMeal => 'Koji obrok dodaješ?';

  @override
  String get planTitle => 'Sedmični plan';

  @override
  String get planNoHome => 'Ne pripadaš nijednom domaćinstvu.';

  @override
  String get planMake => 'Napravi plan';

  @override
  String get planRemake => 'Ponovo napravi plan';

  @override
  String get planNeedRecipes => 'Prvo dodaj nekoliko recepata';

  @override
  String get planNeedRecipesHint =>
      'Planer raspoređuje tvoje recepte kroz sedmicu. Sačuvaj nekoliko u kartici Obroci.';

  @override
  String get planPrevWeek => 'Prethodna sedmica';

  @override
  String get planNextWeekLabel => 'Sljedeće sedmice';

  @override
  String get planLastWeek => 'Prošle sedmice';

  @override
  String get planWeek => 'Sedmica';

  @override
  String get planBackToToday => 'Nazad na danas';

  @override
  String get planNextWeek => 'Sljedeća sedmica';

  @override
  String get planDay => 'Dan';

  @override
  String get planMonthCalendar => 'Kalendar mjeseca';

  @override
  String get planNoPlanYet => 'Još nema plana za ovu sedmicu.';

  @override
  String get recipe => 'Recept';

  @override
  String get planCookMode => 'Način kuhanja';

  @override
  String get planCookWeek => 'Skuhaj cijelu sedmicu odjednom';

  @override
  String get planBatch => 'Kuhanje unaprijed';

  @override
  String planCookDays(int days, int recipes) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dana kuhanja',
      one: '1 dan kuhanja',
    );
    String _temp1 = intl.Intl.pluralLogic(
      recipes,
      locale: localeName,
      other: '$recipes recepata',
      one: '1 recept',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get planBatchEmpty =>
      'Kad plan bude gotov, reći ću ti kada kupovati, kada kuhati i šta ide u frižider ili zamrzivač.';

  @override
  String get planCookedToFreezer => 'Skuhano · u zamrzivač';

  @override
  String planFrozen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jela sačuvano u zamrzivaču.',
      one: 'Sačuvano u zamrzivaču s fotografijom.',
    );
    return '$_temp0';
  }

  @override
  String get planEnergyLow => 'Malo';

  @override
  String get planEnergyNormal => 'Normalno';

  @override
  String get planEnergyHigh => 'Puno';

  @override
  String get planEnergyHint =>
      'Sa \"malo\" plan bira brze recepte i koristi zamrzivač i tvoja gotova jela.';

  @override
  String get planHowMuchCook => 'Koliko kuhati';

  @override
  String planServings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count porcija',
      one: '1 porcija',
    );
    return '$_temp0';
  }

  @override
  String get close => 'Zatvori';

  @override
  String get planSearchRecipe => 'Traži recept...';

  @override
  String get planNoMatch => 'Nema odgovarajućih recepata.';

  @override
  String get diaDeleteError => 'Obrok nije obrisan.';

  @override
  String get diaManual => 'Ručno';

  @override
  String get diaManualHint => 'Upiši naziv i kalorije';

  @override
  String get diaFromRecipe => 'Iz recepta';

  @override
  String get diaFromRecipeHint => 'Zabilježi svoj recept kao obrok';

  @override
  String get diaWithPhoto => 'Fotografijom';

  @override
  String get diaWithPhotoHint => 'Fotografiši jelo i izračunat ćemo kalorije';

  @override
  String get diaAddManual => 'Dodaj ručno';

  @override
  String get diaKcalField => 'Kalorije (kcal)';

  @override
  String get diaMealTypeOptional => 'Vrsta obroka (neobavezno)';

  @override
  String get diaNoType => 'Bez vrste';

  @override
  String get diaProteinG => 'Proteini (g)';

  @override
  String get diaCarbsG => 'Ugljikohidrati (g)';

  @override
  String get diaFatG => 'Masti (g)';

  @override
  String get diaNeedNameKcal => 'Unesi barem naziv i kalorije.';

  @override
  String get diaSaveError => 'Obrok nije sačuvan.';

  @override
  String get diaRecipesLoadError => 'Recepti nisu učitani.';

  @override
  String get diaNoRecipes => 'Još nemaš recepata za bilježenje.';

  @override
  String diaKcalPerServing(int kcal) {
    return '$kcal kcal po porciji';
  }

  @override
  String get diaNoKcal => 'Nema zabilježenih kalorija';

  @override
  String get diaServings => 'Porcije';

  @override
  String get diaServingsError => 'Unesi broj porcija veći od 0.';

  @override
  String get diaLog => 'Zabilježi';

  @override
  String get diaRecipeLogError => 'Recept nije zabilježen.';

  @override
  String get diaTitle => 'Moj dnevnik';

  @override
  String get diaAddMeal => 'Dodaj obrok';

  @override
  String get previous => 'Prethodno';

  @override
  String get next => 'Sljedeće';

  @override
  String get diaDayCalories => 'Kalorije dana';

  @override
  String diaOfTarget(int kcal) {
    return 'od $kcal kcal';
  }

  @override
  String get diaNoTarget =>
      'Dopuni profil da postaviš dnevni cilj kalorija i vidiš koliko ti ostaje svaki dan.';

  @override
  String get diaCompleteProfile => 'Dopuni moj profil';

  @override
  String get diaOthers => 'Ostalo';

  @override
  String get diaMeal => 'Obrok';

  @override
  String get diaLast7 => 'Tvojih zadnjih 7 dana';

  @override
  String diaTargetPerDay(int kcal) {
    return 'Cilj: $kcal kcal dnevno';
  }

  @override
  String get diaTarget => 'Cilj';

  @override
  String get diaTodaySplit => 'Današnja raspodjela';

  @override
  String get diaNoMacros => 'Danas još nema zabilježenih makroa.';

  @override
  String get diaProtein => 'Proteini';

  @override
  String get diaCarbs => 'Ugljikohidrati';

  @override
  String get diaFat => 'Masti';

  @override
  String get diaAteThePlan => 'Jesi li jeo ono iz plana?';

  @override
  String diaAskLine(String day, String meal, String name, int kcal) {
    return '$day, $meal: $name · $kcal kcal';
  }

  @override
  String get yes => 'Da';

  @override
  String get diaAnswerError => 'Odgovor nije sačuvan.';

  @override
  String get diaAskFirst => 'Pitaj me prije bilježenja plana';

  @override
  String get diaAskOn => 'Pitamo te jesi li pojeo svaki obrok iz plana.';

  @override
  String get diaAskOff =>
      'Obroci iz plana bilježe se sami kad prođe njihovo vrijeme.';

  @override
  String get diaSettingError => 'Postavka nije sačuvana.';

  @override
  String get diaEmpty =>
      'Još nisi ništa zabilježio ovog dana.\nDodaj svoj prvi obrok.';

  @override
  String get recUnfavorite => 'Ukloni iz omiljenih';

  @override
  String get recFavorite => 'Označi kao omiljeni';

  @override
  String get recDelete => 'Obriši recept';

  @override
  String get recDeleteAsk => 'Obrisati recept?';

  @override
  String recRemoveAsk(String name) {
    return '\"$name\" i njegovi sastojci bit će obrisani.';
  }

  @override
  String recDeleted(String name) {
    return '\"$name\" obrisan.';
  }

  @override
  String get recTitle => 'Recepti';

  @override
  String get recNew => 'Novi recept';

  @override
  String get recLoadError => 'Nisam mogao učitati recepte';

  @override
  String get recEmptyTitle => 'Još nema recepata';

  @override
  String get recEmptyHint => 'Napravi prvi ili zatraži ideje s onim što imaš.';

  @override
  String get recIdeas => 'Ideje s onim što imam';

  @override
  String get recNoResults => 'Nema rezultata';

  @override
  String recCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recepata',
      one: '1 recept',
    );
    return '$_temp0';
  }

  @override
  String get recWhatToCook => 'Šta da skuham s onim što imam?';

  @override
  String get recPantryIdeas => 'Ideje s onim što je u tvojoj ostavi';

  @override
  String get recAll => 'Svi';

  @override
  String get recFavorites => 'Omiljeni';

  @override
  String get recOther => 'Ostali';

  @override
  String recSeeAll(int count) {
    return 'Prikaži svih $count';
  }

  @override
  String get recNoFilter =>
      'Nema recepata s ovim filterom.\nProbaj drugu kategoriju.';

  @override
  String get clear => 'Očisti';

  @override
  String recNoMatch(String query) {
    return 'Nema recepata koji odgovaraju\n\"$query\".';
  }

  @override
  String get rdPhoto => 'Fotografija recepta';

  @override
  String get rdAutoPhoto => 'Automatski potraži drugu fotografiju';

  @override
  String get rdAutoPhotoHint => 'Traži novu sliku po nazivu';

  @override
  String get rdGallery => 'Izaberi iz galerije';

  @override
  String get rdNoBetterPhoto => 'Za sada nisam našao bolju fotografiju';

  @override
  String get rdUploadError => 'Fotografija nije otpremljena';

  @override
  String rdShareText(String title, String code) {
    return 'Šaljem ti svoj recept za $title u PrezHome. U aplikaciji idi na Recepti, dodirni Dodaj recept pa S kodom: $code';
  }

  @override
  String get rdSavedFreezer => 'Sačuvano u zamrzivaču.';

  @override
  String get couldNotSave => 'Čuvanje nije uspjelo';

  @override
  String get rdVideoError => 'Link videa nije otvoren';

  @override
  String get rdWatchVideo => 'Pogledaj video';

  @override
  String get share => 'Podijeli';

  @override
  String get rdEdit => 'Uredi recept';

  @override
  String get rdMinutes => 'Minute';

  @override
  String get rdKcalServing => 'Kcal/porcija';

  @override
  String get rdPerServingShort => 'po porciji';

  @override
  String rdServingWord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Porcije',
      one: 'Porcija',
    );
    return '$_temp0';
  }

  @override
  String get rdFreezable => 'Može se zamrznuti';

  @override
  String get rdIngredients => 'Sastojci';

  @override
  String get rdStepsWord => 'Koraci';

  @override
  String rdSteps(int count) {
    return 'Koraci ($count)';
  }

  @override
  String get rdNutrition => 'Nutritivne vrijednosti';

  @override
  String get rdNoIngredients => 'Nema zabilježenih sastojaka.';

  @override
  String rdOriginal(String servings) {
    return 'Originalni recept: $servings';
  }

  @override
  String rdForHome(String servings) {
    return 'Za tvoje domaćinstvo danas: $servings';
  }

  @override
  String get rdHaveAll => 'Imaš sve kod kuće';

  @override
  String rdHaveSome(int have, int total) {
    return 'Imaš $have od $total kod kuće';
  }

  @override
  String rdMissing(int count) {
    return 'Nedostaje $count';
  }

  @override
  String get rdAtHome => 'Kod kuće';

  @override
  String get rdLacking => 'Nedostaje';

  @override
  String get rdNoSteps =>
      'Ovaj recept nema koraka. Možeš ih dodati uređivanjem.';

  @override
  String get rdPerServingTitle => 'Po porciji';

  @override
  String get rdNoNutrition => 'Nema nutritivnih podataka.';

  @override
  String rdPerServing(String amount) {
    return '$amount po porciji';
  }

  @override
  String rdTotal(String amount) {
    return '≈ $amount ukupno';
  }

  @override
  String get rdApproxCost =>
      'Približan trošak. Skeniraj račune da ga preciziraš stvarnim cijenama.';

  @override
  String get rdStartCooking => 'Počni kuhati';

  @override
  String rdAddedMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dodano $count proizvoda u kupovinu',
      one: 'Dodano na listu za kupovinu',
    );
    return '$_temp0';
  }

  @override
  String get rdNeedProfile =>
      'Dopuni nutritivni profil da vidiš koliko grama i kalorija pripada svakoj osobi.';

  @override
  String get rdMember => 'Član';

  @override
  String get rdAdjustSplit =>
      'Prilagodi raspodjelu kalorija po obroku u profilu za ovu vrstu recepta.';

  @override
  String get rdByProfile => 'Prema profilu svakog';

  @override
  String get rdByProfileHint => 'Količina i kalorije po osobi za ovaj obrok.';

  @override
  String get arWriteName => 'Upiši naziv';

  @override
  String get arWriteNameHint => 'Upiši naziv ili zalijepi cijeli recept…';

  @override
  String get arGenerate => 'Generiši';

  @override
  String get arFilled => 'Recept je popunjen. Provjeri ga prije čuvanja.';

  @override
  String get arFillError => 'Recept nije dovršen';

  @override
  String get arImport => 'Uvezi recept';

  @override
  String get arPasteRecipe => 'Zalijepi recept';

  @override
  String get arImportHint =>
      'Zalijepi link s TikToka, YouTubea ili web stranice, ili tekst recepta. Na Instagramu kopiraj opis objave i zalijepi ga ovdje.';

  @override
  String get arLinkOrText => 'Link ili tekst recepta';

  @override
  String get arRecipeText => 'Tekst recepta';

  @override
  String get paste => 'Zalijepi';

  @override
  String get arImportBtn => 'Uvezi';

  @override
  String get arNeedLink => 'Zalijepi link ili cijeli tekst recepta.';

  @override
  String get arImported => 'Recept je uvezen. Provjeri ga prije čuvanja.';

  @override
  String get arImportLinkError => 'Nisam mogao uvesti recept s tog linka';

  @override
  String get arImportError => 'Uvoz nije uspio';

  @override
  String get arPickMealType => 'Izaberi barem jednu vrstu obroka.';

  @override
  String get arVideoNotUrl =>
      'Link videa ne izgleda kao URL, ali ga ipak čuvamo.';

  @override
  String get arRecalculated => 'Kalorije i makroi preračunati iz sastojaka.';

  @override
  String arPhotoFailed(String error) {
    return 'Recept je sačuvan, ali fotografija nije otpremljena: $error';
  }

  @override
  String get arSaveError => 'Greška pri čuvanju';

  @override
  String get arReadingVideo => 'Čitam recept iz videa…';

  @override
  String get arCompleting => 'Dovršavam recept…';

  @override
  String get arAddPhoto => 'Dodaj fotografiju (neobavezno)';

  @override
  String get arTitleField => 'Naslov';

  @override
  String get arTitleRequired => 'Daj mu naslov';

  @override
  String get arDescription => 'Opis (neobavezno)';

  @override
  String get arVideoLink => 'Link videa (neobavezno)';

  @override
  String get arMealTypes => 'Vrsta obroka (možeš izabrati više)';

  @override
  String get arAuto => 'Auto';

  @override
  String get arServingsHelper => 'Za koliko je';

  @override
  String get arGramsServing => 'Grami / porcija';

  @override
  String get arNutritionTitle => 'Nutritivne vrijednosti (po porciji)';

  @override
  String get arCooking => 'Kuhanje';

  @override
  String get arPrepMin => 'Priprema (min)';

  @override
  String get arCookMin => 'Kuhanje (min)';

  @override
  String get arAppliance => 'Glavni uređaj';

  @override
  String get arFreezable => 'Može se zamrznuti';

  @override
  String get arAddIngredient => 'Dodaj sastojak';

  @override
  String get arStepsTitle => 'Koraci pripreme';

  @override
  String get arStepsHint => 'Upiši korake, jedan po redu…';

  @override
  String get arSaveChanges => 'Sačuvaj izmjene';

  @override
  String get arSaveRecipe => 'Sačuvaj recept';

  @override
  String get arIngredient => 'Sastojak';

  @override
  String get tskWhoDid => 'Ko je uradio zadatak?';

  @override
  String get tskTheHome => 'domaćinstvo';

  @override
  String tskPointsFor(int points, String who) {
    return '+$points bodova za $who';
  }

  @override
  String tskPointsForPantry(int points, String who, int count) {
    return '+$points bodova za $who. $count proizvoda u ostavu';
  }

  @override
  String tskYou(String name) {
    return '$name (ti)';
  }

  @override
  String get tskThisMember => 'ovog člana';

  @override
  String get tskResetPoints => 'Resetuj bodove';

  @override
  String tskResetAsk(String name) {
    return 'Bodovi za $name bit će postavljeni na 0. Ovo se ne može poništiti. Sigurno?';
  }

  @override
  String get tskReset => 'Resetuj';

  @override
  String tskResetDone(String name) {
    return 'Bodovi za $name resetovani.';
  }

  @override
  String get tskDeleteTitle => 'Obrisati zadatak?';

  @override
  String tskDeleteAsk(String title) {
    return '\"$title\" će biti obrisan.';
  }

  @override
  String tskClaimed(String title) {
    return '\"$title\" je tvoj';
  }

  @override
  String get tskDone => 'Urađeno';

  @override
  String get tskToTomorrow => 'Prebaci na sutra';

  @override
  String get tskToNextWeek => 'Prebaci na sljedeću sedmicu';

  @override
  String get tskTitle => 'Zadaci';

  @override
  String get tskEmptyTitle => 'Još nema zadataka';

  @override
  String get tskEmptyHint => 'Dodaj prvi.';

  @override
  String get tskNew => 'Novi zadatak';

  @override
  String get tskAnyone => 'Bilo ko';

  @override
  String get tskForToday => 'Za danas';

  @override
  String get tskUpcoming => 'Narednih dana';

  @override
  String get tskPoolEmpty => 'Ništa u zajedničkom. Sve ima vlasnika.';

  @override
  String get tskSwipeToClaim => 'Prevuci ulijevo da ga preuzmeš.';

  @override
  String get tskNothingDone => 'Danas još ništa nije urađeno.';

  @override
  String get tskAll => 'Sve';

  @override
  String get tskMine => 'Moji';

  @override
  String get tskAllDoneToday => 'Danas je sve urađeno';

  @override
  String get tskNextBelow => 'Sljedeće je ispod.';

  @override
  String get tskNothingLeft => 'Ništa nije ostalo.';

  @override
  String get tskScoreboard => 'REZULTAT';

  @override
  String get tskPointsPerPerson => 'BODOVI PO OSOBI';

  @override
  String get tskNoPoints => 'Još nema bodova';

  @override
  String get tskNoPointsHint => 'Završavaj zadatke da skupljaš bodove.';

  @override
  String get tskSomeDays => 'Neki dani';

  @override
  String get tskOnce => 'Jednom';

  @override
  String get tskNothingToday => 'Ništa za danas';

  @override
  String get tskAllDone => 'Sve urađeno';

  @override
  String tskLeft(int count) {
    return 'Preostalo: $count';
  }

  @override
  String tskOverdueCount(int count) {
    return 'Kasni: $count';
  }

  @override
  String tskMarkDone(String title) {
    return 'Označi $title kao urađeno';
  }

  @override
  String tskClaim(String title) {
    return 'Preuzmi $title';
  }

  @override
  String get tskOverdue => 'Kasni';

  @override
  String tskPts(int points) {
    return '$points b.';
  }

  @override
  String tskView(String view) {
    String _temp0 = intl.Intl.selectLogic(view, {
      'pending': 'Na čekanju',
      'pool': 'Zajedničko',
      'other': 'Urađeno',
    });
    return '$_temp0';
  }

  @override
  String get tskOtherDay => 'Drugi dan';

  @override
  String get tskEdit => 'Uredi zadatak';

  @override
  String get tskNameHint => 'Naziv zadatka';

  @override
  String get tskOrTypeAnother => 'Ili upiši drugi';

  @override
  String get tskWhen => 'Kada';

  @override
  String get tomorrow => 'Sutra';

  @override
  String get tskNoDate => 'Bez datuma';

  @override
  String get tskRepeats => 'Ponavlja se';

  @override
  String get tskWho => 'Ko';

  @override
  String get tskMe => 'Ja';

  @override
  String get tskAddPersonHint =>
      'Da ga dodijeliš nekome, dodaj tu osobu u Dom (čak i bez računa).';

  @override
  String get tskDetails => 'Detalji';

  @override
  String get tskNoTime => 'Bez vremena';

  @override
  String get tskRemoveTime => 'Ukloni vrijeme';

  @override
  String tskFreeAt(String time) {
    return 'Slobodno u $time';
  }

  @override
  String get tskNotes => 'Bilješke';

  @override
  String get tskPoints => 'Bodovi';

  @override
  String get tskAdd => 'Dodaj zadatak';

  @override
  String get arcTitle => 'Dodaj recept';

  @override
  String get arcLinkTitle => 'Zalijepi link videa';

  @override
  String get arcLinkSub => 'Sa TikToka ili YouTubea, ili tekst s Instagrama';

  @override
  String get arcNameTitle => 'Upiši naziv';

  @override
  String get arcNameSub => 'Dopunjava se sastojcima, koracima i makroima';

  @override
  String get arcIdeasTitle => 'Ideje za tebe';

  @override
  String get arcIdeasSub => 'Prema tvom marketu, cilju i budžetu';

  @override
  String get arcManualTitle => 'Ručno';

  @override
  String get arcManualSub => 'Sam popuni svako polje';

  @override
  String get arcCodeTitle => 'Sa kodom';

  @override
  String get arcCodeSub => 'Sačuvaj recept koji su ti podijelili';

  @override
  String get arcCodeDialog => 'Kod recepta';

  @override
  String get search => 'Traži';

  @override
  String get arcNoCode => 'Nema recepta s tim kodom';

  @override
  String arcIngredientsAsk(int count) {
    return '$count sastojaka. Sačuvati u tvoje recepte?';
  }

  @override
  String get arcSaved => 'Recept sačuvan';

  @override
  String get nutLoadError => 'Greška pri učitavanju profila';

  @override
  String get nutSaved => 'Profil sačuvan';

  @override
  String get nutSaveError => 'Greška pri spremanju';

  @override
  String get nutBirthDate => 'Datum rođenja';

  @override
  String get nutTitle => 'Moj nutritivni profil';

  @override
  String get nutDiary => 'Dnevnik kalorija';

  @override
  String get nutWizard => 'Podesi korak po korak';

  @override
  String get nutWizardSub =>
      'Asistent ti postavi nekoliko pitanja i izračuna tvoj cilj.';

  @override
  String get nutHowCook => 'Kako kuhaš?';

  @override
  String get nutDaily => 'Svaki dan';

  @override
  String get nutDailySub => 'Kuham svaki dan';

  @override
  String get nutBatch => 'Kuhanje unaprijed';

  @override
  String get nutBatchSub => 'Kuham jednom za više dana';

  @override
  String get nutAmounts => 'Količine';

  @override
  String get nutPractical => 'Praktične';

  @override
  String get nutPracticalSub => 'Pakovanja iz marketa';

  @override
  String get nutExact => 'Tačne';

  @override
  String get nutExactSub => 'Na gram';

  @override
  String get nutSex => 'Spol';

  @override
  String get nutFemale => 'Žensko';

  @override
  String get nutMale => 'Muško';

  @override
  String get nutSelect => 'Odaberi…';

  @override
  String nutAge(int age) {
    return '($age god.)';
  }

  @override
  String get nutHeight => 'Visina (cm)';

  @override
  String get nutWeight => 'Težina (kg)';

  @override
  String get nutActivityLevel => 'Nivo aktivnosti';

  @override
  String get nutGoalLabel => 'Cilj';

  @override
  String nutActivity(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'sedentary': 'Sjedilački (malo ili nimalo vježbe)',
      'light': 'Lagano (1-3 dana/sedmično)',
      'moderate': 'Umjereno (3-5 dana/sedmično)',
      'active': 'Aktivno (6-7 dana/sedmično)',
      'other': 'Vrlo aktivno (intenzivna vježba ili fizički posao)',
    });
    return '$_temp0';
  }

  @override
  String nutGoal(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'lose': 'Smršati',
      'gain': 'Udebljati se',
      'other': 'Održati težinu',
    });
    return '$_temp0';
  }

  @override
  String get nutSplit => 'Raspodjela kalorija po obroku';

  @override
  String nutTotal(int pct) {
    return 'Ukupno: $pct%';
  }

  @override
  String get nutSplitHint =>
      'Stavi 0% za obroke koje preskačeš. Zbir treba biti 100%.';

  @override
  String get nutAtHome => 'Obroci kod kuće';

  @override
  String get nutAtHomeHint =>
      'Označi dane kad jedeš svaki obrok kod kuće. Ako jedeš vani (npr. na poslu), odznači taj dan i neće se računati.';

  @override
  String get nutShare => 'Podijeli moj profil s domaćinstvom';

  @override
  String get nutShareSub => 'Ako je isključeno, tvoj profil je privatan.';

  @override
  String get nutSave => 'Sačuvaj profil';

  @override
  String get nutIncomplete =>
      'Unesi spol, datum rođenja, visinu i težinu da izračunaš dnevne kalorije i makroe.';

  @override
  String get nutDailyTarget => 'Tvoj dnevni cilj (otprilike)';

  @override
  String nutKcalDay(int kcal) {
    return '$kcal kcal / dan';
  }

  @override
  String nutPerMeal(int kcal, int meals) {
    return '≈ $kcal kcal po obroku ($meals obroka)';
  }

  @override
  String get ecoBudgetTitle => 'Mjesečni budžet';

  @override
  String ecoAmount(String symbol) {
    return 'Iznos ($symbol)';
  }

  @override
  String get ecoDeleteTicket => 'Obrisati račun?';

  @override
  String get ecoDeleteTicketSub => 'Više se neće računati u tvoje troškove.';

  @override
  String ecoRedeemed(String title) {
    return 'Iskoristio/la si \"$title\"';
  }

  @override
  String get ecoRedeemFail =>
      'Nije moguće iskoristiti. Možda nemaš dovoljno bodova.';

  @override
  String get ecoNewReward => 'Nova nagrada';

  @override
  String get ecoRewardTitle => 'Naslov';

  @override
  String get ecoRewardDesc => 'Opis (neobavezno)';

  @override
  String get ecoRewardCost => 'Cijena u bodovima';

  @override
  String get ecoTitle => 'Troškovi i računi';

  @override
  String get ecoStats => 'Statistika kupovine';

  @override
  String get ecoScan => 'Skeniraj račun';

  @override
  String ecoTicketsOf(String month) {
    return 'Računi za $month';
  }

  @override
  String get ecoPointsBalance => 'Stanje bodova';

  @override
  String get ecoPointsBalanceSub => 'Stanje svakog člana za nagrade.';

  @override
  String get ecoNoPoints => 'Još nema bodova za podjelu';

  @override
  String get ecoNoPointsSub => 'Završavajte kućne zadatke da skupite bodove.';

  @override
  String get ecoRewards => 'Nagrade';

  @override
  String ecoBalance(int points) {
    return 'Tvoje stanje: $points b.';
  }

  @override
  String get ecoRedeem => 'Iskoristi';

  @override
  String get ecoNoRewards => 'Još nema nagrada';

  @override
  String get ecoNoRewardsSub => 'Napravi prvu dugmetom \"Nova nagrada\".';

  @override
  String get ecoTotalSpent => 'Ukupno zabilježeni trošak';

  @override
  String ecoTicketCount(int count) {
    return 'Ukupno računa: $count';
  }

  @override
  String get ecoThisMonth => 'Ovaj mjesec';

  @override
  String ecoBudget(String amount) {
    return 'Budžet: $amount';
  }

  @override
  String get ecoSetBudget => 'Postavi budžet';

  @override
  String ecoOver(String amount) {
    return 'Prekoračio/la si budžet za $amount';
  }

  @override
  String ecoLeft(String amount) {
    return 'Preostalo ti je $amount';
  }

  @override
  String get ecoLastMonths => 'Troškovi zadnjih mjeseci';

  @override
  String ecoBudgetPerMonth(String amount) {
    return 'Budžet: $amount mjesečno';
  }

  @override
  String get ecoBudgetShort => 'Budžet';

  @override
  String get ecoNoTrend =>
      'Još nema troškova u zadnjim mjesecima.\nSkeniraj račune da ovdje vidiš trend.';

  @override
  String get ecoTicket => 'Račun';

  @override
  String get ecoNoTickets => 'Još nema računa ovaj mjesec.\nSkeniraj prvi.';

  @override
  String get stOthers => 'Ostalo';

  @override
  String get stNoCategory => 'Bez kategorije';

  @override
  String get stThisWeek => 'Ova';

  @override
  String get stTitle => 'Tvoji podaci';

  @override
  String get stSpendByMonth => 'Troškovi po mjesecu';

  @override
  String get stForecastFooter => 'Svijetlo: koliko fali do prognoze';

  @override
  String get stNoSpend => 'Skeniraj račun da vidiš troškove po mjesecima.';

  @override
  String get stWhereSpend => 'Na šta trošiš ovaj mjesec';

  @override
  String get stNoTicketsMonth => 'Još nema računa ovaj mjesec.';

  @override
  String get stTopProducts => 'Šta najviše kupuješ';

  @override
  String get stTopProductsFooter => 'Broj puta na računima u zadnja 3 mjeseca';

  @override
  String get stTopProductsEmpty => 'Pojavit će se kad skeniraš račune.';

  @override
  String get stPantry => 'Tvoja ostava';

  @override
  String get stMealsHome => 'Obroci kod kuće';

  @override
  String get stPerWeek => 'Po sedmici';

  @override
  String stMealsOut(int count) {
    return 'Po sedmici · $count van kuće';
  }

  @override
  String get stMealsEmpty =>
      'Planiraj obroke da vidiš koliko ih jedete kod kuće.';

  @override
  String get stTasksDone => 'Urađeni zadaci';

  @override
  String get stTasksFooter => 'Po sedmici i ko je najviše uradio ovaj mjesec';

  @override
  String get stTasksEmpty => 'Završeni zadaci pojavit će se ovdje.';

  @override
  String get stSoFar => 'Potrošeno ovaj mjesec';

  @override
  String get stForecast => 'Prognoza: ';

  @override
  String stMoreThanAvg(int pct) {
    return ', $pct% više od tvog prosjeka';
  }

  @override
  String stLessThanAvg(int pct) {
    return ', $pct% manje od tvog prosjeka';
  }

  @override
  String get stTickets => 'Računi';

  @override
  String get stExpired => 'Isteklo';

  @override
  String get stExpiringSoon => 'Uskoro ističe';

  @override
  String get stFresh => 'Dobro';

  @override
  String stOverForecast(String amount) {
    return 'Ovim tempom prekoračit ćeš budžet za $amount';
  }

  @override
  String stForecastTip(String amount) {
    return 'Prognoza $amount';
  }

  @override
  String get pwPickOption => 'Odaberi opciju za nastavak.';

  @override
  String get pwPickBirth => 'Odaberi datum rođenja.';

  @override
  String get pwBadHeight => 'Unesi ispravnu visinu u centimetrima.';

  @override
  String get pwBadWeight => 'Unesi ispravnu težinu u kilogramima.';

  @override
  String get pwCompleteStep => 'Završi ovaj korak za nastavak.';

  @override
  String get pwStart => 'Počni koristiti PrezHome';

  @override
  String get pwSeeGoal => 'Vidi moj cilj';

  @override
  String get pwFinish => 'Završi';

  @override
  String get pwIntroTitle => 'Upoznajmo se';

  @override
  String get pwIntroSub =>
      'Nekoliko brzih pitanja da prilagodimo PrezHome tebi. Možeš promijeniti kad hoćeš.';

  @override
  String get pwTrackKcal => 'Želim pratiti kalorije';

  @override
  String get pwTrackKcalSub => 'Planirani obroci se sami upisuju kad prođu.';

  @override
  String get pwOnlyHome => 'Samo organizirati dom';

  @override
  String get pwOnlyHomeSub => 'Bez težine i mjera.';

  @override
  String get pwSex => 'Tvoj spol';

  @override
  String get pwSexSub => 'Koristimo ga za precizniji izračun metabolizma.';

  @override
  String get pwPickDate => 'Odaberi datum';

  @override
  String get pwBirthTitle => 'Kada si rođen/a?';

  @override
  String get pwBirthSub =>
      'Godine nam pomažu da preciznije izračunamo kalorije.';

  @override
  String pwAgeYears(int age) {
    return '$age godina';
  }

  @override
  String get pwHeightTitle => 'Koliko si visok/a?';

  @override
  String get pwHeightSub => 'Unesi visinu u centimetrima.';

  @override
  String get pwWeightTitle => 'Koliko težiš?';

  @override
  String get pwWeightSub => 'Unesi trenutnu težinu u kilogramima.';

  @override
  String get pwActivityTitle => 'Tvoj nivo aktivnosti';

  @override
  String get pwActivitySub => 'Odaberi šta najbolje opisuje tvoju sedmicu.';

  @override
  String get pwGoalTitle => 'Koji je tvoj cilj?';

  @override
  String get pwGoalSub => 'Prilagodit ćemo kalorije onome što želiš postići.';

  @override
  String pwGoalDesc(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'lose': 'Blagi deficit za postepeno mršavljenje.',
      'gain': 'Blagi suficit za zdravo dobijanje mase.',
      'other': 'Zadržati trenutnu težinu i osjećati se dobro.',
    });
    return '$_temp0';
  }

  @override
  String get pwDietTitle => 'Kako se hraniš?';

  @override
  String get pwDietSub => 'Recepti će se prilagoditi tvojoj ishrani.';

  @override
  String pwDiet(String diet) {
    String _temp0 = intl.Intl.selectLogic(diet, {
      'vegetariana': 'Vegetarijanska',
      'vegana': 'Veganska',
      'pescetariana': 'Peskaterijanska',
      'baja_carbo': 'Malo ugljikohidrata',
      'sin_gluten': 'Bez glutena',
      'other': 'Sve',
    });
    return '$_temp0';
  }

  @override
  String get pwAllergiesTitle => 'Alergije ili netolerancije';

  @override
  String get pwOptional => 'Neobavezno.';

  @override
  String pwAllergy(String allergy) {
    String _temp0 = intl.Intl.selectLogic(allergy, {
      'frutossecos': 'orašasti plodovi',
      'lactosa': 'laktoza',
      'gluten': 'gluten (celijakija)',
      'huevo': 'jaja',
      'marisco': 'plodovi mora',
      'soja': 'soja',
      'other': 'riba',
    });
    return '$_temp0';
  }

  @override
  String get pwCuisinesTitle => 'Šta voliš jesti?';

  @override
  String get pwCuisinesSub => 'Odaberi koliko želiš.';

  @override
  String pwCuisine(String cuisine) {
    String _temp0 = intl.Intl.selectLogic(cuisine, {
      'casera': 'Domaća kuhinja',
      'mediterranea': 'Mediteranska',
      'ligera': 'Lagana',
      'rapida': 'Brzo i jednostavno',
      'italiana': 'Italijanska',
      'asiatica': 'Azijska',
      'mexicana': 'Meksička',
      'other': 'Iz cijelog svijeta',
    });
    return '$_temp0';
  }

  @override
  String get pwAppliancesTitle => 'Šta imaš u kuhinji?';

  @override
  String get pwAppliancesSub =>
      'Plan će koristiti samo recepte koje možeš napraviti.';

  @override
  String appliance(String appliance) {
    String _temp0 = intl.Intl.selectLogic(appliance, {
      'oven': 'Rerna',
      'stovetop': 'Tava',
      'pot': 'Lonac',
      'airfryer': 'Air fryer',
      'microwave': 'Mikrovalna',
      'blender': 'Blender',
      'other': 'Ništa',
    });
    return '$_temp0';
  }

  @override
  String get pwDislikedTitle => 'Sastojci koje ne voliš';

  @override
  String get pwDislikedSub => 'Odvojeni zarezima. Neobavezno.';

  @override
  String get pwDislikedHint => 'luk, korijander...';

  @override
  String get pwCookTimeTitle => 'Koliko vremena želiš kuhati?';

  @override
  String get pwCookTimeSub =>
      'Tako prilagođavam recepte tvom ritmu. Možeš ostaviti prazno.';

  @override
  String pwCookTime(String time) {
    String _temp0 = intl.Intl.selectLogic(time, {
      'rapido': 'Brzo (manje od 20 min)',
      'elaborado': 'Složeno (volim kuhati)',
      'other': 'Normalno',
    });
    return '$_temp0';
  }

  @override
  String pwCookTimeDesc(String time) {
    String _temp0 = intl.Intl.selectLogic(time, {
      'rapido': 'Jela gotova za kratko vrijeme.',
      'elaborado': 'Uživam kuhati polako.',
      'other': 'Balans između brzog i složenog.',
    });
    return '$_temp0';
  }

  @override
  String get pwCookStyleTitle => 'Kako najradije kuhaš?';

  @override
  String get pwChangeAnytime => 'Možeš promijeniti kad hoćeš.';

  @override
  String cookStyle(String style) {
    String _temp0 = intl.Intl.selectLogic(style, {
      'batch': 'Unaprijed',
      'mixed': 'Kombinovano',
      'other': 'Svaki dan',
    });
    return '$_temp0';
  }

  @override
  String cookStyleSub(String style) {
    String _temp0 = intl.Intl.selectLogic(style, {
      'batch': 'Kuham unaprijed za više dana',
      'mixed': 'Kombinujem kuhanje unaprijed i svakodnevno',
      'other': 'Kuham svaki dan svježe',
    });
    return '$_temp0';
  }

  @override
  String get pwModulesTitle => 'Šta želiš uključiti?';

  @override
  String get pwModulesSub => 'Ono što isključiš neće se prikazivati.';

  @override
  String homeModule(String module) {
    String _temp0 = intl.Intl.selectLogic(module, {
      'points': 'Način bodova',
      'tasks': 'Zadaci',
      'other': 'Kuhanje unaprijed',
    });
    return '$_temp0';
  }

  @override
  String homeModuleDesc(String module) {
    String _temp0 = intl.Intl.selectLogic(module, {
      'points': 'Osvajaj bodove i nagrade za zadatke.',
      'tasks': 'Organizuj kućne zadatke.',
      'other': 'Kuhaj unaprijed i planiraj pripremu.',
    });
    return '$_temp0';
  }

  @override
  String get pwAllSet => 'Sve je spremno';

  @override
  String get pwAllSetSub =>
      'Recepti, plan i kupovina se prilagođavaju onome što si rekao/la.';

  @override
  String get pwDailyGoal => 'Tvoj dnevni cilj';

  @override
  String get pwKcalDay => 'kcal / dan';

  @override
  String get pwEstimate =>
      'Ovo je početna procjena. Planirani obroci će se sami upisati u dnevnik kad prođu.';

  @override
  String get phCantAnalyze => 'Nije moguće analizirati obrok';

  @override
  String phAnalyzeError(String error) {
    return 'Greška pri analizi fotografije: $error';
  }

  @override
  String get phAnalyzeFail => 'Greška pri analizi fotografije';

  @override
  String get phAddOne => 'Dodaj barem jednu namirnicu s nazivom.';

  @override
  String get phTitle => 'Upiši fotografijom';

  @override
  String get phLooking => 'Gledam tanjir…';

  @override
  String get phStartTitle => 'Fotografiši svoj tanjir';

  @override
  String get phStartSub =>
      'Prepoznajemo namirnice i kalorije. Možeš ispraviti prije spremanja.';

  @override
  String get takePhoto => 'Uslikaj';

  @override
  String get phReview => 'Provjeri i ispravi prepoznato';

  @override
  String get phApprox => 'Kalorije su približne.';

  @override
  String get phMealType => 'Obrok (neobavezno)';

  @override
  String get phNoType => 'Bez vrste';

  @override
  String get day => 'Dan';

  @override
  String get phNothing => 'Nijedna namirnica nije prepoznata. Dodaj ručno.';

  @override
  String phFoods(int count) {
    return 'NAMIRNICE ($count)';
  }

  @override
  String get phAddFood => 'Dodaj namirnicu';

  @override
  String get phFood => 'Namirnica';

  @override
  String get phGrams => 'g (otpr.)';

  @override
  String get phP => 'P (g)';

  @override
  String get phC => 'UH (g)';

  @override
  String get phF => 'M (g)';

  @override
  String get total => 'Ukupno';

  @override
  String kcalAmount(int kcal) {
    return '$kcal kcal';
  }

  @override
  String get phSave => 'Spremi u dnevnik';

  @override
  String get stkOpenError => 'Nije moguće otvoriti račun';

  @override
  String get stkReadError => 'Nije moguće pročitati račun';

  @override
  String get stkScanError => 'Greška pri skeniranju';

  @override
  String get stkPantryError => 'Račun je spremljen, ali ostava nije ažurirana';

  @override
  String stkCrossed(int count) {
    return 'Precrtano s liste: $count';
  }

  @override
  String get stkEdit => 'Uredi račun';

  @override
  String get stkReading => 'Čitam račun…';

  @override
  String get stkStartTitle => 'Skeniraj račun iz kupovine';

  @override
  String get stkStartSub =>
      'Izvlačimo proizvode i cijene. Možeš provjeriti poslije.';

  @override
  String get stkReview => 'Provjeri i ispravi šta treba';

  @override
  String get stkRemember => 'Tvoje ispravke će se zapamtiti za sljedeći put.';

  @override
  String get stkStore => 'Prodavnica';

  @override
  String get date => 'Datum';

  @override
  String get stkAddPantry => 'Dodaj u ostavu';

  @override
  String get stkAddPantrySub => 'Svaki proizvod ide na svoje mjesto';

  @override
  String stkProducts(int count) {
    return 'PROIZVODI ($count)';
  }

  @override
  String stkRaw(String name) {
    return 'Račun: \"$name\"';
  }

  @override
  String get category => 'Kategorija';

  @override
  String get stkQty => 'Kol.';

  @override
  String get stkSave => 'Spremi račun';

  @override
  String foodCategory(String cat) {
    String _temp0 = intl.Intl.selectLogic(cat, {
      'verdura': 'Povrće',
      'fruta': 'Voće',
      'carne': 'Meso',
      'pescado': 'Riba',
      'lacteos': 'Mliječni proizvodi',
      'preparados': 'Gotova jela',
      'panaderia': 'Pekara',
      'cereales': 'Tjestenina, riža i mahunarke',
      'conservas': 'Konzerve',
      'congelados': 'Smrznuto',
      'dulces': 'Slatkiši i grickalice',
      'bebidas': 'Pića',
      'especias': 'Začini i dodaci',
      'higiene': 'Higijena',
      'limpieza': 'Čišćenje',
      'hogar': 'Domaćinstvo',
      'other': 'Ostalo',
    });
    return '$_temp0';
  }

  @override
  String get cookMode => 'Način kuhanja';

  @override
  String get bpMeanwhile => 'U međuvremenu';

  @override
  String bpTapers(String title) {
    return 'Posude · $title';
  }

  @override
  String get bpBatchCook => 'Kuhanje unaprijed';

  @override
  String get bpStart => 'Počni korak po korak';

  @override
  String bpHeroTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recepata odjednom',
      few: '$count recepta odjednom',
      one: '1 recept odjednom',
    );
    return '$_temp0';
  }

  @override
  String bpSteps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count koraka',
      few: '$count koraka',
      one: '1 korak',
    );
    return '$_temp0';
  }

  @override
  String get bpStepsTitle => 'Kako ide kuhanje';

  @override
  String get bpCooking => 'Šta ćeš kuhati';

  @override
  String get cmTimer => 'Tajmer';

  @override
  String cmIngredientsReady(int done, int total) {
    return '$done od $total spremno';
  }

  @override
  String get bpEmpty => 'Trenutno nema ništa za kuhati';

  @override
  String get bpEmptySub =>
      'Kad budeš imao/la planirane recepte, ovdje ću pripremiti plan da sve skuhaš odjednom.';

  @override
  String get bpNeed => 'Šta ti treba';

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String get ready => 'Gotovo';

  @override
  String get pause => 'Pauza';

  @override
  String get start => 'Pokreni';

  @override
  String get reset => 'Resetuj';

  @override
  String cmStep(int n) {
    return 'Korak $n';
  }

  @override
  String get cmTime => 'Vrijeme je';

  @override
  String get cmSeeStep => 'Vidi korak';

  @override
  String get ok => 'U redu';

  @override
  String get cmMicPermission => 'Za glas dozvoli mikrofon u Postavkama.';

  @override
  String get ingredients => 'Sastojci';

  @override
  String get cmExit => 'Izađi iz načina kuhanja';

  @override
  String get cmHandsFreeOff => 'Isključi bez ruku';

  @override
  String get cmHandsFree => 'Bez ruku';

  @override
  String get cmVoiceHint =>
      'Reci «siguiente», «anterior», «repite» ili «temporizador» (glas za sada radi na španskom)';

  @override
  String get cmStop => 'Zaustavi';

  @override
  String cmStepOf(int n, int total) {
    return 'KORAK $n OD $total';
  }

  @override
  String get cmTimerRunning => 'Tajmer radi';

  @override
  String get cmThen => 'Zatim';

  @override
  String get cmNextStep => 'Sljedeći korak';

  @override
  String get shopSugDue => 'Vrijeme je';

  @override
  String get shopSugOut => 'Nedostaje kod kuće';

  @override
  String get shopOutAtHome => 'Potrošeno kod kuće';

  @override
  String get shopGridView => 'Prikaz u mreži';

  @override
  String get shopGridHint => 'Velike fotografije, dvije u redu';

  @override
  String get shopShowSuggestions => 'Prikaži prijedloge';

  @override
  String get shopSuggestionsHint =>
      'Šta treba dokupiti i šta je potrošeno kod kuće';

  @override
  String get shopShowPrices => 'Prikaži cijene';

  @override
  String shopEveryDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Svakih $n dana',
      one: 'Svaki dan',
    );
    return '$_temp0';
  }

  @override
  String get slNewList => 'Nova lista';

  @override
  String get slMyLists => 'Moje liste';

  @override
  String get slActive => 'Aktivna';

  @override
  String get slNewCat => 'Nova kategorija';

  @override
  String get slRenameCat => 'Preimenuj kategoriju';

  @override
  String get slCategories => 'Kategorije';

  @override
  String get slAddCat => 'Dodaj kategoriju';

  @override
  String get slNoCats => 'Još nema kategorija. Dodaj prvu dugmetom ispod.';

  @override
  String get rename => 'Preimenuj';

  @override
  String ppDayMeals(String day, int count) {
    return '$day, obroka: $count';
  }

  @override
  String ppFastTime(String time) {
    return '$time · Post';
  }

  @override
  String get ppEatOut => '· Vani';

  @override
  String mealAdd(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'breakfast': 'Dodaj doručak',
      'lunch': 'Dodaj ručak',
      'snack': 'Dodaj užinu',
      'dinner': 'Dodaj večeru',
      'dessert': 'Dodaj desert',
      'other': 'Dodaj obrok',
    });
    return '$_temp0';
  }

  @override
  String get ppFromFreezer => 'Iz zamrzivača';

  @override
  String ppServings(int count) {
    return 'Porcija: $count';
  }

  @override
  String get ppFresh => 'Tek napravljeno';

  @override
  String ppFridge(String days) {
    return 'Frižider · $days';
  }

  @override
  String ppFreezer(String days) {
    return 'Zamrzivač · $days';
  }

  @override
  String get ppTapersAuto => 'Posude se same dodaju u Moja kuhinja';

  @override
  String drGoal(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'lose': 'Gubitak masti',
      'gain': 'Izgradnja mišića',
      'protein': 'Visokoproteinski',
      'other': 'Održavanje',
    });
    return '$_temp0';
  }

  @override
  String drDiet(String diet) {
    String _temp0 = intl.Intl.selectLogic(diet, {
      'veg': 'Vegetarijanska',
      'vegan': 'Veganska',
      'quick': 'Brza',
      'lowcarb': 'Malo ugljikohidrata',
      'other': 'Bez ograničenja',
    });
    return '$_temp0';
  }

  @override
  String drFreeOf(String allergen) {
    String _temp0 = intl.Intl.selectLogic(allergen, {
      'gluten': 'Bez glutena (celijakija)',
      'lactosa': 'Bez laktoze',
      'huevo': 'Bez jaja',
      'marisco': 'Bez morskih plodova',
      'soja': 'Bez soje',
      'other': 'Bez orašastih plodova',
    });
    return '$_temp0';
  }

  @override
  String get drAnyType => 'Bilo šta';

  @override
  String get drNoIdeas => 'Nisu stigle ideje';

  @override
  String get drSaved => 'Sačuvano u tvojim receptima';

  @override
  String get drSearchSuper => 'Traži supermarket...';

  @override
  String get drNoSuper => 'Nismo pronašli taj supermarket.';

  @override
  String get drTitlePantry => 'Šta da skuham s ovim?';

  @override
  String get drTitle => 'Personalizovane ideje';

  @override
  String get drNewIdeas => 'Nove ideje';

  @override
  String get drWithPantry => 'Sa onim što imam';

  @override
  String get drPantryLoading => 'Gledamo tvoju ostavu…';

  @override
  String get drPantryEmpty =>
      'Tvoja ostava je prazna: dodaj šta imaš kod kuće da dobiješ ideje.';

  @override
  String drPantryUse(int count) {
    return 'Koristićemo $count namirnica iz ostave, počevši od onih kojima prvo ističe rok.';
  }

  @override
  String get drCraving => 'Šta ti se jede?';

  @override
  String get drSupers => 'Supermarketi';

  @override
  String get drSupersHint =>
      'Opcionalno. Ako ne izabereš nijedan, recepti važe za svaki supermarket.';

  @override
  String get drGoalTitle => 'Cilj';

  @override
  String get drDietTitle => 'Ishrana';

  @override
  String drDietLocked(String diet) {
    return 'Koristimo ishranu iz tvog profila: $diet';
  }

  @override
  String get drAllergyTitle => 'Intolerancije i alergije';

  @override
  String get drAllergyHint => 'Nikad se neće pojaviti u receptima.';

  @override
  String get drAppliances => 'Kuhinjski aparati';

  @override
  String get drMaxCost => 'Najveća cijena po porciji';

  @override
  String get drMaxCostHint => 'Opcionalno, npr. 2,50';

  @override
  String get drSearching => 'Tražimo ideje…';

  @override
  String get drSeeIdeas => 'Pogledaj ideje';

  @override
  String drAddedToShop(int count) {
    return 'Dodano na listu za kupovinu: $count';
  }

  @override
  String get drAddFail =>
      'Nije moguće dodati na listu. Provjeri vezu i pokušaj ponovo.';

  @override
  String drProteinShort(String grams) {
    return 'P: ${grams}g';
  }

  @override
  String get drCostTip =>
      'Okvirno: cijene s tvojih računa ili prosječne cijene u supermarketu.';

  @override
  String drPerServing(String price) {
    return '≈ $price/porcija';
  }

  @override
  String get drHave => 'Imaš:';

  @override
  String get drMissing => 'Nedostaje ti:';

  @override
  String get drAddedShort => 'Dodano u kupovinu';

  @override
  String get drAddMissing => 'Dodaj ono što nedostaje';

  @override
  String get drSavedShort => 'Sačuvano';

  @override
  String get drSaveToRecipes => 'Sačuvaj u moje recepte';

  @override
  String taskKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'bano': 'Kupatilo',
      'ropa': 'Veš',
      'compra': 'Kupovina',
      'basura': 'Smeće',
      'platos': 'Suđe',
      'limpieza': 'Čišćenje',
      'plantas': 'Biljke',
      'cama': 'Krevet',
      'mascota': 'Ljubimac',
      'cocinar': 'Kuhanje',
      'pagos': 'Plaćanja',
      'other': 'Zadatak',
    });
    return '$_temp0';
  }

  @override
  String taskPreset(String preset) {
    String _temp0 = intl.Intl.selectLogic(preset, {
      'dishes': 'Oprati suđe',
      'vacuum': 'Usisati',
      'bathroom': 'Očistiti kupatilo',
      'laundry': 'Oprati veš',
      'trash': 'Iznijeti smeće',
      'shopping': 'Kupovina namirnica',
      'plants': 'Zaliti biljke',
      'other': 'Promijeniti posteljinu',
    });
    return '$_temp0';
  }

  @override
  String get recQuick => 'Brzi';

  @override
  String get recLight => 'Lagani';

  @override
  String get recFreezer => 'Za zamrzivač';

  @override
  String get recSearchHint => 'Traži po nazivu ili sastojku';

  @override
  String get recSort => 'Sortiraj';

  @override
  String get recSortRecent => 'Najnoviji';

  @override
  String get recSortAz => 'Od A do Ž';

  @override
  String get recSortFastest => 'Najbrži prvo';

  @override
  String get recSortLightest => 'Najmanje kalorija prvo';

  @override
  String get recClearFilters => 'Ukloni filtere';

  @override
  String get recMore => 'Više';

  @override
  String get recLess => 'Manje';

  @override
  String get planOldTapersTitle => 'Posude iz starog plana';

  @override
  String planOldTapersBody(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'je $count posuda',
      one: 'je 1 posuda',
    );
    return 'U frižideru $_temp0 koje novi plan više ne koristi: $names. Ukloniti iz Moje kuhinje?';
  }

  @override
  String get planOldTapersKeep => 'Ostavi ih';

  @override
  String get hhCreateError => 'Nije moguće kreirati domaćinstvo';

  @override
  String get hhJoinTitle => 'Pridruži se domaćinstvu';

  @override
  String get hhInviteCode => 'Pozivni kod';

  @override
  String get hhJoin => 'Pridruži se';

  @override
  String get hhCodeFormat => 'Kod ima 8 slova i brojeva';

  @override
  String get hhCodeInvalid => 'Nevažeći ili istekao kod';

  @override
  String get hhCodeCreateError => 'Nije moguće kreirati kod';

  @override
  String get hhThisMember => 'ovog člana';

  @override
  String hhRemoveMemberTitle(String name) {
    return 'Ukloniti $name iz domaćinstva?';
  }

  @override
  String get hhRemoveMemberBody => 'Više neće vidjeti kupovinu, ostavu i plan.';

  @override
  String get hhRemoveError => 'Nije moguće ukloniti';

  @override
  String get hhAddGuestTitle => 'Dodaj osobu bez računa';

  @override
  String get hhAddGuestBody =>
      'Za ukućana koji ne koristi aplikaciju. Možeš mu dodijeliti zadatke i bilježiti urađene.';

  @override
  String get hhAddError => 'Nije moguće dodati';

  @override
  String hhRemoveGuestTitle(String name) {
    return 'Ukloniti $name?';
  }

  @override
  String get hhRemoveGuestBody =>
      'Bodovi će biti obrisani, a zadaci ostaju nedodijeljeni.';

  @override
  String get hhLeaveTitle => 'Napustiti domaćinstvo?';

  @override
  String get hhLeaveBody =>
      'Više nećeš vidjeti podatke. Za povratak ti treba novi kod.';

  @override
  String get hhLeave => 'Napusti';

  @override
  String get hhLeaveError => 'Nije moguće napustiti domaćinstvo';

  @override
  String get hhNameTitle => 'Naziv domaćinstva';

  @override
  String get hhRenameError => 'Nije moguće preimenovati';

  @override
  String get hhDeleteAccountTitle => 'Obrisati račun?';

  @override
  String get hhDeleteAccountBody =>
      'Brišu se tvoj račun i podaci. Ako si jedina osoba u domaćinstvu, briše se i domaćinstvo. Ovo se ne može poništiti.';

  @override
  String get hhDeleteConfirm => 'Obriši';

  @override
  String get hhDeleteAccountError => 'Nije moguće obrisati račun';

  @override
  String get hhDeleteAccount => 'Obriši moj račun';

  @override
  String get hhMyHome => 'Moj dom';

  @override
  String get hhSignOut => 'Odjava';

  @override
  String get hhNoHome => 'Još ne pripadaš nijednom domaćinstvu.';

  @override
  String get hhCreateHome => 'Kreiraj novo domaćinstvo';

  @override
  String get hhJoinExisting => 'Pridruži se postojećem domaćinstvu';

  @override
  String get hhRename => 'Preimenuj domaćinstvo';

  @override
  String hhPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Domaćinstvo od $count osoba.',
      one: 'Tvoj dom, zasad samo za tebe.',
    );
    return '$_temp0';
  }

  @override
  String hhMembers(int count) {
    return 'Članovi ($count)';
  }

  @override
  String get hhAdmin => 'Administrator';

  @override
  String get hhRemoveFromHome => 'Ukloni iz domaćinstva';

  @override
  String get hhYou => 'Ti';

  @override
  String get hhNoAccount => 'Bez računa';

  @override
  String get hhLeaveHome => 'Napusti domaćinstvo';

  @override
  String get hhSettings => 'Domaćinstvo i postavke';

  @override
  String get hhAppearance => 'Izgled';

  @override
  String get hhPhoneAlerts => 'Obavještenja na telefonu';

  @override
  String get hhYourData => 'Tvoji podaci';

  @override
  String get hhYourDataSub =>
      'Grafikoni troškova, kupovine, kuhanja i zadataka';

  @override
  String get hhExpenses => 'Troškovi i računi';

  @override
  String get hhExpensesSub => 'Budžet, skenirani računi i troškovi po mjesecu';

  @override
  String get hhYourPlan => 'Tvoj paket';

  @override
  String get hhYourPlanSub => 'Preostala korištenja ovog mjeseca';

  @override
  String get hhNutrition => 'Moj nutritivni profil';

  @override
  String get hhNutritionSub => 'Cilj kalorija, preferencije i asistent';

  @override
  String get hhInvite => 'Pozovi nekoga';

  @override
  String get hhCreateCode => 'Kreiraj kod';

  @override
  String get hhCopy => 'Kopiraj';

  @override
  String get hhCodeCopied => 'Kod kopiran';

  @override
  String hhValidUntil(String date) {
    return 'Važi do $date';
  }

  @override
  String get hhNewCode => 'Novi kod';

  @override
  String get hhChoose => 'Odaberi';

  @override
  String get hhSupersHint =>
      'Recepti će se prilagoditi onome što ima u tvojim marketima. Opcionalno.';

  @override
  String get hhNoSuper => 'Nije odabran market.';

  @override
  String get hhCountryError => 'Nije moguće promijeniti državu';

  @override
  String get hhWhereShop => 'Gdje kupujete?';

  @override
  String get hhPickMany => 'Možeš odabrati više. Opcionalno.';

  @override
  String get hhSaveError => 'Nije moguće sačuvati';

  @override
  String themeMode(String mode) {
    String _temp0 = intl.Intl.selectLogic(mode, {
      'claro': 'Svijetlo',
      'oscuro': 'Tamno',
      'other': 'Sistem',
    });
    return '$_temp0';
  }

  @override
  String get bcNotFound =>
      'Taj kod nije na Open Food Facts. Možeš ga dodati ručno.';

  @override
  String get bcTitle => 'Skeniraj kod';

  @override
  String get bcSearching => 'Tražim proizvod…';

  @override
  String get bcNoPermission =>
      'Treba mi dozvola za kameru da skeniram kod. Možeš je dati u postavkama telefona.';

  @override
  String get bcCameraError =>
      'Nije moguće otvoriti kameru. Proizvod možeš dodati ručno iz ostave.';

  @override
  String planFeature(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'scan_ticket': 'Skeniranje računa',
      'recipes': 'Ideje i recepti',
      'meal_photo': 'Fotografija obroka',
      'other': 'Recepti iz linka',
    });
    return '$_temp0';
  }

  @override
  String puPlanName(String plan) {
    String _temp0 = intl.Intl.selectLogic(plan, {
      'pro': 'Pro paket',
      'other': 'Besplatni paket',
    });
    return '$_temp0';
  }

  @override
  String get puExplain =>
      'Ostava, kupovina, zadaci i plan nemaju ograničenje. Ovo ti je preostalo ovog mjeseca; obnavlja se 1. u mjesecu. Ako nešto ne uspije, ne računa se.';

  @override
  String get puGoPro => 'Pređi na Pro';

  @override
  String puLeft(int left, int limit) {
    return 'Preostalo $left od $limit';
  }

  @override
  String get psTitle => 'Statistika kupovine';

  @override
  String get psMostBought => 'Šta najviše kupuješ';

  @override
  String get psMostSpent => 'Na šta najviše trošiš';

  @override
  String get psPriciest => 'Najskuplji (po komadu)';

  @override
  String get psHistory => 'Tvoja historija kupovine';

  @override
  String psTotal(String amount) {
    return 'Ukupno zabilježeno: $amount';
  }

  @override
  String get psNoPrices => 'Još nema dovoljno podataka o cijenama.';

  @override
  String get psEmptyTitle => 'Još nema statistike';

  @override
  String get psEmptyBody =>
      'Skeniraj račune i ovdje ćeš vidjeti šta najviše kupuješ, na šta najviše trošiš i najskuplje proizvode.';

  @override
  String get meals => 'Obroci';

  @override
  String get mcNoHome => 'Ne pripadaš nijednom domaćinstvu.';

  @override
  String mcPrep(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'compra': 'Kupovina',
      'cocina': 'Kuhanje',
      'other': 'Izvaditi',
    });
    return '$_temp0';
  }

  @override
  String get mcPlanIt => 'Isplaniraj';

  @override
  String get mcSeeInPlan => 'Vidi u planu';

  @override
  String get mcNothing => 'Ništa planirano za ovaj dan.';

  @override
  String get tasks => 'Zadaci';

  @override
  String proPeriod(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'annual': 'Godišnje',
      'sixMonth': 'Svakih 6 mjeseci',
      'threeMonth': 'Svaka 3 mjeseca',
      'twoMonth': 'Svaka 2 mjeseca',
      'monthly': 'Mjesečno',
      'weekly': 'Sedmično',
      'lifetime': 'Zauvijek',
      'other': 'Pro',
    });
    return '$_temp0';
  }

  @override
  String get proAlready => 'Već imaš Pro';

  @override
  String get proMoreUses => 'Više korištenja svakog mjeseca';

  @override
  String get proRestSame =>
      'Ostalo ostaje isto: bez ograničenja i za cijelo domaćinstvo.';

  @override
  String get proFree => 'Besplatno';

  @override
  String get proSoon => 'Pro će uskoro biti dostupan.';

  @override
  String get proNothingToRestore => 'Nema kupovina za vraćanje.';

  @override
  String get proRestore => 'Vrati kupovine';

  @override
  String get proRenews =>
      'Obnavlja se automatski. Možeš otkazati bilo kada u prodavnici.';

  @override
  String get proTerms => 'Uslovi';

  @override
  String get proPrivacy => 'Privatnost';

  @override
  String get aiSaveError => 'Greška pri spremanju';

  @override
  String get aiStoreProduct => 'Proizvod iz marketa';

  @override
  String get aiRemoveProduct => 'Ukloni proizvod';

  @override
  String get aiEditTitle => 'Uredi proizvod';

  @override
  String get aiAddTitle => 'Dodaj u ostavu';

  @override
  String get aiChangePhoto => 'Promijeni fotografiju';

  @override
  String get aiProductType => 'Vrsta proizvoda';

  @override
  String get aiWhatIsIt => 'Šta je to?';

  @override
  String aiDishKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'ingredient': 'Sastojak za kuhanje',
      'base': 'Gotova osnova',
      'other': 'Gotovo jelo',
    });
    return '$_temp0';
  }

  @override
  String get aiSearchStore => 'Traži u marketu';

  @override
  String get aiSearchStoreLong => 'Pronađi proizvod iz marketa sa slikom';

  @override
  String get aiQuickAdd => 'Dodaj uobičajene jednim dodirom';

  @override
  String get aiLocation => 'Lokacija';

  @override
  String get aiCategory => 'Kategorija';

  @override
  String get aiQuantity => 'Količina';

  @override
  String get aiUnit => 'Jedinica';

  @override
  String get aiServings => 'Porcije (opcionalno)';

  @override
  String get aiFrozenDate => 'Datum zamrzavanja';

  @override
  String get aiFrozenOn => 'Zamrznuto (opcionalno)';

  @override
  String get aiWillEstimate => 'Izračunat ćemo koliko traje u zamrzivaču.';

  @override
  String aiBestBefore(String date) {
    return 'Najbolje upotrijebiti do $date (otprilike).';
  }

  @override
  String get aiExpiryDate => 'Rok trajanja';

  @override
  String get aiExpires => 'Ističe';

  @override
  String get aiExpiresApprox => 'Ističe (otprilike)';

  @override
  String get aiNotToList => 'Ne dodaj u kupovinu';

  @override
  String get aiStaplesSub => 'Osnovne stvari koje uvijek imaš';

  @override
  String get aiSaveChanges => 'Sačuvaj izmjene';

  @override
  String get aiSaveNew => 'Sačuvaj u ostavu';

  @override
  String get kzMyKitchen => 'Moja kuhinja';

  @override
  String get kzAllGood => 'Sve u redu';

  @override
  String get phStore => 'Odaberi proizvod iz marketa';

  @override
  String get phCamera => 'Fotografiši';

  @override
  String get phGallery => 'Odaberi iz galerije';

  @override
  String get phError => 'Nije moguće promijeniti fotografiju';

  @override
  String get psStoreTitle => 'Proizvodi iz marketa';

  @override
  String psStoreTitleOf(String store) {
    return 'Proizvodi iz $store';
  }

  @override
  String get psHint => 'Mlijeko, grčki jogurt, deterdžent…';

  @override
  String get psTypeHint => 'Upiši proizvod i dodirni traži.';

  @override
  String get psThrottled => 'Previše pretraga zaredom. Pokušaj za minutu.';

  @override
  String get psOffline => 'Nema internet veze. Svejedno ga možeš dodati.';

  @override
  String get psDown =>
      'Pretraga proizvoda trenutno ne radi. Pokušaj kasnije ili ga svejedno dodaj.';

  @override
  String get psNotInStore => 'Nije u marketu. Svejedno ga možeš dodati.';

  @override
  String psNoResultsIn(String store) {
    return 'Nema rezultata u $store. Ovi su iz drugih marketa.';
  }

  @override
  String psNotYet(String store) {
    return 'Još nemamo proizvode iz $store. Ovi su iz drugih marketa.';
  }

  @override
  String get psOffData => 'Podaci sa Open Food Facts.';

  @override
  String psAddAsIs(String q) {
    return 'Dodaj \"$q\" bez odabira proizvoda';
  }

  @override
  String get offlineExplain =>
      'Možeš i dalje koristiti listu za kupovinu i ostavu: ono što upišeš čuva se na telefonu i šalje kad se veza vrati. Ostalo će se tada ažurirati.';

  @override
  String get offlineNow => 'Trenutno bez veze';

  @override
  String streakMilestone(int days) {
    return '$days dana zaredom!';
  }

  @override
  String streakMilestoneSub(int next) {
    return 'Cilj ostvaren. Sljedeći: $next dana.';
  }

  @override
  String streakDoneSub(int next) {
    return 'Danas se računa. Sljedeći cilj: $next dana.';
  }

  @override
  String get streakKeepSub => 'Označi zadatak ili upiši obrok da nastaviš.';

  @override
  String get streakStart => 'Započni svoj niz';

  @override
  String get streakStartSub => 'Danas označi zadatak ili upiši obrok.';

  @override
  String streakDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dana zaredom',
      one: '1 dan zaredom',
    );
    return '$_temp0';
  }

  @override
  String get syncSaved => 'Sačuvano. Sinhronizovat će se kad se veza vrati.';

  @override
  String get fzTitle => 'Spremiti porcije u zamrzivač?';

  @override
  String get fzSave => 'Spremi u zamrzivač';

  @override
  String get notNow => 'Ne sada';

  @override
  String get fastIn => 'Post';

  @override
  String get fastCanEat => 'Možeš jesti';

  @override
  String fastLeft(String left, String time) {
    return 'Još $left · Jedeš u $time';
  }

  @override
  String fastUntil(String time) {
    return 'Do $time';
  }

  @override
  String get shWeekReady =>
      'Tvoja sedmica je spremna: ručkovi, večere i lista za kupovinu';

  @override
  String get comingSoon => 'USKORO';

  @override
  String psSummary(int distinct, int lines) {
    return '$distinct različitih proizvoda · $lines kupovina';
  }

  @override
  String get errNoConnection =>
      'Izgleda da nema veze. Pokušaj ponovo za trenutak.';

  @override
  String get errBadLogin => 'E-mail ili lozinka nisu tačni.';

  @override
  String get errConfirmEmail =>
      'Potvrdi e-mail (provjeri inbox) i pokušaj ponovo.';

  @override
  String get errSession => 'Sesija je istekla. Prijavi se ponovo.';

  @override
  String get errPermission => 'Nemaš dozvolu za ovo u ovom domaćinstvu.';

  @override
  String get errRateLimit => 'Previše zahtjeva zaredom. Pokušaj kasnije.';

  @override
  String get errExists => 'To već postoji.';

  @override
  String get errUpload => 'Slika nije učitana. Probaj manju.';

  @override
  String get errGeneric => 'Nešto nije uspjelo. Pokušaj ponovo.';

  @override
  String get errBadQuantity => 'Unesi ispravnu količinu.';

  @override
  String get errRecipeComplete => 'Recept nije moguće dovršiti';

  @override
  String get errRecipeImport => 'Nije moguće uvesti recept s tog linka';

  @override
  String get someone => 'Neko';

  @override
  String get reward => 'Nagrada';

  @override
  String remKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'tasks': 'Zadaci sa vremenom',
      'expiry': 'Proizvodi kojima ističe rok',
      'other': 'Niz za dom',
    });
    return '$_temp0';
  }

  @override
  String remTaskOne(String title) {
    return 'Na redu: $title';
  }

  @override
  String remTaskMany(int count) {
    return '$count zadataka na redu';
  }

  @override
  String get remTaskOneBody => 'Kad završiš, označi ga i osvoji bodove.';

  @override
  String remTaskManyBody(String list) {
    return '$list. Označi ih kad završiš i osvoji bodove.';
  }

  @override
  String remExpiryOne(String name) {
    return 'Sutra ističe: $name';
  }

  @override
  String remExpiryMany(int count) {
    return 'Sutra ističe $count proizvoda';
  }

  @override
  String get remExpiryBody =>
      'Skuhaj danas s tim ili zamrzni ono što nećeš iskoristiti.';

  @override
  String remStreakMilestone(int days) {
    return 'Danas dostižeš $days dana';
  }

  @override
  String get remStreakMilestoneBody =>
      'Označi zadatak ili upiši obrok i proslavi.';

  @override
  String remStreakDays(int days) {
    return '$days dana s domom u redu';
  }

  @override
  String get remStreakDaysBody =>
      'Označi zadatak ili upiši obrok da ne izgubiš niz.';

  @override
  String get remHowIsHome => 'Kako je danas u kući?';

  @override
  String get remHowIsHomeBody =>
      'Jedan potez je dovoljan za još jedan dan niza.';

  @override
  String get remStreakAlive => 'Tvoj niz još traje';

  @override
  String get remStreakAliveBody =>
      'Upiši šta si jeo ili označi zadatak prije spavanja.';

  @override
  String listAnd(String items, String last) {
    return '$items i $last';
  }

  @override
  String listMore(String items, int count) {
    return '$items i još $count';
  }

  @override
  String get planMovedLater => 'Ostavljam za drugi put';

  @override
  String get planTheDish => 'jelo';

  @override
  String planMovedTo(String recipe, String day) {
    return '$recipe premješteno na $day';
  }

  @override
  String weekday(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '1': 'ponedjeljak',
      '2': 'utorak',
      '3': 'srijeda',
      '4': 'četvrtak',
      '5': 'petak',
      '6': 'subota',
      'other': 'nedjelja',
    });
    return '$_temp0';
  }

  @override
  String weekdayShortName(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '1': 'pon',
      '2': 'uto',
      '3': 'sri',
      '4': 'čet',
      '5': 'pet',
      '6': 'sub',
      'other': 'ned',
    });
    return '$_temp0';
  }

  @override
  String get prepShopTitle => 'Obaviti kupovinu';

  @override
  String prepShopLine(String day) {
    return 'Za kuhanje unaprijed u $day';
  }

  @override
  String get prepCookTitle => 'Kuhanje unaprijed';

  @override
  String get prepAutoTapers => 'Posude se same upisuju u Moju kuhinju';

  @override
  String get prepThawTitle => 'Iz zamrzivača u frižider';

  @override
  String prepThawLine(String recipe, int count, String day) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count posude',
      one: '1 posuda',
    );
    return '$recipe: $_temp0 za $day';
  }

  @override
  String get taperFresh => 'svježe pripremljeno';

  @override
  String taperFridge(String days) {
    return 'frižider za $days';
  }

  @override
  String taperFreezer(String days) {
    return 'zamrzivač za $days';
  }

  @override
  String stepPrepare(String recipe) {
    return 'Pripremi $recipe';
  }

  @override
  String stepUseAppliance(String appliance, String recipes) {
    String _temp0 = intl.Intl.selectLogic(appliance, {
      'oven': 'Upali rernu',
      'stovetop': 'Upali ringlu',
      'pot': 'Upali lonac',
      'airfryer': 'Upali air fryer',
      'microwave': 'Upali mikrotalasnu',
      'blender': 'Upali blender',
      'other': 'Koristi $appliance',
    });
    return '$_temp0 za $recipes';
  }

  @override
  String comidasTab(String tab) {
    String _temp0 = intl.Intl.selectLogic(tab, {
      'plan': 'Plan',
      'recipes': 'Recepti',
      'other': 'Dnevnik',
    });
    return '$_temp0';
  }

  @override
  String bannerExpiring(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Uskoro ističe',
    );
    return '$_temp0';
  }

  @override
  String get bannerIdeas => 'Ideje';

  @override
  String get bannerHide => 'Sakrij do sutra';

  @override
  String get loading => 'Učitavanje';

  @override
  String get mascot => 'Maskota';

  @override
  String voiceStep(int n) {
    return 'Korak $n.';
  }

  @override
  String voiceTime(String what) {
    return 'Vrijeme je. $what.';
  }

  @override
  String get voiceLastStep => 'To je zadnji korak.';

  @override
  String get voiceNoTime => 'Ovaj korak nema vrijeme.';

  @override
  String voiceTimer(int minutes) {
    return 'Tajmer od $minutes minuta.';
  }

  @override
  String get voiceNoTimers => 'Nema tajmera.';

  @override
  String get voiceStopped => 'Zaustavljeno.';

  @override
  String get voiceNoIngredients => 'Nema liste sastojaka.';

  @override
  String unitOne(String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'unidad': 'komad',
      'diente': 'čen',
      'loncha': 'šnita',
      'lata': 'konzerva',
      'bote': 'tegla',
      'bolsa': 'kesa',
      'comida': 'obrok',
      'cucharada': 'kašika',
      'cucharadita': 'kašičica',
      'other': '$unit',
    });
    return '$_temp0';
  }

  @override
  String unitMany(String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'unidad': 'komada',
      'diente': 'čena',
      'loncha': 'šnita',
      'lata': 'konzerve',
      'bote': 'tegle',
      'bolsa': 'kese',
      'comida': 'obroka',
      'cucharada': 'kašike',
      'cucharadita': 'kašičice',
      'other': '$unit',
    });
    return '$_temp0';
  }

  @override
  String unitShort(String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'unidad': 'kom',
      'cucharada': 'kaš.',
      'cucharadita': 'kašič.',
      'other': '$unit',
    });
    return '$_temp0';
  }

  @override
  String unitToTaste(String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'a_ojo': 'od oka',
      'other': 'po ukusu',
    });
    return '$_temp0';
  }

  @override
  String aiItemType(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'hogar': 'Dom/Čišćenje',
      'other': 'Hrana',
    });
    return '$_temp0';
  }

  @override
  String aiKindShort(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'prep': 'Pripremljeno',
      'dish': 'Gotovo jelo',
      'other': 'Sastojak',
    });
    return '$_temp0';
  }
}
