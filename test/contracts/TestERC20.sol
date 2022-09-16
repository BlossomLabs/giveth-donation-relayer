// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract TestERC20 is ERC20, Ownable {
  constructor() ERC20("Test token", "TST") Ownable() {}

  function mint(address _recipient, uint256 _amount) external onlyOwner {
    _mint(_recipient, _amount);
  }
}