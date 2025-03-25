# README.md

# ProgFuncETL

**Descrição:**  
Este projeto implementa um processo ETL (Extract, Transform, Load) em OCaml para processar dados de pedidos e itens de pedidos, transformá-los e gerar saídas agregadas para uso em dashboards. O projeto utiliza funções puras para o processamento dos dados e funções impuras para operações de I/O, que foram organizadas em módulos distintos.

**Estrutura do Projeto (texto bruto):**

ProgFuncETL/
├── dune-project            // Configuração do Dune (lang dune 3.14, etc.)
├── lib/
│   ├── dune                // Configuração do módulo da biblioteca
│   ├── types.ml            // Definições de registros (Order, OrderItem, etc.)
│   ├── pure.ml             // Funções puras (carregamento, transformação, inner join, etc.)
│   └── impure.ml           // Funções impuras (leitura/escrita de CSV, download via HTTP, SQLite)
├── bin/
│   ├── dune                // Configuração do executável
│   └── main.ml             // Ponto de entrada do programa ETL
├── test/
│   ├── dune                // Configuração dos testes
│   ├── test_pure.ml        // Testes unitários para funções puras
│   └── test_impure.ml      // Testes para funções impuras (download via HTTPS, I/O)
├── report.md               // Relatório do projeto
└── ProgFuncETL.opam        // (Opcional) Arquivo opam para distribuição

**Dependências:**  
Utilize [opam](https://opam.ocaml.org/) para instalar as seguintes dependências:

opam install dune csv sqlite3 cohttp-lwt-unix lwt lwt_ppx ounit2
### 🔧 Compilação e Execução

Para **compilar o projeto**, execute na raiz:

```bash
dune clean
dune build
```

Para **rodar os testes**:

```bash
dune runtest
```

Para **executar o ETL**:

```bash
dune exec progfuncetl_app
```

ou

```bash
dune exec bin/main.exe
```

**Funcionalidades:**

- **Download de Dados:** Lê arquivos CSV diretamente de URLs (via HTTP).
- **Processamento dos Dados:** Utiliza operações funcionais (map, reduce e filter) para transformar os dados, incluindo a junção (inner join) entre pedidos e itens.
- **Saída em CSV:** Gera um arquivo CSV com os campos order_id, total_amount e total_taxes.
- **Agregação Adicional:** Calcula e exibe a média de receita e de impostos pagos agrupados por mês e ano.
- **Persistência em SQLite:** Salva os resultados processados em um banco de dados SQLite.
- **Testes:** Inclui uma suíte completa de testes para funções puras e impuras.

**Documentação:**  
Cada função foi documentada com comentários explicativos. Consulte os arquivos fonte para mais detalhes.

**Relatório:**  
Para mais informações sobre o processo de desenvolvimento, consulte o arquivo [report.md](report.md).
