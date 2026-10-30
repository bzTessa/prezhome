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
}
