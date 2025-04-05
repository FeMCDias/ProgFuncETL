# Relatório do Projeto ETL

## Introdução

Este projeto foi desenvolvido em OCaml com o objetivo de criar um processo ETL para extrair, transformar e carregar dados de pedidos e seus itens. Meu foco principal foi gerar saídas agregadas que alimentem dashboards de visualização, utilizando uma abordagem funcional que separa funções puras (para transformação e agregação) de funções impuras (para operações de I/O, download e persistência).

## Etapas do Projeto

### 1. Extração (Extract)
- **Fontes de Dados:**  
  Os dados são extraídos de dois arquivos CSV. Um dos arquivos é baixado diretamente de uma URL utilizando a biblioteca *Cohttp_lwt_unix*, o que me permitiu obter os dados dinamicamente e atualizá-los diariamente sem intervenção manual.
- **Carregamento dos Dados:**  
  Os arquivos CSV são lidos e convertidos em listas de records (definidos em *types.ml*) através de funções auxiliares como *load_order* e *load_order_item*. Esse processo de extração foi essencial para garantir que os dados estivessem estruturados e prontos para serem transformados.

### 2. Transformação (Transform)
- **Junção dos Dados:**  
  A função *join_and_compute* realiza um inner join entre os pedidos e seus itens, garantindo que apenas os pedidos com itens associados sejam processados. Essa abordagem eliminou a necessidade de múltiplas filtragens e centralizou a lógica de combinação dos dados.
- **Cálculo dos Totais:**  
  Para cada item, calculo a receita (quantidade × preço) e o imposto (tax × receita). O somatório desses valores para cada pedido resulta nos campos *total_amount* e *total_taxes*.
- **Agregação:**  
  A função *group_by_month_year* agrupa os pedidos por mês e ano e calcula a média de receita e de impostos, permitindo-me realizar uma análise temporal agregada dos dados.

### 3. Carregamento (Load)
- **Geração de CSV:**  
  O resultado do processamento é exportado para um arquivo CSV (*output.csv*) que contém os campos `order_id`, `total_amount` e `total_taxes`. Essa etapa facilita a visualização e o compartilhamento dos resultados.
- **Exportação Extra:**  
  Um arquivo adicional (*extra.csv*) é gerado com dados agregados (ano, mês, receita média e impostos médios). Esses dados também são persistidos no SQLite na tabela `extra_output`.
- **Persistência em Banco de Dados:**  
  Os resultados finais são salvos em um banco de dados SQLite, com tabelas separadas para os totais por pedido e para os dados agregados.

### 4. Organização e Testes
- **Estrutura do Projeto:**  
  Organizei o projeto utilizando o Dune, distribuindo-o nos seguintes módulos:
  - *types.ml*: Define os records que representam os dados.
  - *pure.ml*: Contém as funções puras responsáveis pela transformação, junção e agregação.
  - *impure.ml*: Implementa as operações de I/O, download via HTTP e persistência em SQLite.
  - *main.ml*: Ponto de entrada que integra todo o fluxo ETL.
  - *test/*: Conjunto de testes unitários para validar as funções puras usando OUnit2.
- **Testes:**  
  Implementei suítes de testes para verificar o funcionamento correto de todas as funções, garantindo robustez e facilitando futuras manutenções.

## Desafios e Ajustes Realizados

- **Separação entre Funções Puras e Impuras:**  
  A distinção entre as funções que realizam transformações (como `load_order`, `load_order_item` e `join_and_compute`) e aquelas que interagem com o sistema (como `read_csv_from_url` e `write_csv`) foi crucial para manter o código modular. Essa separação permitiu que eu testasse cada parte de forma isolada, mas exigiu um cuidado constante para que as funções puras permanecessem totalmente determinísticas.

- **Otimizações na Agregação de Dados:**  
  Inicialmente, o cálculo dos totais para cada pedido envolvia múltiplas iterações sobre os dados. Identifiquei essa ineficiência e otimizei a lógica utilizando um único `fold_left` com um acumulador que simultaneamente computava o total de receita e o total de impostos. Essa melhoria reduziu a redundância e melhorou a performance, especialmente quando o volume de dados aumentou.

- **Configuração de Dependências e Operações Assíncronas:**  
  Integrar o Lwt e configurar corretamente o `lwt_ppx` para as operações assíncronas, como o download dos arquivos CSV, foi um desafio. Ajustes finos no ambiente e na configuração das dependências foram necessários para que as operações ocorressem de forma estável, o que me permitiu aprender mais sobre o ecossistema de OCaml.

- **Integração com SQLite:**  
  A integração com o SQLite, através das funções `write_output_to_sqlite` e `write_extra_to_sqlite`, exigiu ajustes detalhados para tratar callbacks e bindings corretamente. Resolver problemas como o fechamento adequado das conexões e o tratamento de erros durante a inserção dos dados foi um aprendizado valioso, garantindo que a persistência dos dados ocorresse de forma confiável.

- **Ajustes na Estrutura e Modularidade:**  
  Alterações na configuração do Dune, como a desativação do wrapping de módulos, foram implementadas para evitar dependências circulares e manter o projeto bem modularizado. Essa mudança facilitou a manutenção e permitiu uma maior flexibilidade para futuras expansões ou adaptações.

- **Desafios Práticos e Lições Aprendidas:**  
  Durante o desenvolvimento, enfrentei desafios reais, como ajustar a lógica de transformação para evitar iterações redundantes e adaptar o código para funcionar de maneira consistente em diferentes ambientes de desenvolvimento (inclusive em contêineres Docker). Esses desafios me ensinaram a importância de um ciclo iterativo de testes e refinamentos, além de destacar a relevância de uma comunicação clara e de uma documentação detalhada para facilitar a manutenção futura.

## Considerações Finais

O projeto segue as melhores práticas do paradigma funcional, utilizando intensivamente funções de ordem superior e mantendo uma clara separação entre funções puras e impuras. Essa abordagem melhorou significativamente a legibilidade, a manutenibilidade e a capacidade de testar o sistema, além de facilitar a evolução do código ao longo do tempo.

## Instruções para Reproduzir o Projeto

Siga as instruções de baixar dependências e executar o projeto conforme descrito no [README.md](README.md).

---

## Informações Adicionais e Perspectivas Futuras

- **Overview e Inputs:**  
  Além dos dados extraídos dos arquivos CSV, o projeto foi estruturado para processar dois arquivos diários: um com os pedidos e outro com os itens de cada pedido. Embora não tenha incluído um diagrama MER formal, a relação 1:N entre pedidos e itens está bem definida e é fundamental para a transformação dos dados.

- **Projeto Modular:**  
  A separação dos módulos em funções puras e impuras foi essencial para facilitar a incorporação de novos filtros e a adaptação a mudanças de requisitos, demonstrando a flexibilidade da minha arquitetura.

- **Desenvolvimento Iterativo:**  
  O projeto evoluiu através de várias iterações, onde melhorias na eficiência – como a otimização do `fold_left` para acumular totais – foram implementadas à medida que identificava gargalos no processamento. Essa abordagem iterativa me permitiu ajustar rapidamente a solução conforme novos requisitos surgiam.

- **Reprodutibilidade:**  
  Adotei práticas que garantem a compilação e testes consistentes em diferentes ambientes, inclusive em contêineres Docker. Dessa forma, todas as dependências são resolvidas corretamente e o projeto se comporta de forma consistente.

- **Futuras Melhorias:**  
  Entre as possibilidades para o futuro, destaco:
  - Expansão para processar volumes maiores de dados.
  - Integração com outras fontes de dados, como APIs REST.
  - Implementação de pipelines de CI/CD para automatizar testes e builds.
  - Aperfeiçoamento da interface de filtragem via linha de comando para proporcionar uma experiência de usuário mais intuitiva.

## AI Usage

Declaro que, embora tenha utilizado ferramentas de auxílio para organizar e refinar as ideias durante o desenvolvimento, todo o código e a documentação foram revisados e adaptados manualmente para atender aos requisitos do projeto. Tanto este relatório quanto o README foram assistidos por ferramentas de IA, mas o conteúdo final reflete meu trabalho e minhas decisões de design.

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

Este relatório serve como um roteiro detalhado para reproduzir, entender e manter o projeto ETL em OCaml, abrangendo desde a extração e transformação dos dados até a persistência e validação por meio de testes unitários, além de destacar as otimizações implementadas e as perspectivas para futuras evoluções do sistema.
