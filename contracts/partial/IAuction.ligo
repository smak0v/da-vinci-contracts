type storage is record [
    amount: nat;
]

type return is list(operation) * storage

type actions is
| SubmitForAuction of unit

[@inline] const noOperations : list(operation) = nil;
