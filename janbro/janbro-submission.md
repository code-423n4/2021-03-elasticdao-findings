**Handle:** janbro

**Ethereum Address:** 0xA2bA02db5c34B11C1Be0A25417851C9DfC5d4467

**Bio:** Smart contract bug hunter, occasional auditor, and developer.

# ISSUE 1
## Summary
`seedSummoning` function mints 10^18 more token than expected.

## Risk Rating
High

## Vulnerability Details
ElasticDAO.sol
Line 395: `uint256 deltaLambda = ElasticMath.wdiv(deltaE, token.eByL);`

The wdiv function multiplies the input amount by 10^8 to convert to wei precision, however, deltaE is already in wei value from `msg.sender`. This causes `ElasticGovernanceToken(token.uuid).mintShares(msg.sender, deltaLambda);` to mint 10^18 more tokens than expected as deltaE is expected to be in ETH in the contract logic.

## Impact
Seed summoners have much more influence and tokens in a DAO than expected.

## Proof of Concept
Call seedSummoning() as a summoner after initializing the token. 10^18 more tokens will be minted than expected

## Tools Used
Manual code review

## Recommended Mitigation Steps
Utilize a different division function which doesn't use the precision multiplier or renormalize the result before returning.


# ISSUE 2
## Summary
Utilize safe math

## Risk Rating
Note

## Vulnerability Details
ElasticDAO.sol
Line 246: `address(this).balance - msg.value,`

Safe math is not utilized which could lead to underflow if many users exit the DAO and leave an amount of ETH smaller than equivalent value of `token.maxLambdaPurchase`.

## Impact
capitalDelta would underflow to a large number and mint a large amount of tokens for msg.sender

## Proof of Concept
Users exit DAO
join when ETH balance of contract is smaller than equivalent value of token.macLambdaPurchase

## Tools Used
Manual code review

## Recommended Mitigation Steps
Utilize safe math
`SafeMath.sub(address(this).balance, msg.value),`


# ISSUE 3
## Summary
In periods of high demand, join will unexpectedly fail if the transaction follows other joins since the sent ether must exactly match the calculated value of the token.

## Risk Rating
Low

## Vulnerability Details
Effectively means in periods of high demand many join transactions will fail and in effect self DOS.

## Impact
Many users will not be able to join a DAO during periods of high activity.

## Proof of Concept
Call join with average gas price.
Join with higher gas price is executed before yours.
Your join call with fail since the amount of ETH sent will not match the _deltaLambda passed to purchase since the previous join has changed the calculated price value.

## Tools Used
Manual code review

## Recommended Mitigation Steps
Use a minLambdaExpected instead of exact amount

# ISSUE 4
## Summary 
seedSummoning mints the incorrect number of shares or the comment ETH/EbyL is incorrect. 

## Risk Rating
Low - Critical

## Vulnerability Details
Since the amount of eth is being divided the the eth per share the incorrect number of shares are being minted.

## Impact
Improper minting can result in system failure.