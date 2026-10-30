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
      'The first one will be your main supermarket: recipes will use products that are easy to find there.';

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
      'Recipes will use products from this supermarket.';

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
  String get recNoFilter =>
      'No recipes with this filter.\nTry another category.';

  @override
  String get clear => 'Clear';

  @override
  String recNoMatch(String query) {
    return 'No recipes match\n\"$query\".';
  }
}
