open Impure
open Types

let () =
  (* URLs for CSV data (use the raw URLs from your gist) *)
  let orders_url = "https://gist.githubusercontent.com/FeMCDias/534e4c562ff2fa896f89483d22a45297/raw/order.csv" in
  let order_items_url = "https://gist.githubusercontent.com/FeMCDias/534e4c562ff2fa896f89483d22a45297/raw/order_item.csv" in

  (* Local file names to save the downloaded CSVs *)
  let orders_file = "orders.csv" in
  let order_items_file = "order_items.csv" in

  (* Download the CSV files *)
  let () =
    read_csv_from_url orders_url orders_file;
    read_csv_from_url order_items_url order_items_file
  in

  let output_file = "output.csv" in
  let filter_status = "complete" in
  let filter_origin = "O" in

  (* Execute the ETL process with aggregation *)
  let outputs, aggregated =
    run_etl_with_aggregation orders_file order_items_file filter_status filter_origin
  in

  (* Prepare CSV data *)
  let header = "order_id,total_amount,total_taxes" in
  let csv_lines =
    List.map (fun o ->
      Printf.sprintf "%d,%.2f,%.2f" o.order_id o.total_amount o.total_taxes
    ) outputs
  in
  let csv_data = header :: csv_lines in
  let csv_data_rows = List.map (fun line -> [line]) csv_data in
  write_csv output_file csv_data_rows;
  Printf.printf "Arquivo %s gerado com sucesso.\n" output_file;

  (* Display aggregation on the console *)
  Printf.printf "\nAgregação por mês e ano:\n";
  List.iter (fun a ->
    Printf.printf "Ano: %d, Mês: %d, Receita Média: %.2f, Impostos Médios: %.2f\n"
      a.year a.month a.avg_revenue a.avg_taxes
  ) aggregated;

  (* Optionally, save output to SQLite *)
  let db_file = "output.db" in
  write_output_to_sqlite db_file outputs;
  Printf.printf "\nDados salvos no banco de dados SQLite: %s\n" db_file
