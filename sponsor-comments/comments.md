# Responses to warden submissions

## cmichel

### [Bug 1](https://github.com/code-423n4/contest-2-results/blob/main/cmichel/cmichel-submission.md#bug-1-anyone-can-overwrite-the-dao-eternal-storage-model-and-steal-funds)

Status: __Confirmed__, Resolved in [PR #43](https://github.com/elasticdao/contracts/pull/43)

#### Team Comments

This bug was an obvious oversight by us and a great catch. We have completely removed the Configurator.sol contract in order to make permissions simpler. It's functionality has been folded into [ElasticDAO.sol](https://github.com/elasticdao/contracts/blob/release/0.9.0/src/core/ElasticDAO.sol).

### [Bug 2](https://github.com/code-423n4/contest-2-results/blob/main/cmichel/cmichel-submission.md#bug-2---anyone-can-overwrite-the-ecosystem-eternal-storage-model-and-steal-funds)

Status: __Confirmed__, Resolved in [PR #43](https://github.com/elasticdao/contracts/pull/43)

#### Team Comments

This bug was an obvious oversight by us and a great catch. We have completely removed the Configurator.sol contract in order to make permissions simpler. It's functionality has been folded into [ElasticDAO.sol](https://github.com/elasticdao/contracts/blob/release/0.9.0/src/core/ElasticDAO.sol).

### [Bug 3](https://github.com/code-423n4/contest-2-results/blob/main/cmichel/cmichel-submission.md#bug-3---anyone-can-overwrite-the-token-eternal-storage-model-and-steal-funds)

Status: __Confirmed__, Resolved in [PR #43](https://github.com/elasticdao/contracts/pull/43)

#### Team Comments

This bug was an obvious oversight by us and a great catch. We have completely removed the Configurator.sol contract in order to make permissions simpler. It's functionality has been folded into [ElasticDAO.sol](https://github.com/elasticdao/contracts/blob/release/0.9.0/src/core/ElasticDAO.sol). Additionally, the DAO address has been added to the storage keys, so even if someone were to change that in Ecosystem, they would not be able to overwrite a record that they did not already own.

### [Bug 4](https://github.com/code-423n4/contest-2-results/blob/main/cmichel/cmichel-submission.md#bug-4---the-configurator-can-be-abused-to-overwrite-the-ecosystem-eternal-storage-model-of-any-dao)

Status: __Confirmed__, Resolved in [PR #43](https://github.com/elasticdao/contracts/pull/43)

#### Team Comments

The function in question is now internal to [ElasticDAO.sol](https://github.com/elasticdao/contracts/blob/release/0.9.0/src/core/ElasticDAO.sol) and can no longer be called by anyone who wishes to grief a DAO. The [Token.serialize call](https://github.com/elasticdao/contracts/pull/43/files#diff-4795938acc3b38e2194dd02ed180e833ac02fae999aee918a870e552f58d0020R81) has been moved to [ElasticGovernanceToken.initialize](https://github.com/elasticdao/contracts/pull/43/files#diff-4795938acc3b38e2194dd02ed180e833ac02fae999aee918a870e552f58d0020R81) which contains a guard to ensure it has not already been initialized.

### [Bug 5](https://github.com/code-423n4/contest-2-results/blob/main/cmichel/cmichel-submission.md#bug-5---the-join-functionality-can-be-broken)

Status: __Confirmed__, Resolved in [PR #59](https://github.com/elasticdao/contracts/pull/59)

#### Team Comments

As recommended, we have allowed for an excess of ETH to be sent to the join function. Any unused ETH is sent back to the sender.

### [Bug 6](https://github.com/code-423n4/contest-2-results/blob/main/cmichel/cmichel-submission.md#bug-6---voting-is-broken-due-to-max-number-of-token-votes-and-sybil-attacks)

Status: __Disputed__, Partially addressed in [PR #59](https://github.com/elasticdao/contracts/pull/59)

#### Team Comments

We agree with the recommended mitigation steps and did implement them, however, we did this because we feel that doing so simplifies the user experience, not because we agree with the bug report.

The warden suggest that voting in our system is fundamentally broken due to the potential for sybil attack. This is addressed in our documentation, as the warden points out. We do not view this potential as a vulnerability, but rather as a strength of the protocol.

The impact of purchasing EGT on the public market would be to increase the price of the token on the AMM. At the point where the AMM price exceeds the cost of purchasing another set of EGT (lambda), arbitrage bots would mint the tokens via the [ElasticDAO.join](https://github.com/elasticdao/contracts/blob/release/0.9.0/src/core/ElasticDAO.sol#L219) function. This would result in the same dynamic as the attacker minting the tokens themselves. The scenario described by the warden, where the attacker mints a small number of tokens, is not even necessary. Indeed, the attacker could simply transfer from their main account to a secondary before the vote without minting new tokens in this new account. 

Regardless of which approach is taken, successfully sybil attacking the network, would necessitate the minting of new shares such that the attacker controls a majority of the voting power. This would result is a substantial increase of the backing value of each existing member's tokens. Those members could then take that attacker's money via the [ElasticDAO.exit](https://github.com/elasticdao/contracts/blob/release/0.9.0/src/core/ElasticDAO.sol#L187) function and start a new DAO.

The warden states `The current voting is broken and a max voting amount of tokens is useless.` We disagree in the strongest possible terms. If financial disincentives to sybil attacking a network do not constitute protection, Ethereum and every other Proof of Work blockchain are likewise broken, rendering their consensus mechanism `useless`.

### [Bug 7](https://github.com/code-423n4/contest-2-results/blob/main/cmichel/cmichel-submission.md#bug-7---penalties-can-be-avoided-by-a-bad-behaving-dao-member)

Status: __Confirmed__, Resolved in [PR #44](https://github.com/elasticdao/contracts/pull/44)

#### Team Comments

The purpose of the functionality in question is not to disincentivize bad behaviour, but to remove free riders in scenarios where their lack of participation is preventing the DAO from successfully reaching quorum.

While we are unable to prevent a wallet from transferring their tokens before penalties happen, we are able to fire an event in these cases and manually review. In extreme cases, we could pause the token functionality and burn their tokens unless said tokens have been sold. If those tokens are sold, the desired effect of the penalize function has been realized.

Further note: we do have incentives for good behaviour via the reward function

### [Bug 8](https://github.com/code-423n4/contest-2-results/blob/main/cmichel/cmichel-submission.md#bug-8---multi-signature-threshold-from-the-specification-is-not-enforced)

Status: __Disputed__

The documentation is a set of living documents. They, like all project documentation, are subject to change. The [controller address in ElasticDAO.sol](https://github.com/elasticdao/contracts/blob/release/0.9.0/src/core/ElasticDAO.sol#L24) is designed to be a multisig. We currently envision that to be a 9 member multisig, but that may change leading into launch, at which point the documentation will be updated. Should there ever be a discrepency between the documentation and the actual address stored as the controller, an investor only has to look at the contract on etherscan to see that we are `tricking possible investors`. Looking at the code on etherscan would be the only way to verify that the contracts themselves enforced this 9 member requirement, so looking at the code of the controller address is not any more difficult. Should this controller ever be changed, the [ControllerChanged event would be fired](https://github.com/elasticdao/contracts/blob/release/0.9.0/src/core/ElasticDAO.sol#L24), providing investors with the chance to actively monitor changes and notice any trickery. All of this also ignores the long term financial disincentive involved in tricking potential investors.

Even if the approach described above is not trustless for the warden, the scope of this contest was the code, not the documentation.

### [Bug 9](https://github.com/code-423n4/contest-2-results/blob/main/cmichel/cmichel-submission.md#bug-9---anyone-can-burn-fees-if-no-fee-account-is-set-up)

Status: __Confirmed__, Resolved in [PR #42](https://github.com/elasticdao/contracts/pull/42)

#### Team Comments

This is a good note and a simple fix to prevent a dumb mistake from costing us money. Thanks!

### [Bug 10](https://github.com/code-423n4/contest-2-results/blob/main/cmichel/cmichel-submission.md#bug-10---wrong-logic-check-in-elasticdaoinitialize)

Status: __Confirmed__, Resolved in [PR #47](https://github.com/elasticdao/contracts/pull/47/files#diff-b01d843824b5d557c2914b0f42fdf4ef84315a85723a9640b7040ec8c29f2cefR115)

#### Team Comments

Good catch. Fixed and tested.

### [Bug 11](https://github.com/code-423n4/contest-2-results/blob/main/cmichel/cmichel-submission.md#bug-11---a-malicious-summoner-can-break-all-token-functionality-by-minting-max-tokens)

Status: __Acknowledged__

#### Team Comments

Summoners are considered to be coordinating, trusted entities. We do not consider it to be a bug that needs fixing, despite being technically accurate.

### [Bug #12](https://github.com/code-423n4/contest-2-results/blob/main/cmichel/cmichel-submission.md#bug-12---a-malicious-summoner-can-break-all-token-functionality-by-calling-summon-before-all-other-summoners-deposited)

Status: __Acknowledged__

#### Team Comments

Summoners are considered to be coordinating, trusted entities. We do not consider it to be a bug that needs fixing, despite being technically accurate.

### [Bug #13](https://github.com/code-423n4/contest-2-results/blob/main/cmichel/cmichel-submission.md#bug-13---tokenmodelserialize-is-not-the-inverse-of-tokenmodeldeserialize)

Status: __Acknowledged__

#### Team Comments

We do not view this as an issue. It may be considered by some to be bad practice, but it improves gas efficiency in our case.

### [Gas Optimizations](https://github.com/code-423n4/contest-2-results/blob/main/cmichel/cmichel-submission.md#gas-optimizations)

1. __Confirmed__, Resolved in [PR #56](https://github.com/elasticdao/contracts/pull/56)
2. __Confirmed__, Resolved in [PR #57](https://github.com/elasticdao/contracts/pull/57/files#diff-1709c87ddebd85edd32f6037fe7c58c1c0d02f49e8f4470470942cbe8134389bR56)
3. __Confirmed__, Resolved in [PR #58](https://github.com/elasticdao/contracts/pull/58)
4. __Confirmed__, Resolved in [PR #58](https://github.com/elasticdao/contracts/pull/58) by removing the function entirely
5. __Acknowledged__, This is for convenience on the frontend. The one time gas cost replaces repeated `O(n)` calls to the node with a single call (`O(1)`).
6. __Acknowledged__, We believe that the safety provided by additional, arguably unneccesary, calls to preventReentry justify the extra gas spent.

## gpersoon

### [Bug 1](https://github.com/code-423n4/contest-2-results/blob/main/gpersoon/gpersoon-submission.md#bug-1)

Status: __Acknowledged__

#### Team Comments

This choice was made primarily for gas reasons. The worst case scenario, a full loss of allowance data, is that every wallet needs to re-approve the spending of their tokens.

### [Bug 2](https://github.com/code-423n4/contest-2-results/blob/main/gpersoon/gpersoon-submission.md#bug-2)

Status: __Confirmed__, Resolved in [PR #48](https://github.com/elasticdao/contracts/pull/48)

#### Team Comments

Great catch. Thanks!

### [Bug 3](https://github.com/code-423n4/contest-2-results/blob/main/gpersoon/gpersoon-submission.md#bug-3)

Status: __Confirmed__, Resolved in [PR #46](https://github.com/elasticdao/contracts/pull/46)

#### Team Comments

Agreed. Consistency is better here, despite it's minimal impact.

### [Bug 4](https://github.com/code-423n4/contest-2-results/blob/main/gpersoon/gpersoon-submission.md#bug-4)

Status: __Confirmed__, Resolved in [PR #44](https://github.com/elasticdao/contracts/pull/44)

#### Team Comments

Good note. We've made the change to penalize with the value passed or their full balance, whichever is less.

### [Safe Gas 1](https://github.com/code-423n4/contest-2-results/blob/main/gpersoon/gpersoon-submission.md#safe-gas-1)

Status: __Disputed__

#### Team Comments

The warden states that `The Eternal Storage pattern is not used in the way it is designed.` We use the original pattern, and simply add an struct abstraction layer on top to mitigate stack overflow errors in other functions. Doing it this way also saves gas, as a call to an external function is expensive, and multiple calls for a set of data is drastically more expensive. This is also the reason for having the EternalModel functions be internal, rather than external as described in the spec. ElasticModel derived contracts are purpose built and used `with the sole purpose of acting as a storage to another contract`.

The warden further states `Because the Proxy pattern is already used, the Eternal Storage pattern is not necessary and just complicates the source and uses a lot of gas.` We disagree. Using the EternalModel pattern makes the underlying storage data directly available to external callers. It also allows us to upgrade the structs in the future with no negative impact on the underlying data, as with other standards like Diamond, or with the scenario where a struct is stored directly on the contract. With other patterns, changing the order of the struct keys or removing a key bricks the contract. With the EternalModel pattern, this is not the case. The additional gas costs of the pattern are noticable, but relatively small compared to the safety and data accessibility features they provide.

### [Safe Gas 2](https://github.com/code-423n4/contest-2-results/blob/main/gpersoon/gpersoon-submission.md#6-safe-gas-2)

Status: __Confirmed__, Resolved in [PR #81](https://github.com/elasticdao/contracts/pull/81)

#### Team Comments

Good catch.

### [Safe Gas 3](https://github.com/code-423n4/contest-2-results/blob/main/gpersoon/gpersoon-submission.md#7-safe-gas-3)

Status: __Confirmed__, Resolved in [PR #59](https://github.com/elasticdao/contracts/pull/59)

#### Team Comments

To the judges, we think this should count as a full bug, not a gas improvement. It is functionally the same as: https://github.com/code-423n4/contest-2-results/blob/main/sponsor-comments/comments.md#bug-5

## janbro

### [Issue 1](https://github.com/code-423n4/contest-2-results/blob/main/janbro/janbro-submission.md#issue-1)

Status: __Disputed__

#### Team Comments

This does not bear out if you actually call the contracts. Unable to reproduce and every bit of testing we've done contradicts this report.

### [Issue 2](https://github.com/code-423n4/contest-2-results/blob/main/janbro/janbro-submission.md#issue-2)

Status: __Confirmed__, Resolved in [PR #48](https://github.com/elasticdao/contracts/pull/48)

#### Team Comments

Great catch. Thanks!

### [Issue 3](https://github.com/code-423n4/contest-2-results/blob/main/janbro/janbro-submission.md#issue-3)

Status: __Confirmed__, Resolved in [PR #59](https://github.com/elasticdao/contracts/pull/59)

#### Team Comments

For the judges, the suggested fix is not valid, but the issue is. Both of the previous submitters also flagged this.

### [Issue 4](https://github.com/code-423n4/contest-2-results/blob/main/janbro/janbro-submission.md#issue-4)

Status: __Disputed__

### Team Comments

The referenced functionality is performing as expected. It's possible that the warden did not understand intent, but the report is incorrect.

## ncitron

### [Bug 1](https://github.com/code-423n4/contest-2-results/blob/main/ncitron/ncitron-submission.md#bug-1)

Status: __Confirmed__, Resolved in [PR #59](https://github.com/elasticdao/contracts/pull/59)

#### Team Comments

Same as other reports. Definitely worth fixing.

## pauliax

### [Bug 1](https://github.com/code-423n4/contest-2-results/blob/main/pauliax/pauliax-submission.md#bug-1)

Status: __Confirmed__, Resolved in [PR #42](https://github.com/elasticdao/contracts/pull/42)

#### Team Comments

This is a good note and a simple fix to prevent a dumb mistake from costing us money. Thanks!

### [Bug 2](https://github.com/code-423n4/contest-2-results/blob/main/pauliax/pauliax-submission.md#bug-2)

Status: __Confirmed__, Resolved in [PR #54](https://github.com/elasticdao/contracts/pull/54)

#### Team Comments

Good catch. Copy / paste error on our part.

### [Bug 3](https://github.com/code-423n4/contest-2-results/blob/main/pauliax/pauliax-submission.md#bug-3)

Status: __Confirmed__, Resolved in [PR #47](https://github.com/elasticdao/contracts/pull/47/files#diff-b01d843824b5d557c2914b0f42fdf4ef84315a85723a9640b7040ec8c29f2cefR115)

#### Team Comments

Good catch. Fixed and tested.

### [Bug 4](https://github.com/code-423n4/contest-2-results/blob/main/pauliax/pauliax-submission.md#bug-4)

Status: __Confirmed__, Resolved in [PR #60](https://github.com/elasticdao/contracts/pull/60) and then removed entirely in [PR #81](https://github.com/elasticdao/contracts/pull/81)

#### Team Comments

Good catch. The statement was unnecessary and not matching our language.

### [Bug 5](https://github.com/code-423n4/contest-2-results/blob/main/pauliax/pauliax-submission.md#bug-5)

Status: __Confirmed__, Resolved in [PR #53](https://github.com/elasticdao/contracts/pull/53)

#### Team Comments

Another obvious oversight on our part. Great catch.

### [Bug 6](https://github.com/code-423n4/contest-2-results/blob/main/pauliax/pauliax-submission.md#bug-6)

Status: __Confirmed__, Resolved in [PR #52](https://github.com/elasticdao/contracts/pull/52)

#### Team Comments

Good catch. Regardless of the way we're decreasing the token balance, we should return the event data in terms of the token balance itself.

### [Bug 7](https://github.com/code-423n4/contest-2-results/blob/main/pauliax/pauliax-submission.md#bug-7)

Status: __Confirmed__, Resolved in [PR #43](https://github.com/elasticdao/contracts/pull/43)

#### Team Comments

This bug was an obvious oversight by us and a great catch. We have completely removed the Configurator.sol contract in order to make permissions simpler. It's functionality has been folded into [ElasticDAO.sol](https://github.com/elasticdao/contracts/blob/release/0.9.0/src/core/ElasticDAO.sol).

Note to the judges, cmichel has this as 3 bugs. pauliax's submission should count 3 times, or cmichel's should count once.

### [Bug 8](https://github.com/code-423n4/contest-2-results/blob/main/pauliax/pauliax-submission.md#bug-8)

Status: __Acknowledged__

#### Team Comments

This should not be an issue, as summoners are only set before the DAO is summoned. Additionally, the summoners have no special case or reason for existance after summoning.

### [Code style & notes](https://github.com/code-423n4/contest-2-results/blob/main/pauliax/pauliax-submission.md#code-style--notes)

- __Confirmed__, fixed in [PR #68](https://github.com/elasticdao/contracts/pull/68)
- __Confirmed__, fixed in [PR #70](https://github.com/elasticdao/contracts/pull/70)
- __Acknowledged__, in this case we're going to keep them seperate to save on execution gas costs
- __Confirmed__, fixed in [PR #73](https://github.com/elasticdao/contracts/pull/73)
- __Confirmed__, instead we've removed the Configurator contract entirely
- __Confirmed__, fixed in [PR #83](https://github.com/elasticdao/contracts/pull/83)

### [Gas optimizations](https://github.com/code-423n4/contest-2-results/blob/main/pauliax/pauliax-submission.md#gas-optimizations)

- __Confirmed__, fixed in [PR #56](https://github.com/elasticdao/contracts/pull/56)
- __Confirmed__, fixed in [PR #51](https://github.com/elasticdao/contracts/pull/51)
- __Confirmed__, fixed in [PR #50](https://github.com/elasticdao/contracts/pull/50)
- __Acknowledged__, we like the additional safety of the checks. Gas costs are less important as this function is called infrequently.
- __Confirmed__, fixed in [PR #76](https://github.com/elasticdao/contracts/pull/76)
- __Confirmed__, fixed in [PR #57](https://github.com/elasticdao/contracts/pull/57)
- __Confirmed__, fixed in [PR #85](https://github.com/elasticdao/contracts/pull/85)
- __Confirmed__, fixed in [PR #58](https://github.com/elasticdao/contracts/pull/58)
- __Acknowledged__, We believe that the safety provided by additional, arguably unneccesary, calls to preventReentry justify the extra gas spent.
- __Acknowledged__, this is the case in a few instances, but the gas cost is not large enough to justify the extra function(s)

## pocoTiempo

### [Bug 1](https://github.com/code-423n4/contest-2-results/blob/main/pocoTiempo/pocoTiempo-submission.md#bug-1)

Status: __Confirmed__, fixed in [PR #47](https://github.com/elasticdao/contracts/pull/47/files#diff-b01d843824b5d557c2914b0f42fdf4ef84315a85723a9640b7040ec8c29f2cefR115)

#### Team Comments

Good catch. Thanks!

### [Bug 2](https://github.com/code-423n4/contest-2-results/blob/main/pocoTiempo/pocoTiempo-submission.md#bug-2)

Status: __Confirmed__, fixed in [PR #78](https://github.com/elasticdao/contracts/pull/78)

#### Team Comments

Unlikely issue, and wouldn't really bork anything serious, but good check to add. Thanks.

### [Bug 3](https://github.com/code-423n4/contest-2-results/blob/main/pocoTiempo/pocoTiempo-submission.md#bug-3)

Status: __Acknowledged__

#### Team Comments

The vulnerability is correct, however, the impact is incorrect. Because we deploy with proxies, in a worst case scenario, the proxy implementation could be upgraded to fix this issue.

### [Bug 4](https://github.com/code-423n4/contest-2-results/blob/main/pocoTiempo/pocoTiempo-submission.md#bug-4)

Status: __Confirmed__, fixed in [PR #54](https://github.com/elasticdao/contracts/pull/54)

#### Team Comments

Good spot. Thanks.

### [Bug 5](https://github.com/code-423n4/contest-2-results/blob/main/pocoTiempo/pocoTiempo-submission.md#bug-5)

Status: __Acknowledged__

#### Team Comments

This issue is present in most ERC20 tokens and very few choose to take the recommended mitigation step. We've choosen to go with expected behaviour instead of removing a function that is part of the spec.

### [Bug 6](https://github.com/code-423n4/contest-2-results/blob/main/pocoTiempo/pocoTiempo-submission.md#bug-6)

Status: __Confirmed__, fixed in [PR #77](https://github.com/elasticdao/contracts/pull/77)

#### Team Comments

Good catch. Thank you.

### [Bug 7](https://github.com/code-423n4/contest-2-results/blob/main/pocoTiempo/pocoTiempo-submission.md#bug-7)

Status: __Confirmed__, fixed in [PR #60](https://github.com/elasticdao/contracts/pull/60/files)

#### Team Comments

We also completely removed this check in [PR #81](https://github.com/elasticdao/contracts/pull/81) since SafeMath already guards against this issue.

### [Bug 8](https://github.com/code-423n4/contest-2-results/blob/main/pocoTiempo/pocoTiempo-submission.md#bug-8)

Status: __Disputed__

#### Team Comments

This would have been a very large issue indeed. Fortunately, the bug report was actually incorrect. We spent 2 days on this issue and engaged several outside maths experts to review our findings. We also reached out to the original team who developed the function and got them involved. They have closed the issue. The example provided by the wardens here would result in a legit `0` value as `wmul(1, 1)` is equivalent to `0.000000000000000001 * 0.000000000000000001`. The resulting value is far less than the minimum supported value in solidity and correctly rounds to `0`. Accordingly, we do not feel as though treating this as an error state makes sense. More detail is now available on the original issue, and in this gist (https://gist.github.com/smalldutta/51a9836b223277f1595467ad81f27737), compiled by our math guy, @smalldutta.

### [Bug 9](https://github.com/code-423n4/contest-2-results/blob/main/pocoTiempo/pocoTiempo-submission.md#bug-9)

Status: __Confirmed__, fixed in [PR #59](https://github.com/elasticdao/contracts/pull/59/files#diff-b01d843824b5d557c2914b0f42fdf4ef84315a85723a9640b7040ec8c29f2cefR241)

#### Team Comments

Good catch here. This issue had a number of impacts and has now been resolved by allowing a user to pass more ETH than needed with the call.

### [Gas Optimization 1](https://github.com/code-423n4/contest-2-results/blob/main/pocoTiempo/pocoTiempo-submission.md#gas-optimization-1)

Status: __Confirmed__, fixed in [PR #69](https://github.com/elasticdao/contracts/issues/69)

#### Team Comments

We actually had another reviewer suggest that this was no longer the case. We created simple contracts to test which was more expensive, and the OZ version saves ~1800 gas, which is non-trivial when considering the number of times this guard is used.

### [Gas Optimization 2](https://github.com/code-423n4/contest-2-results/blob/main/pocoTiempo/pocoTiempo-submission.md#gas-optimization-2)

Status: __Confirmed__, partially fixed in [PR #56](https://github.com/elasticdao/contracts/pull/56)

#### Team Comments

We fixed the first instance, but decided not to change the second. Our reasoning is that the IElasticToken interface specifies a boolean return and an alternate implementation could return false in the future. This may be an upgrade of our own, or someone else implementing an IElasticToken with a different set of considerations.

## s!m0

### [Exploit](https://github.com/code-423n4/contest-2-results/blob/main/s1m0/Bug1.sol)

Status: __Unclear__

#### Team Comments

There is no description provided for the code submitted. It looks as though the warden is reporting the lack of guard on Token.updateNumberOfTokenHolders. If so, this has been resolved as noted earlier. If the warden can provide more info, we're happy to respond more directly.