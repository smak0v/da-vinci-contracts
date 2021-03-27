#include "../partial/IMarket.ligo"

[@inline] function getMap (const tokenAddress : address; const tokenData : userMap) : map(nat, tez) is
  case tokenData[tokenAddress] of
    Some (v) -> v
    | None -> failwith ("This map not found")
  end

[@inline] function getPrice (const tokenId : nat; const tokenData : map(nat, tez)) : tez is
  case tokenData[tokenId] of
    Some (v) -> v
    | None -> failwith ("This tokenId not found")
  end

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
    s.userData[Tezos.sender] := Map.add(tokenId, price, s.userData[Tezos.sender]);

    const transferDestination : transfer_destination = record [
      to_ = Tezos.self_address;
      token_id = tokenId;
      amount = 1n;
    ];
    const transferParam : transfer_param = record [
      from_ = Tezos.sender;
      txs = list [transferDestination];
    ];
    const operations = Tezos.transaction(
      TransferType(list[transferParam]),
      0mutez,
      getTokenTransferEntrypoint(s.tokenFa2)
    );
  } with (operations, s)

function buy (const ownerAddress : address; const tokenId : nat; var s : storage) : return is
  block {
    var userMap : map(nat, tez) := getMap(ownerAddress);
    var userPrice : tez := getPrice(userMap);
    s.userData[ownerAddress] := Map.remove(tokenId, s.userData[ownerAddress]);

    const transferDestination : transfer_destination = record [
      to_ = Tezos.sender;
      token_id = tokenId;
      amount = 1n;
    ];
    const transferParam : transfer_param = record [
      from_ = Tezos.self_address;
      txs = list [transferDestination];
    ];

    if Tezos.amount =/= userPrice then
      failwith("Not enough XTZ")
    else skip;

    const receiver : contract(unit) = case (Tezos.get_contract_opt(ownerAddress) : option(contract(unit))) of
      | Some(contract) -> contract
      | None -> (failwith("Invalid contract") : contract(unit))
      end;

    const operations : list(operation) = list[
      Tezos.transaction(
        Tezos.sender,
        userPrice,
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
    s.userData[Tezos.sender] := Map.remove(tokenId, s.userData[Tezos.sender]);

    const transferDestination : transfer_destination = record [
      to_ = Tezos.sender;
      token_id = tokenId;
      amount = 1n;
    ];
    const transferParam : transfer_param = record [
      from_ = Tezos.self_address;
      txs = list [transferDestination];
    ];
    const operations = Tezos.transaction(
      TransferType(list[transferParam]),
      0mutez,
      getTokenTransferEntrypoint(s.tokenFa2)
    );
  } with (operations, s)

function changePrice (const tokenId : nat; const price : nat; var s : storage) : return is
  block {
    var userMap : map(nat, tez) := getMap(ownerAddress);
    var userPrice : tez := getPrice(userMap);
    if userPrice > 0tez then
      s.userData[Tezos.sender] := Map.update(tokenId, price, s.userData[Tezos.sender]);
    else skip;

  } with (noOperations, s)

function main(const action : entryAction; var s : storage) : return is
  block {
  skip
  } with case action of
  | SetMarketAdmin(params) -> setMarketAdmin(params, s)
  | ExhibitToken(params) -> exhibitToken(params, s)
  | Buy(params) -> buy(params, s)
  | Delete(params) -> delete(params, s)
  | ChangePrice(params) -> changePrice(params, s)
  end;
