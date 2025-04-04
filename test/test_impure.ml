open OUnit2
open Impure
open Types
open Sqlite3

(* URLs HTTPS para os arquivos CSV *)
let orders_url = "https://gist.githubusercontent.com/FeMCDias/534e4c562ff2fa896f89483d22a45297/raw/order.csv"
let order_items_url = "https://gist.githubusercontent.com/FeMCDias/534e4c562ff2fa896f89483d22a45297/raw/order_item.csv"

let test_read_csv_from_https_orders _ =
  let local_file = "temp_orders_https.csv" in
  read_csv_from_url orders_url local_file;
  let csv_data = read_csv local_file in
  assert_bool "Orders CSV from HTTPS deve conter dados" (List.length csv_data > 1)

let test_read_csv_from_https_order_items _ =
  let local_file = "temp_order_items_https.csv" in
  read_csv_from_url order_items_url local_file;
  let csv_data = read_csv local_file in
  assert_bool "Order items CSV from HTTPS deve conter dados" (List.length csv_data > 1)

let test_write_csv _ =
  let filename = "temp_write.csv" in
  let data = [["header1,header2"]; ["row1col1,row1col2"]; ["row2col1,row2col2"]] in
  write_csv filename data;
  let read_data = read_csv filename in
  assert_equal data read_data

(* Função auxiliar para criar arquivos CSV temporários *)
let create_temp_csv filename content =
  let oc = open_out filename in
  output_string oc content;
  close_out oc

let test_run_etl_filter _ =
  let orders_content = "id,client_id,order_date,status,origin\n\
                        1,100,2024-10-02,complete,O\n\
                        2,101,2024-11-03,pending,P\n\
                        3,102,2024-12-04,complete,O\n" in
  let order_items_content = "order_id,product_id,quantity,price,tax\n\
                             1,101,2,10.0,0.1\n\
                             1,102,1,20.0,0.2\n\
                             3,103,3,30.0,0.3\n" in
  let orders_file = "temp_orders.csv" in
  let order_items_file = "temp_order_items.csv" in
  create_temp_csv orders_file orders_content;
  create_temp_csv order_items_file order_items_content;
  let outputs = run_etl orders_file order_items_file "complete" "O" in
  (* Espera-se os pedidos 1 e 3 *)
  assert_equal 2 (List.length outputs);
  let output1 = List.find (fun o -> o.order_id = 1) outputs in
  let output3 = List.find (fun o -> o.order_id = 3) outputs in
  let expected_amount1 = (2. *. 10.0) +. (1. *. 20.0) in
  let expected_tax1 = (0.1 *. (2. *. 10.0)) +. (0.2 *. (1. *. 20.0)) in
  let expected_amount3 = 3. *. 30.0 in
  let expected_tax3 = 0.3 *. (3. *. 30.0) in
  assert_equal expected_amount1 output1.total_amount;
  assert_equal expected_tax1 output1.total_taxes;
  assert_equal expected_amount3 output3.total_amount;
  assert_equal expected_tax3 output3.total_taxes

let test_run_etl_no_filter _ =
  let orders_content = "id,client_id,order_date,status,origin\n\
                        1,100,2024-10-02,complete,O\n\
                        2,101,2024-11-03,pending,P\n\
                        3,102,2024-12-04,complete,O\n" in
  let order_items_content = "order_id,product_id,quantity,price,tax\n\
                             1,101,2,10.0,0.1\n\
                             1,102,1,20.0,0.2\n\
                             3,103,3,30.0,0.3\n" in
  let orders_file = "temp_orders_no_filter.csv" in
  let order_items_file = "temp_order_items_no_filter.csv" in
  create_temp_csv orders_file orders_content;
  create_temp_csv order_items_file order_items_content;
  let outputs = run_etl orders_file order_items_file "" "" in
  (* Apenas os pedidos com itens (1 e 3) devem ser retornados *)
  assert_equal 2 (List.length outputs)

let test_run_etl_with_aggregation _ =
  let orders_content = "id,client_id,order_date,status,origin\n\
                        1,100,2024-10-02,complete,O\n\
                        3,102,2024-11-03,complete,O\n" in
  let order_items_content = "order_id,product_id,quantity,price,tax\n\
                             1,101,2,10.0,0.1\n\
                             1,102,1,20.0,0.2\n\
                             3,103,3,30.0,0.3\n" in
  let orders_file = "temp_orders_agg.csv" in
  let order_items_file = "temp_order_items_agg.csv" in
  create_temp_csv orders_file orders_content;
  create_temp_csv order_items_file order_items_content;
  let (outputs, aggregated) = run_etl_with_aggregation orders_file order_items_file "complete" "O" in
  (* Espera-se 2 outputs e 2 grupos de agregação *)
  assert_equal 2 (List.length outputs);
  assert_equal 2 (List.length aggregated);
  let agg_oct = List.find (fun a -> a.month = 10 && a.year = 2024) aggregated in
  let output1 = List.find (fun o -> o.order_id = 1) outputs in
  assert_equal output1.total_amount agg_oct.avg_revenue;
  assert_equal output1.total_taxes agg_oct.avg_taxes

let test_write_output_to_sqlite _ =
  let outputs = [
    { order_id = 1; total_amount = 40.0; total_taxes = 6.0 };
    { order_id = 3; total_amount = 90.0; total_taxes = 27.0 }
  ] in
  let db_file = "temp_output.db" in
  write_output_to_sqlite db_file outputs;
  let db = db_open db_file in
  let count = ref 0 in
  let _ = exec db "SELECT COUNT(*) FROM order_output" 
    ~cb:(fun row _ -> 
      match row.(0) with
      | Some count_str -> count := int_of_string count_str; ()
      | None -> ()
    )
  in
  ignore (db_close db);
  assert_equal 2 !count

let test_write_extra_csv _ =
  let aggregated = [
    { year = 2024; month = 10; avg_revenue = 40.0; avg_taxes = 6.0 };
    { year = 2024; month = 11; avg_revenue = 90.0; avg_taxes = 27.0 }
  ] in
  let filename = "temp_extra.csv" in
  write_extra_csv filename aggregated;
  let csv_data = read_csv filename in
  (* Verifica se há cabeçalho + 2 linhas de dados *)
  assert_equal 3 (List.length csv_data)

let test_write_extra_to_sqlite _ =
  let aggregated = [
    { year = 2024; month = 10; avg_revenue = 40.0; avg_taxes = 6.0 };
    { year = 2024; month = 11; avg_revenue = 90.0; avg_taxes = 27.0 }
  ] in
  let db_file = "temp_extra.db" in
  write_extra_to_sqlite db_file aggregated;
  let db = db_open db_file in
  let count = ref 0 in
  let _ = exec db "SELECT COUNT(*) FROM extra_output" 
    ~cb:(fun row _ ->
      match row.(0) with
      | Some count_str -> count := int_of_string count_str; ()
      | None -> ()
    )
  in
  ignore (db_close db);
  assert_equal 2 !count

let suite =
  "Test Funções Impuras" >::: [
    "test_read_csv_from_https_orders" >:: test_read_csv_from_https_orders;
    "test_read_csv_from_https_order_items" >:: test_read_csv_from_https_order_items;
    "test_write_csv" >:: test_write_csv;
    "test_run_etl_filter" >:: test_run_etl_filter;
    "test_run_etl_no_filter" >:: test_run_etl_no_filter;
    "test_run_etl_with_aggregation" >:: test_run_etl_with_aggregation;
    "test_write_output_to_sqlite" >:: test_write_output_to_sqlite;
    "test_write_extra_csv" >:: test_write_extra_csv;
    "test_write_extra_to_sqlite" >:: test_write_extra_to_sqlite;
  ]

let () =
  run_test_tt_main suite
