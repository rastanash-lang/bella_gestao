# 🌸 Bella Gestão — Documentação Técnica & de Requisitos (PRD)

> **Versão:** 1.5 (Atualizado com Agenda e Mapa de Vagas)  
> **Modelo:** 100% Offline (Local-First)  
> **Stack:** Flutter (Dart) + SQLite (`sqflite`) + State Management (`Provider`)  
> **CI/CD:** GitHub Actions (Geração automática de APK Release)  
> **Público-alvo:** Profissionais autônomos e MEIs da área da beleza (manicures, cabeleireiras, esteticistas).

---

## 1. Visão Geral e Propósito do Produto
O **Bella Gestão** é um aplicativo móvel ultrarrápido, intuitivo e sem dependência de internet ou servidores externos, desenvolvido para solucionar as três maiores dores do profissional de beleza autônomo:
1. Mistura das contas da casa com as contas do salão (separação PF vs PJ).
2. Dificuldade em controlar faturamento para a declaração anual do MEI (DASN-SIMEI).
3. Conflitos de agenda, tempo ocioso e retrabalho de anotar atendimento na agenda e depois ter que lançar no caderno financeiro.

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

text

lib/
├── main.dart                               # Ponto de entrada, pt_BR e ChangeNotifierProvider
├── core/
│   ├── database/
│   │   └── db_helper.dart                  # Singleton SQLite (tabelas: transacoes, cofrinhos, agendamentos)
│   ├── services/
│   │   └── pdf_service.dart                # Geração do relatório executivo em PDF com tabelas e gráficos
│   └── theme/
│       └── app_theme.dart                  # Material Design 3, Dark Slate (#0F172A), Verde (#16A34A), Carmim (#DC2626)
├── data/
│   ├── models/
│   │   ├── transacao_model.dart            # Model de receitas/despesas com suporte a parcelas e âmbitos
│   │   ├── agendamento_model.dart          # Model de agendamentos com horários de início e término
│   │   └── cofrinho_model.dart             # Model de metas de economia do salão
│   └── repositories/
│       ├── transacao_repository.dart       # CRUD no SQLite da tabela transacoes
│       ├── agendamento_repository.dart     # CRUD no SQLite da tabela agendamentos
│       └── cofrinho_repository.dart        # CRUD no SQLite da tabela cofrinhos
├── controllers/
│   └── financeiro_controller.dart          # Cérebro do app: regras de negócio de caixa, grade de horários, MEI e metas
└── views/
    ├── home/
    │   └── home_screen.dart                # BottomNavigationBar (Caixa, Agenda, Clientes, Relatórios, MEI)
    ├── dashboard/
    │   └── dashboard_view.dart             # Extrato, saldo acumulado, filtro por mês e atalhos rápidos
    ├── formulario/
    │   └── novo_lancamento_view.dart       # Formulário de entrada/saída com parcelamento em até 12x
    ├── agenda/
    │   ├── agenda_view.dart                # Listagem diária, cancelamento, lixeira e botão de conclusão
    │   ├── mapa_vagas_view.dart            # Grade cronológica de slots de 30 minutos com status visual
    │   └── novo_agendamento_view.dart      # Criação/edição com detecção automática de conflito de horário
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

5. Regras de Negócio e Funcionalidades Ativas

5.1. Caixa Financeiro & Lançamentos

Alternância PJ/PF: Chave no topo que filtra instantaneamente o saldo e os lançamentos sem recarregar a tela.
Saldo Geral Acumulado Real: Diferenciação clara entre o saldo total em caixa de todos os tempos e as movimentações específicas do mês selecionado.
Parcelamento Inteligente no Crédito: Ao registrar uma despesa ou receita em cartão parcelado (ex: 3x), o app insere automaticamente 3 registros no banco de dados com os vencimentos futuros nos meses correspondentes.
Compartilhamento de Recibo: Botão de 1 toque que gera uma mensagem formatada e estilizada pronta para enviar no WhatsApp da cliente.
Baixa Rápida: Alternância de status de "Pendente" para "Pago" tocando na tag do extrato.

5.2. Agenda Inteligente & Gestão de Horários
Detecção de Conflitos em Tempo Real: Ao tentar salvar ou ajustar um agendamento cujo horário colida com outro já marcado, o sistema bloqueia e exibe botão para saltar para o próximo horário vago.
Mapa de Vagas (Slots de 30 min): Tela dedicada exibindo os blocos do dia (das 08h às 20h) divididos em Verde (Livre), Vermelho (Ocupado) e Cinza (Horário já encerrado no dia).
Ajuste Rápido de Horário: Botões de +15 min e -15 min nos cards da agenda para acomodar atrasos ou adiantamentos sem precisar abrir formulários.
Integração Agenda ➔ Caixa: Ao tocar em Concluir na agenda, o sistema marca o agendamento como concluído e abre modal para lançar o valor diretamente no Caixa PJ, escolhendo a forma de pagamento e a categoria MEI.
Lembrete WhatsApp: Geração de mensagem elegante com nome da cliente, data, intervalo de horário e procedimento.

5.3. CRM de Clientes
Lista agrupada automaticamente a partir dos lançamentos: exibe quantas visitas a cliente fez, valor total já pago, valor que eventualmente está pendente e histórico detalhado em folha inferior (BottomSheet).

5.4. Fechamento MEI (DASN-SIMEI)
Painel de monitoramento do limite anual de faturamento de R$ 81.000,00.
Separação automática entre Serviços e Produtos (obrigatório na declaração anual do MEI).
Alertas visuais automáticos nos patamares de 70%, 85% e 95% do teto legal.

5.5. Relatórios & Segurança de Dados
Gráfico de Evolução Mensal: Gráfico comparativo de barras com rolagem horizontal livre para visualizar todo o histórico financeiro do ano.
Exportação PDF: Documento no formato A4 com cabeçalho oficial, resumo executivo, dados contábeis MEI, divisão de custos e tabela completa de movimentações com campo para assinatura.
Exportação CSV: Planilha para abrir no Excel.
Backup e Restauração Local JSON: Exportação e restauração manual de dados via texto JSON para troca de aparelho sem nuvem.
