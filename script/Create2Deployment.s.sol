// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "openzeppelin-contracts/utils/Create2.sol";

import "../src/GivethDonationRelayer.sol";

contract Create2Deployment is Script {
  bytes implementationCreationCode = type(GivethDonationRelayer).creationCode;
  bytes proxyBytecode = type(ERC1967Proxy).creationCode;
  
  function deployContracts(uint256 deployerPrivateKey, bytes32 salt) public returns (address deployedImplementationAddress, address deployedProxyAddress) {
    address deployerAddress = vm.addr(deployerPrivateKey);
    // Include deployer address in first salt bytes to avoid front-running or other collissions.
    bytes32 deploymentSalt = bytes32(abi.encodePacked(deployerAddress, salt));


    vm.startBroadcast(deployerPrivateKey);

    deployedImplementationAddress = Create2.deploy(0, deploymentSalt, implementationCreationCode);

    // Include initialize data to deploy and initialize proxy in the same tx to avoid front-running
    bytes memory proxyCreationCode = abi.encodePacked(proxyBytecode, buildProxyConstructorParams(deployedImplementationAddress, deployerAddress));
    deployedProxyAddress = Create2.deploy(0, deploymentSalt, proxyCreationCode);

    vm.stopBroadcast();
  }

  function run() external {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    bytes32 salt = bytes32(bytes(vm.envString("DEPLOYMENT_SALT")));

    deployContracts(deployerPrivateKey, salt);    
  }
  
  function buildProxyConstructorParams(address _implementation, address _owner) internal pure returns (bytes memory) {
    return abi.encode(_implementation, abi.encodeWithSignature("initialize(address)", _owner));
  }
}