open OUnit2
open Types
open Pure

(* ------------------------------------------------------------------------- *)
(* Testa a função [load_order]:
   Verifica se uma lista de strings é convertida corretamente em um record [order]. *)
let test_load_order _ =
  let fields = ["1"; "100"; "2024-10-02"; "complete"; "O"] in
  let order = load_order fields in
  assert_equal 1 order.id;
  assert_equal 100 order.client_id;
  assert_equal "2024-10-02" order.order_date;
  assert_equal "complete" order.status;
  assert_equal "O" order.origin

(* ------------------------------------------------------------------------- *)
(* Testa a função [load_order_item]:
   Verifica se uma lista de strings é convertida corretamente em um record [order_item]. *)
let test_load_order_item _ =
  let fields = ["1"; "200"; "2"; "15.5"; "10.0"] in
  let item = load_order_item fields in
  assert_equal 1 item.order_id;
  assert_equal 200 item.product_id;
  assert_equal 2 item.quantity;
  assert_equal 15.5 item.price;
  assert_equal 10.0 item.tax

(* ------------------------------------------------------------------------- *)
(* Testa a função [compute_totals]:
   Calcula o total de receita e impostos para uma lista de order_items. *)
let test_compute_totals _ =
  let items = [
    { order_id = 1; product_id = 200; quantity = 2; price = 15.5; tax = 10.0 };
    { order_id = 1; product_id = 201; quantity = 1; price = 20.0; tax = 5.0 }
  ] in
  let total_amount, total_taxes = compute_totals items in
  let expected_amount = (2. *. 15.5) +. (1. *. 20.0) in
  let expected_taxes = (10.0 *. (2. *. 15.5)) +. (5.0 *. (1. *. 20.0)) in
  assert_equal expected_amount total_amount;
  assert_equal expected_taxes total_taxes

(* ------------------------------------------------------------------------- *)
(* Testa a função [group_order_items]:
   Verifica se os order_items são corretamente agrupados pelo campo [order_id]. *)
let test_group_order_items _ =
  let items = [
    { order_id = 1; product_id = 101; quantity = 2; price = 10.0; tax = 0.1 };
    { order_id = 1; product_id = 102; quantity = 1; price = 20.0; tax = 0.2 };
    { order_id = 2; product_id = 103; quantity = 3; price = 30.0; tax = 0.3 }
  ] in
  let grouped = group_order_items items in
  (* Verifica se a chave 1 possui 2 itens e a chave 2 possui 1 item *)
  let items1 = List.assoc 1 grouped in
  let items2 = List.assoc 2 grouped in
  assert_equal 2 (List.length items1);
  assert_equal 1 (List.length items2)

(* ------------------------------------------------------------------------- *)
(* Testa a função [join_and_compute] com filtro:
   Considera somente os pedidos com status "complete" e origem "O". *)
let test_join_and_compute_filter _ =
  let orders = [
    { id = 1; client_id = 100; order_date = "2024-10-02"; status = "complete"; origin = "O" };
    { id = 2; client_id = 101; order_date = "2024-11-03"; status = "pending"; origin = "P" };
    { id = 3; client_id = 102; order_date = "2024-12-04"; status = "complete"; origin = "O" }
  ] in
  let order_items = [
    { order_id = 1; product_id = 101; quantity = 2; price = 10.0; tax = 0.1 };
    { order_id = 1; product_id = 102; quantity = 1; price = 20.0; tax = 0.2 };
    { order_id = 3; product_id = 103; quantity = 3; price = 30.0; tax = 0.3 }
  ] in
  let outputs = join_and_compute orders order_items "complete" "O" in
  (* Espera-se que os pedidos 1 e 3 sejam retornados *)
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
(* Testa a função [join_and_compute] sem filtros:
   Quando os filtros são strings vazias, espera-se que todos os pedidos com itens sejam retornados. *)
let test_join_and_compute_no_filter _ =
  let orders = [
    { id = 1; client_id = 100; order_date = "2024-10-02"; status = "complete"; origin = "O" };
    { id = 2; client_id = 101; order_date = "2024-11-03"; status = "pending"; origin = "P" };
    { id = 3; client_id = 102; order_date = "2024-12-04"; status = "complete"; origin = "O" }
  ] in
  let order_items = [
    { order_id = 1; product_id = 101; quantity = 2; price = 10.0; tax = 0.1 };
    { order_id = 1; product_id = 102; quantity = 1; price = 20.0; tax = 0.2 };
    { order_id = 3; product_id = 103; quantity = 3; price = 30.0; tax = 0.3 }
  ] in
  let outputs = join_and_compute orders order_items "" "" in
  (* Como o pedido 2 não possui itens, espera-se somente os pedidos 1 e 3 *)
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
(* Testa a função [group_by_month_year]:
   Agrupa os resultados por mês e ano, calculando a média de receita e de impostos. *)
let test_group_by_month_year _ =
  let orders = [
    { id = 1; client_id = 100; order_date = "2024-10-02"; status = "complete"; origin = "O" };
    { id = 3; client_id = 102; order_date = "2024-11-03"; status = "complete"; origin = "O" }
  ] in
  let outputs = [
    { order_id = 1; total_amount = 40.0; total_taxes = 6.0 };
    { order_id = 3; total_amount = 90.0; total_taxes = 27.0 }
  ] in
  let aggs = group_by_month_year orders outputs in
  (* Espera-se que existam dois grupos: um para outubro (mês 10) e outro para novembro (mês 11) *)
  let agg_oct = List.find (fun a -> a.month = 10 && a.year = 2024) aggs in
  let agg_nov = List.find (fun a -> a.month = 11 && a.year = 2024) aggs in
  assert_equal 40.0 agg_oct.avg_revenue;
  assert_equal 6.0 agg_oct.avg_taxes;
  assert_equal 90.0 agg_nov.avg_revenue;
  assert_equal 27.0 agg_nov.avg_taxes

(* ------------------------------------------------------------------------- *)
(* Conjunto de testes para as funções puras do ETL *)
let suite =
  "Testes Pure" >::: [
    "test_load_order" >:: test_load_order;
    "test_load_order_item" >:: test_load_order_item;
    "test_compute_totals" >:: test_compute_totals;
    "test_group_order_items" >:: test_group_order_items;
    "test_join_and_compute_filter" >:: test_join_and_compute_filter;
    "test_join_and_compute_no_filter" >:: test_join_and_compute_no_filter;
    "test_group_by_month_year" >:: test_group_by_month_year;
  ]

(* ------------------------------------------------------------------------- *)
(* Executa a suíte de testes *)
let () =
  run_test_tt_main suite
