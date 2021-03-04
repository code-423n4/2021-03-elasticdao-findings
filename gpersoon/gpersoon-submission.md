Handle: gpersoon
Team: -
Ethereum Address: 0x8e2A89fF2F45ed7f8C8506f846200D671e2f176f
Bio: Teacher blockchains at The Hague University of Applied Sciences in The Netherlands

# BUG 1
## Summary
 _allowances is not using the Eternal Storage pattern

## Risk Rating
1 (low)

## Vulnerability Details
 Most of the data is stored via the Eternal Storage pattern, however the _allowances mapping isn’t.

ElasticGovernanceToken.sol:
```
contract ElasticGovernanceToken is IElasticToken, ReentryProtection {

  mapping(address => mapping(address => uint256)) private _allowances;
```

## Impact
Unexpected situations might occur after upgrades. The probability of this a low.
See also the remark about the Eternal Storage Pattern versus the Proxy Pattern below.
 
## Tools Used
Remix

## Recommended Mitigation Steps
 Check whether it’s useful to also use the Eternal Storage pattern for _allowances. Or at least test the _allowances when testing contract upgrades.

# BUG 2
## Summary
Use of Safemath.sub is missing in the function join, call to ElasticMath.capitalDelta

## Risk Rating
1 (low)

## Vulnerability Details
A subtraction is made without using Safemath in the call to function ElasticMath.capitalDelta:

ElasticDAO.sol:
```
function join(uint256 _deltaLambda)
    uint256 capitalDelta =
      ElasticMath.capitalDelta(
        // the current totalBalance of the DAO is inclusive of msg.value,
        // capitalDelta is to be calculated without the msg.value
        address(this).balance - msg.value,
        tokenContract.totalSupply()
      );
```

## Impact
Although in practice this will not result in a negative value, this happens to be one of the more dangerous points because ETH is being handled here.

## Tools Used
Remix

## Recommended Mitigation Steps
Use Safemath.sub

# BUG 3
## Summary
Use of Safemath.div is missing in the function wdiv in ElasticMath.sol.

## Risk Rating
1 (low)

## Vulnerability Details
Two divisions are made without the use of Safemath.div, while in other locations the Safemath functions are used.

ElasticMath.sol:
```
function wdiv(uint256 a, uint256 b) internal pure returns (uint256) {
    return SafeMath.add(SafeMath.mul(a, 1000000000000000000), b / 2) / b;
  }
}
```

## Impact
The implementation of safemath div doesn’t check anything, so it doesn’t really matter, but it is not consistent. 

## Tools Used
Remix

## Recommended Mitigation Steps
Use safemath.div
Additionally it might be useful to show an error for divisions by 0.



# BUG 4
## Summary
Penalize is unnecessarily strict.

## Risk Rating
1 (low)

## Vulnerability Details

When calling the penalize function, you have to use an amount that is less than or equal the available lambda, otherwise the SafeMath.sub in updateBalance will fail and the transaction will revert.

ElasticDAO.sol:
```
function penalize(address[] memory _addresses, uint256[] memory _amounts)
    for (uint256 i = 0; i < _addresses.length; i += 1) {
      tokenContract.burnShares(_addresses[i], _amounts[i]);
    }
  }
ElasticGovernanceToken.sol
  function burnShares(address _account, uint256 _amount)
..
    _burnShares(_account, _amount);
 
function _burnShares(address _account, uint256 _deltaLambda) internal {
…
    tokenHolder = _updateBalance(tokenHolder, false, _deltaLambda);

 function _updateBalance(
..
      _tokenHolder.lambda = SafeMath.sub(_tokenHolder.lambda, _deltaLambda);
```

## Impact
If someone, who is about to be penalized, is able to front run this transaction with a call to the exit function, with only a tiny amount, then the penalize will fail. 

## Tools Used
Remix

## Recommended Mitigation Steps
If the lambda left for the tokenholder is less than the amount to be penalized for, penalize for the entire available lambda.


# Safe gas 1
The Eternal Storage pattern is not used in the way it is designed. According to https://fravoll.github.io/solidity-patterns/eternal_storage.html:
“A separate contract, with the sole purpose of acting as a storage to another contract, is introduced.”
However with ElasticDAO the contracts are derived from EternalModel and thus the EternalModel memory is integrated in the contract:
    • contract TokenHolder is EternalModel, ReentryProtection {
    • contract Token is EternalModel, ReentryProtection {
    • contract Ecosystem is EternalModel, ReentryProtection {
    • contract DAO is EternalModel, ReentryProtection {
You can also see the difference in the implementation of the EternalModel functions, they should be external to be callable from another contract:
ElasticDAO EternalModel.sol:
Fravoll EternalModel.sol:
function setUint(bytes32 _key, uint256 _value) internal {
    s.uIntStorage[_key] = _value;
  }
function setUint(bytes32 _key, uint _value) onlyLatestVersion external {
      uIntStorage[_key] = _value;
 }

Because the Proxy pattern is already used, the Eternal Storage pattern is not necessary and just complicates the source and uses a lot of gas.

## Recommendation:
Choose either the Proxy pattern or the Eternal Storage pattern.
Use the same chosen pattern for allowances (see bugs above).

# 6. Safe gas 2

The line  “require(newAllowance…” is only reached when 
_allowances[msg.sender][_spender] == _subtractedValue
In other error situations the execution is stopped already by Safemath:


ElasticGovernanceToken.sol:
  function decreaseAllowance(address _spender, uint256 _subtractedValue)
    external
    preventReentry
    returns (bool)
  {
    uint256 newAllowance = SafeMath.sub(_allowances[msg.sender][_spender], _subtractedValue);
    require(newAllowance > 0, 'ElasticDAO: Allowance decrease less than 0');
    _approve(msg.sender, _spender, newAllowance);
    return true;
  }

## Recommendation:
If this is meant to catch the 0 situation then adapt the error message.
If the 0 situation is not relevant the “require” line can be deleted and some comment should be added.

# 7. Safe gas 3

When you want to join the DAO and call the function “join”, you have to supply the exact amount of ETH to join, which changes frequently.
This could lead to a race condition, when several people try to join at the same time and the required amount has changed in the mean time. This way you would have to do multiple tries to join the DAO.

ElasticDAO.sol:
function join(uint256 _deltaLambda)
..
    uint256 deltaE =   ElasticMath.deltaE( ….
…
   if (deltaE != msg.value) {
      revert('ElasticDAO: Incorrect ETH amount');
    }

## Recommendation:
Allow to supply more ETH than necessary and return the superfluous amount.
