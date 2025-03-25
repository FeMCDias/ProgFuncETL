open OUnit2
open Types
open Pure

let test_load_order _ =
  let fields = ["1"; "100"; "2022-05-12"; "complete"; "O"] in
  let order = load_order fields in
  assert_equal 1 order.id;
  assert_equal 100 order.client_id;
  assert_equal "2022-05-12" order.order_date;
  assert_equal "complete" order.status;
  assert_equal "O" order.origin

let test_load_order_item _ =
  let fields = ["1"; "200"; "2"; "15.5"; "10.0"] in
  let item = load_order_item fields in
  assert_equal 1 item.order_id;
  assert_equal 200 item.product_id;
  assert_equal 2 item.quantity;
  assert_equal 15.5 item.price;
  assert_equal 10.0 item.tax

let test_compute_totals _ =
  let items = [
    { order_id = 1; product_id = 200; quantity = 2; price = 15.5; tax = 10.0 };
    { order_id = 1; product_id = 201; quantity = 1; price = 20.0; tax = 5.0 }
  ] in
  let total_amount, total_taxes = compute_totals items in
  let expected_amount = (2. *. 15.5) +. (1. *. 20.0) in
  let expected_taxes = (10.0 /. 100.0 *. (2. *. 15.5)) +. (5.0 /. 100.0 *. (1. *. 20.0)) in
  assert_equal expected_amount total_amount;
  assert_equal expected_taxes total_taxes

let suite =
  "Testes Pure" >::: [
    "test_load_order" >:: test_load_order;
    "test_load_order_item" >:: test_load_order_item;
    "test_compute_totals" >:: test_compute_totals;
  ]

let () =
  run_test_tt_main suite
