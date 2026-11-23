---
name: flutter-device-live
description: Roda um app Flutter em um dispositivo Android conectado por USB (maquininha POS, celular) e mantém o app aberto para testar com hot reload/restart, tirar screenshot e tocar na tela via adb. Use sempre que precisar testar, depurar ou validar uma mudança de UI/Dart em aparelho real, ou quando o dono pedir para "rodar no aparelho", "ver a tela" ou "testar no dispositivo".
---

# Flutter no aparelho USB, sem reabrir o app a cada mudança

Objetivo: economizar tokens e tempo. Inicie o app UMA vez, mantenha-o aberto e use hot reload/restart. Só olhe a tela quando necessário.

## 1. Descobrir o aparelho
`flutter devices` (pegue o id/serial). `adb devices` confirma. Resolução típica de POS: 720x1440 (coordenadas de toque = pixels do screenshot).

## 2. Iniciar uma vez (canal de comandos por arquivo)
Use arquivos na pasta de scratchpad da sessão. Um FIFO NÃO funciona com `flutter.bat` no Windows; use `tail -f`:
```
cd <pasta do app flutter>
: > cmds.txt
(tail -f cmds.txt | flutter run -d <id> > run.log 2>&1 &)
```
Espere o app subir: faça um loop (até ~5 min) procurando em `run.log` por `Flutter run key commands`, por uma linha de log do próprio app, ou por `FAILURE`/`rror:`. A 1ª compilação demora ~1 min.

## 3. Aplicar mudanças
- Hot reload (só Dart, corpo de métodos/widgets): `echo r >> cmds.txt`
- Hot restart (estado novo): `echo R >> cmds.txt`. OBRIGATÓRIO quando mudar campos `late final`/`initState`, mapas de ações, nomes/quantidade de botões, enums, `main()` ou providers (hot reload mantém o estado antigo e causa "Null check" ou botão sem efeito).
- Código nativo (Kotlin/Java, AndroidManifest, gradle, assets nativos, plugins): reload NÃO basta. `echo q >> cmds.txt`, espere sair e inicie de novo (passo 2).
- Confirme em `run.log`: `Reloaded N libraries` / `Restarted application`; erros aparecem como `Unhandled Exception` ou `E/flutter`.

## 4. Verificar com custo baixo
1. Prefira ler `run.log` (`grep`) ao screenshot: logs do app mostram resultado de chamadas.
2. Screenshot só quando precisar ver UI: `adb -s <serial> exec-out screencap -p > shot.png` e depois `Read` na imagem.
3. Tocar: `adb -s <serial> shell input tap X Y`; rolar: `input swipe x1 y1 x2 y2 300`. As posições mudam quando a tela rola ou a janela abre: depois de um toque, confira antes de repetir.
4. Mudanças em janelas/estado: reabra o fluxo para ver o resultado novo (o hot reload não refaz diálogos já abertos).

## 5. Encerrar
Mantenha o app aberto entre tarefas. Ao terminar a sessão ou se travar: `echo q >> cmds.txt`; se sobrar processo, `taskkill //F //IM dart.exe` (Git Bash no Windows). Nunca deixe vários `flutter run` simultâneos no mesmo aparelho.

## Cuidados
- Não envie dados pessoais/credenciais reais em logs ou screenshots deixados fora do projeto.
- Se o app depende de um serviço do aparelho (ex.: serviço da POS) que ficou preso, reiniciar o aparelho resolve mais que reinstalar o app.
