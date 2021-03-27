#include "../partial/IAuction.ligo"

function getTokenTransferEntrypoint(const token : address) : contract(transfer_type) is
  case (Tezos.get_entrypoint_opt("%transfer", token) : option(contract(transfer_type))) of
  | Some(c) -> c
  | None -> (failwith("getTokenTransferEntrypoint not found") : contract(transfer_type))
  end;

function getAuctionsByUser(const user : address; const s : storage) : list(auction_params) is
  block {
    const auctionsByUser : list(auction_params) = case s.auctionsByUser[user] of
    | Some(lst) -> lst
    | None -> (list [] : list(auction_params))
    end;
  } with auctionsByUser

function getTokensByUser(const user : address; const s : storage) : list(token_params) is
  block {
    const tokensByUser : list(token_params) = case s.tokensByUser[user] of
    | Some(lst) -> lst
    | None -> (list [] : list(token_params))
    end;
  } with tokensByUser

function getTokenTransferOperation(const token : address; const tokenId : nat) : operation is
  block {
    const transferDestination : transfer_destination = record [
      to_ = Tezos.self_address;
      token_id = tokenId;
      amount = 1n;
    ];
    const transferParam : transfer_param = record [
      from_ = Tezos.sender;
      txs = list [transferDestination];
    ];
    const op = Tezos.transaction(
      TransferType(list [transferParam]),
      0mutez,
      getTokenTransferEntrypoint(token)
    );
  } with op

function checkIfTokenIsOnAuction(const tokenParams : token_params; const s : storage) : bool is
  case s.auctionByToken[tokenParams] of
  | Some(v) -> True
  | None -> False
  end;

function validateSubmition(const params : submit_token_params; var s : storage) : unit is
  block {
    if params.lifetime < s.minAuctionLifetime then
      failwith("Too small lifetime")
    else
      skip;

    if params.extensionTime > s.maxExtensionTime then
      failwith("Too high extension time")
    else
      skip;

    if checkIfTokenIsOnAuction(params.tokenParams, s) then
      failwith("Token already is on auction")
    else
      skip;
  } with unit

function validateBid(const bidParams : make_bid_params; var s : storage) : unit is
  block {
    if not checkIfTokenIsOnAuction(bidParams.tokenParams, s) then
      failwith("Token is not on auction")
    else
      skip;

    if
  } with unit

function submitForAuction(const params : submit_token_params; var s : storage) : return is
  block {
    validateSubmition(params, s);

    const operations : list(operation) = list [getTokenTransferOperation(
      params.tokenParams.token,
      params.tokenParams.tokenId
    )];
    const bid : bid_params = record [
      user = Tezos.sender;
      bid = params.initialPrice;
      createdAt = Tezos.now;
    ];
    const auction : auction_params = record [
      tokenParams = params;
      bids = list [bid];
      createdAt = Tezos.now;
    ];
    const token : token_params = record [
      token = params.tokenParams.token;
      tokenId = params.tokenParams.tokenId;
    ];
    var auctionsByUser := getAuctionsByUser(Tezos.sender, s);
    var tokensByUser := getTokensByUser(Tezos.sender, s);

    auctionsByUser := auction # auctionsByUser;
    tokensByUser := token # tokensByUser;
    s.auctions := auction # s.auctions;
    s.auctionsByUser[Tezos.sender] := auctionsByUser;
    s.tokensByUser[Tezos.sender] := tokensByUser;
  } with (operations, s)

function makeBid(const bidParams : make_bid_params; var s : storage) : return is
  block {
    validateBid(bidParams, s);

  } with (noOperations, s)

function claimToken(var s : storage) : return is
  block {
    skip;
  } with (noOperations, s)

function claimCoins(var s : storage) : return is
  block {
    skip;
  } with (noOperations, s)

function setAdmin(const admin : address; var s : storage) : return is
  block {
    if Tezos.sender =/= s.admin then
      failwith("Not admin");
    else
      skip;

    s.admin := admin;
  } with (noOperations, s)

function main(const action : actions; const s : storage) : return is
  case action of
  | SubmitForAuction(v) -> submitForAuction(v, s)
  | MakeBid(v) -> makeBid(v, s)
  | ClaimToken(v) -> claimToken(s)
  | ClaimCoins(v) -> claimCoins(s)
  | SetAdmin(v) -> setAdmin(v, s)
  end
