// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../GivethDonationRelayer.sol";

contract GivethDonationRelayerV2 is GivethDonationRelayer {
  function contractVersion() external pure returns (uint256) {
    return 2;
  } 
}