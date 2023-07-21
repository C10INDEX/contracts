// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./vault.sol";

contract C10Token is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("C10index", "C10") {}

    function mint(uint256 amount) public onlyOwner {
        _mint(msg.sender, amount);
    }

    function burnTokens(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}

contract C10INDEX is C10Token {

    //address public constant LINK = 0xe9c4393a23246293a8D31BF7ab68c17d4CF90A29;//LINK Mumbai faucet
    //router pour uniswap qui work,mais a check pour oneinch!
    address public constant routerAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    ISwapRouter public immutable swapRouter = ISwapRouter(routerAddress);

    address public constant USDC = 0x65aFADD39029741B3b8f0756952C74678c9cEC93;
    IERC20 public usdcToken = IERC20(USDC);
    C10Vault public vault;//CONTRACT DU VAULT

    //Chainlink data's array
    AggregatorV3Interface[] internal priceFeeds;
    //Assets structure array
    Asset[2] public assets;

    struct Asset 
    {
        uint256 price;
    }

    function setVaultAddress(address _vault) public onlyOwner {
        vault = C10Vault(_vault);
    }

    function changeVaultOwner(address _vaultOwner) public onlyOwner {
        vault.setC10ContractAsOwner(_vaultOwner);
    }

    //["0xe9c4393a23246293a8D31BF7ab68c17d4CF90A29","0xe9c4393a23246293a8D31BF7ab68c17d4CF90A29"]
    function setTokenAddresses(address[2] memory _tokenAddresses) public onlyOwner {
        tokenAddresses = _tokenAddresses;
    }

    function setProportions(uint[2] memory _Proportion) public onlyOwner {
        Proportion = _Proportion;
    }

    function updateAssetValues() public 
    {
        for (i = 0; i < priceFeeds.length; i++) 
        {
            (, int256 price, , , ) = priceFeeds[i].latestRoundData();
            assets[i].price = uint256(price);
        }
    }
    //["0x48731cF7e84dc94C5f84577882c14Be11a5B7456","0x48731cF7e84dc94C5f84577882c14Be11a5B7456"]
    function set_Oracle (address[] memory _priceFeedAddresses) public{
        for (i = 0; i < _priceFeedAddresses.length; i++)
        {
            AggregatorV3Interface priceFeed = AggregatorV3Interface(_priceFeedAddresses[i]);
            priceFeeds.push(priceFeed);
        }
        updateAssetValues();
    }

    //test avec uniswap par simpliciter de doc, a demander a oneinch team pour unoswap?
    function swap(uint256 amountIn) internal returns (uint256 amountOut)
    {
        usdcToken.approve(address(swapRouter), amountIn);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: USDC,
                tokenOut: tokenAddresses[i],
                fee: poolFee,
                recipient: address(vault),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        amountOut = swapRouter.exactInputSingle(params);     
    }

    //dont need deposit function anymore,but need to approve spending in usdc contract
    function buyETF(uint256 usdcAmount) external {    
        
        
        require(usdcToken.allowance(msg.sender, address(this)) >= usdcAmount, "Error");
        require(usdcToken.transferFrom(msg.sender, address(this), usdcAmount), "Error.");
        //the swap sends values to the vault
        for ( i = 0; i < 2; i++){
            swap(Proportion[i]*usdcAmount /100);
        }
        //mint(usdcAmount * 1e18);  
    }
}
