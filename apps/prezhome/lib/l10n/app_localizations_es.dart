// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String tabLabel(String tab) {
    String _temp0 = intl.Intl.selectLogic(tab, {
      'inicio': 'Hoy',
      'comidas': 'Comida',
      'compra': 'Compra',
      'despensa': 'Despensa',
      'tareas': 'Tareas',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get country => 'País';

  @override
  String get countryHint => 'Moneda, supermercados y precios de referencia';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get back => 'Atrás';

  @override
  String get oneMoment => 'Un momento…';

  @override
  String get retry => 'Reintentar';

  @override
  String get loginAccountCreated =>
      'Cuenta creada. Te damos la bienvenida a PrezHome';

  @override
  String get loginAuthError => 'Error de autenticación';

  @override
  String loginProviderError(String provider) {
    return 'No se pudo iniciar con $provider';
  }

  @override
  String get loginResetNeedsEmail =>
      'Escribe primero tu correo y te enviaré el enlace para restablecer tu contraseña.';

  @override
  String get loginResetSent =>
      'Te he enviado un correo para restablecer tu contraseña.';

  @override
  String get loginResetError => 'No se pudo enviar el correo';

  @override
  String get loginWelcomeBack => 'Hola de nuevo';

  @override
  String get loginCreateAccount => 'Crea tu cuenta';

  @override
  String get loginTagline => 'PrezHome, tu hogar organizado';

  @override
  String loginContinueWith(String provider) {
    return 'Continuar con $provider';
  }

  @override
  String get loginOrEmail => 'o con tu correo';

  @override
  String get loginEmail => 'Correo electrónico';

  @override
  String get loginEmailInvalid => 'Introduce un correo válido';

  @override
  String get loginPassword => 'Contraseña';

  @override
  String get loginShowPassword => 'Mostrar contraseña';

  @override
  String get loginHidePassword => 'Ocultar contraseña';

  @override
  String get loginPasswordShort => 'Mínimo 6 caracteres';

  @override
  String get loginForgot => '¿Has olvidado tu contraseña?';

  @override
  String get loginSignIn => 'Entrar';

  @override
  String get loginSignUp => 'Registrarme';

  @override
  String get loginNoAccount => '¿No tienes cuenta? Regístrate';

  @override
  String get loginHaveAccount => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get homeCodeFormat =>
      'El código tiene 8 letras y números (por ejemplo ABCD-EFGH).';

  @override
  String get homeSetupError => 'No se pudo configurar el hogar';

  @override
  String get homeLastStep => 'Último paso: tu hogar';

  @override
  String get homeCreateHint =>
      'Créalo ahora y, cuando quieras, invita a quien viva contigo desde Inicio.';

  @override
  String get homeCreate => 'Crear mi hogar';

  @override
  String get homeInvited => 'Me han invitado a un hogar';

  @override
  String get homeInviteCode => 'Código de invitación';

  @override
  String get homeJoin => 'Unirme a un hogar';

  @override
  String get sessionLoadError => 'No se pudo cargar tu perfil.';

  @override
  String get onbSectionHome => 'Tu hogar';

  @override
  String get onbPeopleTitle => '¿Cuántas personas vivís?';

  @override
  String get onbPeopleHint =>
      'Para calcular raciones, la compra y el reparto de tareas.';

  @override
  String get onbSectionGoals => 'Lo que te ocupa';

  @override
  String get onbGoalsTitle => '¿Qué quieres quitarte de la cabeza?';

  @override
  String get onbGoalsHint =>
      'Elige todo lo que quieras. Lo demás quedará escondido.';

  @override
  String get onbPickOne => 'Elige al menos una';

  @override
  String onbContinueCount(int count) {
    return 'Continuar ($count)';
  }

  @override
  String get onbSectionKitchen => 'En la cocina';

  @override
  String get onbCookingTitle => '¿Cómo cocináis?';

  @override
  String get onbCookingHint => 'Así sabemos si organizar tandas y congelador.';

  @override
  String get onbSectionShopping => 'La compra';

  @override
  String get onbShopTitle => '¿Dónde compras?';

  @override
  String get onbShopHint =>
      'El primero será tu súper principal: las recetas usarán productos fáciles de encontrar allí.';

  @override
  String get onbSkipSeeHome => 'Saltar y ver mi hogar';

  @override
  String get onbSeeHome => 'Ver mi hogar';

  @override
  String get onbSlogan => 'La casa en orden, la cabeza tranquila.';

  @override
  String get onbStart => 'Comenzar';

  @override
  String get onbHaveAccount => 'Ya tengo cuenta';

  @override
  String get onbOneLess => 'Una menos';

  @override
  String get onbOneMore => 'Una más';

  @override
  String onbPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas',
      one: 'Solo yo',
    );
    return '$_temp0';
  }

  @override
  String get onbProfileBadge => 'Tu perfil de hogar';

  @override
  String onbProfileName(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'solo': 'En Solitario',
      'duo': 'El Dúo',
      'tribu': 'La Tribu',
      'other': 'La Familia',
    });
    return '$_temp0';
  }

  @override
  String onbProfileDescription(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'solo':
          'Toda la casa depende de ti. PrezHome se acuerda de lo que hay, lo que caduca y lo que toca, para que tú no tengas que hacerlo.',
      'duo':
          'Dos personas y una casa. PrezHome reparte la carga a la vista, para que nadie lleve la cuenta de todo en la cabeza.',
      'other':
          'Muchas bocas y muchas cosas a la vez. PrezHome planifica comidas, compra y tareas para todos, y avisa a cada uno de lo suyo.',
    });
    return '$_temp0';
  }

  @override
  String get onbLoadToday => 'Carga mental hoy';

  @override
  String get onbLoadWithApp => 'Con PrezHome';

  @override
  String onbLoad(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'high': 'pesada',
      'medium': 'media',
      'other': 'ligera',
    });
    return '$_temp0';
  }

  @override
  String get onbCreateAccount => 'Crear mi cuenta';

  @override
  String onbFeature(String f) {
    String _temp0 = intl.Intl.selectLogic(f, {
      'compra': 'Lista de la compra',
      'comidas': 'Qué comemos',
      'despensa': 'Despensa y caducidades',
      'tareas': 'Tareas del hogar',
      'other': 'Gasto de la casa',
    });
    return '$_temp0';
  }

  @override
  String goalLabel(String g) {
    String _temp0 = intl.Intl.selectLogic(g, {
      'comidas': 'Qué comemos',
      'compra': 'La compra',
      'despensa': 'Lo que hay en casa',
      'tareas': 'Tareas del hogar',
      'lote': 'Cocinar en lote',
      'other': 'El gasto de la casa',
    });
    return '$_temp0';
  }

  @override
  String goalHint(String g) {
    String _temp0 = intl.Intl.selectLogic(g, {
      'comidas': 'Plan de comidas y recetas',
      'compra': 'Lista que se escribe sola',
      'despensa': 'Despensa, nevera y caducidades',
      'tareas': 'Reparto justo y recordatorios',
      'lote': 'Táperes y congelador organizados',
      'other': 'Presupuesto y tickets',
    });
    return '$_temp0';
  }

  @override
  String cookingLabel(String c) {
    String _temp0 = intl.Intl.selectLogic(c, {
      'diario': 'Cada día',
      'lote': 'En lote',
      'mixto': 'Un poco de todo',
      'other': 'Casi nunca',
    });
    return '$_temp0';
  }

  @override
  String cookingHint(String c) {
    String _temp0 = intl.Intl.selectLogic(c, {
      'diario': 'Cocino lo del momento',
      'lote': 'Preparo varios días de una vez',
      'mixto': 'Algunos días en lote',
      'other': 'Como fuera o algo rápido',
    });
    return '$_temp0';
  }
}
