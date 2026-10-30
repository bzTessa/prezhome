// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String tabLabel(String tab) {
    String _temp0 = intl.Intl.selectLogic(tab, {
      'inicio': 'Heute',
      'comidas': 'Essen',
      'compra': 'Einkauf',
      'despensa': 'Vorrat',
      'tareas': 'Aufgaben',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get country => 'Land';

  @override
  String get countryHint => 'Währung, Supermärkte und Richtpreise';

  @override
  String get continueLabel => 'Weiter';

  @override
  String get back => 'Zurück';

  @override
  String get oneMoment => 'Einen Moment…';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get loginAccountCreated => 'Konto erstellt. Willkommen bei PrezHome';

  @override
  String get loginConfirmEmailSent =>
      'Wir haben dir eine E-Mail zur Bestätigung deines Kontos geschickt. Öffne sie auf diesem Handy, dann bist du angemeldet.';

  @override
  String get loginAuthError => 'Anmeldefehler';

  @override
  String loginProviderError(String provider) {
    return 'Anmeldung mit $provider fehlgeschlagen';
  }

  @override
  String get loginResetNeedsEmail =>
      'Gib zuerst deine E-Mail ein, dann schicke ich dir einen Link zum Zurücksetzen des Passworts.';

  @override
  String get loginResetSent =>
      'Ich habe dir eine E-Mail zum Zurücksetzen des Passworts geschickt.';

  @override
  String get loginResetError => 'E-Mail konnte nicht gesendet werden';

  @override
  String get loginWelcomeBack => 'Willkommen zurück';

  @override
  String get loginCreateAccount => 'Erstelle dein Konto';

  @override
  String get loginTagline => 'PrezHome, dein Zuhause organisiert';

  @override
  String loginContinueWith(String provider) {
    return 'Weiter mit $provider';
  }

  @override
  String get loginOrEmail => 'oder mit deiner E-Mail';

  @override
  String get loginEmail => 'E-Mail';

  @override
  String get loginEmailInvalid => 'Gib eine gültige E-Mail ein';

  @override
  String get loginPassword => 'Passwort';

  @override
  String get loginShowPassword => 'Passwort anzeigen';

  @override
  String get loginHidePassword => 'Passwort verbergen';

  @override
  String get loginPasswordShort => 'Mindestens 6 Zeichen';

  @override
  String get loginForgot => 'Passwort vergessen?';

  @override
  String get loginSignIn => 'Anmelden';

  @override
  String get loginSignUp => 'Registrieren';

  @override
  String get loginNoAccount => 'Kein Konto? Registrieren';

  @override
  String get loginHaveAccount => 'Schon ein Konto? Anmelden';

  @override
  String get homeCodeFormat =>
      'Der Code hat 8 Buchstaben und Ziffern (zum Beispiel ABCD-EFGH).';

  @override
  String get homeSetupError => 'Zuhause konnte nicht eingerichtet werden';

  @override
  String get homeLastStep => 'Letzter Schritt: dein Zuhause';

  @override
  String get homeCreateHint =>
      'Erstelle es jetzt und lade später unter Heute ein, wer mit dir wohnt.';

  @override
  String get homeCreate => 'Mein Zuhause erstellen';

  @override
  String get homeInvited => 'Ich wurde in ein Zuhause eingeladen';

  @override
  String get homeInviteCode => 'Einladungscode';

  @override
  String get homeJoin => 'Einem Zuhause beitreten';

  @override
  String get sessionLoadError => 'Dein Profil konnte nicht geladen werden.';

  @override
  String get onbSectionHome => 'Dein Zuhause';

  @override
  String get onbPeopleTitle => 'Wie viele Personen wohnen bei euch?';

  @override
  String get onbPeopleHint =>
      'Für Portionen, Einkauf und die Aufteilung der Aufgaben.';

  @override
  String get onbSectionGoals => 'Was dich beschäftigt';

  @override
  String get onbGoalsTitle => 'Was möchtest du aus dem Kopf haben?';

  @override
  String get onbGoalsHint =>
      'Wähle so viel du willst. Der Rest bleibt verborgen.';

  @override
  String get onbPickOne => 'Wähle mindestens eins';

  @override
  String onbContinueCount(int count) {
    return 'Weiter ($count)';
  }

  @override
  String get onbSectionKitchen => 'In der Küche';

  @override
  String get onbCookingTitle => 'Wie kocht ihr?';

  @override
  String get onbCookingHint =>
      'So wissen wir, ob wir Vorkochen und Gefrierfach planen.';

  @override
  String get onbSectionShopping => 'Einkauf';

  @override
  String get onbShopTitle => 'Wo kaufst du ein?';

  @override
  String get onbShopHint =>
      'Der erste wird dein Hauptsupermarkt: Rezepte nutzen Produkte, die es dort leicht gibt.';

  @override
  String get onbSkipSeeHome => 'Überspringen und mein Zuhause ansehen';

  @override
  String get onbSeeHome => 'Mein Zuhause ansehen';

  @override
  String get onbSlogan => 'Ein Zuhause in Ordnung, ein ruhiger Kopf.';

  @override
  String get onbStart => 'Los geht\'s';

  @override
  String get onbHaveAccount => 'Ich habe schon ein Konto';

  @override
  String get onbOneLess => 'Eine weniger';

  @override
  String get onbOneMore => 'Eine mehr';

  @override
  String onbPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Personen',
      one: 'Nur ich',
    );
    return '$_temp0';
  }

  @override
  String get onbProfileBadge => 'Dein Haushaltsprofil';

  @override
  String onbProfileName(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'solo': 'Solo',
      'duo': 'Das Duo',
      'tribu': 'Der Clan',
      'other': 'Die Familie',
    });
    return '$_temp0';
  }

  @override
  String onbProfileDescription(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'solo':
          'Das ganze Zuhause hängt an dir. PrezHome merkt sich, was da ist, was abläuft und was ansteht, damit du es nicht musst.',
      'duo':
          'Zwei Personen, ein Zuhause. PrezHome verteilt die Last sichtbar, damit niemand alles im Kopf behalten muss.',
      'other':
          'Viele Münder und vieles gleichzeitig. PrezHome plant Essen, Einkauf und Aufgaben für alle und erinnert jeden an seinen Teil.',
    });
    return '$_temp0';
  }

  @override
  String get onbLoadToday => 'Mentale Last heute';

  @override
  String get onbLoadWithApp => 'Mit PrezHome';

  @override
  String onbLoad(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'high': 'hoch',
      'medium': 'mittel',
      'other': 'gering',
    });
    return '$_temp0';
  }

  @override
  String get onbCreateAccount => 'Mein Konto erstellen';

  @override
  String onbFeature(String f) {
    String _temp0 = intl.Intl.selectLogic(f, {
      'compra': 'Einkaufsliste',
      'comidas': 'Was wir essen',
      'despensa': 'Vorrat und Ablaufdaten',
      'tareas': 'Hausarbeit',
      'other': 'Haushaltsausgaben',
    });
    return '$_temp0';
  }

  @override
  String goalLabel(String g) {
    String _temp0 = intl.Intl.selectLogic(g, {
      'comidas': 'Was wir essen',
      'compra': 'Einkauf',
      'despensa': 'Was zu Hause ist',
      'tareas': 'Hausarbeit',
      'lote': 'Vorkochen',
      'other': 'Haushaltsausgaben',
    });
    return '$_temp0';
  }

  @override
  String goalHint(String g) {
    String _temp0 = intl.Intl.selectLogic(g, {
      'comidas': 'Essensplan und Rezepte',
      'compra': 'Eine Liste, die sich selbst schreibt',
      'despensa': 'Vorrat, Kühlschrank und Ablaufdaten',
      'tareas': 'Faire Aufteilung und Erinnerungen',
      'lote': 'Dosen und Gefrierfach im Griff',
      'other': 'Budget und Kassenbons',
    });
    return '$_temp0';
  }

  @override
  String cookingLabel(String c) {
    String _temp0 = intl.Intl.selectLogic(c, {
      'diario': 'Jeden Tag',
      'lote': 'Vorkochen',
      'mixto': 'Ein bisschen von beidem',
      'other': 'Fast nie',
    });
    return '$_temp0';
  }

  @override
  String cookingHint(String c) {
    String _temp0 = intl.Intl.selectLogic(c, {
      'diario': 'Ich koche spontan',
      'lote': 'Ich koche für mehrere Tage vor',
      'mixto': 'An manchen Tagen vorgekocht',
      'other': 'Ich esse auswärts oder etwas Schnelles',
    });
    return '$_temp0';
  }

  @override
  String homeGreeting(String part) {
    String _temp0 = intl.Intl.selectLogic(part, {
      'morning': 'Guten Morgen',
      'afternoon': 'Guten Tag',
      'other': 'Guten Abend',
    });
    return '$_temp0';
  }

  @override
  String get homeCustomize => 'Heute anpassen';

  @override
  String get homeYourData => 'Deine Daten';

  @override
  String get homeYourHome => 'Dein Zuhause';

  @override
  String homeTodayTag(String meal) {
    return 'Heute · $meal';
  }

  @override
  String mealType(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'breakfast': 'Frühstück',
      'lunch': 'Mittagessen',
      'snack': 'Snack',
      'dinner': 'Abendessen',
      'dessert': 'Dessert',
      'drink': 'Getränk',
      'other': 'Mahlzeit',
    });
    return '$_temp0';
  }

  @override
  String get homeEatingOut => 'Auswärts';

  @override
  String get homeWhatToEat => 'Was essen wir heute?';

  @override
  String get homeNothingPlanned => 'Für heute ist noch nichts geplant.';

  @override
  String get homePlan => 'Planen';

  @override
  String get homeWithWhatIHave => 'Mit dem, was da ist';

  @override
  String get homeExpiring => 'Läuft ab';

  @override
  String homeTasksToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Aufgaben heute',
      one: 'Aufgabe heute',
    );
    return '$_temp0';
  }

  @override
  String get homeInShopping => 'Auf der Liste';

  @override
  String get homeShortcuts => 'Schnellzugriffe';

  @override
  String get homeForToday => 'Für heute';

  @override
  String get homeSeeAll => 'Alle ansehen';

  @override
  String homePoints(int points) {
    return '$points Pkt.';
  }

  @override
  String homePointsSnack(int points) {
    return '+$points Punkte';
  }

  @override
  String get homeToday => 'Heute';

  @override
  String get homeTomorrow => 'Morgen';

  @override
  String get homeCaloriesTitle => 'Berechne dein Kalorienziel';

  @override
  String get homeCaloriesHint =>
      'Beantworte ein paar kurze Fragen und ich passe PrezHome an dich an.';

  @override
  String homeOf(String total) {
    return 'von $total';
  }

  @override
  String get homeCaloriesToday => 'Kalorien heute';

  @override
  String homeKcal(int kcal) {
    return '$kcal kcal';
  }

  @override
  String homeKcalLeft(int kcal) {
    return 'Noch $kcal kcal';
  }

  @override
  String homeKcalOver(int kcal) {
    return '$kcal kcal zu viel';
  }

  @override
  String get homeMonthSpend => 'Ausgaben diesen Monat';

  @override
  String homeMoneyLeft(String amount) {
    return 'Noch $amount';
  }

  @override
  String homeMoneyOver(String amount) {
    return '$amount über dem Budget';
  }

  @override
  String get save => 'Speichern';

  @override
  String get homeCardsSection => 'Karten (ziehen zum Sortieren)';

  @override
  String get homeQuickSection => 'Schnellaktionen';

  @override
  String get homeQuickHint => 'Wähle die Schnellzugriffe oben auf Heute.';

  @override
  String dashCard(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'meals': 'Essen heute',
      'calories': 'Kalorien heute',
      'tasks': 'Aufgaben',
      'other': 'Ausgaben diesen Monat',
    });
    return '$_temp0';
  }

  @override
  String quickAction(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'add_inventory': 'Zum Vorrat hinzufügen',
      'scan_ticket': 'Kassenbon scannen',
      'shopping': 'Einkaufsliste',
      'add_recipe': 'Neues Rezept',
      'meal_plan': 'Wochenplan',
      'other': 'Kalorientagebuch',
    });
    return '$_temp0';
  }

  @override
  String get shopPickStore => 'Supermarkt wählen';

  @override
  String get shopAddFromPlan => 'Wochenplan hinzufügen';

  @override
  String get shopListOptions => 'Listenoptionen';

  @override
  String get shopAllInCart => 'Alles im Wagen';

  @override
  String shopPending(int pending, int done) {
    return '$pending zu kaufen · $done im Wagen';
  }

  @override
  String shopUnpriced(int count) {
    return ' · $count ohne Preis';
  }

  @override
  String get shopAddProduct => 'Produkt hinzufügen';

  @override
  String get shopSearchStore => 'Im Supermarkt suchen';

  @override
  String get moreOptions => 'Weitere Optionen';

  @override
  String get less => 'Weniger';

  @override
  String get more => 'Mehr';

  @override
  String shopAdded(String name) {
    return '$name, hinzugefügt';
  }

  @override
  String shopAdd(String name) {
    return '$name hinzufügen';
  }

  @override
  String get shopLiveOffline =>
      'Gerade keine Live-Verbindung; wird beim Neuladen aktualisiert.';

  @override
  String get couldNotUpdate => 'Aktualisierung fehlgeschlagen';

  @override
  String shopSavedToPantry(int count) {
    return '$count Produkte im Vorrat gespeichert';
  }

  @override
  String get shopRemoveFromList => 'Von der Liste entfernen';

  @override
  String shopRemovedOne(String name) {
    return '\"$name\" entfernt';
  }

  @override
  String get couldNotChangePhoto => 'Foto konnte nicht geändert werden';

  @override
  String get shopAddToList => 'Zur Liste hinzufügen';

  @override
  String get shopTypeFood => 'Lebensmittel';

  @override
  String get shopTypeHome => 'Haushalt/Reinigung';

  @override
  String get name => 'Name';

  @override
  String get product => 'Produkt';

  @override
  String get quantity => 'Menge';

  @override
  String get unit => 'Einheit';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get add => 'Hinzufügen';

  @override
  String get nameEmpty => 'Der Name darf nicht leer sein.';

  @override
  String get couldNotAdd => 'Hinzufügen fehlgeschlagen';

  @override
  String get shopPlanAllAtHome => 'Du hast schon alles aus dem Plan zu Hause';

  @override
  String shopAddedFromPlan(int count) {
    return '$count Produkte aus dem Plan hinzugefügt';
  }

  @override
  String get shopListTitle => 'Einkaufsliste';

  @override
  String get shopMainList => 'Hauptliste';

  @override
  String get couldNotCreateList => 'Liste konnte nicht erstellt werden';

  @override
  String get shopRecipesUseStore =>
      'Rezepte verwenden Produkte aus diesem Supermarkt.';

  @override
  String get shopStoreSaveError =>
      'Supermarkt konnte nicht gespeichert werden. Versuch es noch einmal.';

  @override
  String get shopGroupByAisle => 'Nach Gang gruppieren';

  @override
  String get shopGroupHint => 'Gemüse, Fleisch, Reinigung…';

  @override
  String get shopShowPhotos => 'Produktfotos anzeigen';

  @override
  String get shopMyLists => 'Meine Listen';

  @override
  String get categories => 'Kategorien';

  @override
  String get shopFinish => 'Einkauf beenden';

  @override
  String shopFinishCount(int count) {
    return 'Einkauf beenden ($count)';
  }

  @override
  String get shopScanTicket => 'Kassenbon scannen';

  @override
  String get shopAllBought => 'Alles gekauft';

  @override
  String get shopToBuy => 'Zu kaufen';

  @override
  String get shopUsual => 'Das Übliche';

  @override
  String get shopInCart => 'Im Wagen';

  @override
  String shopRemovedMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Produkte entfernt',
      one: '1 Produkt entfernt',
    );
    return '$_temp0';
  }

  @override
  String get couldNotRemove => 'Entfernen fehlgeschlagen';

  @override
  String get undo => 'Rückgängig';

  @override
  String get couldNotUndo => 'Rückgängig machen fehlgeschlagen';

  @override
  String get shopToCart => 'In den Wagen';

  @override
  String get shopFromPlan => 'Aus dem Wochenplan';

  @override
  String get changePhoto => 'Foto ändern';

  @override
  String get shopEmptyTitle => 'Deine Liste ist leer';

  @override
  String get shopEmptyHint =>
      'Schreib oben, was du brauchst, oder übernimm den Plan.';

  @override
  String get shopFromPlanAction => 'Aus dem Plan';

  @override
  String get shopDoneTitle => 'Einkauf erledigt';

  @override
  String get shopDoneHint => 'Du hast alles von der Liste. Gut gemacht!';

  @override
  String panUsedInOne(String meal) {
    return 'Entfernt, was du für $meal verbraucht hast';
  }

  @override
  String panUsedInMany(int count) {
    return 'Entfernt, was du für $count geplante Mahlzeiten verbraucht hast';
  }

  @override
  String get view => 'Ansehen';

  @override
  String get couldNotDelete => 'Löschen fehlgeschlagen';

  @override
  String panNoLongerShop(String name) {
    return '$name erscheint nicht mehr im Einkauf.';
  }

  @override
  String panBackToShop(String name) {
    return '$name erscheint wieder im Einkauf.';
  }

  @override
  String panCouldNotMarkOut(String name) {
    return '$name konnte nicht als aufgebraucht markiert werden';
  }

  @override
  String panMarkedOut(String name) {
    return 'Ich habe $name als aufgebraucht markiert.';
  }

  @override
  String panOutNotAdded(String name) {
    return '$name ist aufgebraucht, aber ich konnte es nicht zum Einkauf hinzufügen';
  }

  @override
  String panAlreadyInList(String name) {
    return '$name steht schon auf deiner Einkaufsliste.';
  }

  @override
  String panAddedToShop(String name) {
    return 'Ich habe $name zum Einkauf hinzugefügt';
  }

  @override
  String get panAddManual => 'Manuell hinzufügen';

  @override
  String get panScanBarcode => 'Barcode scannen';

  @override
  String get panFreezeDish => 'Gekochtes Gericht in den Gefrierschrank';

  @override
  String get panFreezeDishHint => 'Wähle das Rezept und die Portionen';

  @override
  String get panSaveRecipeFirst => 'Speichere zuerst ein Rezept.';

  @override
  String get panWhichDish => 'Welches Gericht frierst du ein?';

  @override
  String get panHowManyServings => 'Wie viele Portionen frierst du ein?';

  @override
  String get panTitle => 'Vorrat und Kühlschrank';

  @override
  String get panAddTooltip => 'Zum Vorrat hinzufügen';

  @override
  String get panLoadError => 'Vorrat konnte nicht geladen werden';

  @override
  String get panEmptyTitle => 'Dein Vorrat ist leer';

  @override
  String get panEmptyHint =>
      'Füge hinzu, was du zu Hause hast, oder hake den Einkauf ab, dann landet es hier.';

  @override
  String get panAddProduct => 'Produkt hinzufügen';

  @override
  String get panWhatToCook => 'Was koche ich damit?';

  @override
  String get panExpiringHeader => 'Abgelaufen und bald ablaufend';

  @override
  String get panNothingHere => 'Hier ist nichts.';

  @override
  String kitchenZone(String zone) {
    String _temp0 = intl.Intl.selectLogic(zone, {
      'nevera': 'Kühlschrank',
      'congelador': 'Gefrierschrank',
      'despensa': 'Vorrat',
      'bebidas': 'Getränke',
      'especias': 'Gewürze',
      'limpieza': 'Reinigung',
      'hogar': 'Hygiene und Haushalt',
      'other': '$zone',
    });
    return '$_temp0';
  }

  @override
  String get kitchenReview => 'Prüfen';

  @override
  String expiryGroup(String group) {
    String _temp0 = intl.Intl.selectLogic(group, {
      'expired': 'Abgelaufen',
      'week': 'Diese Woche',
      'later': 'Später',
      'other': 'Ohne Datum',
    });
    return '$_temp0';
  }

  @override
  String panExpiredAgo(int days) {
    return 'Seit $days Tagen abgelaufen';
  }

  @override
  String get panExpiredYesterday => 'Gestern abgelaufen';

  @override
  String get panExpiresToday => 'Läuft heute ab';

  @override
  String get panExpiresTomorrow => 'Läuft morgen ab';

  @override
  String panExpiresIn(int days) {
    return 'Läuft in $days Tagen ab';
  }

  @override
  String panDays(int days) {
    return '$days Tage';
  }

  @override
  String get panNotBought => 'Wird nicht gekauft';

  @override
  String get panConsumed => 'Verbraucht';

  @override
  String get panToShopping => 'Zum Einkauf';

  @override
  String panCouldNotAddToShop(String name) {
    return '$name konnte nicht zum Einkauf hinzugefügt werden';
  }

  @override
  String panExpiredDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count abgelaufene gelöscht',
      one: 'Abgelaufenes gelöscht',
    );
    return '$_temp0';
  }

  @override
  String get panMyKitchen => 'Meine Küche';

  @override
  String get panUsedHistory => 'Was verbraucht wurde';

  @override
  String get panNothingExpired => 'Nichts abgelaufen';

  @override
  String panDeleteExpired(int count) {
    return 'Abgelaufene löschen ($count)';
  }

  @override
  String panEmptyZone(String where) {
    return '$where leeren';
  }

  @override
  String panEmptyAsk(String where) {
    return '$where leeren?';
  }

  @override
  String panWillDelete(int count) {
    return '$count Produkte werden gelöscht.';
  }

  @override
  String get panEmpty => 'Leeren';

  @override
  String panDeleted(int count) {
    return '$count Produkte gelöscht';
  }

  @override
  String get edit => 'Bearbeiten';

  @override
  String get panShopAgain => 'Wieder zum Einkauf hinzufügen';

  @override
  String get panDontShop => 'Nicht zum Einkauf hinzufügen';

  @override
  String get panStapleHint => 'Für Grundlagen, die du immer hast';

  @override
  String get panWillAddToShop => 'Ich setze es auf den Einkauf';

  @override
  String get delete => 'Löschen';

  @override
  String panDeleteAsk(String name) {
    return '$name löschen?';
  }

  @override
  String panConsumedOn(String name, String day) {
    return '$name, verbraucht $day';
  }

  @override
  String get todayLower => 'heute';

  @override
  String get yesterdayLower => 'gestern';

  @override
  String panOnDate(int day, int month) {
    return 'am $day.$month.';
  }

  @override
  String get panWhen => 'Wann?';

  @override
  String get today => 'Heute';

  @override
  String get yesterday => 'Gestern';

  @override
  String get panOtherDay => 'Anderer Tag';

  @override
  String get panWhichDay => 'Welcher Tag?';

  @override
  String get panHowMany => 'Wie viele?';

  @override
  String panAll(String qty) {
    return 'Alles ($qty)';
  }

  @override
  String get couldNotLoad => 'Laden fehlgeschlagen';

  @override
  String get panNothingYet => 'Noch nichts.';

  @override
  String get panWhenCooking => 'Beim Kochen';

  @override
  String get planHowLong => 'Für wie lange?';

  @override
  String get thisWeek => 'Diese Woche';

  @override
  String planWeeks(int count) {
    return '$count Wochen';
  }

  @override
  String get planMonth4 => 'Ein Monat (4 Wochen)';

  @override
  String get planPickDates => 'Daten wählen';

  @override
  String get planDates => 'Plandaten';

  @override
  String get planMaxTwoMonths => 'Höchstens zwei Monate auf einmal.';

  @override
  String get planReadyAllHome => 'Plan fertig. Du hast schon alles zu Hause';

  @override
  String planListReady(int count) {
    return 'Plan fertig. Einkaufsliste mit $count Produkten';
  }

  @override
  String get planBackInPlan => 'Ist wieder im Plan';

  @override
  String planEntryTitle(String meal, String recipe) {
    return '$meal · $recipe';
  }

  @override
  String get planNoRecipe => 'Kein Rezept';

  @override
  String get planChangeRecipe => 'Rezept ändern';

  @override
  String get planWhoEats => 'Wer isst mit';

  @override
  String get planMarkHome => 'Als zu Hause markieren';

  @override
  String get planMarkOut => 'Als auswärts markieren';

  @override
  String get planStopRepeat => 'Nicht mehr wiederholen';

  @override
  String get planStopRepeatHint => 'Entfernt die nächsten Male';

  @override
  String get planRepeat => 'Wiederholen';

  @override
  String get planRepeatHint => 'Täglich, wöchentlich… oder für immer';

  @override
  String get planRemove => 'Aus dem Plan entfernen';

  @override
  String planRepeatTitle(String meal) {
    return '$meal wiederholen';
  }

  @override
  String get planHowOften => 'Wie oft?';

  @override
  String planEveryDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Alle $days Tage',
      one: 'Jeden Tag',
    );
    return '$_temp0';
  }

  @override
  String planEveryWeeks(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: 'Alle $weeks Wochen',
      one: 'Jede Woche',
    );
    return '$_temp0';
  }

  @override
  String get planUntilWhen => 'Bis wann?';

  @override
  String get planForever => 'Für immer';

  @override
  String planMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Monate',
      one: '1 Monat',
    );
    return '$_temp0';
  }

  @override
  String get planRepeatDone =>
      'Erledigt. Du siehst es in den nächsten Wochen im Plan; hat ein Tag schon etwas anderes, bleibt es.';

  @override
  String get planWhoAtHome => 'Wer isst zu Hause?';

  @override
  String get planCalendarPermission =>
      'Erlaube den Kalenderzugriff in den Handy-Einstellungen';

  @override
  String get planInFast => 'Fällt in die Fastenzeit';

  @override
  String get planSettings => 'Planeinstellungen';

  @override
  String get planBatchCook => 'Ich koche vor';

  @override
  String get planBatchCookHint => 'Einkaufstag, Kochtag und Dosen';

  @override
  String get planTimes => 'Uhrzeiten';

  @override
  String get planFasting => 'Intervallfasten';

  @override
  String get no => 'Nein';

  @override
  String planEatWindow(String from, String to) {
    return 'Du isst von $from bis $to. Verschiebt sich mit der Abendessenszeit.';
  }

  @override
  String get planCalendar => 'Kalender';

  @override
  String get planToCalendar => 'In den Kalender übernehmen';

  @override
  String get planCalendarLinked => 'Kalender verbunden';

  @override
  String get planCalendarHint =>
      'Mahlzeiten und Aufgaben mit Uhrzeit, im Google Kalender';

  @override
  String get planCalendarUpdates => 'Wird beim Öffnen des Plans aktualisiert';

  @override
  String get remove => 'Entfernen';

  @override
  String get planPickRecipe => 'Wähle ein Rezept';

  @override
  String get planDayFull => 'Dieser Tag hat schon alle Mahlzeiten.';

  @override
  String get planWhichMeal => 'Welche Mahlzeit fügst du hinzu?';

  @override
  String get planTitle => 'Wochenplan';

  @override
  String get planNoHome => 'Du gehörst zu keinem Haushalt.';

  @override
  String get planMake => 'Plan erstellen';

  @override
  String get planRemake => 'Plan neu erstellen';

  @override
  String get planNeedRecipes => 'Füge zuerst ein paar Rezepte hinzu';

  @override
  String get planNeedRecipesHint =>
      'Der Planer verteilt deine Rezepte über die Woche. Speichere ein paar im Tab Essen.';

  @override
  String get planPrevWeek => 'Vorherige Woche';

  @override
  String get planNextWeekLabel => 'Nächste Woche';

  @override
  String get planLastWeek => 'Letzte Woche';

  @override
  String get planWeek => 'Woche';

  @override
  String get planBackToToday => 'Zurück zu heute';

  @override
  String get planNextWeek => 'Nächste Woche';

  @override
  String get planDay => 'Tag';

  @override
  String get planMonthCalendar => 'Monatskalender';

  @override
  String get planNoPlanYet => 'Noch kein Plan für diese Woche.';

  @override
  String get recipe => 'Rezept';

  @override
  String get planCookMode => 'Kochmodus';

  @override
  String get planCookWeek => 'Koch die ganze Woche auf einmal';

  @override
  String get planBatch => 'Vorkochen';

  @override
  String planCookDays(int days, int recipes) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Kochtage',
      one: '1 Kochtag',
    );
    String _temp1 = intl.Intl.pluralLogic(
      recipes,
      locale: localeName,
      other: '$recipes Rezepte',
      one: '1 Rezept',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get planBatchEmpty =>
      'Sobald der Plan steht, sage ich dir, wann du einkaufst, wann du kochst und was in den Kühlschrank oder Gefrierschrank kommt.';

  @override
  String get planCookedToFreezer => 'Gekocht · in den Gefrierschrank';

  @override
  String planFrozen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Gerichte im Gefrierschrank gespeichert.',
      one: 'Mit Foto im Gefrierschrank gespeichert.',
    );
    return '$_temp0';
  }

  @override
  String get planEnergyLow => 'Wenig';

  @override
  String get planEnergyNormal => 'Normal';

  @override
  String get planEnergyHigh => 'Viel';

  @override
  String get planEnergyHint =>
      'Mit \"wenig\" nutzt der Plan mehr den Gefrierschrank.';

  @override
  String get planHowMuchCook => 'Wie viel kochen';

  @override
  String planServings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Portionen',
      one: '1 Portion',
    );
    return '$_temp0';
  }

  @override
  String get close => 'Schließen';

  @override
  String get planSearchRecipe => 'Rezept suchen...';

  @override
  String get planNoMatch => 'Keine passenden Rezepte.';

  @override
  String get diaDeleteError => 'Mahlzeit konnte nicht gelöscht werden.';

  @override
  String get diaManual => 'Manuell';

  @override
  String get diaManualHint => 'Gib Name und Kalorien ein';

  @override
  String get diaFromRecipe => 'Aus einem Rezept';

  @override
  String get diaFromRecipeHint => 'Trag eines deiner Rezepte als Mahlzeit ein';

  @override
  String get diaWithPhoto => 'Mit einem Foto';

  @override
  String get diaWithPhotoHint =>
      'Fotografiere das Gericht und wir berechnen die Kalorien';

  @override
  String get diaAddManual => 'Manuell hinzufügen';

  @override
  String get diaKcalField => 'Kalorien (kcal)';

  @override
  String get diaMealTypeOptional => 'Mahlzeit (optional)';

  @override
  String get diaNoType => 'Ohne Typ';

  @override
  String get diaProteinG => 'Eiweiß (g)';

  @override
  String get diaCarbsG => 'Kohlenhydrate (g)';

  @override
  String get diaFatG => 'Fett (g)';

  @override
  String get diaNeedNameKcal =>
      'Gib mindestens einen Namen und die Kalorien ein.';

  @override
  String get diaSaveError => 'Mahlzeit konnte nicht gespeichert werden.';

  @override
  String get diaRecipesLoadError => 'Rezepte konnten nicht geladen werden.';

  @override
  String get diaNoRecipes => 'Du hast noch keine Rezepte zum Eintragen.';

  @override
  String diaKcalPerServing(int kcal) {
    return '$kcal kcal pro Portion';
  }

  @override
  String get diaNoKcal => 'Keine Kalorien eingetragen';

  @override
  String get diaServings => 'Portionen';

  @override
  String get diaServingsError => 'Gib eine Portionenzahl über 0 ein.';

  @override
  String get diaLog => 'Eintragen';

  @override
  String get diaRecipeLogError => 'Rezept konnte nicht eingetragen werden.';

  @override
  String get diaTitle => 'Mein Tagebuch';

  @override
  String get diaAddMeal => 'Mahlzeit hinzufügen';

  @override
  String get previous => 'Zurück';

  @override
  String get next => 'Weiter';

  @override
  String get diaDayCalories => 'Kalorien des Tages';

  @override
  String diaOfTarget(int kcal) {
    return 'von $kcal kcal';
  }

  @override
  String get diaNoTarget =>
      'Vervollständige dein Profil, um ein tägliches Kalorienziel festzulegen und zu sehen, wie viel dir bleibt.';

  @override
  String get diaCompleteProfile => 'Mein Profil vervollständigen';

  @override
  String get diaOthers => 'Andere';

  @override
  String get diaMeal => 'Mahlzeit';

  @override
  String get diaLast7 => 'Deine letzten 7 Tage';

  @override
  String diaTargetPerDay(int kcal) {
    return 'Ziel: $kcal kcal pro Tag';
  }

  @override
  String get diaTarget => 'Ziel';

  @override
  String get diaTodaySplit => 'Heutige Verteilung';

  @override
  String get diaNoMacros => 'Heute noch keine Makros eingetragen.';

  @override
  String get diaProtein => 'Eiweiß';

  @override
  String get diaCarbs => 'Kohlenhydrate';

  @override
  String get diaFat => 'Fett';

  @override
  String get diaAteThePlan => 'Hast du gegessen, was geplant war?';

  @override
  String diaAskLine(String day, String meal, String name, int kcal) {
    return '$day, $meal: $name · $kcal kcal';
  }

  @override
  String get yes => 'Ja';

  @override
  String get diaAnswerError => 'Antwort konnte nicht gespeichert werden.';

  @override
  String get diaAskFirst => 'Frag mich, bevor der Plan eingetragen wird';

  @override
  String get diaAskOn =>
      'Wir fragen, ob du jede geplante Mahlzeit gegessen hast.';

  @override
  String get diaAskOff =>
      'Geplante Mahlzeiten werden nach ihrer Uhrzeit automatisch eingetragen.';

  @override
  String get diaSettingError => 'Einstellung konnte nicht gespeichert werden.';

  @override
  String get diaEmpty =>
      'Für diesen Tag hast du noch nichts eingetragen.\nFüge deine erste Mahlzeit hinzu.';

  @override
  String get recUnfavorite => 'Aus Favoriten entfernen';

  @override
  String get recFavorite => 'Als Favorit markieren';

  @override
  String get recDelete => 'Rezept löschen';

  @override
  String get recDeleteAsk => 'Rezept löschen?';

  @override
  String recRemoveAsk(String name) {
    return '\"$name\" und seine Zutaten werden gelöscht.';
  }

  @override
  String recDeleted(String name) {
    return '\"$name\" gelöscht.';
  }

  @override
  String get recTitle => 'Rezepte';

  @override
  String get recNew => 'Neues Rezept';

  @override
  String get recLoadError => 'Ich konnte die Rezepte nicht laden';

  @override
  String get recEmptyTitle => 'Noch keine Rezepte';

  @override
  String get recEmptyHint =>
      'Erstelle das erste oder hol dir Ideen mit dem, was du hast.';

  @override
  String get recIdeas => 'Ideen mit dem, was ich habe';

  @override
  String get recNoResults => 'Keine Ergebnisse';

  @override
  String recCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Rezepte',
      one: '1 Rezept',
    );
    return '$_temp0';
  }

  @override
  String get recWhatToCook => 'Was koche ich mit dem, was ich habe?';

  @override
  String get recPantryIdeas => 'Ideen mit dem, was in deinem Vorrat ist';

  @override
  String get recAll => 'Alle';

  @override
  String get recFavorites => 'Favoriten';

  @override
  String get recNoFilter =>
      'Keine Rezepte mit diesem Filter.\nVersuch eine andere Kategorie.';

  @override
  String get clear => 'Löschen';

  @override
  String recNoMatch(String query) {
    return 'Keine Rezepte passen zu\n\"$query\".';
  }
}
