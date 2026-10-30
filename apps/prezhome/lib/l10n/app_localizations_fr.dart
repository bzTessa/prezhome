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
}
