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
  String get loginConfirmEmailSent =>
      'Nous t\'avons envoyé un e-mail pour confirmer ton compte. Ouvre-le sur ce téléphone et tu seras connecté.';

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
      'Le premier sera ton supermarché principal : nous y chercherons les produits de ta liste de courses.';

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
  String get shopAddDetailed => 'Ajouter avec détails';

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
      'Les produits de ta liste seront cherchés dans ce supermarché. Les recettes marchent partout.';

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
  String get shopShowIcons =>
      'Afficher des dessins quand il n\'y a pas de photo';

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
      'hogar': 'Divers',
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
  String get planAddDish => 'Ajouter un autre plat';

  @override
  String get planAutoDessert => 'Dessert automatique';

  @override
  String get planAutoDessertHint => 'Le plan ajoute un dessert à ces repas';

  @override
  String get planBoughtReady => 'Acheté tout prêt';

  @override
  String get planBoughtReadyHint =>
      'Un plat préparé du supermarché, sans cuisiner';

  @override
  String get planYourReady => 'Tes plats préparés';

  @override
  String get planReadySearch => 'Chercher au supermarché';

  @override
  String get planReadyEmpty =>
      'Tu n\'as pas encore de plats préparés de confiance. Cherche-les dans le catalogue du supermarché.';

  @override
  String get planReadyMain => 'Plat';

  @override
  String get planReadyDessert => 'Dessert';

  @override
  String get planReadyKcal => 'Calories par portion (facultatif)';

  @override
  String get planReadyRemove => 'Retirer de tes plats préparés';

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
      'Avec « peu », le plan choisit des recettes rapides et puise dans le congélateur et tes plats préparés.';

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
  String get recOther => 'Autres';

  @override
  String recSeeAll(int count) {
    return 'Voir les $count';
  }

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

  @override
  String get tskWhoDid => 'Qui a fait la tâche ?';

  @override
  String get tskTheHome => 'le foyer';

  @override
  String tskPointsFor(int points, String who) {
    return '+$points points pour $who';
  }

  @override
  String tskPointsForPantry(int points, String who, int count) {
    return '+$points points pour $who. $count produits dans les placards';
  }

  @override
  String tskYou(String name) {
    return '$name (toi)';
  }

  @override
  String get tskThisMember => 'ce membre';

  @override
  String get tskResetPoints => 'Réinitialiser les points';

  @override
  String tskResetAsk(String name) {
    return 'Les points de $name seront remis à 0. C\'est irréversible. Tu es sûr ?';
  }

  @override
  String get tskReset => 'Réinitialiser';

  @override
  String tskResetDone(String name) {
    return 'Points de $name réinitialisés.';
  }

  @override
  String get tskDeleteTitle => 'Supprimer la tâche ?';

  @override
  String tskDeleteAsk(String title) {
    return '\"$title\" sera supprimée.';
  }

  @override
  String tskClaimed(String title) {
    return '\"$title\" est à toi';
  }

  @override
  String get tskDone => 'Faite';

  @override
  String get tskToTomorrow => 'Reporter à demain';

  @override
  String get tskToNextWeek => 'Reporter à la semaine prochaine';

  @override
  String get tskTitle => 'Tâches';

  @override
  String get tskEmptyTitle => 'Pas encore de tâches';

  @override
  String get tskEmptyHint => 'Ajoute la première.';

  @override
  String get tskNew => 'Nouvelle tâche';

  @override
  String get tskAnyone => 'N\'importe qui';

  @override
  String get tskForToday => 'Pour aujourd\'hui';

  @override
  String get tskUpcoming => 'Prochains jours';

  @override
  String get tskPoolEmpty => 'Rien dans le pot commun. Tout a un responsable.';

  @override
  String get tskSwipeToClaim => 'Glisse vers la gauche pour la prendre.';

  @override
  String get tskNothingDone => 'Rien de fait aujourd\'hui pour l\'instant.';

  @override
  String get tskAll => 'Toutes';

  @override
  String get tskMine => 'Les miennes';

  @override
  String get tskAllDoneToday => 'Tout est fait aujourd\'hui';

  @override
  String get tskNextBelow => 'La suite, plus bas.';

  @override
  String get tskNothingLeft => 'Plus rien en attente.';

  @override
  String get tskScoreboard => 'TABLEAU DES SCORES';

  @override
  String get tskPointsPerPerson => 'POINTS PAR PERSONNE';

  @override
  String get tskNoPoints => 'Pas encore de points';

  @override
  String get tskNoPointsHint => 'Termine des tâches pour cumuler des points.';

  @override
  String get tskSomeDays => 'Certains jours';

  @override
  String get tskOnce => 'Une fois';

  @override
  String get tskNothingToday => 'Rien pour aujourd\'hui';

  @override
  String get tskAllDone => 'Tout est fait';

  @override
  String tskLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Il en reste $count',
      one: 'Il en reste 1',
    );
    return '$_temp0';
  }

  @override
  String tskOverdueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count en retard',
      one: '1 en retard',
    );
    return '$_temp0';
  }

  @override
  String tskMarkDone(String title) {
    return 'Marquer $title comme faite';
  }

  @override
  String tskClaim(String title) {
    return 'Prendre $title';
  }

  @override
  String get tskOverdue => 'En retard';

  @override
  String tskPts(int points) {
    return '$points pts';
  }

  @override
  String tskView(String view) {
    String _temp0 = intl.Intl.selectLogic(view, {
      'pending': 'À faire',
      'pool': 'Pot commun',
      'other': 'Faites',
    });
    return '$_temp0';
  }

  @override
  String get tskOtherDay => 'Un autre jour';

  @override
  String get tskEdit => 'Modifier la tâche';

  @override
  String get tskNameHint => 'Nom de la tâche';

  @override
  String get tskOrTypeAnother => 'Ou écris-en une autre';

  @override
  String get tskWhen => 'Quand';

  @override
  String get tomorrow => 'Demain';

  @override
  String get tskNoDate => 'Sans date';

  @override
  String get tskRepeats => 'Se répète';

  @override
  String get tskWho => 'Qui';

  @override
  String get tskMe => 'Moi';

  @override
  String get tskAddPersonHint =>
      'Pour l\'attribuer à quelqu\'un, ajoute cette personne dans Foyer (même sans compte).';

  @override
  String get tskDetails => 'Détails';

  @override
  String get tskNoTime => 'Sans heure';

  @override
  String get tskRemoveTime => 'Retirer l\'heure';

  @override
  String tskFreeAt(String time) {
    return 'Libre à $time';
  }

  @override
  String get tskNotes => 'Notes';

  @override
  String get tskPoints => 'Points';

  @override
  String get tskAdd => 'Ajouter la tâche';

  @override
  String get arcTitle => 'Ajouter une recette';

  @override
  String get arcLinkTitle => 'Coller un lien vidéo';

  @override
  String get arcLinkSub => 'De TikTok ou YouTube, ou le texte d\'Instagram';

  @override
  String get arcNameTitle => 'Écris le nom';

  @override
  String get arcNameSub => 'Complétée avec ingrédients, étapes et macros';

  @override
  String get arcIdeasTitle => 'Idées pour toi';

  @override
  String get arcIdeasSub => 'Selon ton supermarché, ton objectif et ton budget';

  @override
  String get arcManualTitle => 'À la main';

  @override
  String get arcManualSub => 'Remplis chaque champ toi-même';

  @override
  String get arcCodeTitle => 'Avec un code';

  @override
  String get arcCodeSub => 'Enregistre une recette partagée avec toi';

  @override
  String get arcCodeDialog => 'Code de la recette';

  @override
  String get search => 'Rechercher';

  @override
  String get arcNoCode => 'Aucune recette avec ce code';

  @override
  String arcIngredientsAsk(int count) {
    return '$count ingrédients. L\'enregistrer dans tes recettes ?';
  }

  @override
  String get arcSaved => 'Recette enregistrée';

  @override
  String get nutLoadError => 'Impossible de charger le profil';

  @override
  String get nutSaved => 'Profil enregistré';

  @override
  String get nutSaveError => 'Erreur d\'enregistrement';

  @override
  String get nutBirthDate => 'Date de naissance';

  @override
  String get nutTitle => 'Mon profil nutritionnel';

  @override
  String get nutDiary => 'Journal des calories';

  @override
  String get nutWizard => 'Configurer pas à pas';

  @override
  String get nutWizardSub =>
      'Un assistant te pose quelques questions et calcule ton objectif.';

  @override
  String get nutHowCook => 'Comment cuisines-tu ?';

  @override
  String get nutDaily => 'Au jour le jour';

  @override
  String get nutDailySub => 'Je cuisine chaque jour';

  @override
  String get nutBatch => 'Cuisine en lot';

  @override
  String get nutBatchSub => 'Je cuisine une fois pour plusieurs jours';

  @override
  String get nutAmounts => 'Quantités';

  @override
  String get nutPractical => 'Pratiques';

  @override
  String get nutPracticalSub => 'Formats du supermarché';

  @override
  String get nutExact => 'Exactes';

  @override
  String get nutExactSub => 'Au gramme près';

  @override
  String get nutSex => 'Sexe';

  @override
  String get nutFemale => 'Femme';

  @override
  String get nutMale => 'Homme';

  @override
  String get nutSelect => 'Choisir…';

  @override
  String nutAge(int age) {
    return '($age ans)';
  }

  @override
  String get nutHeight => 'Taille (cm)';

  @override
  String get nutWeight => 'Poids (kg)';

  @override
  String get nutActivityLevel => 'Niveau d\'activité';

  @override
  String get nutGoalLabel => 'Objectif';

  @override
  String nutActivity(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'sedentary': 'Sédentaire (peu ou pas d\'exercice)',
      'light': 'Léger (1-3 jours/semaine)',
      'moderate': 'Modéré (3-5 jours/semaine)',
      'active': 'Actif (6-7 jours/semaine)',
      'other': 'Très actif (sport intense ou travail physique)',
    });
    return '$_temp0';
  }

  @override
  String nutGoal(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'lose': 'Perdre du poids',
      'gain': 'Prendre du poids',
      'other': 'Maintenir son poids',
    });
    return '$_temp0';
  }

  @override
  String get nutSplit => 'Répartition des calories par repas';

  @override
  String nutTotal(int pct) {
    return 'Total : $pct %';
  }

  @override
  String get nutSplitHint =>
      'Mets 0 % aux repas que tu ne prends pas. Le total doit faire 100 %.';

  @override
  String get nutAtHome => 'Repas à la maison';

  @override
  String get nutAtHomeHint =>
      'Coche les jours où tu prends chaque repas à la maison. Si tu manges dehors (au travail, par ex.), décoche ce jour et il ne comptera pas.';

  @override
  String get nutShare => 'Partager mon profil avec le foyer';

  @override
  String get nutShareSub => 'Si désactivé, ton profil est privé.';

  @override
  String get nutSave => 'Enregistrer le profil';

  @override
  String get nutIncomplete =>
      'Renseigne sexe, date de naissance, taille et poids pour calculer tes calories et macros du jour.';

  @override
  String get nutDailyTarget => 'Ton objectif quotidien (env.)';

  @override
  String nutKcalDay(int kcal) {
    return '$kcal kcal / jour';
  }

  @override
  String nutPerMeal(int kcal, int meals) {
    return '≈ $kcal kcal par repas ($meals repas)';
  }

  @override
  String get ecoBudgetTitle => 'Budget mensuel';

  @override
  String ecoAmount(String symbol) {
    return 'Montant ($symbol)';
  }

  @override
  String get ecoDeleteTicket => 'Supprimer le ticket ?';

  @override
  String get ecoDeleteTicketSub => 'Il ne comptera plus dans tes dépenses.';

  @override
  String ecoRedeemed(String title) {
    return 'Tu as échangé \"$title\"';
  }

  @override
  String get ecoRedeemFail =>
      'Échange impossible. Il te manque peut-être des points.';

  @override
  String get ecoNewReward => 'Nouvelle récompense';

  @override
  String get ecoRewardTitle => 'Titre';

  @override
  String get ecoRewardDesc => 'Description (facultatif)';

  @override
  String get ecoRewardCost => 'Coût en points';

  @override
  String get ecoTitle => 'Dépenses et tickets';

  @override
  String get ecoStats => 'Statistiques des courses';

  @override
  String get ecoScan => 'Scanner un ticket';

  @override
  String ecoTicketsOf(String month) {
    return 'Tickets de $month';
  }

  @override
  String get ecoPointsBalance => 'Balance des points';

  @override
  String get ecoPointsBalanceSub =>
      'Solde de chaque membre pour échanger des récompenses.';

  @override
  String get ecoNoPoints => 'Pas encore de points à répartir';

  @override
  String get ecoNoPointsSub =>
      'Faites des tâches du foyer pour remplir la balance.';

  @override
  String get ecoRewards => 'Récompenses';

  @override
  String ecoBalance(int points) {
    return 'Ton solde : $points pts';
  }

  @override
  String get ecoRedeem => 'Échanger';

  @override
  String get ecoNoRewards => 'Pas encore de récompenses';

  @override
  String get ecoNoRewardsSub =>
      'Crée la première avec le bouton \"Nouvelle récompense\".';

  @override
  String get ecoTotalSpent => 'Dépense totale enregistrée';

  @override
  String ecoTicketCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tickets au total',
      one: '1 ticket au total',
    );
    return '$_temp0';
  }

  @override
  String get ecoThisMonth => 'Ce mois-ci';

  @override
  String ecoBudget(String amount) {
    return 'Budget : $amount';
  }

  @override
  String get ecoSetBudget => 'Fixer un budget';

  @override
  String ecoOver(String amount) {
    return 'Tu as dépassé le budget de $amount';
  }

  @override
  String ecoLeft(String amount) {
    return 'Il te reste $amount';
  }

  @override
  String get ecoLastMonths => 'Dépenses des derniers mois';

  @override
  String ecoBudgetPerMonth(String amount) {
    return 'Budget : $amount par mois';
  }

  @override
  String get ecoBudgetShort => 'Budget';

  @override
  String get ecoNoTrend =>
      'Aucune dépense enregistrée ces derniers mois.\nScanne des tickets pour voir ta tendance ici.';

  @override
  String get ecoTicket => 'Ticket';

  @override
  String get ecoNoTickets =>
      'Pas encore de tickets ce mois-ci.\nScanne le premier.';

  @override
  String get stOthers => 'Autres';

  @override
  String get stNoCategory => 'Sans catégorie';

  @override
  String get stThisWeek => 'Cette';

  @override
  String get stTitle => 'Tes données';

  @override
  String get stSpendByMonth => 'Dépenses par mois';

  @override
  String get stForecastFooter =>
      'En clair : ce qu\'il reste jusqu\'à la prévision';

  @override
  String get stNoSpend =>
      'Scanne un ticket pour voir tes dépenses mois par mois.';

  @override
  String get stWhereSpend => 'Où vont tes dépenses ce mois-ci';

  @override
  String get stNoTicketsMonth => 'Pas encore de tickets ce mois-ci.';

  @override
  String get stTopProducts => 'Ce que tu achètes le plus';

  @override
  String get stTopProductsFooter =>
      'Nombre de fois sur tes tickets des 3 derniers mois';

  @override
  String get stTopProductsEmpty => 'Apparaîtra quand tu scanneras des tickets.';

  @override
  String get stPantry => 'Tes placards';

  @override
  String get stMealsHome => 'Repas à la maison';

  @override
  String get stPerWeek => 'Par semaine';

  @override
  String stMealsOut(int count) {
    return 'Par semaine · $count hors de la maison';
  }

  @override
  String get stMealsEmpty =>
      'Planifie des repas pour voir combien vous en prenez à la maison.';

  @override
  String get stTasksDone => 'Tâches faites';

  @override
  String get stTasksFooter =>
      'Par semaine, et qui en a fait le plus ce mois-ci';

  @override
  String get stTasksEmpty => 'Les tâches terminées apparaîtront ici.';

  @override
  String get stSoFar => 'Dépensé ce mois-ci';

  @override
  String get stForecast => 'Prévision : ';

  @override
  String stMoreThanAvg(int pct) {
    return ', $pct % de plus que ta moyenne';
  }

  @override
  String stLessThanAvg(int pct) {
    return ', $pct % de moins que ta moyenne';
  }

  @override
  String get stTickets => 'Tickets';

  @override
  String get stExpired => 'Périmé';

  @override
  String get stExpiringSoon => 'Périme bientôt';

  @override
  String get stFresh => 'Ok';

  @override
  String stOverForecast(String amount) {
    return 'À ce rythme tu dépasseras le budget de $amount';
  }

  @override
  String stForecastTip(String amount) {
    return 'Prévision $amount';
  }

  @override
  String get pwPickOption => 'Choisis une option pour continuer.';

  @override
  String get pwPickBirth => 'Choisis ta date de naissance.';

  @override
  String get pwBadHeight => 'Saisis une taille valide en centimètres.';

  @override
  String get pwBadWeight => 'Saisis un poids valide en kilos.';

  @override
  String get pwCompleteStep => 'Termine cette étape pour continuer.';

  @override
  String get pwStart => 'Commencer à utiliser PrezHome';

  @override
  String get pwSeeGoal => 'Voir mon objectif';

  @override
  String get pwFinish => 'Terminer';

  @override
  String get pwIntroTitle => 'Faisons connaissance';

  @override
  String get pwIntroSub =>
      'Quelques questions rapides pour adapter PrezHome à toi. Tu peux le changer quand tu veux.';

  @override
  String get pwTrackKcal => 'Je veux suivre mes calories';

  @override
  String get pwTrackKcalSub =>
      'Les repas du plan s\'enregistrent tout seuls une fois passés.';

  @override
  String get pwOnlyHome => 'Juste organiser la maison';

  @override
  String get pwOnlyHomeSub => 'Sans poids ni mesures.';

  @override
  String get pwSex => 'Ton sexe';

  @override
  String get pwSexSub =>
      'On l\'utilise pour calculer ton métabolisme plus précisément.';

  @override
  String get pwPickDate => 'Choisir une date';

  @override
  String get pwBirthTitle => 'Quand es-tu né(e) ?';

  @override
  String get pwBirthSub => 'L\'âge nous aide à affiner le calcul des calories.';

  @override
  String pwAgeYears(int age) {
    return '$age ans';
  }

  @override
  String get pwHeightTitle => 'Quelle est ta taille ?';

  @override
  String get pwHeightSub => 'Indique ta taille en centimètres.';

  @override
  String get pwWeightTitle => 'Combien pèses-tu ?';

  @override
  String get pwWeightSub => 'Indique ton poids actuel en kilos.';

  @override
  String get pwActivityTitle => 'Ton niveau d\'activité';

  @override
  String get pwActivitySub =>
      'Choisis l\'option qui décrit le mieux ta semaine.';

  @override
  String get pwGoalTitle => 'Quel est ton objectif ?';

  @override
  String get pwGoalSub =>
      'On ajustera tes calories selon ce que tu veux atteindre.';

  @override
  String pwGoalDesc(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'lose': 'Léger déficit pour perdre du poids petit à petit.',
      'gain': 'Léger surplus pour prendre de la masse sainement.',
      'other': 'Garder ton poids actuel et te sentir bien.',
    });
    return '$_temp0';
  }

  @override
  String get pwDietTitle => 'Comment manges-tu ?';

  @override
  String get pwDietSub => 'Les recettes s\'adapteront à ton régime.';

  @override
  String pwDiet(String diet) {
    String _temp0 = intl.Intl.selectLogic(diet, {
      'vegetariana': 'Végétarien',
      'vegana': 'Végan',
      'pescetariana': 'Pescétarien',
      'baja_carbo': 'Pauvre en glucides',
      'sin_gluten': 'Sans gluten',
      'other': 'De tout',
    });
    return '$_temp0';
  }

  @override
  String get pwAllergiesTitle => 'Allergies ou intolérances';

  @override
  String get pwOptional => 'Facultatif.';

  @override
  String pwAllergy(String allergy) {
    String _temp0 = intl.Intl.selectLogic(allergy, {
      'frutossecos': 'fruits à coque',
      'lactosa': 'lactose',
      'gluten': 'gluten (cœliaquie)',
      'huevo': 'œuf',
      'marisco': 'fruits de mer',
      'soja': 'soja',
      'other': 'poisson',
    });
    return '$_temp0';
  }

  @override
  String get pwCuisinesTitle => 'Qu\'aimes-tu manger ?';

  @override
  String get pwCuisinesSub => 'Choisis-en autant que tu veux.';

  @override
  String pwCuisine(String cuisine) {
    String _temp0 = intl.Intl.selectLogic(cuisine, {
      'casera': 'Cuisine maison',
      'mediterranea': 'Méditerranéenne',
      'ligera': 'Légère',
      'rapida': 'Rapide et simple',
      'italiana': 'Italienne',
      'asiatica': 'Asiatique',
      'mexicana': 'Mexicaine',
      'other': 'Du monde entier',
    });
    return '$_temp0';
  }

  @override
  String get pwAppliancesTitle => 'Qu\'as-tu dans ta cuisine ?';

  @override
  String get pwAppliancesSub =>
      'Le plan n\'utilisera que des recettes que tu peux faire.';

  @override
  String appliance(String appliance) {
    String _temp0 = intl.Intl.selectLogic(appliance, {
      'oven': 'Four',
      'stovetop': 'Poêle',
      'pot': 'Casserole',
      'airfryer': 'Friteuse à air',
      'microwave': 'Micro-ondes',
      'blender': 'Mixeur',
      'other': 'Aucun',
    });
    return '$_temp0';
  }

  @override
  String get pwDislikedTitle => 'Ingrédients que tu n\'aimes pas';

  @override
  String get pwDislikedSub => 'Séparés par des virgules. Facultatif.';

  @override
  String get pwDislikedHint => 'oignon, coriandre...';

  @override
  String get pwCookTimeTitle => 'Combien de temps veux-tu cuisiner ?';

  @override
  String get pwCookTimeSub =>
      'Pour adapter les recettes à ton rythme. Tu peux ne rien choisir.';

  @override
  String pwCookTime(String time) {
    String _temp0 = intl.Intl.selectLogic(time, {
      'rapido': 'Rapide (moins de 20 min)',
      'elaborado': 'Élaboré (j\'aime cuisiner)',
      'other': 'Normal',
    });
    return '$_temp0';
  }

  @override
  String pwCookTimeDesc(String time) {
    String _temp0 = intl.Intl.selectLogic(time, {
      'rapido': 'Des plats prêts en peu de temps.',
      'elaborado': 'J\'aime cuisiner tranquillement.',
      'other': 'Un équilibre entre rapide et élaboré.',
    });
    return '$_temp0';
  }

  @override
  String get pwCookStyleTitle => 'Comment préfères-tu cuisiner ?';

  @override
  String get pwChangeAnytime => 'Tu peux le changer quand tu veux.';

  @override
  String cookStyle(String style) {
    String _temp0 = intl.Intl.selectLogic(style, {
      'batch': 'En lot',
      'mixed': 'Mixte',
      'other': 'Au quotidien',
    });
    return '$_temp0';
  }

  @override
  String cookStyleSub(String style) {
    String _temp0 = intl.Intl.selectLogic(style, {
      'batch': 'Je cuisine en lots pour plusieurs jours',
      'mixed': 'Je combine lots et cuisine du jour',
      'other': 'Je cuisine chaque jour sur le moment',
    });
    return '$_temp0';
  }

  @override
  String get pwModulesTitle => 'Que veux-tu activer ?';

  @override
  String get pwModulesSub => 'Ce que tu désactives ne s\'affichera pas.';

  @override
  String homeModule(String module) {
    String _temp0 = intl.Intl.selectLogic(module, {
      'points': 'Mode points',
      'tasks': 'Tâches',
      'other': 'Cuisine en lot',
    });
    return '$_temp0';
  }

  @override
  String homeModuleDesc(String module) {
    String _temp0 = intl.Intl.selectLogic(module, {
      'points': 'Gagne des points et des récompenses pour tes tâches.',
      'tasks': 'Organise les tâches du foyer.',
      'other': 'Cuisine en lots et planifie tes préparations.',
    });
    return '$_temp0';
  }

  @override
  String get pwAllSet => 'Tout est prêt';

  @override
  String get pwAllSetSub =>
      'Recettes, plan et courses s\'adaptent à ce que tu as dit.';

  @override
  String get pwDailyGoal => 'Ton objectif quotidien';

  @override
  String get pwKcalDay => 'kcal / jour';

  @override
  String get pwEstimate =>
      'C\'est une estimation pour commencer. Les repas du plan s\'enregistreront seuls dans ton journal une fois passés.';

  @override
  String get phCantAnalyze => 'Impossible d\'analyser le repas';

  @override
  String phAnalyzeError(String error) {
    return 'Erreur d\'analyse de la photo : $error';
  }

  @override
  String get phAnalyzeFail => 'Erreur d\'analyse de la photo';

  @override
  String get phAddOne => 'Ajoute au moins un aliment avec un nom.';

  @override
  String get phTitle => 'Enregistrer avec une photo';

  @override
  String get phLooking => 'J\'examine l\'assiette…';

  @override
  String get phStartTitle => 'Prends ton assiette en photo';

  @override
  String get phStartSub =>
      'On calcule les aliments et leurs calories. Tu pourras corriger avant d\'enregistrer.';

  @override
  String get takePhoto => 'Prendre une photo';

  @override
  String get phReview => 'Vérifie et corrige ce qui a été détecté';

  @override
  String get phApprox => 'Les calories sont approximatives.';

  @override
  String get phMealType => 'Repas (facultatif)';

  @override
  String get phNoType => 'Aucun';

  @override
  String get day => 'Jour';

  @override
  String get phNothing => 'Aucun aliment reconnu. Ajoute-les à la main.';

  @override
  String phFoods(int count) {
    return 'ALIMENTS ($count)';
  }

  @override
  String get phAddFood => 'Ajouter un aliment';

  @override
  String get phFood => 'Aliment';

  @override
  String get phGrams => 'g (env.)';

  @override
  String get phP => 'P (g)';

  @override
  String get phC => 'G (g)';

  @override
  String get phF => 'L (g)';

  @override
  String get total => 'Total';

  @override
  String kcalAmount(int kcal) {
    return '$kcal kcal';
  }

  @override
  String get phSave => 'Enregistrer dans le journal';

  @override
  String get stkOpenError => 'Impossible d\'ouvrir le ticket';

  @override
  String get stkReadError => 'Impossible de lire le ticket';

  @override
  String get stkScanError => 'Erreur de scan';

  @override
  String get stkPantryError =>
      'Ticket enregistré, mais impossible de mettre à jour les placards';

  @override
  String stkCrossed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count produits cochés sur la liste',
      one: '1 produit coché sur la liste',
    );
    return '$_temp0';
  }

  @override
  String get stkEdit => 'Modifier le ticket';

  @override
  String get stkReading => 'Lecture du ticket…';

  @override
  String get stkStartTitle => 'Scanne le ticket de courses';

  @override
  String get stkStartSub =>
      'On récupère produits et prix. Tu pourras vérifier ensuite.';

  @override
  String get stkReview => 'Vérifie et corrige si besoin';

  @override
  String get stkRemember =>
      'Tes corrections seront mémorisées pour la prochaine fois.';

  @override
  String get stkStore => 'Magasin';

  @override
  String get date => 'Date';

  @override
  String get stkAddPantry => 'Ajouter aux placards';

  @override
  String get stkAddPantrySub => 'Chaque produit va à sa place';

  @override
  String stkProducts(int count) {
    return 'PRODUITS ($count)';
  }

  @override
  String stkRaw(String name) {
    return 'Ticket : \"$name\"';
  }

  @override
  String get category => 'Catégorie';

  @override
  String get stkQty => 'Qté';

  @override
  String get stkSave => 'Enregistrer le ticket';

  @override
  String foodCategory(String cat) {
    String _temp0 = intl.Intl.selectLogic(cat, {
      'verdura': 'Légumes',
      'fruta': 'Fruits',
      'carne': 'Viande',
      'pescado': 'Poisson',
      'lacteos': 'Produits laitiers',
      'preparados': 'Plats préparés',
      'panaderia': 'Boulangerie',
      'cereales': 'Pâtes, riz et légumineuses',
      'conservas': 'Conserves',
      'congelados': 'Surgelés',
      'dulces': 'Sucreries et snacks',
      'bebidas': 'Boissons',
      'especias': 'Épices et condiments',
      'higiene': 'Hygiène',
      'limpieza': 'Ménage',
      'hogar': 'Maison',
      'other': 'Autres',
    });
    return '$_temp0';
  }

  @override
  String get cookMode => 'Mode cuisine';

  @override
  String get bpMeanwhile => 'Pendant ce temps';

  @override
  String bpTapers(String title) {
    return 'Boîtes · $title';
  }

  @override
  String get bpBatchCook => 'Cuisine en lot';

  @override
  String get bpStart => 'Commencer pas à pas';

  @override
  String bpHeroTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recettes en une fois',
      one: '1 recette en une fois',
    );
    return '$_temp0';
  }

  @override
  String bpSteps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count étapes',
      one: '1 étape',
    );
    return '$_temp0';
  }

  @override
  String get bpStepsTitle => 'Le déroulé';

  @override
  String get bpCooking => 'Ce que tu vas cuisiner';

  @override
  String get cmTimer => 'Minuteur';

  @override
  String cmIngredientsReady(int done, int total) {
    return '$done sur $total prêts';
  }

  @override
  String get bpEmpty => 'Rien à cuisiner pour l\'instant';

  @override
  String get bpEmptySub =>
      'Quand tu auras des recettes planifiées, je te préparerai ici un plan pour tout faire d\'un coup.';

  @override
  String get bpNeed => 'Ce qu\'il te faut';

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String get ready => 'Prêt';

  @override
  String get pause => 'Pause';

  @override
  String get start => 'Démarrer';

  @override
  String get reset => 'Réinitialiser';

  @override
  String cmStep(int n) {
    return 'Étape $n';
  }

  @override
  String get cmTime => 'Temps écoulé';

  @override
  String get cmSeeStep => 'Voir l\'étape';

  @override
  String get ok => 'OK';

  @override
  String get cmMicPermission =>
      'Pour utiliser la voix, autorise le micro dans Réglages.';

  @override
  String get ingredients => 'Ingrédients';

  @override
  String get cmExit => 'Quitter le mode cuisine';

  @override
  String get cmHandsFreeOff => 'Désactiver mains libres';

  @override
  String get cmHandsFree => 'Mains libres';

  @override
  String get cmVoiceHint =>
      'Dis « siguiente », « anterior », « repite » ou « temporizador » (voix en espagnol pour l\'instant)';

  @override
  String get cmStop => 'Arrêter';

  @override
  String cmStepOf(int n, int total) {
    return 'ÉTAPE $n SUR $total';
  }

  @override
  String get cmTimerRunning => 'Minuteur en cours';

  @override
  String get cmThen => 'Ensuite';

  @override
  String get cmNextStep => 'Étape suivante';

  @override
  String get shopSugDue => 'À racheter';

  @override
  String get shopSugOut => 'Manque à la maison';

  @override
  String get shopOutAtHome => 'Épuisé à la maison';

  @override
  String get shopGridView => 'Vue en grille';

  @override
  String get shopGridHint => 'Grandes photos, deux par ligne';

  @override
  String get shopShowSuggestions => 'Afficher les suggestions';

  @override
  String get shopSuggestionsHint =>
      'Ce qu\'il faut racheter et ce qui manque à la maison';

  @override
  String get shopShowPrices => 'Afficher les prix';

  @override
  String shopEveryDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Tous les $n jours',
      one: 'Chaque jour',
    );
    return '$_temp0';
  }

  @override
  String get slNewList => 'Nouvelle liste';

  @override
  String get slMyLists => 'Mes listes';

  @override
  String get slActive => 'Active';

  @override
  String get slNewCat => 'Nouvelle catégorie';

  @override
  String get slRenameCat => 'Renommer la catégorie';

  @override
  String get slCategories => 'Catégories';

  @override
  String get slAddCat => 'Ajouter une catégorie';

  @override
  String get slNoCats =>
      'Pas encore de catégories. Ajoute la première avec le bouton ci-dessous.';

  @override
  String get rename => 'Renommer';

  @override
  String ppDayMeals(String day, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repas',
      one: '1 repas',
    );
    return '$day, $_temp0';
  }

  @override
  String ppFastTime(String time) {
    return '$time · Jeûne';
  }

  @override
  String get ppEatOut => '· Dehors';

  @override
  String mealAdd(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'breakfast': 'Ajouter le petit-déjeuner',
      'lunch': 'Ajouter le déjeuner',
      'snack': 'Ajouter le goûter',
      'dinner': 'Ajouter le dîner',
      'dessert': 'Ajouter le dessert',
      'other': 'Ajouter un repas',
    });
    return '$_temp0';
  }

  @override
  String get ppFromFreezer => 'Du congélateur';

  @override
  String ppServings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count port.',
      one: '1 portion',
    );
    return '$_temp0';
  }

  @override
  String get ppFresh => 'Tout juste fait';

  @override
  String ppFridge(String days) {
    return 'Frigo · $days';
  }

  @override
  String ppFreezer(String days) {
    return 'Congélateur · $days';
  }

  @override
  String get ppTapersAuto =>
      'Les boîtes s\'ajoutent toutes seules dans Ma cuisine';

  @override
  String drGoal(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'lose': 'Perdre du gras',
      'gain': 'Prendre du muscle',
      'protein': 'Riche en protéines',
      'other': 'Maintenir',
    });
    return '$_temp0';
  }

  @override
  String drDiet(String diet) {
    String _temp0 = intl.Intl.selectLogic(diet, {
      'veg': 'Végétarien',
      'vegan': 'Végétalien',
      'quick': 'Rapide',
      'lowcarb': 'Pauvre en glucides',
      'other': 'Sans restriction',
    });
    return '$_temp0';
  }

  @override
  String drFreeOf(String allergen) {
    String _temp0 = intl.Intl.selectLogic(allergen, {
      'gluten': 'Sans gluten (cœliaquie)',
      'lactosa': 'Sans lactose',
      'huevo': 'Sans œuf',
      'marisco': 'Sans fruits de mer',
      'soja': 'Sans soja',
      'other': 'Sans fruits à coque',
    });
    return '$_temp0';
  }

  @override
  String get drAnyType => 'Peu importe';

  @override
  String get drNoIdeas => 'Aucune idée reçue';

  @override
  String get drSaved => 'Enregistrée dans tes recettes';

  @override
  String get drSearchSuper => 'Chercher un supermarché...';

  @override
  String get drNoSuper => 'Nous n\'avons pas trouvé ce supermarché.';

  @override
  String get drTitlePantry => 'Que cuisiner avec ça ?';

  @override
  String get drTitle => 'Idées personnalisées';

  @override
  String get drNewIdeas => 'Nouvelles idées';

  @override
  String get drWithPantry => 'Avec ce que j\'ai';

  @override
  String get drPantryLoading => 'On regarde ton garde-manger…';

  @override
  String get drPantryEmpty =>
      'Ton garde-manger est vide : ajoute ce que tu as chez toi pour recevoir des idées.';

  @override
  String drPantryUse(int count) {
    return 'Nous utiliserons $count aliments de ton garde-manger, en commençant par ce qui périme en premier.';
  }

  @override
  String get drCraving => 'De quoi as-tu envie ?';

  @override
  String get drSupers => 'Supermarchés';

  @override
  String get drSupersHint =>
      'Facultatif. Si tu n\'en choisis aucun, les recettes conviennent à tout supermarché.';

  @override
  String get drGoalTitle => 'Objectif';

  @override
  String get drDietTitle => 'Régime';

  @override
  String drDietLocked(String diet) {
    return 'Nous utilisons le régime de ton profil : $diet';
  }

  @override
  String get drAllergyTitle => 'Intolérances et allergies';

  @override
  String get drAllergyHint => 'Ils n\'apparaîtront jamais dans les recettes.';

  @override
  String get drAppliances => 'Appareils';

  @override
  String get drMaxCost => 'Coût maximum par portion';

  @override
  String get drMaxCostHint => 'Facultatif, ex. 2,50';

  @override
  String get drSearching => 'Recherche d\'idées…';

  @override
  String get drSeeIdeas => 'Voir les idées';

  @override
  String drAddedToShop(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count produits ajoutés aux courses',
      one: 'Ajouté à la liste de courses',
    );
    return '$_temp0';
  }

  @override
  String get drAddFail =>
      'Impossible d\'ajouter aux courses. Vérifie la connexion et réessaie.';

  @override
  String drProteinShort(String grams) {
    return 'P : $grams g';
  }

  @override
  String get drCostTip =>
      'Indicatif : prix de tes tickets ou, sinon, prix moyens en supermarché.';

  @override
  String drPerServing(String price) {
    return '≈ $price/portion';
  }

  @override
  String get drHave => 'Tu as :';

  @override
  String get drMissing => 'Il te manque :';

  @override
  String get drAddedShort => 'Ajouté aux courses';

  @override
  String get drAddMissing => 'Ajouter ce qui manque';

  @override
  String get drSavedShort => 'Enregistrée';

  @override
  String get drSaveToRecipes => 'Enregistrer dans mes recettes';

  @override
  String taskKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'bano': 'Salle de bain',
      'ropa': 'Linge',
      'compra': 'Courses',
      'basura': 'Poubelles',
      'platos': 'Vaisselle',
      'limpieza': 'Ménage',
      'plantas': 'Plantes',
      'cama': 'Lit',
      'mascota': 'Animal',
      'cocinar': 'Cuisine',
      'pagos': 'Paiements',
      'other': 'Tâche',
    });
    return '$_temp0';
  }

  @override
  String taskPreset(String preset) {
    String _temp0 = intl.Intl.selectLogic(preset, {
      'dishes': 'Faire la vaisselle',
      'vacuum': 'Passer l\'aspirateur',
      'bathroom': 'Nettoyer la salle de bain',
      'laundry': 'Lancer une lessive',
      'trash': 'Sortir les poubelles',
      'shopping': 'Faire les courses',
      'plants': 'Arroser les plantes',
      'other': 'Changer les draps',
    });
    return '$_temp0';
  }

  @override
  String get recQuick => 'Rapides';

  @override
  String get recLight => 'Légères';

  @override
  String get recFreezer => 'Congelables';

  @override
  String get recSearchHint => 'Cherche par nom ou ingrédient';

  @override
  String get recSort => 'Trier';

  @override
  String get recSortRecent => 'Plus récentes';

  @override
  String get recSortAz => 'De A à Z';

  @override
  String get recSortFastest => 'Plus rapides d\'abord';

  @override
  String get recSortLightest => 'Moins de calories d\'abord';

  @override
  String get recClearFilters => 'Effacer les filtres';

  @override
  String get recMore => 'Plus';

  @override
  String get recLess => 'Moins';

  @override
  String get planBusyAware => 'Organiser selon mon agenda';

  @override
  String get planBusyAwareHint =>
      'Les jours chargés, recettes rapides ou du congélateur ; on cuisine le jour le plus libre et les tâches sans heure vont dans un créneau libre. S\'applique en créant le plan.';

  @override
  String get planBusyDay => 'Journée chargée';

  @override
  String get nutAlternate => 'Un jour sur deux';

  @override
  String get nutAlternateSub =>
      'Je cuisine plus et je mange les restes le lendemain';

  @override
  String get planHowYouCook => 'Comment tu cuisines';

  @override
  String get planModeDaily => 'Chaque jour';

  @override
  String get planModeAlternate => 'Tous les 2 jours';

  @override
  String get planModeBatch => 'En lot';

  @override
  String get planLeftoverMeals => 'Ce qui se répète le lendemain';

  @override
  String get planLeftover => 'Restes d\'hier';

  @override
  String get planOldTapersTitle => 'Boîtes de l\'ancien planning';

  @override
  String planOldTapersBody(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count boîtes',
      one: '1 boîte',
    );
    return 'Il reste $_temp0 au frigo que le nouveau planning n\'utilise plus : $names. Les retirer de Ma cuisine ?';
  }

  @override
  String get planOldTapersKeep => 'Les garder';

  @override
  String get hhCreateError => 'Impossible de créer le foyer';

  @override
  String get hhJoinTitle => 'Rejoindre un foyer';

  @override
  String get hhInviteCode => 'Code d\'invitation';

  @override
  String get hhJoin => 'Rejoindre';

  @override
  String get hhCodeFormat => 'Le code a 8 lettres et chiffres';

  @override
  String get hhCodeInvalid => 'Code invalide ou expiré';

  @override
  String get hhCodeCreateError => 'Impossible de créer le code';

  @override
  String get hhThisMember => 'ce membre';

  @override
  String hhRemoveMemberTitle(String name) {
    return 'Retirer $name du foyer ?';
  }

  @override
  String get hhRemoveMemberBody =>
      'Ne verra plus les courses, le garde-manger ni le planning.';

  @override
  String get hhRemoveError => 'Impossible de retirer';

  @override
  String get hhAddGuestTitle => 'Ajouter une personne sans compte';

  @override
  String get hhAddGuestBody =>
      'Pour quelqu\'un de la maison qui n\'utilise pas l\'appli. Tu pourras lui attribuer des tâches et noter celles qu\'il fait.';

  @override
  String get hhAddError => 'Impossible d\'ajouter';

  @override
  String hhRemoveGuestTitle(String name) {
    return 'Retirer $name ?';
  }

  @override
  String get hhRemoveGuestBody =>
      'Ses points seront supprimés et ses tâches ne seront plus attribuées.';

  @override
  String get hhLeaveTitle => 'Quitter le foyer ?';

  @override
  String get hhLeaveBody =>
      'Tu ne verras plus ses données. Pour revenir, il te faudra un nouveau code.';

  @override
  String get hhLeave => 'Quitter';

  @override
  String get hhLeaveError => 'Impossible de quitter le foyer';

  @override
  String get hhNameTitle => 'Nom du foyer';

  @override
  String get hhRenameError => 'Impossible de renommer';

  @override
  String get hhDeleteAccountTitle => 'Supprimer ton compte ?';

  @override
  String get hhDeleteAccountBody =>
      'Ton compte et tes données seront supprimés. Si tu es seul·e dans le foyer, le foyer aussi. C\'est irréversible.';

  @override
  String get hhDeleteConfirm => 'Supprimer';

  @override
  String get hhDeleteAccountError => 'Impossible de supprimer le compte';

  @override
  String get hhDeleteAccount => 'Supprimer mon compte';

  @override
  String get hhMyHome => 'Mon foyer';

  @override
  String get hhSignOut => 'Se déconnecter';

  @override
  String get hhNoHome => 'Tu n\'appartiens encore à aucun foyer.';

  @override
  String get hhCreateHome => 'Créer un nouveau foyer';

  @override
  String get hhJoinExisting => 'Rejoindre un foyer existant';

  @override
  String get hhRename => 'Renommer le foyer';

  @override
  String hhPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Un foyer de $count personnes.',
      one: 'Ton foyer, pour toi seul·e pour l\'instant.',
    );
    return '$_temp0';
  }

  @override
  String hhMembers(int count) {
    return 'Membres ($count)';
  }

  @override
  String get hhAdmin => 'Admin';

  @override
  String get hhRemoveFromHome => 'Retirer du foyer';

  @override
  String get hhYou => 'Toi';

  @override
  String get hhNoAccount => 'Sans compte';

  @override
  String get hhLeaveHome => 'Quitter le foyer';

  @override
  String get hhSettings => 'Foyer et réglages';

  @override
  String get hhAppearance => 'Apparence';

  @override
  String get hhPhoneAlerts => 'Notifications sur le téléphone';

  @override
  String get hhYourData => 'Tes données';

  @override
  String get hhYourDataSub =>
      'Graphiques des dépenses, courses, cuisine et tâches';

  @override
  String get hhExpenses => 'Dépenses et tickets';

  @override
  String get hhExpensesSub => 'Budget, tickets scannés et dépenses par mois';

  @override
  String get hhYourPlan => 'Ton forfait';

  @override
  String get hhYourPlanSub => 'Utilisations restantes ce mois-ci';

  @override
  String get hhNutrition => 'Mon profil nutritionnel';

  @override
  String get hhNutritionSub => 'Objectif calorique, préférences et assistant';

  @override
  String get hhInvite => 'Inviter quelqu\'un';

  @override
  String get hhCreateCode => 'Créer un code';

  @override
  String get hhCopy => 'Copier';

  @override
  String get hhCodeCopied => 'Code copié';

  @override
  String hhValidUntil(String date) {
    return 'Valable jusqu\'au $date';
  }

  @override
  String get hhNewCode => 'Nouveau code';

  @override
  String get hhChoose => 'Choisir';

  @override
  String get hhSupersHint =>
      'Les recettes s\'adapteront à ce que vendent tes supermarchés. Facultatif.';

  @override
  String get hhNoSuper => 'Aucun supermarché choisi.';

  @override
  String get hhCountryError => 'Impossible de changer de pays';

  @override
  String get hhWhereShop => 'Où faites-vous les courses ?';

  @override
  String get hhPickMany => 'Tu peux en choisir plusieurs. Facultatif.';

  @override
  String get hhSaveError => 'Impossible d\'enregistrer';

  @override
  String themeMode(String mode) {
    String _temp0 = intl.Intl.selectLogic(mode, {
      'claro': 'Clair',
      'oscuro': 'Sombre',
      'other': 'Système',
    });
    return '$_temp0';
  }

  @override
  String get bcNotFound =>
      'Ce code n\'est pas sur Open Food Facts. Tu peux l\'ajouter à la main.';

  @override
  String get bcTitle => 'Scanner le code';

  @override
  String get bcSearching => 'Recherche du produit…';

  @override
  String get bcNoPermission =>
      'J\'ai besoin de la caméra pour scanner le code. Tu peux l\'autoriser dans les réglages du téléphone.';

  @override
  String get bcCameraError =>
      'Impossible d\'ouvrir la caméra. Tu peux ajouter le produit à la main depuis le garde-manger.';

  @override
  String planFeature(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'scan_ticket': 'Scanner des tickets',
      'recipes': 'Idées et recettes',
      'meal_photo': 'Photo de ton repas',
      'other': 'Recettes depuis un lien',
    });
    return '$_temp0';
  }

  @override
  String puPlanName(String plan) {
    String _temp0 = intl.Intl.selectLogic(plan, {
      'pro': 'Forfait Pro',
      'other': 'Forfait gratuit',
    });
    return '$_temp0';
  }

  @override
  String get puExplain =>
      'Garde-manger, courses, tâches et planning sont illimités. Voici ce qu\'il te reste ce mois-ci ; ça se renouvelle le 1er. Si quelque chose échoue, ça ne compte pas.';

  @override
  String get puGoPro => 'Passer à Pro';

  @override
  String puLeft(int left, int limit) {
    return 'Il te reste $left sur $limit';
  }

  @override
  String get psTitle => 'Statistiques des courses';

  @override
  String get psMostBought => 'Ce que tu achètes le plus';

  @override
  String get psMostSpent => 'Là où tu dépenses le plus';

  @override
  String get psPriciest => 'Les plus chers (à l\'unité)';

  @override
  String get psHistory => 'Ton historique de courses';

  @override
  String psTotal(String amount) {
    return 'Dépenses totales enregistrées : $amount';
  }

  @override
  String get psNoPrices => 'Pas encore assez de données de prix.';

  @override
  String get psEmptyTitle => 'Pas encore de statistiques';

  @override
  String get psEmptyBody =>
      'Scanne tes tickets et tu verras ici ce que tu achètes le plus, où tu dépenses le plus et les produits les plus chers.';

  @override
  String get meals => 'Repas';

  @override
  String get mcNoHome => 'Tu n\'appartiens à aucun foyer.';

  @override
  String mcPrep(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'compra': 'Courses',
      'cocina': 'Cuisiner',
      'other': 'Sortir',
    });
    return '$_temp0';
  }

  @override
  String get mcPlanIt => 'Planifier';

  @override
  String get mcSeeInPlan => 'Voir dans le planning';

  @override
  String get mcNothing => 'Rien de prévu ce jour-là.';

  @override
  String get tasks => 'Tâches';

  @override
  String proPeriod(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'annual': 'Par an',
      'sixMonth': 'Tous les 6 mois',
      'threeMonth': 'Tous les 3 mois',
      'twoMonth': 'Tous les 2 mois',
      'monthly': 'Par mois',
      'weekly': 'Par semaine',
      'lifetime': 'À vie',
      'other': 'Pro',
    });
    return '$_temp0';
  }

  @override
  String get proAlready => 'Tu as déjà Pro';

  @override
  String get proMoreUses => 'Plus d\'utilisations chaque mois';

  @override
  String get proRestSame =>
      'Le reste ne change pas : illimité et pour tout le foyer.';

  @override
  String get proFree => 'Gratuit';

  @override
  String get proSoon => 'Pro sera bientôt disponible.';

  @override
  String get proNothingToRestore => 'Aucun achat à restaurer.';

  @override
  String get proRestore => 'Restaurer les achats';

  @override
  String get proRenews =>
      'Renouvellement automatique. Annulable à tout moment depuis la boutique.';

  @override
  String get proTerms => 'Conditions';

  @override
  String get proPrivacy => 'Confidentialité';

  @override
  String get aiSaveError => 'Erreur d\'enregistrement';

  @override
  String get aiStoreProduct => 'Produit du supermarché';

  @override
  String get aiRemoveProduct => 'Retirer le produit';

  @override
  String get aiEditTitle => 'Modifier le produit';

  @override
  String get aiAddTitle => 'Ajouter au garde-manger';

  @override
  String get aiChangePhoto => 'Changer la photo';

  @override
  String get aiProductType => 'Type de produit';

  @override
  String get aiWhatIsIt => 'Qu\'est-ce que c\'est ?';

  @override
  String aiDishKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'ingredient': 'Ingrédient à cuisiner',
      'base': 'Base déjà préparée',
      'other': 'Plat prêt à manger',
    });
    return '$_temp0';
  }

  @override
  String get aiSearchStore => 'Chercher au supermarché';

  @override
  String get aiSearchStoreLong =>
      'Trouver le produit du supermarché avec photo';

  @override
  String get aiQuickAdd => 'Ajoute les habituels en un geste';

  @override
  String get aiLocation => 'Emplacement';

  @override
  String get aiCategory => 'Catégorie';

  @override
  String get aiQuantity => 'Quantité';

  @override
  String get aiUnit => 'Unité';

  @override
  String get aiServings => 'Portions (facultatif)';

  @override
  String get aiFrozenDate => 'Date de congélation';

  @override
  String get aiFrozenOn => 'Congelé le (facultatif)';

  @override
  String get aiWillEstimate =>
      'Nous calculerons combien de temps il se conserve au congélateur.';

  @override
  String aiBestBefore(String date) {
    return 'À consommer de préférence avant le $date (env.).';
  }

  @override
  String get aiExpiryDate => 'Date d\'expiration';

  @override
  String get aiExpires => 'Expire le';

  @override
  String get aiExpiresApprox => 'Expire le (env.)';

  @override
  String get aiNotToList => 'Ne pas ajouter aux courses';

  @override
  String get aiStaplesSub => 'Basiques que tu as toujours';

  @override
  String get aiSaveChanges => 'Enregistrer';

  @override
  String get aiSaveNew => 'Enregistrer au garde-manger';

  @override
  String get kzMyKitchen => 'Ma cuisine';

  @override
  String get kzAllGood => 'À jour';

  @override
  String get phStore => 'Choisir un produit du supermarché';

  @override
  String get phCamera => 'Prendre une photo';

  @override
  String get phGallery => 'Choisir dans la galerie';

  @override
  String get phError => 'Impossible de changer la photo';

  @override
  String get psStoreTitle => 'Produits du supermarché';

  @override
  String psStoreTitleOf(String store) {
    return 'Produits de $store';
  }

  @override
  String get psHint => 'Lait, yaourt grec, lessive…';

  @override
  String get psTypeHint => 'Écris un produit et touche chercher.';

  @override
  String get psThrottled =>
      'Trop de recherches à la suite. Réessaie dans une minute.';

  @override
  String get psOffline =>
      'Pas de connexion internet. Tu peux quand même l\'ajouter.';

  @override
  String get psDown =>
      'La recherche de produits ne répond pas. Réessaie plus tard ou ajoute-le quand même.';

  @override
  String get psNotInStore =>
      'Pas au supermarché. Tu peux quand même l\'ajouter.';

  @override
  String psNoResultsIn(String store) {
    return 'Aucun résultat chez $store. Ceux-ci viennent d\'autres supermarchés.';
  }

  @override
  String psNotYet(String store) {
    return 'Nous n\'avons pas encore les produits de $store. Ceux-ci viennent d\'autres supermarchés.';
  }

  @override
  String get psOffData => 'Données d\'Open Food Facts.';

  @override
  String psAddAsIs(String q) {
    return 'Ajouter « $q » sans choisir de produit';
  }

  @override
  String get offlineExplain =>
      'Tu peux continuer à utiliser la liste de courses et le garde-manger : ce que tu notes est enregistré sur le téléphone et envoyé au retour de la connexion. Le reste se mettra à jour à ce moment-là.';

  @override
  String get offlineNow => 'Hors connexion pour le moment';

  @override
  String streakMilestone(int days) {
    return '$days jours d\'affilée !';
  }

  @override
  String streakMilestoneSub(int next) {
    return 'Étape atteinte. Prochaine : $next jours.';
  }

  @override
  String streakDoneSub(int next) {
    return 'Aujourd\'hui compte déjà. Prochaine étape : $next jours.';
  }

  @override
  String get streakKeepSub =>
      'Coche une tâche ou note un repas pour continuer.';

  @override
  String get streakStart => 'Commence ta série';

  @override
  String get streakStartSub => 'Coche une tâche ou note un repas aujourd\'hui.';

  @override
  String streakDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours d\'affilée',
      one: '1 jour d\'affilée',
    );
    return '$_temp0';
  }

  @override
  String get syncSaved =>
      'Enregistré. Synchronisation au retour de la connexion.';

  @override
  String get fzTitle => 'Mettre des portions au congélateur ?';

  @override
  String get fzSave => 'Mettre au congélateur';

  @override
  String get notNow => 'Pas maintenant';

  @override
  String get fastIn => 'En jeûne';

  @override
  String get fastCanEat => 'Tu peux manger';

  @override
  String fastLeft(String left, String time) {
    return 'Encore $left · Tu manges à $time';
  }

  @override
  String fastUntil(String time) {
    return 'Jusqu\'à $time';
  }

  @override
  String get shWeekReady =>
      'Ta semaine est prête : déjeuners, dîners et liste de courses';

  @override
  String get comingSoon => 'BIENTÔT';

  @override
  String psSummary(int distinct, int lines) {
    return '$distinct produits différents · $lines achats';
  }

  @override
  String get errNoConnection =>
      'Il semble ne pas y avoir de connexion. Réessaie dans un instant.';

  @override
  String get errBadLogin => 'L\'e-mail ou le mot de passe est incorrect.';

  @override
  String get errConfirmEmail =>
      'Confirme ton e-mail (regarde ta boîte de réception) et réessaie.';

  @override
  String get errSession => 'Ta session a expiré. Reconnecte-toi.';

  @override
  String get errPermission =>
      'Tu n\'as pas la permission de faire ça dans ce foyer.';

  @override
  String get errRateLimit => 'Trop de demandes à la suite. Réessaie plus tard.';

  @override
  String get errExists => 'Ça existe déjà.';

  @override
  String get errUpload =>
      'Impossible d\'envoyer l\'image. Essaie une plus petite.';

  @override
  String get errGeneric => 'Quelque chose n\'a pas marché. Réessaie.';

  @override
  String get errBadQuantity => 'Saisis une quantité valide.';

  @override
  String get errRecipeComplete => 'Impossible de compléter la recette';

  @override
  String get errRecipeImport =>
      'Impossible d\'importer la recette depuis ce lien';

  @override
  String get someone => 'Quelqu\'un';

  @override
  String get reward => 'Récompense';

  @override
  String remKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'tasks': 'Tâches avec horaire',
      'expiry': 'Produits qui expirent',
      'other': 'Série du foyer',
    });
    return '$_temp0';
  }

  @override
  String remTaskOne(String title) {
    return 'C\'est l\'heure : $title';
  }

  @override
  String remTaskMany(int count) {
    return '$count tâches à faire';
  }

  @override
  String get remTaskOneBody =>
      'Quand tu as fini, coche-la pour gagner des points.';

  @override
  String remTaskManyBody(String list) {
    return '$list. Coche-les une fois faites pour gagner des points.';
  }

  @override
  String remExpiryOne(String name) {
    return 'Expire demain : $name';
  }

  @override
  String remExpiryMany(int count) {
    return '$count produits expirent demain';
  }

  @override
  String get remExpiryBody =>
      'Cuisine-le aujourd\'hui ou congèle ce que tu n\'utiliseras pas.';

  @override
  String remStreakMilestone(int days) {
    return 'Aujourd\'hui tu atteins $days jours';
  }

  @override
  String get remStreakMilestoneBody =>
      'Coche une tâche ou note un repas pour fêter ça.';

  @override
  String remStreakDays(int days) {
    return '$days jours de foyer à jour';
  }

  @override
  String get remStreakDaysBody =>
      'Coche une tâche ou note un repas pour garder ta série.';

  @override
  String get remHowIsHome => 'Comment va la maison aujourd\'hui ?';

  @override
  String get remHowIsHomeBody =>
      'Un seul geste suffit pour ajouter un jour à ta série.';

  @override
  String get remStreakAlive => 'Ta série est toujours en vie';

  @override
  String get remStreakAliveBody =>
      'Note ce que tu as mangé ou coche une tâche avant de dormir.';

  @override
  String listAnd(String items, String last) {
    return '$items et $last';
  }

  @override
  String listMore(String items, int count) {
    return '$items et $count de plus';
  }

  @override
  String get planMovedLater => 'Je le garde pour plus tard';

  @override
  String get planTheDish => 'le plat';

  @override
  String planMovedTo(String recipe, String day) {
    return '$recipe déplacé à $day';
  }

  @override
  String weekday(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '1': 'lundi',
      '2': 'mardi',
      '3': 'mercredi',
      '4': 'jeudi',
      '5': 'vendredi',
      '6': 'samedi',
      'other': 'dimanche',
    });
    return '$_temp0';
  }

  @override
  String weekdayShortName(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '1': 'lun',
      '2': 'mar',
      '3': 'mer',
      '4': 'jeu',
      '5': 'ven',
      '6': 'sam',
      'other': 'dim',
    });
    return '$_temp0';
  }

  @override
  String get prepShopTitle => 'Faire les courses';

  @override
  String prepShopLine(String day) {
    return 'Pour cuisiner en lot $day';
  }

  @override
  String get prepCookTitle => 'Cuisiner en lot';

  @override
  String get prepAutoTapers =>
      'Les boîtes sont ajoutées toutes seules à Ma cuisine';

  @override
  String get prepThawTitle => 'Du congélateur au frigo';

  @override
  String prepThawLine(String recipe, int count, String day) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count boîtes',
      one: '1 boîte',
    );
    return '$recipe : $_temp0 pour $day';
  }

  @override
  String get taperFresh => 'tout juste préparé';

  @override
  String taperFridge(String days) {
    return 'frigo pour $days';
  }

  @override
  String taperFreezer(String days) {
    return 'congélateur pour $days';
  }

  @override
  String stepPrepare(String recipe) {
    return 'Préparer $recipe';
  }

  @override
  String stepUseAppliance(String appliance, String recipes) {
    String _temp0 = intl.Intl.selectLogic(appliance, {
      'oven': 'Allume le four',
      'stovetop': 'Allume les feux',
      'pot': 'Allume la cocotte',
      'airfryer': 'Allume la friteuse à air',
      'microwave': 'Allume le micro-ondes',
      'blender': 'Allume le mixeur',
      'other': 'Utilise $appliance',
    });
    return '$_temp0 pour $recipes';
  }

  @override
  String comidasTab(String tab) {
    String _temp0 = intl.Intl.selectLogic(tab, {
      'plan': 'Planning',
      'recipes': 'Recettes',
      'other': 'Journal',
    });
    return '$_temp0';
  }

  @override
  String bannerExpiring(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Expire bientôt',
    );
    return '$_temp0';
  }

  @override
  String get bannerIdeas => 'Idées';

  @override
  String get bannerHide => 'Masquer jusqu\'à demain';

  @override
  String get loading => 'Chargement';

  @override
  String get mascot => 'Mascotte';

  @override
  String voiceStep(int n) {
    return 'Étape $n.';
  }

  @override
  String voiceTime(String what) {
    return 'Temps écoulé. $what.';
  }

  @override
  String get voiceLastStep => 'C\'est la dernière étape.';

  @override
  String get voiceNoTime => 'Cette étape n\'a pas de durée.';

  @override
  String voiceTimer(int minutes) {
    return 'Minuteur de $minutes minutes.';
  }

  @override
  String get voiceNoTimers => 'Aucun minuteur.';

  @override
  String get voiceStopped => 'Arrêté.';

  @override
  String get voiceNoIngredients => 'Pas de liste d\'ingrédients.';

  @override
  String unitOne(String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'unidad': 'unité',
      'diente': 'gousse',
      'loncha': 'tranche',
      'lata': 'boîte',
      'bote': 'pot',
      'bolsa': 'sachet',
      'comida': 'repas',
      'cucharada': 'c. à soupe',
      'cucharadita': 'c. à café',
      'other': '$unit',
    });
    return '$_temp0';
  }

  @override
  String unitMany(String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'unidad': 'unités',
      'diente': 'gousses',
      'loncha': 'tranches',
      'lata': 'boîtes',
      'bote': 'pots',
      'bolsa': 'sachets',
      'comida': 'repas',
      'cucharada': 'c. à soupe',
      'cucharadita': 'c. à café',
      'other': '$unit',
    });
    return '$_temp0';
  }

  @override
  String unitShort(String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'unidad': 'u.',
      'cucharada': 'c. s.',
      'cucharadita': 'c. c.',
      'other': '$unit',
    });
    return '$_temp0';
  }

  @override
  String unitToTaste(String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'a_ojo': 'à l\'œil',
      'other': 'selon le goût',
    });
    return '$_temp0';
  }

  @override
  String aiItemType(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'hogar': 'Maison/Ménage',
      'other': 'Alimentation',
    });
    return '$_temp0';
  }

  @override
  String aiKindShort(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'prep': 'Préparé',
      'dish': 'Plat prêt',
      'other': 'Ingrédient',
    });
    return '$_temp0';
  }
}
