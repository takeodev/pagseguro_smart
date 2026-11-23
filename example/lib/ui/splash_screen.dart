import 'package:example/ui/main_screen.dart';
import 'package:flutter/material.dart';

/// ======================================================================================
/// Arquivo         : ui/splash_screen.dart
/// Projeto         : PagSeguro Smart
/// Plataforma      : Android
/// Autor           : Fernando Takeo Miyaji
/// ======================================================================================

/// Tela de abertura animada com o logotipo do desenvolvedor (substitui a tela padrão do Flutter).
///
/// Sequência (≈ 2,6 s): o logo surge com fade + zoom suave, um brilho atravessa o logo e, por fim, aparecem os créditos.
/// Depois faz a transição (fade) para a [MainScreen]. Toque em qualquer lugar para pular.
/// Se o aparelho tem as animações desativadas (acessibilidade), mostra o logo estático por um instante e segue.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  /// Duração total da animação de entrada
  static const Duration _duration = Duration(milliseconds: 2600);

  /// Tempo que a tela fica parada no final, antes de abrir o app
  static const Duration _hold = Duration(milliseconds: 500);

  late final AnimationController _controller = AnimationController(vsync: this, duration: _duration);

  // ---- Trechos da animação (0.0 a 1.0 do tempo total) ----
  /// Logo: aparece (opacidade)
  late final Animation<double> _logoFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
  );

  /// Logo: cresce de 82% a 100% com um leve "quique" no final
  late final Animation<double> _logoScale = Tween<double>(begin: 0.82, end: 1.0).animate(
    CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
    ),
  );

  /// Logo: sobe 18 px até a posição final
  late final Animation<double> _logoRise = Tween<double>(begin: 18, end: 0).animate(
    CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    ),
  );

  /// Brilho que atravessa o logo da esquerda para a direita (-1 = fora à esquerda, 2 = fora à direita)
  late final Animation<double> _shine = Tween<double>(begin: -1.0, end: 2.0).animate(
    CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.85, curve: Curves.easeInOut),
    ),
  );

  /// Créditos ("Desenvolvido por..."): aparecem no final
  late final Animation<double> _creditsFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
  );

  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) Future<void>.delayed(_hold, _goToApp);
    });
    // Só inicia depois do 1º frame, para a animação não perder quadros durante a abertura do app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _controller.value = 1.0; // sem animação: mostra tudo de uma vez
      } else {
        _controller.forward();
      }
    });
  }

  /// Abre a tela principal com transição em fade (executa uma única vez)
  void _goToApp() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, _, _) => const MainScreen(),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double logoWidth = (MediaQuery.of(context).size.width * 0.7).clamp(180.0, 380.0);

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _goToApp, // toque pula a animação
        child: Container(
          width: double.infinity,
          height: double.infinity,
          // Fundo branco com um leve azulado embaixo, combinando com as cores do logo
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFEFF6FF)]),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // LOGO com fade, zoom, subida e brilho
                  Opacity(
                    opacity: _logoFade.value,
                    child: Transform.translate(
                      offset: Offset(0, _logoRise.value),
                      child: Transform.scale(scale: _logoScale.value, child: _shiningLogo(logoWidth)),
                    ),
                  ),
                  const SizedBox(height: 36),
                  // CRÉDITOS
                  Opacity(
                    opacity: _creditsFade.value,
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - _creditsFade.value)),
                      child: const Column(
                        children: [
                          Text(
                            'Desenvolvido por Takeo',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.4, color: Color(0xFF3D1BD3)),
                          ),
                          SizedBox(height: 4),
                          Text('Pacote gratuito para a comunidade Flutter', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Logo com uma faixa de brilho diagonal que se move conforme [_shine].
  /// O ShaderMask com `srcATop` pinta o brilho só sobre os pixels do próprio logo (o fundo transparente não recebe nada).
  Widget _shiningLogo(double width) {
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (Rect bounds) {
        final double center = _shine.value;
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          transform: const GradientRotation(0.35), // inclina a faixa de brilho
          colors: const [Color(0x00FFFFFF), Color(0xB3FFFFFF), Color(0x00FFFFFF)],
          stops: [(center - 0.18).clamp(0.0, 1.0), center.clamp(0.0, 1.0), (center + 0.18).clamp(0.0, 1.0)],
        ).createShader(bounds);
      },
      child: Image.asset('assets/logo_takeo.png', width: width, semanticLabel: 'Logotipo do desenvolvedor Takeo'),
    );
  }
}
