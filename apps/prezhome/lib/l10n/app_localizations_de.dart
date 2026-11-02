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
      'Der erste wird dein Hauptsupermarkt: Dort suchen wir die Produkte deiner Einkaufsliste.';

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
      'Die Produkte deiner Liste werden in diesem Supermarkt gesucht. Rezepte passen zu jedem.';

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
  String get shopShowIcons => 'Zeichnungen zeigen, wenn es kein Foto gibt';

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
  String get recOther => 'Weitere';

  @override
  String recSeeAll(int count) {
    return 'Alle $count ansehen';
  }

  @override
  String get recNoFilter =>
      'Keine Rezepte mit diesem Filter.\nVersuch eine andere Kategorie.';

  @override
  String get clear => 'Löschen';

  @override
  String recNoMatch(String query) {
    return 'Keine Rezepte passen zu\n\"$query\".';
  }

  @override
  String get rdPhoto => 'Rezeptfoto';

  @override
  String get rdAutoPhoto => 'Automatisch ein anderes Foto suchen';

  @override
  String get rdAutoPhotoHint => 'Sucht ein neues Bild nach dem Namen';

  @override
  String get rdGallery => 'Aus der Galerie wählen';

  @override
  String get rdNoBetterPhoto => 'Ich habe vorerst kein besseres Foto gefunden';

  @override
  String get rdUploadError => 'Foto konnte nicht hochgeladen werden';

  @override
  String rdShareText(String title, String code) {
    return 'Hier ist mein Rezept für $title in PrezHome. Geh in der App zu Rezepte, tippe auf Rezept hinzufügen und dann Mit einem Code: $code';
  }

  @override
  String get rdSavedFreezer => 'Im Gefrierschrank gespeichert.';

  @override
  String get couldNotSave => 'Speichern fehlgeschlagen';

  @override
  String get rdVideoError => 'Videolink konnte nicht geöffnet werden';

  @override
  String get rdWatchVideo => 'Video ansehen';

  @override
  String get share => 'Teilen';

  @override
  String get rdEdit => 'Rezept bearbeiten';

  @override
  String get rdMinutes => 'Minuten';

  @override
  String get rdKcalServing => 'Kcal/Portion';

  @override
  String get rdPerServingShort => 'pro Portion';

  @override
  String rdServingWord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Portionen',
      one: 'Portion',
    );
    return '$_temp0';
  }

  @override
  String get rdFreezable => 'Einfrierbar';

  @override
  String get rdIngredients => 'Zutaten';

  @override
  String get rdStepsWord => 'Schritte';

  @override
  String rdSteps(int count) {
    return 'Schritte ($count)';
  }

  @override
  String get rdNutrition => 'Nährwerte';

  @override
  String get rdNoIngredients => 'Keine Zutaten eingetragen.';

  @override
  String rdOriginal(String servings) {
    return 'Originalrezept: $servings';
  }

  @override
  String rdForHome(String servings) {
    return 'Für deinen Haushalt heute: $servings';
  }

  @override
  String get rdHaveAll => 'Du hast alles zu Hause';

  @override
  String rdHaveSome(int have, int total) {
    return 'Du hast $have von $total zu Hause';
  }

  @override
  String rdMissing(int count) {
    return '$count fehlen';
  }

  @override
  String get rdAtHome => 'Zu Hause';

  @override
  String get rdLacking => 'Fehlt';

  @override
  String get rdNoSteps =>
      'Dieses Rezept hat keine Schritte. Du kannst sie beim Bearbeiten hinzufügen.';

  @override
  String get rdPerServingTitle => 'Pro Portion';

  @override
  String get rdNoNutrition => 'Keine Nährwertangaben.';

  @override
  String rdPerServing(String amount) {
    return '$amount pro Portion';
  }

  @override
  String rdTotal(String amount) {
    return '≈ $amount insgesamt';
  }

  @override
  String get rdApproxCost =>
      'Ungefähre Kosten. Scanne Kassenbons, um sie mit deinen echten Preisen zu verfeinern.';

  @override
  String get rdStartCooking => 'Mit dem Kochen beginnen';

  @override
  String rdAddedMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Produkte zum Einkauf hinzugefügt',
      one: 'Zur Einkaufsliste hinzugefügt',
    );
    return '$_temp0';
  }

  @override
  String get rdNeedProfile =>
      'Vervollständige ein Ernährungsprofil, um zu sehen, wie viele Gramm und Kalorien jede Person bekommt.';

  @override
  String get rdMember => 'Mitglied';

  @override
  String get rdAdjustSplit =>
      'Passe die Kalorienverteilung pro Mahlzeit im Profil für diese Rezeptart an.';

  @override
  String get rdByProfile => 'Nach dem Profil jeder Person';

  @override
  String get rdByProfileHint =>
      'Menge und Kalorien pro Person für diese Mahlzeit.';

  @override
  String get arWriteName => 'Gib den Namen ein';

  @override
  String get arWriteNameHint =>
      'Gib den Namen ein oder füge ein ganzes Rezept ein…';

  @override
  String get arGenerate => 'Erstellen';

  @override
  String get arFilled => 'Rezept ausgefüllt. Prüfe es vor dem Speichern.';

  @override
  String get arFillError => 'Rezept konnte nicht vervollständigt werden';

  @override
  String get arImport => 'Rezept importieren';

  @override
  String get arPasteRecipe => 'Rezept einfügen';

  @override
  String get arImportHint =>
      'Füge den Link von TikTok, YouTube oder einer Website oder den Rezepttext ein. Bei Instagram kopiere die Beschreibung des Beitrags und füge sie hier ein.';

  @override
  String get arLinkOrText => 'Rezeptlink oder -text';

  @override
  String get arRecipeText => 'Rezepttext';

  @override
  String get paste => 'Einfügen';

  @override
  String get arImportBtn => 'Importieren';

  @override
  String get arNeedLink =>
      'Füge einen Link oder den vollständigen Rezepttext ein.';

  @override
  String get arImported => 'Rezept importiert. Prüfe es vor dem Speichern.';

  @override
  String get arImportLinkError =>
      'Ich konnte das Rezept von diesem Link nicht importieren';

  @override
  String get arImportError => 'Import fehlgeschlagen';

  @override
  String get arPickMealType => 'Wähle mindestens eine Mahlzeit.';

  @override
  String get arVideoNotUrl =>
      'Der Videolink sieht nicht wie eine URL aus, wir speichern ihn trotzdem.';

  @override
  String get arRecalculated =>
      'Kalorien und Makros aus den Zutaten neu berechnet.';

  @override
  String arPhotoFailed(String error) {
    return 'Rezept gespeichert, aber das Foto konnte nicht hochgeladen werden: $error';
  }

  @override
  String get arSaveError => 'Fehler beim Speichern';

  @override
  String get arReadingVideo => 'Rezept wird aus dem Video gelesen…';

  @override
  String get arCompleting => 'Rezept wird vervollständigt…';

  @override
  String get arAddPhoto => 'Foto hinzufügen (optional)';

  @override
  String get arTitleField => 'Titel';

  @override
  String get arTitleRequired => 'Gib ihm einen Titel';

  @override
  String get arDescription => 'Beschreibung (optional)';

  @override
  String get arVideoLink => 'Videolink (optional)';

  @override
  String get arMealTypes => 'Mahlzeit (mehrere möglich)';

  @override
  String get arAuto => 'Auto';

  @override
  String get arServingsHelper => 'Für wie viele';

  @override
  String get arGramsServing => 'Gramm / Portion';

  @override
  String get arNutritionTitle => 'Nährwerte (pro Portion)';

  @override
  String get arCooking => 'Kochen';

  @override
  String get arPrepMin => 'Vorbereitung (Min.)';

  @override
  String get arCookMin => 'Garzeit (Min.)';

  @override
  String get arAppliance => 'Hauptgerät';

  @override
  String get arFreezable => 'Einfrierbar';

  @override
  String get arAddIngredient => 'Zutat hinzufügen';

  @override
  String get arStepsTitle => 'Zubereitungsschritte';

  @override
  String get arStepsHint => 'Schreib die Schritte, einen pro Zeile…';

  @override
  String get arSaveChanges => 'Änderungen speichern';

  @override
  String get arSaveRecipe => 'Rezept speichern';

  @override
  String get arIngredient => 'Zutat';

  @override
  String get tskWhoDid => 'Wer hat die Aufgabe erledigt?';

  @override
  String get tskTheHome => 'den Haushalt';

  @override
  String tskPointsFor(int points, String who) {
    return '+$points Punkte für $who';
  }

  @override
  String tskPointsForPantry(int points, String who, int count) {
    return '+$points Punkte für $who. $count Produkte in den Vorrat';
  }

  @override
  String tskYou(String name) {
    return '$name (du)';
  }

  @override
  String get tskThisMember => 'dieses Mitglied';

  @override
  String get tskResetPoints => 'Punkte zurücksetzen';

  @override
  String tskResetAsk(String name) {
    return 'Die Punkte von $name werden auf 0 gesetzt. Das kann nicht rückgängig gemacht werden. Sicher?';
  }

  @override
  String get tskReset => 'Zurücksetzen';

  @override
  String tskResetDone(String name) {
    return 'Punkte von $name zurückgesetzt.';
  }

  @override
  String get tskDeleteTitle => 'Aufgabe löschen?';

  @override
  String tskDeleteAsk(String title) {
    return '\"$title\" wird gelöscht.';
  }

  @override
  String tskClaimed(String title) {
    return '\"$title\" gehört dir';
  }

  @override
  String get tskDone => 'Erledigt';

  @override
  String get tskToTomorrow => 'Auf morgen verschieben';

  @override
  String get tskToNextWeek => 'Auf nächste Woche verschieben';

  @override
  String get tskTitle => 'Aufgaben';

  @override
  String get tskEmptyTitle => 'Noch keine Aufgaben';

  @override
  String get tskEmptyHint => 'Füge die erste hinzu.';

  @override
  String get tskNew => 'Neue Aufgabe';

  @override
  String get tskAnyone => 'Jeder';

  @override
  String get tskForToday => 'Für heute';

  @override
  String get tskUpcoming => 'Nächste Tage';

  @override
  String get tskPoolEmpty => 'Nichts im Pool. Alles hat jemanden.';

  @override
  String get tskSwipeToClaim => 'Nach links wischen, um sie zu übernehmen.';

  @override
  String get tskNothingDone => 'Heute noch nichts erledigt.';

  @override
  String get tskAll => 'Alle';

  @override
  String get tskMine => 'Meine';

  @override
  String get tskAllDoneToday => 'Heute ist alles erledigt';

  @override
  String get tskNextBelow => 'Das Nächste steht unten.';

  @override
  String get tskNothingLeft => 'Nichts mehr offen.';

  @override
  String get tskScoreboard => 'PUNKTESTAND';

  @override
  String get tskPointsPerPerson => 'PUNKTE PRO PERSON';

  @override
  String get tskNoPoints => 'Noch keine Punkte';

  @override
  String get tskNoPointsHint => 'Erledige Aufgaben, um Punkte zu sammeln.';

  @override
  String get tskSomeDays => 'An manchen Tagen';

  @override
  String get tskOnce => 'Einmalig';

  @override
  String get tskNothingToday => 'Nichts für heute';

  @override
  String get tskAllDone => 'Alles erledigt';

  @override
  String tskLeft(int count) {
    return '$count übrig';
  }

  @override
  String tskOverdueCount(int count) {
    return '$count überfällig';
  }

  @override
  String tskMarkDone(String title) {
    return '$title als erledigt markieren';
  }

  @override
  String tskClaim(String title) {
    return '$title übernehmen';
  }

  @override
  String get tskOverdue => 'Überfällig';

  @override
  String tskPts(int points) {
    return '$points P.';
  }

  @override
  String tskView(String view) {
    String _temp0 = intl.Intl.selectLogic(view, {
      'pending': 'Offen',
      'pool': 'Pool',
      'other': 'Erledigt',
    });
    return '$_temp0';
  }

  @override
  String get tskOtherDay => 'Anderer Tag';

  @override
  String get tskEdit => 'Aufgabe bearbeiten';

  @override
  String get tskNameHint => 'Name der Aufgabe';

  @override
  String get tskOrTypeAnother => 'Oder schreib eine andere';

  @override
  String get tskWhen => 'Wann';

  @override
  String get tomorrow => 'Morgen';

  @override
  String get tskNoDate => 'Ohne Datum';

  @override
  String get tskRepeats => 'Wiederholt sich';

  @override
  String get tskWho => 'Wer';

  @override
  String get tskMe => 'Ich';

  @override
  String get tskAddPersonHint =>
      'Um sie jemandem zuzuweisen, füge die Person unter Zuhause hinzu (auch ohne Konto).';

  @override
  String get tskDetails => 'Details';

  @override
  String get tskNoTime => 'Ohne Uhrzeit';

  @override
  String get tskRemoveTime => 'Uhrzeit entfernen';

  @override
  String tskFreeAt(String time) {
    return 'Frei um $time';
  }

  @override
  String get tskNotes => 'Notizen';

  @override
  String get tskPoints => 'Punkte';

  @override
  String get tskAdd => 'Aufgabe hinzufügen';

  @override
  String get arcTitle => 'Rezept hinzufügen';

  @override
  String get arcLinkTitle => 'Videolink einfügen';

  @override
  String get arcLinkSub => 'Von TikTok oder YouTube, oder den Instagram-Text';

  @override
  String get arcNameTitle => 'Namen eingeben';

  @override
  String get arcNameSub => 'Wird mit Zutaten, Schritten und Makros ergänzt';

  @override
  String get arcIdeasTitle => 'Ideen für dich';

  @override
  String get arcIdeasSub => 'Passend zu Supermarkt, Ziel und Budget';

  @override
  String get arcManualTitle => 'Von Hand';

  @override
  String get arcManualSub => 'Jedes Feld selbst ausfüllen';

  @override
  String get arcCodeTitle => 'Mit einem Code';

  @override
  String get arcCodeSub => 'Speichere ein geteiltes Rezept';

  @override
  String get arcCodeDialog => 'Rezeptcode';

  @override
  String get search => 'Suchen';

  @override
  String get arcNoCode => 'Kein Rezept mit diesem Code';

  @override
  String arcIngredientsAsk(int count) {
    return '$count Zutaten. In deinen Rezepten speichern?';
  }

  @override
  String get arcSaved => 'Rezept gespeichert';

  @override
  String get nutLoadError => 'Profil konnte nicht geladen werden';

  @override
  String get nutSaved => 'Profil gespeichert';

  @override
  String get nutSaveError => 'Speichern fehlgeschlagen';

  @override
  String get nutBirthDate => 'Geburtsdatum';

  @override
  String get nutTitle => 'Mein Ernährungsprofil';

  @override
  String get nutDiary => 'Kalorientagebuch';

  @override
  String get nutWizard => 'Schritt für Schritt einrichten';

  @override
  String get nutWizardSub =>
      'Ein Assistent stellt dir ein paar Fragen und berechnet dein Ziel.';

  @override
  String get nutHowCook => 'Wie kochst du?';

  @override
  String get nutDaily => 'Täglich';

  @override
  String get nutDailySub => 'Ich koche jeden Tag';

  @override
  String get nutBatch => 'Vorkochen';

  @override
  String get nutBatchSub => 'Ich koche einmal für mehrere Tage';

  @override
  String get nutAmounts => 'Mengen';

  @override
  String get nutPractical => 'Praktisch';

  @override
  String get nutPracticalSub => 'Supermarkt-Packungen';

  @override
  String get nutExact => 'Exakt';

  @override
  String get nutExactSub => 'Aufs Gramm';

  @override
  String get nutSex => 'Geschlecht';

  @override
  String get nutFemale => 'Weiblich';

  @override
  String get nutMale => 'Männlich';

  @override
  String get nutSelect => 'Auswählen…';

  @override
  String nutAge(int age) {
    return '($age Jahre)';
  }

  @override
  String get nutHeight => 'Größe (cm)';

  @override
  String get nutWeight => 'Gewicht (kg)';

  @override
  String get nutActivityLevel => 'Aktivitätslevel';

  @override
  String get nutGoalLabel => 'Ziel';

  @override
  String nutActivity(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'sedentary': 'Sitzend (wenig oder kein Sport)',
      'light': 'Leicht (1-3 Tage/Woche)',
      'moderate': 'Mäßig (3-5 Tage/Woche)',
      'active': 'Aktiv (6-7 Tage/Woche)',
      'other': 'Sehr aktiv (intensiver Sport oder körperliche Arbeit)',
    });
    return '$_temp0';
  }

  @override
  String nutGoal(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'lose': 'Abnehmen',
      'gain': 'Zunehmen',
      'other': 'Gewicht halten',
    });
    return '$_temp0';
  }

  @override
  String get nutSplit => 'Kalorien pro Mahlzeit';

  @override
  String nutTotal(int pct) {
    return 'Gesamt: $pct%';
  }

  @override
  String get nutSplitHint =>
      'Setze 0% für Mahlzeiten, die du auslässt. Die Summe sollte 100% sein.';

  @override
  String get nutAtHome => 'Mahlzeiten zu Hause';

  @override
  String get nutAtHomeHint =>
      'Markiere die Tage, an denen du jede Mahlzeit zu Hause isst. Wenn du auswärts isst (z. B. bei der Arbeit), entferne den Tag und er zählt nicht.';

  @override
  String get nutShare => 'Mein Profil mit dem Haushalt teilen';

  @override
  String get nutShareSub => 'Wenn aus, ist dein Profil privat.';

  @override
  String get nutSave => 'Profil speichern';

  @override
  String get nutIncomplete =>
      'Gib Geschlecht, Geburtsdatum, Größe und Gewicht an, um deine täglichen Kalorien und Makros zu berechnen.';

  @override
  String get nutDailyTarget => 'Dein Tagesziel (ca.)';

  @override
  String nutKcalDay(int kcal) {
    return '$kcal kcal / Tag';
  }

  @override
  String nutPerMeal(int kcal, int meals) {
    return '≈ $kcal kcal pro Mahlzeit ($meals Mahlzeiten)';
  }

  @override
  String get ecoBudgetTitle => 'Monatsbudget';

  @override
  String ecoAmount(String symbol) {
    return 'Betrag ($symbol)';
  }

  @override
  String get ecoDeleteTicket => 'Kassenbon löschen?';

  @override
  String get ecoDeleteTicketSub =>
      'Er zählt dann nicht mehr zu deinen Ausgaben.';

  @override
  String ecoRedeemed(String title) {
    return 'Du hast \"$title\" eingelöst';
  }

  @override
  String get ecoRedeemFail =>
      'Einlösen fehlgeschlagen. Vielleicht reicht dein Guthaben nicht.';

  @override
  String get ecoNewReward => 'Neue Belohnung';

  @override
  String get ecoRewardTitle => 'Titel';

  @override
  String get ecoRewardDesc => 'Beschreibung (optional)';

  @override
  String get ecoRewardCost => 'Kosten in Punkten';

  @override
  String get ecoTitle => 'Ausgaben und Kassenbons';

  @override
  String get ecoStats => 'Einkaufsstatistik';

  @override
  String get ecoScan => 'Kassenbon scannen';

  @override
  String ecoTicketsOf(String month) {
    return 'Kassenbons im $month';
  }

  @override
  String get ecoPointsBalance => 'Punktestand';

  @override
  String get ecoPointsBalanceSub => 'Guthaben jedes Mitglieds für Belohnungen.';

  @override
  String get ecoNoPoints => 'Noch keine Punkte zu verteilen';

  @override
  String get ecoNoPointsSub => 'Erledigt Hausaufgaben, um Punkte zu sammeln.';

  @override
  String get ecoRewards => 'Belohnungen';

  @override
  String ecoBalance(int points) {
    return 'Dein Guthaben: $points P.';
  }

  @override
  String get ecoRedeem => 'Einlösen';

  @override
  String get ecoNoRewards => 'Noch keine Belohnungen';

  @override
  String get ecoNoRewardsSub => 'Erstelle die erste mit \"Neue Belohnung\".';

  @override
  String get ecoTotalSpent => 'Erfasste Gesamtausgaben';

  @override
  String ecoTicketCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kassenbons insgesamt',
      one: '1 Kassenbon insgesamt',
    );
    return '$_temp0';
  }

  @override
  String get ecoThisMonth => 'Dieser Monat';

  @override
  String ecoBudget(String amount) {
    return 'Budget: $amount';
  }

  @override
  String get ecoSetBudget => 'Budget festlegen';

  @override
  String ecoOver(String amount) {
    return 'Du liegst $amount über dem Budget';
  }

  @override
  String ecoLeft(String amount) {
    return 'Noch $amount übrig';
  }

  @override
  String get ecoLastMonths => 'Ausgaben der letzten Monate';

  @override
  String ecoBudgetPerMonth(String amount) {
    return 'Budget: $amount pro Monat';
  }

  @override
  String get ecoBudgetShort => 'Budget';

  @override
  String get ecoNoTrend =>
      'Noch keine Ausgaben in den letzten Monaten.\nScanne Kassenbons, um hier deinen Verlauf zu sehen.';

  @override
  String get ecoTicket => 'Kassenbon';

  @override
  String get ecoNoTickets =>
      'Diesen Monat noch keine Kassenbons.\nScanne den ersten.';

  @override
  String get stOthers => 'Sonstige';

  @override
  String get stNoCategory => 'Ohne Kategorie';

  @override
  String get stThisWeek => 'Diese';

  @override
  String get stTitle => 'Deine Daten';

  @override
  String get stSpendByMonth => 'Ausgaben pro Monat';

  @override
  String get stForecastFooter => 'Hell: was bis zur Prognose fehlt';

  @override
  String get stNoSpend =>
      'Scanne einen Kassenbon, um deine Ausgaben pro Monat zu sehen.';

  @override
  String get stWhereSpend => 'Wofür du diesen Monat ausgibst';

  @override
  String get stNoTicketsMonth => 'Diesen Monat noch keine Kassenbons.';

  @override
  String get stTopProducts => 'Was du am meisten kaufst';

  @override
  String get stTopProductsFooter =>
      'Anzahl auf deinen Kassenbons der letzten 3 Monate';

  @override
  String get stTopProductsEmpty => 'Erscheint, sobald du Kassenbons scannst.';

  @override
  String get stPantry => 'Dein Vorrat';

  @override
  String get stMealsHome => 'Mahlzeiten zu Hause';

  @override
  String get stPerWeek => 'Pro Woche';

  @override
  String stMealsOut(int count) {
    return 'Pro Woche · $count auswärts';
  }

  @override
  String get stMealsEmpty =>
      'Plane Mahlzeiten, um zu sehen, wie viele ihr zu Hause esst.';

  @override
  String get stTasksDone => 'Erledigte Aufgaben';

  @override
  String get stTasksFooter =>
      'Pro Woche und wer diesen Monat am meisten gemacht hat';

  @override
  String get stTasksEmpty => 'Erledigte Aufgaben erscheinen hier.';

  @override
  String get stSoFar => 'Bisher diesen Monat';

  @override
  String get stForecast => 'Prognose: ';

  @override
  String stMoreThanAvg(int pct) {
    return ', $pct % über deinem Schnitt';
  }

  @override
  String stLessThanAvg(int pct) {
    return ', $pct % unter deinem Schnitt';
  }

  @override
  String get stTickets => 'Kassenbons';

  @override
  String get stExpired => 'Abgelaufen';

  @override
  String get stExpiringSoon => 'Läuft bald ab';

  @override
  String get stFresh => 'Gut';

  @override
  String stOverForecast(String amount) {
    return 'So liegst du $amount über dem Budget';
  }

  @override
  String stForecastTip(String amount) {
    return 'Prognose $amount';
  }

  @override
  String get pwPickOption => 'Wähle eine Option, um fortzufahren.';

  @override
  String get pwPickBirth => 'Wähle dein Geburtsdatum.';

  @override
  String get pwBadHeight => 'Gib eine gültige Größe in Zentimetern ein.';

  @override
  String get pwBadWeight => 'Gib ein gültiges Gewicht in Kilo ein.';

  @override
  String get pwCompleteStep => 'Schließe diesen Schritt ab, um fortzufahren.';

  @override
  String get pwStart => 'PrezHome nutzen';

  @override
  String get pwSeeGoal => 'Mein Ziel ansehen';

  @override
  String get pwFinish => 'Fertig';

  @override
  String get pwIntroTitle => 'Lernen wir uns kennen';

  @override
  String get pwIntroSub =>
      'Ein paar kurze Fragen, um PrezHome an dich anzupassen. Du kannst es jederzeit ändern.';

  @override
  String get pwTrackKcal => 'Ich möchte Kalorien zählen';

  @override
  String get pwTrackKcalSub =>
      'Geplante Mahlzeiten werden danach automatisch eingetragen.';

  @override
  String get pwOnlyHome => 'Nur den Haushalt organisieren';

  @override
  String get pwOnlyHomeSub => 'Ohne Gewicht oder Maße.';

  @override
  String get pwSex => 'Dein Geschlecht';

  @override
  String get pwSexSub => 'Damit berechnen wir deinen Stoffwechsel genauer.';

  @override
  String get pwPickDate => 'Datum wählen';

  @override
  String get pwBirthTitle => 'Wann bist du geboren?';

  @override
  String get pwBirthSub =>
      'Dein Alter hilft uns, die Kalorien genauer zu berechnen.';

  @override
  String pwAgeYears(int age) {
    return '$age Jahre';
  }

  @override
  String get pwHeightTitle => 'Wie groß bist du?';

  @override
  String get pwHeightSub => 'Gib deine Größe in Zentimetern an.';

  @override
  String get pwWeightTitle => 'Wie viel wiegst du?';

  @override
  String get pwWeightSub => 'Gib dein aktuelles Gewicht in Kilo an.';

  @override
  String get pwActivityTitle => 'Dein Aktivitätslevel';

  @override
  String get pwActivitySub => 'Wähle, was deine Woche am besten beschreibt.';

  @override
  String get pwGoalTitle => 'Was ist dein Ziel?';

  @override
  String get pwGoalSub => 'Wir passen deine Kalorien an dein Ziel an.';

  @override
  String pwGoalDesc(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'lose': 'Sanftes Defizit, um langsam abzunehmen.',
      'gain': 'Sanfter Überschuss für gesunden Masseaufbau.',
      'other': 'Dein Gewicht halten und dich wohlfühlen.',
    });
    return '$_temp0';
  }

  @override
  String get pwDietTitle => 'Wie ernährst du dich?';

  @override
  String get pwDietSub => 'Rezepte passen sich deiner Ernährung an.';

  @override
  String pwDiet(String diet) {
    String _temp0 = intl.Intl.selectLogic(diet, {
      'vegetariana': 'Vegetarisch',
      'vegana': 'Vegan',
      'pescetariana': 'Pescetarisch',
      'baja_carbo': 'Low Carb',
      'sin_gluten': 'Glutenfrei',
      'other': 'Alles',
    });
    return '$_temp0';
  }

  @override
  String get pwAllergiesTitle => 'Allergien oder Unverträglichkeiten';

  @override
  String get pwOptional => 'Optional.';

  @override
  String pwAllergy(String allergy) {
    String _temp0 = intl.Intl.selectLogic(allergy, {
      'frutossecos': 'Nüsse',
      'lactosa': 'Laktose',
      'gluten': 'Gluten (Zöliakie)',
      'huevo': 'Ei',
      'marisco': 'Meeresfrüchte',
      'soja': 'Soja',
      'other': 'Fisch',
    });
    return '$_temp0';
  }

  @override
  String get pwCuisinesTitle => 'Was isst du gern?';

  @override
  String get pwCuisinesSub => 'Wähle so viele du willst.';

  @override
  String pwCuisine(String cuisine) {
    String _temp0 = intl.Intl.selectLogic(cuisine, {
      'casera': 'Hausmannskost',
      'mediterranea': 'Mediterran',
      'ligera': 'Leicht',
      'rapida': 'Schnell und einfach',
      'italiana': 'Italienisch',
      'asiatica': 'Asiatisch',
      'mexicana': 'Mexikanisch',
      'other': 'Aus aller Welt',
    });
    return '$_temp0';
  }

  @override
  String get pwAppliancesTitle => 'Was hast du in der Küche?';

  @override
  String get pwAppliancesSub =>
      'Der Plan nutzt nur Rezepte, die du kochen kannst.';

  @override
  String appliance(String appliance) {
    String _temp0 = intl.Intl.selectLogic(appliance, {
      'oven': 'Backofen',
      'stovetop': 'Pfanne',
      'pot': 'Topf',
      'airfryer': 'Heißluftfritteuse',
      'microwave': 'Mikrowelle',
      'blender': 'Mixer',
      'other': 'Keins',
    });
    return '$_temp0';
  }

  @override
  String get pwDislikedTitle => 'Zutaten, die du nicht magst';

  @override
  String get pwDislikedSub => 'Durch Kommas getrennt. Optional.';

  @override
  String get pwDislikedHint => 'Zwiebel, Koriander...';

  @override
  String get pwCookTimeTitle => 'Wie lange möchtest du kochen?';

  @override
  String get pwCookTimeSub =>
      'So passen die Rezepte zu deinem Tempo. Du kannst es offen lassen.';

  @override
  String pwCookTime(String time) {
    String _temp0 = intl.Intl.selectLogic(time, {
      'rapido': 'Schnell (unter 20 Min.)',
      'elaborado': 'Aufwendig (ich koche gern)',
      'other': 'Normal',
    });
    return '$_temp0';
  }

  @override
  String pwCookTimeDesc(String time) {
    String _temp0 = intl.Intl.selectLogic(time, {
      'rapido': 'Gerichte in kurzer Zeit.',
      'elaborado': 'Ich koche gern in Ruhe.',
      'other': 'Eine Mischung aus schnell und aufwendig.',
    });
    return '$_temp0';
  }

  @override
  String get pwCookStyleTitle => 'Wie kochst du am liebsten?';

  @override
  String get pwChangeAnytime => 'Du kannst es jederzeit ändern.';

  @override
  String cookStyle(String style) {
    String _temp0 = intl.Intl.selectLogic(style, {
      'batch': 'Vorkochen',
      'mixed': 'Gemischt',
      'other': 'Täglich',
    });
    return '$_temp0';
  }

  @override
  String cookStyleSub(String style) {
    String _temp0 = intl.Intl.selectLogic(style, {
      'batch': 'Ich koche auf Vorrat für mehrere Tage',
      'mixed': 'Ich kombiniere Vorkochen und tägliches Kochen',
      'other': 'Ich koche jeden Tag frisch',
    });
    return '$_temp0';
  }

  @override
  String get pwModulesTitle => 'Was möchtest du aktivieren?';

  @override
  String get pwModulesSub => 'Was du ausschaltest, wird nicht angezeigt.';

  @override
  String homeModule(String module) {
    String _temp0 = intl.Intl.selectLogic(module, {
      'points': 'Punktemodus',
      'tasks': 'Aufgaben',
      'other': 'Vorkochen',
    });
    return '$_temp0';
  }

  @override
  String homeModuleDesc(String module) {
    String _temp0 = intl.Intl.selectLogic(module, {
      'points': 'Sammle Punkte und Belohnungen für deine Aufgaben.',
      'tasks': 'Organisiere die Hausarbeit.',
      'other': 'Koche auf Vorrat und plane die Zubereitung.',
    });
    return '$_temp0';
  }

  @override
  String get pwAllSet => 'Alles bereit';

  @override
  String get pwAllSetSub =>
      'Rezepte, Plan und Einkauf passen sich deinen Angaben an.';

  @override
  String get pwDailyGoal => 'Dein Tagesziel';

  @override
  String get pwKcalDay => 'kcal / Tag';

  @override
  String get pwEstimate =>
      'Das ist eine erste Schätzung. Geplante Mahlzeiten werden danach automatisch ins Tagebuch eingetragen.';

  @override
  String get phCantAnalyze => 'Die Mahlzeit konnte nicht analysiert werden';

  @override
  String phAnalyzeError(String error) {
    return 'Foto konnte nicht analysiert werden: $error';
  }

  @override
  String get phAnalyzeFail => 'Foto konnte nicht analysiert werden';

  @override
  String get phAddOne => 'Füge mindestens ein Lebensmittel mit Namen hinzu.';

  @override
  String get phTitle => 'Mit Foto erfassen';

  @override
  String get phLooking => 'Schaue mir den Teller an…';

  @override
  String get phStartTitle => 'Fotografiere deinen Teller';

  @override
  String get phStartSub =>
      'Wir erkennen Lebensmittel und Kalorien. Du kannst vor dem Speichern korrigieren.';

  @override
  String get takePhoto => 'Foto aufnehmen';

  @override
  String get phReview => 'Prüfe und korrigiere das Erkannte';

  @override
  String get phApprox => 'Die Kalorien sind ungefähr.';

  @override
  String get phMealType => 'Mahlzeit (optional)';

  @override
  String get phNoType => 'Keine';

  @override
  String get day => 'Tag';

  @override
  String get phNothing => 'Kein Lebensmittel erkannt. Füge sie von Hand hinzu.';

  @override
  String phFoods(int count) {
    return 'LEBENSMITTEL ($count)';
  }

  @override
  String get phAddFood => 'Lebensmittel hinzufügen';

  @override
  String get phFood => 'Lebensmittel';

  @override
  String get phGrams => 'g (ca.)';

  @override
  String get phP => 'E (g)';

  @override
  String get phC => 'KH (g)';

  @override
  String get phF => 'F (g)';

  @override
  String get total => 'Gesamt';

  @override
  String kcalAmount(int kcal) {
    return '$kcal kcal';
  }

  @override
  String get phSave => 'Im Tagebuch speichern';

  @override
  String get stkOpenError => 'Kassenbon konnte nicht geöffnet werden';

  @override
  String get stkReadError => 'Kassenbon konnte nicht gelesen werden';

  @override
  String get stkScanError => 'Scannen fehlgeschlagen';

  @override
  String get stkPantryError =>
      'Kassenbon gespeichert, aber der Vorrat konnte nicht aktualisiert werden';

  @override
  String stkCrossed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Produkte von der Liste abgehakt',
      one: '1 Produkt von der Liste abgehakt',
    );
    return '$_temp0';
  }

  @override
  String get stkEdit => 'Kassenbon bearbeiten';

  @override
  String get stkReading => 'Lese den Kassenbon…';

  @override
  String get stkStartTitle => 'Scanne deinen Kassenbon';

  @override
  String get stkStartSub =>
      'Wir lesen Produkte und Preise aus. Du kannst es danach prüfen.';

  @override
  String get stkReview => 'Prüfe und korrigiere, was nötig ist';

  @override
  String get stkRemember =>
      'Deine Korrekturen werden fürs nächste Mal gemerkt.';

  @override
  String get stkStore => 'Geschäft';

  @override
  String get date => 'Datum';

  @override
  String get stkAddPantry => 'Zum Vorrat hinzufügen';

  @override
  String get stkAddPantrySub => 'Jedes Produkt an seinen Platz';

  @override
  String stkProducts(int count) {
    return 'PRODUKTE ($count)';
  }

  @override
  String stkRaw(String name) {
    return 'Bon: \"$name\"';
  }

  @override
  String get category => 'Kategorie';

  @override
  String get stkQty => 'Menge';

  @override
  String get stkSave => 'Kassenbon speichern';

  @override
  String foodCategory(String cat) {
    String _temp0 = intl.Intl.selectLogic(cat, {
      'verdura': 'Gemüse',
      'fruta': 'Obst',
      'carne': 'Fleisch',
      'pescado': 'Fisch',
      'lacteos': 'Milchprodukte',
      'preparados': 'Fertiggerichte',
      'panaderia': 'Backwaren',
      'cereales': 'Nudeln, Reis und Hülsenfrüchte',
      'conservas': 'Konserven',
      'congelados': 'Tiefkühlkost',
      'dulces': 'Süßes und Snacks',
      'bebidas': 'Getränke',
      'especias': 'Gewürze und Würzmittel',
      'higiene': 'Körperpflege',
      'limpieza': 'Reinigung',
      'hogar': 'Haushalt',
      'other': 'Sonstiges',
    });
    return '$_temp0';
  }

  @override
  String get cookMode => 'Kochmodus';

  @override
  String get bpMeanwhile => 'Währenddessen';

  @override
  String bpTapers(String title) {
    return 'Dosen · $title';
  }

  @override
  String get bpBatchCook => 'Vorkochen';

  @override
  String get bpStart => 'Schritt für Schritt starten';

  @override
  String get bpEmpty => 'Gerade gibt es nichts zu kochen';

  @override
  String get bpEmptySub =>
      'Sobald du Rezepte geplant hast, erstelle ich hier einen Kochplan, um alles auf einmal zu machen.';

  @override
  String get bpNeed => 'Was du brauchst';

  @override
  String get bpSplit => 'In Dosen aufteilen';

  @override
  String get bpSplitSub => 'Sie landen automatisch in Meine Küche';

  @override
  String get bpYourPlan => 'Dein Kochplan';

  @override
  String bpTotalMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Etwa $count Minuten insgesamt',
      one: 'Etwa 1 Minute insgesamt',
    );
    return '$_temp0';
  }

  @override
  String minutesShort(int count) {
    return '$count Min.';
  }

  @override
  String get bpParallel => 'Parallel';

  @override
  String bpFor(String recipes) {
    return 'Für $recipes';
  }

  @override
  String get ready => 'Fertig';

  @override
  String get pause => 'Pause';

  @override
  String get start => 'Start';

  @override
  String get reset => 'Zurücksetzen';

  @override
  String get bpDone => 'Erledigt';

  @override
  String get bpMarkDone => 'Als erledigt markieren';

  @override
  String cmStep(int n) {
    return 'Schritt $n';
  }

  @override
  String get cmTime => 'Zeit ist um';

  @override
  String get cmSeeStep => 'Schritt ansehen';

  @override
  String get ok => 'OK';

  @override
  String get cmMicPermission =>
      'Um die Sprachsteuerung zu nutzen, erlaube das Mikrofon in den Einstellungen.';

  @override
  String get ingredients => 'Zutaten';

  @override
  String get cmExit => 'Kochmodus beenden';

  @override
  String get cmHandsFreeOff => 'Freihändig aus';

  @override
  String get cmHandsFree => 'Freihändig';

  @override
  String get cmVoiceHint =>
      'Sag «siguiente», «anterior», «repite» oder «temporizador» (Sprache vorerst nur Spanisch)';

  @override
  String get cmStop => 'Stopp';

  @override
  String cmStepOf(int n, int total) {
    return 'SCHRITT $n VON $total';
  }

  @override
  String get cmTimerRunning => 'Timer läuft';

  @override
  String cmTimerMin(int count) {
    return 'Timer $count Min.';
  }

  @override
  String get cmThen => 'Danach';

  @override
  String get cmNextStep => 'Nächster Schritt';

  @override
  String get shopSugDue => 'Ist fällig';

  @override
  String get shopSugOut => 'Fehlt zu Hause';

  @override
  String get shopOutAtHome => 'Zu Hause leer';

  @override
  String get shopGridView => 'Rasteransicht';

  @override
  String get shopGridHint => 'Große Fotos, zwei pro Reihe';

  @override
  String get shopShowSuggestions => 'Vorschläge anzeigen';

  @override
  String get shopSuggestionsHint =>
      'Was nachgekauft werden muss und was zu Hause fehlt';

  @override
  String get shopShowPrices => 'Preise anzeigen';

  @override
  String shopEveryDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Alle $n Tage',
      one: 'Jeden Tag',
    );
    return '$_temp0';
  }

  @override
  String get slNewList => 'Neue Liste';

  @override
  String get slMyLists => 'Meine Listen';

  @override
  String get slActive => 'Aktiv';

  @override
  String get slNewCat => 'Neue Kategorie';

  @override
  String get slRenameCat => 'Kategorie umbenennen';

  @override
  String get slCategories => 'Kategorien';

  @override
  String get slAddCat => 'Kategorie hinzufügen';

  @override
  String get slNoCats =>
      'Noch keine Kategorien. Füge die erste mit dem Button unten hinzu.';

  @override
  String get rename => 'Umbenennen';

  @override
  String ppDayMeals(String day, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Mahlzeiten',
      one: '1 Mahlzeit',
    );
    return '$day, $_temp0';
  }

  @override
  String ppFastTime(String time) {
    return '$time · Fasten';
  }

  @override
  String get ppEatOut => '· Auswärts';

  @override
  String mealAdd(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'breakfast': 'Frühstück hinzufügen',
      'lunch': 'Mittagessen hinzufügen',
      'snack': 'Snack hinzufügen',
      'dinner': 'Abendessen hinzufügen',
      'dessert': 'Dessert hinzufügen',
      'other': 'Mahlzeit hinzufügen',
    });
    return '$_temp0';
  }

  @override
  String get ppFromFreezer => 'Aus dem Gefrierfach';

  @override
  String ppServings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Port.',
      one: '1 Portion',
    );
    return '$_temp0';
  }

  @override
  String get ppFresh => 'Frisch gekocht';

  @override
  String ppFridge(String days) {
    return 'Kühlschrank · $days';
  }

  @override
  String ppFreezer(String days) {
    return 'Gefrierfach · $days';
  }

  @override
  String get ppTapersAuto => 'Die Boxen landen automatisch in Meine Küche';
}
