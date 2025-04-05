# ProgFuncETL

**Descrição:**  
Projeto em OCaml que implementa um processo **ETL (Extract, Transform, Load)** para processar dados de pedidos e itens de pedidos. O sistema transforma os dados e gera saídas agregadas para dashboards, organizando o código em módulos com **funções puras** e **funções impuras**.

---

## 📁 Estrutura do Projeto

```
ProgFuncETL/
├── dune-project            # Configuração do Dune (lang dune 3.14, etc.)
├── ProgFuncETL.opam        # Arquivo opcional para gerenciamento com opam
├── lib/
│   ├── dune                # Configuração do módulo da biblioteca
│   ├── types.ml            # Tipos (Order, OrderItem, etc.)
│   ├── pure.ml             # Funções puras (transformação, inner join, etc.)
│   └── impure.ml           # Funções impuras (I/O, HTTP, SQLite)
├── bin/
│   ├── dune                # Configuração do executável
│   └── main.ml             # Ponto de entrada do ETL
├── data/                   # Pasta vazia para armazenar os arquivos CSV baixados e o banco de dados SQLite
├── example_data/           # Pasta com arquivos CSV de exemplo
│   ├── order_items.csv     # Arquivo de itens de pedidos
│   ├── orders.csv          # Arquivo de pedidos
│   ├── output.csv          # Arquivo CSV gerado pelo ETL
│   └── extra.csv           # Arquivo CSV com dados agregados
├── test/
│   ├── dune                # Configuração dos testes
│   ├── test_pure.ml        # Testes unitários das funções puras
│   └── test_impure.ml      # Testes das funções impuras
└── report.md               # Relatório do projeto
```

---

## 📦 Dependências

Instale com o [opam](https://opam.ocaml.org/):

```
opam install dune csv sqlite3 cohttp-lwt-unix lwt lwt_ppx ounit2
```


Em alguns macbooks, pode ser necessário instalar o pkg-config antes de instalar as dependências para o SQLite:

```
brew install pkg-config
```


Lembre de configurar o ambiente do opam:

```
eval $(opam env)
```


---

## 🔧 Compilação e Execução

### Compilar o projeto:
```
dune clean
dune build
```


### Rodar os testes:
```
dune runtest
```


### Executar o ETL:
> Antes de executar o ETL, abra o arquivo `bin/main.ml` e verifique as variáveis de filtro (`filter_status` e `filter_origin`) para ajustar a filtragem conforme necessário (Filtragem descrita em detalhes abaixo das funcionalidades).

Para executar o ETL, utilize o seguinte comando:
```
dune exec bin/main.exe
```
ou, dependendo da configuração:
```
dune exec progfuncetl_app
```


---

## 🚀 Funcionalidades

- **Download de Dados:** Lê arquivos CSV diretamente de URLs via HTTP, guardando na pasta `data/`.
- **Transformações Funcionais:** Utiliza funções como map, filter, reduce e inner join para processar os dados.
- **Geração de CSV:** Exporta um arquivo com os campos `order_id`, `total_amount` e `total_taxes`.
- **Agregações:** Calcula a média de receita e de impostos pagos por mês e ano.
- **Persistência:** Armazena os resultados processados em um banco de dados SQLite (`data/output.db`), com tabelas separadas para os totais por pedido (`order_output`) e dados agregados (`extra_output`) com ano, mês, receita média e impostos médios. Todos os arquivos gerados são salvos na pasta `data/`.
- **Testes:** Possui uma suíte completa para testar as funções puras e impuras.

---

## 🎚️ Aplicando Filtros e Personalizando o Comportamento

No arquivo `main.ml` você encontrará duas variáveis de filtro:

- **filter_status:** Define o status do pedido que deve ser processado (ex.: `"complete"`, `"pending"`, etc.).
- **filter_origin:** Define a origem do pedido a ser processado (ex.: `"O"` para online, `"P"` para paraphysical).

**Como utilizar os filtros:**

- **Sem filtros:**  
  Se você quiser processar todos os pedidos que possuem itens, basta definir ambas as variáveis como strings vazias:
  ```
  ocaml
  let filter_status = ""
  let filter_origin = ""
  ```

  Isso faz com que a função de junção (`join_and_compute`) não aplique restrições e retorne todos os pedidos que possuem itens.

- **Com filtros:**  
  Para aplicar filtros, defina os valores conforme necessário. Por exemplo, para processar apenas os pedidos com status `"complete"` e origem `"O"`, configure:
  ```
  ocaml
  let filter_status = "complete"
  let filter_origin = "O"
  ```

  Dessa forma, somente os pedidos que atenderem a esses critérios serão incluídos no processamento.

**Observação:**  
O processamento utiliza um inner join entre as tabelas de pedidos e itens de pedido, ou seja, pedidos sem itens associados não serão incluídos na saída.

---

## 📚 Documentação

Cada função do projeto possui docstrings explicativas nos arquivos `.ml`.  
- As **funções puras** (em `pure.ml`) cuidam da transformação dos dados, junção e agregação, operando sobre listas de records.  
- As **funções impuras** (em `impure.ml`) são responsáveis por operações de I/O, download de arquivos e acesso a banco de dados SQLite.

Consulte os respectivos arquivos para entender a implementação detalhada.


---

## 🗂️ Pasta de Exemplo
A pasta `example_data/` contém arquivos CSV com os arquivos gerados e processados pelo ETL para quem não quiser executar o download dos arquivos originais e testar o ETL.

---

## 📑 Relatório

Para informações detalhadas sobre as decisões de design, implementação e o uso (ou não) de IA Generativa, veja o arquivo [relatorio.md](relatorio.md).

---

## 💡 Personalização e Manutenção

Caso alguma parte do código precise ser modificada (por exemplo, alterar os filtros, o formato dos CSVs ou os parâmetros de conexão com o banco de dados), basta editar os arquivos correspondentes em `lib/` ou `bin/`.  
As alterações podem ser validadas através da suíte de testes disponível em `test/`.

---

Este README cobre todos os detalhes essenciais para compilar, testar, executar e personalizar o projeto ETL em OCaml.

### IA Generativa
> Este Readme foi auxiliado por IA Generativa, mas revisado e editado para garantir clareza e precisão.
