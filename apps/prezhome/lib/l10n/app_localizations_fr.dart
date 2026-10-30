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
}
