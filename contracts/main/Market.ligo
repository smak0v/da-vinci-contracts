#include "../partial/IMarket.ligo"

[@inline] function getMarketsByUser(const user : address; const s : storage) : set(nat) is
  block {
    const marketsByUser : set(nat) = case s.marketsByUser[user] of
    | Some(v) -> v
    | None -> (set [] : set(nat))
    end;
  } with marketsByUser

[@inline] function getTokensByUser(const user : address; const s : storage) : set(nat) is
  block {
    const tokensByUser : set(nat) = case s.tokensByUser[user] of
    | Some(v) -> v
    | None -> (set [] : set(nat))
    end;
  } with tokensByUser

[@inline] function checkToken (const tokenId : nat; const s : storage) : nat is
  case s.marketsByToken[tokenId] of
    | Some(v) -> v
    | None -> 0n
  end;

[@inline] function getMarket (const marketTokenId : nat; const s : storage) : itemParams is
  case s.markets[marketTokenId] of
    | Some(v) -> v
    | None -> (failwith("No active market for this token"): itemParams)
  end;

[@inline] function getTokenTransferEntrypoint (const tokenAddress : address) : contract(transferType) is
  case (Tezos.get_entrypoint_opt("%transfer", tokenAddress) : option(contract(transferType))) of
  Some(contr) -> contr
  | None -> (failwith("CantGetContractToken") : contract(transferType))
  end;

function setMarketAdmin (const newAdmin : address; var s : storage) : return is
  block {
  if Tezos.sender =/= s.admin then
    failwith("NotAdmin")
  else skip;
  s.admin := newAdmin;
  } with (noOperations, s)

function exhibitToken (const tokenId : nat; const price : tez; var s : storage) : return is
  block {
    if price = 0tez then
      failwith("exhibitPrice is zero")
    else skip;

    var itemData : itemParams := record [
      owner = Tezos.sender;
      tokenId = tokenId;
      price = price;
      status = 0n;
    ];

    var marketsByUser := getMarketsByUser(Tezos.sender, s);
    var tokensByUser := getTokensByUser(Tezos.sender, s);

    s.lastTokenId := s.lastTokenId + 1n;
    marketsByUser := Set.add(s.lastTokenId, marketsByUser);
    tokensByUser := Set.add(tokenId, tokensByUser);
    s.markets[s.lastTokenId] := itemData;
    s.marketsByToken[tokenId] := s.lastTokenId;
    s.marketsByUser[Tezos.sender] := marketsByUser;
    s.tokensByUser[Tezos.sender] := tokensByUser;

    const transferDestination : transfer_destination = record [
      to_ = Tezos.self_address;
      token_id = tokenId;
      amount = 1n;
    ];
    const transferParam : transfer_param = record [
      from_ = Tezos.sender;
      txs = list [transferDestination];
    ];
    const operations : list(operation) = list [Tezos.transaction(
      TransferType(list[transferParam]),
      0mutez,
      getTokenTransferEntrypoint(s.tokenFa2)
    )];
  } with (operations, s)

function buy (const tokenId : nat; var s : storage) : return is
  block {
    var marketTokenId : nat := checkToken(tokenId, s);
    if marketTokenId = 0n then
      failwith("marketTokenId is zero")
    else skip;

    var itemData : itemParams := record [
      owner = zeroAddress;
      tokenId = tokenId;
      price = 0tez;
      status = 1n;
    ];

    var market := getMarket(marketTokenId, s);

    s.markets[marketTokenId] := itemData;

    remove tokenId from map s.marketsByToken;
    s.marketsByUser[Tezos.sender] := Set.remove(marketTokenId, getMarketsByUser(Tezos.sender, s));

    const transferDestination : transfer_destination = record [
      to_ = Tezos.sender;
      token_id = market.tokenId;
      amount = 1n;
    ];
    const transferParam : transfer_param = record [
      from_ = Tezos.self_address;
      txs = list [transferDestination];
    ];

    if market.price = 0tez then
      failwith("Price is zero")
    else skip;

    if Tezos.amount =/= market.price then
      failwith("Not enough XTZ")
    else skip;

    const receiver : contract(unit) = case (Tezos.get_contract_opt(market.owner) : option(contract(unit))) of
      | Some(contract) -> contract
      | None -> (failwith("Invalid contract") : contract(unit))
      end;

    const operations : list(operation) = list[
      Tezos.transaction(
        unit,
        market.price,
        receiver
      );
      Tezos.transaction(
        TransferType(list[transferParam]),
        0mutez,
        getTokenTransferEntrypoint(s.tokenFa2)
      )
    ];
  } with (operations, s)

function delete (const tokenId : nat; var s : storage) : return is
  block {
    var marketTokenId : nat := checkToken(tokenId, s);
    if marketTokenId = 0n then
      failwith("marketTokenId is zero")
    else skip;

    var itemData : itemParams := record [
      owner = zeroAddress;
      tokenId = tokenId;
      price = 0tez;
      status = 2n;
    ];

    var market := getMarket(marketTokenId, s);

    s.markets[marketTokenId] := itemData;

    remove tokenId from map s.marketsByToken;
    s.marketsByUser[Tezos.sender] := Set.remove(marketTokenId, getMarketsByUser(Tezos.sender, s));

    const transferDestination : transfer_destination = record [
      to_ = Tezos.sender;
      token_id = tokenId;
      amount = 1n;
    ];
    const transferParam : transfer_param = record [
      from_ = Tezos.self_address;
      txs = list [transferDestination];
    ];
    const operations : list(operation) = list[
      Tezos.transaction(
        TransferType(list[transferParam]),
        0mutez,
        getTokenTransferEntrypoint(s.tokenFa2)
    )];
  } with (operations, s)

function changePrice (const tokenId : nat; const price : tez; var s : storage) : return is
  block {
    var marketTokenId : nat := checkToken(tokenId, s);

    if marketTokenId = 0n then
      failwith("marketTokenId is zero")
    else skip;

    var market := getMarket(marketTokenId, s);

    if (market.owner = Tezos.sender) and (market.price > 0tez) then
      s.markets[marketTokenId] := record [
        owner = Tezos.sender;
        tokenId = tokenId;
        price = price;
        status = 0n;
      ];
    else skip;
  } with (noOperations, s)

function main (const action : entryAction; var s : storage) : return is
  case action of
  | SetMarketAdmin(params) -> setMarketAdmin(params, s)
  | ExhibitToken(params) -> exhibitToken(params.tokenId, params.price, s)
  | Buy(params) -> buy(params, s)
  | Delete(params) -> delete(params, s)
  | ChangePrice(params) -> changePrice(params.tokenId, params.price, s)
  end;
