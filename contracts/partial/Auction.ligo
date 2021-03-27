#include "../partial/IAuction.ligo"

function getTokenTransferEntrypoint(const token : address) : contract(transfer_type) is
  case (Tezos.get_entrypoint_opt("%transfer", token) : option(contract(transfer_type))) of
  | Some(c) -> c
  | None -> (failwith("getTokenTransferEntrypoint not found") : contract(transfer_type))
  end;

function getAuctionsByUser(const user : address; const s : storage) : set(auctionId) is
  block {
    const auctionsByUser : set(auctionId) = case s.auctionsByUser[user] of
    | Some(v) -> v
    | None -> (set [] : set(auctionId))
    end;
  } with auctionsByUser

function getTokensByUser(const user : address; const s : storage) : set(tokenId) is
  block {
    const tokensByUser : set(tokenId) = case s.tokensByUser[user] of
    | Some(v) -> v
    | None -> (set [] : set(tokenId))
    end;
  } with tokensByUser

function getTokenTransferOperation(const token : address; const tokenId : tokenId; const src : address; const dst : address) : operation is
  block {
    const transferDestination : transfer_destination = record [
      to_ = dst;
      token_id = tokenId;
      amount = 1n;
    ];
    const transferParam : transfer_param = record [
      from_ = src;
      txs = list [transferDestination];
    ];
    const op = Tezos.transaction(
      TransferType(list [transferParam]),
      0mutez,
      getTokenTransferEntrypoint(token)
    );
  } with op

function getAuctionIdByTokenId(const tokenId : tokenId; const s : storage) : auctionId is
  case s.auctionByToken[tokenId] of
  | Some(v) -> v
  | None -> 0n
  end;

function getAuctionByTokenId(const tokenId : tokenId; const s : storage) : auction_params is
  block {
    const auctionId : auctionId = getAuctionIdByTokenId(tokenId, s);
    const auction : auction_params = case s.auctions[auctionId] of
    | Some(v) -> v
    | None -> (failwith("No active auctions for this token") : auction_params)
    end;
  } with auction

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

function validateBid(const bidParams : make_bid_params; const auction : auction_params; const s : storage) : unit is
  block {
    if auction.createdAt + int(auction.tokenParams.lifetime) < Tezos.now then
      failwith("Auction is already finished")
    else
      skip;

    if bidParams.bid - auction.lastBid.bid < auction.tokenParams.minBidStep then
      failwith("Bid should be greater than min bid step")
    else
      skip;
  } with unit

function submitForAuction(const params : submit_token_params; var s : storage) : return is
  block {
    validateSubmition(params, s);

    const operations : list(operation) = list [getTokenTransferOperation(
      s.token,
      params.tokenId,
      Tezos.sender,
      Tezos.self_address
    )];
    const auction : auction_params = record [
      creator = Tezos.sender;
      tokenParams = params;
      lastBid = record [
        user = ("tz1ZZZZZZZZZZZZZZZZZZZZZZZZZZZZNkiRg" : address);
        bid = 0tez;
      ];
      createdAt = Tezos.now;
      finished = False;
    ];
    var auctionsByUser := getAuctionsByUser(Tezos.sender, s);
    var tokensByUser := getTokensByUser(Tezos.sender, s);

    s.lastAuctionId := s.lastAuctionId + 1n;
    auctionsByUser := Set.add(s.lastAuctionId, auctionsByUser);
    tokensByUser := Set.add(params.tokenId, tokensByUser);
    s.auctions[s.lastAuctionId] := auction;
    s.auctionByToken[params.tokenId] := s.lastAuctionId;
    s.auctionsByUser[Tezos.sender] := auctionsByUser;
    s.tokensByUser[Tezos.sender] := tokensByUser;
  } with (operations, s)

function makeBid(const bidParams : make_bid_params; var s : storage) : return is
  block {
    var auction : auction_params := getAuctionByTokenId(bidParams.tokenId, s);
    var operations : list(operation) := noOperations;

    validateBid(bidParams, auction, s);

    if Tezos.amount =/= bidParams.bid then
      failwith("Not enough XTZ")
    else
      skip;

    if auction.lastBid.bid > 0tez then block {
      const receiver : contract(unit) = case(Tezos.get_contract_opt(auction.lastBid.user) : option(contract(unit))) of
      | Some(contract) -> contract
      | None -> (failwith("Invalid contract") : contract(unit))
      end;

      operations := Tezos.transaction(unit, auction.lastBid.bid, receiver) # operations;
    } else
      skip;

    const auctionId = getAuctionIdByTokenId(bidParams.tokenId, s);

    auction.lastBid.user := Tezos.sender;
    auction.lastBid.bid := Tezos.amount;
    s.auctions[auctionId] := auction;
  } with (operations, s)

function claimToken(const tokenId : tokenId; var s : storage) : return is
  block {
    var auction : auction_params := getAuctionByTokenId(tokenId, s);
    var operations : list(operation) := noOperations;

    if auction.createdAt + int(auction.tokenParams.lifetime) > Tezos.now then
      failwith("Auction is not finished yet")
    else block {
      if auction.lastBid.bid <= 0tez then block {
        if Tezos.sender = auction.creator then
          operations := getTokenTransferOperation(s.token, tokenId, Tezos.self_address, auction.creator) # operations
        else
          failwith("Allowed only for creator");
      } else block {
        if Tezos.sender = auction.lastBid.user then
          operations := getTokenTransferOperation(s.token, tokenId, Tezos.self_address, auction.lastBid.user) # operations
        else
          failwith("Allowed only for last betman");
      };
      const auctionId = getAuctionIdByTokenId(tokenId, s);
      var auctionsByUser := getAuctionsByUser(auction.creator, s);
      var tokensByUser := getTokensByUser(auction.creator, s);

      auctionsByUser := Set.remove(auctionId, auctionsByUser);
      tokensByUser := Set.remove(tokenId, tokensByUser);
      auction.finished := True;
      s.auctions[auctionId] := auction;
      s.auctionByToken[tokenId] := 0n;
      s.auctionsByUser[auction.creator] := auctionsByUser;
      s.tokensByUser[auction.creator] := tokensByUser;
    }
  } with (operations, s)

function claimCoins(const tokenId : tokenId; var s : storage) : return is
  block {
    const auction : auction_params = getAuctionByTokenId(tokenId, s);
    var operations : list(operation) := noOperations;

    if auction.createdAt + int(auction.tokenParams.lifetime) > Tezos.now then
      failwith("Auction is not finished yet")
    else block {
      if Tezos.sender =/= auction.lastBid.user then
        failwith("Allowed only for last betman")
      else block {
        const receiver : contract(unit) = case(Tezos.get_contract_opt(auction.creator) : option(contract(unit))) of
        | Some(contract) -> contract
        | None -> (failwith("Invalid contract") : contract(unit))
        end;

        operations := Tezos.transaction(unit, auction.lastBid.bid, receiver) # operations;
      };
      const auctionId = getAuctionIdByTokenId(tokenId, s);
      var auctionsByUser := getAuctionsByUser(auction.creator, s);
      var tokensByUser := getTokensByUser(auction.creator, s);

      auctionsByUser := Set.remove(auctionId, auctionsByUser);
      tokensByUser := Set.remove(tokenId, tokensByUser);
      auction.finished := True;
      s.auctions[auctionId] := auction;
      s.auctionByToken[tokenId] := 0n;
      s.auctionsByUser[auction.creator] := auctionsByUser;
      s.tokensByUser[auction.creator] := tokensByUser;
    }
  } with (operations, s)

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
