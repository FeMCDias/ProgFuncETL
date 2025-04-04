open Impure
open Types

(** 
   Ponto de entrada do programa ETL.
   Realiza o download dos CSVs, executa o ETL, gera os arquivos de saída (output.csv e extra.csv)
   e salva os dados no banco de dados SQLite.
*)
let () =
  (* URLs para os dados CSV (utilize as URLs brutas do seu gist) *)
  let orders_url = "https://gist.githubusercontent.com/FeMCDias/534e4c562ff2fa896f89483d22a45297/raw/order.csv" in
  let order_items_url = "https://gist.githubusercontent.com/FeMCDias/534e4c562ff2fa896f89483d22a45297/raw/order_item.csv" in

  (* Nomes dos arquivos CSV locais *)
  let orders_file = "orders.csv" in
  let order_items_file = "order_items.csv" in

  (* Download dos arquivos CSV *)
  let () =
    read_csv_from_url orders_url orders_file;
    read_csv_from_url order_items_url order_items_file
  in

  (* Parâmetros de filtro *)
  let filter_status = "" in
  let filter_origin = "" in

  (* Nomes dos arquivos de saída *)
  let output_file = "output.csv" in
  let extra_file = "extra.csv" in

  (* Executa o processo ETL com agregação *)
  let outputs, aggregated = run_etl_with_aggregation orders_file order_items_file filter_status filter_origin in

  (* Geração do CSV principal com os totais por pedido *)
  let header = "order_id,total_amount,total_taxes" in
  let csv_lines =
    List.map (fun o ->
      Printf.sprintf "%d,%.2f,%.2f" o.order_id o.total_amount o.total_taxes
    ) outputs in
  let csv_data = header :: csv_lines in
  let csv_data_rows = List.map (fun line -> [line]) csv_data in
  write_csv output_file csv_data_rows;
  Printf.printf "Arquivo %s gerado com sucesso.\n" output_file;

  (* Geração do CSV extra com os dados agregados *)
  write_extra_csv extra_file aggregated;
  Printf.printf "Arquivo %s gerado com sucesso.\n" extra_file;

  (* Exibe a agregação no console *)
  Printf.printf "\nAgregação por mês e ano:\n";
  List.iter (fun a ->
    Printf.printf "Ano: %d, Mês: %d, Receita Média: %.2f, Impostos Médios: %.2f\n"
      a.year a.month a.avg_revenue a.avg_taxes
  ) aggregated;

  (* Salva os resultados principais no banco de dados SQLite *)
  let db_file = "output.db" in
  write_output_to_sqlite db_file outputs;
  Printf.printf "\nDados salvos no banco de dados SQLite: %s\n" db_file;

  (* Salva os dados agregados no banco de dados SQLite *)
  write_extra_to_sqlite db_file aggregated;
  Printf.printf "\nDados agregados salvos no banco de dados SQLite: %s\n" db_file
