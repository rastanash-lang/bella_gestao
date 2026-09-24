# 🌸 Bella Gestão — Documentação Técnica & de Requisitos (PRD)

> **Versão:** 1.7 (Layout Clean 2x2, Gestão Integrada PJ/PF, Estoque, Cofrinho Validado e Agenda 10h)  
> **Modelo:** 100% Offline (Local-First)  
> **Stack:** Flutter (Dart) + SQLite (`sqflite`) + State Management (`Provider`)  
> **CI/CD:** GitHub Actions (Geração automática de APK Release)  
> **Público-alvo:** Profissionais autônomos e MEIs da área da beleza (manicures, cabeleireiras, esteticistas).

---

## 1. Visão Geral e Propósito do Produto
O **Bella Gestão** é um aplicativo mobile ultrarrápido, intuitivo e sem dependência de internet ou servidores externos, desenvolvido para solucionar as dores centrais do profissional de beleza autônomo:
1. **Contabilidade Real Unificada:** As despesas pessoais (PF) são deduzidas de forma transparente do faturamento do salão (PJ), exibindo o dinheiro real que sobra no bolso sem misturar contabilidade formal com gastos domésticos.
2. **Conformidade MEI (DASN-SIMEI):** Monitoramento do teto anual de faturamento sem distorções contábeis causadas por reservas ou movimentações internas.
3. **Agenda Inteligente Flexível:** Suporte a procedimentos curtos e longos (de 30 min até 10 horas contínuas), com detecção de conflitos, alarmes prévios configuráveis e baixa com 1 toque no caixa.
4. **Controle de Estoque e Cosméticos:** Alertas visuais para reposição de insumos de uso diário e produtos de revenda.
5. **Reservas Financeiras Seguras (Cofrinho):** Gestão de metas com trava de segurança para impedir depósitos superiores ao saldo em mãos no caixa.

---

## 2. Stack Tecnológica e Dependências

* **Framework:** Flutter 3.x (Canal Stable)
* **Linguagem:** Dart
* **Banco de Dados Local:** `sqflite: ^2.x` + `path_provider` (Banco: `bella_finance_v5.db`)
* **Gerenciamento de Estado:** `provider: ^6.x`
* **Datas e Formatação:** `intl: ^0.19.x` (Localização em `pt_BR`)
* **Gerenciamento de Arquivos Locais:** `file_picker: ^13.x` (Seleção nativa de arquivos `.json` do celular)
* **Documentos e Compartilhamento:** `pdf: ^3.x` e `share_plus: ^10.x`
* **Automação CI/CD:** GitHub Actions com injeção automática de ícone vetorial SVG e compilação direta do APK nativo.

---

## 3. Estrutura de Pastas e Mapeamento de Arquivos

```text
lib/
├── main.dart                               # Ponto de entrada, pt_BR e MultiProvider
├── core/
│   ├── database/
│   │   └── db_helper.dart                  # Singleton SQLite (transacoes, cofrinhos, agendamentos, produtos)
│   ├── services/
│   │   └── pdf_service.dart                # Geração de relatório executivo contábil em PDF A4
│   └── theme/
│       └── app_theme.dart                  # Material Design 3, Dark Slate (#0F172A), Verde (#16A34A), Carmim (#DC2626)
├── data/
│   ├── models/
│   │   ├── transacao_model.dart            # Model financeiro (parcelamento, âmbitos PJ/PF, tipos MEI)
│   │   ├── agendamento_model.dart          # Model de agenda (duração de até 600 min, antecedência de alarme)
│   │   ├── cofrinho_model.dart             # Model de metas de economia do salão
│   │   └── produto_model.dart              # Model de produtos e cosméticos com estoque mínimo
│   └── repositories/
│       ├── transacao_repository.dart       # CRUD no SQLite da tabela transacoes
│       ├── agendamento_repository.dart     # CRUD no SQLite da tabela agendamentos
│       ├── cofrinho_repository.dart        # CRUD no SQLite da tabela cofrinhos
│       └── produto_repository.dart         # CRUD no SQLite da tabela produtos
├── controllers/
│   └── financeiro_controller.dart          # Cérebro do app: regras de caixa, deduções PJ/PF, agenda e estoque
└── views/
    ├── home/
    │   └── home_screen.dart                # BottomNavigationBar (Caixa, Agenda, Clientes, Relatórios, MEI)
    ├── dashboard/
    │   └── dashboard_view.dart             # Card Principal limpo 2x2, atalhos amplos (Cofrinho e Estoque) e extrato
    ├── formulario/
    │   └── novo_lancamento_view.dart       # Formulário dinâmico (limpa termos do salão ao selecionar Pessoal PF)
    ├── agenda/
    │   ├── agenda_view.dart                # Listagem cronológica, cancelamentos, WhatsApp e baixa no caixa
    │   ├── mapa_vagas_view.dart            # Grade visual cronológica de slots de 30 min (livre, ocupado, passado)
    │   └── novo_agendamento_view.dart      # Formulário com duração de até 10h e escolha de antecedência do alarme
    ├── estoque/
    │   ├── estoque_view.dart               # Lista de insumos, banner de alerta de falta e movimentação com 1 toque
    │   └── novo_produto_view.dart          # Cadastro e edição de produtos de uso interno e revenda
    ├── clientes/
    │   └── clientes_view.dart              # CRM com histórico por cliente, total gasto e pendências
    ├── cofrinho/
    │   └── cofrinho_view.dart              # Metas visuais com botão de olhinho e validação de saldo disponível
    └── relatorios/
        ├── relatorios_view.dart            # Gráficos de barras mensais e balanço consolidado de sobras
        └── painel_mei_view.dart            # Acompanhamento do teto de R$ 81.000 (Serviços vs Produtos)
4. Esquema do Banco de Dados SQLite (bella_finance_v5.db)
Tabela transacoes
id INTEGER PRIMARY KEY AUTOINCREMENT
descricao TEXT NOT NULL
cliente TEXT (Opcional, desativado para contas PF)
valor REAL NOT NULL
tipo TEXT NOT NULL (entrada ou saida)
ambito TEXT NOT NULL (PJ ou PF)
categoria TEXT NOT NULL
formaPagamento TEXT NOT NULL (Pix, Dinheiro, Débito, Crédito)
status TEXT NOT NULL (Pago ou Pendente)
tipoCusto TEXT (Para saídas do salão: Fixo, Variável, Emergência)
tipoReceita TEXT (Para receitas MEI: Serviço, Produto)
parcelaAtual INTEGER DEFAULT 1
totalParcelas INTEGER DEFAULT 1
data TEXT NOT NULL (ISO-8601)
Tabela agendamentos
id INTEGER PRIMARY KEY AUTOINCREMENT
cliente TEXT NOT NULL
servico TEXT NOT NULL
valor REAL NOT NULL
dataHoraInicio TEXT NOT NULL (ISO-8601)
duracaoMinutos INTEGER NOT NULL (De 30 min até 600 min / 10 horas)
status TEXT NOT NULL (Agendado, Concluido, Cancelado)
observacoes TEXT
antecedenciaLembreteMinutos INTEGER DEFAULT 15
Tabela cofrinhos
id INTEGER PRIMARY KEY AUTOINCREMENT
titulo TEXT NOT NULL
valorAlvo REAL NOT NULL
valorAtual REAL NOT NULL
dataCriacao TEXT NOT NULL (ISO-8601)
Tabela produtos
id INTEGER PRIMARY KEY AUTOINCREMENT
nome TEXT NOT NULL
categoria TEXT NOT NULL (Coloração, Tratamento/Shampoo, Unhas/Esmaltes, Revenda Clientes, etc.)
quantidadeAtual INTEGER NOT NULL
quantidadeMinima INTEGER NOT NULL
precoCusto REAL NOT NULL
precoVenda REAL NOT NULL
unidade TEXT NOT NULL (un, frasco, tubo, kit, ml, g)
5. Regras de Negócio e Funcionalidades Ativas
5.1. Dashboard Limpo e Contabilidade Real Integrada
Grade 2x2 Anti-poluição: O resumo mensal organiza os dados em 4 cartões individuais e arredondados:
🟢 Receita do Mês: Entradas operacionais reais do salão.
🔴 Despesas Salão: Custos fixos e variáveis do salão.
🟣 Gastos Pessoais: Total retirado do salão para compras pessoais no mês.
🔵 Sobra do Mês: Faturamento real limpo após pagar o salão e retirar as despesas pessoais.
Cálculo Real do Dinheiro em Mãos:
Saldo em Caixa
=
(
∑
Entradas PJ
)
−
(
∑
Despesas PJ
)
−
(
∑
Gastos PF
)
−
(
∑
Total em Cofrinhos
)
Saldo em Caixa=(∑Entradas PJ)−(∑Despesas PJ)−(∑Gastos PF)−(∑Total em Cofrinhos)
Atalhos Otimizados: Remoção de atalhos redundantes; o topo conta apenas com acessos rápidos amplos para Cofrinho / Metas e Estoque Insumos.
5.2. Gestão de Gastos Pessoais (PF)
Formulário Específico: Ao alternar para conta PF, a interface remove automaticamente os campos de cliente e classificação MEI. Pede apenas o que foi comprado, data, valor e forma de pagamento.
Bloqueio de Gastos sem Lastro: O aplicativo exibe em tempo real o saldo disponível no caixa do salão e bloqueia tentativas de registrar retiradas pessoais acima do dinheiro existente.
5.3. Cofrinho & Metas Financeiras
Visibilidade Protegida: Botão de alternância (olhinho) direto no topo da tela e no card para ocultar ou exibir o saldo guardado.
Validação Rigorosa de Depósito: Só é permitido guardar dinheiro se houver saldo positivo disponível no caixa do salão.
Neutralidade Contábil: Guardar e resgatar dinheiro de metas ajusta o dinheiro disponível sem gerar receitas ou despesas fantasmas que poluiriam o extrato ou a declaração do MEI.
5.4. Agenda Inteligente & Gestão de Procedimentos
Duração Estendida (até 10 Horas): Seletor rápido de 30 min até 600 min (10h), atendendo procedimentos longos como mega hair, descolorações complexas e dias de noiva.
Alarme e Lembrete Prévio: Configuração individual por agendamento para alertas antes do procedimento (10 min, 15 min, 30 min, 45 min, 1h, 2h ou desativado).
Prevenção de Conflitos & Próximo Vago: Bloqueio automático de sobreposições de horário com cálculo do próximo slot livre.
Baixa com 1 Toque: Ao concluir um agendamento, o valor é lançado diretamente no Caixa PJ com a classificação correta.
Disparo WhatsApp: Lembretes de agendamento e comprovantes formatados com emojis prontos para envio.
5.5. Controle de Estoque
Alerta Visual de Estoque Baixo: Identificação imediata de itens cuja quantidade atual está igual ou abaixo da mínima configurada.
Entrada e Saída Integradas: Opção de gerar despesa de compra de estoque no Caixa PJ ou registrar venda de produto com destinação contábil MEI.
5.6. Segurança de Dados & Relatórios
Restauração Nativa com file_picker: O app abre diretamente o gerenciador de arquivos e pastas do Android para seleção de backups .json.
Exportação Completa: Backup estruturado contendo transações, cofrinhos, agendamentos e catálogo de produtos em arquivo único.
Relatórios Executivos: Geração de PDF contábil formal com discriminação DASN-SIMEI e planilhas em CSV.
