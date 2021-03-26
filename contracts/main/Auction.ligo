#include "../partial/IAuction.ligo"

function submitForAuction(const s : storage) : return is
  block {
    skip;
  } with (noOperations, s)

function main(const action : actions; const s : storage) : return is
  case action of
  | SubmitForAuction(v) -> submitForAuction(s)
  end
