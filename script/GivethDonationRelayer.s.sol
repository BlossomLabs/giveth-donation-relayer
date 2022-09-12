// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/GivethDonationRelayer.sol";

contract DeploymentScript is Script {
  function run() external {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    vm.startBroadcast(deployerPrivateKey);

    GivethDonationRelayer gdr = new GivethDonationRelayer();
    ERC1967Proxy proxy = new ERC1967Proxy(address(gdr), "");

    gdr = GivethDonationRelayer(address(proxy));
    gdr.initialize();

    vm.stopBroadcast();
  }
}