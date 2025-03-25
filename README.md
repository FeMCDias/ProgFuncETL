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
├── test/
│   ├── dune                # Configuração dos testes
│   ├── test_pure.ml        # Testes unitários das funções puras
│   └── test_impure.ml      # Testes das funções impuras
└── report.md               # Relatório do projeto
```

---

## 📦 Dependências

Instale com o [opam](https://opam.ocaml.org/):

```bash
opam install dune csv sqlite3 cohttp-lwt-unix lwt lwt_ppx ounit2
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

- 📥 **Download de Dados:** Lê arquivos CSV diretamente de URLs via HTTP.
- 🔁 **Transformações Funcionais:** Usa `map`, `filter`, `reduce` e `inner join` para processar os dados.
- 📄 **Geração de CSV:** Exporta arquivo com `order_id`, `total_amount`, `total_taxes`.
- 📊 **Agregações:** Calcula média de receita e impostos por mês e ano.
- 🗃️ **Persistência:** Armazena resultados em banco de dados SQLite.
- 🧪 **Testes:** Suíte completa para testar funções puras e impuras.

---

## 📚 Documentação

Cada função está comentada com explicações. Consulte os arquivos `.ml` para mais detalhes.

---

## 📑 Relatório

Para informações detalhadas sobre decisões de design e implementação, veja o arquivo [`report.md`](report.md).
