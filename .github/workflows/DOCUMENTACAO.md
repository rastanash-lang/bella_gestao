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

```text
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
