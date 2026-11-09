// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String tabLabel(String tab) {
    String _temp0 = intl.Intl.selectLogic(tab, {
      'inicio': 'Today',
      'comidas': 'Meals',
      'compra': 'Shopping',
      'despensa': 'Pantry',
      'tareas': 'Chores',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get country => 'Country';

  @override
  String get countryHint => 'Currency, supermarkets and reference prices';

  @override
  String get continueLabel => 'Continue';

  @override
  String get back => 'Back';

  @override
  String get oneMoment => 'One moment…';

  @override
  String get retry => 'Try again';

  @override
  String get loginAccountCreated => 'Account created. Welcome to PrezHome';

  @override
  String get loginConfirmEmailSent =>
      'We\'ve sent you an email to confirm your account. Open it on this phone and you\'ll be signed in.';

  @override
  String get loginAuthError => 'Sign-in error';

  @override
  String loginProviderError(String provider) {
    return 'Couldn\'t sign in with $provider';
  }

  @override
  String get loginResetNeedsEmail =>
      'Enter your email first and I\'ll send you a link to reset your password.';

  @override
  String get loginResetSent =>
      'I\'ve sent you an email to reset your password.';

  @override
  String get loginResetError => 'Couldn\'t send the email';

  @override
  String get loginWelcomeBack => 'Welcome back';

  @override
  String get loginCreateAccount => 'Create your account';

  @override
  String get loginTagline => 'PrezHome, your home organised';

  @override
  String loginContinueWith(String provider) {
    return 'Continue with $provider';
  }

  @override
  String get loginOrEmail => 'or with your email';

  @override
  String get loginEmail => 'Email';

  @override
  String get loginEmailInvalid => 'Enter a valid email';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginShowPassword => 'Show password';

  @override
  String get loginHidePassword => 'Hide password';

  @override
  String get loginPasswordShort => 'At least 6 characters';

  @override
  String get loginForgot => 'Forgot your password?';

  @override
  String get loginSignIn => 'Sign in';

  @override
  String get loginSignUp => 'Sign up';

  @override
  String get loginNoAccount => 'No account? Sign up';

  @override
  String get loginHaveAccount => 'Already have an account? Sign in';

  @override
  String get homeCodeFormat =>
      'The code has 8 letters and numbers (for example ABCD-EFGH).';

  @override
  String get homeSetupError => 'Couldn\'t set up the home';

  @override
  String get homeLastStep => 'Last step: your home';

  @override
  String get homeCreateHint =>
      'Create it now and, whenever you like, invite the people you live with from Today.';

  @override
  String get homeCreate => 'Create my home';

  @override
  String get homeInvited => 'I\'ve been invited to a home';

  @override
  String get homeInviteCode => 'Invitation code';

  @override
  String get homeJoin => 'Join a home';

  @override
  String get sessionLoadError => 'Couldn\'t load your profile.';

  @override
  String get onbSectionHome => 'Your home';

  @override
  String get onbPeopleTitle => 'How many people live with you?';

  @override
  String get onbPeopleHint =>
      'To work out portions, shopping and how chores are shared.';

  @override
  String get onbSectionGoals => 'What keeps you busy';

  @override
  String get onbGoalsTitle => 'What would you like off your mind?';

  @override
  String get onbGoalsHint =>
      'Pick as many as you like. The rest will stay hidden.';

  @override
  String get onbPickOne => 'Pick at least one';

  @override
  String onbContinueCount(int count) {
    return 'Continue ($count)';
  }

  @override
  String get onbSectionKitchen => 'In the kitchen';

  @override
  String get onbCookingTitle => 'How do you cook?';

  @override
  String get onbCookingHint =>
      'So we know whether to plan batches and the freezer.';

  @override
  String get onbSectionShopping => 'Shopping';

  @override
  String get onbShopTitle => 'Where do you shop?';

  @override
  String get onbShopHint =>
      'The first one will be your main supermarket: we will look for your shopping list products there.';

  @override
  String get onbSkipSeeHome => 'Skip and see my home';

  @override
  String get onbSeeHome => 'See my home';

  @override
  String get onbSlogan => 'A tidy home, a calm mind.';

  @override
  String get onbStart => 'Get started';

  @override
  String get onbHaveAccount => 'I already have an account';

  @override
  String get onbOneLess => 'One fewer';

  @override
  String get onbOneMore => 'One more';

  @override
  String onbPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: 'Just me',
    );
    return '$_temp0';
  }

  @override
  String get onbProfileBadge => 'Your home profile';

  @override
  String onbProfileName(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'solo': 'Solo',
      'duo': 'The Duo',
      'tribu': 'The Tribe',
      'other': 'The Family',
    });
    return '$_temp0';
  }

  @override
  String onbProfileDescription(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'solo':
          'The whole home depends on you. PrezHome remembers what you have, what\'s about to expire and what\'s due, so you don\'t have to.',
      'duo':
          'Two people, one home. PrezHome shares the load where you can both see it, so nobody keeps track of everything in their head.',
      'other':
          'Lots of mouths and lots going on. PrezHome plans meals, shopping and chores for everyone, and reminds each person of their part.',
    });
    return '$_temp0';
  }

  @override
  String get onbLoadToday => 'Mental load today';

  @override
  String get onbLoadWithApp => 'With PrezHome';

  @override
  String onbLoad(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'high': 'heavy',
      'medium': 'medium',
      'other': 'light',
    });
    return '$_temp0';
  }

  @override
  String get onbCreateAccount => 'Create my account';

  @override
  String onbFeature(String f) {
    String _temp0 = intl.Intl.selectLogic(f, {
      'compra': 'Shopping list',
      'comidas': 'What we eat',
      'despensa': 'Pantry and expiry dates',
      'tareas': 'Household chores',
      'other': 'Home spending',
    });
    return '$_temp0';
  }

  @override
  String goalLabel(String g) {
    String _temp0 = intl.Intl.selectLogic(g, {
      'comidas': 'What we eat',
      'compra': 'Shopping',
      'despensa': 'What\'s at home',
      'tareas': 'Household chores',
      'lote': 'Batch cooking',
      'other': 'Home spending',
    });
    return '$_temp0';
  }

  @override
  String goalHint(String g) {
    String _temp0 = intl.Intl.selectLogic(g, {
      'comidas': 'Meal plan and recipes',
      'compra': 'A list that writes itself',
      'despensa': 'Pantry, fridge and expiry dates',
      'tareas': 'Fair sharing and reminders',
      'lote': 'Containers and freezer organised',
      'other': 'Budget and receipts',
    });
    return '$_temp0';
  }

  @override
  String cookingLabel(String c) {
    String _temp0 = intl.Intl.selectLogic(c, {
      'diario': 'Every day',
      'lote': 'In batches',
      'mixto': 'A bit of both',
      'other': 'Hardly ever',
    });
    return '$_temp0';
  }

  @override
  String cookingHint(String c) {
    String _temp0 = intl.Intl.selectLogic(c, {
      'diario': 'I cook as I go',
      'lote': 'I prep several days at once',
      'mixto': 'Some days in batches',
      'other': 'I eat out or grab something quick',
    });
    return '$_temp0';
  }

  @override
  String homeGreeting(String part) {
    String _temp0 = intl.Intl.selectLogic(part, {
      'morning': 'Good morning',
      'afternoon': 'Good afternoon',
      'other': 'Good evening',
    });
    return '$_temp0';
  }

  @override
  String get homeCustomize => 'Customise Today';

  @override
  String get homeYourData => 'Your data';

  @override
  String get homeYourHome => 'Your home';

  @override
  String homeTodayTag(String meal) {
    return 'Today · $meal';
  }

  @override
  String mealType(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'breakfast': 'Breakfast',
      'lunch': 'Lunch',
      'snack': 'Snack',
      'dinner': 'Dinner',
      'dessert': 'Dessert',
      'drink': 'Drink',
      'other': 'Meal',
    });
    return '$_temp0';
  }

  @override
  String get homeEatingOut => 'Eating out';

  @override
  String get homeWhatToEat => 'What are we eating today?';

  @override
  String get homeNothingPlanned => 'Nothing planned for today yet.';

  @override
  String get homePlan => 'Plan';

  @override
  String get homeWithWhatIHave => 'With what I have';

  @override
  String get homeExpiring => 'Expiring';

  @override
  String homeTasksToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Chores today',
      one: 'Chore today',
    );
    return '$_temp0';
  }

  @override
  String get homeInShopping => 'On the list';

  @override
  String get homeShortcuts => 'Shortcuts';

  @override
  String get homeForToday => 'For today';

  @override
  String get homeSeeAll => 'See all';

  @override
  String homePoints(int points) {
    return '$points pts';
  }

  @override
  String homePointsSnack(int points) {
    return '+$points points';
  }

  @override
  String get homeToday => 'Today';

  @override
  String get homeTomorrow => 'Tomorrow';

  @override
  String get homeCaloriesTitle => 'Work out your calorie goal';

  @override
  String get homeCaloriesHint =>
      'Answer a few quick questions and I\'ll tailor PrezHome to you.';

  @override
  String homeOf(String total) {
    return 'of $total';
  }

  @override
  String get homeCaloriesToday => 'Today\'s calories';

  @override
  String homeKcal(int kcal) {
    return '$kcal kcal';
  }

  @override
  String homeKcalLeft(int kcal) {
    return '$kcal kcal left';
  }

  @override
  String homeKcalOver(int kcal) {
    return '$kcal kcal over';
  }

  @override
  String get homeMonthSpend => 'This month\'s spending';

  @override
  String homeMoneyLeft(String amount) {
    return '$amount left';
  }

  @override
  String homeMoneyOver(String amount) {
    return '$amount over budget';
  }

  @override
  String get save => 'Save';

  @override
  String get homeCardsSection => 'Cards (drag to reorder)';

  @override
  String get homeQuickSection => 'Quick actions';

  @override
  String get homeQuickHint =>
      'Choose the shortcuts you\'ll see at the top of Today.';

  @override
  String dashCard(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'meals': 'Today\'s meals',
      'calories': 'Today\'s calories',
      'tasks': 'Chores',
      'other': 'This month\'s spending',
    });
    return '$_temp0';
  }

  @override
  String quickAction(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'add_inventory': 'Add to pantry',
      'scan_ticket': 'Scan receipt',
      'shopping': 'Shopping list',
      'add_recipe': 'New recipe',
      'meal_plan': 'Weekly plan',
      'other': 'Calorie diary',
    });
    return '$_temp0';
  }

  @override
  String get shopPickStore => 'Choose supermarket';

  @override
  String get shopAddFromPlan => 'Add this week\'s plan';

  @override
  String get shopListOptions => 'List options';

  @override
  String get shopAllInCart => 'Everything\'s in the cart';

  @override
  String shopPending(int pending, int done) {
    return '$pending to buy · $done in the cart';
  }

  @override
  String shopUnpriced(int count) {
    return ' · $count without price';
  }

  @override
  String get shopAddProduct => 'Add product';

  @override
  String get shopSearchStore => 'Search the supermarket';

  @override
  String get shopAddDetailed => 'Add with details';

  @override
  String get moreOptions => 'More options';

  @override
  String get less => 'Less';

  @override
  String get more => 'More';

  @override
  String shopAdded(String name) {
    return '$name, added';
  }

  @override
  String shopAdd(String name) {
    return 'Add $name';
  }

  @override
  String get shopLiveOffline =>
      'No live connection right now; it will update when you reload.';

  @override
  String get couldNotUpdate => 'Couldn\'t update';

  @override
  String shopSavedToPantry(int count) {
    return '$count products saved to the pantry';
  }

  @override
  String get shopRemoveFromList => 'Remove from list';

  @override
  String shopRemovedOne(String name) {
    return 'Removed \"$name\"';
  }

  @override
  String get couldNotChangePhoto => 'Couldn\'t change the photo';

  @override
  String get shopAddToList => 'Add to list';

  @override
  String get shopTypeFood => 'Food';

  @override
  String get shopTypeHome => 'Home/Cleaning';

  @override
  String get name => 'Name';

  @override
  String get product => 'Product';

  @override
  String get quantity => 'Quantity';

  @override
  String get unit => 'Unit';

  @override
  String get cancel => 'Cancel';

  @override
  String get add => 'Add';

  @override
  String get nameEmpty => 'The name can\'t be empty.';

  @override
  String get couldNotAdd => 'Couldn\'t add';

  @override
  String get shopPlanAllAtHome =>
      'You already have everything from the plan at home';

  @override
  String shopAddedFromPlan(int count) {
    return 'Added $count products from the plan';
  }

  @override
  String get shopListTitle => 'Shopping list';

  @override
  String get shopMainList => 'Main list';

  @override
  String get couldNotCreateList => 'Couldn\'t create the list';

  @override
  String get shopRecipesUseStore =>
      'Your list products will be looked up in this supermarket. Recipes work with any store.';

  @override
  String get shopStoreSaveError =>
      'Couldn\'t save the supermarket. Please try again.';

  @override
  String get shopGroupByAisle => 'Group by aisle';

  @override
  String get shopGroupHint => 'Vegetables, meat, cleaning…';

  @override
  String get shopShowPhotos => 'Show product photos';

  @override
  String get shopShowIcons => 'Show drawings when there is no photo';

  @override
  String get shopMyLists => 'My lists';

  @override
  String get categories => 'Categories';

  @override
  String get shopFinish => 'Finish shopping';

  @override
  String shopFinishCount(int count) {
    return 'Finish shopping ($count)';
  }

  @override
  String get shopScanTicket => 'Scan receipt';

  @override
  String get shopAllBought => 'All bought';

  @override
  String get shopToBuy => 'To buy';

  @override
  String get shopUsual => 'The usual';

  @override
  String get shopInCart => 'In the cart';

  @override
  String shopRemovedMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Removed $count products',
      one: 'Removed 1 product',
    );
    return '$_temp0';
  }

  @override
  String get couldNotRemove => 'Couldn\'t remove';

  @override
  String get undo => 'Undo';

  @override
  String get couldNotUndo => 'Couldn\'t undo';

  @override
  String get shopToCart => 'To cart';

  @override
  String get shopFromPlan => 'From this week\'s plan';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get shopEmptyTitle => 'Your list is empty';

  @override
  String get shopEmptyHint => 'Type what you need above or bring in the plan.';

  @override
  String get shopFromPlanAction => 'From the plan';

  @override
  String get shopDoneTitle => 'Shopping done';

  @override
  String get shopDoneHint => 'You\'ve got everything on the list. Nice work!';

  @override
  String panUsedInOne(String meal) {
    return 'Removed what you used in $meal';
  }

  @override
  String panUsedInMany(int count) {
    return 'Removed what you used in $count planned meals';
  }

  @override
  String get view => 'View';

  @override
  String get couldNotDelete => 'Couldn\'t delete';

  @override
  String panNoLongerShop(String name) {
    return '$name won\'t show up in shopping anymore.';
  }

  @override
  String panBackToShop(String name) {
    return '$name will show up in shopping again.';
  }

  @override
  String panCouldNotMarkOut(String name) {
    return 'Couldn\'t mark $name as run out';
  }

  @override
  String panMarkedOut(String name) {
    return 'I\'ve marked $name as run out.';
  }

  @override
  String panOutNotAdded(String name) {
    return '$name is marked as run out, but I couldn\'t add it to shopping';
  }

  @override
  String panAlreadyInList(String name) {
    return '$name is already on your shopping list.';
  }

  @override
  String panAddedToShop(String name) {
    return 'I\'ve added $name to shopping';
  }

  @override
  String get panAddManual => 'Add manually';

  @override
  String get panScanBarcode => 'Scan barcode';

  @override
  String get panFreezeDish => 'Cooked dish to the freezer';

  @override
  String get panFreezeDishHint => 'Pick the recipe and how many servings';

  @override
  String get panSaveRecipeFirst => 'Save a recipe first.';

  @override
  String get panWhichDish => 'Which dish are you freezing?';

  @override
  String get panHowManyServings => 'How many servings are you freezing?';

  @override
  String get panTitle => 'Pantry and Fridge';

  @override
  String get panAddTooltip => 'Add to pantry';

  @override
  String get panLoadError => 'Couldn\'t load the inventory';

  @override
  String get panEmptyTitle => 'Your pantry is empty';

  @override
  String get panEmptyHint =>
      'Add what you have at home, or tick off your shopping and it\'ll show up here.';

  @override
  String get panAddProduct => 'Add product';

  @override
  String get panWhatToCook => 'What can I cook with this?';

  @override
  String get panExpiringHeader => 'Expired and about to expire';

  @override
  String get panNothingHere => 'Nothing here.';

  @override
  String kitchenZone(String zone) {
    String _temp0 = intl.Intl.selectLogic(zone, {
      'nevera': 'Fridge',
      'congelador': 'Freezer',
      'despensa': 'Pantry',
      'bebidas': 'Drinks',
      'especias': 'Seasonings',
      'limpieza': 'Cleaning',
      'hogar': 'Hygiene and home',
      'other': '$zone',
    });
    return '$_temp0';
  }

  @override
  String get kitchenReview => 'Review';

  @override
  String expiryGroup(String group) {
    String _temp0 = intl.Intl.selectLogic(group, {
      'expired': 'Expired',
      'week': 'This week',
      'later': 'Later',
      'other': 'No date',
    });
    return '$_temp0';
  }

  @override
  String panExpiredAgo(int days) {
    return 'Expired $days days ago';
  }

  @override
  String get panExpiredYesterday => 'Expired yesterday';

  @override
  String get panExpiresToday => 'Expires today';

  @override
  String get panExpiresTomorrow => 'Expires tomorrow';

  @override
  String panExpiresIn(int days) {
    return 'Expires in $days days';
  }

  @override
  String panDays(int days) {
    return '$days days';
  }

  @override
  String get panNotBought => 'Not bought';

  @override
  String get panConsumed => 'Used up';

  @override
  String get panToShopping => 'To shopping';

  @override
  String panCouldNotAddToShop(String name) {
    return 'Couldn\'t add $name to shopping';
  }

  @override
  String panExpiredDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expired items deleted',
      one: 'Expired item deleted',
    );
    return '$_temp0';
  }

  @override
  String get panMyKitchen => 'My kitchen';

  @override
  String get panUsedHistory => 'What\'s been used';

  @override
  String get panNothingExpired => 'Nothing expired';

  @override
  String panDeleteExpired(int count) {
    return 'Delete expired ($count)';
  }

  @override
  String panEmptyZone(String where) {
    return 'Empty $where';
  }

  @override
  String panEmptyAsk(String where) {
    return 'Empty $where?';
  }

  @override
  String panWillDelete(int count) {
    return '$count products will be deleted.';
  }

  @override
  String get panEmpty => 'Empty';

  @override
  String panDeleted(int count) {
    return '$count products deleted';
  }

  @override
  String get edit => 'Edit';

  @override
  String get panShopAgain => 'Add to shopping again';

  @override
  String get panDontShop => 'Don\'t add to shopping';

  @override
  String get panStapleHint => 'For basics you always have';

  @override
  String get panWillAddToShop => 'I\'ll add it to shopping';

  @override
  String get delete => 'Delete';

  @override
  String panDeleteAsk(String name) {
    return 'Delete $name?';
  }

  @override
  String panConsumedOn(String name, String day) {
    return '$name, used up $day';
  }

  @override
  String get todayLower => 'today';

  @override
  String get yesterdayLower => 'yesterday';

  @override
  String panOnDate(int day, int month) {
    return 'on $month/$day';
  }

  @override
  String get panWhen => 'When?';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get panOtherDay => 'Another day';

  @override
  String get panWhichDay => 'Which day?';

  @override
  String get panHowMany => 'How many?';

  @override
  String panAll(String qty) {
    return 'All ($qty)';
  }

  @override
  String get couldNotLoad => 'Couldn\'t load';

  @override
  String get panNothingYet => 'Nothing yet.';

  @override
  String get panWhenCooking => 'When cooking';

  @override
  String get planHowLong => 'For how long?';

  @override
  String get thisWeek => 'This week';

  @override
  String planWeeks(int count) {
    return '$count weeks';
  }

  @override
  String get planMonth4 => 'A month (4 weeks)';

  @override
  String get planPickDates => 'Pick dates';

  @override
  String get planDates => 'Plan dates';

  @override
  String get planMaxTwoMonths => 'Two months at most at a time.';

  @override
  String get planReadyAllHome =>
      'Plan ready. You already have everything you need at home';

  @override
  String planListReady(int count) {
    return 'Plan ready. Shopping list with $count products';
  }

  @override
  String get planBackInPlan => 'It\'s back in the plan';

  @override
  String planEntryTitle(String meal, String recipe) {
    return '$meal · $recipe';
  }

  @override
  String get planNoRecipe => 'No recipe';

  @override
  String get planChangeRecipe => 'Change recipe';

  @override
  String get planWhoEats => 'Who\'s eating';

  @override
  String get planMarkHome => 'Mark as at home';

  @override
  String get planMarkOut => 'Mark as eating out';

  @override
  String get planStopRepeat => 'Stop repeating';

  @override
  String get planStopRepeatHint => 'Removes the next times';

  @override
  String get planRepeat => 'Repeat';

  @override
  String get planRepeatHint => 'Every day, every week… or forever';

  @override
  String get planRemove => 'Remove from plan';

  @override
  String planRepeatTitle(String meal) {
    return 'Repeat $meal';
  }

  @override
  String get planHowOften => 'How often?';

  @override
  String planEveryDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Every $days days',
      one: 'Every day',
    );
    return '$_temp0';
  }

  @override
  String planEveryWeeks(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: 'Every $weeks weeks',
      one: 'Every week',
    );
    return '$_temp0';
  }

  @override
  String get planUntilWhen => 'Until when?';

  @override
  String get planForever => 'Forever';

  @override
  String planMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String get planRepeatDone =>
      'Done. You\'ll see it in the plan in the coming weeks; if a day already has something else, that stays.';

  @override
  String get planWhoAtHome => 'Who\'s eating at home?';

  @override
  String get planCalendarPermission =>
      'Allow calendar access in your phone settings';

  @override
  String get planInFast => 'Falls during the fast';

  @override
  String get planSettings => 'Plan settings';

  @override
  String get planBatchCook => 'I batch cook';

  @override
  String get planBatchCookHint => 'Shopping day, cooking day and containers';

  @override
  String get planTimes => 'Times';

  @override
  String get planFasting => 'Intermittent fasting';

  @override
  String get no => 'No';

  @override
  String planEatWindow(String from, String to) {
    return 'You eat from $from to $to. It moves with dinner time.';
  }

  @override
  String get planCalendar => 'Calendar';

  @override
  String get planToCalendar => 'Send to calendar';

  @override
  String get planCalendarLinked => 'Calendar connected';

  @override
  String get planCalendarHint => 'Meals and timed tasks, in Google Calendar';

  @override
  String get planCalendarUpdates => 'Updates when you open the plan';

  @override
  String get remove => 'Remove';

  @override
  String get planPickRecipe => 'Pick a recipe';

  @override
  String get planDayFull => 'That day already has all its meals.';

  @override
  String get planWhichMeal => 'Which meal are you adding?';

  @override
  String get planTitle => 'Weekly plan';

  @override
  String get planNoHome => 'You\'re not part of any household.';

  @override
  String get planMake => 'Make plan';

  @override
  String get planRemake => 'Redo plan';

  @override
  String get planNeedRecipes => 'Add some recipes first';

  @override
  String get planNeedRecipesHint =>
      'The planner spreads your recipes across the week. Save a few in the Meals tab.';

  @override
  String get planPrevWeek => 'Previous week';

  @override
  String get planNextWeekLabel => 'Next week';

  @override
  String get planLastWeek => 'Last week';

  @override
  String get planWeek => 'Week';

  @override
  String get planBackToToday => 'Back to today';

  @override
  String get planNextWeek => 'Next week';

  @override
  String get planDay => 'Day';

  @override
  String get planMonthCalendar => 'Month calendar';

  @override
  String get planNoPlanYet => 'No plan for this week yet.';

  @override
  String get recipe => 'Recipe';

  @override
  String get planCookMode => 'Cooking mode';

  @override
  String get planCookWeek => 'Cook the whole week in one go';

  @override
  String get planBatch => 'Batch cooking';

  @override
  String planCookDays(int days, int recipes) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days cooking days',
      one: '1 cooking day',
    );
    String _temp1 = intl.Intl.pluralLogic(
      recipes,
      locale: localeName,
      other: '$recipes recipes',
      one: '1 recipe',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get planBatchEmpty =>
      'Once the plan is made I\'ll tell you when to shop, when to cook and what goes in the fridge or freezer.';

  @override
  String get planCookedToFreezer => 'Cooked · to the freezer';

  @override
  String planFrozen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dishes saved in the freezer.',
      one: 'Saved in the freezer with its photo.',
    );
    return '$_temp0';
  }

  @override
  String get planEnergyLow => 'Little';

  @override
  String get planEnergyNormal => 'Normal';

  @override
  String get planEnergyHigh => 'A lot';

  @override
  String get planEnergyHint =>
      'With \"little\" the plan relies more on the freezer.';

  @override
  String get planHowMuchCook => 'How much to cook';

  @override
  String planServings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count servings',
      one: '1 serving',
    );
    return '$_temp0';
  }

  @override
  String get close => 'Close';

  @override
  String get planSearchRecipe => 'Search recipe...';

  @override
  String get planNoMatch => 'No matching recipes.';

  @override
  String get diaDeleteError => 'Couldn\'t delete the meal.';

  @override
  String get diaManual => 'Manually';

  @override
  String get diaManualHint => 'Type the name and calories';

  @override
  String get diaFromRecipe => 'From a recipe';

  @override
  String get diaFromRecipeHint => 'Log one of your recipes as a meal';

  @override
  String get diaWithPhoto => 'With a photo';

  @override
  String get diaWithPhotoHint =>
      'Take a photo of the dish and we\'ll work out the calories';

  @override
  String get diaAddManual => 'Add manually';

  @override
  String get diaKcalField => 'Calories (kcal)';

  @override
  String get diaMealTypeOptional => 'Meal type (optional)';

  @override
  String get diaNoType => 'No type';

  @override
  String get diaProteinG => 'Protein (g)';

  @override
  String get diaCarbsG => 'Carbs (g)';

  @override
  String get diaFatG => 'Fat (g)';

  @override
  String get diaNeedNameKcal => 'Enter at least a name and the calories.';

  @override
  String get diaSaveError => 'Couldn\'t save the meal.';

  @override
  String get diaRecipesLoadError => 'Couldn\'t load the recipes.';

  @override
  String get diaNoRecipes => 'You don\'t have any recipes to log yet.';

  @override
  String diaKcalPerServing(int kcal) {
    return '$kcal kcal per serving';
  }

  @override
  String get diaNoKcal => 'No calories recorded';

  @override
  String get diaServings => 'Servings';

  @override
  String get diaServingsError => 'Enter a number of servings above 0.';

  @override
  String get diaLog => 'Log';

  @override
  String get diaRecipeLogError => 'Couldn\'t log the recipe.';

  @override
  String get diaTitle => 'My diary';

  @override
  String get diaAddMeal => 'Add meal';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get diaDayCalories => 'Calories today';

  @override
  String diaOfTarget(int kcal) {
    return 'of $kcal kcal';
  }

  @override
  String get diaNoTarget =>
      'Complete your profile to set a daily calorie goal and see how much you have left each day.';

  @override
  String get diaCompleteProfile => 'Complete my profile';

  @override
  String get diaOthers => 'Other';

  @override
  String get diaMeal => 'Meal';

  @override
  String get diaLast7 => 'Your last 7 days';

  @override
  String diaTargetPerDay(int kcal) {
    return 'Goal: $kcal kcal a day';
  }

  @override
  String get diaTarget => 'Goal';

  @override
  String get diaTodaySplit => 'Today\'s split';

  @override
  String get diaNoMacros => 'No macros logged today yet.';

  @override
  String get diaProtein => 'Protein';

  @override
  String get diaCarbs => 'Carbs';

  @override
  String get diaFat => 'Fat';

  @override
  String get diaAteThePlan => 'Did you eat what was planned?';

  @override
  String diaAskLine(String day, String meal, String name, int kcal) {
    return '$day, $meal: $name · $kcal kcal';
  }

  @override
  String get yes => 'Yes';

  @override
  String get diaAnswerError => 'Couldn\'t save the answer.';

  @override
  String get diaAskFirst => 'Ask me before logging the plan';

  @override
  String get diaAskOn => 'We\'ll ask whether you ate each planned meal.';

  @override
  String get diaAskOff =>
      'Planned meals are logged automatically once their time has passed.';

  @override
  String get diaSettingError => 'Couldn\'t save the setting.';

  @override
  String get diaEmpty =>
      'You haven\'t logged anything this day yet.\nAdd your first meal.';

  @override
  String get recUnfavorite => 'Remove from favourites';

  @override
  String get recFavorite => 'Mark as favourite';

  @override
  String get recDelete => 'Delete recipe';

  @override
  String get recDeleteAsk => 'Delete recipe?';

  @override
  String recRemoveAsk(String name) {
    return '\"$name\" and its ingredients will be deleted.';
  }

  @override
  String recDeleted(String name) {
    return '\"$name\" deleted.';
  }

  @override
  String get recTitle => 'Recipes';

  @override
  String get recNew => 'New recipe';

  @override
  String get recLoadError => 'I couldn\'t load the recipes';

  @override
  String get recEmptyTitle => 'No recipes yet';

  @override
  String get recEmptyHint =>
      'Create the first one or ask for ideas with what you have.';

  @override
  String get recIdeas => 'Ideas with what I have';

  @override
  String get recNoResults => 'No results';

  @override
  String recCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recipes',
      one: '1 recipe',
    );
    return '$_temp0';
  }

  @override
  String get recWhatToCook => 'What can I cook with what I have?';

  @override
  String get recPantryIdeas => 'Ideas with what\'s in your pantry';

  @override
  String get recAll => 'All';

  @override
  String get recFavorites => 'Favourites';

  @override
  String get recOther => 'Other';

  @override
  String recSeeAll(int count) {
    return 'See all $count';
  }

  @override
  String get recNoFilter =>
      'No recipes with this filter.\nTry another category.';

  @override
  String get clear => 'Clear';

  @override
  String recNoMatch(String query) {
    return 'No recipes match\n\"$query\".';
  }

  @override
  String get rdPhoto => 'Recipe photo';

  @override
  String get rdAutoPhoto => 'Find another photo automatically';

  @override
  String get rdAutoPhotoHint => 'Searches for a new image by name';

  @override
  String get rdGallery => 'Choose from gallery';

  @override
  String get rdNoBetterPhoto => 'I haven\'t found a better photo for now';

  @override
  String get rdUploadError => 'Couldn\'t upload the photo';

  @override
  String rdShareText(String title, String code) {
    return 'Here\'s my $title recipe on PrezHome. In the app, go to Recipes, tap Add recipe and then With a code: $code';
  }

  @override
  String get rdSavedFreezer => 'Saved in the freezer.';

  @override
  String get couldNotSave => 'Couldn\'t save';

  @override
  String get rdVideoError => 'Couldn\'t open the video link';

  @override
  String get rdWatchVideo => 'Watch video';

  @override
  String get share => 'Share';

  @override
  String get rdEdit => 'Edit recipe';

  @override
  String get rdMinutes => 'Minutes';

  @override
  String get rdKcalServing => 'Kcal/serving';

  @override
  String get rdPerServingShort => 'per serving';

  @override
  String rdServingWord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Servings',
      one: 'Serving',
    );
    return '$_temp0';
  }

  @override
  String get rdFreezable => 'Freezable';

  @override
  String get rdIngredients => 'Ingredients';

  @override
  String get rdStepsWord => 'Steps';

  @override
  String rdSteps(int count) {
    return 'Steps ($count)';
  }

  @override
  String get rdNutrition => 'Nutrition';

  @override
  String get rdNoIngredients => 'No ingredients recorded.';

  @override
  String rdOriginal(String servings) {
    return 'Original recipe: $servings';
  }

  @override
  String rdForHome(String servings) {
    return 'For your household today: $servings';
  }

  @override
  String get rdHaveAll => 'You have everything at home';

  @override
  String rdHaveSome(int have, int total) {
    return 'You have $have of $total at home';
  }

  @override
  String rdMissing(int count) {
    return '$count missing';
  }

  @override
  String get rdAtHome => 'At home';

  @override
  String get rdLacking => 'Missing';

  @override
  String get rdNoSteps =>
      'This recipe has no steps. You can add them by editing it.';

  @override
  String get rdPerServingTitle => 'Per serving';

  @override
  String get rdNoNutrition => 'No nutrition data.';

  @override
  String rdPerServing(String amount) {
    return '$amount per serving';
  }

  @override
  String rdTotal(String amount) {
    return '≈ $amount total';
  }

  @override
  String get rdApproxCost =>
      'Approximate cost. Scan receipts to fine-tune it with your real prices.';

  @override
  String get rdStartCooking => 'Start cooking';

  @override
  String rdAddedMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count products to shopping',
      one: 'Added to the shopping list',
    );
    return '$_temp0';
  }

  @override
  String get rdNeedProfile =>
      'Complete a Nutrition Profile to see how many grams and calories each person gets.';

  @override
  String get rdMember => 'Member';

  @override
  String get rdAdjustSplit =>
      'Adjust the calorie split per meal in the profile for this type of recipe.';

  @override
  String get rdByProfile => 'Based on each person\'s profile';

  @override
  String get rdByProfileHint => 'Amount and calories per person for this meal.';

  @override
  String get arWriteName => 'Type the name';

  @override
  String get arWriteNameHint => 'Type the name or paste a whole recipe…';

  @override
  String get arGenerate => 'Generate';

  @override
  String get arFilled => 'Recipe filled in. Check it before saving.';

  @override
  String get arFillError => 'Couldn\'t complete the recipe';

  @override
  String get arImport => 'Import recipe';

  @override
  String get arPasteRecipe => 'Paste the recipe';

  @override
  String get arImportHint =>
      'Paste the TikTok, YouTube or website link, or the recipe text. On Instagram, copy the post\'s caption and paste it here.';

  @override
  String get arLinkOrText => 'Recipe link or text';

  @override
  String get arRecipeText => 'Recipe text';

  @override
  String get paste => 'Paste';

  @override
  String get arImportBtn => 'Import';

  @override
  String get arNeedLink => 'Paste a link or the full recipe text.';

  @override
  String get arImported => 'Recipe imported. Check it before saving.';

  @override
  String get arImportLinkError =>
      'I couldn\'t import the recipe from that link';

  @override
  String get arImportError => 'Couldn\'t import';

  @override
  String get arPickMealType => 'Pick at least one meal type.';

  @override
  String get arVideoNotUrl =>
      'The video link doesn\'t look like a URL, but we\'ll save it anyway.';

  @override
  String get arRecalculated =>
      'Calories and macros recalculated from the ingredients.';

  @override
  String arPhotoFailed(String error) {
    return 'Recipe saved, but the photo couldn\'t be uploaded: $error';
  }

  @override
  String get arSaveError => 'Error while saving';

  @override
  String get arReadingVideo => 'Reading the recipe from the video…';

  @override
  String get arCompleting => 'Completing the recipe…';

  @override
  String get arAddPhoto => 'Add photo (optional)';

  @override
  String get arTitleField => 'Title';

  @override
  String get arTitleRequired => 'Give it a title';

  @override
  String get arDescription => 'Description (optional)';

  @override
  String get arVideoLink => 'Video link (optional)';

  @override
  String get arMealTypes => 'Meal type (you can pick several)';

  @override
  String get arAuto => 'Auto';

  @override
  String get arServingsHelper => 'How many it serves';

  @override
  String get arGramsServing => 'Grams / serving';

  @override
  String get arNutritionTitle => 'Nutrition facts (per serving)';

  @override
  String get arCooking => 'Cooking';

  @override
  String get arPrepMin => 'Prep (min)';

  @override
  String get arCookMin => 'Cooking (min)';

  @override
  String get arAppliance => 'Main appliance';

  @override
  String get arFreezable => 'Freezable';

  @override
  String get arAddIngredient => 'Add ingredient';

  @override
  String get arStepsTitle => 'Preparation steps';

  @override
  String get arStepsHint => 'Write the steps, one per line…';

  @override
  String get arSaveChanges => 'Save changes';

  @override
  String get arSaveRecipe => 'Save recipe';

  @override
  String get arIngredient => 'Ingredient';

  @override
  String get tskWhoDid => 'Who did the task?';

  @override
  String get tskTheHome => 'the household';

  @override
  String tskPointsFor(int points, String who) {
    return '+$points points for $who';
  }

  @override
  String tskPointsForPantry(int points, String who, int count) {
    return '+$points points for $who. $count products to the pantry';
  }

  @override
  String tskYou(String name) {
    return '$name (you)';
  }

  @override
  String get tskThisMember => 'this member';

  @override
  String get tskResetPoints => 'Reset points';

  @override
  String tskResetAsk(String name) {
    return '$name\'s points will be set to 0. This can\'t be undone. Are you sure?';
  }

  @override
  String get tskReset => 'Reset';

  @override
  String tskResetDone(String name) {
    return '$name\'s points reset.';
  }

  @override
  String get tskDeleteTitle => 'Delete task?';

  @override
  String tskDeleteAsk(String title) {
    return '\"$title\" will be deleted.';
  }

  @override
  String tskClaimed(String title) {
    return '\"$title\" is yours';
  }

  @override
  String get tskDone => 'Done';

  @override
  String get tskToTomorrow => 'Move to tomorrow';

  @override
  String get tskToNextWeek => 'Move to next week';

  @override
  String get tskTitle => 'Tasks';

  @override
  String get tskEmptyTitle => 'No tasks yet';

  @override
  String get tskEmptyHint => 'Add the first one.';

  @override
  String get tskNew => 'New task';

  @override
  String get tskAnyone => 'Anyone';

  @override
  String get tskForToday => 'For today';

  @override
  String get tskUpcoming => 'Coming days';

  @override
  String get tskPoolEmpty => 'Nothing in the pool. Everything has an owner.';

  @override
  String get tskSwipeToClaim => 'Swipe left to claim it.';

  @override
  String get tskNothingDone => 'Nothing done yet today.';

  @override
  String get tskAll => 'All';

  @override
  String get tskMine => 'Mine';

  @override
  String get tskAllDoneToday => 'Everything\'s done today';

  @override
  String get tskNextBelow => 'Next up, below.';

  @override
  String get tskNothingLeft => 'Nothing left to do.';

  @override
  String get tskScoreboard => 'SCOREBOARD';

  @override
  String get tskPointsPerPerson => 'POINTS PER PERSON';

  @override
  String get tskNoPoints => 'No points yet';

  @override
  String get tskNoPointsHint => 'Complete tasks to start adding up.';

  @override
  String get tskSomeDays => 'Some days';

  @override
  String get tskOnce => 'Once';

  @override
  String get tskNothingToday => 'Nothing for today';

  @override
  String get tskAllDone => 'All done';

  @override
  String tskLeft(int count) {
    return '$count left';
  }

  @override
  String tskOverdueCount(int count) {
    return '$count overdue';
  }

  @override
  String tskMarkDone(String title) {
    return 'Mark $title as done';
  }

  @override
  String tskClaim(String title) {
    return 'Claim $title';
  }

  @override
  String get tskOverdue => 'Overdue';

  @override
  String tskPts(int points) {
    return '$points pts';
  }

  @override
  String tskView(String view) {
    String _temp0 = intl.Intl.selectLogic(view, {
      'pending': 'To do',
      'pool': 'Pool',
      'other': 'Done',
    });
    return '$_temp0';
  }

  @override
  String get tskOtherDay => 'Another day';

  @override
  String get tskEdit => 'Edit task';

  @override
  String get tskNameHint => 'Task name';

  @override
  String get tskOrTypeAnother => 'Or type another';

  @override
  String get tskWhen => 'When';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get tskNoDate => 'No date';

  @override
  String get tskRepeats => 'Repeats';

  @override
  String get tskWho => 'Who';

  @override
  String get tskMe => 'Me';

  @override
  String get tskAddPersonHint =>
      'To assign it to someone, add that person in Home (even without an account).';

  @override
  String get tskDetails => 'Details';

  @override
  String get tskNoTime => 'No time';

  @override
  String get tskRemoveTime => 'Remove time';

  @override
  String tskFreeAt(String time) {
    return 'Free at $time';
  }

  @override
  String get tskNotes => 'Notes';

  @override
  String get tskPoints => 'Points';

  @override
  String get tskAdd => 'Add task';

  @override
  String get arcTitle => 'Add recipe';

  @override
  String get arcLinkTitle => 'Paste a video link';

  @override
  String get arcLinkSub => 'From TikTok or YouTube, or the Instagram text';

  @override
  String get arcNameTitle => 'Type the name';

  @override
  String get arcNameSub => 'Filled in with ingredients, steps and macros';

  @override
  String get arcIdeasTitle => 'Ideas for you';

  @override
  String get arcIdeasSub => 'Based on your supermarket, goal and budget';

  @override
  String get arcManualTitle => 'By hand';

  @override
  String get arcManualSub => 'Fill in each field yourself';

  @override
  String get arcCodeTitle => 'With a code';

  @override
  String get arcCodeSub => 'Save a recipe someone shared with you';

  @override
  String get arcCodeDialog => 'Recipe code';

  @override
  String get search => 'Search';

  @override
  String get arcNoCode => 'No recipe with that code';

  @override
  String arcIngredientsAsk(int count) {
    return '$count ingredients. Save it to your recipes?';
  }

  @override
  String get arcSaved => 'Recipe saved';

  @override
  String get nutLoadError => 'Couldn\'t load the profile';

  @override
  String get nutSaved => 'Profile saved';

  @override
  String get nutSaveError => 'Couldn\'t save';

  @override
  String get nutBirthDate => 'Date of birth';

  @override
  String get nutTitle => 'My nutrition profile';

  @override
  String get nutDiary => 'Calorie diary';

  @override
  String get nutWizard => 'Set up step by step';

  @override
  String get nutWizardSub =>
      'An assistant asks you a few questions and works out your goal.';

  @override
  String get nutHowCook => 'How do you cook?';

  @override
  String get nutDaily => 'Day by day';

  @override
  String get nutDailySub => 'I cook every day';

  @override
  String get nutBatch => 'Batch cooking';

  @override
  String get nutBatchSub => 'I cook once for several days';

  @override
  String get nutAmounts => 'Amounts';

  @override
  String get nutPractical => 'Practical';

  @override
  String get nutPracticalSub => 'Supermarket pack sizes';

  @override
  String get nutExact => 'Exact';

  @override
  String get nutExactSub => 'To the gram';

  @override
  String get nutSex => 'Sex';

  @override
  String get nutFemale => 'Female';

  @override
  String get nutMale => 'Male';

  @override
  String get nutSelect => 'Select…';

  @override
  String nutAge(int age) {
    return '($age years)';
  }

  @override
  String get nutHeight => 'Height (cm)';

  @override
  String get nutWeight => 'Weight (kg)';

  @override
  String get nutActivityLevel => 'Activity level';

  @override
  String get nutGoalLabel => 'Goal';

  @override
  String nutActivity(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'sedentary': 'Sedentary (little or no exercise)',
      'light': 'Light (1-3 days/week)',
      'moderate': 'Moderate (3-5 days/week)',
      'active': 'Active (6-7 days/week)',
      'other': 'Very active (hard exercise or physical job)',
    });
    return '$_temp0';
  }

  @override
  String nutGoal(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'lose': 'Lose weight',
      'gain': 'Gain weight',
      'other': 'Maintain weight',
    });
    return '$_temp0';
  }

  @override
  String get nutSplit => 'Calories per meal';

  @override
  String nutTotal(int pct) {
    return 'Total: $pct%';
  }

  @override
  String get nutSplitHint =>
      'Set 0% for meals you skip. The total should be 100%.';

  @override
  String get nutAtHome => 'Meals at home';

  @override
  String get nutAtHomeHint =>
      'Tick the days you have each meal at home. If you eat out (e.g. at work), untick that day and it won\'t count.';

  @override
  String get nutShare => 'Share my profile with the household';

  @override
  String get nutShareSub => 'If off, your profile is private.';

  @override
  String get nutSave => 'Save profile';

  @override
  String get nutIncomplete =>
      'Fill in sex, date of birth, height and weight to work out your daily calories and macros.';

  @override
  String get nutDailyTarget => 'Your daily target (approx.)';

  @override
  String nutKcalDay(int kcal) {
    return '$kcal kcal / day';
  }

  @override
  String nutPerMeal(int kcal, int meals) {
    return '≈ $kcal kcal per meal ($meals meals)';
  }

  @override
  String get ecoBudgetTitle => 'Monthly budget';

  @override
  String ecoAmount(String symbol) {
    return 'Amount ($symbol)';
  }

  @override
  String get ecoDeleteTicket => 'Delete receipt?';

  @override
  String get ecoDeleteTicketSub => 'It will no longer count in your spending.';

  @override
  String ecoRedeemed(String title) {
    return 'You redeemed \"$title\"';
  }

  @override
  String get ecoRedeemFail =>
      'Couldn\'t redeem. You may not have enough points.';

  @override
  String get ecoNewReward => 'New reward';

  @override
  String get ecoRewardTitle => 'Title';

  @override
  String get ecoRewardDesc => 'Description (optional)';

  @override
  String get ecoRewardCost => 'Cost in points';

  @override
  String get ecoTitle => 'Spending and receipts';

  @override
  String get ecoStats => 'Shopping stats';

  @override
  String get ecoScan => 'Scan receipt';

  @override
  String ecoTicketsOf(String month) {
    return 'Receipts for $month';
  }

  @override
  String get ecoPointsBalance => 'Points balance';

  @override
  String get ecoPointsBalanceSub => 'Each member\'s balance to redeem rewards.';

  @override
  String get ecoNoPoints => 'No points to share yet';

  @override
  String get ecoNoPointsSub => 'Complete household tasks to fill the balance.';

  @override
  String get ecoRewards => 'Rewards';

  @override
  String ecoBalance(int points) {
    return 'Your balance: $points pts';
  }

  @override
  String get ecoRedeem => 'Redeem';

  @override
  String get ecoNoRewards => 'No rewards yet';

  @override
  String get ecoNoRewardsSub =>
      'Create the first one with the \"New reward\" button.';

  @override
  String get ecoTotalSpent => 'Total spending recorded';

  @override
  String ecoTicketCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count receipts in total',
      one: '1 receipt in total',
    );
    return '$_temp0';
  }

  @override
  String get ecoThisMonth => 'This month';

  @override
  String ecoBudget(String amount) {
    return 'Budget: $amount';
  }

  @override
  String get ecoSetBudget => 'Set budget';

  @override
  String ecoOver(String amount) {
    return 'You\'re $amount over budget';
  }

  @override
  String ecoLeft(String amount) {
    return '$amount left';
  }

  @override
  String get ecoLastMonths => 'Spending in recent months';

  @override
  String ecoBudgetPerMonth(String amount) {
    return 'Budget: $amount a month';
  }

  @override
  String get ecoBudgetShort => 'Budget';

  @override
  String get ecoNoTrend =>
      'No spending recorded in recent months yet.\nScan receipts to see your trend here.';

  @override
  String get ecoTicket => 'Receipt';

  @override
  String get ecoNoTickets => 'No receipts this month yet.\nScan the first one.';

  @override
  String get stOthers => 'Others';

  @override
  String get stNoCategory => 'No category';

  @override
  String get stThisWeek => 'This';

  @override
  String get stTitle => 'Your data';

  @override
  String get stSpendByMonth => 'Spending by month';

  @override
  String get stForecastFooter => 'Lighter: what\'s left to reach the forecast';

  @override
  String get stNoSpend => 'Scan a receipt to see your spending month by month.';

  @override
  String get stWhereSpend => 'Where your money goes this month';

  @override
  String get stNoTicketsMonth => 'No receipts this month yet.';

  @override
  String get stTopProducts => 'What you buy most';

  @override
  String get stTopProductsFooter =>
      'Times on your receipts in the last 3 months';

  @override
  String get stTopProductsEmpty => 'Shows up once you scan receipts.';

  @override
  String get stPantry => 'Your pantry';

  @override
  String get stMealsHome => 'Meals at home';

  @override
  String get stPerWeek => 'Per week';

  @override
  String stMealsOut(int count) {
    return 'Per week · $count eaten out';
  }

  @override
  String get stMealsEmpty => 'Plan meals to see how many you eat at home.';

  @override
  String get stTasksDone => 'Tasks done';

  @override
  String get stTasksFooter => 'Per week, and who did the most this month';

  @override
  String get stTasksEmpty => 'Tasks you complete will show up here.';

  @override
  String get stSoFar => 'Spent so far this month';

  @override
  String get stForecast => 'Forecast: ';

  @override
  String stMoreThanAvg(int pct) {
    return ', $pct% above your average';
  }

  @override
  String stLessThanAvg(int pct) {
    return ', $pct% below your average';
  }

  @override
  String get stTickets => 'Receipts';

  @override
  String get stExpired => 'Expired';

  @override
  String get stExpiringSoon => 'Expiring soon';

  @override
  String get stFresh => 'Fine';

  @override
  String stOverForecast(String amount) {
    return 'At this rate you\'ll be $amount over budget';
  }

  @override
  String stForecastTip(String amount) {
    return 'Forecast $amount';
  }

  @override
  String get pwPickOption => 'Pick an option to continue.';

  @override
  String get pwPickBirth => 'Select your date of birth.';

  @override
  String get pwBadHeight => 'Enter a valid height in centimetres.';

  @override
  String get pwBadWeight => 'Enter a valid weight in kilos.';

  @override
  String get pwCompleteStep => 'Complete this step to continue.';

  @override
  String get pwStart => 'Start using PrezHome';

  @override
  String get pwSeeGoal => 'See my goal';

  @override
  String get pwFinish => 'Finish';

  @override
  String get pwIntroTitle => 'Let\'s get to know you';

  @override
  String get pwIntroSub =>
      'A few quick questions to tailor PrezHome to you. You can change it any time.';

  @override
  String get pwTrackKcal => 'I want to track calories';

  @override
  String get pwTrackKcalSub =>
      'Planned meals log themselves once they\'re past.';

  @override
  String get pwOnlyHome => 'Just organise the home';

  @override
  String get pwOnlyHomeSub => 'No weight or measurements.';

  @override
  String get pwSex => 'Your sex';

  @override
  String get pwSexSub =>
      'We use it to estimate your metabolism more accurately.';

  @override
  String get pwPickDate => 'Select date';

  @override
  String get pwBirthTitle => 'When were you born?';

  @override
  String get pwBirthSub => 'Your age helps us fine-tune the calorie estimate.';

  @override
  String pwAgeYears(int age) {
    return '$age years old';
  }

  @override
  String get pwHeightTitle => 'How tall are you?';

  @override
  String get pwHeightSub => 'Enter your height in centimetres.';

  @override
  String get pwWeightTitle => 'How much do you weigh?';

  @override
  String get pwWeightSub => 'Enter your current weight in kilos.';

  @override
  String get pwActivityTitle => 'Your activity level';

  @override
  String get pwActivitySub => 'Pick the option that best describes your week.';

  @override
  String get pwGoalTitle => 'What\'s your goal?';

  @override
  String get pwGoalSub =>
      'We\'ll adjust your calories to what you want to achieve.';

  @override
  String pwGoalDesc(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'lose': 'A gentle deficit to lose weight bit by bit.',
      'gain': 'A gentle surplus to gain mass healthily.',
      'other': 'Keep your current weight and feel good.',
    });
    return '$_temp0';
  }

  @override
  String get pwDietTitle => 'How do you eat?';

  @override
  String get pwDietSub => 'Recipes will adapt to your diet.';

  @override
  String pwDiet(String diet) {
    String _temp0 = intl.Intl.selectLogic(diet, {
      'vegetariana': 'Vegetarian',
      'vegana': 'Vegan',
      'pescetariana': 'Pescatarian',
      'baja_carbo': 'Low carb',
      'sin_gluten': 'Gluten-free',
      'other': 'Everything',
    });
    return '$_temp0';
  }

  @override
  String get pwAllergiesTitle => 'Allergies or intolerances';

  @override
  String get pwOptional => 'Optional.';

  @override
  String pwAllergy(String allergy) {
    String _temp0 = intl.Intl.selectLogic(allergy, {
      'frutossecos': 'nuts',
      'lactosa': 'lactose',
      'gluten': 'gluten (coeliac)',
      'huevo': 'egg',
      'marisco': 'shellfish',
      'soja': 'soy',
      'other': 'fish',
    });
    return '$_temp0';
  }

  @override
  String get pwCuisinesTitle => 'What do you like to eat?';

  @override
  String get pwCuisinesSub => 'Pick as many as you like.';

  @override
  String pwCuisine(String cuisine) {
    String _temp0 = intl.Intl.selectLogic(cuisine, {
      'casera': 'Classic home cooking',
      'mediterranea': 'Mediterranean',
      'ligera': 'Light',
      'rapida': 'Quick and easy',
      'italiana': 'Italian',
      'asiatica': 'Asian',
      'mexicana': 'Mexican',
      'other': 'From around the world',
    });
    return '$_temp0';
  }

  @override
  String get pwAppliancesTitle => 'What\'s in your kitchen?';

  @override
  String get pwAppliancesSub => 'The plan will only use recipes you can make.';

  @override
  String appliance(String appliance) {
    String _temp0 = intl.Intl.selectLogic(appliance, {
      'oven': 'Oven',
      'stovetop': 'Frying pan',
      'pot': 'Pot',
      'airfryer': 'Air fryer',
      'microwave': 'Microwave',
      'blender': 'Blender',
      'other': 'None',
    });
    return '$_temp0';
  }

  @override
  String get pwDislikedTitle => 'Ingredients you don\'t like';

  @override
  String get pwDislikedSub => 'Comma-separated. Optional.';

  @override
  String get pwDislikedHint => 'onion, coriander...';

  @override
  String get pwCookTimeTitle => 'How long do you want to cook?';

  @override
  String get pwCookTimeSub =>
      'So recipes match your pace. You can leave it blank.';

  @override
  String pwCookTime(String time) {
    String _temp0 = intl.Intl.selectLogic(time, {
      'rapido': 'Quick (under 20 min)',
      'elaborado': 'Elaborate (I enjoy cooking)',
      'other': 'Normal',
    });
    return '$_temp0';
  }

  @override
  String pwCookTimeDesc(String time) {
    String _temp0 = intl.Intl.selectLogic(time, {
      'rapido': 'Dishes done in no time.',
      'elaborado': 'I enjoy cooking slowly.',
      'other': 'A balance between quick and elaborate.',
    });
    return '$_temp0';
  }

  @override
  String get pwCookStyleTitle => 'How do you prefer to cook?';

  @override
  String get pwChangeAnytime => 'You can change it any time.';

  @override
  String cookStyle(String style) {
    String _temp0 = intl.Intl.selectLogic(style, {
      'batch': 'Batch',
      'mixed': 'Mixed',
      'other': 'Daily',
    });
    return '$_temp0';
  }

  @override
  String cookStyleSub(String style) {
    String _temp0 = intl.Intl.selectLogic(style, {
      'batch': 'I cook in batches for several days',
      'mixed': 'I mix batches and day-to-day cooking',
      'other': 'I cook something fresh every day',
    });
    return '$_temp0';
  }

  @override
  String get pwModulesTitle => 'What do you want to turn on?';

  @override
  String get pwModulesSub => 'Anything you turn off won\'t be shown.';

  @override
  String homeModule(String module) {
    String _temp0 = intl.Intl.selectLogic(module, {
      'points': 'Points mode',
      'tasks': 'Tasks',
      'other': 'Batch cooking',
    });
    return '$_temp0';
  }

  @override
  String homeModuleDesc(String module) {
    String _temp0 = intl.Intl.selectLogic(module, {
      'points': 'Earn points and rewards for your tasks.',
      'tasks': 'Organise household tasks.',
      'other': 'Cook in batches and plan your prep.',
    });
    return '$_temp0';
  }

  @override
  String get pwAllSet => 'All set';

  @override
  String get pwAllSetSub =>
      'Recipes, plan and shopping adapt to what you told us.';

  @override
  String get pwDailyGoal => 'Your daily goal';

  @override
  String get pwKcalDay => 'kcal / day';

  @override
  String get pwEstimate =>
      'This is a starting estimate. Planned meals will log themselves in your diary once they\'re past.';

  @override
  String get phCantAnalyze => 'Couldn\'t analyse the meal';

  @override
  String phAnalyzeError(String error) {
    return 'Couldn\'t analyse the photo: $error';
  }

  @override
  String get phAnalyzeFail => 'Couldn\'t analyse the photo';

  @override
  String get phAddOne => 'Add at least one food with a name.';

  @override
  String get phTitle => 'Log with a photo';

  @override
  String get phLooking => 'Looking at your plate…';

  @override
  String get phStartTitle => 'Take a photo of your plate';

  @override
  String get phStartSub =>
      'We work out the foods and their calories. You can correct it before saving.';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get phReview => 'Check and fix what was detected';

  @override
  String get phApprox => 'Calories are approximate.';

  @override
  String get phMealType => 'Meal (optional)';

  @override
  String get phNoType => 'None';

  @override
  String get day => 'Day';

  @override
  String get phNothing => 'No food was recognised. Add them by hand.';

  @override
  String phFoods(int count) {
    return 'FOODS ($count)';
  }

  @override
  String get phAddFood => 'Add food';

  @override
  String get phFood => 'Food';

  @override
  String get phGrams => 'g (approx.)';

  @override
  String get phP => 'P (g)';

  @override
  String get phC => 'C (g)';

  @override
  String get phF => 'F (g)';

  @override
  String get total => 'Total';

  @override
  String kcalAmount(int kcal) {
    return '$kcal kcal';
  }

  @override
  String get phSave => 'Save to diary';

  @override
  String get stkOpenError => 'Couldn\'t open the receipt';

  @override
  String get stkReadError => 'Couldn\'t read the receipt';

  @override
  String get stkScanError => 'Scan failed';

  @override
  String get stkPantryError =>
      'The receipt was saved, but the pantry couldn\'t be updated';

  @override
  String stkCrossed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items ticked off the list',
      one: '1 item ticked off the list',
    );
    return '$_temp0';
  }

  @override
  String get stkEdit => 'Edit receipt';

  @override
  String get stkReading => 'Reading the receipt…';

  @override
  String get stkStartTitle => 'Scan your shopping receipt';

  @override
  String get stkStartSub =>
      'We pull out products and prices. You can review it afterwards.';

  @override
  String get stkReview => 'Check and fix anything needed';

  @override
  String get stkRemember => 'Your corrections will be remembered next time.';

  @override
  String get stkStore => 'Store';

  @override
  String get date => 'Date';

  @override
  String get stkAddPantry => 'Add to pantry';

  @override
  String get stkAddPantrySub => 'Each product goes to its spot';

  @override
  String stkProducts(int count) {
    return 'PRODUCTS ($count)';
  }

  @override
  String stkRaw(String name) {
    return 'Receipt: \"$name\"';
  }

  @override
  String get category => 'Category';

  @override
  String get stkQty => 'Qty';

  @override
  String get stkSave => 'Save receipt';

  @override
  String foodCategory(String cat) {
    String _temp0 = intl.Intl.selectLogic(cat, {
      'verdura': 'Vegetables',
      'fruta': 'Fruit',
      'carne': 'Meat',
      'pescado': 'Fish',
      'lacteos': 'Dairy',
      'preparados': 'Ready meals',
      'panaderia': 'Bakery',
      'cereales': 'Pasta, rice and pulses',
      'conservas': 'Tinned food',
      'congelados': 'Frozen',
      'dulces': 'Sweets and snacks',
      'bebidas': 'Drinks',
      'especias': 'Spices and condiments',
      'higiene': 'Personal care',
      'limpieza': 'Cleaning',
      'hogar': 'Household',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String get cookMode => 'Cooking mode';

  @override
  String get bpMeanwhile => 'Meanwhile';

  @override
  String bpTapers(String title) {
    return 'Containers · $title';
  }

  @override
  String get bpBatchCook => 'Batch cooking';

  @override
  String get bpStart => 'Start step by step';

  @override
  String get bpEmpty => 'Nothing to cook right now';

  @override
  String get bpEmptySub =>
      'Once you have recipes planned, I\'ll put together a cooking plan here so you can do it all in one go.';

  @override
  String get bpNeed => 'What you need';

  @override
  String get bpSplit => 'Split into containers';

  @override
  String get bpSplitSub => 'They\'re added to My kitchen automatically';

  @override
  String get bpYourPlan => 'Your cooking plan';

  @override
  String bpTotalMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'About $count minutes in total',
      one: 'About 1 minute in total',
    );
    return '$_temp0';
  }

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String get bpParallel => 'In parallel';

  @override
  String bpFor(String recipes) {
    return 'For $recipes';
  }

  @override
  String get ready => 'Done';

  @override
  String get pause => 'Pause';

  @override
  String get start => 'Start';

  @override
  String get reset => 'Reset';

  @override
  String get bpDone => 'Done';

  @override
  String get bpMarkDone => 'Mark as done';

  @override
  String cmStep(int n) {
    return 'Step $n';
  }

  @override
  String get cmTime => 'Time\'s up';

  @override
  String get cmSeeStep => 'See step';

  @override
  String get ok => 'OK';

  @override
  String get cmMicPermission =>
      'To use voice, allow the microphone in Settings.';

  @override
  String get ingredients => 'Ingredients';

  @override
  String get cmExit => 'Exit cooking mode';

  @override
  String get cmHandsFreeOff => 'Turn off hands-free';

  @override
  String get cmHandsFree => 'Hands-free';

  @override
  String get cmVoiceHint =>
      'Say «siguiente», «anterior», «repite» or «temporizador» (voice works in Spanish for now)';

  @override
  String get cmStop => 'Stop';

  @override
  String cmStepOf(int n, int total) {
    return 'STEP $n OF $total';
  }

  @override
  String get cmTimerRunning => 'Timer running';

  @override
  String cmTimerMin(int count) {
    return 'Timer $count min';
  }

  @override
  String get cmThen => 'Next';

  @override
  String get cmNextStep => 'Next step';

  @override
  String get shopSugDue => 'Due to buy';

  @override
  String get shopSugOut => 'Out at home';

  @override
  String get shopOutAtHome => 'Out at home';

  @override
  String get shopGridView => 'Grid view';

  @override
  String get shopGridHint => 'Big photos, two per row';

  @override
  String get shopShowSuggestions => 'Show suggestions';

  @override
  String get shopSuggestionsHint =>
      'What\'s due to restock and what ran out at home';

  @override
  String get shopShowPrices => 'Show prices';

  @override
  String shopEveryDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Every $n days',
      one: 'Every day',
    );
    return '$_temp0';
  }

  @override
  String get slNewList => 'New list';

  @override
  String get slMyLists => 'My lists';

  @override
  String get slActive => 'Active';

  @override
  String get slNewCat => 'New category';

  @override
  String get slRenameCat => 'Rename category';

  @override
  String get slCategories => 'Categories';

  @override
  String get slAddCat => 'Add category';

  @override
  String get slNoCats =>
      'No categories yet. Add the first one with the button below.';

  @override
  String get rename => 'Rename';

  @override
  String ppDayMeals(String day, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count meals',
      one: '1 meal',
    );
    return '$day, $_temp0';
  }

  @override
  String ppFastTime(String time) {
    return '$time · Fasting';
  }

  @override
  String get ppEatOut => '· Eating out';

  @override
  String mealAdd(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'breakfast': 'Add breakfast',
      'lunch': 'Add lunch',
      'snack': 'Add snack',
      'dinner': 'Add dinner',
      'dessert': 'Add dessert',
      'other': 'Add meal',
    });
    return '$_temp0';
  }

  @override
  String get ppFromFreezer => 'From the freezer';

  @override
  String ppServings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count serv.',
      one: '1 serving',
    );
    return '$_temp0';
  }

  @override
  String get ppFresh => 'Freshly made';

  @override
  String ppFridge(String days) {
    return 'Fridge · $days';
  }

  @override
  String ppFreezer(String days) {
    return 'Freezer · $days';
  }

  @override
  String get ppTapersAuto =>
      'Meal-prep boxes are added to My kitchen automatically';

  @override
  String drGoal(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'lose': 'Lose fat',
      'gain': 'Build muscle',
      'protein': 'High protein',
      'other': 'Maintain',
    });
    return '$_temp0';
  }

  @override
  String drDiet(String diet) {
    String _temp0 = intl.Intl.selectLogic(diet, {
      'veg': 'Vegetarian',
      'vegan': 'Vegan',
      'quick': 'Quick',
      'lowcarb': 'Low carb',
      'other': 'No restrictions',
    });
    return '$_temp0';
  }

  @override
  String drFreeOf(String allergen) {
    String _temp0 = intl.Intl.selectLogic(allergen, {
      'gluten': 'Gluten-free (coeliac)',
      'lactosa': 'Lactose-free',
      'huevo': 'Egg-free',
      'marisco': 'Shellfish-free',
      'soja': 'Soy-free',
      'other': 'Nut-free',
    });
    return '$_temp0';
  }

  @override
  String get drAnyType => 'Any';

  @override
  String get drNoIdeas => 'No ideas came back';

  @override
  String get drSaved => 'Saved to your recipes';

  @override
  String get drSearchSuper => 'Search supermarket...';

  @override
  String get drNoSuper => 'We couldn\'t find that supermarket.';

  @override
  String get drTitlePantry => 'What can I cook with this?';

  @override
  String get drTitle => 'Personalised ideas';

  @override
  String get drNewIdeas => 'New ideas';

  @override
  String get drWithPantry => 'With what I have';

  @override
  String get drPantryLoading => 'Checking your pantry…';

  @override
  String get drPantryEmpty =>
      'Your pantry is empty: add what you have at home to get ideas with it.';

  @override
  String drPantryUse(int count) {
    return 'We\'ll use $count items from your pantry, starting with what expires first.';
  }

  @override
  String get drCraving => 'What do you fancy?';

  @override
  String get drSupers => 'Supermarkets';

  @override
  String get drSupersHint =>
      'Optional. If you don\'t pick any, the recipes work for any supermarket.';

  @override
  String get drGoalTitle => 'Goal';

  @override
  String get drDietTitle => 'Diet';

  @override
  String drDietLocked(String diet) {
    return 'We use the diet from your profile: $diet';
  }

  @override
  String get drAllergyTitle => 'Intolerances and allergies';

  @override
  String get drAllergyHint => 'They\'ll never appear in the recipes.';

  @override
  String get drAppliances => 'Appliances';

  @override
  String get drMaxCost => 'Maximum cost per serving';

  @override
  String get drMaxCostHint => 'Optional, e.g. 2.50';

  @override
  String get drSearching => 'Looking for ideas…';

  @override
  String get drSeeIdeas => 'See ideas';

  @override
  String drAddedToShop(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count items to the shopping list',
      one: 'Added to the shopping list',
    );
    return '$_temp0';
  }

  @override
  String get drAddFail =>
      'Couldn\'t add to the shopping list. Check your connection and try again.';

  @override
  String drProteinShort(String grams) {
    return 'P: ${grams}g';
  }

  @override
  String get drCostTip =>
      'Approximate: prices from your receipts or, if none, average supermarket prices.';

  @override
  String drPerServing(String price) {
    return '≈ $price/serving';
  }

  @override
  String get drHave => 'You have:';

  @override
  String get drMissing => 'You need:';

  @override
  String get drAddedShort => 'Added to shopping';

  @override
  String get drAddMissing => 'Add what\'s missing';

  @override
  String get drSavedShort => 'Saved';

  @override
  String get drSaveToRecipes => 'Save to my recipes';

  @override
  String taskKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'bano': 'Bathroom',
      'ropa': 'Laundry',
      'compra': 'Shopping',
      'basura': 'Trash',
      'platos': 'Dishes',
      'limpieza': 'Cleaning',
      'plantas': 'Plants',
      'cama': 'Bed',
      'mascota': 'Pet',
      'cocinar': 'Cooking',
      'pagos': 'Payments',
      'other': 'Task',
    });
    return '$_temp0';
  }

  @override
  String taskPreset(String preset) {
    String _temp0 = intl.Intl.selectLogic(preset, {
      'dishes': 'Do the dishes',
      'vacuum': 'Vacuum',
      'bathroom': 'Clean the bathroom',
      'laundry': 'Do the laundry',
      'trash': 'Take out the trash',
      'shopping': 'Do the shopping',
      'plants': 'Water the plants',
      'other': 'Change the sheets',
    });
    return '$_temp0';
  }

  @override
  String get recQuick => 'Quick';

  @override
  String get recLight => 'Light';

  @override
  String get recFreezer => 'Freezable';

  @override
  String get recSearchHint => 'Search by name or ingredient';

  @override
  String get recSort => 'Sort';

  @override
  String get recSortRecent => 'Newest';

  @override
  String get recSortAz => 'A to Z';

  @override
  String get recSortFastest => 'Quickest first';

  @override
  String get recSortLightest => 'Fewest calories first';

  @override
  String get recClearFilters => 'Clear filters';

  @override
  String get recMore => 'More';

  @override
  String get recLess => 'Less';
}
