**Handle:** ncitron  
**Ethereum Address:** ncitron.eth 

# BUG 1
## Summary
`ElastricDAO.join` reverts if two users attempt to join in the same block.

## Risk Rating
1

## Vulnerability Details
Since `ElastricDAO.join` requires that msg.value is equal to the exact cost to join, and a user joining causes the price for future joiners to go up, then a second `join` call in the same block will always revert.

## Impact
This does pose a threat to the overall security of the contract, but with the cost of gas being as high as it is, it would be prudent to avoid uneeded reverts. Additionally, if in the future ElasticDAO decided to enable deployments on L2, then this function would be susceptible to a griefing attack, where a malicious user could make the contracts unusable by constantly sending cheap join requests.

## Proof of Concept
Using the testing suite in the elasticdao/contracts GitHub repo:
```js
describe('bugs', () => {
  let dao;
  let token;
  let sdk;

  beforeEach(async () => {
      await deployments.fixture();
      sdk = await SDK();
      dao = await summonedDAO();
      token = await dao.token();
  });

  it("should revert", async () => {
    const ethBalanceElasticDAOBeforeJoin = await ethBalance(dao.uuid);
    const totalSupplyOfToken = await dao.elasticGovernanceToken.totalSupply();
    const cDelta = capitalDelta(ethBalanceElasticDAOBeforeJoin, totalSupplyOfToken);
    const deltaLambda = BigNumber(0.1);
    const lambdaDash = token.lambda.plus(deltaLambda);
    const dE = deltaE(deltaLambda, cDelta, token.k, token.elasticity, token.lambda, token.m);
    const mD = mDash(lambdaDash, token.lambda, token.m);

    const tx1 = await dao.elasticDAO.join(deltaLambda, { value: dE });
    const tx2 =  dao.elasticDAO.join(deltaLambda, { value: dE });
    await expect(tx2).to.be.revertedWith('ElasticDAO: Incorrect ETH amount');
  });
});
```

## Tools Used
Hardhat

## Recommended Mitigation Steps
A possible way to mitigate this is to instead have msg.value be equal to the maximum amount a user is willing to pay to join. If the cost to join is above msg.value, revert. If it is below msg.value, then join the dao and refund the unused ether back to the user. Another possible mitigation is to instead have users pay in WETH. You could then do a similar mitagation strategy as above, but without having to refund extra ether.
