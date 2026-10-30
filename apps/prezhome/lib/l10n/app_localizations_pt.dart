// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String tabLabel(String tab) {
    String _temp0 = intl.Intl.selectLogic(tab, {
      'inicio': 'Hoje',
      'comidas': 'Refeições',
      'compra': 'Compras',
      'despensa': 'Despensa',
      'tareas': 'Tarefas',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get country => 'País';

  @override
  String get countryHint => 'Moeda, supermercados e preços de referência';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get back => 'Voltar';

  @override
  String get oneMoment => 'Um momento…';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get loginAccountCreated => 'Conta criada. Bem-vindo ao PrezHome';

  @override
  String get loginAuthError => 'Erro de autenticação';

  @override
  String loginProviderError(String provider) {
    return 'Não foi possível entrar com $provider';
  }

  @override
  String get loginResetNeedsEmail =>
      'Escreve primeiro o teu e-mail e envio-te o link para redefinir a palavra-passe.';

  @override
  String get loginResetSent =>
      'Enviei-te um e-mail para redefinir a palavra-passe.';

  @override
  String get loginResetError => 'Não foi possível enviar o e-mail';

  @override
  String get loginWelcomeBack => 'Olá de novo';

  @override
  String get loginCreateAccount => 'Cria a tua conta';

  @override
  String get loginTagline => 'PrezHome, a tua casa organizada';

  @override
  String loginContinueWith(String provider) {
    return 'Continuar com $provider';
  }

  @override
  String get loginOrEmail => 'ou com o teu e-mail';

  @override
  String get loginEmail => 'E-mail';

  @override
  String get loginEmailInvalid => 'Introduz um e-mail válido';

  @override
  String get loginPassword => 'Palavra-passe';

  @override
  String get loginShowPassword => 'Mostrar palavra-passe';

  @override
  String get loginHidePassword => 'Ocultar palavra-passe';

  @override
  String get loginPasswordShort => 'Mínimo 6 caracteres';

  @override
  String get loginForgot => 'Esqueceste-te da palavra-passe?';

  @override
  String get loginSignIn => 'Entrar';

  @override
  String get loginSignUp => 'Registar-me';

  @override
  String get loginNoAccount => 'Não tens conta? Regista-te';

  @override
  String get loginHaveAccount => 'Já tens conta? Inicia sessão';

  @override
  String get homeCodeFormat =>
      'O código tem 8 letras e números (por exemplo ABCD-EFGH).';

  @override
  String get homeSetupError => 'Não foi possível configurar a casa';

  @override
  String get homeLastStep => 'Último passo: a tua casa';

  @override
  String get homeCreateHint =>
      'Cria-a agora e, quando quiseres, convida quem vive contigo a partir de Hoje.';

  @override
  String get homeCreate => 'Criar a minha casa';

  @override
  String get homeInvited => 'Fui convidado para uma casa';

  @override
  String get homeInviteCode => 'Código de convite';

  @override
  String get homeJoin => 'Juntar-me a uma casa';

  @override
  String get sessionLoadError => 'Não foi possível carregar o teu perfil.';

  @override
  String get onbSectionHome => 'A tua casa';

  @override
  String get onbPeopleTitle => 'Quantas pessoas vivem convosco?';

  @override
  String get onbPeopleHint =>
      'Para calcular porções, compras e a divisão de tarefas.';

  @override
  String get onbSectionGoals => 'O que te ocupa';

  @override
  String get onbGoalsTitle => 'O que queres tirar da cabeça?';

  @override
  String get onbGoalsHint =>
      'Escolhe tudo o que quiseres. O resto fica escondido.';

  @override
  String get onbPickOne => 'Escolhe pelo menos uma';

  @override
  String onbContinueCount(int count) {
    return 'Continuar ($count)';
  }

  @override
  String get onbSectionKitchen => 'Na cozinha';

  @override
  String get onbCookingTitle => 'Como cozinham?';

  @override
  String get onbCookingHint =>
      'Assim sabemos se organizamos lotes e congelador.';

  @override
  String get onbSectionShopping => 'As compras';

  @override
  String get onbShopTitle => 'Onde fazes compras?';

  @override
  String get onbShopHint =>
      'O primeiro será o teu supermercado principal: as receitas usarão produtos fáceis de encontrar lá.';

  @override
  String get onbSkipSeeHome => 'Saltar e ver a minha casa';

  @override
  String get onbSeeHome => 'Ver a minha casa';

  @override
  String get onbSlogan => 'A casa em ordem, a cabeça tranquila.';

  @override
  String get onbStart => 'Começar';

  @override
  String get onbHaveAccount => 'Já tenho conta';

  @override
  String get onbOneLess => 'Uma a menos';

  @override
  String get onbOneMore => 'Uma a mais';

  @override
  String onbPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pessoas',
      one: 'Só eu',
    );
    return '$_temp0';
  }

  @override
  String get onbProfileBadge => 'O teu perfil de casa';

  @override
  String onbProfileName(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'solo': 'A Solo',
      'duo': 'O Duo',
      'tribu': 'A Tribo',
      'other': 'A Família',
    });
    return '$_temp0';
  }

  @override
  String onbProfileDescription(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'solo':
          'A casa toda depende de ti. O PrezHome lembra-se do que há, do que está a acabar o prazo e do que é preciso fazer, para que não tenhas de o fazer.',
      'duo':
          'Duas pessoas e uma casa. O PrezHome divide a carga à vista, para que ninguém tenha de guardar tudo na cabeça.',
      'other':
          'Muitas bocas e muitas coisas ao mesmo tempo. O PrezHome planeia refeições, compras e tarefas para todos, e lembra cada um do que lhe cabe.',
    });
    return '$_temp0';
  }

  @override
  String get onbLoadToday => 'Carga mental hoje';

  @override
  String get onbLoadWithApp => 'Com PrezHome';

  @override
  String onbLoad(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'high': 'pesada',
      'medium': 'média',
      'other': 'leve',
    });
    return '$_temp0';
  }

  @override
  String get onbCreateAccount => 'Criar a minha conta';

  @override
  String onbFeature(String f) {
    String _temp0 = intl.Intl.selectLogic(f, {
      'compra': 'Lista de compras',
      'comidas': 'O que comemos',
      'despensa': 'Despensa e validades',
      'tareas': 'Tarefas de casa',
      'other': 'Gastos da casa',
    });
    return '$_temp0';
  }

  @override
  String goalLabel(String g) {
    String _temp0 = intl.Intl.selectLogic(g, {
      'comidas': 'O que comemos',
      'compra': 'As compras',
      'despensa': 'O que há em casa',
      'tareas': 'Tarefas de casa',
      'lote': 'Cozinhar em lote',
      'other': 'Gastos da casa',
    });
    return '$_temp0';
  }

  @override
  String goalHint(String g) {
    String _temp0 = intl.Intl.selectLogic(g, {
      'comidas': 'Plano de refeições e receitas',
      'compra': 'Uma lista que se escreve sozinha',
      'despensa': 'Despensa, frigorífico e validades',
      'tareas': 'Divisão justa e lembretes',
      'lote': 'Caixas e congelador organizados',
      'other': 'Orçamento e talões',
    });
    return '$_temp0';
  }

  @override
  String cookingLabel(String c) {
    String _temp0 = intl.Intl.selectLogic(c, {
      'diario': 'Todos os dias',
      'lote': 'Em lote',
      'mixto': 'Um pouco de tudo',
      'other': 'Quase nunca',
    });
    return '$_temp0';
  }

  @override
  String cookingHint(String c) {
    String _temp0 = intl.Intl.selectLogic(c, {
      'diario': 'Cozinho na hora',
      'lote': 'Preparo vários dias de uma vez',
      'mixto': 'Alguns dias em lote',
      'other': 'Como fora ou algo rápido',
    });
    return '$_temp0';
  }

  @override
  String homeGreeting(String part) {
    String _temp0 = intl.Intl.selectLogic(part, {
      'morning': 'Bom dia',
      'afternoon': 'Boa tarde',
      'other': 'Boa noite',
    });
    return '$_temp0';
  }

  @override
  String get homeCustomize => 'Personalizar Hoje';

  @override
  String get homeYourData => 'Os teus dados';

  @override
  String get homeYourHome => 'A tua casa';

  @override
  String homeTodayTag(String meal) {
    return 'Hoje · $meal';
  }

  @override
  String mealType(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'breakfast': 'Pequeno-almoço',
      'lunch': 'Almoço',
      'snack': 'Lanche',
      'dinner': 'Jantar',
      'dessert': 'Sobremesa',
      'drink': 'Bebida',
      'other': 'Refeição',
    });
    return '$_temp0';
  }

  @override
  String get homeEatingOut => 'Fora de casa';

  @override
  String get homeWhatToEat => 'O que comemos hoje?';

  @override
  String get homeNothingPlanned => 'Ainda não há nada planeado para hoje.';

  @override
  String get homePlan => 'Planear';

  @override
  String get homeWithWhatIHave => 'Com o que tenho';

  @override
  String get homeExpiring => 'A expirar';

  @override
  String homeTasksToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tarefas hoje',
      one: 'Tarefa hoje',
    );
    return '$_temp0';
  }

  @override
  String get homeInShopping => 'Na lista';

  @override
  String get homeShortcuts => 'Atalhos';

  @override
  String get homeForToday => 'Para hoje';

  @override
  String get homeSeeAll => 'Ver tudo';

  @override
  String homePoints(int points) {
    return '$points pts';
  }

  @override
  String homePointsSnack(int points) {
    return '+$points pontos';
  }

  @override
  String get homeToday => 'Hoje';

  @override
  String get homeTomorrow => 'Amanhã';

  @override
  String get homeCaloriesTitle => 'Calcula o teu objetivo de calorias';

  @override
  String get homeCaloriesHint =>
      'Responde a umas perguntas rápidas e adapto o PrezHome a ti.';

  @override
  String homeOf(String total) {
    return 'de $total';
  }

  @override
  String get homeCaloriesToday => 'Calorias de hoje';

  @override
  String homeKcal(int kcal) {
    return '$kcal kcal';
  }

  @override
  String homeKcalLeft(int kcal) {
    return 'Faltam-te $kcal kcal';
  }

  @override
  String homeKcalOver(int kcal) {
    return 'Passaste $kcal kcal';
  }

  @override
  String get homeMonthSpend => 'Gasto do mês';

  @override
  String homeMoneyLeft(String amount) {
    return 'Faltam-te $amount';
  }

  @override
  String homeMoneyOver(String amount) {
    return 'Passaste $amount do orçamento';
  }

  @override
  String get save => 'Guardar';

  @override
  String get homeCardsSection => 'Cartões (arrasta para ordenar)';

  @override
  String get homeQuickSection => 'Acessos rápidos';

  @override
  String get homeQuickHint => 'Escolhe os atalhos que vês no topo de Hoje.';

  @override
  String dashCard(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'meals': 'Refeições de hoje',
      'calories': 'Calorias de hoje',
      'tasks': 'Tarefas',
      'other': 'Gasto do mês',
    });
    return '$_temp0';
  }

  @override
  String quickAction(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'add_inventory': 'Adicionar à despensa',
      'scan_ticket': 'Ler talão',
      'shopping': 'Lista de compras',
      'add_recipe': 'Nova receita',
      'meal_plan': 'Plano semanal',
      'other': 'Diário de calorias',
    });
    return '$_temp0';
  }

  @override
  String get shopPickStore => 'Escolher supermercado';

  @override
  String get shopAddFromPlan => 'Adicionar o plano da semana';

  @override
  String get shopListOptions => 'Opções da lista';

  @override
  String get shopAllInCart => 'Tudo no carrinho';

  @override
  String shopPending(int pending, int done) {
    return '$pending por comprar · $done no carrinho';
  }

  @override
  String shopUnpriced(int count) {
    return ' · $count sem preço';
  }

  @override
  String get shopAddProduct => 'Adicionar produto';

  @override
  String get shopSearchStore => 'Procurar no supermercado';

  @override
  String get moreOptions => 'Mais opções';

  @override
  String get less => 'Menos';

  @override
  String get more => 'Mais';

  @override
  String shopAdded(String name) {
    return '$name, adicionado';
  }

  @override
  String shopAdd(String name) {
    return 'Adicionar $name';
  }

  @override
  String get shopLiveOffline =>
      'Sem ligação em direto agora; atualiza ao recarregar.';

  @override
  String get couldNotUpdate => 'Não foi possível atualizar';

  @override
  String shopSavedToPantry(int count) {
    return '$count produtos guardados na despensa';
  }

  @override
  String get shopRemoveFromList => 'Tirar da lista';

  @override
  String shopRemovedOne(String name) {
    return 'Removido \"$name\"';
  }

  @override
  String get couldNotChangePhoto => 'Não foi possível mudar a foto';

  @override
  String get shopAddToList => 'Adicionar à lista';

  @override
  String get shopTypeFood => 'Comida';

  @override
  String get shopTypeHome => 'Casa/Limpeza';

  @override
  String get name => 'Nome';

  @override
  String get product => 'Produto';

  @override
  String get quantity => 'Quantidade';

  @override
  String get unit => 'Unidade';

  @override
  String get cancel => 'Cancelar';

  @override
  String get add => 'Adicionar';

  @override
  String get nameEmpty => 'O nome não pode estar vazio.';

  @override
  String get couldNotAdd => 'Não foi possível adicionar';

  @override
  String get shopPlanAllAtHome => 'Já tens em casa tudo o que o plano pede';

  @override
  String shopAddedFromPlan(int count) {
    return 'Adicionados $count produtos do plano';
  }

  @override
  String get shopListTitle => 'Lista de compras';

  @override
  String get shopMainList => 'Lista principal';

  @override
  String get couldNotCreateList => 'Não foi possível criar a lista';

  @override
  String get shopRecipesUseStore =>
      'As receitas vão usar produtos deste supermercado.';

  @override
  String get shopStoreSaveError =>
      'Não foi possível guardar o supermercado. Tenta novamente.';

  @override
  String get shopGroupByAisle => 'Agrupar por corredor';

  @override
  String get shopGroupHint => 'Legumes, carne, limpeza…';

  @override
  String get shopShowPhotos => 'Mostrar fotos dos produtos';

  @override
  String get shopMyLists => 'As minhas listas';

  @override
  String get categories => 'Categorias';

  @override
  String get shopFinish => 'Terminar compras';

  @override
  String shopFinishCount(int count) {
    return 'Terminar compras ($count)';
  }

  @override
  String get shopScanTicket => 'Ler talão';

  @override
  String get shopAllBought => 'Tudo comprado';

  @override
  String get shopToBuy => 'Por comprar';

  @override
  String get shopUsual => 'O habitual';

  @override
  String get shopInCart => 'No carrinho';

  @override
  String shopRemovedMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Removidos $count produtos',
      one: 'Removido 1 produto',
    );
    return '$_temp0';
  }

  @override
  String get couldNotRemove => 'Não foi possível remover';

  @override
  String get undo => 'Desfazer';

  @override
  String get couldNotUndo => 'Não foi possível desfazer';

  @override
  String get shopToCart => 'Para o carrinho';

  @override
  String get shopFromPlan => 'Do plano da semana';

  @override
  String get changePhoto => 'Mudar foto';

  @override
  String get shopEmptyTitle => 'A tua lista está vazia';

  @override
  String get shopEmptyHint =>
      'Escreve em cima o que precisas ou traz o do plano.';

  @override
  String get shopFromPlanAction => 'Do plano';

  @override
  String get shopDoneTitle => 'Compras concluídas';

  @override
  String get shopDoneHint => 'Já tens tudo o que está na lista. Bom trabalho!';

  @override
  String panUsedInOne(String meal) {
    return 'Retirado o que usaste em $meal';
  }

  @override
  String panUsedInMany(int count) {
    return 'Retirado o que usaste em $count refeições do plano';
  }

  @override
  String get view => 'Ver';

  @override
  String get couldNotDelete => 'Não foi possível eliminar';

  @override
  String panNoLongerShop(String name) {
    return '$name já não vai aparecer nas compras.';
  }

  @override
  String panBackToShop(String name) {
    return '$name vai voltar a aparecer nas compras.';
  }

  @override
  String panCouldNotMarkOut(String name) {
    return 'Não foi possível marcar $name como esgotado';
  }

  @override
  String panMarkedOut(String name) {
    return 'Marquei $name como esgotado.';
  }

  @override
  String panOutNotAdded(String name) {
    return '$name ficou esgotado, mas não consegui adicioná-lo às compras';
  }

  @override
  String panAlreadyInList(String name) {
    return '$name já está na tua lista de compras.';
  }

  @override
  String panAddedToShop(String name) {
    return 'Adicionei $name às compras';
  }

  @override
  String get panAddManual => 'Adicionar à mão';

  @override
  String get panScanBarcode => 'Ler código de barras';

  @override
  String get panFreezeDish => 'Prato cozinhado para o congelador';

  @override
  String get panFreezeDishHint => 'Escolhe a receita e quantas doses';

  @override
  String get panSaveRecipeFirst => 'Primeiro guarda uma receita.';

  @override
  String get panWhichDish => 'Que prato vais congelar?';

  @override
  String get panHowManyServings => 'Quantas doses congelas?';

  @override
  String get panTitle => 'Despensa e Frigorífico';

  @override
  String get panAddTooltip => 'Adicionar à despensa';

  @override
  String get panLoadError => 'Não foi possível carregar o inventário';

  @override
  String get panEmptyTitle => 'A tua despensa está vazia';

  @override
  String get panEmptyHint =>
      'Adiciona o que tens em casa ou risca as compras e aparece sozinho.';

  @override
  String get panAddProduct => 'Adicionar produto';

  @override
  String get panWhatToCook => 'O que cozinho com isto?';

  @override
  String get panExpiringHeader => 'Fora de prazo e quase a expirar';

  @override
  String get panNothingHere => 'Aqui não há nada.';

  @override
  String kitchenZone(String zone) {
    String _temp0 = intl.Intl.selectLogic(zone, {
      'nevera': 'Frigorífico',
      'congelador': 'Congelador',
      'despensa': 'Despensa',
      'bebidas': 'Bebidas',
      'especias': 'Condimentos',
      'limpieza': 'Limpeza',
      'hogar': 'Higiene e casa',
      'other': '$zone',
    });
    return '$_temp0';
  }

  @override
  String get kitchenReview => 'Rever';

  @override
  String expiryGroup(String group) {
    String _temp0 = intl.Intl.selectLogic(group, {
      'expired': 'Fora de prazo',
      'week': 'Esta semana',
      'later': 'Mais tarde',
      'other': 'Sem data',
    });
    return '$_temp0';
  }

  @override
  String panExpiredAgo(int days) {
    return 'Expirou há $days dias';
  }

  @override
  String get panExpiredYesterday => 'Expirou ontem';

  @override
  String get panExpiresToday => 'Expira hoje';

  @override
  String get panExpiresTomorrow => 'Expira amanhã';

  @override
  String panExpiresIn(int days) {
    return 'Expira em $days dias';
  }

  @override
  String panDays(int days) {
    return '$days dias';
  }

  @override
  String get panNotBought => 'Não se compra';

  @override
  String get panConsumed => 'Consumido';

  @override
  String get panToShopping => 'Para as compras';

  @override
  String panCouldNotAddToShop(String name) {
    return 'Não consegui adicionar $name às compras';
  }

  @override
  String panExpiredDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count produtos fora de prazo eliminados',
      one: 'Produto fora de prazo eliminado',
    );
    return '$_temp0';
  }

  @override
  String get panMyKitchen => 'A minha cozinha';

  @override
  String get panUsedHistory => 'O que se gastou';

  @override
  String get panNothingExpired => 'Nada fora de prazo';

  @override
  String panDeleteExpired(int count) {
    return 'Eliminar fora de prazo ($count)';
  }

  @override
  String panEmptyZone(String where) {
    return 'Esvaziar $where';
  }

  @override
  String panEmptyAsk(String where) {
    return 'Esvaziar $where?';
  }

  @override
  String panWillDelete(int count) {
    return 'Serão eliminados $count produtos.';
  }

  @override
  String get panEmpty => 'Esvaziar';

  @override
  String panDeleted(int count) {
    return '$count produtos eliminados';
  }

  @override
  String get edit => 'Editar';

  @override
  String get panShopAgain => 'Voltar a adicionar às compras';

  @override
  String get panDontShop => 'Não adicionar às compras';

  @override
  String get panStapleHint => 'Para básicos que tens sempre';

  @override
  String get panWillAddToShop => 'Vou adicioná-lo às compras';

  @override
  String get delete => 'Eliminar';

  @override
  String panDeleteAsk(String name) {
    return 'Eliminar $name?';
  }

  @override
  String panConsumedOn(String name, String day) {
    return '$name, consumido $day';
  }

  @override
  String get todayLower => 'hoje';

  @override
  String get yesterdayLower => 'ontem';

  @override
  String panOnDate(int day, int month) {
    return 'a $day/$month';
  }

  @override
  String get panWhen => 'Quando?';

  @override
  String get today => 'Hoje';

  @override
  String get yesterday => 'Ontem';

  @override
  String get panOtherDay => 'Outro dia';

  @override
  String get panWhichDay => 'Que dia?';

  @override
  String get panHowMany => 'Quantos?';

  @override
  String panAll(String qty) {
    return 'Tudo ($qty)';
  }

  @override
  String get couldNotLoad => 'Não foi possível carregar';

  @override
  String get panNothingYet => 'Ainda não há nada.';

  @override
  String get panWhenCooking => 'Ao cozinhar';

  @override
  String get planHowLong => 'Para quanto tempo?';

  @override
  String get thisWeek => 'Esta semana';

  @override
  String planWeeks(int count) {
    return '$count semanas';
  }

  @override
  String get planMonth4 => 'Um mês (4 semanas)';

  @override
  String get planPickDates => 'Escolher datas';

  @override
  String get planDates => 'Datas do plano';

  @override
  String get planMaxTwoMonths => 'No máximo dois meses de cada vez.';

  @override
  String get planReadyAllHome =>
      'Plano pronto. Já tens em casa tudo o que precisas';

  @override
  String planListReady(int count) {
    return 'Plano pronto. Lista de compras com $count produtos';
  }

  @override
  String get planBackInPlan => 'Voltou ao plano';

  @override
  String planEntryTitle(String meal, String recipe) {
    return '$meal · $recipe';
  }

  @override
  String get planNoRecipe => 'Sem receita';

  @override
  String get planChangeRecipe => 'Mudar receita';

  @override
  String get planWhoEats => 'Quem come';

  @override
  String get planMarkHome => 'Marcar em casa';

  @override
  String get planMarkOut => 'Marcar como fora';

  @override
  String get planStopRepeat => 'Deixar de repetir';

  @override
  String get planStopRepeatHint => 'Retira as próximas vezes';

  @override
  String get planRepeat => 'Repetir';

  @override
  String get planRepeatHint =>
      'Todos os dias, todas as semanas… ou para sempre';

  @override
  String get planRemove => 'Tirar do plano';

  @override
  String planRepeatTitle(String meal) {
    return 'Repetir $meal';
  }

  @override
  String get planHowOften => 'De quanto em quanto tempo?';

  @override
  String planEveryDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'De $days em $days dias',
      one: 'Todos os dias',
    );
    return '$_temp0';
  }

  @override
  String planEveryWeeks(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: 'De $weeks em $weeks semanas',
      one: 'Todas as semanas',
    );
    return '$_temp0';
  }

  @override
  String get planUntilWhen => 'Até quando?';

  @override
  String get planForever => 'Para sempre';

  @override
  String planMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count meses',
      one: '1 mês',
    );
    return '$_temp0';
  }

  @override
  String get planRepeatDone =>
      'Feito. Vais vê-lo no plano nas próximas semanas; se um dia já tiver outra coisa, mantém-se.';

  @override
  String get planWhoAtHome => 'Quem come em casa?';

  @override
  String get planCalendarPermission =>
      'Dá permissão ao calendário nas definições do telemóvel';

  @override
  String get planInFast => 'Calha no jejum';

  @override
  String get planSettings => 'Definições do plano';

  @override
  String get planBatchCook => 'Cozinho em lote';

  @override
  String get planBatchCookHint => 'Dia de compras, de cozinha e marmitas';

  @override
  String get planTimes => 'Horas';

  @override
  String get planFasting => 'Jejum intermitente';

  @override
  String get no => 'Não';

  @override
  String planEatWindow(String from, String to) {
    return 'Comes das $from às $to. Acompanha a hora do jantar.';
  }

  @override
  String get planCalendar => 'Calendário';

  @override
  String get planToCalendar => 'Passar para o calendário';

  @override
  String get planCalendarLinked => 'Calendário ligado';

  @override
  String get planCalendarHint =>
      'Refeições e tarefas com hora, no Google Calendar';

  @override
  String get planCalendarUpdates => 'Atualiza ao abrir o plano';

  @override
  String get remove => 'Remover';

  @override
  String get planPickRecipe => 'Escolhe uma receita';

  @override
  String get planDayFull => 'Esse dia já tem todas as refeições.';

  @override
  String get planWhichMeal => 'Que refeição adicionas?';

  @override
  String get planTitle => 'Plano semanal';

  @override
  String get planNoHome => 'Não pertences a nenhum lar.';

  @override
  String get planMake => 'Fazer plano';

  @override
  String get planRemake => 'Refazer plano';

  @override
  String get planNeedRecipes => 'Adiciona primeiro algumas receitas';

  @override
  String get planNeedRecipesHint =>
      'O planeador distribui as tuas receitas pela semana. Guarda algumas no separador Refeições.';

  @override
  String get planPrevWeek => 'Semana anterior';

  @override
  String get planNextWeekLabel => 'Próxima semana';

  @override
  String get planLastWeek => 'Semana passada';

  @override
  String get planWeek => 'Semana';

  @override
  String get planBackToToday => 'Voltar a hoje';

  @override
  String get planNextWeek => 'Semana seguinte';

  @override
  String get planDay => 'Dia';

  @override
  String get planMonthCalendar => 'Calendário do mês';

  @override
  String get planNoPlanYet => 'Ainda não há plano para esta semana.';

  @override
  String get recipe => 'Receita';

  @override
  String get planCookMode => 'Modo cozinha';

  @override
  String get planCookWeek => 'Cozinha a semana de uma vez';

  @override
  String get planBatch => 'Cozinha em lote';

  @override
  String planCookDays(int days, int recipes) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dias de cozinha',
      one: '1 dia de cozinha',
    );
    String _temp1 = intl.Intl.pluralLogic(
      recipes,
      locale: localeName,
      other: '$recipes receitas',
      one: '1 receita',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get planBatchEmpty =>
      'Com o plano feito digo-te quando comprar, quando cozinhar e o que vai para o frigorífico ou congelador.';

  @override
  String get planCookedToFreezer => 'Já cozinhado · para o congelador';

  @override
  String planFrozen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pratos guardados no congelador.',
      one: 'Guardado no congelador com a foto.',
    );
    return '$_temp0';
  }

  @override
  String get planEnergyLow => 'Pouco';

  @override
  String get planEnergyNormal => 'Normal';

  @override
  String get planEnergyHigh => 'Muito';

  @override
  String get planEnergyHint =>
      'Com \"pouco\" o plano recorre mais ao congelador.';

  @override
  String get planHowMuchCook => 'Quanto cozinhar';

  @override
  String planServings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count doses',
      one: '1 dose',
    );
    return '$_temp0';
  }

  @override
  String get close => 'Fechar';

  @override
  String get planSearchRecipe => 'Procurar receita...';

  @override
  String get planNoMatch => 'Sem receitas correspondentes.';

  @override
  String get diaDeleteError => 'Não foi possível apagar a refeição.';

  @override
  String get diaManual => 'À mão';

  @override
  String get diaManualHint => 'Escreve o nome e as calorias';

  @override
  String get diaFromRecipe => 'A partir de uma receita';

  @override
  String get diaFromRecipeHint => 'Regista uma receita tua como refeição';

  @override
  String get diaWithPhoto => 'Com uma foto';

  @override
  String get diaWithPhotoHint =>
      'Tira uma foto ao prato e calculamos as calorias';

  @override
  String get diaAddManual => 'Adicionar à mão';

  @override
  String get diaKcalField => 'Calorias (kcal)';

  @override
  String get diaMealTypeOptional => 'Tipo de refeição (opcional)';

  @override
  String get diaNoType => 'Sem tipo';

  @override
  String get diaProteinG => 'Proteína (g)';

  @override
  String get diaCarbsG => 'Hidratos (g)';

  @override
  String get diaFatG => 'Gordura (g)';

  @override
  String get diaNeedNameKcal => 'Indica pelo menos um nome e as calorias.';

  @override
  String get diaSaveError => 'Não foi possível guardar a refeição.';

  @override
  String get diaRecipesLoadError => 'Não foi possível carregar as receitas.';

  @override
  String get diaNoRecipes => 'Ainda não tens receitas para registar.';

  @override
  String diaKcalPerServing(int kcal) {
    return '$kcal kcal por dose';
  }

  @override
  String get diaNoKcal => 'Sem calorias registadas';

  @override
  String get diaServings => 'Doses';

  @override
  String get diaServingsError => 'Indica um número de doses maior que 0.';

  @override
  String get diaLog => 'Registar';

  @override
  String get diaRecipeLogError => 'Não foi possível registar a receita.';

  @override
  String get diaTitle => 'O meu diário';

  @override
  String get diaAddMeal => 'Adicionar refeição';

  @override
  String get previous => 'Anterior';

  @override
  String get next => 'Seguinte';

  @override
  String get diaDayCalories => 'Calorias do dia';

  @override
  String diaOfTarget(int kcal) {
    return 'de $kcal kcal';
  }

  @override
  String get diaNoTarget =>
      'Completa o teu perfil para definir um objetivo diário de calorias e ver quanto te falta cada dia.';

  @override
  String get diaCompleteProfile => 'Completar o meu perfil';

  @override
  String get diaOthers => 'Outras';

  @override
  String get diaMeal => 'Refeição';

  @override
  String get diaLast7 => 'Os teus últimos 7 dias';

  @override
  String diaTargetPerDay(int kcal) {
    return 'Objetivo: $kcal kcal por dia';
  }

  @override
  String get diaTarget => 'Objetivo';

  @override
  String get diaTodaySplit => 'Distribuição de hoje';

  @override
  String get diaNoMacros => 'Ainda não há macros registados hoje.';

  @override
  String get diaProtein => 'Proteína';

  @override
  String get diaCarbs => 'Hidratos';

  @override
  String get diaFat => 'Gordura';

  @override
  String get diaAteThePlan => 'Comeste o que estava no plano?';

  @override
  String diaAskLine(String day, String meal, String name, int kcal) {
    return '$day, $meal: $name · $kcal kcal';
  }

  @override
  String get yes => 'Sim';

  @override
  String get diaAnswerError => 'Não foi possível guardar a resposta.';

  @override
  String get diaAskFirst => 'Perguntar-me antes de registar o plano';

  @override
  String get diaAskOn => 'Perguntamos se comeste cada refeição do plano.';

  @override
  String get diaAskOff =>
      'As refeições do plano registam-se sozinhas depois da hora.';

  @override
  String get diaSettingError => 'Não foi possível guardar a definição.';

  @override
  String get diaEmpty =>
      'Ainda não registaste nada neste dia.\nAdiciona a tua primeira refeição.';

  @override
  String get recUnfavorite => 'Remover dos favoritos';

  @override
  String get recFavorite => 'Marcar como favorita';

  @override
  String get recDelete => 'Eliminar receita';

  @override
  String get recDeleteAsk => 'Eliminar receita?';

  @override
  String recRemoveAsk(String name) {
    return '\"$name\" e os seus ingredientes serão apagados.';
  }

  @override
  String recDeleted(String name) {
    return '\"$name\" eliminada.';
  }

  @override
  String get recTitle => 'Receitas';

  @override
  String get recNew => 'Nova receita';

  @override
  String get recLoadError => 'Não consegui carregar as receitas';

  @override
  String get recEmptyTitle => 'Ainda não há receitas';

  @override
  String get recEmptyHint => 'Cria a primeira ou pede ideias com o que tens.';

  @override
  String get recIdeas => 'Ideias com o que tenho';

  @override
  String get recNoResults => 'Sem resultados';

  @override
  String recCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count receitas',
      one: '1 receita',
    );
    return '$_temp0';
  }

  @override
  String get recWhatToCook => 'O que cozinho com o que tenho?';

  @override
  String get recPantryIdeas => 'Ideias com o que há na tua despensa';

  @override
  String get recAll => 'Todas';

  @override
  String get recFavorites => 'Favoritas';

  @override
  String get recNoFilter =>
      'Não há receitas com este filtro.\nExperimenta outra categoria.';

  @override
  String get clear => 'Limpar';

  @override
  String recNoMatch(String query) {
    return 'Não há receitas que correspondam a\n\"$query\".';
  }
}
