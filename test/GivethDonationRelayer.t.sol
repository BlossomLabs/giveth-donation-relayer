// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/utils/Create2.sol";

import "src/GivethDonationRelayer.sol";

import "./contracts/TestERC20.sol";
import "./contracts/GivethDonationRelayerV2.sol";

import "script/Create2Deployment.s.sol";

contract GivethDonationRelayerTest is Test {
    event SendDonation(address indexed from, address indexed to, uint256 indexed projectId, IERC20 token, uint256 amount);

    Create2Deployment deploymentScript;

    GivethDonationRelayer donationRelayer;
    ERC1967Proxy proxy;
    TestERC20 token;

    uint256 ownerPK = vm.deriveKey("test test test test test test test test test test test junk", 0);
    string forkUrl = "https://rpc.gnosischain.com";
    bytes32 salt = bytes32("test-salt");

    // Default foundry deployer account
    address defaultDeployer = 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84;
    address owner = vm.addr(ownerPK);
    address sender = address(1);
    address receiver = address(2);
    address notOwner = address(3);

    uint256 projectId = 1;

    uint256 donatedAmount = 5 ether;

    address deployedImplementationAddress;
    address deployedProxyAddress;

    function setUp() public {
        deploymentScript = new Create2Deployment();

        (deployedImplementationAddress, deployedProxyAddress) = deploymentScript.deployContracts(ownerPK, salt);

        donationRelayer = GivethDonationRelayer(deployedProxyAddress);
        proxy = ERC1967Proxy(payable(deployedProxyAddress));

        token = new TestERC20();

        vm.label(sender, "sender");
        vm.label(receiver, "receiver");


        vm.prank(defaultDeployer);
        token.mint(sender, 50 ether);

        vm.deal(sender, 50 ether);
    }

    function testItTransfersAmountCorrectly() public {
        uint256 senderBeforeBalance = token.balanceOf(sender);
        uint256 receiverBeforeBalance = token.balanceOf(receiver);
        uint8 decimals = token.decimals();

        vm.startPrank(sender);
        token.approve(address(donationRelayer), donatedAmount);
        donationRelayer.sendDonation(token, receiver,  donatedAmount, projectId);
        vm.stopPrank();

        assertEqDecimal(token.balanceOf(sender), senderBeforeBalance - donatedAmount, decimals);
        assertEqDecimal(token.balanceOf(receiver), receiverBeforeBalance + donatedAmount, decimals);
    }

    function testItEmitsSendDonationCorrectly() public {
        vm.startPrank(sender);

        token.approve(address(donationRelayer), donatedAmount);

        vm.expectEmit(true, true, true, true);
        emit SendDonation(sender, receiver, projectId, token, donatedAmount);

        donationRelayer.sendDonation(token, receiver, donatedAmount, projectId);

        vm.stopPrank();
    }

    function testItHasCorrectOwner() public {
        assertEq(donationRelayer.owner(), owner);
    }

    function testItDeploysAtTheSameAddressInOtherNetwork() public {
        vm.createSelectFork(forkUrl);

        (address forkDeployedImpAddress, address forkDeployedProxyAddress) = new Create2Deployment().deployContracts(ownerPK, salt);

        assertEq(deployedImplementationAddress, forkDeployedImpAddress, "Implementation address mismatch");
        assertEq(deployedProxyAddress, forkDeployedProxyAddress, "Proxy address mismatch");
    }



    function testItUpgradesCorrectly() public {
        GivethDonationRelayerV2 donationRelayerV2 = new GivethDonationRelayerV2();

        vm.prank(owner);
        donationRelayer.upgradeTo(address(donationRelayerV2));
        donationRelayerV2 = GivethDonationRelayerV2(address(proxy));

        assertEq(donationRelayerV2.contractVersion(), 2);  
    }

    function testItFailsWhenUpgradingWithNotOwner() public {
        GivethDonationRelayerV2 donationRelayerV2 = new GivethDonationRelayerV2();

        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        vm.prank(notOwner);
        donationRelayer.upgradeTo(address(donationRelayerV2));
    }
}
