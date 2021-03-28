const zeroAddress : address = ("tz1ZZZZZZZZZZZZZZZZZZZZZZZZZZZZNkiRg" : address);

type itemParams is [@layout:comb] record [
  owner           : address;
  tokenId         : nat;
  price           : tez;
  status          : nat; // 0 - market, 1 - sold, 2 - del
]

type storage is [@layout:comb] record [
  tokenFa2        : address;
  admin           : address;
  tokensByUser    : big_map(address, set(nat)); // users token
  marketsByToken  : big_map(nat, nat); // (tokenId, marketId)
  markets         : big_map(nat, itemParams); // (marketId, itemParams)
  marketsByUser   : big_map(address, set(nat)); // users items in market
  lastTokenId     : nat;
  fee             : tez;
]

type changePriceParams is [@layout:comb] record [
  tokenId         : nat;
  price           : tez;
]

type transfer_destination is [@layout:comb] record [
  to_             : address;
  token_id        : nat;
  amount          : nat;
]

type transfer_param is [@layout:comb] record [
  from_           : address;
  txs             : list(transfer_destination);
]

type transfer_params is list(transfer_param)
type transferType is TransferType of transfer_params

[@inline] const noOperations : list (operation) = nil;
type return is list (operation) * storage

type entryAction is
  | SetMarketAdmin of address
  | SetNewFee of tez
  | Withdraw of address
  | ExhibitToken of changePriceParams
  | Buy of nat
  | Delete of nat
  | ChangePrice of changePriceParams
