const zeroAddress : address = ("tz1ZZZZZZZZZZZZZZZZZZZZZZZZZZZZNkiRg" : address);

type tokenParams is [@layout:comb] record [
  tokenId       : nat;
  price         : tez;
  owner         : address;
]

type userMap is map (address, set(tokenParams));

type storage is [@layout:comb] record [
  tokenFa2      : address;
  admin         : address;
  userData      : userMap;
  tokenCounter  : nat;
]

type ownerTokenParams is [@layout:comb] record [
  ownerAddress  : address;
  tokenId       : nat;
]

type transfer_destination is [@layout:comb] record [
  to_           : address;
  token_id      : nat;
  amount        : nat;
]

type transfer_param is [@layout:comb] record [
  from_         : address;
  txs           : list(transfer_destination);
]

type transfer_params is list(transfer_param)
type transferType is TransferType of transfer_params

[@inline] const noOperations : list (operation) = nil;
type return is list (operation) * storage

type entryAction is 
  | SetMarketAdmin of address
  | ExhibitToken of tokenParams
  | Buy of ownerTokenParams
  | Delete of nat
  | ChangePrice of tokenParams
