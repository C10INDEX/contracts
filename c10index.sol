// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "./vault.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

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
    using SafeMath for uint256;

    address public constant USDC = 0x65aFADD39029741B3b8f0756952C74678c9cEC93;
    address public constant LINK = 0xe9c4393a23246293a8D31BF7ab68c17d4CF90A29;
    IERC20 public usdcToken = IERC20(USDC);
    IERC20 public linkToken = IERC20(LINK);
    address[2] public tokenAddresses;
    uint256[2] public Proportion;
    uint256 public i = 0;
    uint256 public j = 0;
    uint256 public AUM_In_Usd;
    uint256 public C10_Supply;
    uint256 public C10_Price;


    C10Vault public vault;//CONTRACT DU VAULT

    //Chainlink data's array
    AggregatorV3Interface[] internal priceFeeds;
    //Assets structure array
    Asset[2] public assets;

    event transaction_success(uint256 value);
    struct Asset 
    {
        uint256 price;
        uint256 proportion;
        uint256 dec;
    }

    constructor() {
    Proportion[0] = 75;
    Proportion[1] = 25;
    priceFeeds = new AggregatorV3Interface[](2);
    priceFeeds[0] = AggregatorV3Interface(0x48731cF7e84dc94C5f84577882c14Be11a5B7456); //LINK/USD price feed
    priceFeeds[1] = AggregatorV3Interface(0x48731cF7e84dc94C5f84577882c14Be11a5B7456); //LINK/USD
    tokenAddresses[0] = 0xe9c4393a23246293a8D31BF7ab68c17d4CF90A29;//link
    tokenAddresses[1] = 0xe9c4393a23246293a8D31BF7ab68c17d4CF90A29;
    }

    function setVaultAddress(address _vault) public onlyOwner {
        vault = C10Vault(_vault);
    }

    function changeVaultOwner(address _vaultOwner) public onlyOwner {
        vault.setC10ContractAsOwner(_vaultOwner);
    }

    function get_supply() public view returns (uint256) {
    return totalSupply();
    }

    function setTokenAddresses(address[] memory _tokenAddresses) public onlyOwner {
        tokenAddresses = _tokenAddresses;
    }

    function setProportions(uint256[] memory _proportion) public onlyOwner {
        for (i = 0; i < assets.lenght; i++)
        {
            assets[i].
        }
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
    function get_c10()public view returns(uint256){
        return AUM_In_Usd/ totalSupply();
    }

    function get_TVL()public view returns(uint256){
        return AUM_In_Usd;
    }

}
