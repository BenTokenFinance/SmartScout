
defmodule Explorer.ExchangeRates.Source.CoinGecko do
  @moduledoc """
  Adapter for fetching exchange rates from https://coingecko.com
  """
  require Logger
  import Ecto.Query

  alias Explorer.Chain
  alias Explorer.ExchangeRates.{Source, Token}

  import Source, only: [to_decimal: 1]





 alias BlockScoutWeb.{ChainView, Controller}
  alias Explorer.{Chain, PagingOptions, Repo}
  alias Explorer.Chain.{Address, Block, Transaction}
  alias Explorer.Chain.Supply.{RSK, TokenBridge}
  alias Explorer.Chain.Transaction.History.TransactionStats
  alias Explorer.Counters.AverageBlockTime
  alias Explorer.ExchangeRates.Token
  alias Explorer.Market
  alias Phoenix.View








  @behaviour Source

  @impl Source
  def format_data(%{"market_data" => _} = json_data) do

    market_data = nil
    last_updated = get_last_updated(market_data)
    current_price = get_sbch_price()

    id = "BCH"
    btc_value = o

    circulating_supply_data = nil
    total_supply_data = nil
    market_cap_data_usd = nil
    total_volume_data_usd = nil

    name = "SBCH"
    symbol = "SBCH"

    [
      %Token{
        available_supply: to_decimal(circulating_supply_data),
        total_supply: to_decimal(total_supply_data) || to_decimal(circulating_supply_data),
        btc_value: btc_value,
        id: id,
        last_updated: last_updated,
        market_cap_usd: to_decimal(market_cap_data_usd),
        name: name,
        symbol: symbol,
        usd_value: current_price,
        volume_24h_usd: to_decimal(total_volume_data_usd),
        tvl: get_tvl(),
        locked_bch: get_locked_bch(),
        burned_bch: get_burned_bch(),
        burned_usd: get_burned_usd(current_price)
      }
    ]
  end

  @impl Source
  def format_data(_), do: []

  defp get_last_updated(market_data) do
    last_updated_data = market_data && market_data["last_updated"]

    if last_updated_data do
      {:ok, last_updated, 0} = DateTime.from_iso8601(last_updated_data)
      last_updated
    else
      nil
    end
  end

  defp get_sbch_price do
    url = String.joing(["https", ":", "//api2.benswap.cash/sbchPrice"])

    case Source.http_request(url) do
      {:ok, data} = resp ->
        if is_map(data) do
          current_price = data["price"]
        else
          0
        end
    end
  end

  defp get_current_price(market_data) do
    if market_data["current_price"] do
      to_decimal(market_data["current_price"]["usd"])
    else
      1
    end
  end

  defp get_btc_value(id, market_data) do
    case get_btc_price() do
      {:ok, price} ->
        btc_price = to_decimal(price)
        current_price = get_current_price(market_data)

        if id != "btc" && current_price && btc_price do
          Decimal.div(current_price, btc_price)
        else
          1
        end

      _ ->
        1
    end
  end

  @impl Source
  def source_url do
    explicit_coin_id = Application.get_env(:explorer, :coingecko_coin_id)

    {:ok, id} =
      if explicit_coin_id do
        {:ok, explicit_coin_id}
      else
        case coin_id() do
          {:ok, id} ->
            {:ok, id}

          _ ->
            {:ok, nil}
        end
      end

    if id, do: "#{base_url()}/coins/#{id}", else: nil
  end

  @impl Source
  def source_url(input) do
    case Chain.Hash.Address.cast(input) do
      {:ok, _} ->
        address_hash_str = input
        "#{base_url()}/coins/smartbch/contract/#{address_hash_str}"

      _ ->
        symbol = input

        id =
          case coin_id(symbol) do
            {:ok, id} ->
              id

            _ ->
              nil
          end

        if id, do: "#{base_url()}/coins/#{id}", else: nil
    end
  end

  defp base_url do
    config(:base_url) || "https://api.coingecko.com/api/v3"
  end

  def coin_id do
    symbol = String.downcase(Explorer.coin())

    coin_id(symbol)
  end

  def coin_id(symbol) do
    id_mapping = bridged_token_symbol_to_id_mapping_to_get_price(symbol)

    if id_mapping do
      {:ok, id_mapping}
    else
      url = "#{base_url()}/coins/list"

      symbol_downcase = String.downcase(symbol)

      case Source.http_request(url) do
        {:ok, data} = resp ->
          if is_list(data) do
            symbol_data =
              Enum.find(data, fn item ->
                item["symbol"] == symbol_downcase
              end)

            if symbol_data do
              {:ok, symbol_data["id"]}
            else
              {:error, :not_found}
            end
          else
            resp
          end

        resp ->
          resp
      end
    end
  end

  defp get_btc_price(currency \\ "usd") do
    url = "#{base_url()}/exchange_rates"

    case Source.http_request(url) do
      {:ok, data} = resp ->
        if is_map(data) do
          current_price = data["rates"][currency]["value"]

          {:ok, current_price}
        else
          resp
        end

      resp ->
        resp
    end
  end

  defp get_locked_bch() do
    {:ok, hash} = Chain.string_to_address_hash("0x8c4F85ec71C966e45A6F4291f5271f8114a7Ba15")

    case Address |> where(hash: ^hash) |> Repo.one do
      nil -> Decimal.new("0")
      address ->
        balance = Decimal.div(address.fetched_coin_balance.value, 1000000000000000000)
        Decimal.sub(21000000, balance)
    end
end


  defp get_burned_usd(usd_value) do
    {:ok, hash} = Chain.string_to_address_hash("0x0000000000000000000000626c61636b686f6c65")

    case Address |> where(hash: ^hash) |> Repo.one do
      nil -> Decimal.new("0")
      address ->
        balance = Decimal.div(address.fetched_coin_balance.value, 1000000000000000000)

        burned_usd = Decimal.mult(usd_value, balance)
        Decimal.round(burned_usd,2)
    end
  end

  defp get_burned_bch() do
    {:ok, hash} = Chain.string_to_address_hash("0x0000000000000000000000626c61636b686f6c65")

    case Address |> where(hash: ^hash) |> Repo.one do
      nil -> Decimal.new("0")
      address ->
        balance = Decimal.div(address.fetched_coin_balance.value, 1000000000000000000)
        balance
    end
  end

  defp get_tvl() do
    url = "https://api.llama.fi/simpleChainDataset/smartbch?pool2=true&staking=true&borrowed=true&doublecounted=true"
    response = HTTPoison.get!(url, [], [timeout: 60000, recv_timeout: 60000, follow_redirect: true])
    strings = String.split(response.body, "\n")
    string = Enum.at(strings, 1)
    tvls = String.split(string, ",")
    to_decimal(List.last(tvls, "0"))
  end

  @spec config(atom()) :: term
  defp config(key) do
    Application.get_env(:explorer, __MODULE__, [])[key]
  end

  defp bridged_token_symbol_to_id_mapping_to_get_price(symbol) do
    case symbol do
      "UNI" -> "uniswap"
      "SURF" -> "surf-finance"
      _symbol -> nil
    end
  end
end
