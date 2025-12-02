// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/BUSD.sol";
import "../src/CCNFT.sol";

contract DeployCCNFT is Script {
    function run() external {
       
        string memory sepoliaUrl = vm.envString("SEPOLIA_RPC_URL");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log(" Deploying to Sepolia via Alchemy");
        console.log(" Deployer:", deployer);
        console.log(" Balance:", deployer.balance / 1e18, "ETH");
        console.log(" RPC:", sepoliaUrl);
        
       
        if (deployer.balance == 0) {
            revert("No ETH balance. Get Sepolia ETH at: https://sepoliafaucet.com");
        }
        
        vm.startBroadcast(deployerPrivateKey);
        
       
        console.log("\n Deploying BUSD Token...");
        BUSD busd = new BUSD();
        console.log(" BUSD deployed at:", address(busd));
        
     
        console.log("\n Deploying CryptoCampo NFT...");
        CCNFT ccnft = new CCNFT("CryptoCampo NFT", "CCNFT");
        console.log(" CCNFT deployed at:", address(ccnft));
        
       
        console.log("\n Configuring CCNFT...");
        
        
        ccnft.setFundsToken(address(busd));
        console.log("   Funds Token:", address(busd));
        
       
        ccnft.setFundsCollector(deployer);
        console.log("   Funds Collector:", deployer);
        
        ccnft.setFeesCollector(deployer);
        console.log("   Fees Collector:", deployer);
        
      
        console.log("\n   Adding valid values for NFTs...");
        

        uint256 value1 = 100 * 10 ** 18;   // 100 BUSD
        uint256 value2 = 500 * 10 ** 18;   // 500 BUSD
        uint256 value3 = 1000 * 10 ** 18;  // 1000 BUSD
        
        ccnft.addValidValues(value1);
        console.log("    Valid Value Added: 100 BUSD");
        
        ccnft.addValidValues(value2);
        console.log("    Valid Value Added: 500 BUSD");
        
        ccnft.addValidValues(value3);
        console.log("    Valid Value Added: 1000 BUSD");
        
   
        ccnft.setBuyFee(100);      // 1%
        ccnft.setTradeFee(50);     // 0.5%
        ccnft.setProfitToPay(500); // 5%
        console.log("    Fees configured: Buy=1%, Trade=0.5%, Profit=5%");
        
        
        console.log("\n Transferring BUSD to deployer for testing...");
        uint256 testBusd = 5000 * 10 ** 18; // 5000 BUSD
        busd.transfer(deployer, testBusd);
        console.log("  Transferred:", testBusd / 1e18, "BUSD to", deployer);
        
        vm.stopBroadcast();
    
        console.log("\n DEPLOYMENT COMPLETE!");
        console.log("========================");
        console.log(" BUSD Address:", address(busd));
        console.log(" CCNFT Address:", address(ccnft));
        console.log(" Deployer Address:", deployer);
        console.log("\n Next Steps:");
        console.log("   1. Import BUSD to MetaMask: ", address(busd));
        console.log("   2. Approve BUSD for CCNFT");
        console.log("   3. Call 'buy' on CCNFT contract");
        console.log("   4. Verify contracts on Etherscan");
        console.log("========================");
    }
}