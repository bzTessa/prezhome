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
  String get loginConfirmEmailSent =>
      'Enviámos-te um e-mail para confirmar a conta. Abre-o neste telemóvel e entras automaticamente.';

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
  String get shopShowIcons => 'Mostrar desenhos quando não há foto';

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

  @override
  String get rdPhoto => 'Foto da receita';

  @override
  String get rdAutoPhoto => 'Procurar outra foto automática';

  @override
  String get rdAutoPhotoHint => 'Procura uma imagem nova pelo nome';

  @override
  String get rdGallery => 'Escolher da galeria';

  @override
  String get rdNoBetterPhoto => 'Não encontrei outra foto melhor por agora';

  @override
  String get rdUploadError => 'Não foi possível carregar a foto';

  @override
  String rdShareText(String title, String code) {
    return 'Envio-te a minha receita de $title no PrezHome. Na app, vai a Receitas, toca em Adicionar receita e depois Com um código: $code';
  }

  @override
  String get rdSavedFreezer => 'Guardado no congelador.';

  @override
  String get couldNotSave => 'Não foi possível guardar';

  @override
  String get rdVideoError => 'Não foi possível abrir a ligação do vídeo';

  @override
  String get rdWatchVideo => 'Ver vídeo';

  @override
  String get share => 'Partilhar';

  @override
  String get rdEdit => 'Editar receita';

  @override
  String get rdMinutes => 'Minutos';

  @override
  String get rdKcalServing => 'Kcal/dose';

  @override
  String get rdPerServingShort => 'por dose';

  @override
  String rdServingWord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Doses',
      one: 'Dose',
    );
    return '$_temp0';
  }

  @override
  String get rdFreezable => 'Congelável';

  @override
  String get rdIngredients => 'Ingredientes';

  @override
  String get rdStepsWord => 'Passos';

  @override
  String rdSteps(int count) {
    return 'Passos ($count)';
  }

  @override
  String get rdNutrition => 'Nutrição';

  @override
  String get rdNoIngredients => 'Sem ingredientes registados.';

  @override
  String rdOriginal(String servings) {
    return 'Receita original: $servings';
  }

  @override
  String rdForHome(String servings) {
    return 'Para o teu lar hoje: $servings';
  }

  @override
  String get rdHaveAll => 'Tens tudo em casa';

  @override
  String rdHaveSome(int have, int total) {
    return 'Tens $have de $total em casa';
  }

  @override
  String rdMissing(int count) {
    return 'Faltam $count';
  }

  @override
  String get rdAtHome => 'Em casa';

  @override
  String get rdLacking => 'Falta';

  @override
  String get rdNoSteps =>
      'Esta receita não tem passos. Podes adicioná-los ao editá-la.';

  @override
  String get rdPerServingTitle => 'Por dose';

  @override
  String get rdNoNutrition => 'Sem dados nutricionais.';

  @override
  String rdPerServing(String amount) {
    return '$amount por dose';
  }

  @override
  String rdTotal(String amount) {
    return '≈ $amount no total';
  }

  @override
  String get rdApproxCost =>
      'Custo aproximado. Lê talões para o afinar com os teus preços reais.';

  @override
  String get rdStartCooking => 'Começar a cozinhar';

  @override
  String rdAddedMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Adicionados $count produtos às compras',
      one: 'Adicionado à lista de compras',
    );
    return '$_temp0';
  }

  @override
  String get rdNeedProfile =>
      'Completa um Perfil Nutricional para ver quantos gramas e calorias cabem a cada pessoa.';

  @override
  String get rdMember => 'Membro';

  @override
  String get rdAdjustSplit =>
      'Ajusta a distribuição de calorias por refeição no perfil para este tipo de receita.';

  @override
  String get rdByProfile => 'Segundo o perfil de cada um';

  @override
  String get rdByProfileHint =>
      'Quantidade e calorias por pessoa para esta refeição.';

  @override
  String get arWriteName => 'Escreve o nome';

  @override
  String get arWriteNameHint => 'Escreve o nome ou cola uma receita inteira…';

  @override
  String get arGenerate => 'Gerar';

  @override
  String get arFilled => 'Receita preenchida. Revê-a antes de guardar.';

  @override
  String get arFillError => 'Não foi possível completar a receita';

  @override
  String get arImport => 'Importar receita';

  @override
  String get arPasteRecipe => 'Cola a receita';

  @override
  String get arImportHint =>
      'Cola a ligação do TikTok, YouTube ou de um site, ou o texto da receita. No Instagram copia a descrição do post e cola-a aqui.';

  @override
  String get arLinkOrText => 'Ligação ou texto da receita';

  @override
  String get arRecipeText => 'Texto da receita';

  @override
  String get paste => 'Colar';

  @override
  String get arImportBtn => 'Importar';

  @override
  String get arNeedLink => 'Cola uma ligação ou o texto completo da receita.';

  @override
  String get arImported => 'Receita importada. Revê-a antes de guardar.';

  @override
  String get arImportLinkError =>
      'Não consegui importar a receita dessa ligação';

  @override
  String get arImportError => 'Não foi possível importar';

  @override
  String get arPickMealType => 'Escolhe pelo menos um tipo de refeição.';

  @override
  String get arVideoNotUrl =>
      'A ligação do vídeo não parece um URL, mas guardamos na mesma.';

  @override
  String get arRecalculated =>
      'Calorias e macros recalculadas com os ingredientes.';

  @override
  String arPhotoFailed(String error) {
    return 'Receita guardada, mas não foi possível carregar a foto: $error';
  }

  @override
  String get arSaveError => 'Erro ao guardar';

  @override
  String get arReadingVideo => 'A ler a receita do vídeo…';

  @override
  String get arCompleting => 'A completar a receita…';

  @override
  String get arAddPhoto => 'Adicionar foto (opcional)';

  @override
  String get arTitleField => 'Título';

  @override
  String get arTitleRequired => 'Dá-lhe um título';

  @override
  String get arDescription => 'Descrição (opcional)';

  @override
  String get arVideoLink => 'Ligação de vídeo (opcional)';

  @override
  String get arMealTypes => 'Tipo de refeição (podes escolher vários)';

  @override
  String get arAuto => 'Auto';

  @override
  String get arServingsHelper => 'Para quantas é';

  @override
  String get arGramsServing => 'Gramas / dose';

  @override
  String get arNutritionTitle => 'Valores nutricionais (por dose)';

  @override
  String get arCooking => 'Cozinha';

  @override
  String get arPrepMin => 'Preparação (min)';

  @override
  String get arCookMin => 'Cozedura (min)';

  @override
  String get arAppliance => 'Aparelho principal';

  @override
  String get arFreezable => 'É congelável';

  @override
  String get arAddIngredient => 'Adicionar ingrediente';

  @override
  String get arStepsTitle => 'Passos de preparação';

  @override
  String get arStepsHint => 'Escreve os passos, um por linha…';

  @override
  String get arSaveChanges => 'Guardar alterações';

  @override
  String get arSaveRecipe => 'Guardar receita';

  @override
  String get arIngredient => 'Ingrediente';

  @override
  String get tskWhoDid => 'Quem fez a tarefa?';

  @override
  String get tskTheHome => 'o lar';

  @override
  String tskPointsFor(int points, String who) {
    return '+$points pontos para $who';
  }

  @override
  String tskPointsForPantry(int points, String who, int count) {
    return '+$points pontos para $who. $count produtos para a despensa';
  }

  @override
  String tskYou(String name) {
    return '$name (tu)';
  }

  @override
  String get tskThisMember => 'este membro';

  @override
  String get tskResetPoints => 'Repor pontos';

  @override
  String tskResetAsk(String name) {
    return 'Os pontos de $name vão ficar a 0. Isto não se pode desfazer. Tens a certeza?';
  }

  @override
  String get tskReset => 'Repor';

  @override
  String tskResetDone(String name) {
    return 'Pontos de $name repostos.';
  }

  @override
  String get tskDeleteTitle => 'Eliminar tarefa?';

  @override
  String tskDeleteAsk(String title) {
    return '\"$title\" será apagada.';
  }

  @override
  String tskClaimed(String title) {
    return '\"$title\" é tua';
  }

  @override
  String get tskDone => 'Feita';

  @override
  String get tskToTomorrow => 'Passar para amanhã';

  @override
  String get tskToNextWeek => 'Passar para a próxima semana';

  @override
  String get tskTitle => 'Tarefas';

  @override
  String get tskEmptyTitle => 'Ainda não há tarefas';

  @override
  String get tskEmptyHint => 'Adiciona a primeira.';

  @override
  String get tskNew => 'Nova tarefa';

  @override
  String get tskAnyone => 'Qualquer um';

  @override
  String get tskForToday => 'Para hoje';

  @override
  String get tskUpcoming => 'Próximos dias';

  @override
  String get tskPoolEmpty => 'Nada no saco. Tudo tem dono.';

  @override
  String get tskSwipeToClaim => 'Desliza para a esquerda para a pedires.';

  @override
  String get tskNothingDone => 'Hoje ainda não há nada feito.';

  @override
  String get tskAll => 'Todas';

  @override
  String get tskMine => 'Minhas';

  @override
  String get tskAllDoneToday => 'Hoje está tudo feito';

  @override
  String get tskNextBelow => 'O seguinte, em baixo.';

  @override
  String get tskNothingLeft => 'Não falta nada.';

  @override
  String get tskScoreboard => 'PLACAR';

  @override
  String get tskPointsPerPerson => 'PONTOS POR PESSOA';

  @override
  String get tskNoPoints => 'Ainda não há pontos';

  @override
  String get tskNoPointsHint => 'Completa tarefas para ir somando.';

  @override
  String get tskSomeDays => 'Alguns dias';

  @override
  String get tskOnce => 'Uma vez';

  @override
  String get tskNothingToday => 'Nada para hoje';

  @override
  String get tskAllDone => 'Tudo feito';

  @override
  String tskLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Faltam $count',
      one: 'Falta 1',
    );
    return '$_temp0';
  }

  @override
  String tskOverdueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count atrasadas',
      one: '1 atrasada',
    );
    return '$_temp0';
  }

  @override
  String tskMarkDone(String title) {
    return 'Marcar $title como feita';
  }

  @override
  String tskClaim(String title) {
    return 'Ficar com $title';
  }

  @override
  String get tskOverdue => 'Atrasada';

  @override
  String tskPts(int points) {
    return '$points pts';
  }

  @override
  String tskView(String view) {
    String _temp0 = intl.Intl.selectLogic(view, {
      'pending': 'Pendentes',
      'pool': 'Saco',
      'other': 'Feitas',
    });
    return '$_temp0';
  }

  @override
  String get tskOtherDay => 'Outro dia';

  @override
  String get tskEdit => 'Editar tarefa';

  @override
  String get tskNameHint => 'Nome da tarefa';

  @override
  String get tskOrTypeAnother => 'Ou escreve outra';

  @override
  String get tskWhen => 'Quando';

  @override
  String get tomorrow => 'Amanhã';

  @override
  String get tskNoDate => 'Sem data';

  @override
  String get tskRepeats => 'Repete-se';

  @override
  String get tskWho => 'Quem';

  @override
  String get tskMe => 'Eu';

  @override
  String get tskAddPersonHint =>
      'Para a atribuir a alguém, adiciona essa pessoa em Lar (mesmo sem conta).';

  @override
  String get tskDetails => 'Detalhes';

  @override
  String get tskNoTime => 'Sem hora';

  @override
  String get tskRemoveTime => 'Tirar hora';

  @override
  String tskFreeAt(String time) {
    return 'Livre às $time';
  }

  @override
  String get tskNotes => 'Notas';

  @override
  String get tskPoints => 'Pontos';

  @override
  String get tskAdd => 'Adicionar tarefa';

  @override
  String get arcTitle => 'Adicionar receita';

  @override
  String get arcLinkTitle => 'Colar link de vídeo';

  @override
  String get arcLinkSub => 'Do TikTok ou YouTube, ou o texto do Instagram';

  @override
  String get arcNameTitle => 'Escreve o nome';

  @override
  String get arcNameSub => 'Completa-se com ingredientes, passos e macros';

  @override
  String get arcIdeasTitle => 'Ideias para ti';

  @override
  String get arcIdeasSub => 'Segundo o teu supermercado, objetivo e orçamento';

  @override
  String get arcManualTitle => 'À mão';

  @override
  String get arcManualSub => 'Preenche tu cada campo';

  @override
  String get arcCodeTitle => 'Com um código';

  @override
  String get arcCodeSub => 'Guarda uma receita que partilharam contigo';

  @override
  String get arcCodeDialog => 'Código da receita';

  @override
  String get search => 'Pesquisar';

  @override
  String get arcNoCode => 'Não há nenhuma receita com esse código';

  @override
  String arcIngredientsAsk(int count) {
    return '$count ingredientes. Guardas nas tuas receitas?';
  }

  @override
  String get arcSaved => 'Receita guardada';

  @override
  String get nutLoadError => 'Erro ao carregar o perfil';

  @override
  String get nutSaved => 'Perfil guardado';

  @override
  String get nutSaveError => 'Erro ao guardar';

  @override
  String get nutBirthDate => 'Data de nascimento';

  @override
  String get nutTitle => 'O meu perfil nutricional';

  @override
  String get nutDiary => 'Diário de calorias';

  @override
  String get nutWizard => 'Configurar passo a passo';

  @override
  String get nutWizardSub =>
      'Um assistente faz-te umas perguntas e calcula o teu objetivo.';

  @override
  String get nutHowCook => 'Como cozinhas?';

  @override
  String get nutDaily => 'Do dia';

  @override
  String get nutDailySub => 'Cozinho todos os dias';

  @override
  String get nutBatch => 'Cozinhar em lote';

  @override
  String get nutBatchSub => 'Cozinho de uma vez para vários dias';

  @override
  String get nutAmounts => 'Quantidades';

  @override
  String get nutPractical => 'Práticas';

  @override
  String get nutPracticalSub => 'Formatos do supermercado';

  @override
  String get nutExact => 'Exatas';

  @override
  String get nutExactSub => 'Ao grama';

  @override
  String get nutSex => 'Sexo';

  @override
  String get nutFemale => 'Mulher';

  @override
  String get nutMale => 'Homem';

  @override
  String get nutSelect => 'Selecionar…';

  @override
  String nutAge(int age) {
    return '($age anos)';
  }

  @override
  String get nutHeight => 'Altura (cm)';

  @override
  String get nutWeight => 'Peso (kg)';

  @override
  String get nutActivityLevel => 'Nível de atividade';

  @override
  String get nutGoalLabel => 'Objetivo';

  @override
  String nutActivity(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'sedentary': 'Sedentário (pouco ou nenhum exercício)',
      'light': 'Ligeiro (1-3 dias/semana)',
      'moderate': 'Moderado (3-5 dias/semana)',
      'active': 'Ativo (6-7 dias/semana)',
      'other': 'Muito ativo (exercício intenso ou trabalho físico)',
    });
    return '$_temp0';
  }

  @override
  String nutGoal(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'lose': 'Perder peso',
      'gain': 'Ganhar peso',
      'other': 'Manter o peso',
    });
    return '$_temp0';
  }

  @override
  String get nutSplit => 'Distribuição de calorias por refeição';

  @override
  String nutTotal(int pct) {
    return 'Total: $pct%';
  }

  @override
  String get nutSplitHint =>
      'Põe 0% nas refeições que não fazes. A soma deve ser 100%.';

  @override
  String get nutAtHome => 'Refeições em casa';

  @override
  String get nutAtHomeHint =>
      'Marca os dias em que fazes cada refeição em casa. Se comes fora (p. ex. no trabalho), desmarca esse dia e não conta.';

  @override
  String get nutShare => 'Partilhar o meu perfil com o lar';

  @override
  String get nutShareSub => 'Se estiver desativado, o teu perfil é privado.';

  @override
  String get nutSave => 'Guardar perfil';

  @override
  String get nutIncomplete =>
      'Completa sexo, data de nascimento, altura e peso para calcular as tuas calorias e macros diários.';

  @override
  String get nutDailyTarget => 'O teu objetivo diário (aprox.)';

  @override
  String nutKcalDay(int kcal) {
    return '$kcal kcal / dia';
  }

  @override
  String nutPerMeal(int kcal, int meals) {
    return '≈ $kcal kcal por refeição ($meals refeições)';
  }

  @override
  String get ecoBudgetTitle => 'Orçamento mensal';

  @override
  String ecoAmount(String symbol) {
    return 'Valor ($symbol)';
  }

  @override
  String get ecoDeleteTicket => 'Eliminar talão?';

  @override
  String get ecoDeleteTicketSub => 'Deixará de contar nos teus gastos.';

  @override
  String ecoRedeemed(String title) {
    return 'Trocaste \"$title\"';
  }

  @override
  String get ecoRedeemFail => 'Não foi possível trocar. Talvez te falte saldo.';

  @override
  String get ecoNewReward => 'Nova recompensa';

  @override
  String get ecoRewardTitle => 'Título';

  @override
  String get ecoRewardDesc => 'Descrição (opcional)';

  @override
  String get ecoRewardCost => 'Custo em pontos';

  @override
  String get ecoTitle => 'Gastos e talões';

  @override
  String get ecoStats => 'Estatísticas das compras';

  @override
  String get ecoScan => 'Digitalizar talão';

  @override
  String ecoTicketsOf(String month) {
    return 'Talões de $month';
  }

  @override
  String get ecoPointsBalance => 'Balança de pontos';

  @override
  String get ecoPointsBalanceSub =>
      'Saldo de cada membro para trocar recompensas.';

  @override
  String get ecoNoPoints => 'Ainda não há pontos para repartir';

  @override
  String get ecoNoPointsSub =>
      'Completem tarefas do lar para encher a balança.';

  @override
  String get ecoRewards => 'Recompensas';

  @override
  String ecoBalance(int points) {
    return 'O teu saldo: $points pts';
  }

  @override
  String get ecoRedeem => 'Trocar';

  @override
  String get ecoNoRewards => 'Ainda não há recompensas';

  @override
  String get ecoNoRewardsSub =>
      'Cria a primeira com o botão \"Nova recompensa\".';

  @override
  String get ecoTotalSpent => 'Gasto total registado';

  @override
  String ecoTicketCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count talões no total',
      one: '1 talão no total',
    );
    return '$_temp0';
  }

  @override
  String get ecoThisMonth => 'Este mês';

  @override
  String ecoBudget(String amount) {
    return 'Orçamento: $amount';
  }

  @override
  String get ecoSetBudget => 'Definir orçamento';

  @override
  String ecoOver(String amount) {
    return 'Passaste $amount do orçamento';
  }

  @override
  String ecoLeft(String amount) {
    return 'Restam-te $amount';
  }

  @override
  String get ecoLastMonths => 'Gasto dos últimos meses';

  @override
  String ecoBudgetPerMonth(String amount) {
    return 'Orçamento: $amount por mês';
  }

  @override
  String get ecoBudgetShort => 'Orçamento';

  @override
  String get ecoNoTrend =>
      'Ainda não há gasto registado nos últimos meses.\nQuando digitalizares talões verás aqui a tua tendência.';

  @override
  String get ecoTicket => 'Talão';

  @override
  String get ecoNoTickets =>
      'Ainda não há talões este mês.\nDigitaliza o primeiro.';

  @override
  String get stOthers => 'Outros';

  @override
  String get stNoCategory => 'Sem categoria';

  @override
  String get stThisWeek => 'Esta';

  @override
  String get stTitle => 'Os teus dados';

  @override
  String get stSpendByMonth => 'Gasto por mês';

  @override
  String get stForecastFooter => 'Em claro, o que falta para a previsão';

  @override
  String get stNoSpend => 'Digitaliza um talão e verás o teu gasto mês a mês.';

  @override
  String get stWhereSpend => 'Em que gastas este mês';

  @override
  String get stNoTicketsMonth => 'Ainda não há talões este mês.';

  @override
  String get stTopProducts => 'O que mais compras';

  @override
  String get stTopProductsFooter => 'Vezes nos teus talões dos últimos 3 meses';

  @override
  String get stTopProductsEmpty => 'Aparece quando digitalizares talões.';

  @override
  String get stPantry => 'A tua despensa';

  @override
  String get stMealsHome => 'Refeições em casa';

  @override
  String get stPerWeek => 'Por semana';

  @override
  String stMealsOut(int count) {
    return 'Por semana · $count fora de casa';
  }

  @override
  String get stMealsEmpty => 'Planeia refeições e verás quantas fazem em casa.';

  @override
  String get stTasksDone => 'Tarefas feitas';

  @override
  String get stTasksFooter => 'Por semana e quem fez mais este mês';

  @override
  String get stTasksEmpty => 'Quando completarem tarefas aparecem aqui.';

  @override
  String get stSoFar => 'Gastaste este mês';

  @override
  String get stForecast => 'Previsão: ';

  @override
  String stMoreThanAvg(int pct) {
    return ', $pct% acima da tua média';
  }

  @override
  String stLessThanAvg(int pct) {
    return ', $pct% abaixo da tua média';
  }

  @override
  String get stTickets => 'Talões';

  @override
  String get stExpired => 'Fora de prazo';

  @override
  String get stExpiringSoon => 'Expira em breve';

  @override
  String get stFresh => 'Bem';

  @override
  String stOverForecast(String amount) {
    return 'A este ritmo vais passar $amount do orçamento';
  }

  @override
  String stForecastTip(String amount) {
    return 'Previsão $amount';
  }

  @override
  String get pwPickOption => 'Escolhe uma opção para continuar.';

  @override
  String get pwPickBirth => 'Seleciona a tua data de nascimento.';

  @override
  String get pwBadHeight => 'Escreve uma altura válida em centímetros.';

  @override
  String get pwBadWeight => 'Escreve um peso válido em quilos.';

  @override
  String get pwCompleteStep => 'Completa este passo para continuar.';

  @override
  String get pwStart => 'Começar a usar o PrezHome';

  @override
  String get pwSeeGoal => 'Ver o meu objetivo';

  @override
  String get pwFinish => 'Terminar';

  @override
  String get pwIntroTitle => 'Vamos conhecer-te';

  @override
  String get pwIntroSub =>
      'Umas perguntas rápidas para adaptar o PrezHome a ti. Podes mudar quando quiseres.';

  @override
  String get pwTrackKcal => 'Quero contar as calorias';

  @override
  String get pwTrackKcalSub =>
      'As refeições do plano registam-se sozinhas quando passam.';

  @override
  String get pwOnlyHome => 'Só organizar a casa';

  @override
  String get pwOnlyHomeSub => 'Sem peso nem medidas.';

  @override
  String get pwSex => 'O teu sexo';

  @override
  String get pwSexSub =>
      'Usamo-lo para calcular o teu metabolismo com mais precisão.';

  @override
  String get pwPickDate => 'Selecionar data';

  @override
  String get pwBirthTitle => 'Quando nasceste?';

  @override
  String get pwBirthSub => 'A idade ajuda-nos a afinar o cálculo de calorias.';

  @override
  String pwAgeYears(int age) {
    return '$age anos';
  }

  @override
  String get pwHeightTitle => 'Quanto medes?';

  @override
  String get pwHeightSub => 'Indica a tua altura em centímetros.';

  @override
  String get pwWeightTitle => 'Quanto pesas?';

  @override
  String get pwWeightSub => 'Indica o teu peso atual em quilos.';

  @override
  String get pwActivityTitle => 'O teu nível de atividade';

  @override
  String get pwActivitySub =>
      'Escolhe a opção que melhor descreve a tua semana.';

  @override
  String get pwGoalTitle => 'Qual é o teu objetivo?';

  @override
  String get pwGoalSub => 'Ajustamos as tuas calorias ao que queres conseguir.';

  @override
  String pwGoalDesc(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'lose': 'Défice suave para perder peso aos poucos.',
      'gain': 'Excedente suave para ganhar massa de forma saudável.',
      'other': 'Manter o teu peso atual e sentir-te bem.',
    });
    return '$_temp0';
  }

  @override
  String get pwDietTitle => 'Como te alimentas?';

  @override
  String get pwDietSub => 'As receitas adaptam-se à tua dieta.';

  @override
  String pwDiet(String diet) {
    String _temp0 = intl.Intl.selectLogic(diet, {
      'vegetariana': 'Vegetariana',
      'vegana': 'Vegana',
      'pescetariana': 'Pescetariana',
      'baja_carbo': 'Baixa em hidratos',
      'sin_gluten': 'Sem glúten',
      'other': 'De tudo',
    });
    return '$_temp0';
  }

  @override
  String get pwAllergiesTitle => 'Alergias ou intolerâncias';

  @override
  String get pwOptional => 'Opcional.';

  @override
  String pwAllergy(String allergy) {
    String _temp0 = intl.Intl.selectLogic(allergy, {
      'frutossecos': 'frutos secos',
      'lactosa': 'lactose',
      'gluten': 'glúten (doença celíaca)',
      'huevo': 'ovo',
      'marisco': 'marisco',
      'soja': 'soja',
      'other': 'peixe',
    });
    return '$_temp0';
  }

  @override
  String get pwCuisinesTitle => 'O que gostas de comer?';

  @override
  String get pwCuisinesSub => 'Escolhe as que quiseres.';

  @override
  String pwCuisine(String cuisine) {
    String _temp0 = intl.Intl.selectLogic(cuisine, {
      'casera': 'Caseira de sempre',
      'mediterranea': 'Mediterrânica',
      'ligera': 'Leve',
      'rapida': 'Rápida e simples',
      'italiana': 'Italiana',
      'asiatica': 'Asiática',
      'mexicana': 'Mexicana',
      'other': 'De todo o mundo',
    });
    return '$_temp0';
  }

  @override
  String get pwAppliancesTitle => 'O que tens na cozinha?';

  @override
  String get pwAppliancesSub => 'O plano só usa receitas que consegues fazer.';

  @override
  String appliance(String appliance) {
    String _temp0 = intl.Intl.selectLogic(appliance, {
      'oven': 'Forno',
      'stovetop': 'Frigideira',
      'pot': 'Panela',
      'airfryer': 'Airfryer',
      'microwave': 'Micro-ondas',
      'blender': 'Varinha',
      'other': 'Nenhum',
    });
    return '$_temp0';
  }

  @override
  String get pwDislikedTitle => 'Ingredientes de que não gostas';

  @override
  String get pwDislikedSub => 'Separados por vírgulas. Opcional.';

  @override
  String get pwDislikedHint => 'cebola, coentros...';

  @override
  String get pwCookTimeTitle => 'Quanto tempo queres cozinhar?';

  @override
  String get pwCookTimeSub =>
      'Assim ajusto as receitas ao teu ritmo. Podes deixar sem escolher.';

  @override
  String pwCookTime(String time) {
    String _temp0 = intl.Intl.selectLogic(time, {
      'rapido': 'Rápido (menos de 20 min)',
      'elaborado': 'Elaborado (gosto de cozinhar)',
      'other': 'Normal',
    });
    return '$_temp0';
  }

  @override
  String pwCookTimeDesc(String time) {
    String _temp0 = intl.Intl.selectLogic(time, {
      'rapido': 'Pratos feitos em pouco tempo.',
      'elaborado': 'Gosto de cozinhar com calma.',
      'other': 'Um equilíbrio entre rápido e elaborado.',
    });
    return '$_temp0';
  }

  @override
  String get pwCookStyleTitle => 'Como preferes cozinhar?';

  @override
  String get pwChangeAnytime => 'Podes mudar quando quiseres.';

  @override
  String cookStyle(String style) {
    String _temp0 = intl.Intl.selectLogic(style, {
      'batch': 'Em lote',
      'mixed': 'Misto',
      'other': 'Diário',
    });
    return '$_temp0';
  }

  @override
  String cookStyleSub(String style) {
    String _temp0 = intl.Intl.selectLogic(style, {
      'batch': 'Cozinho em lotes para vários dias',
      'mixed': 'Combino lotes e cozinha do dia',
      'other': 'Cozinho todos os dias na hora',
    });
    return '$_temp0';
  }

  @override
  String get pwModulesTitle => 'O que queres ativar?';

  @override
  String get pwModulesSub => 'O que desligares não aparece.';

  @override
  String homeModule(String module) {
    String _temp0 = intl.Intl.selectLogic(module, {
      'points': 'Modo pontos',
      'tasks': 'Tarefas',
      'other': 'Cozinha em lote',
    });
    return '$_temp0';
  }

  @override
  String homeModuleDesc(String module) {
    String _temp0 = intl.Intl.selectLogic(module, {
      'points': 'Ganha pontos e recompensas pelas tuas tarefas.',
      'tasks': 'Organiza as tarefas do lar.',
      'other': 'Cozinha em lotes e planeia preparações.',
    });
    return '$_temp0';
  }

  @override
  String get pwAllSet => 'Tudo pronto';

  @override
  String get pwAllSetSub =>
      'Receitas, plano e compras adaptam-se ao que contaste.';

  @override
  String get pwDailyGoal => 'O teu objetivo diário';

  @override
  String get pwKcalDay => 'kcal / dia';

  @override
  String get pwEstimate =>
      'É uma estimativa para começar. As refeições do plano registam-se sozinhas no diário quando passarem.';

  @override
  String get phCantAnalyze => 'Não foi possível analisar a refeição';

  @override
  String phAnalyzeError(String error) {
    return 'Erro ao analisar a foto: $error';
  }

  @override
  String get phAnalyzeFail => 'Erro ao analisar a foto';

  @override
  String get phAddOne => 'Adiciona pelo menos um alimento com nome.';

  @override
  String get phTitle => 'Registar com foto';

  @override
  String get phLooking => 'A olhar para o prato…';

  @override
  String get phStartTitle => 'Tira uma foto ao teu prato';

  @override
  String get phStartSub =>
      'Calculamos os alimentos e as calorias. Podes corrigir antes de guardar.';

  @override
  String get takePhoto => 'Tirar foto';

  @override
  String get phReview => 'Revê e corrige o que foi detetado';

  @override
  String get phApprox => 'As calorias são aproximadas.';

  @override
  String get phMealType => 'Refeição (opcional)';

  @override
  String get phNoType => 'Nenhum';

  @override
  String get day => 'Dia';

  @override
  String get phNothing =>
      'Não foi reconhecido nenhum alimento. Adiciona à mão.';

  @override
  String phFoods(int count) {
    return 'ALIMENTOS ($count)';
  }

  @override
  String get phAddFood => 'Adicionar alimento';

  @override
  String get phFood => 'Alimento';

  @override
  String get phGrams => 'g (aprox.)';

  @override
  String get phP => 'P (g)';

  @override
  String get phC => 'HC (g)';

  @override
  String get phF => 'G (g)';

  @override
  String get total => 'Total';

  @override
  String kcalAmount(int kcal) {
    return '$kcal kcal';
  }

  @override
  String get phSave => 'Guardar no diário';

  @override
  String get stkOpenError => 'Não foi possível abrir o talão';

  @override
  String get stkReadError => 'Não foi possível ler o talão';

  @override
  String get stkScanError => 'Erro ao digitalizar';

  @override
  String get stkPantryError =>
      'O talão foi guardado, mas não foi possível atualizar a despensa';

  @override
  String stkCrossed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count produtos riscados da lista',
      one: '1 produto riscado da lista',
    );
    return '$_temp0';
  }

  @override
  String get stkEdit => 'Editar talão';

  @override
  String get stkReading => 'A ler o talão…';

  @override
  String get stkStartTitle => 'Digitaliza o talão das compras';

  @override
  String get stkStartSub => 'Tiramos os produtos e preços. Podes rever depois.';

  @override
  String get stkReview => 'Revê e corrige o que for preciso';

  @override
  String get stkRemember =>
      'As tuas correções ficam guardadas para a próxima vez.';

  @override
  String get stkStore => 'Loja';

  @override
  String get date => 'Data';

  @override
  String get stkAddPantry => 'Adicionar à despensa';

  @override
  String get stkAddPantrySub => 'Cada produto vai para a sua zona';

  @override
  String stkProducts(int count) {
    return 'PRODUTOS ($count)';
  }

  @override
  String stkRaw(String name) {
    return 'Talão: \"$name\"';
  }

  @override
  String get category => 'Categoria';

  @override
  String get stkQty => 'Qtd.';

  @override
  String get stkSave => 'Guardar talão';

  @override
  String foodCategory(String cat) {
    String _temp0 = intl.Intl.selectLogic(cat, {
      'verdura': 'Legumes',
      'fruta': 'Fruta',
      'carne': 'Carne',
      'pescado': 'Peixe',
      'lacteos': 'Laticínios',
      'preparados': 'Pratos preparados',
      'panaderia': 'Padaria',
      'cereales': 'Massa, arroz e leguminosas',
      'conservas': 'Conservas',
      'congelados': 'Congelados',
      'dulces': 'Doces e snacks',
      'bebidas': 'Bebidas',
      'especias': 'Especiarias e condimentos',
      'higiene': 'Higiene',
      'limpieza': 'Limpeza',
      'hogar': 'Casa',
      'other': 'Outros',
    });
    return '$_temp0';
  }
}
