// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "src/GivethDonationRelayer.sol";
import "./GivethDonationRelayerV2.sol";
import "./TestERC20.sol";

contract GivethDonationRelayerTest is Test {
    event SendDonation(address indexed from, address indexed to, IERC20 token, uint256 amount, bytes project);


    GivethDonationRelayer donationRelayer;
    ERC1967Proxy proxy;
    TestERC20 token;
    

    // Default foundry deployer account
    address deployer = 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84;
    address sender = address(1);
    address receiver = address(2);
    address notOwner = address(3);

    bytes project = bytes("Test Project");

    uint256 donatedAmount = 5 ether;

    function setUp() public {
        donationRelayer = new GivethDonationRelayer();
        proxy = new ERC1967Proxy(address(donationRelayer), "");
        donationRelayer = GivethDonationRelayer(address(proxy));
        donationRelayer.initialize();

        token = new TestERC20();

        vm.label(sender, "sender");
        vm.label(receiver, "receiver");


        vm.prank(deployer);
        token.mint(sender, 50 ether);

        vm.deal(sender, 50 ether);
    }

    function testItTransfersAmountCorrectly() public {
        uint256 senderBeforeBalance = token.balanceOf(sender);
        uint256 receiverBeforeBalance = token.balanceOf(receiver);
        uint8 decimals = token.decimals();

        vm.startPrank(sender);
        token.approve(address(donationRelayer), donatedAmount);
        donationRelayer.sendDonation(token, receiver,  donatedAmount, project);
        vm.stopPrank();

        assertEqDecimal(token.balanceOf(sender), senderBeforeBalance - donatedAmount, decimals);
        assertEqDecimal(token.balanceOf(receiver), receiverBeforeBalance + donatedAmount, decimals);
    }

    function testItEmitsSendDonationCorrectly() public {
        vm.startPrank(sender);

        token.approve(address(donationRelayer), donatedAmount);

        vm.expectEmit(true, true, true, true);
        emit SendDonation(sender, receiver, token, donatedAmount, project);

        donationRelayer.sendDonation(token, receiver, donatedAmount, project);

        vm.stopPrank();
    }

    function testItUpgradesCorrectly() public {
        GivethDonationRelayerV2 donationRelayerV2 = new GivethDonationRelayerV2();

        donationRelayer.upgradeTo(address(donationRelayerV2));
        donationRelayerV2 = GivethDonationRelayerV2(address(proxy));

        assertEq(donationRelayerV2.contractVersion(), 2);  
    }

    function testItFailsWhenUpgradingWithNoOwner() public {
        GivethDonationRelayerV2 donationRelayerV2 = new GivethDonationRelayerV2();

        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        vm.prank(notOwner);
        donationRelayer.upgradeTo(address(donationRelayerV2));
    }
}
