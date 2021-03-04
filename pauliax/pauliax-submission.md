**Handle:**  
paulius.eth  

**Ethereum Address:**  
0x523B5b2Cc58A818667C22c862930B141f85d49DD    

**Reported Bugs**
8  

**Gas Optimizations**  
11

# BUG 1  
function collectFees does not check that the feeAddress is set
## Summary  
function `collectFees` sends all the ether stored in the contract to the `feeAddress`. Until the `feeAddress` is set, all the funds go to `0x0` address (are burned).
## Risk Rating  
1
## Vulnerability Details  
Function `collectFees` does not check that the `feeAddress` is set (not `0x0`) before sending the ether. Until `updateFeeAddress` is invoked by the manager, `feeAddress` is an empty address so all the collected fees will be sent to this burn address. It depends on the intentions, maybe the initial idea is to burn some fees. However, the comment on the top of the contract says: "Collects a fee which is later used by ElasticDAO for further development of the project." so I assume these funds should go to the ElasticDAO controlled address.
## Impact  
Probably this scenario is very unlikely as the team should be prepared to invoke the `updateFeeAddress` as soon as the contract is deployed. Yet theoretically it leaves a gap that funds can be sent to the address the team does not control.

## Proof of Concept

https://github.com/code-423n4/code-contests/blob/4db2720312f0958f2e89f6207a6774c9e5360655/contests/02-elasticdao/contracts/core/ElasticDAOFactory.sol#L73-L79

https://github.com/code-423n4/code-contests/blob/4db2720312f0958f2e89f6207a6774c9e5360655/contests/02-elasticdao/contracts/core/ElasticDAOFactory.sol#L183-L188

## Tools Used
Just a simple code review using a text editor.

## Recommended Mitigation Steps
Either check that the `feeAddress` is not `0x0` in function `collectFees` or add the initialization of `feeAddress` in the function `initialize`.

# BUG 2   
modifier onlyDAO also allows minter
## Summary
modifier `onlyDAO` requires that the `msg.sender` is a `daoAddress` OR `minter` while the name suggests that it should only allow the daoAddress.
## Risk Rating
3
## Vulnerability Details
  ```
  solidity
  modifier onlyDAO() {
    require(msg.sender == daoAddress || msg.sender == minter, 'ElasticDAO: Not authorized');
    _;
  }
  ```
## Impact
This allows the minter to call functions that are supposed to be called only by DAO like `setBurner` or `setMinter`.
## Proof of Concept

https://github.com/code-423n4/code-contests/blob/4db2720312f0958f2e89f6207a6774c9e5360655/contests/02-elasticdao/contracts/tokens/ElasticGovernanceToken.sol#L31-L34

## Tools Used
Just a simple code review using a text editor.

## Recommended Mitigation Steps
Remove this condition: `|| msg.sender == minter`

# BUG 3
ElasticDAO function initialize does not ensure that the ecosystem model address is not zero

## Summary
function `initialize` in the contract ElasticDAO does not require that both `_ecosystemModelAddress` and `_controller` addresses are not empty.

## Risk Rating
1

## Vulnerability Details
There is a comment in the requirements: 

> "The ecosystem model address cannot be the zero address"

However, because the condition is `OR`, the code allows `_ecosystemModelAddress` to be `0x0` if the `_controller` is not `0x0`:
  ```
  solidity
    require(
      _ecosystemModelAddress != address(0) || _controller != address(0),
      'ElasticDAO: Address Zero'
    );
  ```
## Impact
When the `_ecosystemModelAddress` is `0x0` then the next line will fail and the function will revert:
  ```
  solidity
    Ecosystem(_ecosystemModelAddress).deserialize
  ```
When the `_controller` is `0x0`, then it will make the functions with `onlyController` modifier unusable. Such functions are `penalize`, `reward` and `setController`.  
  
However, in practice, I assume that DAOs will be created by ElasticDAOFactory (function `deployDAOAndToken`). It uses `ecosystemModelAddress` that is already checked against `0x0` and `msg.sender` as the controller so it should be fine.
## Proof of Concept

https://github.com/code-423n4/code-contests/blob/4db2720312f0958f2e89f6207a6774c9e5360655/contests/02-elasticdao/contracts/core/ElasticDAO.sol#L87-L115

## Tools Used
Just a simple code review using a text editor.
## Recommended Mitigation Steps
Replace the `OR` condition (`||`) with `AND` condition (`&&`).



# BUG 4   
function decreaseAllowance does not allow new allowances of 0
## Summary
`decreaseAllowance` requires that the new allowance is above `0` which makes it inconsistent with the comment and error message.

## Risk Rating
1
## Vulnerability Details
contract `ElasticGovernanceToken`, function `decreaseAllowance` has a comment:  
```
  * @dev Requirement:
  * Allowance cannot be lower than 0
```

and the code:
  ```
  solidity
    require(newAllowance > 0, 'ElasticDAO: Allowance decrease less than 0');
  ```
  
Both comment and error message indicates that the new allowance cannot be less than zero, yet the code also forbids the allowance of `0`. 
## Impact
In practice, this should not cause any issues as an allowance of 1 means just the smallest fraction of the token with decimals (e.g. in ethereum that has 18 decimals it's called wei) so it shouldn't make any difference. In theory, I think a standard approach is to allow decreasing allowance to the 0.
## Proof of Concept

https://github.com/code-423n4/code-contests/blob/4db2720312f0958f2e89f6207a6774c9e5360655/contests/02-elasticdao/contracts/tokens/ElasticGovernanceToken.sol#L236-L258

## Tools Used
Just a simple code review using a text editor.
## Recommended Mitigation Steps
There are 2 options:
  1) require that newAllowance >= 0 (which is probably useless as the SafeMath used above should already prevent that).
  2) update the comment and error msg to make it corresponding to the code that the new allowance must be greater than 0.

# BUG 5  
function updateNumberOfTokenHolders in the contract Token can be invoked by anyone
## Summary
`updateNumberOfTokenHolders` does not have any authorizations on the caller so anyone can set any arbitrary value of `numberOfTokenHolders` for any token they specify.
## Risk Rating
2
## Vulnerability Details
function `updateNumberOfTokenHolders` in the contract Token is invoked by function `_updateNumberOfTokenHolders` in contract `ElasticGovernanceToken`. However, updateNumberOfTokenHolders does not check who is the caller so it is possible for anyone to invoke it directly and set any value.

## Impact
This function is only used to update and later view the number of token holders so the funds are not at risk. In theory, there are some hypothetical scenarios, for example, someone sets `numberOfTokenHolders` to `MAX_UINT`, then the next time `_updateNumberOfTokenHolders` will try to increment this number, it will overflow and revert thus making the tx fail. Of course, then you need to manually set the correct value and the loop continues.
## Proof of Concept

https://github.com/code-423n4/code-contests/blob/dcde6b1d78d84d0165d2defd6e959d59ff8aba68/contests/02-elasticdao/contracts/models/Token.sol#L94-L99

## Tools Used
Just a simple code review using a text editor.

## Recommended Mitigation Steps
Add requirements for the caller similar to the ones that are present in the function serialize.



# BUG 6  
Inconsistent values for the Transfer event 
## Summary
function `_burnShares` emits `Transfer` event passing `_deltaLambda` as the amount transferred while the function `_mintShares` uses `deltaT`.
## Risk Rating
1
## Vulnerability Details
`_burnShares` emits the event that `_deltaLambda` was burned. `_mintShares` recalculates `deltaT` and uses that in the same event. So it is unclear if this event should emit the number of shares or the number of tokens minted/burned. Probably tokens as the third place where this event is emitted (function `_transfer`) uses tokens.
## Impact
No impact on the security, it could just make it harder for a frontend application to handle the values coming from these events.
## Proof of Concept

https://github.com/code-423n4/code-contests/blob/dcde6b1d78d84d0165d2defd6e959d59ff8aba68/contests/02-elasticdao/contracts/tokens/ElasticGovernanceToken.sol#L479

and

https://github.com/code-423n4/code-contests/blob/dcde6b1d78d84d0165d2defd6e959d59ff8aba68/contests/02-elasticdao/contracts/tokens/ElasticGovernanceToken.sol#L506

## Tools Used
Just a simple code review using a text editor.
## Recommended Mitigation Steps
Decide if you want to emit shares or number of tokens in the Transfer event and use it in all cases where this event is emitted.



# BUG 7  
Serialization can be invoked by anyone 
## Summary
A sophisticated hacker can trick access checks in model contracts to think that he is a legit sender. He can set arbitrary values to be serialized in the storage.
## Risk Rating
4
## Vulnerability Details
Model contracts `DAO`, `Ecosystem` and `Token` have the authorization checks in serialization function, however, these checks are not effective as the caller can pass any values inside the nested object. For instance, DAO contract has such an auth check:

```
  solidity
  require(
      msg.sender == _record.uuid || msg.sender == _record.ecosystem.configuratorAddress,
      'ElasticDAO: Unauthorized'
    );
```
The second part of the `OR` condition is useless as it is possible to pass a `_record` struct with a nested ecosystem struct that is built with your parameters and can trick the contract to think that you are the configurator.

## Impact
The impact is huge. The storage cannot be trusted as anyone can overwrite it. Without proper storage, it is impossible to use the ElasticDAO contracts as they heavily rely on this.  
## Proof of Concept
See the contract that I wrote and attached to this gist: `ExploitDaoSerialize.sol`

It is a simplified version demonstrating how a DAO model contract can be exploited. Open this file in Remix IDE (you can use something else if you have a preference). Compile and deploy DAO contract, then deploy the Attacker contract, specify the DAO contract address and a target address that can be any address for the testing purposes. Then invoke function deserialize on DOA contract passing the same target address and see that the data has been updated to the values set in the Attacker contract. Other model contracts can be exploited in a similar fashion.

## Tools Used
Remix IDE to play with the code and build the PoC attacker contract.
## Recommended Mitigation Steps
Do not trust any parameters sent from the outside. It needs to be refactored to take these parameters from a trusted source, for example, by creating some sort of whitelist.



# BUG 8  
DAO summoners serialization loop does not delete previous entries
## Summary
Contract DAO function serialize sets summoners in a for loop. It iterates over the list of summoners that was passed inside the struct parameter and sets the 'summoner' to true and its index.
## Risk Rating
1
## Vulnerability Details
In a hypothetical scenario when a list of summoners is updated and the new list is smaller than the previous one, all the remaining summoners are still considered active as the for loop iterates over this smaller list leaving all the excess elements untouched.
## Impact
There is no risk if we assume that the serialization can only be called by a trusted party and that the summoners are initialized only once and do not change. 
## Proof of Concept

https://github.com/code-423n4/code-contests/blob/dcde6b1d78d84d0165d2defd6e959d59ff8aba68/contests/02-elasticdao/contracts/models/DAO.sol#L91-L94

Here is a code snipet that can be used to test this:
  ```solidity
   address[] memory summoners = new address[](2);
   summoners[0] = 0x1111111111111111111111111111111111111111;
   summoners[1] = 0x2222222222222222222222222222222222222222;
   
   dao.summoners = summoners;
   daoStorage.serialize(dao);
   
   address[] memory summoners2 = new address[](1);
   summoners2[0] = 0x1111111111111111111111111111111111111111;
   
   dao.summoners = summoners2;
   daoStorage.serialize(dao);
  ```
After that if you invoke function isSummoner, you should see that both 0x1111111111111111111111111111111111111111 and 0x2222222222222222222222222222222222222222 return true although we expected to see only 0x1111111111111111111111111111111111111111.

## Tools Used
Remix IDE to play with the code and test the assumption.
## Recommended Mitigation Steps
It may be inefficient in gas but probably the most straightforward solution is before serializing new summoners iterate over the old summoners and remove them (set inactive). If the summoners are set only once and you believe this won't change, then it may be left as it is.

# Code style & notes:
* function updateFeeAddress, comment says "emits FeeUpdated event" but the actual event emitted is:  FeeAddressUpdated.
* function setMaxVotingLambda, the comment says "emits MaxVotingLambda event" but the actual event emitted is:  MaxVotingLambdaChanged.
* contract ElasticGovernanceToken functions _burnShares and _mintShares share a lot of common ground so might be useful to extract the common code to make it re-usable.
* function join, comment says "The amount of shares being purchased has to be lower than maxLambdaPurchase" but the code also allows the amount to be equal to maxLambdaPurchase so either the comment or the code needs to be updated to make it consistent.
* I think it would make sense to add access restrictions to the Configurator contract so that all the external functions could be invoked only by the ElasticDAO contract which I think is expected.
* It is unclear why the interface IElasticToken contains functions burn and burnShares but only contains mintShares, not mint.



# Gas optimizations:
* function initializeToken 2 times checks that the sender is a deployer:
  1) it has an onlyDeployer modifier in its declaration
  2) the first line of the function: 
  ```solidity
  require(msg.sender == deployer, 'ElasticDAO: Only deployer can initialize the Token'); 
  ```
* ElasticDAOFactory tracks deployedDAOCount in a separate variable. function deployDAOAndToken updates this value:
    ```solidity
    deployedDAOAddresses.push(daoAddress);
    deployedDAOCount = SafeMath.add(deployedDAOCount, 1);
    ```
It is an unecesary calculation and invocation of SafeMath library. You can get deployedDAOCount by making a view that returns deployedDAOAddresses.length:
  ```solidity
   function deployedDAOCount() external view returns (uint) {
       return deployedDAOAddresses.length;
    }
  ```
* contracts ElasticGovernanceToken and ElasticDAO imports both SafeMath and ElasticMath:
  ```solidity
  import '../libraries/SafeMath.sol';
  import '../libraries/ElasticMath.sol';
  ```
It is not necessary as ElasticMath already imports the SafeMath.
* Here it is not needed to check for return values as these functions always return true if complete without reverting:
    ```solidity
    bool success = tokenContract.setBurner(controller);
    require(success, 'ElasticDAO: Set Burner failed during setController');
    success = tokenContract.setMinter(controller);
    require(success, 'ElasticDAO: Set Minter failed during setController');
    ```
 * modifier onlyAfterTokenInitialized invokes _getEcosystem 2 times. You can re-use the ecosystem variable obtained in the first step.
 * It is unclear why DAO and Token model contracts have an unused parameter Ecosystem.Instance memory in function exists declaration. This parameter can be removed to save some gas.
  ```solidity
  function exists(address _uuid, Ecosystem.Instance memory) external view returns (bool) {
    return _exists(_uuid);
  }
  ```
* events MaxVotingLambdaChanged and ControllerChanged have a parameter 'bytes32 settingName' which I think is useless as the only place where these events are emitted are in function setMaxVotingLambda and function setController respectively.
* The only place where a SafeMath's function pow is used is here:
   ```solidity
    function revamp(uint256 elasticity) internal pure returns (uint256) {
      return SafeMath.add(elasticity, SafeMath.pow(10, 18));
    }
  ```
I don't see why this special pow function is needed in this case. SafeMath.pow(10, 18) can be replaced with 10**18 (or 1 ether) to save some gas as this is always constant and does not overflow.
* Some functions do not need preventReentry modifier as they do not call any contract or EOA. Removing this modifier would save some gas. Some examples from where I think preventReentry can be removed:
contract ElasticDAOFactory functions updateManager, updateFeeAddress, updateFee, updateElasticDAOImplementationAddress and many more.
* Serialization of models iterates over all the properties. This is inefficient in cases where only one property needs to be updated, for example, contract ElasticDAO function setMaxVotingLambda only updates maxVotingLambda.