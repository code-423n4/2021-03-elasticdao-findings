Team: PocoTiempo  
Members: Rajeev, Maurelian, Mariano Conti  
Ethereum Address: To be sent very soon by Maurelian  
   
# Findings:  

# BUG 1
## Summary  
Passing a zero address for controller by mistake will require redeployment of the contract.

## Risk Rating

Impact = High
Likelihood = Low
Risk/Severity = Medium (per OWASP)

## Vulnerability Details

The initialize() function in ElasticDAO.sol mistakenly uses a ‘||’ instead of ‘&&’ in the require statement: “_ecosystemModelAddress != address(0) || _controller != address(0)” which allows one of them to be zero but still let require to be successful.

## Impact

Passing a zero address for controller by mistake during initialization (allowed only once) will require redeployment of the contract to fix it because of the usage of onlyController modifier for critical contract functions.

## Proof of Concept

https://github.com/elasticdao/code-contests/blob/e643cce4bbec683765e3b9a1ab576542ac61000f/contests/02-elasticdao/contracts/core/ElasticDAO.sol#L112-L115

## Tools Used

Manual review.

## Recommended Mitigation Steps

Change ‘||’ to ‘&&’ in the require() statement.

# BUG 2
## Summary
No zero-address check for _summoners in initialize() of ElasticDAO.sol

## Risk Rating

Impact = High
Likelihood = Low
Risk = Medium (per OWASP)

## Vulnerability Details

There is no zero-address check for _summoners in initialize() which fails the stated requirement of "atleast one summoner to summon the DAO" if all the initialized summoners happen to be 0 by accident.

## Impact

Given that initialization is allowed only once, contract will have to be redeployed to fix this.

## Proof of Concept

https://github.com/elasticdao/code-contests/blob/e643cce4bbec683765e3b9a1ab576542ac61000f/contests/02-elasticdao/contracts/core/ElasticDAO.sol#L87-L130

## Tools Used

Manual review.

## Recommended Mitigation Steps

Add zero address check for  _summoners array of addresses.

# BUG 3

## Summary

Single-step setting/updating of controller role address may irreversibly lock out administrative access if incorrect address is mistakenly used.

## Risk Rating

Impact = High
Likelihood = Low
Risk = Medium (per OWASP)

## Vulnerability Details

The setController() function in ElasticDAO.sol updates controller role address in one-step. If an incorrect address is mistakenly used then future administrative access or recovering from this mistake is prevented because onlyController modifier is used for setController(), which requires msg.sender to be the incorrectly used controller address (for which private keys may not be available to sign transactions).

## Impact

Future administrative access or even recovering from this mistake is prevented. Contracts will have to be redeployed.

## Proof of Concept

https://github.com/elasticdao/code-contests/blob/e643cce4bbec683765e3b9a1ab576542ac61000f/contests/02-elasticdao/contracts/core/ElasticDAO.sol#L344-L357

## Tools Used

Manual review.

## Recommended Mitigation Steps

Use a two-step process where the old controller address first grants ownership in one transaction and a second transaction from the new controller address accepts ownership. A mistake in the first step can be recovered by granting again before the new controller address accepts ownership.

# BUG 4
## Summary

onlyDao modifier incorrectly considers the minter address along with the daoAddress.

## Risk Rating

Impact = High
Likelihood = High
Risk = Critical (per OWASP)

## Vulnerability Details

onlyDao modifier incorrectly considers the minter address along with the daoAddress giving minter address the ability to change its address (minter) and burner addresses in setMinter and setBurner functions respectively. This capability should only be with daoAddress.

## Impact

minter address can change its address (minter) and burner addresses in setMinter and setBurner functions that use onlyDAO modifer.

## Proof of Concept

https://github.com/elasticdao/code-contests/blob/e643cce4bbec683765e3b9a1ab576542ac61000f/contests/02-elasticdao/contracts/tokens/ElasticGovernanceToken.sol#L31-L34

## Tools Used

Manual review.

## Recommended Mitigation Steps

Remove “|| msg.sender == minter” from onlyDAO modifier.

# BUG 5
## Summary

Avoid Transaction-Order-Dependence race condition for governance token approve().

## Risk Rating

Impact = High
Likelihood = Medium
Risk = High (per OWASP)

## Vulnerability Details

While this vulnerability is recognized in the comment, it is still present in the code. This is the classic ERC20 approve() race condition where a malicious spender can double-spend allowance (old and new allowance) by front-running the owner’s approve() call that aims to change the allowance. 

## Impact

A malicious spender can double-spend allowance (old and new allowance) by front-running the owner’s approve() call that aims to change the allowance. 

## Proof of Concept

https://github.com/elasticdao/code-contests/blob/e643cce4bbec683765e3b9a1ab576542ac61000f/contests/02-elasticdao/contracts/tokens/ElasticGovernanceToken.sol#L100-L125

## Tools Used

Manual review.

## Recommended Mitigation Steps

Remove approve() given that the combination of increaseAllowance() and decreaseAllowance() can provide the same functionality.

# BUG 6
## Summary

Incorrect event parameters in `transferFrom()`

## Risk Rating

Impact = Medium
Likelihood = High
Risk = High (per OWASP)

## Vulnerability Details

The event should be
`emit Approval(from, msg.sender, _allowances[_from][msg.sender]);`
instead of
`emit Approval(msg.sender, _to, _allowances[_from][msg.sender]);`

because the event is emitted when `msg.sender != _from` as specified in the conditional.

## Impact

This incorrect event emission will negatively impact any off-chain tools monitoring these critical transfer events of the governance token.

## Proof of Concept

https://github.com/elasticdao/code-contests/blob/e643cce4bbec683765e3b9a1ab576542ac61000f/contests/02-elasticdao/contracts/tokens/ElasticGovernanceToken.sol#L436

## Tools Used

Manual review.

## Recommended Mitigation Steps

Change event to:
`emit Approval(from, msg.sender, _allowances[_from][msg.sender]);`

# BUG 7
## Summary

The operator should be `>=` instead of `>` in the check for `newAllowance` in `decreaseAllowance()`.

## Risk Rating

Impact = Medium
Likelihood = Medium
Risk = Medium (per OWASP)

## Vulnerability Details

The operator should be `>=` instead of `>` (see below) in the check for `newAllowance` in `decreaseAllowance()` because it is desirable to reduce the allowance to be `0`.

`require(newAllowance > 0, 'ElasticDAO: Allowance decrease less than 0');`

## Impact

Owner will not be able to reduce allowance of spender to zero. In the case of an exploited spender contract, the owner might try to decrease allowance to 0 and fail with this require reverting, which might open an opportunity for the malicious spender contract to spend/acquire owner funds. In the benign spender contract case, the owner might end up leaving dust allowance for the spender.

## Proof of Concept

https://github.com/elasticdao/code-contests/blob/e643cce4bbec683765e3b9a1ab576542ac61000f/contests/02-elasticdao/contracts/tokens/ElasticGovernanceToken.sol#L254

## Tools Used

Manual review.

## Recommended Mitigation Steps

Change to

`require(newAllowance >= 0, 'ElasticDAO: Allowance decrease less than 0');`

# BUG 8
## Summary

`wmul` of of two positive numbers can result in zero.

## Risk Rating

Impact = High
Likelihood = High
Risk = Critical (per OWASP)

## Vulnerability Details

ElasticMath functions wmul and wdiv for float values are inspired by https://github.com/dapphub/ds-math/blob/master/src/math.sol as noted in the code comment. But that contract has a critical issue as noted in their repository from Oct 2019: https://github.com/dapphub/ds-math/issues/13.

The critical error (as raised by the issue) is that the wmul multiplication of two positive numbers `a` and `b` can result in zero for every `a,b > 0` and `b < 5*10^17 / a`. For e.g., `wmul(1,1)` returns `0`.

## Impact

Given that wmul is used for all the critical math operations on the tokens, it can produce unexpected results when the operands a and b are positive integers because `wmul` will return `0`.

## Proof of Concept

https://github.com/elasticdao/code-contests/blob/e643cce4bbec683765e3b9a1ab576542ac61000f/contests/02-elasticdao/contracts/libraries/ElasticMath.sol#L138-L148

Extracting this function and testing in Remix confirms that `wmul(1,1)` returns `0`.

## Tools Used

Remix.

## Recommended Mitigation Steps

Revert `wmul` for such cases.

# BUG 9
## Summary

An attacker may (selectively) prevent others from joining the DAO by front-running and changing contract balance.

## Risk Rating

Impact = High
Likelihood = High
Risk = Critical (per OWASP)

## Vulnerability Details

An attacker may (selectively) prevent others from joining the DAO by front-running their join txs with a tx that increments the DAO contract balance (even by 1 wei). This works because the protocol expects the applying joinee to precisely know the contract ETH balance for their msg.value calculation sent in their join tx.

`if (deltaE != msg.value) {revert('ElasticDAO: Incorrect ETH amount’);}`

## Impact

An attacker may (selectively) prevent others from joining the DAO leading to a DoS. This may affect DAO governance in situations where the attacker is a member of the DAO and doesn’t want (specific) others to join for a certain duration (e.g. until voting closes) because the current DAO membership is suitable to the attacker’s proposals/votes. So the attacker keeps front-running join txs with ETH deposits (1 wei should suffice) to the contract.

## Proof of Concept

https://github.com/elasticdao/code-contests/blob/e643cce4bbec683765e3b9a1ab576542ac61000f/contests/02-elasticdao/contracts/core/ElasticDAO.sol#L242-L261

## Tools Used

Manual review.

## Recommended Mitigation Steps

Revert in `receive()` and `fallback()`.

# Gas Optimization 1
## Summary

The reentrancy guard implementation using toggling boolean values is expensive.

## Risk Rating

Impact = High

## Vulnerability Details

The reentrancy guard implementation using toggling boolean values is expensive as explained (see below comment) in OpenZeppelin’s ReentrancyGuard library:

```
// Booleans are more expensive than uint256 or any type that takes up a full
// word because each write operation emits an extra SLOAD to first read the
// slot's contents, replace the bits taken up by the boolean, and then write
// back. This is the compiler's defense against contract upgrades and
// pointer aliasing, and it cannot be disabled.
```

Also see reference: https://eips.ethereum.org/EIPS/eip-1283

## Impact

Given that the reentrancy guard modifier `preventReentry` is used extensively, the gas usage impact will be significant.

## Proof of Concept

https://github.com/elasticdao/code-contests/blob/e643cce4bbec683765e3b9a1ab576542ac61000f/contests/02-elasticdao/contracts/services/ReentryProtection.sol#L9-L26

## Tools Used

Manual review.

## Recommended Mitigation Steps

Use an implementation based on enum Mutex {UNUSED, OPEN, LOCKED} or OpenZeppelin’s optimized ReentrancyGuard library.

# Gas Optimization 2
## Summary

Redundant require()s.

## Risk Rating

Impact = Low

## Vulnerability Details

The require(msg.sender == deployer) check in initializeToken is redundant because onlyDeployer modifier already would have checked this.

The require(success) check in join() is redundant because tokenContract.mintShares always returns true.

## Impact

Gas usage.

## Proof of Concept

https://github.com/elasticdao/code-contests/blob/e643cce4bbec683765e3b9a1ab576542ac61000f/contests/02-elasticdao/contracts/core/ElasticDAO.sol#L159-L160

https://github.com/elasticdao/code-contests/blob/e643cce4bbec683765e3b9a1ab576542ac61000f/contests/02-elasticdao/contracts/core/ElasticDAO.sol#L274-L275

## Tools Used

Manual review.

## Recommended Mitigation Steps

Remove these require()s.

