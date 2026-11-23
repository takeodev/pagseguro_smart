# pagseguro_smart

## Tour do App Example (regra permanente)

O Tour guiado do Example (`example/lib/ui/app_tour.dart`) deve refletir SEMPRE a interface atual.
Sempre que uma tarefa **criar, remover, renomear ou alterar** um bloco (Card), botão ou campo nas abas do
Example (`payment_tab.dart`, `commands_tab.dart`, `features_tab.dart`), atualize o Tour **na mesma tarefa**:

- Delegue ao agente `tour-sync` (Haiku, barato) passando a lista do que mudou; revise o resultado e rode
  `flutter analyze lib` em `example/`. Se a mudança for pequena (1 botão), pode editar direto.
- Padrão do Tour: por bloco, um passo-resumo (`block: true`) + um passo por botão; cada componente tem
  `key: TourKeys.of('<id>')` e um `TourStep` com o mesmo id (veja `AppTour._group`).
- Recursos (aba 3): basta adicionar o item em `kFeatureSections` (features_tab.dart) e a ação em `_actions`;
  o Tour gera os passos sozinho.
- Textos do Tour e dos diálogos em português, explicando o que o botão faz e quando fica habilitado.

## Comentários, README e CHANGELOG (regra permanente)

Toda tarefa que criar ou alterar código deve terminar com a documentação em dia, delegando a agentes Haiku
(baratos) e revisando o resultado:

- **Comentários:** agente `code-commenter` (passe a lista de arquivos alterados). Comentários em português, para que
  qualquer pessoa que baixe o pacote entenda o que o código faz. Nunca altera lógica.
- **README.md e CHANGELOGs:** agente `docs-sync` (passe a lista objetiva do que mudou e se afetou o pacote, o
  Example ou ambos). Pacote -> `CHANGELOG.md`; app Example -> `example/CHANGELOG.md`.
- **Padrão do CHANGELOG:** `## x.y.z` + uma linha por alteração, objetiva, com tag `[Add]`, `[Improve]`, `[Fix]`,
  `[Upgrade]` ou `[Remove]`; mudança com várias partes quebra em várias linhas, cada uma com sua tag. Métodos/classes
  em `"**nome**"`, valores/termos em `"_valor_"`, trocas em `"~~_antigo_~~" => "_novo_"`.
- Mudança pequena (1 linha de changelog, 1 comentário): pode ser feita direto, sem agente.
- Bump de versão (`pubspec.yaml`) é decisão do dono: apenas avise quando for necessário.
