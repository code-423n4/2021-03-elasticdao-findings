Please submit a report for all bugs you have encountered according to the following template. If you have found multiple bugs, title them numerically.

**Handle:** cmichel (Christoph Michel)
**Team:**
**Ethereum Address:** 0x6823636c2462cfdcD8d33fE53fBCD0EdbE2752ad
**Bio:** https://twitter.com/cmichelio

# Bug 1 Anyone can overwrite the DAO eternal storage model and steal funds

## Summary

Anyone can overwrite the eternal storage DAO model of an existing DAO and steal all tokens

## Risk Rating

4

## Vulnerability Details

The `models/DAO.sol` eternal storage contract identifies a specific DAO by a `uuid` (the address of the DAO) and uses the `serialize(Instance memory _record)` to store metadata about it.
This function can be called by an attacker who is free to choose the `_record` argument in a way to overwrite an existing DAO's storage while bypassing the authorization check of the function.

```solidity
require(
  msg.sender == _record.uuid || msg.sender == _record.ecosystem.configuratorAddress,
  'ElasticDAO: Unauthorized'
);
// continues to write to _record.uuid
```

The attacker chooses `_record.uuid` of an existing DAO but chooses the `_record.ecosystem.configuratorAddress` address to be the attacking sender address instead of the expected configurator address. This passes the check and allows the attacker to change the DAO data.

An attacker could, for example, set the `summoned` field to `false` again, and add themselves as the `summoner`:

```solidity
setBool(keccak256(abi.encode(_record.uuid, 'summoned')), _record.summoned);
setAddress(keccak256(abi.encode(_record.uuid, 'summoners', i)), _record.summoners[i]);
```

They can then mint themselves infinite tokens using `ElasticDAO.summon(uint256 _deltaLambda)` and dump them on the market, crashing the economics of the DAO.

## Impact

It will break all DAOs created by ElasticDAO.

## Proof of Concept

## Tools Used

## Recommended Mitigation Steps

Don't blindly trust the parameters to match the actual existing DAO data. The reason why the `msg.sender == _record.configurator` check exists is probably because of the initial `Configurator.buildDAO` call. It might be enough to allow the initial serialize call to succeed if the DAO with this `uuid` does not already exist. Otherwise, always enforce that `msg.sender == _record.uuid`. In this case, consider if it's possible for someone to precompute a DAO address and initialize the DAO eternal storage before its `configurator.buildDAO` call. It shouldn't be possible because the DAO Eternal Storage proxy is deployed in the same `DAO.initialize` call.

Alternatively, hardcode or store the real configurator address.

# Bug 2 - Anyone can overwrite the Ecosystem eternal storage model and steal funds

## Summary

Anyone can overwrite the eternal storage Ecosystem model of an existing DAO and steal all tokens

## Risk Rating

4

## Vulnerability Details

The `models/Ecosystem.sol` eternal storage contract identifies a specific DAO by its address and uses the `serialize(Instance memory _record)` to store ecosystem metadata about it.
This function can be called by an attacker who is free to choose the `_record` argument in a way to overwrite an existing DAO's ecosystem storage while bypassing the authorization check of the function.

```solidity
require(
  msg.sender == _record.daoAddress ||
    msg.sender == _record.configuratorAddress ||
    (_record.daoAddress == address(0) && !recordExists),
  'ElasticDAO: Unauthorized'
);
// continues to write to _record.daoAddress
```

The attacker chooses `_record.daoAddress` of an existing DAO but chooses the `_record.configuratorAddress` address to be the attacking sender address instead of the expected configurator address. This passes the check and allows the attacker to change the DAO ecosystem data.

An attacker could, for example, set the `daoModelAddress` field to an attacker-controlled proxy contract.

```solidity
setAddress(
  keccak256(abi.encode(_record.daoAddress, 'daoModelAddress')),
  _record.daoModelAddress
);
```

Having full control over the DAO's storage, the attacker can launch a similar attack to the one in bug 1:
They can then mint themselves infinite tokens using `ElasticDAO.summon(uint256 _deltaLambda)` and dump them on the market, crashing the economics of the DAO.

## Impact

It will break all DAOs created by ElasticDAO.

## Proof of Concept

## Tools Used

## Recommended Mitigation Steps

Instead of checking if `msg.sender == _record.configuratorAddress`, load the ecosystem at the `_record.daoAddress` and compare `msg.sender` to the already stored configurator address. This could still cause issues if the configurator address is compromised or found to have vulnerabilities. (see bug 4)

# Bug 3 - Anyone can overwrite the Token eternal storage model and steal funds

## Summary

Anyone can overwrite the eternal storage Token model of an existing DAO and steal all tokens

## Risk Rating

4

## Vulnerability Details

The `models/Token.sol` eternal storage contract identifies a specific governance token by a `uuid` (which is the token's address) and uses the `serialize(Instance memory _record)` to store token metadata about it.
This function can be called by an attacker who is free to choose the `_record` argument in a way to overwrite an existing DAO's token storage while bypassing the authorization check of the function.

```solidity
require(
  msg.sender == _record.uuid ||
    msg.sender == _record.ecosystem.daoAddress ||
    (msg.sender == _record.ecosystem.configuratorAddress && !_exists(_record.uuid)),
  'ElasticDAO: Unauthorized'
);
// continues to write to _record.uuid
```

The attacker chooses `_record.uuid` of an existing DAO's token address but chooses the `_record.daoAddress` address to be the attacking sender address instead of the expected DAO address. This passes the check and allows the attacker to change the DAO's token curve parameters.

An attacker could, for example, set the `k` value of the token curve parameters to a very high value.

```solidity
setUint(keccak256(abi.encode(_record.uuid, 'k')), _record.k);
```

This would lead to the attacker receiving much more ETH from the DAO in return for their shares (lambda) when calling `exit`, stealing all DAO funds. See `deltaE` on how the `k` value influences the ETH received per share.

## Impact

It will break all DAOs created by ElasticDAO.

## Proof of Concept

## Tools Used

## Recommended Mitigation Steps

Don't blindly trust the `_record.ecosystem` parameter structure to have the real ecosystem data.
Use similar mitigation techniques as in bug 2.

# Bug 4 - The configurator can be abused to overwrite the Ecosystem eternal storage model of any DAO

## Summary

Anyone can overwrite the eternal storage Ecosystem model of an existing DAO and steal all tokens using a bug in the Configurator contract code.

Notice that this is different from bug 2 as it uses a different attack vector, namely a bug in the Configurator.
The vulnerability still persists even if one patches the `msg.sender == _record.configuratorAddress` check in `models/Ecosystem.sol:serialize` to use the hard-coded configurator address.


## Risk Rating

4

## Vulnerability Details

The `services/Configurator.sol` configurator contract has a `buildToken` function that is callable by anyone without access restrictions and performs the following external call down the line:

```solidity
function buildToken(
  // ... first some params, we don't care about
  Ecosystem.Instance memory _ecosystem
) external returns (Token.Instance memory token) {
  // ...
  Ecosystem(_ecosystem.ecosystemModelAddress).serialize(_ecosystem);
}
```

The attacker can call the function with an `_ecosystem` parameter that uses a `_ecosystem.daoAddress` of an actual DAO. All other parameters can be chosen to be attacker-controlled.

The `Ecosystem.serialize` call now originates from the **configurator contract** and passes the `models/Token.sol:serialize` check (even if bug 2 is patched with a hardcoded configurator address).

Having arbitrary write access to the other fields of the DAO's ecosystem, the attacker can exploit the protocol. For example, setting `summoned` to `false`, adding themselves as a `summoner`, minting tokens using `ElasticDAO.summon(uint256 _deltaLambda)`.

## Impact

It will break all DAOs created by ElasticDAO.

## Proof of Concept

## Tools Used

## Recommended Mitigation Steps

The `Configurator.buildToken` function should not serialize the `Ecosystem` model, in addition to the `Token`. This is unexpected from the name and goes against the single responsibility principle.
It might not even be necessary to do so in the first place as `_ecosystem` did not change since reading it in `initializeToken`?


# Bug 5 - The `join` functionality can be broken

## Summary

An attacker can prevent users from joining a DAO.
The incentive could be to block new users from voting on a proposal.

## Risk Rating

4

## Vulnerability Details

The `ElasticDAO.join` function requires the **exact** amount of ETH (`msg.value`) to be sent for the desired shares:

```solidity
function join(uint256 _deltaLambda)
  external
  payable
  onlyAfterSummoning
  onlyWhenOpen
  preventReentry
{
  // ...
  if (deltaE != msg.value) {
    revert('ElasticDAO: Incorrect ETH amount');
  }
}
```

An attacker can observe the mempool for any `join` transactions and send a tiny amount of wei to the DAO contract. This changes the `capitalDelta` computation which, in return, changes the `deltaE` computation to a different value than the one calculated by a user at the time they tried to join the DAO.

```solidity
uint256 capitalDelta =
  ElasticMath.capitalDelta(
    // the current totalBalance of the DAO is inclusive of msg.value,
    // capitalDelta is to be calculated without the msg.value
    // CAN SEND TINY AMOUNT OF WEI AND CHANGE THIS
    address(this).balance - msg.value,
    tokenContract.totalSupply()
  );
uint256 deltaE =
  ElasticMath.deltaE(
    _deltaLambda,
    capitalDelta,
    token.k,
    token.elasticity,
    token.lambda,
    token.m
  );
```

This can also happen naturally from normal DAO usage whenever any of the token curve parameters change.

## Impact

Users can be blocked from joining a DAO.

## Proof of Concept

## Tools Used

## Recommended Mitigation Steps

Consider checking `msg.value >= deltaE` and sending back the remaining amount.
This is similar to a slippage parameter on AMMs.
This drastically increases the economic costs of such a `join` frontrunning attack.



# Bug 6 - Voting is broken due to max number of token votes and Sybil attacks

## Summary

Each DAO defines a max number of token votes a member has.
This immediately raises the question of how Sybil attacks are prevented.
The Elastic DAO addresses this as follows in [their FAQ](https://docs.elasticdao.org/start-with/faq#how-elasticdao-prevents-sybil-attacks):

> "Even tho it is not impossible for someone to make multiple accounts, ElasticDAO's join curve makes sybil attacks very expensive. When people join, they cannot purchase more than a DAO configured maximum number of tokens. The more addresses join the DAO, the more expensive it becomes. The net effect of a sybil attack would be enrichment of the existing DAO members. In an extreme case, those members could just leave and found a new DAO with the attacker's money."

We don't believe this to be correct. It's easy to circumvent the max vote restriction and launch a Sybil attack on the votes.

## Risk Rating

4

## Vulnerability Details

While it is true that joining a DAO makes the tokens more expensive, one must not need to buy tokens when joining the DAO.

Assume a DAO member has more tokens than the max voting amount.
They can create a second ETH account, call `ElasticDAO.join` on the DAO with a tiny `_deltaLambda` share (or even with a share of _zero_), essentially not buying new shares.

They then simply use the `ElasticGovernanceToken.transfer` function to transfer the shares from their main account to this second account, circumventing the price increase and the max vote restriction.

## Impact

The current voting is broken and a max voting amount of tokens is useless.

## Proof of Concept

## Tools Used

## Recommended Mitigation Steps

Preventing sybil attacks is very hard and there's no simple way to prevent it unless KYC on the DAO members is done, or another _proof of unique human_ protocol is used.
It might be best to just remove the max voting amount as it can easily be circumvented.
Alternatively, force new users to buy at least X ETH of shares when `join`ing the DAO. This does not prevent the attack, it only makes it economically more expensive for the attacker.



# Bug 7 - Penalties can be avoided by a bad-behaving DAO member

## Summary

ElasticDAO has the concept of penalties:

> The penalty rate is currently 10%. Unlike rewards, penalties apply to the entire balance of a wallet, ensuring that regardless of the free rider's balance.

These penalties can easily be avoided by simply transferring the tokens to a different account upon seeing the `ElasticDAO.penalize` function of the DAO.
This makes this penalty concept essentially useless

## Risk Rating

4

## Vulnerability Details

A DAO member that is about to be penalized, can see the `penalize` function either in the mempool, or, as this functionality is run through a DAO msig, in the DAO's pending msigs.
The member transfers their whole balance to a different address.
After the `penalize` function is included in a block, they can send it back to their original account.

They could also `exit` the DAO before they will be penalized.

## Impact

The current penalization system is easy to circumvent and therefore does not serve as any disincentive. This in return encourages bad behaviour by the DAO members.

## Proof of Concept

## Tools Used

## Recommended Mitigation Steps

Frontrunning such a function is hard to circumvent.
Have voters stake their share for a specific duration to be able to vote.
Additionally, it might be easier to come up with incentives for good behaviour instead of disincentives for bad behaviour.

# Bug 8 - Multi-Signature threshold from the specification is not enforced

## Summary

ElasticDAO states that a DAO's `controller` (which is also the `minter` and `burner`) is a multi-signature [account with 9 members](https://docs.elasticdao.org/start-with/fair-governance#fair-governance):

> "The votes are then ratified by a 9 member multisig."

There's no mention of 9 members, or even of any multi-signature concept, in the code.

## Risk Rating

2

## Vulnerability Details


## Impact

The founding ElasticDAO's functionality might be different than specified in their documentation, tricking possible investors.

## Proof of Concept

## Tools Used

## Recommended Mitigation Steps

Add proof that the `controller` is indeed a multi-signature account to the documentation.


# Bug 9 - Anyone can burn fees if no fee account is set up

## Summary

The `ElasticDAOFactory:collectFees` function sends fees to a `feeAddress` in storage.
There is no check if the `feeAddress` has been initialized.

## Risk Rating

3

## Vulnerability Details

The `feeAddress` is **not** initialized through the `inititialize` function, one needs to call `updateFeeAddress`. Therefore, it is easy to miss.

An attacker can call `collectFees` and if uninitialized, the fees will be sent to the zero address.
The tokens cannot be recovered from there anymore.

```solidity
function collectFees() external preventReentry {
  uint256 amount = address(this).balance;

  (bool success, ) = feeAddress.call{ value: amount }('');
  require(success, 'ElasticDAO: TransactionFailed');
  emit FeesCollected(address(feeAddress), amount);
}
```

## Impact

Fees from creating new DAOs are currently the main way for ElasticDAO to create revenue besides the token market.
This revenue can be burned by anyone if not careful.

## Proof of Concept

## Tools Used

## Recommended Mitigation Steps

Add a `require(feeAddress != 0)` check to `collectFees`.


# Bug 10 - Wrong logic check in `ElasticDAO.initialize`

## Summary

The `ElasticDAO.initialize` function has a check which passes when only one of `_ecosystemModelAddress` or `_controller` is non-zero.
The intention was probably to check that both are non-zero.



## Risk Rating

2

## Vulnerability Details

The `ElasticDAO.initialize` performs this check which passes when only one of `_ecosystemModelAddress` or `_controller` is non-zero.


```solidity
require(
  _ecosystemModelAddress != address(0) || _controller != address(0),
  'ElasticDAO: Address Zero'
);
```


## Impact

The `initialize` function can be called with the wrong parameters which break further functionality.
For example, the `controller` could be the zero address and the DAO is unable to change this parameter again.
The only option is to redeploy everything.

## Proof of Concept

## Tools Used

## Recommended Mitigation Steps

Use a logical **and** instead of an **or**:

```solidity
require(
  _ecosystemModelAddress != address(0) && _controller != address(0),
  'ElasticDAO: Address Zero'
);
```



# Bug 11 - A malicious summoner can break all token functionality by minting max tokens


## Summary

A summoner chooses the initial shares that each summoner receives using the `ElasticDAO.summon(uint256 _deltaLambda)` function.
A malicious summoner can mint a total number of shares that equals the maximum possible value of an unsigned integer.
This means minting any further shares would result in an overflow and the functions would fail.


## Risk Rating

2

## Vulnerability Details

The malicious summoner attacker chooses the `uint256 _deltaLambda` of shares to mint for each summoner as:

```solidity
uint256 _deltaLambda = type(uint256).max / dao.numberOfSummoners
```

This leads to a total share supply close to the maximum as each summoner receives this same amount.



## Impact

Any token related minting leads to an overflow and breaks the functionality.
This means nobody can join the DAO anymore.
The only option is to redeploy everything.

## Proof of Concept

## Tools Used

## Recommended Mitigation Steps

Don't let summoners choose the initial amount of shares each summoner receives.
This should be a parameter chosen during initialization, or could even be a predefined constant.



# Bug 12 - A malicious summoner can break all token functionality by calling `summon` before all other summoners deposited


## Summary

ElasticDAO allows summoners to provide some seed funding in exchange for initial shares using the `ElasticDAO.seedSummoning` function.
Once seed summoners have deposited, the DAO can be summoned using the `ElasticDAO.summon` function.

However, there's no way to know which summoners want to provide an initial seed summoning and for the contract to wait for all summoners to deposit. The DAO can be summoned as soon as it has a non-zero balance.

This can be abused by a summoner who is the first one to send ETH to the contract and immediately calls `summon` afterwards, before other summoners get the chance to provide seed summoning.


## Risk Rating

2

## Vulnerability Details

A malicious summoner is the first to send 1 wei to the `ElasticDAO` contract before any other summoner can call `ElasticDAO.seedSummoning` and receive their shares.
They then proceed to call `summon` which passes the `require(address(this).balance > 0);` check and distributes equal shares to all summoners.

There's no way for other summoners that were willing to provide seed funding to receive shares in exchange for their funds anymore, except through manually doing a `reward` msig transaction which is tedious.

## Impact
Willing seed summoners are prevented from receiving shares for their seed funding.
This leaves the DAO with less seed funding and will probably have to be redeployed.

## Proof of Concept

## Tools Used

## Recommended Mitigation Steps
Add a min amount of funds required to be able to call `summon`. This makes such an attack infeasible.
Also, make each summoner signal if they want to provide seed funds or not. Only if all summoners signalled their choice, allow `summon` to be called.

# Bug 13 - `TokenModel.serialize` is not the inverse of `TokenModel.deserialize`


## Summary

The `models/Token.sol:serialize` action does not serialize all fields which are deserialized by its `deserialize` function.
This might be unexpected behaviour.

## Risk Rating

1

## Vulnerability Details

The `serialize` function does not serialize the `numberOfTokenHolders` field, the `updateNumberOfTokenHolders` function is used for this field instead.
However, the `deserialize` function returns this field.
This does currently not lead to any vulnerabilities.

## Impact
Possible problems in the future when extending functionality.

## Proof of Concept

## Tools Used

## Recommended Mitigation Steps
Remove the `numberOfTokenHolders` field from being returned by the `deserialize` function to conform with the behaviour of `serialize`, which should be its inverse. Then, add a new `getNumberOfTokenHolders` function to retrieve it.

---

# Gas Optimizations

Here are several ways to improve the contracts' gas usage:

1. `ElasticDao.initializeToken` checks `msg.sender == deployer` again, but is already checked in `onlyDeployer` modifier.
2. `models/DAO.exists` has an unused second argument that is passed
3. `SafeMath.pow(10, 18)` in `ElasticMath.revamp` is a very expensive exponentiation that should be hardcoded to `1e18`.
4. `SafeMath.pow` in general is inefficient. Can use a more efficient [repeated squaring algorithm](https://en.wikipedia.org/wiki/Exponentiation_by_squaring), like [this one in the DSMath](https://github.com/dapphub/ds-math/blob/master/src/math.sol#L77).
5. `ElasticDAO.sol` stores the `summoners` in its storage, but only uses the summoners stored in the DAO eternal storage model. The `summoners` storage within the `ElasticDAO` is never read and can be removed to save gas.
6. Many of the `preventReentry` modifiers are not necessary on functions that only call trusted contracts and don't take any attacker-controlled arguments. These include: `ElasticDAO.initialize, initializeToken, exit, join, penalize, reward, setController, setMaxVotingLambda, seedSummoning, summon`. `ElasticDAOFactory.initialize, collectFees, deployDAOAndToken, updateElasticDAOImplementationAddress, updateFee, updateFeeAddress, updateManager`. As well as many of the `ElasticGovernanceToken` functions.
