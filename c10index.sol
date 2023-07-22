// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./lastvault.sol";

/* Price feeds addresses
0xd6d95CF12EdC1C513beF08E78f79bA31E516FF32 ETH/USD
0xF3e0f39954Fc5E3154a400aA29133438382b28A1 BTC/USD
0x30c5f72273cB67EF95257d77d2E7ae9972aa9d4D MATIC/USD 
0xfB425EF72d1bBDe50195784CC6049d6d486349f8 DAI/USD
1INCH/USD
0x8B83c43d30944B43Fd976440031C21E84bdd3b8e USDT/USD
0xdaa1ED784644db147cd20F3324E9676295165370 LINK/USD
0x338F2170c43D8111Bad6B1883e473de00695372E BNB/USD
0x7FC9a50aE58b83c202CDb7a0bD9b3705C4067471 SNX/USD
0x3c8AB2F01ED2E6F06b8a2568472F2Db12CC369b7 UNI/USD
*/

contract C10Token is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("C10index", "C10") {}

    function mint(uint256 amount) public onlyOwner {
        _mint(msg.sender, amount);
    }

    function burnTokens(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}

contract C10ETF is C10Token, C10Vault {

    using SafeMath for uint256;

    Asset[10] public assets;
    AggregatorV3Interface[] public priceFeeds;

    address public constant DAI = 0x9C58BAcC331c9aa871AFD802DB6379a98e80CEdb;
    IERC20 public DAIToken = IERC20(DAI);
    
    C10Vault public vault;

    mapping (address => uint256) public tokenBalances;
    
    address [10] public tokenAddresses;
    uint256 public i = 0;
    uint256 public j = 0;
    uint256 public AUM_In_Usd;
    uint256 public C10_Supply;
    uint256 public C10_Price;
    uint256 public Pool_Value;
    uint256 public tokenBalance;
    uint256 public tokenPrice;
    uint24 public constant poolFee = 3000;
    uint256 [10] public proportion;
    uint256[10] public decimal = [18, 8, 18, 6, 18, 18, 18, 18, 18, 18];

    event transaction_success(uint256 value);

    struct Asset 
    {
        uint256 price;
        uint256 part;
        uint256 dec;
    }

    constructor() {
    tokenAddresses[0] = 0x6A023CCd1ff6F2045C3309768eAd9E68F978f6e1;//WETH
    tokenAddresses[1] = 0x8e5bBbb09Ed1ebdE8674Cda39A0c169401db4252;//WBTC
    tokenAddresses[2] = 0x9C58BAcC331c9aa871AFD802DB6379a98e80CEdb;//DAI
    tokenAddresses[3] = 0x7122d7661c4564b7C6Cd4878B06766489a6028A2;//WMATIC
    tokenAddresses[4] = 0x4ECaBa5870353805a9F068101A40E0f32ed605C6;//USDT
    tokenAddresses[5] = 0xE2e73A1c69ecF83F464EFCE6A5be353a37cA09b2;//LINK
    tokenAddresses[6] = 0xCa8d20f3e0144a72C6B5d576e9Bd3Fd8557E2B04;//BNB
    tokenAddresses[7] = 0x4537e328Bf7e4eFA29D05CAeA260D7fE26af9D74;//UNI
    tokenAddresses[8] = 0x7f7440C5098462f833E123B44B8A03E1d9785BAb;//W1INCH
    tokenAddresses[9] = 0x3A00E08544d589E19a8e7D97D0294331341cdBF6;//SNX18
    
    }
    function setVaultAddress(address _vault) public onlyOwner {
        vault = C10Vault(_vault);
    }

    function changeVaultOwner(address _vaultOwner) public onlyOwner {
        vault.setC10ContractAsOwner(_vaultOwner);
    }

    function getTotalSupply() public view returns (uint256) {
    return totalSupply();
    }

    function mint_single(uint amount) public {
         mint(amount);
    }

    function set_Proportion(uint256[] memory _proportion) public
    {
        for (i = 0; i < proportion.length; i++){
        proportion[i] = _proportion[i];
        }
    }

    function setPriceFeeds (address[] memory _PriceFeeds) public
    {
        for  (i = 0; i < _PriceFeeds.length; i++){
            priceFeeds[i] = AggregatorV3Interface(_PriceFeeds[i]);
        }
    }

    function updateAssetValues() public 
    {
        for (i = 0; i < priceFeeds.length; i++) 
        {
            (, int256 price, , , ) = priceFeeds[i].latestRoundData();
            assets[i].price = uint256(price);
            assets[i].dec = decimal[i];
        }
    }

    function _updateTokenBalance() public{

        for (i = 0; i < 1; i++){
            uint256 nextBalance = IERC20(tokenAddresses[i]).balanceOf(address(vault));//with 18 decimals
            tokenBalances[tokenAddresses[i]] = nextBalance;
        }
    }

    function _updatePoolValue() public returns (uint256) {
    Pool_Value = 0; 

    _updateTokenBalance(); 
    updateAssetValues();
    for (i = 0; i < tokenAddresses.length; i++) {
        tokenBalance = (tokenBalances[tokenAddresses[i]]);//with 18 decimals
        tokenPrice = (assets[i].price / 1e8);
        Pool_Value = Pool_Value.add(tokenBalance.mul(tokenPrice));
    }
    return Pool_Value;
    }

    function getc10Price()public view returns(uint256){
        return AUM_In_Usd/ totalSupply();
    }

    function getTVL()public view returns(uint256){
        return AUM_In_Usd;
    }
}
