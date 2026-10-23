# 🌸 Bella Gestão — Documentação Técnica & de Requisitos (PRD)

> **Versão:** 2.0 (Estável com Notificações Nativas, Teto Dinâmico LC 238/2026, Banco v2 e Restauração Atômica)  
> **Modelo:** 100% Offline (Local-First)  
> **Stack:** Flutter (Dart) + SQLite (`sqflite`) + State Management (`Provider`)  
> **CI/CD:** GitHub Actions (Compilação automática de APK com publicação em Releases)  
> **Público-alvo:** Profissionais autônomos e MEIs da área da beleza (cabeleireiras, manicures, esteticistas).

---

## 1. Visão Geral e Propósito do Produto
O **Bella Gestão** é uma plataforma mobile ultrarrápida, sem mensalidades e sem dependência de internet ou servidores externos, desenvolvida especificamente para profissionais autônomos da beleza. 

O aplicativo atua como o **centro de comando diário** do negócio:
1. **Contabilidade Real Unificada:** As despesas pessoais (PF) são deduzidas de forma transparente do faturamento do salão (PJ), informando com precisão a sobra limpa que vai para o bolso do profissional sem desorganizar a contabilidade formal.
2. **Conformidade Fiscal com o MEI (DASN-SIMEI):** Monitoramento automático e escalonado do teto anual do MEI com separação obrigatória entre Serviços e Venda de Produtos.
3. **Agenda Inteligente com Alarmes Reais:** Procedimentos curtos e longos (de 30 min até 10 horas contínuas), com alarme configurável que toca no celular mesmo com o aplicativo fechado ou tela bloqueada.
4. **Baixa e Estorno Conectados:** Concluir um agendamento gera a receita no caixa; cancelar ou excluir o agendamento estorna a quantia do Caixa e do MEI imediatamente.
5. **Estoque de Insumos e Revenda:** Controle de estoque com alertas visuais para compras antes que o produto acabe na bancada.
6. **Segurança Máxima de Dados:** Backup em arquivo local `.json` com restauração atômica protegida por transações no SQLite (se o arquivo for corrompido, nada é apagado).

---

## 2. Stack Tecnológica e Dependências

* **Framework:** Flutter 3.x (Canal Stable)
* **Linguagem:** Dart
* **Banco de Dados Local:** `sqflite: ^2.3.3+1` + `path_provider: ^2.1.4` (Banco: `bella_finance_v5.db`, Versão de Schema: 2)
* **Gerenciamento de Estado:** `provider: ^6.1.2`
* **Datas e Formatação:** `intl: ^0.19.0` (Localização brasileira `pt_BR`)
* **Alarmes & Notificações em Segundo Plano:** `flutter_local_notifications: ^22.0.0` + `timezone: ^0.10.0`
* **Gerenciamento de Arquivos Locais:** `file_picker: ^13.0.0` (Abertura nativa de pastas de Downloads/Documentos)
* **Documentos e Compartilhamento:** `pdf: ^3.11.1` e `share_plus: ^10.0.2`
* **Automação de Build:** GitHub Actions com injeção automática de ícones, permissões, receivers nativos no Android e publicação direta na aba **Releases**.

---

## 3. Estrutura de Pastas e Mapeamento de Arquivos

```text
lib/
├── main.dart                               # Ponto de entrada, pt_BR, MultiProvider e inicialização do NotificationService
├── core/
│   ├── database/
│   │   └── db_helper.dart                  # Singleton SQLite v2 com migration no onUpgrade e restauração atômica
│   ├── services/
│   │   ├── pdf_service.dart                # Emissão de relatório executivo contábil em PDF A4
│   │   └── notification_service.dart       # Motor de alarmes com agendamento nativo Android (AndroidScheduleMode.exactAllowWhileIdle)
│   └── theme/
│       └── app_theme.dart                  # Material Design 3, Dark Slate (#0F172A), Verde (#16A34A), Carmim (#DC2626)
├── data/
│   ├── models/
│   │   ├── transacao_model.dart            # Model de lançamentos (PJ/PF, MEI, parcelamento e agendamentoId)
│   │   ├── agendamento_model.dart          # Model de agendamentos (até 600 min e antecedência de alarme)
│   │   ├── cofrinho_model.dart             # Model de metas financeiras do salão
│   │   └── produto_model.dart              # Model de produtos e insumos com quantidade mínima
│   └── repositories/
│       ├── transacao_repository.dart       # CRUD no SQLite (inclui deletarPorAgendamentoId para estornos)
│       ├── agendamento_repository.dart     # CRUD no SQLite da tabela agendamentos
│       ├── cofrinho_repository.dart        # CRUD no SQLite da tabela cofrinhos
│       └── produto_repository.dart         # CRUD no SQLite da tabela produtos
├── controllers/
│   └── financeiro_controller.dart          # Cérebro do sistema: caixa, saldos, agenda, teto do MEI dinâmico e estoque
└── views/
    ├── home/
    │   └── home_screen.dart                # Barra de navegação inferior (Caixa, Agenda, Clientes, Relatórios, MEI)
    ├── dashboard/
    │   └── dashboard_view.dart             # Card Principal limpo em grade 2x2, atalhos amplos e extrato diário
    ├── formulario/
    │   └── novo_lancamento_view.dart       # Formulário unificado (Lançamentos normais, Gastos Pessoais e Saldo Histórico)
    ├── agenda/
    │   ├── agenda_view.dart                # Lista cronológica, WhatsApp, estorno de baixas e cancelamento
    │   ├── mapa_vagas_view.dart            # Grade visual cronológica de slots de 30 min (Livre, Ocupado, Encerrado)
    │   └── novo_agendamento_view.dart      # Agendamentos de até 10 horas com escolha da antecedência do alarme
    ├── estoque/
    │   ├── estoque_view.dart               # Catálogo de insumos, alerta de falta e movimentação com 1 toque
    │   └── novo_produto_view.dart          # Cadastro/edição de produtos de uso interno e revenda
    ├── clientes/
    │   └── clientes_view.dart              # CRM com histórico por cliente, total gasto e pendências
    ├── cofrinho/
    │   └── cofrinho_view.dart              # Metas visuais com trava contra saldo insuficiente e botão de visibilidade
    └── relatorios/
        ├── relatorios_view.dart            # Gráficos de barras mensais e balanço consolidado de sobras
        └── painel_mei_view.dart            # Acompanhamento do teto anual dinâmico (Lei Complementar 238/2026)
4. Esquema do Banco de Dados SQLite (bella_finance_v5.db - Versão 2)
Tabela transacoes
id INTEGER PRIMARY KEY AUTOINCREMENT
descricao TEXT NOT NULL
cliente TEXT (Opcional, omitido em contas PF e em lançamentos históricos)
valor REAL NOT NULL
tipo TEXT NOT NULL (entrada ou saida)
ambito TEXT NOT NULL (PJ ou PF)
categoria TEXT NOT NULL
formaPagamento TEXT NOT NULL (Dinheiro, Pix, Débito, Crédito, Outros)
status TEXT NOT NULL (Pago ou Pendente)
tipoCusto TEXT (Fixo, Variável, Emergência - para saídas PJ)
tipoReceita TEXT (Serviço, Produto - para receitas PJ)
parcelaAtual INTEGER DEFAULT 1
totalParcelas INTEGER DEFAULT 1
agendamento_id INTEGER (Chave estrangeira lógica para rastreio e estorno de baixas)
data TEXT NOT NULL (ISO-8601)
Tabela agendamentos
id INTEGER PRIMARY KEY AUTOINCREMENT
cliente TEXT NOT NULL
servico TEXT NOT NULL
valor REAL NOT NULL
dataHoraInicio TEXT NOT NULL (ISO-8601)
duracaoMinutos INTEGER NOT NULL (De 30 a 600 minutos)
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
5.1. Contabilidade Real Integrada (PJ & PF)
Fórmula do Saldo Disponível em Caixa (Em Mãos):
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
Resumo Visual em Grade 2x2:
🟢 Receita do Mês: Faturamento operacional do salão.
🔴 Despesas Salão: Custos fixos e insumos da empresa.
🟣 Gastos Pessoais: Dinheiro retirado pelo profissional para compras de uso pessoal.
🔵 Sobra do Mês: Lucro limpo que realmente sobrou após pagar o salão e retirar as despesas pessoais.
Validação de Retiradas Pessoais: O formulário de despesas pessoais (PF) exibe o saldo em mãos em tempo real e bloqueia retiradas acima do dinheiro existente.
5.2. Módulo MEI Atualizado com a Lei Complementar nº 238/2026
O teto de faturamento anual do MEI ajusta-se automaticamente com base no ano da transação/consulta:
Até 2026: Teto de **R
81.000
,
00
∗
∗
(
M
e
ˊ
d
i
a
:
R
81.000,00∗∗(M 
e
ˊ
 dia:R
 6.750,00/mês).
Ano de 2027: Teto de **R
110.000
,
00
∗
∗
(
M
e
ˊ
d
i
a
:
R
110.000,00∗∗(M 
e
ˊ
 dia:R
 9.166,67/mês).
Ano de 2028 em diante: Teto de **R
140.000
,
00
∗
∗
(
M
e
ˊ
d
i
a
:
R
140.000,00∗∗(M 
e
ˊ
 dia:R
 11.666,67/mês).
Segregação Obrigatória: Divisão transparente entre prestação de Serviços e Venda de Produtos para facilidade no preenchimento da declaração anual DASN-SIMEI.
Alertas Visuais: Disparo de avisos aos 70%, 85% e 95% do teto legal vigente.
5.3. Cadastro de Saldo Histórico / Início de Uso (BUG-01)
Permite cadastrar montantes acumulados do passado (retroativos até 24 meses) para quem já operava antes de instalar o aplicativo.
Atalhos rápidos: "Início do Ano", "1 mês atrás", "3 meses atrás", "5 meses atrás", "6 meses atrás" e "12 meses atrás".
Oculta a obrigatoriedade de clientes e permite categorização direta para alimentar o teto anual do MEI e o saldo de caixa sem poluir a agenda ou o extrato diário.
5.4. Cofrinho Patrimonial Neutro (BUG-02)
Depósitos e resgates ajustam a reserva patrimonial na tabela cofrinhos sem inserir despesas ou receitas fictícias na tabela transacoes, eliminando duplas deduções e receitas fantasmas na declaração do MEI.
Validação de segurança: Não permite guardar valores acima do saldo disponível em mãos no caixa.
Olhinho de visibilidade para ocultar valores na tela com 1 toque.
5.5. Notificações e Alarmes em Segundo Plano (BUG-03)
Integração nativa com ScheduledNotificationReceiver e ScheduledNotificationBootReceiver no Android.
O alarme dispara no horário exato configurado (10 min, 15 min, 30 min, 45 min, 1h ou 2h antes) mesmo com o aplicativo fechado ou com a tela bloqueada.
5.6. Baixa com Vínculo e Estorno Automático (BUG-04)
A baixa com 1 toque grava o ID do agendamento na coluna agendamento_id da transação criada no Caixa PJ.
Se o agendamento for posteriormente marcado como "Cancelado" ou for excluído, o sistema localiza a receita atrelada e estorna o valor do Caixa PJ e do relatório do MEI imediatamente.
5.7. Restauração Atômica de Backup (BUG-05)
O processo de restauração via DatabaseHelper.instance.restaurarBancoDados é executado dentro de uma transação atômica do SQLite (db.transaction).
Se o arquivo .json estiver corrompido ou for interrompido, o SQLite executa ROLLBACK automático, mantendo os dados originais do usuário 100% intactos.
6. Histórico de Correções Críticas (Changelog)
ID	Descrição	Status	Solução Implementada
BUG-01	Ausência de lançamento simplificado de saldo histórico retroativo	✅ Resolvido	Modo "Saldo Histórico Anterior" no formulário com atalhos de meses anteriores e classificação MEI.
BUG-02	Dupla dedução e receitas fantasmas causadas por transações de cofrinho	✅ Resolvido	Padronização neutra via tabela cofrinhos e fórmula consolidada no getter saldoAtual.
BUG-03	Alarmes de agendamento não disparavam com o app fechado	✅ Resolvido	Configuração de receivers nativos no Android e agendamento via NotificationService v22+.
BUG-04	Falta de estorno contábil ao cancelar atendimento com baixa realizada	✅ Resolvido	Adição da coluna agendamento_id (Migration v2) e estorno atômico em cancelamentos/exclusões.
BUG-05	Perda parcial de banco durante restauração de JSON corrompido	✅ Resolvido	Envelopamento do processo em db.transaction com rollback automático no SQLite.
7. Pipeline de Integração Contínua (CI/CD)
O projeto utiliza GitHub Actions (.github/workflows/build_apk.yml) configurado para:
Gerar o ambiente nativo Android com Java 17 e Flutter Stable.
Injetar automaticamente permissões e receptores de notificação em segundo plano no AndroidManifest.xml.
Configurar compatibilidade com Java Desugaring (desugar_jdk_libs:2.1.4) para suporte a alarmes exatos em todas as versões do Android.
Gerar o instalador .apk de produção (--release --no-tree-shake-icons).
Armazenar o artefato com retenção de 1 dia (para não estourar a cota gratuita de 500 MB).
Criar automaticamente uma Release no GitHub com download direto do instalador.
