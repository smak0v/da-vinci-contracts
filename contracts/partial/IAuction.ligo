// Auction types
type tokenId is nat
type auctionId is nat

type submit_token_params is [@layout:comb] record [
  tokenId                 : tokenId;
  initialPrice            : tez;
  minBidStep              : tez;
  lifetime                : nat;
  extensionTime           : nat;
]

type make_bid_params is [@layout:comb] record [
  tokenId                 : tokenId;
  bid                     : tez;
]

type bid_params is [@layout:comb] record [
  user                    : address;
  bid                     : tez;
]

type auction_params is [@layout:comb] record [
  creator                 : address;
  tokenParams             : submit_token_params;
  lastBid                 : bid_params;
  createdAt               : timestamp;
  finished                : bool;
]

type storage is [@layout:comb] record [
  auctions                : big_map(auctionId, auction_params);
  auctionByToken          : big_map(tokenId, auctionId);
  auctionsByUser          : big_map(address, set(auctionId));
  tokensByUser            : big_map(address, set(tokenId));
  admin                   : address;
  token                   : address;
  lastAuctionId           : nat;
  minAuctionLifetime      : nat;
  maxExtensionTime        : nat;
  fee                     : tez;
  totalFee                : tez;
]

type return is list(operation) * storage

type actions is
| SubmitForAuction of submit_token_params
| MakeBid of make_bid_params
| ClaimToken of tokenId
| ClaimCoins of tokenId
| SetAdmin of address
| SetMinAuctionLifetime of nat
| SetMaxExtensionTime of nat
| SetFee of tez
| WithdrawFee of address

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
