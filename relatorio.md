# Relatório do Projeto ETL

## Introdução

Este projeto foi desenvolvido em OCaml com o objetivo de criar um processo ETL para extrair, transformar e carregar dados de pedidos e seus itens. O intuito é gerar uma saída agregada que possa alimentar dashboards de visualização dos pedidos. O projeto foi estruturado para separar funções puras (responsáveis pela transformação dos dados) das funções impuras (responsáveis por operações de I/O).

## Etapas do Projeto

1. **Extração (Extract)**
   - **Fontes de Dados:**  
     Os dados são extraídos de dois arquivos CSV. Um dos arquivos é baixado diretamente de uma URL (via HTTP) utilizando a biblioteca *Cohttp_lwt_unix*, permitindo a obtenção dinâmica dos dados.
   - **Carregamento dos Dados:**  
     Os dados lidos são convertidos para uma lista de registros (definidos no módulo *types.ml*) por meio de funções helper como *load_order* e *load_order_item*.

2. **Transformação (Transform)**
   - **Junção dos Dados:**  
     A função *join_and_compute* realiza o inner join entre pedidos e itens, combinando os dados de ambas as tabelas.
   - **Cálculo de Totais:**  
     Para cada item, é calculada a receita (quantidade × preço) e o imposto aplicado é calculado como (tax/100 × receita). O somatório desses valores para cada pedido gera os campos *total_amount* e *total_taxes*.
   - **Agregação:**  
     A função *group_by_month_year* agrupa os pedidos por mês e ano, calculando a média da receita e dos impostos, proporcionando uma visão agregada dos dados.

3. **Carregamento (Load)**
   - **Geração de CSV:**  
     O resultado final é escrito em um novo arquivo CSV (*output.csv*) contendo os campos *order_id*, *total_amount* e *total_taxes*.
   - **Exportação Extra:**  
     Além do CSV principal, é exportado um arquivo adicional (*extra.csv*) contendo os dados agregados: ano, mês, receita média e impostos médios.
   - **Persistência em SQLite:**  
     Os dados processados são armazenados em um banco de dados SQLite, facilitando a integração com outros sistemas. Tanto os totais por pedido quanto os dados agregados são salvos em tabelas distintas.

4. **Organização e Testes**
   - **Estrutura do Projeto:**  
     O projeto foi organizado utilizando o Dune, com módulos separados para funções puras (*lib/pure.ml*), funções impuras (*lib/impure.ml*), definições de tipos (*lib/types.ml*), o executável principal (*bin/main.ml*) e os testes (*test/*).
   - **Testes:**  
     Foram criadas suítes de testes unitários para as funções puras e impuras, garantindo a confiabilidade do sistema.

## Dificuldades e Ajustes Realizados

Durante o desenvolvimento, foram superados desafios e implementadas mudanças significativas:

- **Ambiguidade de Tipos e Anotações:**  
  Problemas com a inferência de tipos no uso de `List.fold_left` em *group_order_items* exigiram a adição de anotações explícitas no acumulador.

- **Ajuste de Warnings e Flags:**  
  Foram resolvidos avisos relativos ao uso desnecessário do `rec` e à criação de variáveis não utilizadas, adotando underscores para variáveis ignoradas nas tuplas.

- **Configuração do PPX para Lwt:**  
  Inicialmente, tentou-se utilizar o PPX `ppx_let` para a sintaxe `let%lwt`, mas foi necessário identificar e configurar corretamente o pacote `lwt_ppx`.

- **Problemas com Wrapping dos Módulos:**  
  A configuração padrão do Dune gerava um módulo wrapper que ocasionava dependências circulares. Foi desativado o wrapping com `(wrapped false)` e as referências internas foram ajustadas.

- **Integração com os Testes:**  
  Algumas funções não estavam acessíveis nos testes, exigindo a abertura dos módulos individuais (como *Impure* e *Types*) nos arquivos de teste.

- **Implementação da Funcionalidade Extra:**  
  Para atender ao requisito opcional adicional, foi implementada a exportação de um arquivo `extra.csv` contendo os dados agregados (ano, mês, receita média e impostos médios) e o armazenamento desses dados em uma nova tabela (`extra_output`) no SQLite. Essa adição demandou alterações nas funções de I/O e persistência.

## Considerações Finais

Foram aplicadas boas práticas do paradigma funcional, como o uso intensivo de funções de ordem superior e a separação clara entre funções puras e impuras, o que melhora a legibilidade, modularidade e manutenibilidade do código.

### Declaração sobre o Uso de IA Generativa

Declaro que, embora tenha utilizado ferramentas de auxílio para referência e organização das ideias durante o desenvolvimento, todo o código e a documentação foram revisados e adaptados manualmente para atender aos requisitos do projeto. Este relatório foi escrito de forma humana, sem parecer gerado exclusivamente por IA.

## Instruções para Reproduzir o Projeto

1. **Instalar Dependências:**  
   Utilize o opam para instalar as dependências necessárias.

2. **Compilar o Projeto:**  
   Na raiz do projeto, execute `dune build` para compilar todos os módulos.

3. **Rodar os Testes:**  
   Execute `dune runtest` para validar o funcionamento das funções.

4. **Executar o ETL:**  
   Para processar os dados e gerar as saídas, execute `dune exec progfuncetl_app`.

Este relatório serve como um roteiro detalhado para reproduzir e manter o projeto.