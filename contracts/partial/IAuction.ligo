// Auction types
type token_params is [@layout:comb] record [
  token                   : address;
  tokenId                 : nat;
]

type submit_token_params is [@layout:comb] record [
  tokenParams             : token_params;
  initialPrice            : nat;
  minBidStep              : nat;
  lifetime                : nat;
  extensionTime           : nat;
]

type make_bid_params is [@layout:comb] record [
  tokenParams             : token_params;
  bid                     : nat;
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

type auction_params is [@layout:comb] record [
  tokenParams             : submit_token_params;
  bids                    : list(bid_params);
  createdAt               : timestamp;
]

type storage is [@layout:comb] record [
  auctions                : list(auction_params);
  auctionByToken          : big_map(token_params, auction_params);
  auctionsByUser          : big_map(address, list(auction_params));
  tokensByUser            : big_map(address, list(token_params));
  previousAuctionsByToken : big_map(token_params, list(previous_auctions_params));
  minAuctionLifetime      : nat;
  maxExtensionTime        : nat;
  admin                   : address;
]

type return is list(operation) * storage

type actions is
| SubmitForAuction of submit_token_params
| MakeBid of make_bid_params
| ClaimToken of unit
| ClaimCoins of unit
| SetAdmin of address

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
