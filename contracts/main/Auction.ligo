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

function getTokensByUser(const user : address; const s : storage) : list(tokenId) is
  block {
    const tokensByUser : list(tokenId) = case s.tokensByUser[user] of
    | Some(lst) -> lst
    | None -> (list [] : list(tokenId))
    end;
  } with tokensByUser

function getTokenTransferOperation(const token : address; const tokenId : tokenId) : operation is
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

function checkIfTokenIsOnAuction(const tokenId : tokenId; const s : storage) : bool is
  case s.auctionByToken[tokenId] of
  | Some(v) -> True
  | None -> False
  end;

function validateSubmition(const params : submit_token_params; const s : storage) : unit is
  block {
    if params.lifetime < s.minAuctionLifetime then
      failwith("Too small lifetime")
    else
      skip;

    if params.extensionTime > s.maxExtensionTime then
      failwith("Too high extension time")
    else
      skip;

    if checkIfTokenIsOnAuction(params.tokenId, s) then
      failwith("Token already is on auction")
    else
      skip;
  } with unit

function validateBid(const bidParams : make_bid_params; const auction : auction_params; const s : storage) : bid_params is
  block {
    var lastBid : bid_params := record [
      user = ("tz1ZZZZZZZZZZZZZZZZZZZZZZZZZZZZNkiRg" : address);
      bid = 0tez;
      createdAt = ("1970-01-01T00:00:00Z" : timestamp);
    ];

    for bid in list auction.bids block {
      if bid.createdAt > lastBid.createdAt then
        lastBid := bid;
      else
        skip;
    };

    if auction.createdAt + int(auction.tokenParams.lifetime) < Tezos.now then
      failwith("Auction is already finished")
    else
      skip;

    if bidParams.bid - lastBid.bid < auction.tokenParams.minBidStep then
      failwith("Bid should be greater than min bid step")
    else
      skip;
  } with lastBid

function submitForAuction(const params : submit_token_params; var s : storage) : return is
  block {
    validateSubmition(params, s);

    const operations : list(operation) = list [getTokenTransferOperation(
      s.token,
      params.tokenId
    )];
    const auction : auction_params = record [
      creator = Tezos.sender;
      tokenParams = params;
      bids = (list [] : list(bid_params));
      createdAt = Tezos.now;
    ];
    var auctionsByUser := getAuctionsByUser(Tezos.sender, s);
    var tokensByUser := getTokensByUser(Tezos.sender, s);

    auctionsByUser := auction # auctionsByUser;
    tokensByUser := params.tokenId # tokensByUser;
    s.auctions := auction # s.auctions;
    s.auctionsByUser[Tezos.sender] := auctionsByUser;
    s.tokensByUser[Tezos.sender] := tokensByUser;
  } with (operations, s)

function makeBid(const bidParams : make_bid_params; var s : storage) : return is
  block {
    const auctionByToken : auction_params = case s.auctionByToken[bidParams.tokenId] of
    | Some(v) -> v
    | None -> (failwith("No active auctions for this token") : auction_params)
    end;
    const lastBid : bid_params = validateBid(bidParams, auctionByToken, s);
    var operations : list(operation) := noOperations;

    if Tezos.amount =/= bidParams.bid then
      failwith("Not enough XTZ")
    else
      skip;

    if lastBid.bid > 0tez then block {
      const receiver : contract(unit) = case(Tezos.get_contract_opt(lastBid.user) : option(contract(unit))) of
      | Some(contract) -> contract
      | None -> (failwith("Invalid contract") : contract(unit))
      end;

      operations := Tezos.transaction(unit, lastBid.bid, receiver) # operations;
    } else
      skip;

    // TODO Add the new bid to the token`s auction
    // TODO Update auction in the storage
  } with (operations, s)

function claimToken(const tokenId : tokenId; var s : storage) : return is
  block {
    const auctionByToken : auction_params = case s.auctionByToken[tokenId] of
    | Some(v) -> v
    | None -> (failwith("No active auctions for this token") : auction_params)
    end;


  } with (noOperations, s)

function claimCoins(const tokenId : tokenId; var s : storage) : return is
  block {
    const auctionByToken : auction_params = case s.auctionByToken[tokenId] of
    | Some(v) -> v
    | None -> (failwith("No active auctions for this token") : auction_params)
    end;


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
  | ClaimToken(v) -> claimToken(v, s)
  | ClaimCoins(v) -> claimCoins(v, s)
  | SetAdmin(v) -> setAdmin(v, s)
  end
