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
      'hogar': 'Higijena i dom',
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
  String get planEnergyHint => 'Sa \"malo\" plan više koristi zamrzivač.';

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
}
