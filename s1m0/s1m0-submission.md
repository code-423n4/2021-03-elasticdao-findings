BUG 1

Summary

Anyone can set the numberOfTokenHolders for every token.

Risk Rating

2/3

Vulnerability Details

The vulnerability allows anyone to set the numberOfTokenHolders because the function updateNumberOfTokenHolder() doesn’t do any access control.

Impact

Right now numberOfTokenHolders doesn’t seem to be used for any contract logic.

The only impact would be to fake the numberOfTokenHolders.

Proof of Concept

See attachment.

Tools Used

Manual analysis.

Recommended Mitigation Steps

In the function updateNumberOfTokenHolder() check who called it.

e.g.

require(msg.sender == _record.uuid, ‘ElasticDAO: Unauthorized’);

Base on the fact that it’s called only from ElasticGovernanceToken.

 

BUG 2

Summary

The minter of ElasticGovernanceToken can set the minter and the burner.

Risk Rating

2

Vulnerability Details

The minter of ElasticGovernanceToken can set the minter and the burner because the modifier onlyDAO made a wrong check allowing also the minter to call the functions that only the DAO should call.

Impact

The minter can call setBurner() and setMinter() allowing whoever he wants to burn and mint token.

Proof of Concept

By being the minter call setBurner() with an address you want and then from that address call burn() or burnShares(). Same thing can be done with setMinter().

Tools Used

Manual analysis.

Recommended Mitigation Steps

Set the modifier onlyDAO to:

require(msg.sender == daoAddress, ‘ElasticDAO: Not Authorized’);

 

BUG 3

Summary

The collected fees by the ElasticDAOFactory could get lost.

Risk Rating

1

Vulnerability Details

The collectFees() function send all the ETH balance (the collected fees) to the feeAddress but the feeAddress could be the.

Impact

The collected fees could get sent to the address(0) and so lost.

Proof of Concept

After deploying some DAO with deployDAOAndToken() call collectFees() and the fees will be sent to the address(0).

Tools Used

Manual analysis.

Recommended Mitigation Steps

Two possible mitigation:

1 Set the feeAddress in the initialize() function by adding a 3rd parameter.

2 Check in the collectFees() that the feeAddress is initialized.

e.g. require(feeAddress != address(0), ‘ElasticDAO: Set the feeAddress’);

 

GAS 1

Summary

In the ElasticDAOFactory the storage variable deployedDAOAddresses and deployedDAOCount are set in the deployDAOAndToken() and then never used.

If these variables are just for “history” purpose is better to emit an event (as already you do).

Without setting these 2 variables the gas consumed by deployDAOAndToken() could be reduced by ~62558.

