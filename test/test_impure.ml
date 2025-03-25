open OUnit2
open Impure

(* HTTPS URLs for the CSV files *)
let orders_url = "https://gist.githubusercontent.com/FeMCDias/534e4c562ff2fa896f89483d22a45297/raw/order.csv"
let order_items_url = "https://gist.githubusercontent.com/FeMCDias/534e4c562ff2fa896f89483d22a45297/raw/order_item.csv"

(* Test for downloading and reading orders CSV via HTTPS *)
let test_read_csv_from_https_orders _ =
  let local_file = "temp_orders.csv" in
  read_csv_from_url orders_url local_file;
  let csv_data = read_csv local_file in
  assert_bool "Orders CSV from HTTPS should have data" (List.length csv_data > 1)

(* Test for downloading and reading order items CSV via HTTPS *)
let test_read_csv_from_https_order_items _ =
  let local_file = "temp_order_item.csv" in
  read_csv_from_url order_items_url local_file;
  let csv_data = read_csv local_file in
  assert_bool "Order items CSV from HTTPS should have data" (List.length csv_data > 1)

let suite =
  "TestImpureHTTPS" >::: [
    "test_read_csv_from_https_orders" >:: test_read_csv_from_https_orders;
    "test_read_csv_from_https_order_items" >:: test_read_csv_from_https_order_items;
  ]

let () = run_test_tt_main suite
