# 🌸 Bella Gestão — Documentação Técnica & de Requisitos (PRD)

> **Versão:** 2.1 (CRM Oficial de Clientes, Ficha Técnica do Salão, Histórico 360º e Banco v3)  
> **Modelo:** 100% Offline (Local-First)  
> **Stack:** Flutter (Dart) + SQLite (`sqflite`) + State Management (`Provider`)  
> **CI/CD:** GitHub Actions (Compilação de APK Release e publicação direta em Releases)  
> **Público-alvo:** Profissionais autônomos e MEIs da área da beleza (cabeleireiras, manicures, esteticistas).

---

## 1. Visão Geral e Propósito do Produto
O **Bella Gestão** é um ecossistema mobile completo, 100% offline e sem custos de assinatura ou servidores em nuvem, projetado para ser o centro operacional do profissional de beleza autônomo.

O sistema integra seis pilares essenciais:
1. **CRM de Clientes & Ficha Técnica:** Cadastro formal de clientes com telefone/WhatsApp e campo para fórmulas de coloração, químicas, preferências e alergias, unificando serviços passados (do início do ano) com os agendamentos de hoje.
2. **Contabilidade Real Unificada:** Dedução transparente dos gastos pessoais (PF) da receita operacional do salão (PJ), informando com precisão o lucro líquido real em mãos sem quebrar as regras fiscais do MEI.
3. **Conformidade Fiscal com o MEI (DASN-SIMEI):** Teto anual dinâmico e escalonado conforme a **Lei Complementar nº 238/2026** (R$ 81 mil até 2026, R$ 110 mil em 2027 e R$ 140 mil em 2028), com discriminação entre Serviços e Produtos.
4. **Agenda Inteligente com Alarmes Nativos:** Procedimentos de 30 minutos até 10 horas contínuas, com alarmes prévios que tocam no aparelho mesmo com o aplicativo fechado ou tela bloqueada.
5. **Baixa e Estorno Conectados:** Baixa com 1 toque vinculada ao ID do agendamento; cancelamentos ou exclusões estornam o valor do Caixa PJ e do relatório MEI na mesma hora.
6. **Segurança de Dados com Restauração Atômica:** Backup em arquivo local `.json` com restauração protegida por transações no SQLite (se o arquivo estiver com erro, nada é apagado).

---

## 2. Stack Tecnológica e Dependências

* **Framework:** Flutter 3.x (Canal Stable)
* **Linguagem:** Dart
* **Banco de Dados Local:** `sqflite: ^2.3.3+1` + `path_provider: ^2.1.4` (Banco: `bella_finance_v5.db`, Versão de Schema: 3)
* **Gerenciamento de Estado:** `provider: ^6.1.2`
* **Datas e Formatação:** `intl: ^0.19.0` (Localização brasileira `pt_BR`)
* **Alarmes & Notificações Nativas:** `flutter_local_notifications: ^22.0.0` + `timezone: ^0.10.0`
* **Gerenciamento de Arquivos Locais:** `file_picker: ^13.0.0` (Abertura de pastas e downloads do celular)
* **Documentos e Compartilhamento:** `pdf: ^3.11.1` e `share_plus: ^10.0.2`
* **Pipeline CI/CD:** GitHub Actions com injeção automática de ícones, permissões, receivers nativos do Android e publicação automática de **Releases** com retenção de artefatos de 1 dia.

---

## 3. Estrutura de Pastas e Mapeamento de Arquivos

```text
lib/
├── main.dart                               # Ponto de entrada, pt_BR, MultiProvider e NotificationService.init()
├── core/
│   ├── database/
│   │   └── db_helper.dart                  # Singleton SQLite v3 (migrations onUpgrade v2 e v3, restauração atômica)
│   ├── services/
│   │   ├── pdf_service.dart                # Emissão de relatório executivo contábil em PDF A4
│   │   └── notification_service.dart       # Motor de alarmes em segundo plano (AndroidScheduleMode.exactAllowWhileIdle)
│   └── theme/
│       └── app_theme.dart                  # Material Design 3, Dark Slate (#0F172A), Verde (#16A34A), Carmim (#DC2626)
├── data/
│   ├── models/
│   │   ├── transacao_model.dart            # Model financeiro (PJ/PF, MEI, parcelamento e agendamentoId)
│   │   ├── agendamento_model.dart          # Model de agenda (até 600 min e antecedência de alarme)
│   │   ├── cofrinho_model.dart             # Model de metas de economia do salão
│   │   ├── produto_model.dart              # Model de estoque de insumos e revenda com quantidade mínima
│   │   └── cliente_model.dart              # Model de cliente (Nome, WhatsApp, Ficha Técnica e data de cadastro)
│   └── repositories/
│       ├── transacao_repository.dart       # CRUD no SQLite (com deletarPorAgendamentoId para estornos)
│       ├── agendamento_repository.dart     # CRUD no SQLite da tabela agendamentos
│       ├── cofrinho_repository.dart        # CRUD no SQLite da tabela cofrinhos
│       ├── produto_repository.dart         # CRUD no SQLite da tabela produtos
│       └── cliente_repository.dart         # CRUD no SQLite da tabela clientes
├── controllers/
│   └── financeiro_controller.dart          # Cérebro do sistema: caixa, saldos, agenda, teto do MEI dinâmico, estoque e CRM
└── views/
    ├── home/
    │   └── home_screen.dart                # Barra de navegação inferior (Caixa, Agenda, Clientes, Relatórios, MEI)
    ├── dashboard/
    │   └── dashboard_view.dart             # Resumo mensal limpo em grade 2x2, atalhos amplos e extrato diário
    ├── formulario/
    │   └── novo_lancamento_view.dart       # Formulário dinâmico (PJ, PF e Saldo Histórico Retroativo)
    ├── agenda/
    │   ├── agenda_view.dart                # Lista diária, WhatsApp, estorno de baixas e cancelamento
    │   ├── mapa_vagas_view.dart            # Grade visual cronológica de slots de 30 min (Livre, Ocupado, Encerrado)
    │   └── novo_agendamento_view.dart      # Agendamentos de até 10h com escolha da antecedência do alarme e autocomplete
    ├── estoque/
    │   ├── estoque_view.dart               # Catálogo de insumos, alerta de falta e compra/baixa com 1 toque
    │   └── novo_produto_view.dart          # Cadastro/edição de produtos de uso interno e revenda
    ├── clientes/
    │   ├── clientes_view.dart              # CRM com busca, importação de clientes antigos, WhatsApp e Visão 360º
    │   └── novo_cliente_view.dart          # Formulário de cliente com Ficha Técnica e Correção em Cascata
    ├── cofrinho/
    │   └── cofrinho_view.dart              # Metas com trava de saldo disponível e botão de visibilidade
    └── relatorios/
        ├── relatorios_view.dart            # Gráficos de barras mensais e balanço consolidado de sobras
        └── painel_mei_view.dart            # Painel do MEI dinâmico com tetos da Lei Complementar nº 238/2026
4. Esquema do Banco de Dados SQLite (bella_finance_v5.db - Versão 3)
Tabela clientes (Adicionada na Versão 3)
id INTEGER PRIMARY KEY AUTOINCREMENT
nome TEXT NOT NULL
telefone TEXT (Opcional, com disparo direto para WhatsApp)
observacoesTecnicas TEXT (Ficha do salão: fórmulas, tintas, alergias e estilo)
dataCadastro TEXT NOT NULL (ISO-8601)
Tabela transacoes (Atualizada na Versão 2)
id INTEGER PRIMARY KEY AUTOINCREMENT
descricao TEXT NOT NULL
cliente TEXT (Opcional, omitido em contas PF e lançamentos históricos)
valor REAL NOT NULL
tipo TEXT NOT NULL (entrada ou saida)
ambito TEXT NOT NULL (PJ ou PF)
categoria TEXT NOT NULL
formaPagamento TEXT NOT NULL (Dinheiro, Pix, Débito, Crédito, Outros)
status TEXT NOT NULL (Pago ou Pendente)
tipoCusto TEXT (Fixo, Variável, Emergência - saídas PJ)
tipoReceita TEXT (Serviço, Produto - receitas PJ)
parcelaAtual INTEGER DEFAULT 1
totalParcelas INTEGER DEFAULT 1
agendamento_id INTEGER (Chave lógica para estorno automático)
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
categoria TEXT NOT NULL
quantidadeAtual INTEGER NOT NULL
quantidadeMinima INTEGER NOT NULL
precoCusto REAL NOT NULL
precoVenda REAL NOT NULL
unidade TEXT NOT NULL
5. Regras de Negócio e Funcionalidades Ativas
5.1. CRM Oficial de Clientes & Ficha Técnica
Cadastro Dedicado com Ficha Técnica: Campo exclusivo para registrar fórmulas de tintura (ex: "7.1 com Ox 20vol"), químicas anteriores, alergias e preferências de corte.
Botão Mágico "Importar Clientes Antigos": Varre em 1 segundo todas as transações passadas do início do ano e agendamentos antigos, cadastrando todos os clientes automaticamente sem digitação manual.
Correção e Unificação em Cascata: Ao editar o nome de um cliente (ex: de "Mari" para "Mariana Silva"), o sistema atualiza em cascata todos os lançamentos passados e agendamentos futuros para não quebrar o histórico.
Visão 360º ao Tocar no Cliente:
Ficha Técnica e fórmulas em destaque dourado;
Total já investido no salão e valores pendentes;
Agendamentos futuros marcados na agenda;
Histórico cronológico de todos os serviços realizados (inclusive os lançados retroativamente).
Atalho WhatsApp com 1 Toque: Disparo direto de mensagens para o número da cliente via share_plus.
5.2. Dashboard Limpo e Contabilidade Real
Fórmula do Saldo Disponível em Caixa:
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
Grade 2x2 Espaçosa:
🟢 Receita do Mês: Faturamento operacional do salão.
🔴 Despesas Salão: Custos fixos e insumos da empresa.
🟣 Gastos Pessoais: Total retirado do salão para compras pessoais no mês.
🔵 Sobra do Mês: Faturamento real limpo após pagar o salão e retirar as despesas pessoais.
Atalhos Otimizados: Acesso rápido amplo apenas para Cofrinho / Metas e Estoque Insumos (eliminando redundâncias).
5.3. Módulo MEI Dinâmico (Lei Complementar nº 238/2026)
O limite de faturamento anual adapta-se automaticamente conforme o ano de referência da consulta:
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
Segregação Obrigatória: Divisão transparente entre Serviços e Venda de Produtos para a declaração anual DASN-SIMEI.
Alertas Visuais: Disparo de avisos aos 70%, 85% e 95% do teto legal vigente.
5.4. Lançamento de Saldo Histórico Retroativo (BUG-01)
Permite cadastrar montantes acumulados do passado (retroativos até 24 meses) para quem já operava antes de instalar o aplicativo.
Atalhos rápidos: "Início do Ano", "1 mês atrás", "3 meses atrás", "5 meses atrás", "6 meses atrás" e "12 meses atrás".
Oculta a obrigatoriedade de clientes e permite categorização direta para alimentar o teto anual do MEI e o saldo de caixa sem poluir a agenda ou o extrato diário.
5.5. Cofrinho Patrimonial Neutro (BUG-02)
Depósitos e resgates ajustam a reserva patrimonial na tabela cofrinhos sem inserir despesas ou receitas fictícias na tabela transacoes, eliminando duplas deduções e receitas fantasmas na declaração do MEI.
Validação de segurança: Não permite guardar valores acima do saldo disponível em mãos no caixa.
Olhinho de visibilidade para ocultar valores na tela com 1 toque.
5.6. Notificações e Alarmes em Segundo Plano (BUG-03)
Integração nativa com ScheduledNotificationReceiver e ScheduledNotificationBootReceiver no Android.
O alarme dispara no horário exato configurado (10 min, 15 min, 30 min, 45 min, 1h ou 2h antes) mesmo com o aplicativo fechado ou com a tela bloqueada.
5.7. Baixa com Vínculo e Estorno Automático (BUG-04)
A baixa com 1 toque grava o ID do agendamento na coluna agendamento_id da transação criada no Caixa PJ.
Se o agendamento for posteriormente marcado como "Cancelado" ou for excluído, o sistema localiza a receita atrelada e estorna o valor do Caixa PJ e do relatório do MEI imediatamente.
5.8. Restauração Atômica de Backup (BUG-05)
O processo de restauração via DatabaseHelper.instance.restaurarBancoDados é executado dentro de uma transação atômica do SQLite (db.transaction).
Se o arquivo .json estiver corrompido ou for interrompido, o SQLite executa ROLLBACK automático, mantendo os dados originais do usuário 100% intactos.
6. Histórico de Correções e Melhorias (Changelog)
Versão / ID	Descrição	Status	Solução Implementada
v2.1	Gestão de Clientes (CRM Oficial) & Ficha Técnica	✅ Concluído	Tabela clientes v3, Ficha de Fórmulas, botão "Importar Clientes Antigos", correção em cascata e Visão 360º.
v2.0	Atualização do Teto MEI para a Lei Complementar 238/2026	✅ Concluído	Teto anual dinâmico e escalonado (R
81
k
a
t
e
ˊ
2026
,
R
81kat 
e
ˊ
 2026,R
 110k em 2027 e R$ 140k em 2028).
BUG-05	Perda parcial de dados durante restauração de backup corrompido	✅ Resolvido	Restauração envelopada em db.transaction com rollback automático no SQLite.
BUG-04	Falta de estorno contábil ao cancelar atendimento com baixa realizada	✅ Resolvido	Adição da coluna agendamento_id (Migration v2) e estorno atômico em cancelamentos/exclusões.
BUG-03	Alarmes de agendamento não disparavam com o app fechado	✅ Resolvido	Configuração de receivers nativos no Android e agendamento via NotificationService v22+.
BUG-02	Dupla dedução e receitas fantasmas causadas por transações de cofrinho	✅ Resolvido	Padronização neutra via tabela cofrinhos e fórmula consolidada no getter saldoAtual.
BUG-01	Ausência de lançamento simplificado de saldo histórico retroativo	✅ Resolvido	Modo "Saldo Histórico Anterior" no formulário com atalhos de meses anteriores e classificação MEI.
7. Pipeline de Integração Contínua (CI/CD)
O projeto utiliza GitHub Actions (.github/workflows/build_apk.yml) configurado para:
Gerar o ambiente nativo Android com Java 17 e Flutter Stable.
Injetar automaticamente permissões e receptores de notificação em segundo plano no AndroidManifest.xml.
Configurar compatibilidade com Java Desugaring (desugar_jdk_libs:2.1.4) para suporte a alarmes exatos em todas as versões do Android.
Gerar o instalador .apk de produção (--release --no-tree-shake-icons).
Armazenar o artefato com retenção de 1 dia (para não estourar a cota gratuita de 500 MB).
Criar automaticamente uma Release no GitHub com download direto do instalador.
