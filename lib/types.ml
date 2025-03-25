(** 
   Módulo de tipos utilizados no projeto ETL.
*)

type order = {
  id : int;
  client_id : int;
  order_date : string;
  status : string;
  origin : string;
}

type order_item = {
  order_id : int;
  product_id : int;
  quantity : int;
  price : float;
  tax : float;
}

type order_output = {
  order_id : int;
  total_amount : float;
  total_taxes : float;
}

type aggregated = {
  month : int;
  year : int;
  avg_revenue : float;
  avg_taxes : float;
}
