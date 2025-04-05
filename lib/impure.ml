open Types
open Pure

(** 
   Lê um arquivo CSV e retorna uma lista de linhas, onde cada linha é uma lista de strings.
   Utiliza a biblioteca [Csv].
*)
let read_csv (filename : string) : string list list =
  Csv.load filename

(** 
   Escreve um arquivo CSV a partir de uma lista de linhas, onde cada linha é uma lista de strings.
*)
let write_csv (filename : string) (data : string list list) : unit =
  Csv.save filename data

(** 
   Lê um arquivo CSV a partir de uma URL e salva-o no arquivo [local_file].
   Requer a biblioteca [Cohttp_lwt_unix] e utiliza Lwt para operações assíncronas.
*)
let read_csv_from_url (url : string) (local_file : string) : unit =
  Lwt_main.run (
    let open Lwt.Infix in
    print_endline ("Baixando CSV de " ^ url);
    Cohttp_lwt_unix.Client.get (Uri.of_string url) >>= fun (_, body) ->
    Cohttp_lwt.Body.to_string body >>= fun body_str ->
    let oc = open_out local_file in
    output_string oc body_str;
    close_out oc;
    Lwt.return_unit
  )

(** 
   Salva os dados de saída em um banco de dados SQLite.
   Utiliza a biblioteca [Sqlite3].
   Cria a tabela [order_output] se ela não existir e insere os registros.
*)
let write_output_to_sqlite (db_file : string) (outputs : order_output list) : unit =
  let db = Sqlite3.db_open db_file in
  let sql_create = "CREATE TABLE IF NOT EXISTS order_output (order_id INTEGER, total_amount REAL, total_taxes REAL);" in
  let _ = Sqlite3.exec db sql_create in
  let insert_stmt = "INSERT INTO order_output (order_id, total_amount, total_taxes) VALUES (?, ?, ?);" in
  let stmt = Sqlite3.prepare db insert_stmt in
  List.iter (fun o ->
    let _ = Sqlite3.bind stmt 1 (Sqlite3.Data.INT (Int64.of_int o.order_id)) in
    let _ = Sqlite3.bind stmt 2 (Sqlite3.Data.FLOAT o.total_amount) in
    let _ = Sqlite3.bind stmt 3 (Sqlite3.Data.FLOAT o.total_taxes) in
    let _ = Sqlite3.step stmt in
    let _ = Sqlite3.reset stmt in
    ()
  ) outputs;
  ignore (Sqlite3.finalize stmt);
  ignore (Sqlite3.db_close db)

(** 
   Exporta os dados agregados para um arquivo CSV.
   O arquivo conterá um cabeçalho e cada linha com: ano, mês, receita média e impostos médios.
*)
let write_extra_csv (filename : string) (aggregated : aggregated list) : unit =
  let header = "year,month,avg_revenue,avg_taxes" in
  let rows = List.map (fun a ->
    Printf.sprintf "%d,%d,%.2f,%.2f" a.year a.month a.avg_revenue a.avg_taxes
  ) aggregated in
  let csv_data = header :: rows in
  let csv_data_rows = List.map (fun line -> [line]) csv_data in
  write_csv filename csv_data_rows

(** 
   Salva os dados agregados em um banco de dados SQLite.
   Cria a tabela [extra_output] se ela não existir e insere os registros.
*)
let write_extra_to_sqlite (db_file : string) (aggregated : aggregated list) : unit =
  let db = Sqlite3.db_open db_file in
  let sql_create = "CREATE TABLE IF NOT EXISTS extra_output (year INTEGER, month INTEGER, avg_revenue REAL, avg_taxes REAL);" in
  let _ = Sqlite3.exec db sql_create in
  let insert_stmt = "INSERT INTO extra_output (year, month, avg_revenue, avg_taxes) VALUES (?, ?, ?, ?);" in
  let stmt = Sqlite3.prepare db insert_stmt in
  List.iter (fun a ->
    let _ = Sqlite3.bind stmt 1 (Sqlite3.Data.INT (Int64.of_int a.year)) in
    let _ = Sqlite3.bind stmt 2 (Sqlite3.Data.INT (Int64.of_int a.month)) in
    let _ = Sqlite3.bind stmt 3 (Sqlite3.Data.FLOAT a.avg_revenue) in
    let _ = Sqlite3.bind stmt 4 (Sqlite3.Data.FLOAT a.avg_taxes) in
    let _ = Sqlite3.step stmt in
    let _ = Sqlite3.reset stmt in
    ()
  ) aggregated;
  ignore (Sqlite3.finalize stmt);
  ignore (Sqlite3.db_close db)

(** 
   Executa o processo ETL completo.
   - Lê os arquivos CSV de orders e order_items.
   - Remove os cabeçalhos e converte as linhas em records utilizando as funções puras.
   - Realiza a junção dos dados e aplica os filtros.
   - Retorna a lista de [order_output].
*)
let run_etl (orders_file : string) (order_items_file : string) (filter_status : string) (filter_origin : string) : order_output list =
  let orders_csv = read_csv orders_file in
  let order_items_csv = read_csv order_items_file in
  (* Remove cabeçalhos *)
  let orders_data = List.tl orders_csv in
  let order_items_data = List.tl order_items_csv in
  let orders = List.map load_order orders_data in
  let order_items = List.map load_order_item order_items_data in
  join_and_compute orders order_items filter_status filter_origin

(** 
   Executa o processo ETL completo e realiza a agregação por mês e ano.
   Retorna uma tupla contendo:
   - A lista de [order_output] gerada.
   - A lista de [aggregated] com os dados agregados.
*)
let run_etl_with_aggregation (orders_file : string) (order_items_file : string) (filter_status : string) (filter_origin : string) : (order_output list * aggregated list) =
  let outputs = run_etl orders_file order_items_file filter_status filter_origin in
  let orders_csv = read_csv orders_file in
  let orders_data = List.tl orders_csv in
  let orders = List.map load_order orders_data in
  let agg = group_by_month_year orders outputs in
  (outputs, agg)
