open Types

(** 
   Converte uma lista de strings para um registro de [order].
   [fields] deve conter os campos: id, client_id, order_date, status, origin.
*)
let load_order (fields : string list) : order =
  match fields with
  | [id; client_id; order_date; status; origin] ->
      { id = int_of_string id;
        client_id = int_of_string client_id;
        order_date;
        status;
        origin }
  | _ -> failwith "Formato inválido para Order"

(** 
   Converte uma lista de strings para um registro de [order_item].
   [fields] deve conter os campos: order_id, product_id, quantity, price, tax.
*)
let load_order_item (fields : string list) : order_item =
  match fields with
  | [order_id; product_id; quantity; price; tax] ->
      { order_id = int_of_string order_id;
        product_id = int_of_string product_id;
        quantity = int_of_string quantity;
        price = float_of_string price;
        tax = float_of_string tax }
  | _ -> failwith "Formato inválido para OrderItem"

(** 
   Agrupa os [order_item]s por [order_id].
   Retorna uma lista de tuplas (order_id, order_item list).
*)
let group_order_items (items : order_item list) : (int * order_item list) list =
  let add_item (acc : (int * order_item list) list) (item : order_item) : (int * order_item list) list =
    let key = item.order_id in
    let items_for_key = try List.assoc key acc with Not_found -> [] in
    (key, item :: items_for_key) :: List.remove_assoc key acc
  in
  List.fold_left add_item ([] : (int * order_item list) list) items

(** 
   Calcula o total de receita e o total de impostos para uma lista de [order_item]s.
   - Receita: quantity * price.
   - Imposto: (tax/100.0) * (quantity * price).
*)
let compute_totals (items : order_item list) : (float * float) =
  let calc (rev, tax_sum) item =
    let revenue = float_of_int item.quantity *. item.price in
    let tax_amount = (item.tax) *. revenue in
    (rev +. revenue, tax_sum +. tax_amount)
  in
  List.fold_left calc (0.0, 0.0) items

(** 
   Realiza a junção dos dados de [order] e [order_item] e calcula os totais para cada ordem.
   Os pedidos são filtrados pelos parâmetros [filter_status] e [filter_origin].
   Retorna uma lista de [order_output].
*)
let join_and_compute (orders : order list) (items : order_item list) 
    (filter_status : string) (filter_origin : string) : order_output list =
  let orders_filtered = List.filter (fun o ->
      (filter_status = "" || String.lowercase_ascii o.status = String.lowercase_ascii filter_status) &&
      (filter_origin = "" || o.origin = filter_origin)
    ) orders in
  let items_grouped = group_order_items items in
  let find_items order_id =
    try List.assoc order_id items_grouped with Not_found -> []
  in
  List.filter_map (fun o ->
    let order_items = find_items o.id in
    if order_items = [] then None
    else 
      let total_amount, total_taxes = compute_totals order_items in
      Some { order_id = o.id; total_amount; total_taxes }
  ) orders_filtered

(** 
   Agrupa os resultados por mês e ano, calculando a média de receita e de impostos.
   Assume que [order_date] está no formato ISO 8601 "YYYY-MM-DD".
*)
let group_by_month_year (orders : order list) (outputs : order_output list) : aggregated list =
  let parse_date date_str =
    try
      Scanf.sscanf date_str "%d-%d-%d" (fun year month day -> (year, month, day))
    with _ -> (0, 0, 0)
  in
  let add_agg acc order_output =
    let order = List.find (fun o -> o.id = order_output.order_id) orders in
    let year, month, _ = parse_date order.order_date in
    let key = (year, month) in
    let current = try List.assoc key acc with Not_found -> (0.0, 0.0, 0) in
    let new_sum_revenue = let (rev, _, _) = current in rev +. order_output.total_amount in
    let new_sum_tax = let (_, tax, _) = current in tax +. order_output.total_taxes in
    let new_count = let (_, _, count) = current in count + 1 in
    (key, (new_sum_revenue, new_sum_tax, new_count)) :: List.remove_assoc key acc
  in
  let aggregated = List.fold_left add_agg [] outputs in
  List.map (fun ((year, month), (sum_revenue, sum_tax, count)) ->
    { month; year; avg_revenue = sum_revenue /. (float_of_int count); avg_taxes = sum_tax /. (float_of_int count) }
  ) aggregated
