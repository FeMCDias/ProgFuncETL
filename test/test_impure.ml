open OUnit2
open Impure
open Types
open Sqlite3

(* URLs HTTPS para os arquivos CSV *)
let orders_url = "https://gist.githubusercontent.com/FeMCDias/534e4c562ff2fa896f89483d22a45297/raw/order.csv"
let order_items_url = "https://gist.githubusercontent.com/FeMCDias/534e4c562ff2fa896f89483d22a45297/raw/order_item.csv"

(* ------------------------------------------------------------------------- *)
(* Testa a função [read_csv_from_url] para orders:
   Baixa o CSV e verifica se os dados foram lidos corretamente. *)
let test_read_csv_from_https_orders _ =
  let local_file = "temp_orders_https.csv" in
  read_csv_from_url orders_url local_file;
  let csv_data = read_csv local_file in
  assert_bool "Orders CSV from HTTPS deve conter dados" (List.length csv_data > 1)

(* ------------------------------------------------------------------------- *)
(* Testa a função [read_csv_from_url] para order_items:
   Baixa o CSV e verifica se os dados foram lidos corretamente. *)
let test_read_csv_from_https_order_items _ =
  let local_file = "temp_order_items_https.csv" in
  read_csv_from_url order_items_url local_file;
  let csv_data = read_csv local_file in
  assert_bool "Order items CSV from HTTPS deve conter dados" (List.length csv_data > 1)

(* ------------------------------------------------------------------------- *)
(* Testa a função [write_csv]:
   Escreve um conjunto de dados em um arquivo CSV e verifica a integridade da escrita. *)
let test_write_csv _ =
  let filename = "temp_write.csv" in
  let data = [["header1,header2"]; ["row1col1,row1col2"]; ["row2col1,row2col2"]] in
  write_csv filename data;
  let read_data = read_csv filename in
  assert_equal data read_data

(* ------------------------------------------------------------------------- *)
(* Função auxiliar para criar arquivos CSV temporários.
   Recebe o nome do arquivo e o conteúdo em forma de string, e cria o arquivo. *)
let create_temp_csv filename content =
  let oc = open_out filename in
  output_string oc content;
  close_out oc

(* ------------------------------------------------------------------------- *)
(* Testa a função [run_etl] com filtros:
   Cria arquivos temporários para orders e order_items e executa o ETL com filtro.
   Verifica se os outputs gerados correspondem ao esperado para pedidos com status "complete" e origem "O". *)
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
  (* Espera-se que apenas os pedidos 1 e 3 sejam retornados *)
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

(* ------------------------------------------------------------------------- *)
(* Testa a função [run_etl] sem filtros:
   Quando os filtros são strings vazias, espera-se que todos os pedidos com itens
   sejam retornados, excluindo pedidos sem itens (inner join). *)
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
  (* Como o pedido 2 não possui itens, espera-se somente os pedidos 1 e 3 *)
  assert_equal 2 (List.length outputs)

(* ------------------------------------------------------------------------- *)
(* Testa a função [run_etl_with_aggregation]:
   Executa o ETL com agregação e verifica se os outputs e os registros agregados
   correspondem ao esperado para o conjunto de dados fornecido. *)
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

(* ------------------------------------------------------------------------- *)
(* Testa a função [write_output_to_sqlite]:
   Salva os outputs em um banco de dados SQLite e verifica se o número de registros
   na tabela [order_output] corresponde ao esperado. *)
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

(* ------------------------------------------------------------------------- *)
(* Testa a função [write_extra_csv]:
   Salva os dados agregados em um arquivo CSV e verifica se o arquivo possui
   o cabeçalho e o número correto de linhas de dados. *)
let test_write_extra_csv _ =
  let aggregated = [
    { year = 2024; month = 10; avg_revenue = 40.0; avg_taxes = 6.0 };
    { year = 2024; month = 11; avg_revenue = 90.0; avg_taxes = 27.0 }
  ] in
  let filename = "temp_extra.csv" in
  write_extra_csv filename aggregated;
  let csv_data = read_csv filename in
  (* Verifica se há 1 linha de cabeçalho + 2 linhas de dados *)
  assert_equal 3 (List.length csv_data)

(* ------------------------------------------------------------------------- *)
(* Testa a função [write_extra_to_sqlite]:
   Salva os dados agregados em um banco de dados SQLite e verifica se o número de registros
   na tabela [extra_output] corresponde ao esperado. *)
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

(* ------------------------------------------------------------------------- *)
(* Conjunto de testes para as funções impuras do ETL *)
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

(* ------------------------------------------------------------------------- *)
(* Executa a suíte de testes *)
let () =
  run_test_tt_main suite
