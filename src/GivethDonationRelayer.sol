// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "openzeppelin-contracts/interfaces/IERC20.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract GivethDonationRelayer is Initializable, UUPSUpgradeable, OwnableUpgradeable {
  using SafeERC20 for IERC20;

  event SendDonation(address indexed from, address indexed to, IERC20 token, uint256 amount, bytes project);

  function sendDonation(IERC20 _token, address _receiver, uint256 _amount, bytes calldata _project) external {
    _token.safeTransferFrom(msg.sender, _receiver, _amount);

    emit SendDonation(msg.sender, _receiver, _token, _amount, _project);
  }

  function initialize() public initializer {

    ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
    __Ownable_init();
  }

  function _authorizeUpgrade(address) internal override onlyOwner {}
 }
