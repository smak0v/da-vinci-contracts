#include "../partial/IAuction.ligo"

function getTokenTransferEntrypoint(const token : address) : contract(transfer_type) is
  case (Tezos.get_entrypoint_opt("%transfer", token) : option(contract(transfer_type))) of
  | Some(c) -> c
  | None -> (failwith("getTokenTransferEntrypoint not found") : contract(transfer_type))
  end;

function getAuctionsByUser(const user : address; const s : storage) : list(auctions_params) is
  block {
    const auctionsByUser : list(auctions_params) = case s.auctionsByUser[user] of
    | Some(lst) -> lst
    | None -> (list [] : list(auctions_params))
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

function submitForAuction(const token_params : submit_token_params; var s : storage) : return is
  block {
    const operations : list(operation) = list [getTokenTransferOperation(token_params.token, token_params.tokenId)];
    const bid : bid_params = record [
      user = Tezos.sender;
      bid = token_params.initialPrice;
      createdAt = Tezos.now;
    ];
    const auction : auctions_params = record [
      token_params = token_params;
      bids = list [bid];
      createdAt = Tezos.now;
    ];
    const token : token_params = record [
      token = token_params.token;
      tokenId = token_params.tokenId;
    ];
    var auctionsByUser := getAuctionsByUser(Tezos.sender, s);
    var tokensByUser := getTokensByUser(Tezos.sender, s);

    auctionsByUser := auction # auctionsByUser;
    tokensByUser := token # tokensByUser;
    s.auctions := auction # s.auctions;
    s.auctionsByUser[Tezos.sender] := auctionsByUser;
    s.tokensByUser[Tezos.sender] := tokensByUser;
  } with (operations, s)

function main(const action : actions; const s : storage) : return is
  case action of
  | SubmitForAuction(v) -> submitForAuction(v, s)
  end
