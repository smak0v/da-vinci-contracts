#include "../partial/IMarket.ligo"

[@inline] function getUserToken (const userAddress : address; const userData : userMap) : tokenParams is
  case userData[userAddress] of
    Some (tokenParams) -> tokenParams
    | None -> (failwith ("Tokens not found") : tokenParams)
  end

// [@inline] function getTokenPrice (const tokenAddress : address; const tokenData : tokenParams) : nat is
//   case tokenData[tokenAddress] of
//     Some (v) -> v
//     | None -> failwith ("This token not found")
//   end

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
    var tokenForSet : tokenParams := record[tokenId = tokenId; price = price; owner = Tezos.sender];
    s.userData[Tezos.sender] := Set.add(tokenForSet, s.userData[Tezos.sender]);

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
    var tokenSet : set(tokenParams) := getUserToken(ownerAddress);
    var certainToken : tokenParams := record [tokenId = 0n; price = 0tez; owner = zeroAddress];

    for elem in set tokenSet block {
      if elem.tokenId = tokenId then
        certainToken := elem;
      else skip;
    };

    s.userData[ownerAddress] := Set.remove(certainToken, s.userData[ownerAddress]);

    const transferDestination : transfer_destination = record [
      to_ = Tezos.sender;
      token_id = certainToken.tokenId;
      amount = 1n;
    ];
    const transferParam : transfer_param = record [
      from_ = Tezos.self_address;
      txs = list [transferDestination];
    ];

    if Tezos.amount =/= certainToken.price then
      failwith("Not enough XTZ")
    else skip;

    const receiver : contract(unit) = case (Tezos.get_contract_opt(ownerAddress) : option(contract(unit))) of
      | Some(contract) -> contract
      | None -> (failwith("Invalid contract") : contract(unit))
      end;

    const operations : list(operation) = list[
      Tezos.transaction(
        Tezos.sender, 
        certainToken.price, 
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
    var tokenSet : set(tokenParams) := getUserToken(Tezos.sender);
    var certainToken : tokenParams := record [tokenId = 0n; price = 0tez; owner = zeroAddress];

    for elem in set tokenSet block {
      if elem.tokenId = tokenId then
        certainToken := elem;
      else skip;
    };

    s.userData[Tezos.sender] := Set.remove(certainToken, s.userData[Tezos.sender]);

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

function changePrice (var s : storage) : return is
  block {
    
  }

function main(const action : entryAction; var s : storage) : return is
  block {
  skip
  } with case action of
  | SetMarketAdmin(params) -> setMarketAdmin(params, s)
  | ExhibitToken(params) -> exhibitToken(params, s)
  | Buy(params) -> buy(params, s)
  | Delete(params) -> delete(params, s)
  | ChangePrice(params) -> 
  end;
