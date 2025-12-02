// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {BUSD} from "../src/BUSD.sol";
import {CCNFT} from "../src/CCNFT.sol";

contract CCNFTTest is Test {
    address deployer;
    address c1;
    address c2;
    address funds;
    address fees;
    BUSD busd;
    CCNFT ccnft;

    function setUp() public {
        deployer = address(this);
        c1 = address(0x1);
        c2 = address(0x2);
        funds = address(0x3);
        fees = address(0x4);
        
        busd = new BUSD();
        ccnft = new CCNFT("CryptoCampo NFT", "CCNFT");
        
        // Configurar contratos
        ccnft.setFundsToken(address(busd));
        ccnft.setFundsCollector(funds);
        ccnft.setFeesCollector(fees);
        ccnft.addValidValues(100 * 10 ** 18);
        
        // Transferir BUSD a c1 para pruebas
        busd.transfer(c1, 10000 * 10 ** 18);
        busd.transfer(c2, 10000 * 10 ** 18);
    }

    function testSetFundsCollector() public {
        address newCollector = address(0x999);
        ccnft.setFundsCollector(newCollector);
        assertEq(ccnft.fundsCollector(), newCollector);
    }

    function testSetFeesCollector() public {
        address newCollector = address(0x888);
        ccnft.setFeesCollector(newCollector);
        assertEq(ccnft.feesCollector(), newCollector);
    }

    function testSetProfitToPay() public {
        uint32 newProfit = 1000; // 10%
        ccnft.setProfitToPay(newProfit);
        assertEq(ccnft.profitToPay(), newProfit);
    }

    function testSetCanBuy() public {
        // Test true
        ccnft.setCanBuy(true);
        assertEq(ccnft.canBuy(), true);
        
        // Test false
        ccnft.setCanBuy(false);
        assertEq(ccnft.canBuy(), false);
    }

    function testSetCanTrade() public {
        ccnft.setCanTrade(true);
        assertEq(ccnft.canTrade(), true);
        
        ccnft.setCanTrade(false);
        assertEq(ccnft.canTrade(), false);
    }

    function testSetCanClaim() public {
        ccnft.setCanClaim(true);
        assertEq(ccnft.canClaim(), true);
        
        ccnft.setCanClaim(false);
        assertEq(ccnft.canClaim(), false);
    }

    function testSetMaxValueToRaise() public {
        uint256 newMax = 2000000 * 10 ** 18;
        ccnft.setMaxValueToRaise(newMax);
        assertEq(ccnft.maxValueToRaise(), newMax);
    }

    function testAddValidValues() public {
        uint256 value1 = 50 * 10 ** 18;
        uint256 value2 = 200 * 10 ** 18;
        
        ccnft.addValidValues(value1);
        ccnft.addValidValues(value2);
        
        assertEq(ccnft.validValues(value1), true);
        assertEq(ccnft.validValues(value2), true);
    }

    function testSetMaxBatchCount() public {
        uint16 newCount = 20;
        ccnft.setMaxBatchCount(newCount);
        assertEq(ccnft.maxBatchCount(), newCount);
    }

    function testSetBuyFee() public {
        uint16 newFee = 200; // 2%
        ccnft.setBuyFee(newFee);
        assertEq(ccnft.buyFee(), newFee);
    }

    function testSetTradeFee() public {
        uint16 newFee = 100; // 1%
        ccnft.setTradeFee(newFee);
        assertEq(ccnft.tradeFee(), newFee);
    }

    function testCannotTradeWhenCanTradeIsFalse() public {
        ccnft.setCanTrade(false);
        
        vm.prank(c1);
        vm.expectRevert("Trading is disabled");
        ccnft.putOnSale(1, 100 * 10 ** 18);
    }

    function testCannotTradeWhenTokenDoesNotExist() public {
        vm.prank(c1);
        vm.expectRevert("Token does not exist");
        ccnft.putOnSale(999, 100 * 10 ** 18);
    }
    
    function testBuyNFT() public {
        // Preparar aprobación de BUSD
        vm.prank(c1);
        busd.approve(address(ccnft), 200 * 10 ** 18);
        
        // Comprar NFT
        vm.prank(c1);
        ccnft.buy(100 * 10 ** 18, 1);
        
        assertEq(ccnft.ownerOf(1), c1);
        assertEq(ccnft.totalValue(), 100 * 10 ** 18);
    }
}