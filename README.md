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
│   └── test_pure.ml        # Testes unitários das funções puras
└── report.md               # Relatório do projeto
```

---

## 🔧 Compilação e Execução (via Docker)

O projeto já inclui uma pasta `devcontainer/` com a configuração necessária. Para executar via contêiner, siga os passos abaixo:

1. **Rebuild do Contêiner:**  
   - No VS Code, abra a paleta de comandos e selecione "Dev-Containers: Rebuild and Reopen in Container". Isto irá baixar a imagem do contêiner e abrir o projeto dentro dele.
2. **Dentro do Contêiner, Execute os Comandos:**  
   Abra um terminal integrado e execute:
```
eval $(opam env)
```
```
dune clean
```
```
dune build
```
```
dune runtest  # rodando os testes para validar o código
```
<br>

> Antes de executar o ETL, abra o arquivo `bin/main.ml` e verifique as variáveis de filtro (`filter_status` e `filter_origin`) para ajustar a filtragem conforme necessário (Filtragem descrita em detalhes abaixo da seção "🚀 Funcionalidades").


```
dune exec bin/main.exe
```
3. **Acessar os Resultados:**  
   Após a execução, os arquivos CSV gerados estarão na pasta `data/` e o banco de dados SQLite (`output.db`) estará na mesma pasta.

4. **Acessar o Banco de Dados:**
    Para acessar o banco de dados SQLite, utilize um cliente SQLite ou execute o seguinte comando no terminal:
  ```
  sqlite3 data/output.db
  ```
   Isso abrirá o banco de dados e permitirá que você execute consultas SQL diretamente.
   
   Queries para executar dentro do banco de dados:
   ```sql
   SELECT * FROM order_output; -- Para ver os totais por pedido
   SELECT * FROM extra_output; -- Para ver os dados agregados
   ```
   Lembrando que os schemas das tabelas são:
  ```sql
  CREATE TABLE order_output (
      order_id TEXT,
      total_amount REAL,
      total_taxes REAL
  );
  CREATE TABLE extra_output (
      year INTEGER,
      month INTEGER,
      avg_revenue REAL,
      avg_taxes REAL
  );
  ```

---

## 🚀 Funcionalidades

- **Download de Dados:** Lê arquivos CSV diretamente de URLs via HTTP, guardando na pasta `data/`.
- **Transformações Funcionais:** Utiliza funções como map, filter, reduce e inner join para processar os dados.
- **Geração de CSV:** Exporta um arquivo com os campos `order_id`, `total_amount` e `total_taxes`.
- **Agregações:** Calcula a média de receita e de impostos pagos por mês e ano.
- **Persistência:** Armazena os resultados processados em um banco de dados SQLite (`data/output.db`), com tabelas separadas para os totais por pedido (`order_output`) e dados agregados (`extra_output`) com ano, mês, receita média e impostos médios. Todos os arquivos gerados são salvos na pasta `data/`.
- **Testes:** Possui uma suíte completa para testar as funções puras.

---

## 🎚️ Aplicando Filtros e Personalizando o Comportamento

No arquivo `main.ml` você encontrará duas variáveis de filtro:

- **filter_status:** Define o status do pedido que deve ser processado (ex.: `"complete"`, `"pending"`, etc.).
- **filter_origin:** Define a origem do pedido a ser processado (ex.: `"O"` para online, `"P"` para paraphysical).

**Como utilizar os filtros:**

- **Sem filtros:**  
  Se você quiser processar todos os pedidos que possuem itens, basta definir ambas as variáveis como strings vazias:
  ```ocaml
  let filter_status = ""
  let filter_origin = ""
  ```

  Isso faz com que a função de junção (`join_and_compute`) não aplique restrições e retorne todos os pedidos que possuem itens.

- **Com filtros:**  
  Para aplicar filtros, defina os valores conforme necessário. Por exemplo, para processar apenas os pedidos com status `"complete"` e origem `"O"`, configure:
  ```ocaml
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
