(** 
   Módulo de tipos utilizados no projeto ETL.
   A entrada é carregada em uma estrutura de lista de records.
*)

(** 
   Representa um record de pedido no sistema de gestão.
   - [id]: Identificador único do pedido.
   - [client_id]: Identificador do cliente associado ao pedido.
   - [order_date]: Data do pedido, em formato ISO 8601.
   - [status]: Status do pedido (ex.: pending, complete, cancelled).
   - [origin]: Origem do pedido ("P" para paraphysical, "O" para online).
*)
type order = {
  id : int;
  client_id : int;
  order_date : string;
  status : string;
  origin : string;
}

(** 
   Representa um record de item de um pedido.
   - [order_id]: Identificador do pedido ao qual o item pertence.
   - [product_id]: Identificador do produto.
   - [quantity]: Quantidade do produto no pedido.
   - [price]: Preço do produto no momento da compra.
   - [tax]: Percentual de imposto aplicado sobre o produto.
*)
type order_item = {
  order_id : int;
  product_id : int;
  quantity : int;
  price : float;
  tax : float;
}

(** 
   Representa o record de resultado do processamento de um pedido.
   - [order_id]: Identificador do pedido.
   - [total_amount]: Total da receita do pedido, calculado como a soma de (quantidade * preço) de cada item.
   - [total_taxes]: Total dos impostos aplicados no pedido, calculado como o percentual multiplicado pela receita de cada item.
*)
type order_output = {
  order_id : int;
  total_amount : float;
  total_taxes : float;
}

(** 
   Representa um record de dados agregados dos pedidos, calculados por mês e ano.
   - [month]: Mês referente à agregação.
   - [year]: Ano referente à agregação.
   - [avg_revenue]: Receita média dos pedidos no mês/ano.
   - [avg_taxes]: Impostos médios dos pedidos no mês/ano.
*)
type aggregated = {
  month : int;
  year : int;
  avg_revenue : float;
  avg_taxes : float;
}
