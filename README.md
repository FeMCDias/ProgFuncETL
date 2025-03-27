# ProgFuncETL

**Descrição:**  
Projeto em OCaml que implementa um processo **ETL (Extract, Transform, Load)** para processar dados de pedidos e itens de pedidos. O sistema transforma os dados e gera saídas agregadas para dashboards, organizando o código em módulos com **funções puras** e **funções impuras**.

---

## 📁 Estrutura do Projeto

````
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
├── test/
│   ├── dune                # Configuração dos testes
│   ├── test_pure.ml        # Testes unitários das funções puras
│   └── test_impure.ml      # Testes das funções impuras
└── report.md               # Relatório do projeto
````

---

## 📦 Dependências

Instale com o [opam](https://opam.ocaml.org/):

```bash
opam install dune csv sqlite3 cohttp-lwt-unix lwt lwt_ppx ounit2
```

Em alguns macbooks, pode ser necessário instalar o pkg-config antes de instalar as dependências para o SQLite.

```bash
brew install pkg-config
```

---

## 🔧 Compilação e Execução

### Compilar o projeto:
```bash
dune clean
dune build
```

### Rodar os testes:
```bash
dune runtest
```

### Executar o ETL:
```bash
dune exec bin/main.exe
# ou
dune exec progfuncetl_app
```

---

## 🚀 Funcionalidades

- **Download de Dados:** Lê arquivos CSV diretamente de URLs via HTTP.
- **Transformações Funcionais:** Usa funções como `map`, `filter`, `reduce` e inner join para processar os dados.
- **Geração de CSV:** Exporta um arquivo com os campos `order_id`, `total_amount` e `total_taxes`.
- **Agregações:** Calcula a média de receita e de impostos pagos por mês e ano.
- **Persistência:** Armazena os resultados processados em um banco de dados SQLite.
- **Extra CSV:** Exporta um arquivo adicional (`extra.csv`) contendo os dados agregados (ano, mês, receita média e impostos médios) e salva esses dados também no SQLite (tabela `extra_output`).
- **Testes:** Possui uma suíte completa para testar as funções puras e impuras.

---

## 📚 Documentação

Cada função do projeto está comentada com docstrings explicativas. Consulte os arquivos `.ml` para mais detalhes sobre a implementação.

---

## 📑 Relatório

Para informações detalhadas sobre as decisões de design e implementação, veja o arquivo [relatorio.md](relatorio.md).
