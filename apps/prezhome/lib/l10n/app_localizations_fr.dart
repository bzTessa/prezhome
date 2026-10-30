// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String tabLabel(String tab) {
    String _temp0 = intl.Intl.selectLogic(tab, {
      'inicio': 'Aujourd\'hui',
      'comidas': 'Repas',
      'compra': 'Courses',
      'despensa': 'Garde-manger',
      'tareas': 'Tâches',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get country => 'Pays';

  @override
  String get countryHint => 'Devise, supermarchés et prix de référence';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get back => 'Retour';

  @override
  String get oneMoment => 'Un instant…';

  @override
  String get retry => 'Réessayer';

  @override
  String get loginAccountCreated => 'Compte créé. Bienvenue sur PrezHome';

  @override
  String get loginAuthError => 'Erreur de connexion';

  @override
  String loginProviderError(String provider) {
    return 'Impossible de se connecter avec $provider';
  }

  @override
  String get loginResetNeedsEmail =>
      'Saisis d\'abord ton e-mail et je t\'enverrai un lien pour réinitialiser ton mot de passe.';

  @override
  String get loginResetSent =>
      'Je t\'ai envoyé un e-mail pour réinitialiser ton mot de passe.';

  @override
  String get loginResetError => 'Impossible d\'envoyer l\'e-mail';

  @override
  String get loginWelcomeBack => 'Bon retour';

  @override
  String get loginCreateAccount => 'Crée ton compte';

  @override
  String get loginTagline => 'PrezHome, ta maison organisée';

  @override
  String loginContinueWith(String provider) {
    return 'Continuer avec $provider';
  }

  @override
  String get loginOrEmail => 'ou avec ton e-mail';

  @override
  String get loginEmail => 'E-mail';

  @override
  String get loginEmailInvalid => 'Saisis un e-mail valide';

  @override
  String get loginPassword => 'Mot de passe';

  @override
  String get loginShowPassword => 'Afficher le mot de passe';

  @override
  String get loginHidePassword => 'Masquer le mot de passe';

  @override
  String get loginPasswordShort => '6 caractères minimum';

  @override
  String get loginForgot => 'Mot de passe oublié ?';

  @override
  String get loginSignIn => 'Se connecter';

  @override
  String get loginSignUp => 'M\'inscrire';

  @override
  String get loginNoAccount => 'Pas de compte ? Inscris-toi';

  @override
  String get loginHaveAccount => 'Déjà un compte ? Connecte-toi';

  @override
  String get homeCodeFormat =>
      'Le code contient 8 lettres et chiffres (par exemple ABCD-EFGH).';

  @override
  String get homeSetupError => 'Impossible de configurer le foyer';

  @override
  String get homeLastStep => 'Dernière étape : ton foyer';

  @override
  String get homeCreateHint =>
      'Crée-le maintenant et, quand tu veux, invite les personnes qui vivent avec toi depuis Aujourd\'hui.';

  @override
  String get homeCreate => 'Créer mon foyer';

  @override
  String get homeInvited => 'On m\'a invité dans un foyer';

  @override
  String get homeInviteCode => 'Code d\'invitation';

  @override
  String get homeJoin => 'Rejoindre un foyer';

  @override
  String get sessionLoadError => 'Impossible de charger ton profil.';

  @override
  String get onbSectionHome => 'Ton foyer';

  @override
  String get onbPeopleTitle => 'Combien de personnes vivent chez vous ?';

  @override
  String get onbPeopleHint =>
      'Pour calculer les portions, les courses et la répartition des tâches.';

  @override
  String get onbSectionGoals => 'Ce qui t\'occupe';

  @override
  String get onbGoalsTitle => 'Qu\'aimerais-tu te sortir de la tête ?';

  @override
  String get onbGoalsHint =>
      'Choisis tout ce que tu veux. Le reste sera masqué.';

  @override
  String get onbPickOne => 'Choisis-en au moins une';

  @override
  String onbContinueCount(int count) {
    return 'Continuer ($count)';
  }

  @override
  String get onbSectionKitchen => 'En cuisine';

  @override
  String get onbCookingTitle => 'Comment cuisinez-vous ?';

  @override
  String get onbCookingHint =>
      'Ainsi on sait s\'il faut organiser des fournées et le congélateur.';

  @override
  String get onbSectionShopping => 'Les courses';

  @override
  String get onbShopTitle => 'Où fais-tu tes courses ?';

  @override
  String get onbShopHint =>
      'Le premier sera ton supermarché principal : les recettes utiliseront des produits faciles à y trouver.';

  @override
  String get onbSkipSeeHome => 'Passer et voir mon foyer';

  @override
  String get onbSeeHome => 'Voir mon foyer';

  @override
  String get onbSlogan => 'Une maison en ordre, l\'esprit tranquille.';

  @override
  String get onbStart => 'Commencer';

  @override
  String get onbHaveAccount => 'J\'ai déjà un compte';

  @override
  String get onbOneLess => 'Une de moins';

  @override
  String get onbOneMore => 'Une de plus';

  @override
  String onbPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personnes',
      one: 'Juste moi',
    );
    return '$_temp0';
  }

  @override
  String get onbProfileBadge => 'Ton profil de foyer';

  @override
  String onbProfileName(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'solo': 'En solo',
      'duo': 'Le Duo',
      'tribu': 'La Tribu',
      'other': 'La Famille',
    });
    return '$_temp0';
  }

  @override
  String onbProfileDescription(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'solo':
          'Toute la maison repose sur toi. PrezHome se souvient de ce qu\'il y a, de ce qui périme et de ce qu\'il faut faire, pour que tu n\'aies pas à le faire.',
      'duo':
          'Deux personnes, une maison. PrezHome répartit la charge de façon visible, pour que personne ne garde tout en tête.',
      'other':
          'Beaucoup de bouches et beaucoup de choses à la fois. PrezHome planifie repas, courses et tâches pour tous, et rappelle à chacun ce qui le concerne.',
    });
    return '$_temp0';
  }

  @override
  String get onbLoadToday => 'Charge mentale aujourd\'hui';

  @override
  String get onbLoadWithApp => 'Avec PrezHome';

  @override
  String onbLoad(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'high': 'lourde',
      'medium': 'moyenne',
      'other': 'légère',
    });
    return '$_temp0';
  }

  @override
  String get onbCreateAccount => 'Créer mon compte';

  @override
  String onbFeature(String f) {
    String _temp0 = intl.Intl.selectLogic(f, {
      'compra': 'Liste de courses',
      'comidas': 'Ce qu\'on mange',
      'despensa': 'Placards et dates de péremption',
      'tareas': 'Tâches ménagères',
      'other': 'Dépenses de la maison',
    });
    return '$_temp0';
  }

  @override
  String goalLabel(String g) {
    String _temp0 = intl.Intl.selectLogic(g, {
      'comidas': 'Ce qu\'on mange',
      'compra': 'Les courses',
      'despensa': 'Ce qu\'il y a à la maison',
      'tareas': 'Tâches ménagères',
      'lote': 'Cuisiner en avance',
      'other': 'Dépenses de la maison',
    });
    return '$_temp0';
  }

  @override
  String goalHint(String g) {
    String _temp0 = intl.Intl.selectLogic(g, {
      'comidas': 'Planning des repas et recettes',
      'compra': 'Une liste qui s\'écrit toute seule',
      'despensa': 'Placards, frigo et dates de péremption',
      'tareas': 'Répartition juste et rappels',
      'lote': 'Boîtes et congélateur organisés',
      'other': 'Budget et tickets',
    });
    return '$_temp0';
  }

  @override
  String cookingLabel(String c) {
    String _temp0 = intl.Intl.selectLogic(c, {
      'diario': 'Chaque jour',
      'lote': 'En avance',
      'mixto': 'Un peu des deux',
      'other': 'Presque jamais',
    });
    return '$_temp0';
  }

  @override
  String cookingHint(String c) {
    String _temp0 = intl.Intl.selectLogic(c, {
      'diario': 'Je cuisine sur le moment',
      'lote': 'Je prépare plusieurs jours d\'un coup',
      'mixto': 'Certains jours en avance',
      'other': 'Je mange dehors ou un truc rapide',
    });
    return '$_temp0';
  }

  @override
  String homeGreeting(String part) {
    String _temp0 = intl.Intl.selectLogic(part, {
      'morning': 'Bonjour',
      'afternoon': 'Bon après-midi',
      'other': 'Bonsoir',
    });
    return '$_temp0';
  }

  @override
  String get homeCustomize => 'Personnaliser Aujourd\'hui';

  @override
  String get homeYourData => 'Tes données';

  @override
  String get homeYourHome => 'Ton foyer';

  @override
  String homeTodayTag(String meal) {
    return 'Aujourd\'hui · $meal';
  }

  @override
  String mealType(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'breakfast': 'Petit-déjeuner',
      'lunch': 'Déjeuner',
      'snack': 'Goûter',
      'dinner': 'Dîner',
      'dessert': 'Dessert',
      'drink': 'Boisson',
      'other': 'Repas',
    });
    return '$_temp0';
  }

  @override
  String get homeEatingOut => 'À l\'extérieur';

  @override
  String get homeWhatToEat => 'Qu\'est-ce qu\'on mange aujourd\'hui ?';

  @override
  String get homeNothingPlanned =>
      'Rien n\'est encore prévu pour aujourd\'hui.';

  @override
  String get homePlan => 'Planifier';

  @override
  String get homeWithWhatIHave => 'Avec ce que j\'ai';

  @override
  String get homeExpiring => 'Bientôt périmé';

  @override
  String homeTasksToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tâches aujourd\'hui',
      one: 'Tâche aujourd\'hui',
    );
    return '$_temp0';
  }

  @override
  String get homeInShopping => 'Sur la liste';

  @override
  String get homeShortcuts => 'Raccourcis';

  @override
  String get homeForToday => 'Pour aujourd\'hui';

  @override
  String get homeSeeAll => 'Tout voir';

  @override
  String homePoints(int points) {
    return '$points pts';
  }

  @override
  String homePointsSnack(int points) {
    return '+$points points';
  }

  @override
  String get homeToday => 'Aujourd\'hui';

  @override
  String get homeTomorrow => 'Demain';

  @override
  String get homeCaloriesTitle => 'Calcule ton objectif de calories';

  @override
  String get homeCaloriesHint =>
      'Réponds à quelques questions rapides et j\'adapterai PrezHome pour toi.';

  @override
  String homeOf(String total) {
    return 'sur $total';
  }

  @override
  String get homeCaloriesToday => 'Calories du jour';

  @override
  String homeKcal(int kcal) {
    return '$kcal kcal';
  }

  @override
  String homeKcalLeft(int kcal) {
    return 'Il te reste $kcal kcal';
  }

  @override
  String homeKcalOver(int kcal) {
    return '$kcal kcal de trop';
  }

  @override
  String get homeMonthSpend => 'Dépenses du mois';

  @override
  String homeMoneyLeft(String amount) {
    return 'Il te reste $amount';
  }

  @override
  String homeMoneyOver(String amount) {
    return '$amount au-dessus du budget';
  }

  @override
  String get save => 'Enregistrer';

  @override
  String get homeCardsSection => 'Cartes (glisse pour réordonner)';

  @override
  String get homeQuickSection => 'Accès rapides';

  @override
  String get homeQuickHint =>
      'Choisis les raccourcis affichés en haut d\'Aujourd\'hui.';

  @override
  String dashCard(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'meals': 'Repas du jour',
      'calories': 'Calories du jour',
      'tasks': 'Tâches',
      'other': 'Dépenses du mois',
    });
    return '$_temp0';
  }

  @override
  String quickAction(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'add_inventory': 'Ajouter aux placards',
      'scan_ticket': 'Scanner un ticket',
      'shopping': 'Liste de courses',
      'add_recipe': 'Nouvelle recette',
      'meal_plan': 'Planning de la semaine',
      'other': 'Journal des calories',
    });
    return '$_temp0';
  }

  @override
  String get shopPickStore => 'Choisir un supermarché';

  @override
  String get shopAddFromPlan => 'Ajouter le planning de la semaine';

  @override
  String get shopListOptions => 'Options de la liste';

  @override
  String get shopAllInCart => 'Tout est dans le panier';

  @override
  String shopPending(int pending, int done) {
    return '$pending à acheter · $done dans le panier';
  }

  @override
  String shopUnpriced(int count) {
    return ' · $count sans prix';
  }

  @override
  String get shopAddProduct => 'Ajouter un produit';

  @override
  String get shopSearchStore => 'Chercher au supermarché';

  @override
  String get moreOptions => 'Plus d\'options';

  @override
  String get less => 'Moins';

  @override
  String get more => 'Plus';

  @override
  String shopAdded(String name) {
    return '$name, ajouté';
  }

  @override
  String shopAdd(String name) {
    return 'Ajouter $name';
  }

  @override
  String get shopLiveOffline =>
      'Pas de connexion en direct pour l\'instant ; la liste se mettra à jour au rechargement.';

  @override
  String get couldNotUpdate => 'Impossible de mettre à jour';

  @override
  String shopSavedToPantry(int count) {
    return '$count produits rangés dans les placards';
  }

  @override
  String get shopRemoveFromList => 'Retirer de la liste';

  @override
  String shopRemovedOne(String name) {
    return '\"$name\" retiré';
  }

  @override
  String get couldNotChangePhoto => 'Impossible de changer la photo';

  @override
  String get shopAddToList => 'Ajouter à la liste';

  @override
  String get shopTypeFood => 'Alimentation';

  @override
  String get shopTypeHome => 'Maison/Ménage';

  @override
  String get name => 'Nom';

  @override
  String get product => 'Produit';

  @override
  String get quantity => 'Quantité';

  @override
  String get unit => 'Unité';

  @override
  String get cancel => 'Annuler';

  @override
  String get add => 'Ajouter';

  @override
  String get nameEmpty => 'Le nom ne peut pas être vide.';

  @override
  String get couldNotAdd => 'Impossible d\'ajouter';

  @override
  String get shopPlanAllAtHome =>
      'Tu as déjà à la maison tout ce qu\'il faut pour le planning';

  @override
  String shopAddedFromPlan(int count) {
    return '$count produits du planning ajoutés';
  }

  @override
  String get shopListTitle => 'Liste de courses';

  @override
  String get shopMainList => 'Liste principale';

  @override
  String get couldNotCreateList => 'Impossible de créer la liste';

  @override
  String get shopRecipesUseStore =>
      'Les recettes utiliseront des produits de ce supermarché.';

  @override
  String get shopStoreSaveError =>
      'Impossible d\'enregistrer le supermarché. Réessaie.';

  @override
  String get shopGroupByAisle => 'Grouper par rayon';

  @override
  String get shopGroupHint => 'Légumes, viande, ménage…';

  @override
  String get shopShowPhotos => 'Afficher les photos des produits';

  @override
  String get shopMyLists => 'Mes listes';

  @override
  String get categories => 'Catégories';

  @override
  String get shopFinish => 'Terminer les courses';

  @override
  String shopFinishCount(int count) {
    return 'Terminer les courses ($count)';
  }

  @override
  String get shopScanTicket => 'Scanner le ticket';

  @override
  String get shopAllBought => 'Tout acheté';

  @override
  String get shopToBuy => 'À acheter';

  @override
  String get shopUsual => 'L\'habituel';

  @override
  String get shopInCart => 'Dans le panier';

  @override
  String shopRemovedMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count produits retirés',
      one: '1 produit retiré',
    );
    return '$_temp0';
  }

  @override
  String get couldNotRemove => 'Impossible de retirer';

  @override
  String get undo => 'Annuler';

  @override
  String get couldNotUndo => 'Impossible d\'annuler';

  @override
  String get shopToCart => 'Au panier';

  @override
  String get shopFromPlan => 'Du planning de la semaine';

  @override
  String get changePhoto => 'Changer la photo';

  @override
  String get shopEmptyTitle => 'Ta liste est vide';

  @override
  String get shopEmptyHint =>
      'Écris en haut ce dont tu as besoin ou importe le planning.';

  @override
  String get shopFromPlanAction => 'Depuis le planning';

  @override
  String get shopDoneTitle => 'Courses terminées';

  @override
  String get shopDoneHint => 'Tu as tout ce qui est sur la liste. Bien joué !';

  @override
  String panUsedInOne(String meal) {
    return 'Retiré ce que tu as utilisé pour $meal';
  }

  @override
  String panUsedInMany(int count) {
    return 'Retiré ce que tu as utilisé pour $count repas du planning';
  }

  @override
  String get view => 'Voir';

  @override
  String get couldNotDelete => 'Impossible de supprimer';

  @override
  String panNoLongerShop(String name) {
    return '$name n\'apparaîtra plus dans les courses.';
  }

  @override
  String panBackToShop(String name) {
    return '$name réapparaîtra dans les courses.';
  }

  @override
  String panCouldNotMarkOut(String name) {
    return 'Impossible de marquer $name comme épuisé';
  }

  @override
  String panMarkedOut(String name) {
    return 'J\'ai marqué $name comme épuisé.';
  }

  @override
  String panOutNotAdded(String name) {
    return '$name est épuisé, mais je n\'ai pas pu l\'ajouter aux courses';
  }

  @override
  String panAlreadyInList(String name) {
    return '$name est déjà sur ta liste de courses.';
  }

  @override
  String panAddedToShop(String name) {
    return 'J\'ai ajouté $name aux courses';
  }

  @override
  String get panAddManual => 'Ajouter à la main';

  @override
  String get panScanBarcode => 'Scanner le code-barres';

  @override
  String get panFreezeDish => 'Plat cuisiné au congélateur';

  @override
  String get panFreezeDishHint => 'Choisis la recette et le nombre de portions';

  @override
  String get panSaveRecipeFirst => 'Enregistre d\'abord une recette.';

  @override
  String get panWhichDish => 'Quel plat vas-tu congeler ?';

  @override
  String get panHowManyServings => 'Combien de portions congèles-tu ?';

  @override
  String get panTitle => 'Placards et Frigo';

  @override
  String get panAddTooltip => 'Ajouter aux placards';

  @override
  String get panLoadError => 'Impossible de charger l\'inventaire';

  @override
  String get panEmptyTitle => 'Tes placards sont vides';

  @override
  String get panEmptyHint =>
      'Ajoute ce que tu as chez toi ou coche tes courses et ça arrivera tout seul.';

  @override
  String get panAddProduct => 'Ajouter un produit';

  @override
  String get panWhatToCook => 'Qu\'est-ce que je cuisine avec ça ?';

  @override
  String get panExpiringHeader => 'Périmés et bientôt périmés';

  @override
  String get panNothingHere => 'Rien ici.';

  @override
  String kitchenZone(String zone) {
    String _temp0 = intl.Intl.selectLogic(zone, {
      'nevera': 'Frigo',
      'congelador': 'Congélateur',
      'despensa': 'Placards',
      'bebidas': 'Boissons',
      'especias': 'Condiments',
      'limpieza': 'Ménage',
      'hogar': 'Hygiène et maison',
      'other': '$zone',
    });
    return '$_temp0';
  }

  @override
  String get kitchenReview => 'À vérifier';

  @override
  String expiryGroup(String group) {
    String _temp0 = intl.Intl.selectLogic(group, {
      'expired': 'Périmé',
      'week': 'Cette semaine',
      'later': 'Plus tard',
      'other': 'Sans date',
    });
    return '$_temp0';
  }

  @override
  String panExpiredAgo(int days) {
    return 'Périmé depuis $days jours';
  }

  @override
  String get panExpiredYesterday => 'Périmé hier';

  @override
  String get panExpiresToday => 'Périme aujourd\'hui';

  @override
  String get panExpiresTomorrow => 'Périme demain';

  @override
  String panExpiresIn(int days) {
    return 'Périme dans $days jours';
  }

  @override
  String panDays(int days) {
    return '$days jours';
  }

  @override
  String get panNotBought => 'Pas acheté';

  @override
  String get panConsumed => 'Consommé';

  @override
  String get panToShopping => 'Aux courses';

  @override
  String panCouldNotAddToShop(String name) {
    return 'Impossible d\'ajouter $name aux courses';
  }

  @override
  String panExpiredDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count produits périmés supprimés',
      one: 'Produit périmé supprimé',
    );
    return '$_temp0';
  }

  @override
  String get panMyKitchen => 'Ma cuisine';

  @override
  String get panUsedHistory => 'Ce qui a été consommé';

  @override
  String get panNothingExpired => 'Rien de périmé';

  @override
  String panDeleteExpired(int count) {
    return 'Supprimer les périmés ($count)';
  }

  @override
  String panEmptyZone(String where) {
    return 'Vider $where';
  }

  @override
  String panEmptyAsk(String where) {
    return 'Vider $where ?';
  }

  @override
  String panWillDelete(int count) {
    return '$count produits seront supprimés.';
  }

  @override
  String get panEmpty => 'Vider';

  @override
  String panDeleted(int count) {
    return '$count produits supprimés';
  }

  @override
  String get edit => 'Modifier';

  @override
  String get panShopAgain => 'Remettre dans les courses';

  @override
  String get panDontShop => 'Ne pas ajouter aux courses';

  @override
  String get panStapleHint => 'Pour les basiques que tu as toujours';

  @override
  String get panWillAddToShop => 'Je l\'ajouterai aux courses';

  @override
  String get delete => 'Supprimer';

  @override
  String panDeleteAsk(String name) {
    return 'Supprimer $name ?';
  }

  @override
  String panConsumedOn(String name, String day) {
    return '$name, consommé $day';
  }

  @override
  String get todayLower => 'aujourd\'hui';

  @override
  String get yesterdayLower => 'hier';

  @override
  String panOnDate(int day, int month) {
    return 'le $day/$month';
  }

  @override
  String get panWhen => 'Quand ?';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String get panOtherDay => 'Un autre jour';

  @override
  String get panWhichDay => 'Quel jour ?';

  @override
  String get panHowMany => 'Combien ?';

  @override
  String panAll(String qty) {
    return 'Tout ($qty)';
  }

  @override
  String get couldNotLoad => 'Impossible de charger';

  @override
  String get panNothingYet => 'Rien pour l\'instant.';

  @override
  String get panWhenCooking => 'En cuisinant';

  @override
  String get planHowLong => 'Pour combien de temps ?';

  @override
  String get thisWeek => 'Cette semaine';

  @override
  String planWeeks(int count) {
    return '$count semaines';
  }

  @override
  String get planMonth4 => 'Un mois (4 semaines)';

  @override
  String get planPickDates => 'Choisir les dates';

  @override
  String get planDates => 'Dates du planning';

  @override
  String get planMaxTwoMonths => 'Deux mois maximum à la fois.';

  @override
  String get planReadyAllHome =>
      'Planning prêt. Tu as déjà tout ce qu\'il faut à la maison';

  @override
  String planListReady(int count) {
    return 'Planning prêt. Liste de courses avec $count produits';
  }

  @override
  String get planBackInPlan => 'C\'est de nouveau dans le planning';

  @override
  String planEntryTitle(String meal, String recipe) {
    return '$meal · $recipe';
  }

  @override
  String get planNoRecipe => 'Sans recette';

  @override
  String get planChangeRecipe => 'Changer de recette';

  @override
  String get planWhoEats => 'Qui mange';

  @override
  String get planMarkHome => 'Marquer à la maison';

  @override
  String get planMarkOut => 'Marquer comme dehors';

  @override
  String get planStopRepeat => 'Arrêter de répéter';

  @override
  String get planStopRepeatHint => 'Retire les prochaines fois';

  @override
  String get planRepeat => 'Répéter';

  @override
  String get planRepeatHint => 'Chaque jour, chaque semaine… ou pour toujours';

  @override
  String get planRemove => 'Retirer du planning';

  @override
  String planRepeatTitle(String meal) {
    return 'Répéter $meal';
  }

  @override
  String get planHowOften => 'À quelle fréquence ?';

  @override
  String planEveryDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Tous les $days jours',
      one: 'Chaque jour',
    );
    return '$_temp0';
  }

  @override
  String planEveryWeeks(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: 'Toutes les $weeks semaines',
      one: 'Chaque semaine',
    );
    return '$_temp0';
  }

  @override
  String get planUntilWhen => 'Jusqu\'à quand ?';

  @override
  String get planForever => 'Pour toujours';

  @override
  String planMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mois',
      one: '1 mois',
    );
    return '$_temp0';
  }

  @override
  String get planRepeatDone =>
      'C\'est fait. Tu le verras dans le planning les prochaines semaines ; si un jour a déjà autre chose, on le garde.';

  @override
  String get planWhoAtHome => 'Qui mange à la maison ?';

  @override
  String get planCalendarPermission =>
      'Autorise l\'accès au calendrier dans les réglages du téléphone';

  @override
  String get planInFast => 'Tombe pendant le jeûne';

  @override
  String get planSettings => 'Réglages du planning';

  @override
  String get planBatchCook => 'Je cuisine en batch';

  @override
  String get planBatchCookHint => 'Jour de courses, de cuisine et boîtes';

  @override
  String get planTimes => 'Horaires';

  @override
  String get planFasting => 'Jeûne intermittent';

  @override
  String get no => 'Non';

  @override
  String planEatWindow(String from, String to) {
    return 'Tu manges de $from à $to. Ça suit l\'heure du dîner.';
  }

  @override
  String get planCalendar => 'Calendrier';

  @override
  String get planToCalendar => 'Envoyer au calendrier';

  @override
  String get planCalendarLinked => 'Calendrier connecté';

  @override
  String get planCalendarHint =>
      'Repas et tâches avec horaire, dans Google Agenda';

  @override
  String get planCalendarUpdates => 'Se met à jour à l\'ouverture du planning';

  @override
  String get remove => 'Retirer';

  @override
  String get planPickRecipe => 'Choisis une recette';

  @override
  String get planDayFull => 'Ce jour a déjà tous ses repas.';

  @override
  String get planWhichMeal => 'Quel repas ajoutes-tu ?';

  @override
  String get planTitle => 'Planning de la semaine';

  @override
  String get planNoHome => 'Tu ne fais partie d\'aucun foyer.';

  @override
  String get planMake => 'Faire le planning';

  @override
  String get planRemake => 'Refaire le planning';

  @override
  String get planNeedRecipes => 'Ajoute d\'abord quelques recettes';

  @override
  String get planNeedRecipesHint =>
      'Le planificateur répartit tes recettes sur la semaine. Enregistres-en quelques-unes dans l\'onglet Repas.';

  @override
  String get planPrevWeek => 'Semaine précédente';

  @override
  String get planNextWeekLabel => 'La semaine prochaine';

  @override
  String get planLastWeek => 'La semaine dernière';

  @override
  String get planWeek => 'Semaine';

  @override
  String get planBackToToday => 'Revenir à aujourd\'hui';

  @override
  String get planNextWeek => 'Semaine suivante';

  @override
  String get planDay => 'Jour';

  @override
  String get planMonthCalendar => 'Calendrier du mois';

  @override
  String get planNoPlanYet => 'Pas encore de planning pour cette semaine.';

  @override
  String get recipe => 'Recette';

  @override
  String get planCookMode => 'Mode cuisine';

  @override
  String get planCookWeek => 'Cuisine la semaine d\'un coup';

  @override
  String get planBatch => 'Batch cooking';

  @override
  String planCookDays(int days, int recipes) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours de cuisine',
      one: '1 jour de cuisine',
    );
    String _temp1 = intl.Intl.pluralLogic(
      recipes,
      locale: localeName,
      other: '$recipes recettes',
      one: '1 recette',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get planBatchEmpty =>
      'Une fois le planning fait, je te dis quand faire les courses, quand cuisiner et ce qui va au frigo ou au congélateur.';

  @override
  String get planCookedToFreezer => 'Cuisiné · au congélateur';

  @override
  String planFrozen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plats rangés au congélateur.',
      one: 'Rangé au congélateur avec sa photo.',
    );
    return '$_temp0';
  }

  @override
  String get planEnergyLow => 'Peu';

  @override
  String get planEnergyNormal => 'Normal';

  @override
  String get planEnergyHigh => 'Beaucoup';

  @override
  String get planEnergyHint =>
      'Avec « peu », le planning puise davantage dans le congélateur.';

  @override
  String get planHowMuchCook => 'Combien cuisiner';

  @override
  String planServings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count portions',
      one: '1 portion',
    );
    return '$_temp0';
  }

  @override
  String get close => 'Fermer';

  @override
  String get planSearchRecipe => 'Chercher une recette...';

  @override
  String get planNoMatch => 'Aucune recette correspondante.';

  @override
  String get diaDeleteError => 'Impossible de supprimer le repas.';

  @override
  String get diaManual => 'À la main';

  @override
  String get diaManualHint => 'Écris le nom et les calories';

  @override
  String get diaFromRecipe => 'Depuis une recette';

  @override
  String get diaFromRecipeHint => 'Enregistre une de tes recettes comme repas';

  @override
  String get diaWithPhoto => 'Avec une photo';

  @override
  String get diaWithPhotoHint =>
      'Prends le plat en photo et on calcule les calories';

  @override
  String get diaAddManual => 'Ajouter à la main';

  @override
  String get diaKcalField => 'Calories (kcal)';

  @override
  String get diaMealTypeOptional => 'Type de repas (facultatif)';

  @override
  String get diaNoType => 'Sans type';

  @override
  String get diaProteinG => 'Protéines (g)';

  @override
  String get diaCarbsG => 'Glucides (g)';

  @override
  String get diaFatG => 'Lipides (g)';

  @override
  String get diaNeedNameKcal => 'Indique au moins un nom et les calories.';

  @override
  String get diaSaveError => 'Impossible d\'enregistrer le repas.';

  @override
  String get diaRecipesLoadError => 'Impossible de charger les recettes.';

  @override
  String get diaNoRecipes => 'Tu n\'as pas encore de recettes à enregistrer.';

  @override
  String diaKcalPerServing(int kcal) {
    return '$kcal kcal par portion';
  }

  @override
  String get diaNoKcal => 'Pas de calories enregistrées';

  @override
  String get diaServings => 'Portions';

  @override
  String get diaServingsError => 'Indique un nombre de portions supérieur à 0.';

  @override
  String get diaLog => 'Enregistrer';

  @override
  String get diaRecipeLogError => 'Impossible d\'enregistrer la recette.';

  @override
  String get diaTitle => 'Mon journal';

  @override
  String get diaAddMeal => 'Ajouter un repas';

  @override
  String get previous => 'Précédent';

  @override
  String get next => 'Suivant';

  @override
  String get diaDayCalories => 'Calories du jour';

  @override
  String diaOfTarget(int kcal) {
    return 'sur $kcal kcal';
  }

  @override
  String get diaNoTarget =>
      'Complète ton profil pour fixer un objectif calorique quotidien et voir ce qu\'il te reste chaque jour.';

  @override
  String get diaCompleteProfile => 'Compléter mon profil';

  @override
  String get diaOthers => 'Autres';

  @override
  String get diaMeal => 'Repas';

  @override
  String get diaLast7 => 'Tes 7 derniers jours';

  @override
  String diaTargetPerDay(int kcal) {
    return 'Objectif : $kcal kcal par jour';
  }

  @override
  String get diaTarget => 'Objectif';

  @override
  String get diaTodaySplit => 'Répartition du jour';

  @override
  String get diaNoMacros => 'Pas encore de macros enregistrés aujourd\'hui.';

  @override
  String get diaProtein => 'Protéines';

  @override
  String get diaCarbs => 'Glucides';

  @override
  String get diaFat => 'Lipides';

  @override
  String get diaAteThePlan => 'As-tu mangé ce qui était prévu ?';

  @override
  String diaAskLine(String day, String meal, String name, int kcal) {
    return '$day, $meal : $name · $kcal kcal';
  }

  @override
  String get yes => 'Oui';

  @override
  String get diaAnswerError => 'Impossible d\'enregistrer la réponse.';

  @override
  String get diaAskFirst => 'Me demander avant d\'enregistrer le planning';

  @override
  String get diaAskOn =>
      'On te demande si tu as mangé chaque repas du planning.';

  @override
  String get diaAskOff =>
      'Les repas du planning s\'enregistrent tout seuls une fois l\'heure passée.';

  @override
  String get diaSettingError => 'Impossible d\'enregistrer le réglage.';

  @override
  String get diaEmpty =>
      'Tu n\'as encore rien noté ce jour-là.\nAjoute ton premier repas.';

  @override
  String get recUnfavorite => 'Retirer des favoris';

  @override
  String get recFavorite => 'Marquer comme favorite';

  @override
  String get recDelete => 'Supprimer la recette';

  @override
  String get recDeleteAsk => 'Supprimer la recette ?';

  @override
  String recRemoveAsk(String name) {
    return '\"$name\" et ses ingrédients seront supprimés.';
  }

  @override
  String recDeleted(String name) {
    return '\"$name\" supprimée.';
  }

  @override
  String get recTitle => 'Recettes';

  @override
  String get recNew => 'Nouvelle recette';

  @override
  String get recLoadError => 'Je n\'ai pas pu charger les recettes';

  @override
  String get recEmptyTitle => 'Pas encore de recettes';

  @override
  String get recEmptyHint =>
      'Crée la première ou demande des idées avec ce que tu as.';

  @override
  String get recIdeas => 'Des idées avec ce que j\'ai';

  @override
  String get recNoResults => 'Aucun résultat';

  @override
  String recCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recettes',
      one: '1 recette',
    );
    return '$_temp0';
  }

  @override
  String get recWhatToCook => 'Qu\'est-ce que je cuisine avec ce que j\'ai ?';

  @override
  String get recPantryIdeas => 'Des idées avec ce qu\'il y a dans tes placards';

  @override
  String get recAll => 'Toutes';

  @override
  String get recFavorites => 'Favorites';

  @override
  String get recNoFilter =>
      'Aucune recette avec ce filtre.\nEssaie une autre catégorie.';

  @override
  String get clear => 'Effacer';

  @override
  String recNoMatch(String query) {
    return 'Aucune recette ne correspond à\n« $query ».';
  }

  @override
  String get rdPhoto => 'Photo de la recette';

  @override
  String get rdAutoPhoto => 'Chercher une autre photo automatiquement';

  @override
  String get rdAutoPhotoHint => 'Cherche une nouvelle image par le nom';

  @override
  String get rdGallery => 'Choisir dans la galerie';

  @override
  String get rdNoBetterPhoto =>
      'Je n\'ai pas trouvé de meilleure photo pour l\'instant';

  @override
  String get rdUploadError => 'Impossible d\'envoyer la photo';

  @override
  String rdShareText(String title, String code) {
    return 'Voici ma recette de $title sur PrezHome. Dans l\'appli, va dans Recettes, touche Ajouter une recette puis Avec un code : $code';
  }

  @override
  String get rdSavedFreezer => 'Rangé au congélateur.';

  @override
  String get couldNotSave => 'Impossible d\'enregistrer';

  @override
  String get rdVideoError => 'Impossible d\'ouvrir le lien de la vidéo';

  @override
  String get rdWatchVideo => 'Voir la vidéo';

  @override
  String get share => 'Partager';

  @override
  String get rdEdit => 'Modifier la recette';

  @override
  String get rdMinutes => 'Minutes';

  @override
  String get rdKcalServing => 'Kcal/portion';

  @override
  String get rdPerServingShort => 'par portion';

  @override
  String rdServingWord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Portions',
      one: 'Portion',
    );
    return '$_temp0';
  }

  @override
  String get rdFreezable => 'Congelable';

  @override
  String get rdIngredients => 'Ingrédients';

  @override
  String get rdStepsWord => 'Étapes';

  @override
  String rdSteps(int count) {
    return 'Étapes ($count)';
  }

  @override
  String get rdNutrition => 'Nutrition';

  @override
  String get rdNoIngredients => 'Aucun ingrédient enregistré.';

  @override
  String rdOriginal(String servings) {
    return 'Recette d\'origine : $servings';
  }

  @override
  String rdForHome(String servings) {
    return 'Pour ton foyer aujourd\'hui : $servings';
  }

  @override
  String get rdHaveAll => 'Tu as tout à la maison';

  @override
  String rdHaveSome(int have, int total) {
    return 'Tu as $have sur $total à la maison';
  }

  @override
  String rdMissing(int count) {
    return 'Il en manque $count';
  }

  @override
  String get rdAtHome => 'À la maison';

  @override
  String get rdLacking => 'Manque';

  @override
  String get rdNoSteps =>
      'Cette recette n\'a pas d\'étapes. Tu peux les ajouter en la modifiant.';

  @override
  String get rdPerServingTitle => 'Par portion';

  @override
  String get rdNoNutrition => 'Pas de données nutritionnelles.';

  @override
  String rdPerServing(String amount) {
    return '$amount par portion';
  }

  @override
  String rdTotal(String amount) {
    return '≈ $amount au total';
  }

  @override
  String get rdApproxCost =>
      'Coût approximatif. Scanne tes tickets pour l\'affiner avec tes vrais prix.';

  @override
  String get rdStartCooking => 'Commencer à cuisiner';

  @override
  String rdAddedMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count produits ajoutés aux courses',
      one: 'Ajouté à la liste de courses',
    );
    return '$_temp0';
  }

  @override
  String get rdNeedProfile =>
      'Complète un profil nutritionnel pour voir combien de grammes et de calories revient à chaque personne.';

  @override
  String get rdMember => 'Membre';

  @override
  String get rdAdjustSplit =>
      'Ajuste la répartition des calories par repas dans le profil pour ce type de recette.';

  @override
  String get rdByProfile => 'Selon le profil de chacun';

  @override
  String get rdByProfileHint =>
      'Quantité et calories par personne pour ce repas.';

  @override
  String get arWriteName => 'Écris le nom';

  @override
  String get arWriteNameHint => 'Écris le nom ou colle une recette entière…';

  @override
  String get arGenerate => 'Générer';

  @override
  String get arFilled => 'Recette remplie. Vérifie-la avant d\'enregistrer.';

  @override
  String get arFillError => 'Impossible de compléter la recette';

  @override
  String get arImport => 'Importer une recette';

  @override
  String get arPasteRecipe => 'Colle la recette';

  @override
  String get arImportHint =>
      'Colle le lien TikTok, YouTube ou d\'un site, ou le texte de la recette. Sur Instagram, copie la description du post et colle-la ici.';

  @override
  String get arLinkOrText => 'Lien ou texte de la recette';

  @override
  String get arRecipeText => 'Texte de la recette';

  @override
  String get paste => 'Coller';

  @override
  String get arImportBtn => 'Importer';

  @override
  String get arNeedLink => 'Colle un lien ou le texte complet de la recette.';

  @override
  String get arImported => 'Recette importée. Vérifie-la avant d\'enregistrer.';

  @override
  String get arImportLinkError =>
      'Je n\'ai pas pu importer la recette depuis ce lien';

  @override
  String get arImportError => 'Impossible d\'importer';

  @override
  String get arPickMealType => 'Choisis au moins un type de repas.';

  @override
  String get arVideoNotUrl =>
      'Le lien vidéo ne ressemble pas à une URL, mais on l\'enregistre quand même.';

  @override
  String get arRecalculated =>
      'Calories et macros recalculées à partir des ingrédients.';

  @override
  String arPhotoFailed(String error) {
    return 'Recette enregistrée, mais la photo n\'a pas pu être envoyée : $error';
  }

  @override
  String get arSaveError => 'Erreur lors de l\'enregistrement';

  @override
  String get arReadingVideo => 'Lecture de la recette depuis la vidéo…';

  @override
  String get arCompleting => 'Recette en cours de complétion…';

  @override
  String get arAddPhoto => 'Ajouter une photo (facultatif)';

  @override
  String get arTitleField => 'Titre';

  @override
  String get arTitleRequired => 'Donne-lui un titre';

  @override
  String get arDescription => 'Description (facultatif)';

  @override
  String get arVideoLink => 'Lien vidéo (facultatif)';

  @override
  String get arMealTypes => 'Type de repas (plusieurs choix possibles)';

  @override
  String get arAuto => 'Auto';

  @override
  String get arServingsHelper => 'Pour combien';

  @override
  String get arGramsServing => 'Grammes / portion';

  @override
  String get arNutritionTitle => 'Valeurs nutritionnelles (par portion)';

  @override
  String get arCooking => 'Cuisine';

  @override
  String get arPrepMin => 'Préparation (min)';

  @override
  String get arCookMin => 'Cuisson (min)';

  @override
  String get arAppliance => 'Appareil principal';

  @override
  String get arFreezable => 'Se congèle';

  @override
  String get arAddIngredient => 'Ajouter un ingrédient';

  @override
  String get arStepsTitle => 'Étapes de préparation';

  @override
  String get arStepsHint => 'Écris les étapes, une par ligne…';

  @override
  String get arSaveChanges => 'Enregistrer les modifications';

  @override
  String get arSaveRecipe => 'Enregistrer la recette';

  @override
  String get arIngredient => 'Ingrédient';
}
