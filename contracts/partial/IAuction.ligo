// Auction types
type submit_token_params is [@layout:comb] record [
  token                   : address;
  tokenId                 : nat;
  initialPrice            : nat;
  minBidStep              : nat;
  lifetime                : nat;
  extensionTime           : nat;
]

type bid_params is [@layout:comb] record [
  user                    : address;
  bid                     : nat;
  createdAt               : timestamp;
]

type previous_auctions_params is [@layout:comb] record [
  bids                    : list(bid_params);
  createdAt               : timestamp;
]

type auctions_params is [@layout:comb] record [
  token_params            : submit_token_params;
  bids                    : list(bid_params);
  createdAt               : timestamp;
]

type token_params is [@layout:comb] record [
  token                   : address;
  tokenId                 : nat;
]

type storage is [@layout:comb] record [
  auctions                : list(auctions_params);
  auctionsByUser          : big_map(address, list(auctions_params));
  tokensByUser            : big_map(address, list(token_params));
  previousAuctionsByToken : big_map(token_params, list(previous_auctions_params));
]

type return is list(operation) * storage

type actions is
| SubmitForAuction of submit_token_params

[@inline] const noOperations : list(operation) = nil;

// FA2 types
type transfer_destination is [@layout:comb] record [
  to_ : address;
  token_id : nat;
  amount : nat;
]

type transfer_param is [@layout:comb] record [
  from_ : address;
  txs : list(transfer_destination);
]

type transfer_params is list(transfer_param)

type transfer_type is TransferType of transfer_params
