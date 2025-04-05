# Relatório do Projeto ETL

## Introdução

Este projeto foi desenvolvido em OCaml com o objetivo de criar um processo ETL para extrair, transformar e carregar dados de pedidos e seus itens. O foco principal é gerar saídas agregadas que alimentem dashboards de visualização, utilizando uma abordagem funcional que separa funções puras (para transformação e agregação) de funções impuras (para operações de I/O, download e persistência).

## Etapas do Projeto

### 1. Extração (Extract)
- **Fontes de Dados:**  
  Os dados são extraídos de dois arquivos CSV. Um dos arquivos é baixado diretamente de uma URL usando a biblioteca *Cohttp_lwt_unix*, permitindo a obtenção dinâmica dos dados.
- **Carregamento dos Dados:**  
  Os arquivos CSV são lidos e transformados em listas de records (definidos em *types.ml*) através de funções auxiliares como *load_order* e *load_order_item*.

### 2. Transformação (Transform)
- **Junção dos Dados:**  
  A função *join_and_compute* realiza um inner join entre os pedidos e seus itens. Apenas os pedidos com itens associados são considerados.
- **Cálculo dos Totais:**  
  Para cada item, calcula-se a receita (quantidade × preço) e o imposto (tax × receita). O somatório desses valores para cada pedido resulta nos campos *total_amount* e *total_taxes*.
- **Agregação:**  
  A função *group_by_month_year* agrupa os pedidos por mês e ano e calcula a média de receita e de impostos, permitindo uma análise temporal agregada dos dados.

### 3. Carregamento (Load)
- **Geração de CSV:**  
  O resultado do processamento é exportado para um arquivo CSV (*output.csv*) que contém os campos `order_id`, `total_amount` e `total_taxes`.
- **Exportação Extra:**  
  Um arquivo adicional (*extra.csv*) é gerado com dados agregados (ano, mês, receita média e impostos médios). Esses dados também são persistidos no SQLite na tabela `extra_output`.
- **Persistência em Banco de Dados:**  
  Os dados finais são salvos em um banco de dados SQLite, onde há tabelas separadas para os totais por pedido e para os dados agregados.

### 4. Organização e Testes
- **Estrutura do Projeto:**  
  O projeto está organizado utilizando o Dune, com os seguintes módulos principais:
  - *types.ml*: Define os records usados para representar os dados.
  - *pure.ml*: Contém funções puras para transformação, junção e agregação dos dados.
  - *impure.ml*: Implementa operações de I/O, download HTTP e persistência em SQLite.
  - *main.ml*: Ponto de entrada do ETL, integrando a execução completa do processo.
  - *test/*: Conjunto de testes unitários para as funções puras e impuras.
- **Testes:**  
  Foram implementadas suítes de testes (usando OUnit2) para verificar o funcionamento correto de todas as funções, tanto puras quanto impuras, garantindo robustez e facilitando futuras manutenções.

## Desafios e Ajustes Realizados

- **Separação entre Funções Puras e Impuras:**  
  A divisão clara entre transformação (funções puras) e operações de I/O (funções impuras) foi fundamental para manter o código modular e testável.

- **Anotações de Tipo e Uso de Funções de Ordem Superior:**  
  Algumas funções, como *group_order_items* e *compute_totals*, exigiram anotações de tipo explícitas para evitar ambiguidades, reforçando o uso de funções de ordem superior como *List.fold_left* e *List.filter_map*.

- **Configuração de Dependências e PPX:**  
  A integração com *Lwt* e a configuração correta do *lwt_ppx* foram essenciais para o funcionamento adequado das operações assíncronas, principalmente no download dos arquivos CSV.

- **Integração com SQLite:**  
  Foram realizados ajustes para o manuseio de callbacks e bindings no SQLite, garantindo a inserção correta dos dados nas tabelas `order_output` e `extra_output`.

- **Documentação e Testes:**  
  As docstrings foram aprimoradas em todos os módulos, e uma suíte de testes abrangente foi criada para validar tanto as funções puras quanto as impuras, incluindo casos com e sem filtros, e a verificação de que apenas pedidos com itens sejam processados.

- **Ajustes na Estrutura e Gerenciamento de Dependências:**  
  Modificações na configuração do Dune (como a desativação do wrapping de módulos) foram implementadas para evitar dependências circulares e melhorar a modularidade do projeto.

## Considerações Finais

O projeto segue boas práticas do paradigma funcional, utilizando intensivamente funções de ordem superior e garantindo a separação entre funções puras e impuras. Essa abordagem não só melhora a legibilidade e a manutenibilidade do código, mas também facilita a criação de testes robustos e a evolução do sistema.

## Instruções para Reproduzir o Projeto

Siga as instruções de baixar dependências e executar o projeto como foram informadas no [README.md](README.md).

---

## Informações Adicionais e Perspectivas Futuras

- **Overview e Inputs:**  
  Além dos dados extraídos dos arquivos CSV, o projeto foi estruturado para processar diariamente dois arquivos: um contendo os pedidos e outro com os itens de cada pedido. Embora não haja um diagrama MER formal incluso, a estrutura dos dados (pedidos e itens) segue um modelo simples de 1:N, onde cada pedido pode ter múltiplos itens.

- **Projeto Modular:**  
  A separação dos módulos em funções puras e impuras foi decisiva para facilitar testes e futuras expansões. Essa modularidade permite, por exemplo, a incorporação de novos filtros ou fontes de dados sem afetar o núcleo de transformação.

- **Desenvolvimento Iterativo:**  
  Durante o desenvolvimento, a implementação passou por diversas iterações para melhorar a eficiência, como a otimização do uso do *fold_left* para calcular totais em uma única passagem. Essa melhoria reduziu a redundância e aumentou a performance.

- **Reprodutibilidade:**  
  O projeto foi ajustado para garantir que, ao ser compilado e testado em diferentes ambientes (inclusive em contêineres Docker), todas as dependências sejam corretamente resolvidas e os testes passem sem problemas.

- **Futuras Melhorias:**  
  Entre as possibilidades para o futuro, destaca-se:
  - Expansão para tratar volumes maiores de dados.
  - Integração com outras fontes de dados, como APIs REST.
  - Implementação de pipelines de CI/CD para automatizar testes e compilações.
  - Melhoria na interface de filtragem via linha de comando para uma experiência de usuário mais intuitiva.

## AI Usage

Declaro que, embora tenha utilizado ferramentas de auxílio para referência e organização das ideias durante o desenvolvimento, todo o código e a documentação foram revisados e adaptados manualmente para atender aos requisitos do projeto. Tanto este relatório quanto o readme foram auxiliados por ferramentas de IA.

## Requirements

### Project Requirements
- [x] O projeto deve ser implementado em OCaml.
- [x] É necessário utilizar funções como `map`, `reduce` e `filter` para o processamento dos dados.
- [x] O código deve conter funções para leitura e escrita de arquivos CSV, resultando em funções impuras.
- [x] Deve haver separação clara entre funções impuras e funções puras nos arquivos do projeto.
- [x] A entrada deve ser carregada em uma estrutura de lista de records.
- [x] É obrigatório o uso de funções helper para carregar os campos em um record.
- [x] Um relatório detalhado deve ser escrito, explicando como as etapas foram implementadas e indicando o uso ou não de AI Generativa.

### Optional Requirements
- [x] Leitura dos dados de entrada de um arquivo estático na internet (exposto via HTTP).
- [x] Salvamento dos dados de saída em um banco de dados SQLite.
- [x] Processamento dos dados via inner join entre as tabelas de entrada.
- [x] Organização do projeto ETL utilizando Dune.
- [x] Documentação de todas as funções utilizando o formato de docstring.
- [x] Geração de uma saída adicional contendo a média da receita e dos impostos agrupados por mês e ano.
- [x] Implementação de testes completos para as funções puras.

---

Este relatório serve como um roteiro detalhado para reproduzir, entender e manter o projeto ETL em OCaml, cobrindo desde a extração e transformação dos dados até a persistência e validação via testes unitários, além de destacar melhorias implementadas e perspectivas para futuras evoluções do sistema.
