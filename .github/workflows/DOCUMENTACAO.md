# 🌸 Bella Gestão — Documentação Técnica & de Requisitos (PRD)

> **Versão:** 1.6 (Atualizado com Estoque de Cosméticos e Produtos)  
> **Modelo:** 100% Offline (Local-First)  
> **Stack:** Flutter (Dart) + SQLite (`sqflite`) + State Management (`Provider`)  
> **CI/CD:** GitHub Actions (Geração automática de APK Release)  
> **Público-alvo:** Profissionais autônomos e MEIs da área da beleza (manicures, cabeleireiras, esteticistas).

---

## 1. Visão Geral e Propósito do Produto
O **Bella Gestão** é um aplicativo móvel ultrarrápido, intuitivo e sem dependência de internet ou servidores externos, desenvolvido para solucionar as principais dores do profissional de beleza autônomo:
1. Mistura das contas da casa com as contas do salão (separação PF vs PJ).
2. Dificuldade em controlar faturamento para a declaração anual do MEI (DASN-SIMEI).
3. Conflitos de agenda, horários vagos ociosos e retrabalho de lançar atendimentos no caixa.
4. Falta de controle sobre insumos (tintas, esmaltes, shampoos) e perda de produtos de revenda por falta de reposição.

---

## 2. Stack Tecnológica e Dependências

* **Framework:** Flutter 3.x (Canal Stable)
* **Linguagem:** Dart
* **Banco de Dados Local:** `sqflite: ^2.x` + `path_provider` (Banco: `bella_finance_v5.db`)
* **Gerenciamento de Estado:** `provider: ^6.x`
* **Datas e Formatação:** `intl: ^0.19.x` (Localização em `pt_BR`)
* **Documentos e Compartilhamento:** `pdf: ^3.x` e `share_plus: ^10.x`
* **Automação:** GitHub Actions (`.github/workflows/...`) com injeção automática de ícone vetorial SVG e compilação do APK nativo.

---

## 3. Estrutura de Pastas e Mapeamento de Arquivos

```text
lib/
├── main.dart                               # Ponto de entrada, pt_BR e ChangeNotifierProvider
├── core/
│   ├── database/
│   │   └── db_helper.dart                  # Singleton SQLite (tabelas: transacoes, cofrinhos, agendamentos, produtos)
│   ├── services/
│   │   └── pdf_service.dart                # Geração do relatório executivo em PDF com tabelas e gráficos
│   └── theme/
│       └── app_theme.dart                  # Material Design 3, Dark Slate (#0F172A), Verde (#16A34A), Carmim (#DC2626)
├── data/
│   ├── models/
│   │   ├── transacao_model.dart            # Model de receitas/despesas com suporte a parcelas e âmbitos
│   │   ├── agendamento_model.dart          # Model de agendamentos com horários de início e término
│   │   ├── cofrinho_model.dart             # Model de metas de economia do salão
│   │   └── produto_model.dart              # Model de produtos com controle de estoque mínimo e preços
│   └── repositories/
│       ├── transacao_repository.dart       # CRUD no SQLite da tabela transacoes
│       ├── agendamento_repository.dart     # CRUD no SQLite da tabela agendamentos
│       ├── cofrinho_repository.dart        # CRUD no SQLite da tabela cofrinhos
│       └── produto_repository.dart         # CRUD no SQLite da tabela produtos
├── controllers/
│   └── financeiro_controller.dart          # Cérebro do app: caixa, agenda, MEI, estoque e relatórios
└── views/
    ├── home/
    │   └── home_screen.dart                # BottomNavigationBar (Caixa, Agenda, Clientes, Relatórios, MEI)
    ├── dashboard/
    │   └── dashboard_view.dart             # Extrato, saldo acumulado, atalhos rápidos (Estoque, Cofrinho, Finanças)
    ├── formulario/
    │   └── novo_lancamento_view.dart       # Formulário de entrada/saída com parcelamento em até 12x
    ├── agenda/
    │   ├── agenda_view.dart                # Listagem diária, cancelamento, lixeira e botão de conclusão
    │   ├── mapa_vagas_view.dart            # Grade cronológica de slots de 30 minutos com status visual
    │   └── novo_agendamento_view.dart      # Criação/edição com detecção automática de conflito de horário
    ├── estoque/
    │   ├── estoque_view.dart               # Lista de itens, banner de alerta de estoque baixo e baixa/compra rápida
    │   └── novo_produto_view.dart          # Formulário de cadastro/edição de produtos e cosméticos
    ├── clientes/
    │   └── clientes_view.dart              # CRM unificado com histórico de atendimentos e pendências
    ├── cofrinho/
    │   └── cofrinho_view.dart              # Metas visuais com barra de progresso, depósitos e resgates
    └── relatorios/
        ├── relatorios_view.dart            # Gráfico de barras com histórico comparativo de todos os meses
        └── painel_mei_view.dart            # Acompanhamento do teto de R$ 81.000 e discriminação Serviços vs Produtos
4. Esquema do Banco de Dados SQLite (bella_finance_v5.db)
Tabela transacoes
id INTEGER PRIMARY KEY AUTOINCREMENT
descricao TEXT NOT NULL
cliente TEXT (Opcional)
valor REAL NOT NULL
tipo TEXT NOT NULL (entrada ou saida)
ambito TEXT NOT NULL (PJ ou PF)
categoria TEXT NOT NULL
formaPagamento TEXT NOT NULL (Pix, Dinheiro, Débito, Crédito)
status TEXT NOT NULL (Pago ou Pendente)
tipoCusto TEXT (Fixo, Variável, Emergência - para saídas)
tipoReceita TEXT (Serviço, Produto - para entradas PJ)
parcelaAtual INTEGER DEFAULT 1
totalParcelas INTEGER DEFAULT 1
data TEXT NOT NULL (ISO-8601)
Tabela agendamentos
id INTEGER PRIMARY KEY AUTOINCREMENT
cliente TEXT NOT NULL
servico TEXT NOT NULL
valor REAL NOT NULL
dataHoraInicio TEXT NOT NULL (ISO-8601)
duracaoMinutos INTEGER NOT NULL
status TEXT NOT NULL (Agendado, Concluido, Cancelado)
observacoes TEXT (Opcional)
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
5.1. Caixa Financeiro & Lançamentos
Alternância PJ/PF: Filtro instantâneo entre contas pessoais e empresariais no topo da tela.
Saldo Geral Acumulado Real: Cálculo real de todo o dinheiro acumulado desde a inauguração, dissociado do filtro mensal.
Parcelamento Automático: Suporte a vendas/compras no cartão em até 12x, gerando os lançamentos dos meses seguintes no banco.
Comprovantes no WhatsApp: Disparo de recibo elegante e pronto com 1 clique para a cliente.
Baixa Rápida: Alternância instantânea de pendências para "Pago".
5.2. Agenda Inteligente & Mapa de Vagas
Detecção Ativa de Conflitos: Impede sobreposição de horários e sugere o próximo horário livre no dia.
Mapa Visual de Vagas: Grade de 30 em 30 minutos (08h às 20h) destacando horários livres (verde), ocupados (vermelho) e passados (cinza).
Ajuste Rápido de Horário: Botões de +15 min e -15 min direto no card.
Baixa com Integração Financeira: Ao clicar em Concluir Atendimento, o sistema encerra a agenda e lança o dinheiro direto no Caixa PJ com a devida classificação MEI.
Lembrete WhatsApp: Mensagem com os detalhes do horário pronta para envio com 1 toque.
5.3. Controle de Estoque & Cosméticos
Categorização Completa: Separação entre itens de uso interno do salão (tinturas, descolorantes, luvas) e itens para revenda (shampoos home care, óleos).
Alerta Visual de Estoque Baixo: Banner destacado na tela quando qualquer produto atinge ou fica abaixo da quantidadeMinima.
Movimentação Rápida com Integração Financeira:
Comprar / Entrada: Incrementa a quantidade e, opcionalmente, cria uma saída no Caixa PJ categorizada como Produtos/Cosméticos.
Usar ou Vender / Saída: Reduz o estoque e, no caso de revenda para cliente, gera automaticamente uma receita MEI de Produto.
5.4. CRM de Clientes
Agrupamento automático dos lançamentos: exibe histórico de procedimentos, total investido pela cliente e pendências em aberto.
5.5. Fechamento MEI (DASN-SIMEI)
Painel de monitoramento do teto anual de R$ 81.000,00 com barra de progresso visual.
Segregação de faturamento entre Serviços e Venda de Mercadorias (Produtos).
Avisos graduais ao atingir 70%, 85% e 95% do teto legal.
5.6. Relatórios & Segurança Local
Gráfico de Barras: Evolução comparativa de entradas vs saídas com rolagem horizontal livre.
Exportação em PDF Executivo: Documento formal para contabilidade com divisão MEI, custos e comprovante de lançamentos.
Exportação CSV: Planilha compatível com Excel.
Backup e Restauração JSON: Exportação e importação manual dos dados sem dependência de nuvem.
