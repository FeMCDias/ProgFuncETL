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
   - **Persistência em SQLite:**  
     Como funcionalidade opcional, os dados processados também são armazenados em um banco de dados SQLite, facilitando a integração com outros sistemas.

4. **Organização e Testes**
   - **Estrutura do Projeto:**  
     O projeto foi organizado utilizando Dune, com módulos separados para funções puras (*lib/pure.ml*), funções impuras (*lib/impure.ml*), definições de tipos (*lib/types.ml*), o executável principal (*bin/main.ml*) e os testes (*test/*).
   - **Testes:**  
     Foram criadas suítes de testes unitários para as funções puras e impuras, garantindo a confiabilidade do sistema.

## Dificuldades e Ajustes Realizados

Durante o desenvolvimento do projeto, algumas dificuldades e mudanças foram necessárias, dentre as quais destacam-se:

- **Ambiguidade de Tipos e Anotações:**  
  Houve problemas com a inferência de tipos, especialmente no uso do `List.fold_left` em *group_order_items*. Foi necessário adicionar anotações explícitas ao acumulador para que o compilador interpretasse corretamente o tipo da lista.

- **Ajuste de Warnings e Flags:**  
  Foram removidos avisos relacionados ao uso do `rec` em funções não-recursivas e aos padrões de desempacotamento de tuplas, utilizando underscores para indicar variáveis não utilizadas.

- **Configuração do PPX para Lwt:**  
  Inicialmente, foi tentado utilizar o PPX `ppx_let` para habilitar a sintaxe `let%lwt`, mas esse pacote não estava disponível. Após pesquisas, foi identificado que o pacote correto era o `lwt_ppx`, e as configurações do Dune foram ajustadas para utilizar `(preprocess (pps lwt_ppx))`.

- **Problemas com Wrapping dos Módulos:**  
  A configuração padrão do Dune gerava um módulo wrapper (ex.: *ProgFuncETL*) que ocasionava dependências circulares. Para resolver, foi desativado o wrapping com `(wrapped false)` e, consequentemente, as referências internas aos módulos foram ajustadas.

- **Integração com os Testes:**  
  Algumas funções não estavam acessíveis nos testes devido à forma como os módulos eram importados. Foi necessário abrir os módulos individuais (como *Impure* e *Types*) nos arquivos de teste para que todas as funções ficassem disponíveis.

Esses ajustes foram essenciais para que o projeto atendesse a todos os requisitos e funcionasse corretamente.

## Considerações Finais

Durante o desenvolvimento, foram aplicadas boas práticas do paradigma funcional, como o uso de funções de ordem superior e a clara separação entre funções puras e impuras. Essa abordagem melhora a legibilidade, modularidade e manutenibilidade do código.

### Declaração sobre o Uso de IA Generativa

Declaro que, embora tenha utilizado ferramentas de auxílio para referência e organização das ideias durante o desenvolvimento, todo o código e a documentação foram revisados e adaptados manualmente para atender aos requisitos do projeto. Este relatório foi escrito de forma humana, sem parecer gerado exclusivamente por IA.

## Instruções para Reproduzir o Projeto

1. **Instalar Dependências:**  
   Utilize opam para instalar as dependências listadas.

2. **Compilar o Projeto:**  
   Na raiz do projeto, execute `dune build` para compilar todos os módulos.

3. **Rodar os Testes:**  
   Execute `dune runtest` para validar o funcionamento das funções.

4. **Executar o ETL:**  
   Para processar os dados e gerar as saídas, execute `dune exec progfuncetl_app`.

Este relatório serve como um roteiro detalhado para reproduzir e manter o projeto.
